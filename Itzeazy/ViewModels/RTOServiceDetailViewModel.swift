import Foundation
import Combine

// MARK: - Required documents API models (RTO)

private struct RTORequiredDocumentsResponse: Decodable {
    let data: RTORequiredDocumentsData?
    let message: String?
    let statusCode: Int?

    enum CodingKeys: String, CodingKey {
        case data, message
        case statusCode = "status_code"
    }
}

private struct RTORequiredDocumentsData: Decodable {
    let documents: [RTORequiredDocumentItem]?
    let extraFields: RTORequiredDocumentsExtraFields?

    enum CodingKeys: String, CodingKey {
        case documents
        case extraFields = "extra_fields"
    }
}

private struct RTORequiredDocumentItem: Decodable {
    let id: Int
    let documentName: String

    enum CodingKeys: String, CodingKey {
        case id
        case documentName = "document_name"
    }
}

private struct RTORequiredDocumentsExtraFields: Decodable {
    let documentCollection: String?
    let processing: String?
    let visitRequired: String?

    enum CodingKeys: String, CodingKey {
        case documentCollection = "DOCUMENT COLLECTION"
        case processing = "PROCESSING"
        case visitRequired = "VISIT REQUIRED"
    }
}

@MainActor
final class RTOServiceDetailViewModel: ObservableObject {
    let serviceTitle: String // e.g. "Duplicate RC" — passed verbatim as the `work` query param
    let city: String         // e.g. "Delhi"

    @Published var processingTime: String = "-"
    @Published var documentCollection: String = "-"
    @Published var visitRequired: String = "-"
    @Published var requiredDocuments: [String] = []
    @Published var documentsMessage: String? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showUnavailableAlert: Bool = false

    /// Full nav-bar title: "Delhi / Duplicate RC"
    var navigationTitle: String { "\(city) / \(serviceTitle)" }

    /// Redirect path for the "Apply Now" web-login flow. `nil` for services
    /// that aren't wired up on the website yet (New Reg., DL Extract, Vehicle Fitness).
    var redirectPath: String? {
        let c = city.lowercased()
        switch serviceTitle {
        case "Duplicate RC":    return "/order/rto-duplicate-rc-\(c)"
        case "HP Termination":  return "/order/rto-hp-deletion-\(c)"
        case "RC Transfer":     return "/order/rto-ownership-transfer-\(c)"
        case "Vehicle NOC":     return "/order/rto-noc-\(c)"
        case "Re-registration": return "/order/rto-re-registration-\(c)"
        case "New DL":
            return ["faridabad", "ghaziabad", "gurgaon", "noida"].contains(c)
                ? "/order/rto-driving-license-new-\(c)"
                : "/order/rto-driving-license-new"
        case "DL Renewal":   return "/order/rto-driving-license-renew"
        case "Intl. DL":     return "/order/idp"
        case "Duplicate DL": return "/order/rto-driving-license-duplicate"
        default:              return nil // New Reg., DL Extract, Vehicle Fitness
        }
    }

    private let api = ItzeazyAPIService.shared
    private var activeFetchToken = UUID()

    init(serviceTitle: String, city: String = "Bengaluru") {
        self.serviceTitle = serviceTitle
        self.city = city
        fetchRequiredDocuments()
    }

    // MARK: - Fetch required documents + processing details
    // GET user/documents/required?work=<serviceTitle>&address_status=&type=&service_type=rto&city=<city>

    func fetchRequiredDocuments() {
        let token = UUID()
        activeFetchToken = token

        guard let endpoint = requiredDocumentsEndpoint() else { return }

        isLoading = true
        errorMessage = nil
        documentsMessage = nil

        Task {
            defer {
                if token == activeFetchToken { isLoading = false }
            }
            do {
                let response: RTORequiredDocumentsResponse = try await api.get(endpoint: endpoint)
                guard token == activeFetchToken else { return }

                let docs = response.data?.documents ?? []
                requiredDocuments = docs.map { $0.documentName }
                documentsMessage = docs.isEmpty ? "No documents available yet for this service." : nil

                let extraFields = response.data?.extraFields
                processingTime = extraFields?.processing ?? "-"
                documentCollection = extraFields?.documentCollection ?? "-"
                visitRequired = extraFields?.visitRequired ?? "-"
            } catch let error as ItzeazyAPIError {
                guard token == activeFetchToken else { return }
                errorMessage = error.errorDescription
            } catch {
                guard token == activeFetchToken else { return }
                errorMessage = "Failed to load service details. Please try again."
            }
        }
    }

    private func requiredDocumentsEndpoint() -> String? {
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "work", value: serviceTitle),
            URLQueryItem(name: "address_status", value: ""),
            URLQueryItem(name: "type", value: ""),
            URLQueryItem(name: "service_type", value: "rto"),
            URLQueryItem(name: "city", value: city)
        ]
        guard let query = components.percentEncodedQuery else { return nil }
        return "user/documents/required?\(query)"
    }
}
