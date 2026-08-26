import Foundation
import CoreGraphics

// MARK: - PhotoMakerFeature
// One marketing bullet on the entry screen (White Background, AI Auto Crop, etc.)

struct PhotoMakerFeature: Identifiable {
    let id = UUID()
    let iconSystemName: String
    let title: String
    let description: String
}

// MARK: - AiAdjustmentOption
// One tile in the "AI Intelligence Adjustments" grid on the editor screen.

struct AiAdjustmentOption: Identifiable, Equatable {
    let id: String   // stable identity for grid diffing — the Android label, e.g. "Auto Crop"
    let iconAssetName: String
    let label: String
}

// MARK: - PhotoSizePreset
// A quick-pick photo size preset in real physical millimeters — used both for the crop guide's
// aspect ratio and to size each tile when printing a sheet of copies. Nil dimensions mean
// freeform (Custom, before the user has applied specific dimensions).

struct PhotoSizePreset: Identifiable, Equatable {
    let id: String   // the label doubles as identity, matches Android's list-of-labels approach
    let label: String
    let widthMm: Double?
    let heightMm: Double?

    var aspectRatio: Double? {
        guard let widthMm, let heightMm, heightMm != 0 else { return nil }
        return widthMm / heightMm
    }

    init(label: String, widthMm: Double?, heightMm: Double?) {
        self.id = label
        self.label = label
        self.widthMm = widthMm
        self.heightMm = heightMm
    }
}

// MARK: - PersonSegmentationMask
// One Vision person-segmentation result: a per-pixel person-confidence value (0...1) at
// width x height — always the resolution Vision returned the mask at (frequently smaller than
// the source image), so consumers must ratio-scale coordinates rather than assume a 1:1 match.

struct PersonSegmentationMask {
    let width: Int
    let height: Int
    let confidences: [Float]

    /// Nearest-neighbor sample, ratio-scaled from full-image pixel coordinates — mirrors
    /// Android's mask lookup (no bilinear interpolation at the mask/bitmap resolution mismatch).
    func confidence(atImageX x: Int, y: Int, imageWidth: Int, imageHeight: Int) -> Float {
        guard imageWidth > 0, imageHeight > 0 else { return 0 }
        let maskX = min(width - 1, max(0, x * width / imageWidth))
        let maskY = min(height - 1, max(0, y * height / imageHeight))
        return confidences[maskY * width + maskX]
    }
}

// MARK: - DetectedFace
// A Vision face-detection result reduced to just what Auto Crop / Face Center need:
// boundingBox in source-image pixel coordinates (origin top-left, matching UIKit/Core Graphics
// image-space convention used throughout this module), and eyeLineY — the average vertical
// pixel position of both eyes, or just one if only one landmark was detected. Nil when neither
// eye landmark was found (e.g. a steep profile angle); callers fall back to an offset within
// boundingBox in that case.

struct DetectedFace {
    let boundingBox: CGRect
    let eyeLineY: CGFloat?
}
