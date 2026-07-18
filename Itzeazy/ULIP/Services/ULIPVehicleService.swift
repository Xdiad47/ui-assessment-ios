import Foundation

final class ULIPVehicleService {
    static let shared = ULIPVehicleService()

    private init() {}

    func getVehicleDetails(vehicleNumber: String) async throws -> ULIPVehicleRCResponse {
        try await ULIPGateway.post(
            endpoint: ULIPEndpoints.vehicleRC,
            body: ULIPVehicleRCRequest(vehicleNumber: vehicleNumber)
        )
    }
}
