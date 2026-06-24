import Foundation

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
        return URLSession(configuration: config)
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
        return try await execute(request: request, responseType: responseType)
    }

    // Use for all ULIP data APIs — auto-attaches Bearer token
    func authenticatedPost<Req: Encodable, Res: Decodable>(
        endpoint: String,
        body: Req,
        responseType: Res.Type
    ) async throws -> Res {
        var request = try buildAuthenticatedRequest(endpoint: endpoint, method: "POST")
        request.httpBody = try JSONEncoder().encode(body)
        return try await execute(request: request, responseType: responseType)
    }

    func authenticatedGet<Res: Decodable>(
        endpoint: String,
        responseType: Res.Type
    ) async throws -> Res {
        let request = try buildAuthenticatedRequest(endpoint: endpoint, method: "GET")
        return try await execute(request: request, responseType: responseType)
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

    private func execute<Res: Decodable>(request: URLRequest, responseType: Res.Type) async throws -> Res {
        do {
            let (data, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 401 { throw ULIPNetworkError.tokenExpired }
                guard (200...299).contains(http.statusCode) else {
                    throw ULIPNetworkError.httpError(http.statusCode)
                }
            }
            do {
                return try JSONDecoder().decode(Res.self, from: data)
            } catch {
                throw ULIPNetworkError.decodingError(error)
            }
        } catch let error as ULIPNetworkError {
            throw error
        } catch {
            throw ULIPNetworkError.networkError(error)
        }
    }
}
