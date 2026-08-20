import Foundation
import Combine

// Birth Certificate has no government fee — it shows Visit Required instead (per Itzeazy).
@MainActor
final class BirthCertDetailViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var processing: String = ""
    @Published var visitRequired: String = ""
    @Published var itzeazyFee: String = ""
    @Published var documents: [String] = []
    @Published var errorMessage: String? = nil

    private let api = ItzeazyAPIService.shared

    func loadDocuments(city: String) {
        // Backend's stored value has a trailing space on this specific type string — verified
        // against the actual working curl example, not a typo on our side.
        guard let endpoint = DocumentsRequiredService.endpoint(work: "Birth Certificate", type: "New Birth Certificate ", city: city) else { return }
        isLoading = true
        errorMessage = nil

        Task {
            defer { isLoading = false }
            do {
                let response: DocumentsRequiredResponse = try await api.get(endpoint: endpoint)
                let extra = response.data?.extraFields
                processing = DocumentsRequiredService.cleanField(extra, "PROCESSING")
                visitRequired = DocumentsRequiredService.cleanField(extra, "VISIT REQUIRED")
                let rawItzeazyFee = DocumentsRequiredService.cleanField(extra, "ITZEAZY FEE")
                itzeazyFee = rawItzeazyFee.isEmpty ? "" : "₹\(rawItzeazyFee)"
                documents = DocumentsRequiredService.dedupedDocuments(response.data?.documents).map { $0.documentName }
            } catch let error as ItzeazyAPIError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = "Failed to load service details. Please try again."
            }
        }
    }
}
