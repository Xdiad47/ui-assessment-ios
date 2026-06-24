import Foundation

final class ULIPEngineService {
    static let shared = ULIPEngineService()

    private let network = ULIPNetworkService.shared
    private let auth    = ULIPAuthService.shared

    private init() {}

    func getEngineDetails(engineNumber: String) async throws -> ULIPVehicleRCResponse {
        try await auth.ensureValidToken()
        return try await fetchEngineDetails(engineNumber: engineNumber)
    }

    private func fetchEngineDetails(engineNumber: String) async throws -> ULIPVehicleRCResponse {
        do {
            return try await network.authenticatedPost(
                endpoint: ULIPEndpoints.engineRC,
                body: ULIPEngineRCRequest(engineNumber: engineNumber),
                responseType: ULIPVehicleRCResponse.self
            )
        } catch ULIPNetworkError.tokenExpired {
            try await auth.refreshToken()
            return try await network.authenticatedPost(
                endpoint: ULIPEndpoints.engineRC,
                body: ULIPEngineRCRequest(engineNumber: engineNumber),
                responseType: ULIPVehicleRCResponse.self
            )
        }
    }
}
