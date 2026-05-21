import Foundation
import Combine

class PaymentsViewModel: ObservableObject {
    @Published var welcomeName: String = "amar patil"
    let sectionTitle: String = "All Payments"
}
