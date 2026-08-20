import Foundation

// MARK: - Documents-required API models
// Shared by Passport, Marriage Registration, Birth Certificate, and PAN Card detail
// screens — same `user/documents/required?work=&type=&city=` shape for all four
// (a different query shape than RTO/Visa's existing service_type/address_status version).

struct DocumentsRequiredResponse: Decodable {
    let data: DocumentsRequiredData?
    let message: String?
    let statusCode: Int?

    enum CodingKeys: String, CodingKey {
        case data, message
        case statusCode = "status_code"
    }
}

struct DocumentsRequiredData: Decodable {
    let documents: [DocumentsRequiredItem]?
    let extraFields: [String: String]?

    enum CodingKeys: String, CodingKey {
        case documents
        case extraFields = "extra_fields"
    }
}

struct DocumentsRequiredItem: Decodable {
    let id: Int
    let documentName: String
    let docCode: String

    enum CodingKeys: String, CodingKey {
        case id
        case documentName = "document_name"
        case docCode = "doc_code"
    }
}

enum DocumentsRequiredService {
    /// The backend sends the literal string "null" for an unset extra_fields value (not JSON
    /// null) — treat that, and blank strings, as "no value" so callers fall back to empty.
    static func cleanField(_ fields: [String: String]?, _ key: String) -> String {
        guard let raw = fields?[key], !raw.isEmpty, raw.lowercased() != "null" else { return "" }
        return raw
    }

    static func endpoint(work: String, type: String, city: String) -> String? {
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "work", value: work),
            URLQueryItem(name: "type", value: type),
            URLQueryItem(name: "city", value: city)
        ]
        guard let query = components.percentEncodedQuery else { return nil }
        return "user/documents/required?\(query)"
    }

    /// Deduplicates by doc_code — the backend currently returns each document twice for some
    /// services (e.g. Marriage Registration).
    static func dedupedDocuments(_ items: [DocumentsRequiredItem]?) -> [DocumentsRequiredItem] {
        guard let items else { return [] }
        var seen = Set<String>()
        return items.filter { seen.insert($0.docCode).inserted }
    }
}
