import Foundation
import Combine

class VehicleViewModel: ObservableObject {
    @Published var searchResult: VehicleSearchResult?
    @Published var isLoading: Bool = false
    @Published var totalDue: Int = 2500
    @Published var selectedChallansCount: Int = 3
    
    private let repository = MockRepository.shared
    
    init() {
        loadData()
    }
    
    func loadData() {
        isLoading = true
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.searchResult = self.repository.getVehicleSearchResult()
            self.isLoading = false
        }
    }
}
