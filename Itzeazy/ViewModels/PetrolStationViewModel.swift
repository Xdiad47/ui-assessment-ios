import Foundation
import Combine
import CoreLocation
import UIKit

// MARK: - Model

struct PetrolStation: Identifiable {
    let id = UUID()
    let name: String
    let rating: Double
    let isAvailable: Bool
    let address: String
    let fuelTypes: [String]
}

// MARK: - List ViewModel

final class PetrolStationViewModel: ObservableObject {
    @Published var searchText: String = ""

    let stations: [PetrolStation] = [
        PetrolStation(name: "Indian Oil Station",      rating: 4.5, isAvailable: true,  address: "12 MG Road, Near Cubbon Park, Bengaluru, Karnataka 560001",           fuelTypes: ["Petrol", "Diesel"]),
        PetrolStation(name: "HP Fuel Centre",          rating: 4.3, isAvailable: true,  address: "78 Park Street, Kolkata, West Bengal 700016",                         fuelTypes: ["Petrol", "Diesel", "CNG"]),
        PetrolStation(name: "BPCL Pump Station",       rating: 4.6, isAvailable: true,  address: "21 Anna Salai, Near LIC Building, Chennai, Tamil Nadu 600002",         fuelTypes: ["Petrol", "Diesel"]),
        PetrolStation(name: "Shell Fuel Stop",         rating: 4.7, isAvailable: false, address: "5 Linking Road, Bandra West, Mumbai, Maharashtra 400050",              fuelTypes: ["Petrol", "Diesel"]),
        PetrolStation(name: "Reliance Petro Point",    rating: 4.1, isAvailable: true,  address: "8 Sector 18, Near Metro Gate 2, Noida, Uttar Pradesh 201301",          fuelTypes: ["Petrol", "CNG"]),
        PetrolStation(name: "Essar Oil Station",       rating: 3.9, isAvailable: true,  address: "33 Jubilee Hills Road No. 36, Hyderabad, Telangana 500033",            fuelTypes: ["Petrol", "Diesel"]),
        PetrolStation(name: "HP Green Fuel Hub",       rating: 4.4, isAvailable: false, address: "5 SG Highway, Near ISKCON Temple, Ahmedabad, Gujarat 380015",          fuelTypes: ["Petrol", "Diesel", "CNG"]),
        PetrolStation(name: "Indian Oil Xtra Care",    rating: 4.8, isAvailable: true,  address: "44 Ring Road, Lajpat Nagar, New Delhi 110024",                        fuelTypes: ["Petrol", "Diesel"]),
    ]

    var filteredStations: [PetrolStation] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return stations }
        return stations.filter {
            $0.name.localizedCaseInsensitiveContains(q) ||
            $0.address.localizedCaseInsensitiveContains(q)
        }
    }
}

// MARK: - Permission ViewModel

final class PetrolLocationPermissionViewModel: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus

    private let locationManager = CLLocationManager()

    override init() {
        if #available(iOS 14.0, *) {
            authorizationStatus = locationManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
    }

    func requestLocationAccess() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            guard let url = URL(string: UIApplication.openSettingsURLString),
                  UIApplication.shared.canOpenURL(url) else { return }
            UIApplication.shared.open(url)
        default:
            break
        }
    }

    private func updateStatus(for manager: CLLocationManager) {
        if #available(iOS 14.0, *) {
            authorizationStatus = manager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
    }
}

extension PetrolLocationPermissionViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateStatus(for: manager)
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
    }
}
