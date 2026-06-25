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

    let webItems: [ServiceWebItem] = [
        ServiceWebItem(
            label: "Passport",
            icon:  "passport",
            url:   "https://itzeazy.in/location/passport"
        ),
        ServiceWebItem(
            label: "Marriage\nReg.",
            icon:  "marriage_reg",
            url:   "https://itzeazy.in/location/marriage-registration"
        ),
        ServiceWebItem(
            label: "Birth Cert.",
            icon:  "birth_certi",
            url:   "https://itzeazy.in/location/birth-certificate"
        ),
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
        ServiceWebItem(
            label: "Pan Card",
            icon:  "pan_card",
            url:   "https://itzeazy.in/location/pan-card"
        ),
    ]
}
