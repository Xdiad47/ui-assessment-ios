import SwiftUI
import Combine

// MARK: - DocumentScannerListViewModel
// Backs the My PDFs / My Folders tabs on DocumentScannerListView — a thin read/refresh/CRUD layer
// over the repository's document and folder indexes, shared by both tabs since moving a document
// between them touches both. Also backs DocumentScannerMoveToFolderView (same read/CRUD surface).

@MainActor
final class DocumentScannerListViewModel: ObservableObject {
    @Published private(set) var documents: [ScannedDocument] = []
    @Published private(set) var folders: [DocumentFolder] = []
    @Published var toastMessage: String?

    private let repository = DocumentScannerRepository.shared

    func refresh() {
        documents = repository.loadDocumentIndex().sorted { $0.createdAtMillis > $1.createdAtMillis }
        folders = repository.loadFolders().sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    func renameDocument(id: String, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        repository.renameDocument(id: id, newName: trimmed)
        refresh()
    }

    func deleteDocument(id: String) {
        repository.deleteDocument(id: id)
        refresh()
    }

    func moveDocument(_ document: ScannedDocument, toFolder folderName: String) {
        repository.moveDocumentToFolder(id: document.id, folderName: folderName)
        refresh()
        toastMessage = "\"\(document.name)\" moved to \"\(folderName)\" successfully"
    }

    func addFolder(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = repository.addFolder(name: trimmed)
        refresh()
    }

    func renameFolder(id: String, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        repository.renameFolder(id: id, newName: trimmed)
        refresh()
    }

    func deleteFolder(id: String) {
        repository.deleteFolder(id: id)
        refresh()
    }

    func compress(document: ScannedDocument, scale: CGFloat, superCompress: Bool) {
        let effectiveScale = superCompress ? scale * 0.7 : scale
        Task {
            do {
                _ = try repository.compressPDF(document: document, scale: effectiveScale)
                refresh()
                toastMessage = "Document compressed"
            } catch {
                toastMessage = "Couldn't compress the document. Please try again."
            }
        }
    }

    /// Renders every page as a full-resolution JPEG — used for both "Share as JPG" and
    /// "Save as Image", which are the same operation from this list's 3-dot menu.
    func shareAsJPG(document: ScannedDocument, onReady: @escaping ([URL]) -> Void) {
        Task {
            do {
                let urls = try repository.renderPagesAsJPEGs(pdfURL: URL(fileURLWithPath: document.pdfPath), subdir: "document_scanner_jpg_share")
                if urls.isEmpty {
                    toastMessage = "Couldn't prepare the image. Please try again."
                } else {
                    onReady(urls)
                }
            } catch {
                toastMessage = "Couldn't prepare the image. Please try again."
            }
        }
    }

    func addPassword(document: ScannedDocument, password: String) {
        Task {
            do {
                _ = try repository.protectDocumentWithPassword(document, password: password)
                refresh()
                toastMessage = "Password added"
            } catch {
                toastMessage = "Couldn't add a password. Please try again."
            }
        }
    }

    /// Verifies [password] against [document]'s PDF and, if correct, decrypts it to a temp cache
    /// copy for viewing — [onResult] gets that temp file's path, or nil if the password was wrong
    /// or verification failed.
    func verifyPassword(document: ScannedDocument, password: String, onResult: @escaping (String?) -> Void) {
        Task {
            let url = URL(fileURLWithPath: document.pdfPath)
            guard repository.verifyDocumentPassword(pdfURL: url, password: password) else {
                onResult(nil)
                return
            }
            do {
                let temp = try repository.decryptToTempCopy(pdfURL: url, password: password)
                onResult(temp.path)
            } catch {
                onResult(nil)
            }
        }
    }
}
