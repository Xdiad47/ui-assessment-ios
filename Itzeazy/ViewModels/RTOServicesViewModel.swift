import Foundation
import Combine
import SwiftUI

class RTOServicesViewModel: ObservableObject {
    @Published var selectedLocation: String = ""
    @Published var selectedService: String = ""
    @Published var selectedType: String = ""
    
    @Published var rtoServices: [ServiceItem] = [
        ServiceItem(title: "Duplicate RC", iconName: "doc.on.doc"),
        ServiceItem(title: "HP Termination", iconName: "xmark.seal"),
        ServiceItem(title: "RC Transfer", iconName: "arrow.right.arrow.left"),
        ServiceItem(title: "Vehicle NOC", iconName: "doc.text.magnifyingglass"),
        ServiceItem(title: "Re-registration", iconName: "arrow.counterclockwise.circle"),
        ServiceItem(title: "New Reg.", iconName: "car"),
        ServiceItem(title: "New DL", iconName: "lanyardcard"),
        ServiceItem(title: "DL Renewal", iconName: "arrow.triangle.2.circlepath.circle"),
        ServiceItem(title: "Intl. DL", iconName: "globe"),
        ServiceItem(title: "Duplicate DL", iconName: "doc.on.doc.fill"),
        ServiceItem(title: "DL Extract", iconName: "doc.plaintext"),
        ServiceItem(title: "Vehicle Fitness", iconName: "checkmark.seal")
    ]
}
