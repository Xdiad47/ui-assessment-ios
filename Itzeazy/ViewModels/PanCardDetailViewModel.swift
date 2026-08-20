import Foundation
import Combine

@MainActor
final class PanCardDetailViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var processing: String = ""
    @Published var govtFee: String = ""
    @Published var itzeazyFee: String = ""
    @Published var documents: [String] = []
    @Published var errorMessage: String? = nil

    private let api = ItzeazyAPIService.shared

    func loadDocuments(city: String) {
        guard let endpoint = DocumentsRequiredService.endpoint(work: "PAN Card", type: "New Pan Card", city: city) else { return }
        isLoading = true
        errorMessage = nil

        Task {
            defer { isLoading = false }
            do {
                let response: DocumentsRequiredResponse = try await api.get(endpoint: endpoint)
                let extra = response.data?.extraFields
                processing = DocumentsRequiredService.cleanField(extra, "PROCESSING")
                let rawGovtFee = DocumentsRequiredService.cleanField(extra, "GOVT FEE")
                govtFee = rawGovtFee.isEmpty ? "" : "₹\(rawGovtFee)"
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
