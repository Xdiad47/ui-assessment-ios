import SwiftUI
import Combine

/// Identifies which auth screen the gate should present.
enum AuthGateDestination: Identifiable {
    case login
    case createAccount

    var id: Self { self }
}

/// Central gatekeeper for actions that require an authenticated user (wallet, orders, profile,
/// citizen-service web checkout). ULIP-connected utility lookups (vehicle/DL/challan info,
/// EV/petrol locators, RTO & Visa info) are guest-accessible and never call into this gate.
@MainActor
final class AuthGateController: ObservableObject {
    @Published var isPopupPresented = false
    @Published var authFlow: AuthGateDestination?

    /// Returns true if the caller may proceed. If the user isn't logged in, shows the
    /// login/register popup and returns false so the caller can bail out of its own action.
    @discardableResult
    func requireAuth() -> Bool {
        guard !UserDefaults.standard.bool(forKey: "isLoggedIn") else { return true }
        isPopupPresented = true
        return false
    }

    func chooseLogin() {
        isPopupPresented = false
        authFlow = .login
    }

    func chooseCreateAccount() {
        isPopupPresented = false
        authFlow = .createAccount
    }

    func dismissPopup() {
        isPopupPresented = false
    }
}
