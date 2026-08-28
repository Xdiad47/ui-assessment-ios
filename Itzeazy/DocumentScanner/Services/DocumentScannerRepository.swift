import Foundation
import UIKit

// MARK: - DocumentScannerRepositoryError

enum DocumentScannerRepositoryError: LocalizedError {
    case processingFailed(String)

    var errorDescription: String? {
        switch self {
        case .processingFailed(let message): return message
        }
    }
}

// MARK: - DocumentScannerRepository
// Document/folder index CRUD, thumbnail/PDF generation, and the "produces a brand-new derived
// document" family of operations (Split/Rearrange/Append/e-Sign/Import) — mirrors Android's
// DocumentScannerRepository.kt. Filter pixel math lives in DocumentScannerFilterService, OCR in
// DocumentScannerOCRService, and PDF build/render/compress/password in DocumentScannerPDFService;
// this type is the orchestration + on-device index layer, matching how Android's single
// repository class is split by concern here into four Swift services.

final class DocumentScannerRepository {
    static let shared = DocumentScannerRepository()
    private init() {}

    // MARK: - Image load/save

    /// Capped well above any on-screen/print/PDF need so a large scanned photo doesn't get decoded
    /// (and held in memory across filter/rotate/merge steps) at full resolution.
    func decodeSampledImage(at url: URL, maxDimension: CGFloat = DocumentScannerConstants.maxWorkingDimension) throws -> UIImage {
        guard let data = try? Data(contentsOf: url), let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw DocumentScannerRepositoryError.processingFailed("We couldn't read the scanned page. Please try again.")
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw DocumentScannerRepositoryError.processingFailed("We couldn't read the scanned page. Please try again.")
        }
        return UIImage(cgImage: cgImage)
    }

    func rotateImage(_ image: UIImage, degrees: Int) -> UIImage {
        let normalized = ((degrees % 360) + 360) % 360
        guard normalized != 0 else { return image }
        let radians = CGFloat(normalized) * .pi / 180
        let newSize: CGSize = (normalized == 90 || normalized == 270)
            ? CGSize(width: image.size.height, height: image.size.width)
            : image.size
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { ctx in
            ctx.cgContext.translateBy(x: newSize.width / 2, y: newSize.height / 2)
            ctx.cgContext.rotate(by: radians)
            image.draw(in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2, width: image.size.width, height: image.size.height))
        }
    }

    func saveImageToCache(_ image: UIImage, subdir: String) throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(subdir, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("page_\(UUID().uuidString).jpg")
        guard let data = image.jpegData(compressionQuality: 0.92) else {
            throw DocumentScannerRepositoryError.processingFailed("Couldn't save the page.")
        }
        try data.write(to: url, options: .atomic)
        return url
    }

    /// Stacks two ID-scan sides (front, back) vertically onto one page, matching the narrower
    /// width — the merge-to-one-page behavior for Two Side ID Scan.
    func mergeVertically(top: UIImage, bottom: UIImage) -> UIImage {
        let targetWidth = min(top.size.width, bottom.size.width)
        func scaled(_ image: UIImage) -> UIImage {
            guard image.size.width != targetWidth else { return image }
            let targetSize = CGSize(width: targetWidth, height: (image.size.height * targetWidth / image.size.width).rounded())
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            return renderer.image { ctx in
                ctx.cgContext.interpolationQuality = .high
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }
        }
        let scaledTop = scaled(top)
        let scaledBottom = scaled(bottom)
        let gap = max(12, (targetWidth * 0.04).rounded())
        let totalSize = CGSize(width: targetWidth, height: scaledTop.size.height + gap + scaledBottom.size.height)
        let renderer = UIGraphicsImageRenderer(size: totalSize)
        return renderer.image { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: totalSize))
            scaledTop.draw(at: .zero)
            scaledBottom.draw(at: CGPoint(x: 0, y: scaledTop.size.height + gap))
        }
    }

    func generateThumbnail(_ image: UIImage, docId: String) throws -> String {
        let maxDim = DocumentScannerConstants.thumbnailMaxDimension
        let scale = maxDim / max(image.size.width, image.size.height)
        var thumb = image
        if scale < 1 {
            let targetSize = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            thumb = renderer.image { ctx in
                ctx.cgContext.interpolationQuality = .high
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }
        }
        let url = documentsDir().appendingPathComponent("\(docId)_thumb.jpg")
        guard let data = thumb.jpegData(compressionQuality: 0.85) else {
            throw DocumentScannerRepositoryError.processingFailed("Couldn't save the thumbnail.")
        }
        try data.write(to: url, options: .atomic)
        return url.path
    }

    func generatePDF(pages: [UIImage], docId: String) throws -> URL {
        let data = DocumentScannerPDFService.generatePDF(pages: pages)
        let url = documentsDir().appendingPathComponent("\(docId).pdf")
        try data.write(to: url, options: .atomic)
        return url
    }

    func documentsDir() -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("documents", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - Document index — a small Codable-backed JSON file, no DB needed for a flat,
    // occasionally-written list like this.

    private func indexFileURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("document_scanner_index.json")
    }

    func loadDocumentIndex() -> [ScannedDocument] {
        guard let data = try? Data(contentsOf: indexFileURL()) else { return [] }
        return (try? JSONDecoder().decode([ScannedDocument].self, from: data)) ?? []
    }

    private func saveDocumentIndex(_ documents: [ScannedDocument]) {
        guard let data = try? JSONEncoder().encode(documents) else { return }
        try? data.write(to: indexFileURL(), options: .atomic)
    }

    func addDocument(_ document: ScannedDocument) {
        saveDocumentIndex(loadDocumentIndex() + [document])
    }

    func renameDocument(id: String, newName: String) {
        let updated = loadDocumentIndex().map { doc -> ScannedDocument in
            guard doc.id == id else { return doc }
            var copy = doc; copy.name = newName; return copy
        }
        saveDocumentIndex(updated)
    }

    func deleteDocument(id: String) {
        let documents = loadDocumentIndex()
        guard let target = documents.first(where: { $0.id == id }) else { return }
        try? FileManager.default.removeItem(atPath: target.pdfPath)
        try? FileManager.default.removeItem(atPath: target.thumbnailPath)
        saveDocumentIndex(documents.filter { $0.id != id })
    }

    func moveDocumentToFolder(id: String, folderName: String) {
        let updated = loadDocumentIndex().map { doc -> ScannedDocument in
            guard doc.id == id else { return doc }
            var copy = doc; copy.folderName = folderName; return copy
        }
        saveDocumentIndex(updated)
    }

    // MARK: - Folder index — same flat Codable-backed JSON pattern as the document index.

    private func foldersIndexFileURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("document_scanner_folders.json")
    }

    /// Loads the persisted folder list, seeding it with a starter set the first time this is ever
    /// called (Expenditure/Bills/ID Cards/Notes/Unnamed Folder). Once seeded, the persisted file
    /// is the sole source of truth, so deleting a seed folder keeps it deleted across future
    /// launches instead of it silently reappearing.
    func loadFolders() -> [DocumentFolder] {
        let url = foldersIndexFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            let now = Int64(Date().timeIntervalSince1970 * 1000)
            let seeded = DocumentScannerConstants.defaultSeedFolderNames.enumerated().map { index, name in
                DocumentFolder(
                    id: name == unnamedFolderName ? unnamedFolderId : UUID().uuidString,
                    name: name,
                    createdAtMillis: now + Int64(index)
                )
            }
            saveFolders(seeded)
            return seeded
        }
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([DocumentFolder].self, from: data)) ?? []
    }

    private func saveFolders(_ folders: [DocumentFolder]) {
        guard let data = try? JSONEncoder().encode(folders) else { return }
        try? data.write(to: foldersIndexFileURL(), options: .atomic)
    }

    func addFolder(name: String) -> DocumentFolder {
        let folder = DocumentFolder(id: UUID().uuidString, name: name, createdAtMillis: Int64(Date().timeIntervalSince1970 * 1000))
        saveFolders(loadFolders() + [folder])
        return folder
    }

    func renameFolder(id: String, newName: String) {
        let updated = loadFolders().map { folder -> DocumentFolder in
            guard folder.id == id else { return folder }
            var copy = folder; copy.name = newName; return copy
        }
        saveFolders(updated)
    }

    /// Deletes the folder and reassigns any documents inside it back to the Unnamed Folder.
    func deleteFolder(id: String) {
        let folders = loadFolders()
        guard let target = folders.first(where: { $0.id == id }) else { return }
        saveFolders(folders.filter { $0.id != id })
        let documents = loadDocumentIndex()
        let updated = documents.map { doc -> ScannedDocument in
            guard doc.folderName == target.name else { return doc }
            var copy = doc; copy.folderName = unnamedFolderName; return copy
        }
        saveDocumentIndex(updated)
    }

    // MARK: - Password protection

    func protectDocumentWithPassword(_ document: ScannedDocument, password: String) throws -> ScannedDocument {
        try DocumentScannerPDFService.protect(url: URL(fileURLWithPath: document.pdfPath), password: password)
        var updated = document
        updated.isPasswordProtected = true
        saveDocumentIndex(loadDocumentIndex().map { $0.id == updated.id ? updated : $0 })
        return updated
    }

    func verifyDocumentPassword(pdfURL: URL, password: String) -> Bool {
        DocumentScannerPDFService.verifyPassword(url: pdfURL, password: password)
    }

    func decryptToTempCopy(pdfURL: URL, password: String) throws -> URL {
        try DocumentScannerPDFService.decryptToTempCopy(url: pdfURL, password: password)
    }

    // MARK: - Print

    func printDocument(pdfURL: URL, jobName: String) throws {
        let data = try Data(contentsOf: pdfURL)
        DocumentScannerPDFService.printDocument(data: data, jobName: jobName)
    }

    // MARK: - Share as JPEG

    func renderPagesAsJPEGs(pdfURL: URL, subdir: String) throws -> [URL] {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(subdir, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let images = try DocumentScannerPDFService.renderPagesAsImages(url: pdfURL)
        return try images.enumerated().map { index, image in
            let url = dir.appendingPathComponent("page_\(index + 1)_\(UUID().uuidString).jpg")
            guard let data = image.jpegData(compressionQuality: 0.92) else {
                throw DocumentScannerRepositoryError.processingFailed("Couldn't prepare the image.")
            }
            try data.write(to: url, options: .atomic)
            return url
        }
    }

    // MARK: - Compress

    /// Overwrites the document's PDF in place at the given scale and returns the new byte size.
    func compressPDF(document: ScannedDocument, scale: CGFloat) throws -> Int64 {
        let url = URL(fileURLWithPath: document.pdfPath)
        let data = try DocumentScannerPDFService.compressPDF(url: url, scale: scale)
        try data.write(to: url, options: .atomic)
        return Int64(data.count)
    }

    // MARK: - Split

    /// Builds a brand-new PDF (and thumbnail) from just [selectedIndices] of [source]'s pages,
    /// added to the document index as its own entry — Split extracts pages into a new document
    /// rather than mutating the original. Lands in the Unnamed Folder by default, and is tagged
    /// with [source]'s root sourceDocumentId (itself, if [source] has none) so the new document
    /// surfaces alongside [source] as one family on the Review screen.
    func splitPDF(source: ScannedDocument, selectedIndices: [Int]) throws -> ScannedDocument {
        let pages = try DocumentScannerPDFService.renderPagesAsImages(url: URL(fileURLWithPath: source.pdfPath))
        let selectedPages = selectedIndices.sorted().compactMap { $0 < pages.count ? pages[$0] : nil }
        guard let firstPage = selectedPages.first else {
            throw DocumentScannerRepositoryError.processingFailed("Select at least one page to split.")
        }
        return try makeDerivedDocument(pages: selectedPages, firstPage: firstPage, namedFrom: source, suffix: "-split", root: source.sourceDocumentId ?? source.id)
    }

    // MARK: - Rearrange

    /// Builds a brand-new PDF from [document]'s pages in [newOrder] (a permutation of page
    /// indices) — same "don't touch the source" shape as splitPDF, so the original is left
    /// completely untouched rather than overwritten in place.
    func rearrangePDF(document: ScannedDocument, newOrder: [Int]) throws -> ScannedDocument {
        let pages = try DocumentScannerPDFService.renderPagesAsImages(url: URL(fileURLWithPath: document.pdfPath))
        let reordered = newOrder.compactMap { $0 < pages.count ? pages[$0] : nil }
        guard let firstPage = reordered.first else {
            throw DocumentScannerRepositoryError.processingFailed("Couldn't rearrange the document.")
        }
        return try makeDerivedDocument(pages: reordered, firstPage: firstPage, namedFrom: document, suffix: "-rearranged", root: document.sourceDocumentId ?? document.id)
    }

    // MARK: - Append (Add > Scan New Page continuation)

    /// Builds a brand-new PDF combining [target]'s existing pages with [newPages] appended after
    /// them — so scanning another page onto an existing document doesn't erase the version that
    /// was there before it.
    func appendPages(to target: ScannedDocument, newPages: [UIImage]) throws -> ScannedDocument {
        let existingPages = try DocumentScannerPDFService.renderPagesAsImages(url: URL(fileURLWithPath: target.pdfPath))
        let combined = existingPages + newPages
        guard let firstPage = combined.first else {
            throw DocumentScannerRepositoryError.processingFailed("Couldn't update the document.")
        }
        return try makeDerivedDocument(pages: combined, firstPage: firstPage, namedFrom: target, suffix: "-updated", root: target.sourceDocumentId ?? target.id)
    }

    // MARK: - Import

    /// Imports an existing PDF the user picked from device storage ("Add > Add New PDF") — copies
    /// its bytes into the app's own documents dir and indexes it as a new, standalone document. No
    /// sourceDocumentId — it isn't derived from anything already in the app, so it doesn't join
    /// any existing family on the Review screen.
    func importPDF(from sourceURL: URL, displayName: String) throws -> ScannedDocument {
        let docId = UUID().uuidString
        let pdfURL = documentsDir().appendingPathComponent("\(docId).pdf")
        let data = try Data(contentsOf: sourceURL)
        try data.write(to: pdfURL, options: .atomic)
        let pages = try DocumentScannerPDFService.renderPagesAsImages(url: pdfURL)
        guard let firstPage = pages.first else {
            try? FileManager.default.removeItem(at: pdfURL)
            throw DocumentScannerRepositoryError.processingFailed("That file doesn't look like a valid PDF.")
        }
        let thumbPath = try generateThumbnail(firstPage, docId: docId)
        var name = displayName
        if name.lowercased().hasSuffix(".pdf") { name = String(name.dropLast(4)) }
        if name.trimmingCharacters(in: .whitespaces).isEmpty { name = "Imported_Doc" }
        let newDoc = ScannedDocument(
            id: docId, name: name, folderName: unnamedFolderName, pageCount: pages.count,
            fileSizeBytes: fileSize(at: pdfURL), pdfPath: pdfURL.path, thumbnailPath: thumbPath,
            createdAtMillis: Int64(Date().timeIntervalSince1970 * 1000)
        )
        addDocument(newDoc)
        return newDoc
    }

    // MARK: - e-Sign

    /// Draws [signature] onto [page] at the given position/size (all in [page]'s own pixel space)
    /// — flattens the signature into the page image itself.
    func compositeSignature(_ signature: UIImage, onto page: UIImage, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: page.size)
        return renderer.image { _ in
            page.draw(at: .zero)
            signature.draw(in: CGRect(x: x, y: y, width: width, height: height))
        }
    }

    /// Builds a brand-new PDF from [document]'s pages with the pages at the indices in
    /// [pageEdits] (page index -> composited signature page) replaced — signing a document
    /// doesn't erase the unsigned version it was signed from.
    func signPages(document: ScannedDocument, pageEdits: [Int: UIImage]) throws -> ScannedDocument {
        var pages = try DocumentScannerPDFService.renderPagesAsImages(url: URL(fileURLWithPath: document.pdfPath))
        for (index, image) in pageEdits where index < pages.count {
            pages[index] = image
        }
        guard let firstPage = pages.first else {
            throw DocumentScannerRepositoryError.processingFailed("Couldn't save the signature.")
        }
        return try makeDerivedDocument(pages: pages, firstPage: firstPage, namedFrom: document, suffix: "-e-sign", root: document.sourceDocumentId ?? document.id)
    }

    // MARK: - Shared "derived document" builder

    private func makeDerivedDocument(pages: [UIImage], firstPage: UIImage, namedFrom source: ScannedDocument, suffix: String, root: String) throws -> ScannedDocument {
        let docId = UUID().uuidString
        let pdfURL = try generatePDF(pages: pages, docId: docId)
        let thumbPath = try generateThumbnail(firstPage, docId: docId)
        let newDoc = ScannedDocument(
            id: docId, name: "\(source.name)\(suffix)", folderName: unnamedFolderName, pageCount: pages.count,
            fileSizeBytes: fileSize(at: pdfURL), pdfPath: pdfURL.path, thumbnailPath: thumbPath,
            createdAtMillis: Int64(Date().timeIntervalSince1970 * 1000), sourceDocumentId: root
        )
        addDocument(newDoc)
        return newDoc
    }

    func fileSize(at url: URL) -> Int64 {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? NSNumber else { return 0 }
        return size.int64Value
    }
}
