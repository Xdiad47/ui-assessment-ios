#if DEBUG
import UIKit

// MARK: - DocumentScannerPreviewSupport
// Fixtures shared by every #Preview in this feature. Writes real sample images/PDFs to disk (via
// the same DocumentScannerPDFService used at runtime) so canvas previews render actual page
// content instead of the empty/error states DocumentThumbnailImage and the PDF-backed view models
// fall back to when a path doesn't resolve. DEBUG-only — never compiled into the shipping app.

enum DocumentScannerPreviewSupport {

    private static let palette: [UIColor] = [
        UIColor(red: 0.85, green: 0.88, blue: 0.98, alpha: 1),
        UIColor(red: 0.90, green: 0.95, blue: 0.88, alpha: 1),
        UIColor(red: 0.98, green: 0.92, blue: 0.85, alpha: 1),
        UIColor(red: 0.95, green: 0.87, blue: 0.95, alpha: 1)
    ]

    static func sampleImage(text: String, index: Int = 0) -> UIImage {
        let size = CGSize(width: 827, height: 1169)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            palette[index % palette.count].setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let inset: CGFloat = 48
            UIColor.white.withAlphaComponent(0.92).setFill()
            UIBezierPath(roundedRect: CGRect(x: inset, y: inset, width: size.width - inset * 2, height: size.height - inset * 2), cornerRadius: 16).fill()
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            (text as NSString).draw(
                in: CGRect(x: 0, y: size.height / 2 - 30, width: size.width, height: 60),
                withAttributes: [.font: UIFont.boldSystemFont(ofSize: 42), .foregroundColor: UIColor.darkGray, .paragraphStyle: paragraph]
            )
        }
    }

    private static func tempURL(ext: String) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("scanner-preview-\(UUID().uuidString)").appendingPathExtension(ext)
    }

    static func writeTempImage(_ image: UIImage) -> URL {
        let url = tempURL(ext: "jpg")
        try? image.jpegData(compressionQuality: 0.9)?.write(to: url)
        return url
    }

    static func writeTempPDF(pageImages: [UIImage]) -> URL {
        let url = tempURL(ext: "pdf")
        try? DocumentScannerPDFService.generatePDF(pages: pageImages).write(to: url)
        return url
    }

    static func sampleCapturedPages(count: Int = 3) -> [CapturedPage] {
        (0..<count).map { i in
            CapturedPage(id: "preview-page-\(i)", url: writeTempImage(sampleImage(text: "Page \(i + 1)", index: i)))
        }
    }

    static func samplePageURLs(count: Int = 3) -> [URL] {
        sampleCapturedPages(count: count).map(\.url)
    }

    /// A sample saved document. Pass `withRealFiles: false` for previews that only read the
    /// document's metadata (name/page count/size) and never touch disk.
    static func sampleDocument(
        id: String = "preview-doc",
        name: String = "Aadhar Card",
        folderName: String = "ID Cards",
        pageCount: Int = 2,
        withRealFiles: Bool = true
    ) -> ScannedDocument {
        var pdfPath = ""
        var thumbnailPath = ""
        if withRealFiles {
            let images = (0..<pageCount).map { sampleImage(text: "\(name) — Page \($0 + 1)", index: $0) }
            pdfPath = writeTempPDF(pageImages: images).path
            thumbnailPath = writeTempImage(images[0]).path
        }
        return ScannedDocument(
            id: id,
            name: name,
            folderName: folderName,
            pageCount: pageCount,
            fileSizeBytes: 245_000,
            pdfPath: pdfPath,
            thumbnailPath: thumbnailPath,
            createdAtMillis: Int64(Date().timeIntervalSince1970 * 1000)
        )
    }

    static func sampleSession(pageCount: Int = 3) -> ScanSession {
        var session = ScanSession(mode: .documentScan, idSideOption: nil, rawPages: sampleCapturedPages(count: pageCount))
        session.editedPageURLs = session.rawPages.map(\.url)
        session.filteredPageURLs = session.rawPages.map(\.url)
        return session
    }
}
#endif
