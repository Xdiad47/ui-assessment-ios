import Foundation

final class ULIPTGDLService {
    static let shared = ULIPTGDLService()

    private init() {}

    func getTGDLDetails(dlNumber: String) async throws -> ULIPTGDLResponse {
        try await ULIPGateway.post(
            endpoint: ULIPEndpoints.tgDL,
            body: ULIPTGDLRequest(dlNumber: dlNumber)
        )
    }
}
