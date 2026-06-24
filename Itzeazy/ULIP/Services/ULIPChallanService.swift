import Foundation

final class ULIPChallanService {
    static let shared = ULIPChallanService()

    private let network = ULIPNetworkService.shared
    private let auth    = ULIPAuthService.shared

    private init() {}

    func getChallanDetails(vehicleNumber: String) async throws -> ULIPChallanResponse {
        try await auth.ensureValidToken()
        return try await fetchChallanDetails(vehicleNumber: vehicleNumber)
    }

    // MARK: - Private

    private func fetchChallanDetails(vehicleNumber: String) async throws -> ULIPChallanResponse {
        do {
            return try await network.authenticatedPost(
                endpoint: ULIPEndpoints.challan,
                body: ULIPChallanRequest(vehicleNumber: vehicleNumber),
                responseType: ULIPChallanResponse.self
            )
        } catch ULIPNetworkError.tokenExpired {
            try await auth.refreshToken()
            return try await network.authenticatedPost(
                endpoint: ULIPEndpoints.challan,
                body: ULIPChallanRequest(vehicleNumber: vehicleNumber),
                responseType: ULIPChallanResponse.self
            )
        }
    }
}
