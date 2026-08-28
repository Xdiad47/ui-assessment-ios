import SwiftUI
import Combine

// MARK: - DocumentScannerReviewViewModel
// Mirrors Android's DocumentScannerReviewViewModel.kt — handles both entry paths (a freshly-saved
// scan session, or an already-saved document opened from My PDFs, possibly password-decrypted to
// a temp copy for viewing) plus the "related documents" family concept (root original + every
// Split/Rearrange/e-Sign derivative).

@MainActor
final class DocumentScannerReviewViewModel: ObservableObject {
    @Published private(set) var document: ScannedDocument?
    @Published var isSaving = false
    @Published private(set) var pages: [UIImage] = []
    @Published private(set) var pagesLoading = false
    @Published private(set) var relatedDocuments: [ScannedDocument] = []
    @Published var toastMessage: String?

    private let repository = DocumentScannerRepository.shared
    private var renderedPagesForPath: String?
    private var lastLoadedSession: ScanSession?
    private var lastLoadedDocId: String?

    /// Builds the final document from [session]'s filtered pages — merging front+back onto a
    /// single page first if this was a Two Side ID Scan — then generates the PDF, a thumbnail,
    /// and persists the entry. If session.appendToDocumentId is set (the "Add > Scan New Page"
    /// continuation flow), the new pages are appended onto that document's existing ones instead.
    func initSession(_ session: ScanSession) {
        guard lastLoadedSession != session else { return }
        lastLoadedSession = session
        document = nil
        isSaving = true
        let repo = repository
        Task.detached(priority: .userInitiated) {
            do {
                var pageImages: [UIImage] = []
                for url in session.filteredPageURLs {
                    pageImages.append(try repo.decodeSampledImage(at: url))
                }
                guard !pageImages.isEmpty else {
                    throw DocumentScannerRepositoryError.processingFailed("No pages to save")
                }

                let finalPages: [UIImage]
                if session.mode == .idScan, session.idSideOption == .twoSide, pageImages.count >= 2 {
                    finalPages = [repo.mergeVertically(top: pageImages[0], bottom: pageImages[1])]
                } else {
                    finalPages = pageImages
                }

                let appendTarget = session.appendToDocumentId.flatMap { id in
                    repo.loadDocumentIndex().first { $0.id == id }
                }

                let doc: ScannedDocument
                if let appendTarget {
                    doc = try repo.appendPages(to: appendTarget, newPages: finalPages)
                } else {
                    let docId = UUID().uuidString
                    let pdfURL = try repo.generatePDF(pages: finalPages, docId: docId)
                    let thumbPath = try repo.generateThumbnail(finalPages[0], docId: docId)
                    let existingCount = repo.loadDocumentIndex().count
                    let newDoc = ScannedDocument(
                        id: docId,
                        name: "Doc_\(String(format: "%03d", existingCount + 1))",
                        folderName: unnamedFolderName,
                        pageCount: finalPages.count,
                        fileSizeBytes: repo.fileSize(at: pdfURL),
                        pdfPath: pdfURL.path,
                        thumbnailPath: thumbPath,
                        createdAtMillis: Int64(Date().timeIntervalSince1970 * 1000)
                    )
                    repo.addDocument(newDoc)
                    doc = newDoc
                }

                await MainActor.run { [weak self] in
                    self?.document = doc
                    self?.isSaving = false
                    self?.refreshRelatedDocuments()
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.toastMessage = "Couldn't save the document. Please try again."
                    self?.isSaving = false
                }
            }
        }
    }

    /// Loads an already-saved document directly (the My PDFs "tap to open" path). If
    /// [unlockedPdfPath] is given, the caller already verified the password and decrypted to a
    /// temp copy — the in-memory document used for this viewing session points at that temp copy,
    /// while the persisted index entry (and its real, still-encrypted pdfPath) is never touched.
    func loadExistingDocument(_ docId: String, unlockedPdfPath: String? = nil) {
        if lastLoadedDocId == docId, unlockedPdfPath == nil { return }
        lastLoadedDocId = docId
        guard var doc = repository.loadDocumentIndex().first(where: { $0.id == docId }) else { return }
        if let unlockedPdfPath { doc.pdfPath = unlockedPdfPath }
        document = doc
        refreshRelatedDocuments()
    }

    /// Re-reads the current document from the on-device index — needed after returning from
    /// Split/Rearrange/e-Sign, which mutate the same document's PDF directly through the
    /// repository, not through this view model. Called unconditionally on every Review entry.
    func refreshDocument() {
        guard let current = document else { return }
        guard let latest = repository.loadDocumentIndex().first(where: { $0.id == current.id }) else { return }
        var effective = latest
        if current.pdfPath != latest.pdfPath { effective.pdfPath = current.pdfPath }
        document = effective
        refreshRelatedDocuments()
    }

    private func refreshRelatedDocuments() {
        guard let doc = document else { return }
        let rootId = doc.sourceDocumentId ?? doc.id
        relatedDocuments = repository.loadDocumentIndex()
            .filter { $0.id == rootId || $0.sourceDocumentId == rootId }
            .sorted { $0.createdAtMillis < $1.createdAtMillis }
    }

    /// Renders the current document's pages for in-app viewing — skipped if already rendered for
    /// the same pdfPath, since this is called on every entry into View PDF but page content only
    /// actually changes after Split/Rearrange/e-Sign/OCR or a Compress save (those pass force=true).
    func loadPagesForViewing(force: Bool = false) {
        guard let doc = document else { return }
        guard force || renderedPagesForPath != doc.pdfPath else { return }
        renderedPagesForPath = doc.pdfPath
        pagesLoading = true
        let path = doc.pdfPath
        Task.detached(priority: .userInitiated) {
            do {
                let images = try DocumentScannerPDFService.renderPagesAsImages(url: URL(fileURLWithPath: path))
                await MainActor.run { [weak self] in
                    self?.pages = images
                    self?.pagesLoading = false
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.toastMessage = "Couldn't load the document. Please try again."
                    self?.pagesLoading = false
                }
            }
        }
    }

    func renameConfirmed(_ newName: String) {
        guard document != nil else { return }
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        repository.renameDocument(id: document!.id, newName: trimmed)
        document?.name = trimmed
    }

    func printDocument() {
        guard let doc = document else { return }
        do {
            try repository.printDocument(pdfURL: URL(fileURLWithPath: doc.pdfPath), jobName: doc.name)
        } catch {
            toastMessage = "Couldn't open the print dialog. Please try again."
        }
    }

    func delete() {
        guard let doc = document else { return }
        repository.deleteDocument(id: doc.id)
    }

    func compressConfirm(scale: CGFloat, superCompress: Bool) {
        guard let doc = document else { return }
        let effectiveScale = superCompress ? scale * 0.7 : scale
        let repo = repository
        Task.detached(priority: .userInitiated) {
            do {
                let newSize = try repo.compressPDF(document: doc, scale: effectiveScale)
                await MainActor.run { [weak self] in
                    self?.document?.fileSizeBytes = newSize
                    self?.loadPagesForViewing(force: true)
                    self?.toastMessage = "Document compressed"
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.toastMessage = "Couldn't compress the document. Please try again."
                }
            }
        }
    }

    func addPassword(_ password: String) {
        guard let doc = document else { return }
        let repo = repository
        Task.detached(priority: .userInitiated) {
            do {
                let updated = try repo.protectDocumentWithPassword(doc, password: password)
                await MainActor.run { [weak self] in
                    self?.document = updated
                    self?.toastMessage = "Password added"
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.toastMessage = "Couldn't add a password. Please try again."
                }
            }
        }
    }

    func shareAsJPG(onReady: @escaping ([URL]) -> Void) {
        guard let doc = document else { return }
        let repo = repository
        let pdfPath = doc.pdfPath
        Task.detached(priority: .userInitiated) {
            do {
                let urls = try repo.renderPagesAsJPEGs(pdfURL: URL(fileURLWithPath: pdfPath), subdir: "document_scanner_jpg_share")
                await MainActor.run { [weak self] in
                    if urls.isEmpty {
                        self?.toastMessage = "Couldn't prepare the image. Please try again."
                    } else {
                        onReady(urls)
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.toastMessage = "Couldn't prepare the image. Please try again."
                }
            }
        }
    }

    /// True if there's at least one saved document anywhere in the app — used to decide whether
    /// "Add > From Folder" has anything to show before navigating there.
    func hasAnyDocuments() -> Bool {
        !repository.loadDocumentIndex().isEmpty
    }

    /// Copies [url] (a PDF the user picked via "Add > Add New PDF") into the app's own storage
    /// and indexes it as a new document.
    func importPDF(from url: URL, displayName: String, onComplete: @escaping (ScannedDocument) -> Void) {
        isSaving = true
        let repo = repository
        Task.detached(priority: .userInitiated) {
            do {
                let newDoc = try repo.importPDF(from: url, displayName: displayName)
                await MainActor.run { [weak self] in
                    self?.isSaving = false
                    onComplete(newDoc)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.isSaving = false
                    self?.toastMessage = "Couldn't import that PDF. Please try again."
                }
            }
        }
    }
}
