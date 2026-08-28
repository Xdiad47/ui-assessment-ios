import SwiftUI
import Combine

// MARK: - DocumentScannerOCRViewModel
// Mirrors Android's DocumentScannerOcrViewModel.kt.

@MainActor
final class DocumentScannerOCRViewModel: ObservableObject {
    @Published private(set) var recognizedText: String?
    @Published private(set) var isLoading = false
    @Published var toastMessage: String?

    private var lastLoadedDocId: String?

    func initDocument(_ document: ScannedDocument) {
        guard lastLoadedDocId != document.id else { return }
        lastLoadedDocId = document.id
        recognizedText = nil
        isLoading = true
        let path = document.pdfPath
        Task.detached(priority: .userInitiated) {
            do {
                let text = try DocumentScannerOCRService.recognizeText(pdfURL: URL(fileURLWithPath: path))
                await MainActor.run { [weak self] in
                    self?.recognizedText = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No text found in this document." : text
                    self?.isLoading = false
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.toastMessage = "Couldn't extract text. Please try again."
                    self?.recognizedText = ""
                    self?.isLoading = false
                }
            }
        }
    }
}
