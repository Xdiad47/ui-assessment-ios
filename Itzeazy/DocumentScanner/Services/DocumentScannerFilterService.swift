import CoreGraphics
import CoreImage
import UIKit

// MARK: - DocumentScannerFilterService
// The 5 document filters, built on Core Image — GPU-accelerated via Metal, replacing what used to
// be hand-rolled scalar Swift math (shared with Photo Maker's Lab/CLAHE primitives). That CPU
// implementation had no path to the kind of hardware acceleration Android's OpenCV-based filters
// get from native SIMD code, which was the real source of this screen's lag, not just image size.
//
// Core Image has no built-in CLAHE or per-pixel adaptive-threshold filter, so Magic Colour 1/2 and
// B&W are deliberate approximations of the old exact-match-to-Android output, not equivalents:
// CIUnsharpMask stands in for CLAHE's local-histogram-equalization "punch," and B&W uses the same
// divide-by-local-blur illumination-normalize trick as Magic White, followed by a hard contrast
// push toward binary black/white, in place of a literal per-pixel adaptive threshold. Magic White
// itself maps almost exactly onto Core Image's own CIDivideBlendMode — that one is barely an
// approximation at all.

enum DocumentScannerFilterService {

    // A CIContext compiles and caches the Metal render pipeline the first time it's used, so
    // creating a fresh one per filter call would throw that setup cost away every time — one
    // shared instance for the whole app run, same principle as reusing a URLSession.
    private static let context = CIContext()

    static func applyFilter(_ image: UIImage, filter: DocScanFilter) -> UIImage {
        guard filter != .original, let cgImage = image.cgImage else { return image }
        let input = CIImage(cgImage: cgImage)
        let output: CIImage
        switch filter {
        case .original:
            return image
        case .blackAndWhite:
            output = applyBlackAndWhite(input)
        case .magicWhite:
            output = applyMagicWhite(input)
        case .magicColour1:
            output = applyMagicColour(input, unsharpIntensity: DocumentScannerConstants.coreImageMagicColour1UnsharpIntensity, warmShift: false)
        case .magicColour2:
            output = applyMagicColour(input, unsharpIntensity: DocumentScannerConstants.coreImageMagicColour2UnsharpIntensity, warmShift: true)
        }
        guard let outCG = context.createCGImage(output, from: input.extent) else { return image }
        return UIImage(cgImage: outCG, scale: image.scale, orientation: .up)
    }

    /// Blurs `image` against itself to estimate the local background/illumination — `.clampedToExtent()`
    /// before blurring keeps the Gaussian blur from sampling transparent space outside the image
    /// bounds, which would otherwise darken/fade the edges; `.cropped(to:)` after restores the
    /// original frame.
    private static func localBackgroundBlur(_ image: CIImage, radiusDivisor: CGFloat) -> CIImage {
        let radius = max(3, min(image.extent.width, image.extent.height) / radiusDivisor)
        return image.clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: radius])
            .cropped(to: image.extent)
    }

    // MARK: - B&W (illumination-normalize via divide-by-local-blur, then a hard contrast push
    // toward binary black/white — approximates true per-pixel adaptive threshold)

    private static func applyBlackAndWhite(_ image: CIImage) -> CIImage {
        let gray = image.applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 0.0])
        let background = localBackgroundBlur(gray, radiusDivisor: DocumentScannerConstants.coreImageBWBlurDivisor)
        let normalized = divide(gray, by: background)
        let contrasted = normalized.applyingFilter("CIColorControls", parameters: [kCIInputContrastKey: DocumentScannerConstants.coreImageBWContrastBoost])
        return contrasted.applyingFilter("CIColorPosterize", parameters: ["inputLevels": DocumentScannerConstants.coreImageBWPosterizeLevels])
    }

    // MARK: - Magic White (push local background toward white — this is the one filter that maps
    // almost exactly onto a native Core Image blend mode instead of needing an approximation)

    private static func applyMagicWhite(_ image: CIImage) -> CIImage {
        let background = localBackgroundBlur(image, radiusDivisor: DocumentScannerConstants.coreImageMagicWhiteBlurDivisor)
        return divide(image, by: background)
    }

    /// `numerator / denominator`, per pixel. `CIDivideBlendMode` follows Photoshop's "Divide"
    /// convention — result = backgroundImage / inputImage, i.e. the `kCIInputBackgroundImageKey`
    /// parameter is the NUMERATOR and the filter's receiver (`kCIInputImageKey`) is the
    /// DENOMINATOR — the reverse of what the filter's own plain-English name suggests. Getting
    /// this backwards (receiver=numerator) inflates every pixel darker than its local
    /// background — text, ink, shadows — toward huge out-of-range values that clamp to solid
    /// white on render, instead of staying dark: exactly the "everything is white" bug this
    /// wrapper exists to prevent from recurring.
    private static func divide(_ numerator: CIImage, by denominator: CIImage) -> CIImage {
        denominator.applyingFilter("CIDivideBlendMode", parameters: [kCIInputBackgroundImageKey: numerator])
    }

    // MARK: - Magic Colour 1/2 (unsharp-mask local-contrast punch standing in for CLAHE, plus a
    // contrast/saturation lift; Colour 2 adds a warm color shift so the two presets read as
    // distinct, not duplicates)

    private static func applyMagicColour(_ image: CIImage, unsharpIntensity: Double, warmShift: Bool) -> CIImage {
        var out = image.applyingFilter("CIUnsharpMask", parameters: [
            kCIInputRadiusKey: DocumentScannerConstants.coreImageMagicColourUnsharpRadius,
            kCIInputIntensityKey: unsharpIntensity
        ])
        out = out.applyingFilter("CIColorControls", parameters: [
            kCIInputContrastKey: DocumentScannerConstants.coreImageMagicColourContrastBoost,
            kCIInputSaturationKey: DocumentScannerConstants.coreImageMagicColourSaturationBoost
        ])
        if warmShift {
            // CIColorMatrix's vector/bias parameters are filter-specific — unlike the common keys
            // used elsewhere in this file (kCIInputRadiusKey, kCIInputContrastKey, etc.), Core
            // Image doesn't define global kCIInput...Key constants for these, so they're
            // referenced by their raw string names instead.
            let shift = DocumentScannerConstants.coreImageWarmShiftAmount
            out = out.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 1, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 1, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
                "inputBiasVector": CIVector(x: shift, y: 0, z: -shift, w: 0)
            ])
        }
        return out
    }
}
