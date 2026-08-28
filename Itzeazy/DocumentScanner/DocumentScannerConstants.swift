import Foundation

// MARK: - DocumentScannerConstants
// Mirrors the tuned constants in Android's DocumentScannerRepository.kt so filter output stays
// visually equivalent, not just structurally similar code.

enum DocumentScannerConstants {

    // MARK: Filters — Magic White's background-blur kernel is sized relative to the image so
    // shadow removal scales with resolution instead of a fixed pixel count too weak on a large photo.

    static let magicWhiteBlurDivisor = 8

    // MARK: Filters — CLAHE clip limits for the two Magic Colour variants; higher clip = punchier
    // local contrast. Colour 2 also gets a mild warm shift so the two read as distinct presets.

    static let magicColour1ClaheClip: Double = 3.0
    static let magicColour2ClaheClip: Double = 1.8
    static let claheTileGridSize = 8
    static let magicColour2WarmShift: Double = 8.0

    // MARK: Filters — B&W uses a local (adaptive) threshold rather than a single global cutoff,
    // since a document photo's lighting is rarely even across the whole page.

    static let bwAdaptiveBlockSize = 35
    static let bwAdaptiveC: Double = 15.0

    // MARK: Working-image cap — every page decode is capped here (matches Photo Maker's own cap).

    static let maxWorkingDimension: CGFloat = 2048

    // MARK: Thumbnails

    static let thumbnailMaxDimension: CGFloat = 320
    static let filterThumbnailMaxDimension: CGFloat = 200

    // MARK: Capture — page limits handed to VNDocumentCameraViewController's session (VisionKit
    // has no "unlimited" sentinel, so Document Scan just gets a generously high cap).

    static let documentScanPageLimit = 20

    // MARK: Folders — starter set seeded the first time the folder index is ever loaded.

    static let defaultSeedFolderNames = ["Expenditure", "Bills", "ID Cards", "Notes", unnamedFolderName]

    // MARK: Passwords

    static let minPasswordLength = 6
}
