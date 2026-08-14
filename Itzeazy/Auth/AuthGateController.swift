import SwiftUI
import Combine

/// Identifies which auth screen the gate should present.
enum AuthGateDestination: Identifiable {
    case login
    case createAccount

    var id: Self { self }
}

/// Central gatekeeper for actions that require an authenticated user: wallet, orders, profile,
/// the actual RTO/Visa "Apply Now" order submission (a real transaction, not just browsing), and
/// all ULIP-connected utility lookups (Vehicle/Challan/DL/TS Vehicle/TS DL Info, EV Charge) — ULIP
/// calls require a valid session token and there's no guest/anonymous token yet, so these are
/// gated even though they're not account data per se. The browse-only citizen service web pages
/// (Marriage Reg, Birth Cert, Passport, Pan Card, Road Tax, LL Q&B/Mock, and the Home hero "Get
/// Started") are still guest-accessible — those never call into this gate; for a guest they open
/// the plain public itzeazy.in page directly instead of going through the SSO token exchange,
/// which does require login (see WebLoginViewModel.openDirectly / .generateToken).
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

    /// Read-only check that never triggers the popup — for call sites that branch to different
    /// (non-blocking) guest behavior instead of gating, rather than bailing out entirely.
    var isLoggedIn: Bool { UserDefaults.standard.bool(forKey: "isLoggedIn") }

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
