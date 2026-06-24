import Foundation

final class ULIPTGVehicleService {
    static let shared = ULIPTGVehicleService()

    private let network = ULIPNetworkService.shared
    private let auth    = ULIPAuthService.shared

    private init() {}

    func getTGVehicleDetails(vehicleNumber: String) async throws -> ULIPTGVehicleResponse {
        try await auth.ensureValidToken()
        return try await fetchDetails(vehicleNumber: vehicleNumber)
    }

    private func fetchDetails(vehicleNumber: String) async throws -> ULIPTGVehicleResponse {
        do {
            return try await network.authenticatedPost(
                endpoint: ULIPEndpoints.tgVehicle,
                body: ULIPTGVehicleRequest(vehicleNumber: vehicleNumber),
                responseType: ULIPTGVehicleResponse.self
            )
        } catch ULIPNetworkError.tokenExpired {
            try await auth.refreshToken()
            return try await network.authenticatedPost(
                endpoint: ULIPEndpoints.tgVehicle,
                body: ULIPTGVehicleRequest(vehicleNumber: vehicleNumber),
                responseType: ULIPTGVehicleResponse.self
            )
        }
    }
}
