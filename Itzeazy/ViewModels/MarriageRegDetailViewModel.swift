import Foundation
import Combine

// TEMPORARY: static content until the backend exposes a real documents/fee endpoint for
// Marriage Registration. Mirrors Android's MarriageRegDetailViewModel exactly. Both govtFee
// and itzeazyFee are unconfirmed placeholders — the government registration fee varies by
// state, and the real Itzeazy service fee still needs confirming.
@MainActor
final class MarriageRegDetailViewModel: ObservableObject {
    @Published var processing: String = "3-5 days"
    @Published var govtFee: String = "Varies by state"
    @Published var itzeazyFee: String = "₹2,500"
    @Published var documents: [String] = [
        "Aadhaar Card of both bride and groom",
        "Age proof (Birth Certificate, 10th Marksheet, or Passport)",
        "Address proof of both parties",
        "Passport-size photographs of bride and groom",
        "Two witnesses with valid ID proof",
        "Marriage invitation card (if available)"
    ]
}
