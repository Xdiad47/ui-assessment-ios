import Foundation

final class ULIPDLService {
    static let shared = ULIPDLService()

    private let network = ULIPNetworkService.shared
    private let auth    = ULIPAuthService.shared

    private init() {}

    // dob format expected by ULIP: "YYYY-MM-DD"
    func getDLDetails(dlNumber: String, dob: String) async throws -> ULIPDLResponse {
        try await auth.ensureValidToken()
        return try await fetchDLDetails(dlNumber: dlNumber, dob: dob)
    }

    // MARK: - Private

    private func fetchDLDetails(dlNumber: String, dob: String) async throws -> ULIPDLResponse {
        do {
            return try await network.authenticatedPost(
                endpoint: ULIPEndpoints.dlDetails,
                body: ULIPDLRequest(dlNumber: dlNumber, dob: dob),
                responseType: ULIPDLResponse.self
            )
        } catch ULIPNetworkError.tokenExpired {
            try await auth.refreshToken()
            return try await network.authenticatedPost(
                endpoint: ULIPEndpoints.dlDetails,
                body: ULIPDLRequest(dlNumber: dlNumber, dob: dob),
                responseType: ULIPDLResponse.self
            )
        }
    }
}
