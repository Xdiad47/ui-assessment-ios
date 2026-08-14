import Foundation
import Combine

// TEMPORARY: static content until the backend exposes a real documents/fee endpoint for
// PAN Card. Mirrors Android's PanCardDetailViewModel exactly. govtFee (₹110) matches the
// official NSDL/UTIITSL application fee for an Indian communication address. itzeazyFee is
// still an unconfirmed placeholder.
@MainActor
final class PanCardDetailViewModel: ObservableObject {
    @Published var processing: String = "3-5 days"
    @Published var govtFee: String = "₹110"
    @Published var itzeazyFee: String = "₹499"
    @Published var documents: [String] = [
        "Proof of Identity (Aadhaar Card, Voter ID, or Passport)",
        "Proof of Address",
        "Proof of Date of Birth",
        "1 recent passport-size photograph"
    ]
}
