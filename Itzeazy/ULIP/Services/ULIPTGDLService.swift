import Foundation

final class ULIPTGDLService {
    static let shared = ULIPTGDLService()

    private let network = ULIPNetworkService.shared
    private let auth    = ULIPAuthService.shared

    private init() {}

    func getTGDLDetails(dlNumber: String) async throws -> ULIPTGDLResponse {
        try await auth.ensureValidToken()
        return try await fetchDetails(dlNumber: dlNumber)
    }

    private func fetchDetails(dlNumber: String) async throws -> ULIPTGDLResponse {
        do {
            return try await network.authenticatedPost(
                endpoint: ULIPEndpoints.tgDL,
                body: ULIPTGDLRequest(dlNumber: dlNumber),
                responseType: ULIPTGDLResponse.self
            )
        } catch ULIPNetworkError.tokenExpired {
            try await auth.refreshToken()
            return try await network.authenticatedPost(
                endpoint: ULIPEndpoints.tgDL,
                body: ULIPTGDLRequest(dlNumber: dlNumber),
                responseType: ULIPTGDLResponse.self
            )
        }
    }
}
