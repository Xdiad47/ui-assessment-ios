import Foundation
import Combine

struct AddressItem: Identifiable {
    let id = UUID()
    let title: String
    let phoneNumber: String
    let isDefault: Bool
}

class MyAddressViewModel: ObservableObject {
    let pageTitle: String = "My Account"
    let addressesTitle: String = "My Adderesses"

    let addresses: [AddressItem] = [
        AddressItem(
            title: "At - Saint road, New Delhi",
            phoneNumber: "9058956588",
            isDefault: true
        )
    ]
}
