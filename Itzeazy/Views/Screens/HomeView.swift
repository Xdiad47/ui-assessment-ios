import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(white: 0.98).edgesIgnoringSafeArea(.all)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Top Bar
                        TopBarView()
                        
                        // Search Bar
                        SearchBarView(text: $viewModel.searchQuery)
                        
                        // Services Section
                        SectionHeaderView(
                            title: "Services",
                            showViewAll: true,
                            onViewAllTapped: {
                                // View all action
                            }
                        )
                        
                        ServicesGridView(services: viewModel.services)
                        
                        // Popular Right Now Section
                        SectionHeaderView(title: "Popular Right Now")
                            .padding(.top, 8)
                        
                        PopularSectionView(items: viewModel.popularItems)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
