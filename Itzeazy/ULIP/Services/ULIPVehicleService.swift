import Foundation

final class ULIPVehicleService {
    static let shared = ULIPVehicleService()

    private let network = ULIPNetworkService.shared
    private let auth    = ULIPAuthService.shared

    private init() {}

    func getVehicleDetails(vehicleNumber: String) async throws -> ULIPVehicleRCResponse {
        try await auth.ensureValidToken()
        return try await fetchVehicleDetails(vehicleNumber: vehicleNumber)
    }

    // MARK: - Private

    private func fetchVehicleDetails(vehicleNumber: String) async throws -> ULIPVehicleRCResponse {
        do {
            return try await network.authenticatedPost(
                endpoint: ULIPEndpoints.vehicleRC,
                body: ULIPVehicleRCRequest(vehicleNumber: vehicleNumber),
                responseType: ULIPVehicleRCResponse.self
            )
        } catch ULIPNetworkError.tokenExpired {
            // Token expired mid-session — refresh once and retry
            try await auth.refreshToken()
            return try await network.authenticatedPost(
                endpoint: ULIPEndpoints.vehicleRC,
                body: ULIPVehicleRCRequest(vehicleNumber: vehicleNumber),
                responseType: ULIPVehicleRCResponse.self
            )
        }
    }
}
