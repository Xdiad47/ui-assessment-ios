import Foundation
import Combine
import CoreLocation

struct EVChargingStation: Identifiable {
    let id = UUID()
    let name: String
    let distanceKm: Double
    let isAvailable: Bool
    let rating: Double      // 0 = not provided by API; UI hides badge when 0
    let address: String
    let lat: Double?
    let lng: Double?
}

final class EVChargeViewModel: NSObject, ObservableObject {
    @Published var searchText: String = ""
    @Published var stations: [EVChargingStation] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func startFetchingLocation() {
        guard !isLoading && stations.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        locationManager.requestLocation()
    }

    var filteredStations: [EVChargingStation] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return stations }
        return stations.filter {
            $0.name.localizedCaseInsensitiveContains(q) ||
            $0.address.localizedCaseInsensitiveContains(q)
        }
    }

    // MARK: - API call

    private func fetchStations(lat: Double, lng: Double) {
        Task { @MainActor in
            do {
                let latStr = String(format: "%.6f", lat)
                let lngStr = String(format: "%.6f", lng)
                let envelope = try await ULIPEVChargeService.shared.getNearbyStations(lat: latStr, long: lngStr)

                guard let items = envelope.response?.first?.response, !items.isEmpty else {
                    errorMessage = "No charging stations found nearby."
                    isLoading = false
                    return
                }

                let userCoord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                stations = items.compactMap { item -> EVChargingStation? in
                    guard let stLat = item.lat, let stLng = item.lng else { return nil }
                    let dist = haversine(from: userCoord,
                                        to: CLLocationCoordinate2D(latitude: stLat, longitude: stLng))
                    let raw = item.stationName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let name = raw.isEmpty ? "EV Charging Station" : raw
                    return EVChargingStation(
                        name: name,
                        distanceKm: dist,
                        isAvailable: true,
                        rating: 0,
                        address: item.address ?? "Address unavailable",
                        lat: stLat,
                        lng: stLng
                    )
                }
                .sorted { $0.distanceKm < $1.distanceKm }

            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    // MARK: - Haversine distance (km)

    private func haversine(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let R = 6371.0
        let dLat = (to.latitude  - from.latitude)  * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude   * .pi / 180
        let a = sin(dLat/2)*sin(dLat/2) + cos(lat1)*cos(lat2)*sin(dLon/2)*sin(dLon/2)
        return R * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}

// MARK: - CLLocationManagerDelegate

extension EVChargeViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        fetchStations(lat: loc.coordinate.latitude, lng: loc.coordinate.longitude)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Could not get your location. Please try again."
            self.isLoading = false
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }
}
