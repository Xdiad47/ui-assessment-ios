import Foundation
import Vision
import UIKit

// MARK: - DocumentScannerOCRService
// On-device text recognition over every page of a PDF — mirrors Android's ML Kit Latin-script
// recognizer using Vision's VNRecognizeTextRequest. Latin-only here too (matching Android's own
// scope, not a gap to fix) — Vision's default recognition languages cover Latin scripts; it won't
// read Devanagari or other Indic scripts some scanned government forms use, same limitation
// Android's ML Kit recognizer has.

enum DocumentScannerOCRService {

    /// Runs recognition over every page and joins the results — pages are separated with a
    /// heading when there's more than one, matching Android's recognizeText.
    static func recognizeText(pdfURL: URL) throws -> String {
        let pages = try DocumentScannerPDFService.renderPagesAsImages(url: pdfURL)
        return try pages.enumerated().map { index, image in
            let text = try recognizeText(in: image)
            return pages.count > 1 ? "— Page \(index + 1) —\n\(text)" : text
        }.joined(separator: "\n\n")
    }

    private static func recognizeText(in image: UIImage) throws -> String {
        guard let cgImage = image.cgImage else { return "" }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        try handler.perform([request])
        guard let observations = request.results else { return "" }
        return observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
    }
}
