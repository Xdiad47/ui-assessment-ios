import Foundation

final class ULIPEngineService {
    static let shared = ULIPEngineService()

    private init() {}

    func getEngineDetails(engineNumber: String) async throws -> ULIPVehicleRCResponse {
        try await ULIPGateway.post(
            endpoint: ULIPEndpoints.engineRC,
            body: ULIPEngineRCRequest(engineNumber: engineNumber)
        )
    }
}
