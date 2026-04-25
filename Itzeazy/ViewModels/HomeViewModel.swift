import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var services: [ServiceItem] = []
    @Published var popularItems: [PopularItem] = []
    @Published var searchQuery: String = ""
    
    private let repository = MockRepository.shared
    
    init() {
        loadData()
    }
    
    func loadData() {
        services = repository.getServices()
        popularItems = repository.getPopularItems()
    }
}
