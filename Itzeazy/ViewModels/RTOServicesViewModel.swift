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

    // RTO sub-services — slugs match itzeazy.in URL structure
    let rtoSubServices: [SubServiceOption] = [
        SubServiceOption(display: "New Driving License",           slug: "driving-license-agents-consultants"),
        SubServiceOption(display: "Driving License Renewal",       slug: "driving-license-renewal-agents-consultants"),
        SubServiceOption(display: "NOC",                           slug: "noc-for-car-bike"),
        SubServiceOption(display: "Duplicate RC",                  slug: "duplicate-rc-agents-consultants"),
        SubServiceOption(display: "Duplicate Driving License",     slug: "duplicate-driving-license-agents-consultants"),
        SubServiceOption(display: "HP Deletion",                   slug: "hypothecation-deletion-termination-removal-hpt-of-vehicle-car-bike"),
        SubServiceOption(display: "Ownership Transfer",            slug: "ownership-transfer-change-of-vehicle-car-bike"),
        SubServiceOption(display: "International Driving License", slug: "international-driving-license-agents-consultants"),
        SubServiceOption(display: "Re Registration",               slug: "re-registration-agents-consultants")
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

    // MARK: - URL Builder
    // Pattern: https://itzeazy.in/{city-slug}/rto/{subService-slug}-in-{city-slug}

    func buildUrl() -> String? {
        guard let subService = selectedSubService, !selectedLocation.isEmpty else { return nil }
        let citySlug = selectedLocation.lowercased()
            .replacingOccurrences(of: " ", with: "-")
        return "https://itzeazy.in/\(citySlug)/rto/\(subService.slug)-in-\(citySlug)"
    }
}
