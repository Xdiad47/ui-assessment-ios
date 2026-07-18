import Foundation

final class ULIPDLService {
    static let shared = ULIPDLService()

    private init() {}

    // dob format expected by ULIP: "YYYY-MM-DD"
    func getDLDetails(dlNumber: String, dob: String) async throws -> ULIPDLResponse {
        try await ULIPGateway.post(
            endpoint: ULIPEndpoints.dlDetails,
            body: ULIPDLRequest(dlNumber: dlNumber, dob: dob)
        )
    }
}
