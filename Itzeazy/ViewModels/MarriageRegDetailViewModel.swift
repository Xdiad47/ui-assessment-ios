import Foundation
import Combine

// Marriage Registration has no government fee — it shows Visit Required instead (per Itzeazy).
@MainActor
final class MarriageRegDetailViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var processing: String = ""
    @Published var visitRequired: String = ""
    @Published var itzeazyFee: String = ""
    @Published var documents: [String] = []
    @Published var errorMessage: String? = nil

    private let api = ItzeazyAPIService.shared

    func loadDocuments(type: String, city: String) {
        guard let endpoint = DocumentsRequiredService.endpoint(work: "Marriage Registration", type: type, city: city) else { return }
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
