import SwiftUI
import Combine

// MARK: - DocumentScannerSplitViewModel
// Mirrors Android's DocumentScannerSplitViewModel.kt — every page starts selected ("uncheck what
// you don't want" rather than starting from an empty selection).

@MainActor
final class DocumentScannerSplitViewModel: ObservableObject {
    @Published private(set) var pages: [UIImage] = []
    @Published private(set) var selectedIndices: Set<Int> = []
    @Published private(set) var isLoading = false
    @Published var isSplitting = false
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
                    self?.selectedIndices = Set(rendered.indices)
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

    func toggleSelected(_ index: Int) {
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
    }

    func split(document: ScannedDocument, onComplete: @escaping (ScannedDocument) -> Void) {
        guard !selectedIndices.isEmpty else {
            toastMessage = "Select at least one page to split."
            return
        }
        isSplitting = true
        let repo = repository
        let indices = Array(selectedIndices)
        Task.detached(priority: .userInitiated) {
            do {
                let newDoc = try repo.splitPDF(source: document, selectedIndices: indices)
                await MainActor.run { [weak self] in
                    self?.isSplitting = false
                    onComplete(newDoc)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.isSplitting = false
                    self?.toastMessage = "Couldn't split the document. Please try again."
                }
            }
        }
    }
}
