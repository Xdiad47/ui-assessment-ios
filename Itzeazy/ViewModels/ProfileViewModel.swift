import Foundation
import Combine

struct ProfileMenuItem: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
}

class ProfileViewModel: ObservableObject {
    let primarySections: [[ProfileMenuItem]] = [
        [
            ProfileMenuItem(title: "Overview", iconName: "square.grid.2x2"),
            ProfileMenuItem(title: "My Orders", iconName: "bag"),
            ProfileMenuItem(title: "Payment", iconName: "creditcard"),
            ProfileMenuItem(title: "My Address", iconName: "person")
        ],
        [
            ProfileMenuItem(title: "ItzEazy Wallet", iconName: "wallet.pass"),
            ProfileMenuItem(title: "Video Tutorials", iconName: "video"),
            ProfileMenuItem(title: "FAQs", iconName: "questionmark.square"),
            ProfileMenuItem(title: "Help & Support", iconName: "questionmark.circle")
        ],
        [
            ProfileMenuItem(title: "Shipping Details", iconName: "box.truck"),
            ProfileMenuItem(title: "Return Policy", iconName: "arrow.uturn.backward"),
            ProfileMenuItem(title: "Privacy Policy", iconName: "doc.badge.gearshape"),
            ProfileMenuItem(title: "Terms and Conditions", iconName: "doc.text")
        ]
    ]

    let socialItems: [ProfileMenuItem] = [
        ProfileMenuItem(title: "Instagram", iconName: "camera.circle.fill"),
        ProfileMenuItem(title: "Facebook", iconName: "f.circle.fill"),
        ProfileMenuItem(title: "Whatsapp", iconName: "message.circle.fill"),
        ProfileMenuItem(title: "Youtube", iconName: "play.circle.fill"),
        ProfileMenuItem(title: "LinkedIn", iconName: "link.circle.fill")
    ]
}
