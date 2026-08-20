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

// MARK: - Required documents API models

private struct RequiredDocumentsResponse: Decodable {
    let data: RequiredDocumentsData?
    let message: String?
    let statusCode: Int?

    enum CodingKeys: String, CodingKey {
        case data, message
        case statusCode = "status_code"
    }
}

private struct RequiredDocumentsData: Decodable {
    let documents: [RequiredDocumentItem]?
    let extraFields: RequiredDocumentsExtraFields?

    enum CodingKeys: String, CodingKey {
        case documents
        case extraFields = "extra_fields"
    }
}

private struct RequiredDocumentItem: Decodable {
    let id: Int
    let documentName: String

    enum CodingKeys: String, CodingKey {
        case id
        case documentName = "document_name"
    }
}

private struct RequiredDocumentsExtraFields: Decodable {
    let processing: String?
    let govtFee: String?
    let itzeazyFee: String?

    enum CodingKeys: String, CodingKey {
        case processing = "PROCESSING"
        case govtFee = "GOVT FEE"
        case itzeazyFee = "ITZEAZY FEE"
    }
}

/// The backend sends the literal string "null" for an unset extra_fields value (not JSON
/// null) — treat that, and blank strings, as "no value" so callers fall back to empty.
private func cleanExtraField(_ raw: String?) -> String {
    guard let raw, !raw.isEmpty, raw.lowercased() != "null" else { return "" }
    return raw
}

@MainActor
final class VisaViewModel: ObservableObject {
    let selectedCountry: String

    @Published var selectedCategory: VisaCategory = .leisure {
        didSet {
            guard oldValue != selectedCategory else { return }
            fetchRequiredDocuments()
        }
    }

    @Published var requiredDocuments: [DocumentRequirement] = []
    @Published var documentsMessage: String? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    @Published var processingTime: String = ""
    @Published var govtFee: String = ""
    @Published var itzeazyFee: String = ""

    private let api = ItzeazyAPIService.shared
    private var activeFetchToken = UUID()

    init(selectedCountry: String = "Singapore") {
        self.selectedCountry = selectedCountry
        fetchRequiredDocuments()
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
        case "France", "france": return "🇫🇷"
        case "Georgia": return "🇬🇪"
        case "Germany": return "🇩🇪"
        case "Greece", "greece": return "🇬🇷"
        case "Hungary": return "🇭🇺"
        case "Indonesia": return "🇮🇩"
        case "Italy", "italy": return "🇮🇹"
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
        case "Singapore", "singapore": return "🇸🇬"
        case "South Africa": return "🇿🇦"
        case "South Korea": return "🇰🇷"
        case "Spain": return "🇪🇸"
        case "Sri Lanka": return "🇱🇰"
        case "Sweden": return "🇸🇪"
        case "Switzerland", "switzerland": return "🇨🇭"
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

    // MARK: - Fetch required documents + fee/processing details
    // GET user/documents/required?work=visa&address_status=<country>&type=<category>&service_type=visa

    func fetchRequiredDocuments() {
        let token = UUID()
        activeFetchToken = token

        guard let endpoint = requiredDocumentsEndpoint(for: selectedCategory) else { return }

        isLoading = true
        errorMessage = nil
        documentsMessage = nil

        Task {
            defer {
                if token == activeFetchToken { isLoading = false }
            }
            do {
                let response: RequiredDocumentsResponse = try await api.get(endpoint: endpoint)
                guard token == activeFetchToken else { return }

                let docs = response.data?.documents ?? []
                requiredDocuments = docs.map { DocumentRequirement(name: $0.documentName) }
                documentsMessage = docs.isEmpty ? "No documents required for this visa type." : nil

                let extraFields = response.data?.extraFields
                processingTime = cleanExtraField(extraFields?.processing)
                // Govt fee arrives with its own currency symbol already ("€90") — shown as-is.
                govtFee = cleanExtraField(extraFields?.govtFee)
                let rawItzeazyFee = cleanExtraField(extraFields?.itzeazyFee)
                itzeazyFee = rawItzeazyFee.isEmpty ? "" : "₹\(rawItzeazyFee)"
            } catch let error as ItzeazyAPIError {
                guard token == activeFetchToken else { return }
                errorMessage = error.errorDescription
            } catch {
                guard token == activeFetchToken else { return }
                errorMessage = "Failed to load visa details. Please try again."
            }
        }
    }

    private func requiredDocumentsEndpoint(for category: VisaCategory) -> String? {
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "work", value: "visa"),
            URLQueryItem(name: "address_status", value: selectedCountry),
            URLQueryItem(name: "type", value: category.rawValue),
            URLQueryItem(name: "service_type", value: "visa")
        ]
        guard let query = components.percentEncodedQuery else { return nil }
        return "user/documents/required?\(query)"
    }
}
