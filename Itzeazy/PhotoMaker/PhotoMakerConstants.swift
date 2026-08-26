import Foundation
import CoreGraphics

// MARK: - PhotoMakerConstants
// Mirrors the tuned constants in Android's PhotoMakerRepository.kt so the iOS port produces
// visually equivalent results, not just structurally similar code.

enum PhotoMakerConstants {

    // MARK: Print / official sizing

    static let officialPhotoPrintDPI: Double = 600

    // MARK: Auto Crop / Face Center (face-bbox → output-frame math)

    static let autoCropFaceHeightRatio: CGFloat = 0.75   // face bbox height as fraction of output frame height
    static let autoCropEyeLineRatio: CGFloat = 0.45      // eye line position from top as fraction of frame height
    static let fallbackEyeHeightRatioInFace: CGFloat = 0.4  // used only when eye landmarks are missing

    // MARK: Segmentation

    static let personConfidenceThreshold: Float = 0.6   // hard threshold, no edge feathering — matches Android

    // MARK: Brightness Fix

    static let brightnessFixTargetLuminance: Double = 128.0
    static let brightnessFixMaxAdjustment: Double = 60.0

    // MARK: Contrast Balance (CLAHE-equivalent)

    static let claheClipLimit: Double = 2.0
    static let claheTileGridSize: Int = 8   // 8x8 tiles

    // MARK: Skin Tone Balance (gray-world)

    static let skinToneMinScale: Double = 0.85
    static let skinToneMaxScale: Double = 1.15

    // MARK: Enhance Quality (upscale + unsharp mask)

    static let enhanceQualityUpscaleFactor: CGFloat = 1.5
    static let enhanceQualityUnsharpSigma: Double = 3.0
    static let enhanceQualityUnsharpAmount: Double = 0.8

    // MARK: Manual brightness/contrast toolbar cycle

    static let manualContrastStep: Double = 0.25   // contrast = 1 + level * step, level in {-1,0,1}
    static let manualBrightnessStep: Double = 30    // translate += level * step

    // MARK: Working-image cap

    static let maxWorkingDimension: CGFloat = 2048   // every decode is capped here, incl. final export

    // MARK: Size presets

    static let sizePresets: [PhotoSizePreset] = [
        PhotoSizePreset(label: "Passport (35x45mm)", widthMm: 35, heightMm: 45),
        PhotoSizePreset(label: "Visa (2x2\")", widthMm: 50.8, heightMm: 50.8),
        PhotoSizePreset(label: "PAN Card (35mm x 25mm)", widthMm: 35, heightMm: 25),
        PhotoSizePreset(label: "Custom", widthMm: nil, heightMm: nil)
    ]

    // MARK: Custom size quick-fill chips (mm)

    static let customSizeQuickFills: [(label: String, widthMm: Double, heightMm: Double)] = [
        ("35×45mm", 35, 45),
        ("2×2in", 50.8, 50.8),
        ("51×51mm", 51, 51),
        ("50×70mm", 50, 70)
    ]
}
