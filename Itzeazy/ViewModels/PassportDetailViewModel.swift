import Foundation
import Combine

// TEMPORARY: static content until the backend exposes a real documents/fee endpoint for
// Passport (same shape as RTOServiceDetailViewModel/VisaViewModel's user/documents/required,
// once service_type=passport is supported there). Mirrors Android's PassportDetailViewModel
// exactly so both platforms show identical figures. govtFee is sourced from the official MEA
// fee schedule (Normal, Adult, 36-page tier); itzeazyFee is a placeholder pending confirmation.
@MainActor
final class PassportDetailViewModel: ObservableObject {
    @Published var processing: String = "30-45 days"
    @Published var govtFee: String = "₹2,500 (Normal, Adult, 36-page)"
    @Published var itzeazyFee: String = "₹2,500"
    @Published var documents: [String] = [
        "Proof of Address (Aadhaar Card, Utility Bill, or Bank Passbook)",
        "Proof of Date of Birth (Birth Certificate or 10th Marksheet)",
        "Proof of Identity (Aadhaar Card, PAN Card, or Voter ID)",
        "Aadhaar Card",
        "2 recent passport-size photographs (white background)"
    ]
}
