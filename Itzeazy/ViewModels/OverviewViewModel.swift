import Foundation
import Combine

struct OverviewCardItem: Identifiable {
    let id = UUID()
    let title: String
    let detailLines: [String]
    let iconName: String
}

class OverviewViewModel: ObservableObject {
    @Published var welcomeName: String = "amar patil"

    let cards: [OverviewCardItem] = [
        OverviewCardItem(
            title: "My Order",
            detailLines: ["Track your orders and", "related order details"],
            iconName: "cart"
        ),
        OverviewCardItem(
            title: "Payments",
            detailLines: ["Payments can be made", "for orders"],
            iconName: "creditcard"
        ),
        OverviewCardItem(
            title: "Help & Support",
            detailLines: ["You can reach us by", "dropping your", "concerns"],
            iconName: "headphones"
        ),
        OverviewCardItem(
            title: "Documents\nRequired",
            detailLines: ["Important forms that", "may be necessary"],
            iconName: "arrow.down.doc"
        )
    ]
}
