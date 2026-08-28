import SwiftUI
import Combine

// MARK: - DocumentScannerEditViewModel
// Mirrors Android's DocumentScannerEditViewModel.kt — rotation is the only per-page edit here;
// VisionKit's own scanner already crops/straightens each page during capture, so there's no crop
// step on top of that.

@MainActor
final class DocumentScannerEditViewModel: ObservableObject {
    @Published private(set) var pages: [ScanPageDraft] = []
    @Published private(set) var currentIndex = 0
    @Published var isProcessing = false
    @Published var toastMessage: String?

    private let repository = DocumentScannerRepository.shared
    private var lastLoadedPages: [CapturedPage]?

    func initSession(_ rawPages: [CapturedPage]) {
        guard lastLoadedPages != rawPages else { return }
        lastLoadedPages = rawPages
        pages = rawPages.map { ScanPageDraft(id: $0.id, sourceURL: $0.url) }
        currentIndex = 0
    }

    func selectPage(_ index: Int) {
        guard pages.indices.contains(index) else { return }
        currentIndex = index
    }

    func rotateLeft() {
        updateCurrent { draft in
            var copy = draft
            copy.rotationDegrees = ((copy.rotationDegrees - 90) % 360 + 360) % 360
            return copy
        }
    }

    func rotateRight() {
        updateCurrent { draft in
            var copy = draft
            copy.rotationDegrees = (copy.rotationDegrees + 90) % 360
            return copy
        }
    }

    private func updateCurrent(_ transform: (ScanPageDraft) -> ScanPageDraft) {
        guard pages.indices.contains(currentIndex) else { return }
        pages[currentIndex] = transform(pages[currentIndex])
    }

    /// Bakes each page's rotation into a real file and hands back their URLs.
    func next(onDone: @escaping ([URL]) -> Void) {
        guard !isProcessing, !pages.isEmpty else { return }
        isProcessing = true
        let drafts = pages
        let repo = repository
        Task.detached(priority: .userInitiated) {
            do {
                var results: [URL] = []
                for draft in drafts {
                    let image = try repo.decodeSampledImage(at: draft.sourceURL)
                    let rotated = repo.rotateImage(image, degrees: draft.rotationDegrees)
                    results.append(try repo.saveImageToCache(rotated, subdir: "document_scanner_edits"))
                }
                let finalResults = results
                await MainActor.run { [weak self] in
                    self?.isProcessing = false
                    onDone(finalResults)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.isProcessing = false
                    self?.toastMessage = "Couldn't process the pages. Please try again."
                }
            }
        }
    }
}
