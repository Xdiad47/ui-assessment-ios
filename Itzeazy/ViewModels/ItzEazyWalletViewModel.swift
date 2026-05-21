import Foundation
import Combine

struct WalletFeatureItem: Identifiable {
    let id = UUID()
    let title: String
    let descriptionLines: [String]
    let iconName: String
}

class ItzEazyWalletViewModel: ObservableObject {
    @Published var walletTitle: String = "ItzEazy Wallet"
    @Published var balanceText: String = "₹ 0"

    let whatsNewItems: [WalletFeatureItem] = [
        WalletFeatureItem(
            title: "No limits on how much you can redeem!",
            descriptionLines: [
                "You can redeem 100% of the",
                "balance on placing an order",
                "available in your wallet."
            ],
            iconName: "wallets_no_limit"
        ),
        WalletFeatureItem(
            title: "Earn on all your orders!",
            descriptionLines: [
                "Earn points on all the orders you",
                "place. Get upto 5% on each order."
            ],
            iconName: "wallets_email"
        ),
        WalletFeatureItem(
            title: "Points that never expire!",
            descriptionLines: [
                "Points you earn will always stay in",
                "your wallet forever."
            ],
            iconName: "wallets_points_never_expire"
        )
    ]
}
