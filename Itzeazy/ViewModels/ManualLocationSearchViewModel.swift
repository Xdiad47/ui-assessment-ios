import Foundation
import MapKit
import Combine

/// Backs the "Enter Location Manually" screen — free-text place search with
/// autocomplete via MapKit (no API key, no location permission needed), then
/// resolves the picked suggestion down to a coordinate for the EV Charge
/// station lookup.
@MainActor
final class ManualLocationSearchViewModel: NSObject, ObservableObject {
    @Published var query: String = "" {
        didSet { completer.queryFragment = query }
    }
    @Published private(set) var suggestions: [MKLocalSearchCompletion] = []
    @Published var isResolving: Bool = false
    @Published var errorMessage: String? = nil

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func resolveCoordinate(for suggestion: MKLocalSearchCompletion, onResolved: @escaping (CLLocationCoordinate2D) -> Void) {
        isResolving = true
        errorMessage = nil

        let request = MKLocalSearch.Request(completion: suggestion)
        MKLocalSearch(request: request).start { [weak self] response, _ in
            Task { @MainActor in
                self?.isResolving = false
                guard let coordinate = response?.mapItems.first?.placemark.coordinate else {
                    self?.errorMessage = "Couldn't find that location. Please try another search."
                    return
                }
                onResolved(coordinate)
            }
        }
    }
}

extension ManualLocationSearchViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        errorMessage = "Search failed. Please try again."
    }
}
