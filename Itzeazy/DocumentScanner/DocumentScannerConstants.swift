import Foundation

// MARK: - DocumentScannerConstants
// Non-filter constants mirror the tuned values in Android's DocumentScannerRepository.kt so
// behavior stays equivalent, not just structurally similar code. The filter constants below are
// the exception — they tune a from-scratch Core Image (GPU) approximation of Android's
// OpenCV-based filters rather than mirroring OpenCV's own parameters, since Core Image has no
// direct equivalent to OpenCV's CLAHE/adaptive-threshold and needed its own tuning pass.

enum DocumentScannerConstants {

    // MARK: Filters — Core Image (GPU-accelerated) filter tuning. Blur/unsharp radii are
    // expressed as a divisor of the image's shorter side so the effective "local neighborhood"
    // size scales with resolution instead of staying a fixed pixel count that's too weak on the
    // full 2048px working image or too strong on the smaller filter preview.

    /// Magic White's background-estimate blur (divide-by-local-blur shadow removal).
    static let coreImageMagicWhiteBlurDivisor: CGFloat = 8
    /// B&W's illumination-normalize blur — smaller/more local than Magic White's, since adaptive
    /// thresholding needs to react to nearby lighting, not a whole-page background estimate.
    static let coreImageBWBlurDivisor: CGFloat = 25
    static let coreImageBWContrastBoost: Double = 1.4
    /// Levels for the final posterize step that pushes the illumination-normalized image to a
    /// crisp binary black/white, approximating a true per-pixel adaptive threshold.
    static let coreImageBWPosterizeLevels: Double = 2

    /// CIUnsharpMask stands in for CLAHE (Core Image has no local-histogram-equalization filter)
    /// as the "local contrast punch" for Magic Colour 1/2 — intensity mirrors the old CLAHE clip
    /// limits' relationship (Colour 1 punchier than Colour 2).
    static let coreImageMagicColourUnsharpRadius: CGFloat = 40
    static let coreImageMagicColour1UnsharpIntensity: Double = 1.4
    static let coreImageMagicColour2UnsharpIntensity: Double = 0.9
    static let coreImageMagicColourContrastBoost: Double = 1.12
    static let coreImageMagicColourSaturationBoost: Double = 1.08
    /// Colour 2's warm shift, applied as a direct R+/B- bias via CIColorMatrix (0...1 color
    /// space) rather than CITemperatureAndTint — same R+/B- nudge the old per-pixel
    /// implementation used, just without that filter's less certain shift direction.
    static let coreImageWarmShiftAmount: Double = 8.0 / 255.0

    // MARK: Working-image cap — every page decode is capped here (matches Photo Maker's own cap).

    static let maxWorkingDimension: CGFloat = 2048

    // MARK: Thumbnails

    static let thumbnailMaxDimension: CGFloat = 320
    static let filterThumbnailMaxDimension: CGFloat = 200

    // MARK: Filter screen's large preview — sized for its actual on-screen footprint (337x366pt,
    // see DocumentScannerFilterView.previewFrame), not the full working resolution. Comfortably
    // covers 3x Retina (~1100px) with margin; applying the filter math at 2048px for a preview
    // that never renders past ~1100px was pure wasted work (see DocumentScannerFilterViewModel).
    static let filterPreviewMaxDimension: CGFloat = 900

    // MARK: Capture — page limits handed to VNDocumentCameraViewController's session (VisionKit
    // has no "unlimited" sentinel, so Document Scan just gets a generously high cap).

    static let documentScanPageLimit = 20

    // MARK: Folders — starter set seeded the first time the folder index is ever loaded.

    static let defaultSeedFolderNames = ["Expenditure", "Bills", "ID Cards", "Notes", unnamedFolderName]

    // MARK: Passwords

    static let minPasswordLength = 6
}
