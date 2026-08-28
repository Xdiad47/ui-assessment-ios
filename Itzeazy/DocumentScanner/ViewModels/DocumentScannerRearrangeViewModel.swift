import SwiftUI
import Combine

// MARK: - DocumentScannerRearrangeViewModel
// Mirrors Android's DocumentScannerRearrangeViewModel.kt.

@MainActor
final class DocumentScannerRearrangeViewModel: ObservableObject {
    @Published private(set) var pages: [UIImage] = []
    @Published private(set) var isLoading = false
    @Published var isSaving = false
    @Published var toastMessage: String?

    private let repository = DocumentScannerRepository.shared
    private var lastLoadedDocId: String?

    func initDocument(_ document: ScannedDocument) {
        guard lastLoadedDocId != document.id else { return }
        lastLoadedDocId = document.id
        isLoading = true
        let path = document.pdfPath
        Task.detached(priority: .userInitiated) {
            do {
                let rendered = try DocumentScannerPDFService.renderPagesAsImages(url: URL(fileURLWithPath: path))
                await MainActor.run { [weak self] in
                    self?.pages = rendered
                    self?.isLoading = false
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.toastMessage = "Couldn't load the document's pages. Please try again."
                    self?.isLoading = false
                }
            }
        }
    }

    /// [newOrder] is a permutation of page indices in the pages' new display order.
    func rearrange(document: ScannedDocument, newOrder: [Int], onComplete: @escaping (ScannedDocument) -> Void) {
        isSaving = true
        let repo = repository
        Task.detached(priority: .userInitiated) {
            do {
                let newDoc = try repo.rearrangePDF(document: document, newOrder: newOrder)
                await MainActor.run { [weak self] in
                    self?.isSaving = false
                    onComplete(newDoc)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.isSaving = false
                    self?.toastMessage = "Couldn't rearrange the document. Please try again."
                }
            }
        }
    }
}
