import SwiftUI
import Combine

/// The scan mode + (for ID Scan) side option + captured pages a completed scan hands off to the
/// Edit screen.
struct DocumentScanProceedResult {
    let mode: DocumentScanTab
    let idSideOption: IdScanSideOption?
    let pages: [CapturedPage]
}

@MainActor
final class DocumentScannerCameraViewModel: ObservableObject {
    @Published var toastMessage: String?

    func onScanIssue(_ message: String) {
        toastMessage = message
    }

    /// Wraps a completed scan's page URLs into the result the Edit screen expects, or nil if
    /// there's nothing to hand off.
    func buildProceedResult(mode: DocumentScanTab, idSideOption: IdScanSideOption?, pageURLs: [URL]) -> DocumentScanProceedResult? {
        guard !pageURLs.isEmpty else { return nil }
        let pages = pageURLs.map { CapturedPage(id: UUID().uuidString, url: $0) }
        return DocumentScanProceedResult(mode: mode, idSideOption: idSideOption, pages: pages)
    }
}
