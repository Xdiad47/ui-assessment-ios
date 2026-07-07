import Foundation

// Shared envelope for the `user/documents/*` list endpoints
// (e.g. `user/documents/cities`, `user/documents/countries`), which all
// return a flat array of strings under `data`.
struct DocumentsListResponse: Decodable {
    let data: [String]?
    let message: String?
    let statusCode: Int?

    enum CodingKeys: String, CodingKey {
        case data, message
        case statusCode = "status_code"
    }
}
