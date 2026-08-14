import Foundation
import Combine
import SwiftUI

class RTOServicesViewModel: ObservableObject {
    @Published var selectedLocation: String
    @Published var selectedService: String
    // Type is now a structured sub-service selection (replaces free-text)
    @Published var selectedSubService: SubServiceOption? = nil

    // Legacy: kept for backward compat if needed elsewhere
    var selectedType: String { selectedSubService?.display ?? "" }

    // Display values must match RTOServiceDetailViewModel.redirectPath's exact switch
    // cases (and rtoServices below) — "Get Started" navigates straight into
    // RTOServiceDetailView(serviceTitle: subService.display), which uses that string
    // verbatim as both the documents-API `work` param and the redirect-URL lookup key.
    let rtoSubServices: [SubServiceOption] = [
        SubServiceOption(display: "New DL",          slug: "driving-license-agents-consultants"),
        SubServiceOption(display: "DL Renewal",      slug: "driving-license-renewal"),
        SubServiceOption(display: "Vehicle NOC",     slug: "noc-for-car-bike"),
        SubServiceOption(display: "Duplicate RC",    slug: "duplicate-rc-of-vehicle-car-bike"),
        SubServiceOption(display: "Duplicate DL",    slug: "duplicate-driving-license"),
        SubServiceOption(display: "HP Termination",  slug: "hypothecation-deletion-termination-removal-hpt-of-vehicle-car-bike"),
        SubServiceOption(display: "RC Transfer",     slug: "ownership-transfer-change-of-vehicle-car-bike"),
        SubServiceOption(display: "Intl. DL",        slug: "international-driving-license"),
        SubServiceOption(display: "Re-registration", slug: "re-registration-of-vehicle-car-bike")
    ]

    @Published var rtoServices: [ServiceItem] = [
        ServiceItem(title: "Duplicate RC",    iconName: "duplicate_rc",    isAsset: true),
        ServiceItem(title: "HP Termination",  iconName: "hp_termination",  isAsset: true),
        ServiceItem(title: "RC Transfer",     iconName: "rc_transfer",     isAsset: true),
        ServiceItem(title: "Vehicle NOC",     iconName: "vehicle_noc",     isAsset: true),
        ServiceItem(title: "Re-registration", iconName: "re_registration", isAsset: true),
        ServiceItem(title: "New Reg.",        iconName: "vehicle_noc",     isAsset: true),
        ServiceItem(title: "New DL",          iconName: "new_dl",          isAsset: true),
        ServiceItem(title: "DL Renewal",      iconName: "dl_renewal",      isAsset: true),
        ServiceItem(title: "Intl. DL",        iconName: "intl_dl",         isAsset: true),
        ServiceItem(title: "Duplicate DL",    iconName: "duplicate_dl",    isAsset: true),
        ServiceItem(title: "DL Extract",      iconName: "dl_extract",      isAsset: true),
        ServiceItem(title: "Vehicle Fitness", iconName: "vehicle_fitness", isAsset: true)
    ]

    init(
        selectedLocation: String = "",
        selectedService: String = "RTO",
        selectedType: String = ""
    ) {
        self.selectedLocation = selectedLocation
        self.selectedService = selectedService
    }

    // MARK: - Validation

    var isGetStartedEnabled: Bool {
        !selectedLocation.isEmpty && selectedSubService != nil
    }
}
