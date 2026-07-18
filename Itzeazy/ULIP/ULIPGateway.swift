import Foundation

// The backend's own `message` field (for both HTTP errors and a 200 with no `data`)
// can contain raw internal/upstream failure details — DNS lookups, dial errors, etc.
// from the server's own HTTP client calling ULIP — that must never reach the UI.
// Full detail is already written to the OSLog "API" log by ItzeazyAPIService before
// this ever throws; the user only ever sees one of a small set of generic, polite
// messages below, regardless of what the backend actually said.
enum ULIPGatewayError: Error, LocalizedError {
    case notLoggedIn
    case emptyResponse
    case requestFailed(Int)

    var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return "Your session has expired. Please log in again."
        case .emptyResponse:
            return "Something went wrong. Please try again in a moment."
        case .requestFailed(let statusCode):
            switch statusCode {
            case 400:
                return "We couldn't process this request. Please check the details and try again."
            case 401, 403:
                return "Your session has expired. Please log in again."
            case 500:
                return "Something went wrong on our end. Please try again in a moment."
            default:
                return "Something went wrong. Please try again in a moment."
            }
        }
    }
}

// Shared entry point for all ULIP data calls — routed through the Itzeazy
// backend's own ULIP gateway, authenticated with the user's existing session
// token (no separate ULIP login anymore).
enum ULIPGateway {
    static func post<Req: Encodable, Payload: Decodable>(
        endpoint: String,
        body: Req
    ) async throws -> Payload {
        guard let token = AuthSessionStorage.shared.getToken() else {
            NotificationCenter.default.post(name: .itzeazyUnauthorized, object: nil)
            throw ULIPGatewayError.notLoggedIn
        }

        do {
            let envelope: ItzeazyGatewayResponse<Payload> = try await ItzeazyAPIService.shared.post(
                endpoint: endpoint,
                body: body,
                token: token
            )
            guard let data = envelope.data else {
                throw ULIPGatewayError.emptyResponse
            }
            return data
        } catch let error as ItzeazyAPIError {
            if case .httpError(let statusCode, _) = error {
                throw ULIPGatewayError.requestFailed(statusCode)
            }
            throw error
        }
    }
}
