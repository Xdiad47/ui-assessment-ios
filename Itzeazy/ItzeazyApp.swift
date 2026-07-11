import SwiftUI

extension Notification.Name {
    static let itzeazyUnauthorized = Notification.Name("itzeazy.unauthorizedAccess")
}

@main
struct ItzeazyApp: App {
    @State private var showSplash = true
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @StateObject private var tabBarState = TabBarState()
    @StateObject private var userSession = UserSessionViewModel()
    @State private var showSessionToast = false

    init() {
        UIScrollView.appearance().keyboardDismissMode = .onDrag
    }

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .bottom) {
                if showSplash {
                    SplashScreenView {
                        showSplash = false
                    }
                } else if !hasSeenOnboarding {
                    OnboardingView()
                } else {
                    // Login/registration is no longer a blocking gate — guests land on Home and
                    // only hit the AuthGatePopupView when they tap an action that needs an account.
                    MainTabView()
                        .environmentObject(tabBarState)
                        .environmentObject(userSession)
                        .task { userSession.fetchUserProfile() }
                }

                if showSessionToast {
                    ToastView(
                        icon: "lock.slash.fill",
                        message: "Your session has expired. Please sign in again."
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 48)
                    .zIndex(999)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSessionToast)
            .onChange(of: isLoggedIn) { _, loggedIn in
                if loggedIn {
                    userSession.fetchUserProfile()
                } else {
                    userSession.clearUser()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .itzeazyUnauthorized)) { _ in
                isLoggedIn = false
                showSessionToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showSessionToast = false
                }
            }
        }
    }
}
