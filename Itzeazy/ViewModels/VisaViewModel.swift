import Foundation
import SwiftUI
import Combine

enum VisaCategory: String, CaseIterable {
    case leisure = "Leisure"
    case business = "Business"
    case transit = "Transit"
}

struct DocumentRequirement: Identifiable {
    let id = UUID()
    let name: String
}

class VisaViewModel: ObservableObject {
    @Published var selectedCategory: VisaCategory = .leisure
    @Published var isLoading: Bool = false
    
    // Static details matching the Figma design
    var processingTime: String {
        return "3-5 days"
    }
    
    var visaFee: String {
        return "₹2,846"
    }
    
    var visaFeeUSD: String {
        return "(~$30 USD)"
    }
    
    var requiredDocuments: [DocumentRequirement] {
        switch selectedCategory {
        case .leisure:
            return [
                DocumentRequirement(name: "Valid passport (at least 6 months validity; 2 blank pages)"),
                DocumentRequirement(name: "Completed Singapore visa application form (SAVE system or through embassy)"),
                DocumentRequirement(name: "1 recent passport-size photograph (white background)"),
                DocumentRequirement(name: "Confirmed return flight booking"),
                DocumentRequirement(name: "Hotel / accommodation bookings"),
                DocumentRequirement(name: "Bank statements for last 3 months"),
                DocumentRequirement(name: "Employment letter or business registration"),
                DocumentRequirement(name: "Invitation letter from Singapore host (if staying with contacts)")
            ]
        case .business:
            return [
                DocumentRequirement(name: "Valid passport (at least 6 months validity)"),
                DocumentRequirement(name: "Completed Singapore visa application form"),
                DocumentRequirement(name: "Business invitation letter from Singapore company"),
                DocumentRequirement(name: "Company registration certificate")
            ]
        case .transit:
            return [
                DocumentRequirement(name: "Valid passport (at least 6 months validity)"),
                DocumentRequirement(name: "Confirmed onward flight tickets"),
                DocumentRequirement(name: "Visa for next destination (if applicable)")
            ]
        }
    }
}
