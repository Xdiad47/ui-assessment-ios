import Foundation

struct ServiceItem: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
}

struct PopularItem: Identifiable {
    let id = UUID()
    let type: PopularItemType
}

enum PopularItemType {
    case banner(tag: String, title: String, subtitle: String, buttonText: String, backgroundImage: String)
    case info(title: String, description: String, price: String, iconName: String)
}
