import CoreGraphics
import UIKit

// MARK: - DocumentScannerFilterService
// The 5 document filters — mirrors Android's DocumentScannerRepository OpenCV filters using the
// same hand-rolled Lab/CLAHE/box-blur primitives PhotoMakerColorMath already built for Photo Maker
// (Core Image has no native Lab or CLAHE support, and the two apps' filters lean on the exact same
// techniques: Magic White is Photo Maker's Remove-Shadow-style ratio blur without the push-to-mean
// step; Magic Colour 1/2 is Photo Maker's Contrast Balance CLAHE plus an optional warm shift). B&W's
// local adaptive threshold is the one genuinely new piece — Photo Maker never needed a binary
// threshold operation.

enum DocumentScannerFilterService {

    static func applyFilter(_ image: UIImage, filter: DocScanFilter) -> UIImage {
        switch filter {
        case .original: return image
        case .blackAndWhite: return applyBlackAndWhite(image)
        case .magicWhite: return applyMagicWhite(image)
        case .magicColour1: return applyMagicColour(image, claheClip: DocumentScannerConstants.magicColour1ClaheClip, warmShift: false)
        case .magicColour2: return applyMagicColour(image, claheClip: DocumentScannerConstants.magicColour2ClaheClip, warmShift: true)
        }
    }

    // MARK: - B&W (local adaptive threshold on grayscale — lighting is rarely even across a page)

    private static func applyBlackAndWhite(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let buffer = RGBA8Buffer(image: cgImage)
        let gray = grayscaleChannel(buffer)
        let blurred = PhotoMakerColorMath.gaussianApproxBlur(gray, width: buffer.width, height: buffer.height, kernelSize: DocumentScannerConstants.bwAdaptiveBlockSize)

        var out = buffer
        for i in 0..<gray.count {
            let threshold = blurred[i] - DocumentScannerConstants.bwAdaptiveC
            let value: UInt8 = gray[i] > threshold ? 255 : 0
            let o = i * 4
            out.pixels[o] = value; out.pixels[o + 1] = value; out.pixels[o + 2] = value
        }
        guard let outCG = out.makeCGImage() else { return image }
        return UIImage(cgImage: outCG)
    }

    /// ITU-R 601 luma — matches OpenCV's COLOR_RGBA2GRAY, distinct from Lab's L channel (different
    /// formula/gamma), so this doesn't reuse PhotoMakerColorMath.lChannel.
    private static func grayscaleChannel(_ buffer: RGBA8Buffer) -> [Double] {
        var result = [Double](repeating: 0, count: buffer.width * buffer.height)
        for y in 0..<buffer.height {
            for x in 0..<buffer.width {
                let p = buffer.pixel(x: x, y: y)
                result[y * buffer.width + x] = 0.299 * Double(p.r) + 0.587 * Double(p.g) + 0.114 * Double(p.b)
            }
        }
        return result
    }

    // MARK: - Magic White (push local background toward white — Lab L channel divide-by-blur,
    // whole frame; unlike Photo Maker's Remove Shadow this does NOT rescale toward the image's
    // mean luminance, it just normalizes each pixel against its own local background estimate)

    private static func applyMagicWhite(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let buffer = RGBA8Buffer(image: cgImage)
        let l = PhotoMakerColorMath.lChannel(buffer)

        let kernelSize = max(3, (min(buffer.width, buffer.height) / DocumentScannerConstants.magicWhiteBlurDivisor) | 1)
        let blurred = PhotoMakerColorMath.gaussianApproxBlur(l, width: buffer.width, height: buffer.height, kernelSize: kernelSize)
        let epsilon = 1.0 / 255.0 * 100.0   // Android's Magic White adds 1.0 to the blur on a 0-255 L scale

        var newL = [Double](repeating: 0, count: l.count)
        for i in 0..<l.count {
            let ratio = l[i] / (blurred[i] + epsilon)
            newL[i] = max(0, min(100, ratio * 100))
        }

        let out = PhotoMakerColorMath.rebuildRGB(fromL: newL, original: buffer)
        guard let outCG = out.makeCGImage() else { return image }
        return UIImage(cgImage: outCG)
    }

    // MARK: - Magic Colour 1/2 (CLAHE on L for local-contrast punch; Colour 2 adds a mild warm
    // color-temperature shift so the two presets read as distinct, not duplicates)

    private static func applyMagicColour(_ image: UIImage, claheClip: Double, warmShift: Bool) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let buffer = RGBA8Buffer(image: cgImage)
        let l = PhotoMakerColorMath.lChannel(buffer)
        let newL = PhotoMakerColorMath.applyCLAHE(
            l, width: buffer.width, height: buffer.height,
            clipLimit: claheClip, tileGrid: DocumentScannerConstants.claheTileGridSize
        )
        var out = PhotoMakerColorMath.rebuildRGB(fromL: newL, original: buffer)

        if warmShift {
            let shift = DocumentScannerConstants.magicColour2WarmShift
            for i in 0..<(out.width * out.height) {
                let o = i * 4
                out.pixels[o] = UInt8(max(0, min(255, Double(out.pixels[o]) + shift)))
                out.pixels[o + 2] = UInt8(max(0, min(255, Double(out.pixels[o + 2]) - shift)))
            }
        }
        guard let outCG = out.makeCGImage() else { return image }
        return UIImage(cgImage: outCG)
    }
}
