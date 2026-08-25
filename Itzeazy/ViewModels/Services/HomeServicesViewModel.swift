import Foundation
import Combine

// MARK: - ServiceWebItem
// Describes a single home-screen service button that opens a WebView.

struct ServiceWebItem: Identifiable {
    let id    = UUID()
    let label: String      // display label (matches HomeServicesGridView tuple)
    let icon : String      // asset image name
    let url  : String      // hard-coded URL to open
}

// MARK: - HomeServicesViewModel
// ViewModel for the "Services We Provide" section on HomeView.
// Single source of truth for all service-grid buttons that open a WebView.

final class HomeServicesViewModel: ObservableObject {

    // Passport, Marriage Reg., Birth Cert., and Pan Card moved to native intro + detail
    // screens (see HomeServicesGridView.serviceCell) — no longer routed through this list.
    // IT Returns/Affidavit/POI-FRRO were removed from the Services grid entirely (matching
    // Android's HomeRepository.getServices(), which no longer lists them) — no items currently
    // route through this fallback, but it stays in place for any future WebView-backed service.
    let webItems: [ServiceWebItem] = []
}
