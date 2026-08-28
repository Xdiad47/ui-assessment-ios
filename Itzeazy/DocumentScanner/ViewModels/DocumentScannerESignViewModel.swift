import SwiftUI
import Combine

// MARK: - ESignPagePlacement
// A signature placed on one page, as fractions (0..1) of that page's own pixel dimensions.

struct ESignPagePlacement {
    let signatureImage: UIImage
    let xFraction: CGFloat
    let yFraction: CGFloat
    let widthFraction: CGFloat
    let heightFraction: CGFloat
}

// MARK: - DocumentScannerESignViewModel
// Mirrors Android's DocumentScannerESignViewModel.kt — every page is loaded up front (e-Sign is
// dynamic per document: sign one page, several, or all before one Save).

@MainActor
final class DocumentScannerESignViewModel: ObservableObject {
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
                    self?.toastMessage = "Couldn't load the document. Please try again."
                    self?.isLoading = false
                }
            }
        }
    }

    /// Composites every entry in [signedPages] onto its page and builds a brand-new "_esign"
    /// document from the result — lets the user sign one page or every page before a single Save,
    /// and leaves [document] itself untouched.
    func saveSignatures(document: ScannedDocument, signedPages: [Int: ESignPagePlacement], onComplete: @escaping (ScannedDocument) -> Void) {
        guard !signedPages.isEmpty else { return }
        isSaving = true
        let repo = repository
        let currentPages = pages
        Task.detached(priority: .userInitiated) {
            var edits: [Int: UIImage] = [:]
            for (index, placed) in signedPages {
                guard index < currentPages.count else { continue }
                let page = currentPages[index]
                edits[index] = repo.compositeSignature(
                    placed.signatureImage, onto: page,
                    x: placed.xFraction * page.size.width,
                    y: placed.yFraction * page.size.height,
                    width: placed.widthFraction * page.size.width,
                    height: placed.heightFraction * page.size.height
                )
            }
            do {
                let newDoc = try repo.signPages(document: document, pageEdits: edits)
                await MainActor.run { [weak self] in
                    self?.isSaving = false
                    onComplete(newDoc)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.isSaving = false
                    self?.toastMessage = "Couldn't save the signature. Please try again."
                }
            }
        }
    }
}
