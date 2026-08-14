import Foundation
import Combine

// TEMPORARY: static content until the backend exposes a real documents/fee endpoint for
// Birth Certificate. Mirrors Android's BirthCertDetailViewModel exactly. Both govtFee and
// itzeazyFee are unconfirmed placeholders — the municipal certificate fee varies by
// state/city, and the real Itzeazy service fee still needs confirming.
@MainActor
final class BirthCertDetailViewModel: ObservableObject {
    @Published var processing: String = "3-5 days"
    @Published var govtFee: String = "Varies by state"
    @Published var itzeazyFee: String = "₹1,500"
    @Published var documents: [String] = [
        "Hospital birth discharge slip / institutional birth record",
        "Parents' Aadhaar Card",
        "Parents' address proof",
        "Parents' marriage certificate (if available)",
        "Affidavit for delayed registration (if applicable)"
    ]
}
