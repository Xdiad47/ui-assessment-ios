import Foundation

final class ULIPEVChargeService {
    static let shared = ULIPEVChargeService()

    private let network = ULIPNetworkService.shared
    private let auth    = ULIPAuthService.shared

    private init() {}

    func getNearbyStations(lat: String, long: String) async throws -> ULIPEVChargeResponse {
        try await auth.ensureValidToken()
        return try await fetchStations(lat: lat, long: long)
    }

    private func fetchStations(lat: String, long: String) async throws -> ULIPEVChargeResponse {
        do {
            return try await network.authenticatedPost(
                endpoint: ULIPEndpoints.evyatra,
                body: ULIPEVChargeRequest(stateId: "", lat: lat, long: long),
                responseType: ULIPEVChargeResponse.self
            )
        } catch ULIPNetworkError.tokenExpired {
            try await auth.refreshToken()
            return try await network.authenticatedPost(
                endpoint: ULIPEndpoints.evyatra,
                body: ULIPEVChargeRequest(stateId: "", lat: lat, long: long),
                responseType: ULIPEVChargeResponse.self
            )
        }
    }
}
