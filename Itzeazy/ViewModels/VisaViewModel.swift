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
    let selectedCountry: String
    @Published var selectedCategory: VisaCategory = .leisure
    @Published var isLoading: Bool = false

    init(selectedCountry: String = "Singapore") {
        self.selectedCountry = selectedCountry
    }
    
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

    var countryFlag: String {
        switch selectedCountry {
        case "Australia": return "🇦🇺"
        case "Bahrain": return "🇧🇭"
        case "Cambodia": return "🇰🇭"
        case "Canada": return "🇨🇦"
        case "China": return "🇨🇳"
        case "Croatia": return "🇭🇷"
        case "Denmark": return "🇩🇰"
        case "Egypt": return "🇪🇬"
        case "Finland": return "🇫🇮"
        case "France": return "🇫🇷"
        case "Georgia": return "🇬🇪"
        case "Germany": return "🇩🇪"
        case "Greece": return "🇬🇷"
        case "Hungary": return "🇭🇺"
        case "Indonesia": return "🇮🇩"
        case "Italy": return "🇮🇹"
        case "Japan": return "🇯🇵"
        case "Jordan": return "🇯🇴"
        case "Kenya": return "🇰🇪"
        case "Kuwait": return "🇰🇼"
        case "Laos": return "🇱🇦"
        case "Malaysia": return "🇲🇾"
        case "Maldives": return "🇲🇻"
        case "Mexico": return "🇲🇽"
        case "Morocco": return "🇲🇦"
        case "Myanmar": return "🇲🇲"
        case "Nepal": return "🇳🇵"
        case "Netherlands": return "🇳🇱"
        case "New Zealand": return "🇳🇿"
        case "Norway": return "🇳🇴"
        case "Oman": return "🇴🇲"
        case "Philippines": return "🇵🇭"
        case "Portugal": return "🇵🇹"
        case "Qatar": return "🇶🇦"
        case "Russia": return "🇷🇺"
        case "Saudi Arabia": return "🇸🇦"
        case "Singapore": return "🇸🇬"
        case "South Africa": return "🇿🇦"
        case "South Korea": return "🇰🇷"
        case "Spain": return "🇪🇸"
        case "Sri Lanka": return "🇱🇰"
        case "Sweden": return "🇸🇪"
        case "Switzerland": return "🇨🇭"
        case "Taiwan": return "🇹🇼"
        case "Thailand": return "🇹🇭"
        case "Turkey": return "🇹🇷"
        case "UAE": return "🇦🇪"
        case "Uganda": return "🇺🇬"
        case "UK": return "🇬🇧"
        case "USA": return "🇺🇸"
        case "Uzbekistan": return "🇺🇿"
        case "Vietnam": return "🇻🇳"
        case "Zimbabwe": return "🇿🇼"
        default: return "🌍"
        }
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
