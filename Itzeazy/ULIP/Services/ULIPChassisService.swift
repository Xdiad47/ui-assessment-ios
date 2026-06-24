import Foundation

final class ULIPChassisService {
    static let shared = ULIPChassisService()

    private let network = ULIPNetworkService.shared
    private let auth    = ULIPAuthService.shared

    private init() {}

    func getChassisDetails(chassisNumber: String) async throws -> ULIPVehicleRCResponse {
        try await auth.ensureValidToken()
        return try await fetchChassisDetails(chassisNumber: chassisNumber)
    }

    private func fetchChassisDetails(chassisNumber: String) async throws -> ULIPVehicleRCResponse {
        do {
            return try await network.authenticatedPost(
                endpoint: ULIPEndpoints.chassisRC,
                body: ULIPChassisRCRequest(chassisNumber: chassisNumber),
                responseType: ULIPVehicleRCResponse.self
            )
        } catch ULIPNetworkError.tokenExpired {
            try await auth.refreshToken()
            return try await network.authenticatedPost(
                endpoint: ULIPEndpoints.chassisRC,
                body: ULIPChassisRCRequest(chassisNumber: chassisNumber),
                responseType: ULIPVehicleRCResponse.self
            )
        }
    }
}
