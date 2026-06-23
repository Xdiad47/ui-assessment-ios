import Foundation
import Combine

final class RTOServiceInitialViewModel: ObservableObject {
    let locations = [
        "Bangalore",
        "Chennai",
        "Delhi",
        "Faridabad",
        "Ghaziabad",
        "Gurgaon",
        "Hyderabad",
        "Jamshedpur",
        "Noida",
        "Mumbai",
        "Pune",
        "Ranchi"
    ]

    @Published var selectedLocation: String = ""

    var hasSelectedLocation: Bool {
        !selectedLocation.isEmpty
    }
}
