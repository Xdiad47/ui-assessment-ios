import Foundation

enum ULIPAuthError: Error, LocalizedError {
    case loginFailed(String)

    var errorDescription: String? {
        switch self {
        case .loginFailed(let msg): return "ULIP login failed: \(msg)"
        }
    }
}

final class ULIPAuthService {
    static let shared = ULIPAuthService()

    private let network = ULIPNetworkService.shared
    private let storage = ULIPKeychainStorage.shared

    private init() {}

    // Call before every ULIP data API.
    // Skips login if a valid token exists that is less than 24 hours old.
    // Re-logins automatically if token is missing or older than 24 hours.
    func ensureValidToken() async throws {
        guard !storage.isTokenValid else { return }
        try await login()
    }

    // Call when a 401 is received mid-session to force a fresh token.
    func refreshToken() async throws {
        storage.clearToken()
        try await login()
    }

    func logout() {
        storage.clearToken()
    }

    // MARK: - Private

    private func login() async throws {
        let body = ULIPLoginRequest(
            username: ULIPCredentials.username,
            password: ULIPCredentials.password
        )
        let response = try await network.post(
            endpoint: ULIPEndpoints.login,
            body: body,
            responseType: ULIPLoginResponse.self
        )
        guard response.error == "false", !response.response.id.isEmpty else {
            throw ULIPAuthError.loginFailed(response.message)
        }
        storage.saveToken(response.response.id)
    }
}
