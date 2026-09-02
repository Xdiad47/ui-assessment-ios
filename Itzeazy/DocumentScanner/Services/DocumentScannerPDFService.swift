import Foundation
import UIKit
import PDFKit

// MARK: - DocumentScannerPDFServiceError

enum DocumentScannerPDFServiceError: LocalizedError {
    case invalidPDF
    case wrongPassword
    case processingFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidPDF: return "That file doesn't look like a valid PDF."
        case .wrongPassword: return "Incorrect password."
        case .processingFailed(let message): return message
        }
    }
}

// MARK: - DocumentScannerPDFService
// Build/render/compress/password-protect PDFs via PDFKit — mirrors the parts of Android's
// DocumentScannerRepository that lean on PdfDocument/PdfRenderer/PDFBox-Android. Password
// protection is genuinely simpler here: PDFKit supports encryption natively, unlike Android's own
// PdfDocument/PdfRenderer which needed the separate PDFBox-Android library bolted on.

enum DocumentScannerPDFService {

    // MARK: - Build

    /// Renders each page image as its own PDF page, sized 1px = 1pt so no paper-fitting logic is
    /// needed — matches Android's PdfDocument.PageInfo.Builder(bitmap.width, bitmap.height, ...).
    static func generatePDF(pages: [UIImage]) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: .zero)
        return renderer.pdfData { context in
            for image in pages {
                let pageRect = CGRect(origin: .zero, size: image.size)
                context.beginPage(withBounds: pageRect, pageInfo: [:])
                image.draw(in: pageRect)
            }
        }
    }

    // MARK: - Read

    /// Renders every page of the PDF at [url] to a full-resolution in-memory UIImage — the shared
    /// read path for Compress/Split/Rearrange/e-Sign/OCR, all of which need to rebuild a PDF from
    /// its own pages, matching Android's renderPdfPagesAsBitmaps.
    static func renderPagesAsImages(url: URL) throws -> [UIImage] {
        guard let document = PDFDocument(url: url) else { throw DocumentScannerPDFServiceError.invalidPDF }
        return renderPages(document)
    }

    static func renderPagesAsImages(data: Data) throws -> [UIImage] {
        guard let document = PDFDocument(data: data) else { throw DocumentScannerPDFServiceError.invalidPDF }
        return renderPages(document)
    }

    static func pageCount(url: URL) -> Int {
        PDFDocument(url: url)?.pageCount ?? 0
    }

    private static func renderPages(_ document: PDFDocument) -> [UIImage] {
        var images: [UIImage] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            let bounds = page.bounds(for: .mediaBox)
            guard bounds.width > 0, bounds.height > 0 else { continue }
            let renderer = UIGraphicsImageRenderer(size: bounds.size)
            let image = renderer.image { ctx in
                UIColor.white.setFill()
                ctx.fill(bounds)
                // PDF/CoreGraphics pages are bottom-left origin, y-up; UIGraphicsImageRenderer's
                // context is top-left origin, y-down — flip before drawing or the page renders upside down.
                ctx.cgContext.translateBy(x: 0, y: bounds.height)
                ctx.cgContext.scaleBy(x: 1, y: -1)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            images.append(image)
        }
        return images
    }

    // MARK: - Compress

    /// Re-renders every page at [scale] of its original resolution before rebuilding the PDF —
    /// downscaling pixel dimensions is the reliable file-size lever, matching Android's compressPdf.
    static func compressPDF(url: URL, scale: CGFloat) throws -> Data {
        let pages = try renderPagesAsImages(url: url)
        guard scale < 1 else { return generatePDF(pages: pages) }
        let scaledPages = pages.map { image -> UIImage in
            let targetSize = CGSize(width: max(1, image.size.width * scale), height: max(1, image.size.height * scale))
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            return renderer.image { ctx in
                ctx.cgContext.interpolationQuality = .high
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }
        }
        return generatePDF(pages: scaledPages)
    }

    // MARK: - Password protection

    /// Encrypts the PDF at [url] in place with [password] (used as both owner and user password —
    /// the UI only collects one password field), matching Android's PDFBox-based protection.
    static func protect(url: URL, password: String) throws {
        guard let document = PDFDocument(url: url) else { throw DocumentScannerPDFServiceError.invalidPDF }
        let options: [PDFDocumentWriteOption: Any] = [
            .userPasswordOption: password,
            .ownerPasswordOption: password
        ]
        // Write to a sibling temp file, then atomically swap it into place — never straight back
        // to `url`. PDFDocument loads its page content lazily from the backing file it was opened
        // from, so writing to that same URL can overwrite the bytes it's still reading mid-write.
        // The result looked structurally fine (right page count, right file size) but every page
        // rendered blank, because the page content itself got clobbered while `document` was
        // still faulting it in from disk. Writing elsewhere first means the read and the write
        // never touch the same bytes at the same time.
        let tempURL = url.deletingLastPathComponent()
            .appendingPathComponent(".\(UUID().uuidString)_protecting.pdf")
        guard document.write(to: tempURL, withOptions: options) else {
            try? FileManager.default.removeItem(at: tempURL)
            throw DocumentScannerPDFServiceError.processingFailed("Couldn't add a password.")
        }
        do {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: tempURL)
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            throw DocumentScannerPDFServiceError.processingFailed("Couldn't add a password.")
        }
    }

    /// True if [password] unlocks the PDF at [url] — any failure is treated as "doesn't unlock"
    /// rather than propagated, since this only gates whether to proceed opening the document.
    static func verifyPassword(url: URL, password: String) -> Bool {
        guard let document = PDFDocument(url: url), document.isEncrypted else { return false }
        return document.unlock(withPassword: password)
    }

    /// True if the PDF at [url] is still password-protected — used to block handing a locked
    /// file's raw URL straight to UIActivityViewController: most built-in share targets (Mail,
    /// Messages, Save to Files) can't preview or validate content they can't decrypt, so they
    /// exclude themselves entirely, and the system share sheet comes up with the presenting app's
    /// own icon as a generic fallback and no usable destinations — indistinguishable from the
    /// share button silently doing nothing.
    static func isEncrypted(url: URL) -> Bool {
        PDFDocument(url: url)?.isEncrypted ?? false
    }

    /// Produces a plaintext (no password) temporary copy of the PDF at [url] in the app cache,
    /// decrypted with [password] — needed because page-rendering elsewhere assumes an unlocked
    /// document. Only used for VIEWING a protected document; the original encrypted file on disk
    /// is never touched here.
    ///
    /// Renders pages to images and rebuilds the temp copy from scratch via generatePDF (the same
    /// path Compress/Split/e-Sign already use) rather than calling PDFDocument.write(to:) on the
    /// unlocked object directly. That used to unlock `document` in memory and hand the SAME object
    /// straight to PDFKit's own writer — but a PDFDocument that was loaded as encrypted isn't
    /// guaranteed to have every trace of that stripped from what write(to:) emits even after
    /// unlock() succeeds, so the "decrypted" file could come back still carrying stale encryption
    /// state: a fresh PDFDocument(url:) load of it would then be encrypted-but-unauthenticated,
    /// rendering as blank pages with an otherwise-correct page count — the password was accepted,
    /// but the file handed to the viewer was never truly plaintext. Rebuilding through
    /// UIGraphicsPDFRenderer-based generatePDF sidesteps PDFKit's writer entirely, so the output
    /// can't carry forward any encryption metadata — it was never encrypted in the first place.
    static func decryptToTempCopy(url: URL, password: String) throws -> URL {
        guard let document = PDFDocument(url: url), document.unlock(withPassword: password) else {
            throw DocumentScannerPDFServiceError.wrongPassword
        }
        let images = renderPages(document)
        guard !images.isEmpty else {
            throw DocumentScannerPDFServiceError.processingFailed("Couldn't unlock the document.")
        }
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("document_scanner_unlocked", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileURL = dir.appendingPathComponent("\(UUID().uuidString).pdf")
        try generatePDF(pages: images).write(to: fileURL, options: .atomic)
        return fileURL
    }

    // MARK: - Print

    /// Hands PDF data straight to the OS print dialog — "Save as PDF" is one of its default
    /// destinations, doubling as the export path, matching Android's Print Framework hand-off.
    static func printDocument(data: Data, jobName: String) {
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = jobName
        let controller = UIPrintInteractionController.shared
        controller.printInfo = printInfo
        controller.printingItem = data
        controller.present(animated: true, completionHandler: nil)
    }
}
