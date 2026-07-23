import SwiftUI

enum Tab {
    case home
    case orders
    case call
    case profile
}

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @State private var homeNavID = UUID()
    @EnvironmentObject private var tabBarState: TabBarState
    @StateObject private var authGate = AuthGateController()
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    // Home's hamburger drawer lives at this top level (not nested inside HomeView) so it
    // paints above the custom tab bar — same reasoning as the Android fix: a drawer nested
    // inside the switch-selected content can never out-rank the tab bar's own ZStack layer.
    @State private var showHomeDrawer = false
    @State private var homeDrawerDestination: HomeDrawerDestination? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content
            Group {
                switch selectedTab {
                case .home:
                    NavigationView {
                        HomeView(onMenuTap: { withAnimation(.easeInOut(duration: 0.2)) { showHomeDrawer = true } })
                            .id(homeNavID)
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationBarHidden(true)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                case .orders:
                    NavigationView {
                        MyOrdersView(onBackToHome: { selectedTab = .home })
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationBarHidden(true)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                case .call:
                    NavigationView {
                        CallScreen(onBackToHome: { selectedTab = .home })
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationBarHidden(true)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                case .profile:
                    NavigationView {
                        ProfileView {
                            selectedTab = .home
                            homeNavID = UUID()
                        }
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationBarHidden(true)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Card stack: red base card + white tab bar on top
            if !tabBarState.isHidden { ZStack(alignment: .bottom) {
                // White fill — covers bottom safe area gap
                Color.white
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)

                // Red card — peeks below white bar
                Rectangle()
                    .fill(Color(red: 0.718, green: 0.718, blue: 0.718))
                    .frame(maxWidth: .infinity)
                    .frame(height: 82)
                    .clipShape(RoundedCorner(radius: 34, corners: [.topLeft, .topRight]))
                    .padding(.bottom, 2)

                // White tab bar on top
                CustomTabBar(selectedTab: $selectedTab) { tappedTab in
                    switch tappedTab {
                    case .home:
                        homeNavID = UUID()
                        selectedTab = .home
                    case .orders, .profile:
                        // My Orders and Profile hold personal account data — require auth.
                        guard authGate.requireAuth() else { return }
                        selectedTab = tappedTab
                    case .call:
                        selectedTab = .call
                    }
                }
                .padding(.bottom, 1)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { tabBarState.height = geo.size.height }
                            .onChange(of: geo.size.height) { tabBarState.height = $0 }
                    }
                )
            } } // end ZStack + if

            if authGate.isPopupPresented {
                AuthGatePopupView(
                    onLogin: { authGate.chooseLogin() },
                    onCreateAccount: { authGate.chooseCreateAccount() },
                    onDismiss: { authGate.dismissPopup() }
                )
                .transition(.opacity)
                .zIndex(10)
            }

            // Home hamburger drawer — topmost layer so it covers the custom tab bar too.
            if showHomeDrawer {
                ZStack(alignment: .leading) {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { showHomeDrawer = false } }
                        .transition(.opacity)

                    HamburgerDrawerView(
                        appVersion: "\(Bundle.main.shortVersion).\(Bundle.main.buildNumber)",
                        isLoggedIn: isLoggedIn,
                        onItemTap: { destination in
                            showHomeDrawer = false
                            homeDrawerDestination = destination
                        },
                        onLogoutTap: {
                            showHomeDrawer = false
                            isLoggedIn = false
                        },
                        onCloseTap: { withAnimation(.easeInOut(duration: 0.2)) { showHomeDrawer = false } }
                    )
                    .frame(width: UIScreen.main.bounds.width * 0.8)
                    .transition(.move(edge: .leading))
                }
                .zIndex(20)
            }
        }
        .environmentObject(authGate)
        .animation(.easeInOut(duration: 0.2), value: authGate.isPopupPresented)
        .fullScreenCover(item: $authGate.authFlow) { destination in
            switch destination {
            case .login:
                LoginView()
            case .createAccount:
                LoginView(startAtCreateAccount: true)
            }
        }
        .fullScreenCover(item: $homeDrawerDestination) { destination in
            switch destination {
            case .myOrders:
                MyOrdersView(onBackToHome: { homeDrawerDestination = nil })
            case .overview:
                OverviewView(onBackToHome: { homeDrawerDestination = nil })
            case .videoTutorials:
                VideoTutorialsView()
            case .faqs:
                FAQsView()
            case .helpSupport:
                HelpSupportView()
            case .privacyPolicy:
                CitizenServicesWebView(
                    url: "https://itzeazy.in/privacy-policy",
                    title: "Privacy Policy",
                    onBack: { homeDrawerDestination = nil }
                )
            case .terms:
                CitizenServicesWebView(
                    url: "https://itzeazy.in/terms",
                    title: "Terms and Conditions",
                    onBack: { homeDrawerDestination = nil }
                )
            }
        }
        .onChange(of: isLoggedIn) { _, loggedIn in
            if loggedIn {
                authGate.authFlow = nil
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    var onTabTapped: (Tab) -> Void

    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(imageName: "house.fill",   title: "Home",    tab: .home,    isAsset: false, selectedTab: $selectedTab, onTabTapped: onTabTapped)
            TabBarButton(imageName: "orders_icon",  title: "My Orders",  tab: .orders,  isAsset: true,  selectedTab: $selectedTab, onTabTapped: onTabTapped)
            TabBarButton(imageName: "call_icon",    title: "Call",    tab: .call,    isAsset: true,  selectedTab: $selectedTab, onTabTapped: onTabTapped)
            TabBarButton(imageName: "profile_icon", title: "Profile", tab: .profile, isAsset: true,  selectedTab: $selectedTab, onTabTapped: onTabTapped)
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedCorner(radius: 32, corners: [.topLeft, .topRight]))
        .overlay(
            RoundedCorner(radius: 32, corners: [.topLeft, .topRight])
                .stroke(Color(red: 0.72, green: 0.72, blue: 0.72), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 30)
    }
}

struct TabBarButton: View {
    var imageName: String
    var title: String
    var tab: Tab
    var isAsset: Bool
    @Binding var selectedTab: Tab
    var onTabTapped: (Tab) -> Void

    var isSelected: Bool { selectedTab == tab }

    var body: some View {
        Button(action: { onTabTapped(tab) }) {
            VStack(spacing: 5) {
                if isAsset {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .colorMultiply(isSelected ? .red : Color(red: 0.58, green: 0.64, blue: 0.72))
                } else {
                    Image(systemName: imageName)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .red : Color(red: 0.58, green: 0.64, blue: 0.72))
                }

                Text(title)
                    .font(Font.custom("PlusJakartaSans-Regular", size: 10))
                    .foregroundColor(isSelected ? .red : Color(red: 0.58, green: 0.64, blue: 0.72))

                Rectangle()
                    .fill(isSelected ? Color.red : Color.clear)
                    .frame(width: 60, height: 4)
                    .cornerRadius(8, corners: [.topLeft, .topRight])
            }
            .frame(maxWidth: .infinity)
        }
    }
}

//struct MainTabView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainTabView()
//    }
//}
