import Foundation
import OSLog

private let logger = Logger(subsystem: "com.itzeazy.app", category: "ULIP")

#if DEBUG
/// DEBUG-only certificate trust override, scoped to ULIP's host only.
/// DPIIT's ulip.dpiit.gov.in cert is currently expired (confirmed server-side —
/// the API itself responds correctly once TLS trust is skipped). This delegate
/// exists solely so development/testing isn't blocked while they renew it, and
/// it is never compiled into Release builds, so App Store builds always enforce
/// normal certificate validation.
final class ULIPDebugTrustDelegate: NSObject, URLSessionDelegate {
    private let trustedHost = "www.ulip.dpiit.gov.in"

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.host == trustedHost,
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }
}
#endif

enum ULIPNetworkError: Error, LocalizedError {
    case invalidURL
    case noToken
    case tokenExpired
    case httpError(Int)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:               return "Invalid ULIP URL"
        case .noToken:                  return "No ULIP auth token available"
        case .tokenExpired:             return "ULIP token expired"
        case .httpError(let code):      return "ULIP HTTP \(code)"
        case .decodingError(let e):     return "ULIP decode error: \(e.localizedDescription)"
        case .networkError(let e):      return "ULIP network error: \(e.localizedDescription)"
        }
    }
}

final class ULIPNetworkService {
    static let shared = ULIPNetworkService()

    private let baseURL = "https://www.ulip.dpiit.gov.in/ulip/v1.0.0"
    private let storage = ULIPKeychainStorage.shared

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        #if DEBUG
        // ULIP's server certificate is currently expired on DPIIT's side (server-side issue,
        // not ours — see ULIPTrustDelegate). Trusting it here unblocks local development;
        // this delegate is compiled out of Release builds entirely.
        return URLSession(configuration: config, delegate: ULIPDebugTrustDelegate(), delegateQueue: nil)
        #else
        return URLSession(configuration: config)
        #endif
    }()

    private init() {}

    // Use for login — no token header
    func post<Req: Encodable, Res: Decodable>(
        endpoint: String,
        body: Req,
        responseType: Res.Type
    ) async throws -> Res {
        var request = try buildRequest(endpoint: endpoint, method: "POST")
        request.httpBody = try JSONEncoder().encode(body)
        logRequest(request, endpoint: endpoint)
        return try await execute(request: request, endpoint: endpoint, responseType: responseType)
    }

    // Use for all ULIP data APIs — auto-attaches Bearer token
    func authenticatedPost<Req: Encodable, Res: Decodable>(
        endpoint: String,
        body: Req,
        responseType: Res.Type
    ) async throws -> Res {
        var request = try buildAuthenticatedRequest(endpoint: endpoint, method: "POST")
        request.httpBody = try JSONEncoder().encode(body)
        logRequest(request, endpoint: endpoint)
        return try await execute(request: request, endpoint: endpoint, responseType: responseType)
    }

    func authenticatedGet<Res: Decodable>(
        endpoint: String,
        responseType: Res.Type
    ) async throws -> Res {
        let request = try buildAuthenticatedRequest(endpoint: endpoint, method: "GET")
        logRequest(request, endpoint: endpoint)
        return try await execute(request: request, endpoint: endpoint, responseType: responseType)
    }

    // MARK: - Private helpers

    private func buildRequest(endpoint: String, method: String) throws -> URLRequest {
        guard let url = URL(string: baseURL + endpoint) else {
            throw ULIPNetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func buildAuthenticatedRequest(endpoint: String, method: String) throws -> URLRequest {
        guard let token = storage.getToken() else {
            throw ULIPNetworkError.noToken
        }
        var request = try buildRequest(endpoint: endpoint, method: method)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func logRequest(_ request: URLRequest, endpoint: String) {
        logger.debug("➡️ ULIP \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? endpoint)")
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            logger.debug("   Body: \(bodyString)")
        }
        if request.value(forHTTPHeaderField: "Authorization") != nil {
            logger.debug("   Auth: Bearer token attached")
        }
    }

    private func execute<Res: Decodable>(request: URLRequest, endpoint: String, responseType: Res.Type) async throws -> Res {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            let nsError = error as NSError
            logger.error("❌ ULIP network error [\(endpoint)]: domain=\(nsError.domain) code=\(nsError.code) — \(nsError.localizedDescription)")
            if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                logger.error("   Underlying: domain=\(underlying.domain) code=\(underlying.code) — \(underlying.localizedDescription)")
            }
            throw ULIPNetworkError.networkError(error)
        }

        let rawBody = String(data: data, encoding: .utf8) ?? "<non-UTF8 body, \(data.count) bytes>"

        do {
            guard let http = response as? HTTPURLResponse else {
                logger.error("❌ ULIP [\(endpoint)]: non-HTTP response")
                logger.error("   Response: \(rawBody)")
                throw ULIPNetworkError.httpError(-1)
            }

            if (200...299).contains(http.statusCode) {
                logger.debug("✅ ULIP \(http.statusCode) [\(endpoint)]")
                logger.debug("   Response: \(rawBody)")
            } else {
                logger.error("❌ ULIP \(http.statusCode) [\(endpoint)]")
                logger.error("   Response: \(rawBody)")
            }

            if http.statusCode == 401 { throw ULIPNetworkError.tokenExpired }
            guard (200...299).contains(http.statusCode) else {
                throw ULIPNetworkError.httpError(http.statusCode)
            }

            do {
                return try JSONDecoder().decode(Res.self, from: data)
            } catch {
                logger.error("❌ ULIP decode error [\(endpoint)]: \(error)")
                throw ULIPNetworkError.decodingError(error)
            }
        } catch let error as ULIPNetworkError {
            throw error
        }
    }
}
