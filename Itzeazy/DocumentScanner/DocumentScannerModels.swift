import Foundation

// MARK: - DocumentScanTab
// Which scan mode the user picked on the scanner's chooser screen.

enum DocumentScanTab: Equatable {
    case documentScan
    case idScan
}

// MARK: - IdScanSideOption
// Chosen from the ID Scan selection modal.

enum IdScanSideOption: Equatable {
    case oneSide
    case twoSide
}

// MARK: - CapturedPage
// One page captured during a scan session, held on disk (cache) until the user proceeds —
// mirrors Android's Uri-backed CapturedPage rather than keeping raw UIImages in memory, since a
// Document Scan session can hold up to 20 pages.

struct CapturedPage: Identifiable, Equatable {
    let id: String
    let url: URL
}

// MARK: - ScanPageDraft
// A captured page as it's being edited on the rotate screen — VisionKit's own scanner already
// crops/straightens it during capture, so there's nothing to track here beyond rotation.

struct ScanPageDraft: Identifiable, Equatable {
    let id: String
    let sourceURL: URL
    var rotationDegrees: Int = 0
}

// MARK: - DocScanFilter
// The color/clarity treatment applied to every page in a scan session at once.

enum DocScanFilter: String, CaseIterable, Identifiable, Equatable {
    case original
    case magicColour1
    case magicColour2
    case magicWhite
    case blackAndWhite

    var id: String { rawValue }

    var label: String {
        switch self {
        case .original: return "Original"
        case .magicColour1: return "Magic Colour 1"
        case .magicColour2: return "Magic Colour 2"
        case .magicWhite: return "Magic White"
        case .blackAndWhite: return "B&W"
        }
    }
}

// MARK: - ScanSession
// Carries a scan attempt across the Camera -> Edit -> Filter -> Review screens. Held by the
// Document Scanner's own flow host and threaded through each screen's onProceed/onNext callback —
// the same hoisting pattern Android's MainScreen uses.

struct ScanSession: Equatable {
    let mode: DocumentScanTab
    let idSideOption: IdScanSideOption?
    let rawPages: [CapturedPage]
    var editedPageURLs: [URL] = []
    var filteredPageURLs: [URL] = []
    /// If this session was started from a document's Review screen via "Add > Scan New Page" (a
    /// continuation of that document, not a brand-new one), the id of the document being
    /// continued — see DocumentScannerReviewViewModel.initSession, which appends this session's
    /// pages onto that document's existing ones rather than starting a fresh document from
    /// scratch. Nil for an ordinary new scan.
    var appendToDocumentId: String?
}

// MARK: - ScannedDocument
// A saved, finished scan — one row in the on-device document index.

struct ScannedDocument: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var folderName: String
    var pageCount: Int
    var fileSizeBytes: Int64
    var pdfPath: String
    var thumbnailPath: String
    let createdAtMillis: Int64
    var isPasswordProtected: Bool = false
    /// If this document was built FROM another one (Split/Rearrange/e-Sign, or "Add > Scan New
    /// Page" continuing an existing document — all of which produce a new document rather than
    /// overwriting the source), the id of the root original it's derived from. Always the true
    /// root, even for a derivative of a derivative, so the Review screen can show the whole
    /// family of versions together with one flat lookup instead of walking a chain. Nil for an
    /// original scan.
    var sourceDocumentId: String?
}

// MARK: - DocumentFolder
// A user-organized group of documents — one row in the on-device folder index.

struct DocumentFolder: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    let createdAtMillis: Int64
}

/// The name newly scanned documents land in until the user files them elsewhere — matches the
/// seeded "Unnamed Folder" entry in the folder index, not a document without a folder.
let unnamedFolderName = "Unnamed Folder"

/// Fixed id for the seeded Unnamed Folder entry, so it can be identified regardless of rename.
let unnamedFolderId = "unnamed-folder"
