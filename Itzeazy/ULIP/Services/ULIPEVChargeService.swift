import Foundation

final class ULIPEVChargeService {
    static let shared = ULIPEVChargeService()

    private init() {}

    func getNearbyStations(lat: String, long: String) async throws -> ULIPEVChargeResponse {
        try await ULIPGateway.post(
            endpoint: ULIPEndpoints.evyatra,
            body: ULIPEVChargeRequest(stateId: "", lat: lat, long: long)
        )
    }
}
