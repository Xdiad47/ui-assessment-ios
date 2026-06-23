import Foundation
import Combine
import SwiftUI

class RTOServicesViewModel: ObservableObject {
    @Published var selectedLocation: String
    @Published var selectedService: String
    @Published var selectedType: String
    
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
        self.selectedType = selectedType
    }
}
