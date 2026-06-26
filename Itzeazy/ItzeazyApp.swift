import SwiftUI

@main
struct ItzeazyApp: App {
    @State private var showSplash = true
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @StateObject private var tabBarState = TabBarState()
    @StateObject private var userSession = UserSessionViewModel()

    init() {
        UIScrollView.appearance().keyboardDismissMode = .onDrag
    }

    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashScreenView {
                    showSplash = false
                }
            } else if !hasSeenOnboarding {
                OnboardingView()
            } else if !isLoggedIn {
                LoginView()
            } else {
                MainTabView()
                    .environmentObject(tabBarState)
                    .environmentObject(userSession)
                    .task { userSession.fetchUserProfile() }
            }
        }
        .onChange(of: isLoggedIn) { _, loggedIn in
            if loggedIn {
                userSession.fetchUserProfile()
            } else {
                userSession.clearUser()
            }
        }
    }
}
