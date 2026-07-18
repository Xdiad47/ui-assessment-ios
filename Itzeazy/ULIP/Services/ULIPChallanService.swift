import Foundation

final class ULIPChallanService {
    static let shared = ULIPChallanService()

    private init() {}

    func getChallanDetails(vehicleNumber: String) async throws -> ULIPChallanResponse {
        try await ULIPGateway.post(
            endpoint: ULIPEndpoints.challan,
            body: ULIPChallanRequest(vehicleNumber: vehicleNumber)
        )
    }
}
