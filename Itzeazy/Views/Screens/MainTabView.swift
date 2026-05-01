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

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                        .id(homeNavID)
                case .orders:
                    NavigationView {
                        Text("Orders Screen")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(white: 0.98).edgesIgnoringSafeArea(.all))
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                case .call:
                    NavigationView {
                        Text("Call Screen")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(white: 0.98).edgesIgnoringSafeArea(.all))
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                case .profile:
                    NavigationView {
                        Text("Profile Screen")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(white: 0.98).edgesIgnoringSafeArea(.all))
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Tab bar — full width, attached to bottom
            CustomTabBar(selectedTab: $selectedTab) { tappedTab in
                if tappedTab == .home {
                    homeNavID = UUID()
                }
                selectedTab = tappedTab
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    var onTabTapped: (Tab) -> Void

    var body: some View {
        HStack(spacing: 42) {
            TabBarButton(imageName: "house.fill",    title: "HOME",    tab: .home,    selectedTab: $selectedTab, onTabTapped: onTabTapped)
            TabBarButton(imageName: "bag.fill",      title: "ORDERS",  tab: .orders,  selectedTab: $selectedTab, onTabTapped: onTabTapped)
            TabBarButton(imageName: "phone.fill",    title: "CALL",    tab: .call,    selectedTab: $selectedTab, onTabTapped: onTabTapped)
            TabBarButton(imageName: "person.fill",   title: "PROFILE", tab: .profile, selectedTab: $selectedTab, onTabTapped: onTabTapped)
        }
        .padding(EdgeInsets(top: 12, leading: 37, bottom: 32, trailing: 37))
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
    @Binding var selectedTab: Tab
    var onTabTapped: (Tab) -> Void

    var isSelected: Bool { selectedTab == tab }

    var body: some View {
        Button(action: { onTabTapped(tab) }) {
            VStack(spacing: 0) {
                Image(systemName: imageName)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .red : Color(red: 0.58, green: 0.64, blue: 0.72))

                Text(title)
                    .font(Font.custom("Plus Jakarta Sans", size: 10).weight(.bold))
                    .tracking(0.5)
                    .foregroundColor(isSelected ? .red : Color(red: 0.58, green: 0.64, blue: 0.72))
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
