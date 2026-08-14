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
    let webItems: [ServiceWebItem] = [
        ServiceWebItem(
            label: "IT Returns",
            icon:  "it_returns",
            url:   "https://itzeazy.in/income-tax"
        ),
        ServiceWebItem(
            label: "Affidavit",
            icon:  "affidavit",
            url:   "https://itzeazy.in/affadivate"   // intentional typo — matches Android source
        ),
        ServiceWebItem(
            label: "POI/FRRO",
            icon:  "poi_frro",
            url:   "https://itzeazy.in/poi-ffro"     // intentional typo — matches Android source
        ),
    ]
}
