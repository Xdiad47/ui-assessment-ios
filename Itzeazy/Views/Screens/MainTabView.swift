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
            
            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab) { tappedTab in
                if tappedTab == .home {
                    // Reset Home navigation stack to root whether already on Home or switching to it
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
        HStack(alignment: .top, spacing: 0) {
            TabBarButton(imageName: "house.fill",    title: "Home",    tab: .home,    selectedTab: $selectedTab, onTabTapped: onTabTapped)
            TabBarButton(imageName: "bag.fill",      title: "Orders",  tab: .orders,  selectedTab: $selectedTab, onTabTapped: onTabTapped)
            TabBarButton(imageName: "phone.fill",    title: "Call",    tab: .call,    selectedTab: $selectedTab, onTabTapped: onTabTapped)
            TabBarButton(imageName: "person.fill",   title: "Profile", tab: .profile, selectedTab: $selectedTab, onTabTapped: onTabTapped)
        }
        .padding(.horizontal, 26)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedCorner(radius: 32, corners: [.topLeft, .topRight]))
        .overlay(
            RoundedCorner(radius: 32, corners: [.topLeft, .topRight])
                .stroke(Color.red, lineWidth: 1.5)
        )
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
            VStack(spacing: 7) {
                Image(systemName: imageName)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .red : Color(red: 0.58, green: 0.64, blue: 0.72))

                Text(title)
                    .font(Font.custom("Plus Jakarta Sans", size: 14))
                    .foregroundColor(isSelected ? .red : Color(red: 0.58, green: 0.64, blue: 0.72))

                Rectangle()
                    .fill(isSelected ? Color.red : Color.clear)
                    .frame(width: 75, height: 6)
                    .cornerRadius(8)
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
