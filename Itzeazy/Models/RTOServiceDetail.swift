import Foundation

struct RTOServiceDetail {
    let serviceTitle: String        // e.g. "Duplicate RC"
    let city: String                // e.g. "Bengaluru"
    let processingTime: String      // e.g. "3-5 days"
    let documentCollection: String  // e.g. "Yes" / "No"
    let visitRequired: String       // e.g. "Yes" / "No"
    let requiredDocuments: [String]

    /// Full nav-bar title: "Bengaluru / Duplicate RC"
    var navigationTitle: String { "\(city) / \(serviceTitle)" }
}
