import Foundation
import Combine

struct EVChargingStation: Identifiable {
    let id = UUID()
    let name: String
    let rating: Double
    let isAvailable: Bool
    let address: String
}

final class EVChargeViewModel: ObservableObject {
    @Published var searchText: String = ""

    let stations: [EVChargingStation] = [
        EVChargingStation(name: "ChargeGrid Station",      rating: 4.5, isAvailable: true,  address: "45 MG Road, Near Cubbon Park, Bengaluru, Karnataka 560001"),
        EVChargingStation(name: "SuperCharge Hub Pro",     rating: 4.5, isAvailable: true,  address: "78 Park Street, Opposite St. Xavier's College, Kolkata, West Bengal 700016"),
        EVChargingStation(name: "EcoVolt Station North",   rating: 4.3, isAvailable: true,  address: "21 Anna Salai, Near LIC Building, Chennai, Tamil Nadu 600002"),
        EVChargingStation(name: "Electro Station North",   rating: 4.5, isAvailable: true,  address: "45 MG Road, Near Cubbon Park, Bengaluru, Karnataka 560001"),
        EVChargingStation(name: "GreenCharge Point",       rating: 4.1, isAvailable: false, address: "12 Linking Road, Bandra West, Mumbai, Maharashtra 400050"),
        EVChargingStation(name: "Volt Express Hub",        rating: 4.7, isAvailable: true,  address: "8 Sector 18, Near Metro Gate 2, Noida, Uttar Pradesh 201301"),
        EVChargingStation(name: "SwiftCharge Central",     rating: 3.9, isAvailable: false, address: "33 Jubilee Hills Road No. 36, Hyderabad, Telangana 500033"),
        EVChargingStation(name: "PowerPulse Station",      rating: 4.6, isAvailable: true,  address: "5 SG Highway, Near ISKCON Temple, Ahmedabad, Gujarat 380015"),
    ]

    var filteredStations: [EVChargingStation] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return stations }
        return stations.filter {
            $0.name.localizedCaseInsensitiveContains(q) ||
            $0.address.localizedCaseInsensitiveContains(q)
        }
    }
}
