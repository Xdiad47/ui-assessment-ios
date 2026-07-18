import Foundation

final class ULIPTGVehicleService {
    static let shared = ULIPTGVehicleService()

    private init() {}

    func getTGVehicleDetails(vehicleNumber: String) async throws -> ULIPTGVehicleResponse {
        try await ULIPGateway.post(
            endpoint: ULIPEndpoints.tgVehicle,
            body: ULIPTGVehicleRequest(vehicleNumber: vehicleNumber)
        )
    }
}
