import Foundation

final class ULIPChassisService {
    static let shared = ULIPChassisService()

    private init() {}

    func getChassisDetails(chassisNumber: String) async throws -> ULIPVehicleRCResponse {
        try await ULIPGateway.post(
            endpoint: ULIPEndpoints.chassisRC,
            body: ULIPChassisRCRequest(chassisNumber: chassisNumber)
        )
    }
}
