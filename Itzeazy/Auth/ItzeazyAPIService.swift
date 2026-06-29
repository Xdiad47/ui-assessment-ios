import Foundation
import OSLog

private let logger = Logger(subsystem: "com.itzeazy.app", category: "API")

enum ItzeazyAPIError: LocalizedError {
    case invalidURL
    case httpError(Int, String?)
    case decodingError
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL."
        case .httpError(_, let message):
            return message ?? "Something went wrong. Please try again."
        case .decodingError:
            return "Unexpected server response."
        case .networkError:
            return "Network unavailable. Please check your connection."
        }
    }
}

final class ItzeazyAPIService {
    static let shared = ItzeazyAPIService()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
    }

    func post<Req: Encodable, Res: Decodable>(
        endpoint: String,
        body: Req,
        token: String? = nil
    ) async throws -> Res {
        let urlString = AppEnvironment.current.baseURL + endpoint
        guard let url = URL(string: urlString) else {
            throw ItzeazyAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw ItzeazyAPIError.networkError(error)
        }

        // ── Request log ──────────────────────────────────────────
        logger.debug("➡️ POST \(urlString)")
        if let bodyData = request.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            logger.debug("   Body: \(bodyString)")
        }
        if token != nil {
            logger.debug("   Auth: Bearer token attached")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            logger.error("❌ Network error [\(endpoint)]: \(error.localizedDescription)")
            throw ItzeazyAPIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ItzeazyAPIError.networkError(URLError(.badServerResponse))
        }

        // ── Response log ─────────────────────────────────────────
        let rawBody = String(data: data, encoding: .utf8) ?? "<non-UTF8 body>"
        if (200...299).contains(http.statusCode) {
            logger.debug("✅ \(http.statusCode) [\(endpoint)]")
            logger.debug("   Response: \(rawBody)")
        } else {
            logger.error("❌ \(http.statusCode) [\(endpoint)]")
            logger.error("   Response: \(rawBody)")
        }

        guard (200...299).contains(http.statusCode) else {
            try throwHTTPError(statusCode: http.statusCode, data: data)
        }

        do {
            return try JSONDecoder().decode(Res.self, from: data)
        } catch let decodeError {
            logger.error("❌ Decode error [\(endpoint)]: \(decodeError)")
            throw ItzeazyAPIError.decodingError
        }
    }

    func get<Res: Decodable>(
        endpoint: String,
        token: String? = nil
    ) async throws -> Res {
        let urlString = AppEnvironment.current.baseURL + endpoint
        guard let url = URL(string: urlString) else {
            throw ItzeazyAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        logger.debug("➡️ GET \(urlString)")
        if token != nil {
            logger.debug("   Auth: token attached")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            logger.error("❌ Network error [\(endpoint)]: \(error.localizedDescription)")
            throw ItzeazyAPIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ItzeazyAPIError.networkError(URLError(.badServerResponse))
        }

        let rawBody = String(data: data, encoding: .utf8) ?? "<non-UTF8 body>"
        if (200...299).contains(http.statusCode) {
            logger.debug("✅ \(http.statusCode) [\(endpoint)]")
            logger.debug("   Response: \(rawBody)")
        } else {
            logger.error("❌ \(http.statusCode) [\(endpoint)]")
            logger.error("   Response: \(rawBody)")
        }

        guard (200...299).contains(http.statusCode) else {
            try throwHTTPError(statusCode: http.statusCode, data: data)
        }

        do {
            return try JSONDecoder().decode(Res.self, from: data)
        } catch let decodeError {
            logger.error("❌ Decode error [\(endpoint)]: \(decodeError)")
            throw ItzeazyAPIError.decodingError
        }
    }

    func patch<Req: Encodable, Res: Decodable>(
        endpoint: String,
        body: Req,
        token: String? = nil
    ) async throws -> Res {
        let urlString = AppEnvironment.current.baseURL + endpoint
        guard let url = URL(string: urlString) else {
            throw ItzeazyAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw ItzeazyAPIError.networkError(error)
        }

        logger.debug("➡️ PATCH \(urlString)")
        if let bodyData = request.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            logger.debug("   Body: \(bodyString)")
        }
        if token != nil {
            logger.debug("   Auth: token attached")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            logger.error("❌ Network error [\(endpoint)]: \(error.localizedDescription)")
            throw ItzeazyAPIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ItzeazyAPIError.networkError(URLError(.badServerResponse))
        }

        let rawBody = String(data: data, encoding: .utf8) ?? "<non-UTF8 body>"
        if (200...299).contains(http.statusCode) {
            logger.debug("✅ \(http.statusCode) [\(endpoint)]")
            logger.debug("   Response: \(rawBody)")
        } else {
            logger.error("❌ \(http.statusCode) [\(endpoint)]")
            logger.error("   Response: \(rawBody)")
        }

        guard (200...299).contains(http.statusCode) else {
            try throwHTTPError(statusCode: http.statusCode, data: data)
        }

        do {
            return try JSONDecoder().decode(Res.self, from: data)
        } catch let decodeError {
            logger.error("❌ Decode error [\(endpoint)]: \(decodeError)")
            throw ItzeazyAPIError.decodingError
        }
    }

    func delete<Res: Decodable>(
        endpoint: String,
        token: String? = nil
    ) async throws -> Res {
        let urlString = AppEnvironment.current.baseURL + endpoint
        guard let url = URL(string: urlString) else {
            throw ItzeazyAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "accept")

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        logger.debug("➡️ DELETE \(urlString)")
        if token != nil {
            logger.debug("   Auth: Bearer token attached")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            logger.error("❌ Network error [\(endpoint)]: \(error.localizedDescription)")
            throw ItzeazyAPIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ItzeazyAPIError.networkError(URLError(.badServerResponse))
        }

        let rawBody = String(data: data, encoding: .utf8) ?? "<non-UTF8 body>"
        if (200...299).contains(http.statusCode) {
            logger.debug("✅ \(http.statusCode) [\(endpoint)]")
            logger.debug("   Response: \(rawBody)")
        } else {
            logger.error("❌ \(http.statusCode) [\(endpoint)]")
            logger.error("   Response: \(rawBody)")
        }

        guard (200...299).contains(http.statusCode) else {
            try throwHTTPError(statusCode: http.statusCode, data: data)
        }

        do {
            return try JSONDecoder().decode(Res.self, from: data)
        } catch let decodeError {
            logger.error("❌ Decode error [\(endpoint)]: \(decodeError)")
            throw ItzeazyAPIError.decodingError
        }
    }

    private func throwHTTPError(statusCode: Int, data: Data) throws -> Never {
        if statusCode == 401 {
            NotificationCenter.default.post(name: .itzeazyUnauthorized, object: nil)
        }
        let serverMessage = try? JSONDecoder().decode(ServerErrorBody.self, from: data)
        throw ItzeazyAPIError.httpError(statusCode, serverMessage?.message)
    }

    private struct ServerErrorBody: Decodable {
        let message: String?
    }
}
