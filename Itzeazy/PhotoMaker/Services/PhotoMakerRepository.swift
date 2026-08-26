import Foundation
import UIKit
import Vision
import ImageIO
import CoreVideo

// MARK: - PhotoMakerError

enum PhotoMakerError: LocalizedError {
    case noFaceDetected
    case processingFailed(String)

    var errorDescription: String? {
        switch self {
        case .noFaceDetected:
            return "We couldn't detect a face in this photo. Try a clearer, front-facing photo."
        case .processingFailed(let message):
            return message
        }
    }
}

// MARK: - PhotoMakerRepository
// All Photo Maker processing logic — mirrors Android's PhotoMakerRepository.kt. Every method
// here is a synchronous, pure function operating on already-decoded UIImages; threading
// (running off the main actor) is the ViewModel's responsibility, matching how the Android
// source splits "what to compute" (repository) from "when/where to compute it" (viewmodel +
// coroutine dispatcher).
//
// Framework mapping vs Android: ML Kit Face Detection -> Vision VNDetectFaceLandmarksRequest;
// ML Kit Selfie Segmentation -> Vision VNGeneratePersonSegmentationRequest; OpenCV Lab-channel
// filters (Remove Shadow, Brightness Fix, Contrast Balance/CLAHE) -> hand-rolled Lab conversion
// + box-blur + CLAHE in PhotoMakerImageProcessing.swift, since Core Image has no native Lab or
// CLAHE support. Manual brightness/contrast and Enhance Quality's unsharp mask are plain linear
// pixel math, matching Android's own non-OpenCV implementation of those two.

final class PhotoMakerRepository {
    static let shared = PhotoMakerRepository()
    private init() {}

    // MARK: - Static data

    func getSizePresets() -> [PhotoSizePreset] { PhotoMakerConstants.sizePresets }

    func getFeatures() -> [PhotoMakerFeature] {
        [
            PhotoMakerFeature(iconSystemName: "photo.on.rectangle", title: "White Background", description: "Clean, uniform background for official use"),
            PhotoMakerFeature(iconSystemName: "wand.and.stars", title: "AI Auto Crop", description: "Perfectly framed photos every time"),
            PhotoMakerFeature(iconSystemName: "face.smiling", title: "Face Centering", description: "Automatically centers and aligns your face"),
            PhotoMakerFeature(iconSystemName: "checkmark.seal", title: "Gov Approved Sizes", description: "Passport, Visa, PAN and more")
        ]
    }

    func getAiAdjustments() -> [AiAdjustmentOption] {
        [
            AiAdjustmentOption(id: "AI Auto Fix", iconAssetName: "ai_auto_fix_icon", label: "AI Auto Fix"),
            AiAdjustmentOption(id: "BG Remove", iconAssetName: "bg_remove_icon", label: "BG Remove"),
            AiAdjustmentOption(id: "White BG", iconAssetName: "white_bg_icon", label: "White BG"),
            AiAdjustmentOption(id: "Auto Crop", iconAssetName: "auto_crop_icon", label: "Auto Crop"),
            AiAdjustmentOption(id: "Auto Resize", iconAssetName: "auto_resize_icon", label: "Auto Resize"),
            AiAdjustmentOption(id: "Enhance Quality", iconAssetName: "enhance_quality_icon", label: "Enhance Quality"),
            AiAdjustmentOption(id: "Remove Shadow", iconAssetName: "remove_shadow_icon", label: "Remove Shadow"),
            AiAdjustmentOption(id: "Brightness Fix", iconAssetName: "brigthness_fix_icon", label: "Brightness Fix"),
            AiAdjustmentOption(id: "Contrast Balance", iconAssetName: "contrast_balance_icon", label: "Contrast Balance"),
            AiAdjustmentOption(id: "Skin Tone Balance", iconAssetName: "skin_tone_icon", label: "Skin Tone Balance"),
            AiAdjustmentOption(id: "Face Center", iconAssetName: "face_center_icon", label: "Face Center")
        ]
    }

    // MARK: - Decode (sampled, capped at maxWorkingDimension, EXIF-orientation baked in)

    func decodeSampledImage(data: Data, maxDimension: CGFloat = PhotoMakerConstants.maxWorkingDimension) throws -> UIImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw PhotoMakerError.processingFailed("Couldn't read the photo.")
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw PhotoMakerError.processingFailed("Couldn't read the photo.")
        }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Face detection

    func detectFace(in image: UIImage) throws -> DetectedFace {
        guard let cgImage = image.cgImage else {
            throw PhotoMakerError.processingFailed("Couldn't process this photo.")
        }
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        try handler.perform([request])

        guard let observations = request.results, !observations.isEmpty else {
            throw PhotoMakerError.noFaceDetected
        }
        guard let largest = observations.max(by: {
            $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height
        }) else {
            throw PhotoMakerError.noFaceDetected
        }

        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        let vnBox = largest.boundingBox   // normalized, origin bottom-left (Vision convention)
        let pixelBox = CGRect(
            x: vnBox.minX * imageWidth,
            y: (1 - vnBox.maxY) * imageHeight,
            width: vnBox.width * imageWidth,
            height: vnBox.height * imageHeight
        )

        let leftY = eyeCentroidPixelY(largest.landmarks?.leftEye, boundingBox: vnBox, imageHeight: imageHeight)
        let rightY = eyeCentroidPixelY(largest.landmarks?.rightEye, boundingBox: vnBox, imageHeight: imageHeight)
        let eyeYs = [leftY, rightY].compactMap { $0 }
        let eyeLineY: CGFloat? = eyeYs.isEmpty ? nil : eyeYs.reduce(0, +) / CGFloat(eyeYs.count)

        return DetectedFace(boundingBox: pixelBox, eyeLineY: eyeLineY)
    }

    /// Vision's landmark points are normalized to the face's own bounding box, not the whole
    /// image — average them for a single eye "position" (mirrors ML Kit's single-point eye
    /// landmark) and project into image-pixel space.
    private func eyeCentroidPixelY(_ region: VNFaceLandmarkRegion2D?, boundingBox: CGRect, imageHeight: CGFloat) -> CGFloat? {
        guard let region, !region.normalizedPoints.isEmpty else { return nil }
        let avgNormY = region.normalizedPoints.map(\.y).reduce(0, +) / CGFloat(region.normalizedPoints.count)
        let imageNormY = boundingBox.origin.y + avgNormY * boundingBox.height
        return (1 - imageNormY) * imageHeight
    }

    // MARK: - Person segmentation

    func segmentPerson(in image: UIImage) throws -> PersonSegmentationMask {
        guard let cgImage = image.cgImage else {
            throw PhotoMakerError.processingFailed("Couldn't process this photo.")
        }
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        try handler.perform([request])

        guard let result = request.results?.first else {
            throw PhotoMakerError.processingFailed("Couldn't process this photo.")
        }
        let pixelBuffer = result.pixelBuffer
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw PhotoMakerError.processingFailed("Couldn't process this photo.")
        }
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

        var confidences = [Float](repeating: 0, count: width * height)
        for y in 0..<height {
            for x in 0..<width {
                confidences[y * width + x] = Float(buffer[y * bytesPerRow + x]) / 255.0
            }
        }
        return PersonSegmentationMask(width: width, height: height, confidences: confidences)
    }

    // MARK: - Geometry

    func rotate90(_ image: UIImage, clockwise: Bool) -> UIImage {
        let radians = clockwise ? CGFloat.pi / 2 : -CGFloat.pi / 2
        let newSize = CGSize(width: image.size.height, height: image.size.width)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { ctx in
            ctx.cgContext.translateBy(x: newSize.width / 2, y: newSize.height / 2)
            ctx.cgContext.rotate(by: radians)
            image.draw(in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2, width: image.size.width, height: image.size.height))
        }
    }

    func crop(_ image: UIImage, to rect: CGRect) -> UIImage {
        guard let cgImage = image.cgImage, let cropped = cgImage.cropping(to: rect.integral) else { return image }
        return UIImage(cgImage: cropped)
    }

    /// Shared by "Auto Crop" (targetAspectRatio = the selected size preset) and "Face Center"
    /// (targetAspectRatio = nil, keeps the current frame's own aspect ratio).
    func autoCropToFace(_ image: UIImage, face: DetectedFace, targetAspectRatio: CGFloat?) -> UIImage {
        let bitmapW = image.size.width
        let bitmapH = image.size.height
        let faceBox = face.boundingBox

        var frameHeight = faceBox.height / PhotoMakerConstants.autoCropFaceHeightRatio
        let aspect = targetAspectRatio ?? (bitmapW / bitmapH)
        var frameWidth = frameHeight * aspect

        if frameWidth > bitmapW || frameHeight > bitmapH {
            let scale = min(bitmapW / frameWidth, bitmapH / frameHeight)
            frameWidth *= scale
            frameHeight *= scale
        }
        frameWidth = min(frameWidth, bitmapW)
        frameHeight = min(frameHeight, bitmapH)

        let faceCenterX = faceBox.midX
        let eyeY = face.eyeLineY ?? (faceBox.minY + faceBox.height * PhotoMakerConstants.fallbackEyeHeightRatioInFace)

        let left = min(max(0, faceCenterX - frameWidth / 2), bitmapW - frameWidth)
        let top = min(max(0, eyeY - frameHeight * PhotoMakerConstants.autoCropEyeLineRatio), bitmapH - frameHeight)

        return crop(image, to: CGRect(x: left, y: top, width: frameWidth, height: frameHeight))
    }

    /// Pure center-crop to a preset's aspect ratio — does not resize to a specific pixel target.
    func cropToAspectRatio(_ image: UIImage, aspectRatio: CGFloat) -> UIImage {
        let w = image.size.width, h = image.size.height
        guard aspectRatio > 0, w > 0, h > 0 else { return image }
        let currentAspect = w / h
        var cropW = w, cropH = h
        if currentAspect > aspectRatio {
            cropW = h * aspectRatio
        } else {
            cropH = w / aspectRatio
        }
        return crop(image, to: CGRect(x: (w - cropW) / 2, y: (h - cropH) / 2, width: cropW, height: cropH))
    }

    /// Scales to the preset's exact mm-derived pixel size at officialPhotoPrintDPI, letterboxing
    /// with solid white if the source aspect ratio doesn't exactly match — a destructive resize,
    /// distinct from cropToAspectRatio.
    func resizeToOfficialDimensions(_ image: UIImage, preset: PhotoSizePreset) throws -> UIImage {
        guard let widthMm = preset.widthMm, let heightMm = preset.heightMm else {
            throw PhotoMakerError.processingFailed("Pick a size in Quick Size Selector first, then tap Auto Resize.")
        }
        let targetW = (widthMm / 25.4 * PhotoMakerConstants.officialPhotoPrintDPI).rounded()
        let targetH = (heightMm / 25.4 * PhotoMakerConstants.officialPhotoPrintDPI).rounded()
        let targetSize = CGSize(width: targetW, height: targetH)

        let sourceAspect = image.size.width / image.size.height
        let targetAspect = targetW / targetH

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { ctx in
            ctx.cgContext.interpolationQuality = .high
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: targetSize))

            var drawSize = targetSize
            if abs(sourceAspect - targetAspect) > 0.001 {
                drawSize = sourceAspect > targetAspect
                    ? CGSize(width: targetW, height: targetW / sourceAspect)
                    : CGSize(width: targetH * sourceAspect, height: targetH)
            }
            let origin = CGPoint(x: (targetW - drawSize.width) / 2, y: (targetH - drawSize.height) / 2)
            image.draw(in: CGRect(origin: origin, size: drawSize))
        }
    }

    // MARK: - Compositing

    /// nil fillColor = transparent cutout ("BG Remove"); a fillColor = flat replacement (e.g.
    /// "White BG" or a custom color). Hard cutout at the confidence threshold, no edge feathering
    /// — matches Android's binary mask test exactly.
    func compositeBackground(_ image: UIImage, mask: PersonSegmentationMask, fillColor: UIColor?) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        var buffer = RGBA8Buffer(image: cgImage)
        let threshold = PhotoMakerConstants.personConfidenceThreshold

        var fillR: UInt8 = 0, fillG: UInt8 = 0, fillB: UInt8 = 0
        if let fillColor {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            fillColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            fillR = UInt8(max(0, min(255, r * 255)))
            fillG = UInt8(max(0, min(255, g * 255)))
            fillB = UInt8(max(0, min(255, b * 255)))
        }

        for y in 0..<buffer.height {
            for x in 0..<buffer.width {
                let confidence = mask.confidence(atImageX: x, y: y, imageWidth: buffer.width, imageHeight: buffer.height)
                guard confidence <= threshold else { continue }
                if fillColor != nil {
                    buffer.setPixel(x: x, y: y, r: fillR, g: fillG, b: fillB, a: 255)
                } else {
                    buffer.setPixel(x: x, y: y, r: 0, g: 0, b: 0, a: 0)
                }
            }
        }
        guard let outCG = buffer.makeCGImage() else { return image }
        return UIImage(cgImage: outCG)
    }

    // MARK: - Remove Shadow (illumination normalization, Lab L channel)

    func normalizeIllumination(_ image: UIImage, mask: PersonSegmentationMask?) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let buffer = RGBA8Buffer(image: cgImage)
        let l = PhotoMakerColorMath.lChannel(buffer)

        let kernelSize = max(3, (min(buffer.width, buffer.height) / 8) | 1)
        let blurred = PhotoMakerColorMath.gaussianApproxBlur(l, width: buffer.width, height: buffer.height, kernelSize: kernelSize)
        let meanL = l.reduce(0, +) / Double(max(1, l.count))

        var newL = [Double](repeating: 0, count: l.count)
        for i in 0..<l.count {
            let ratio = l[i] / (blurred[i] + 0.4)   // epsilon scaled to our 0-100 L range (Android's +1 is on a 0-255 scale)
            newL[i] = max(0, min(100, ratio * meanL))
        }

        let out = PhotoMakerColorMath.rebuildRGB(fromL: newL, original: buffer, personMask: personMaskTest(mask, buffer: buffer))
        guard let outCG = out.makeCGImage() else { return image }
        return UIImage(cgImage: outCG)
    }

    // MARK: - Brightness Fix (face-region mean -> whole-channel offset, clamped)

    func adjustTowardTargetLuminance(_ image: UIImage, faceBoundingBox: CGRect, mask: PersonSegmentationMask?) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let buffer = RGBA8Buffer(image: cgImage)
        let l = PhotoMakerColorMath.lChannel(buffer)

        let x0 = max(0, Int(faceBoundingBox.minX))
        let y0 = max(0, Int(faceBoundingBox.minY))
        let x1 = min(buffer.width, Int(faceBoundingBox.maxX))
        let y1 = min(buffer.height, Int(faceBoundingBox.maxY))

        var sum = 0.0
        var count = 0
        if x1 > x0 && y1 > y0 {
            for y in y0..<y1 {
                for x in x0..<x1 {
                    sum += l[y * buffer.width + x]
                    count += 1
                }
            }
        }
        let meanFaceLuminance = count > 0 ? sum / Double(count) : 50.0

        // Android's target/max-adjustment are on an 0-255 L scale — rescale into our 0-100 Lab L.
        let targetL = PhotoMakerConstants.brightnessFixTargetLuminance / 255.0 * 100.0
        let maxAdjust = PhotoMakerConstants.brightnessFixMaxAdjustment / 255.0 * 100.0
        let offset = max(-maxAdjust, min(maxAdjust, targetL - meanFaceLuminance))

        var newL = l
        for i in 0..<newL.count { newL[i] = max(0, min(100, newL[i] + offset)) }

        let out = PhotoMakerColorMath.rebuildRGB(fromL: newL, original: buffer, personMask: personMaskTest(mask, buffer: buffer))
        guard let outCG = out.makeCGImage() else { return image }
        return UIImage(cgImage: outCG)
    }

    // MARK: - Contrast Balance (CLAHE on Lab L channel)

    func applyContrastBalance(_ image: UIImage, mask: PersonSegmentationMask?) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let buffer = RGBA8Buffer(image: cgImage)
        let l = PhotoMakerColorMath.lChannel(buffer)
        let newL = PhotoMakerColorMath.applyCLAHE(
            l, width: buffer.width, height: buffer.height,
            clipLimit: PhotoMakerConstants.claheClipLimit, tileGrid: PhotoMakerConstants.claheTileGridSize
        )
        let out = PhotoMakerColorMath.rebuildRGB(fromL: newL, original: buffer, personMask: personMaskTest(mask, buffer: buffer))
        guard let outCG = out.makeCGImage() else { return image }
        return UIImage(cgImage: outCG)
    }

    // MARK: - Skin Tone Balance (gray-world, RGB, always person-restricted)

    func balanceSkinTone(_ image: UIImage, mask: PersonSegmentationMask) throws -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        var buffer = RGBA8Buffer(image: cgImage)

        var sumR = 0.0, sumG = 0.0, sumB = 0.0
        var count = 0
        for y in 0..<buffer.height {
            for x in 0..<buffer.width {
                guard mask.confidence(atImageX: x, y: y, imageWidth: buffer.width, imageHeight: buffer.height) > PhotoMakerConstants.personConfidenceThreshold else { continue }
                let p = buffer.pixel(x: x, y: y)
                sumR += Double(p.r); sumG += Double(p.g); sumB += Double(p.b)
                count += 1
            }
        }
        guard count > 0 else {
            throw PhotoMakerError.processingFailed("We couldn't find a person in this photo to balance skin tone.")
        }
        let meanR = sumR / Double(count), meanG = sumG / Double(count), meanB = sumB / Double(count)
        let gray = (meanR + meanG + meanB) / 3.0
        func scale(_ mean: Double) -> Double {
            guard mean > 0 else { return 1.0 }
            return max(PhotoMakerConstants.skinToneMinScale, min(PhotoMakerConstants.skinToneMaxScale, gray / mean))
        }
        let scaleR = scale(meanR), scaleG = scale(meanG), scaleB = scale(meanB)

        for y in 0..<buffer.height {
            for x in 0..<buffer.width {
                guard mask.confidence(atImageX: x, y: y, imageWidth: buffer.width, imageHeight: buffer.height) > PhotoMakerConstants.personConfidenceThreshold else { continue }
                let p = buffer.pixel(x: x, y: y)
                let r = UInt8(max(0, min(255, (Double(p.r) * scaleR).rounded())))
                let g = UInt8(max(0, min(255, (Double(p.g) * scaleG).rounded())))
                let b = UInt8(max(0, min(255, (Double(p.b) * scaleB).rounded())))
                buffer.setPixel(x: x, y: y, r: r, g: g, b: b, a: p.a)
            }
        }
        guard let outCG = buffer.makeCGImage() else { return image }
        return UIImage(cgImage: outCG)
    }

    // MARK: - Enhance Quality (bicubic-ish upscale + unsharp mask, whole frame, RGB not Lab)

    func enhanceQuality(_ image: UIImage) -> UIImage {
        let scale = PhotoMakerConstants.enhanceQualityUpscaleFactor
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let upscaled = renderer.image { ctx in
            ctx.cgContext.interpolationQuality = .high
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        guard let cgImage = upscaled.cgImage else { return upscaled }
        let buffer = RGBA8Buffer(image: cgImage)
        let pixelCount = buffer.width * buffer.height

        var rChannel = [Double](repeating: 0, count: pixelCount)
        var gChannel = rChannel, bChannel = rChannel
        for y in 0..<buffer.height {
            for x in 0..<buffer.width {
                let p = buffer.pixel(x: x, y: y)
                let i = y * buffer.width + x
                rChannel[i] = Double(p.r); gChannel[i] = Double(p.g); bChannel[i] = Double(p.b)
            }
        }

        let kernelSize = Int(ceil(PhotoMakerConstants.enhanceQualityUnsharpSigma * 3)) * 2 + 1
        let rBlur = PhotoMakerColorMath.gaussianApproxBlur(rChannel, width: buffer.width, height: buffer.height, kernelSize: kernelSize)
        let gBlur = PhotoMakerColorMath.gaussianApproxBlur(gChannel, width: buffer.width, height: buffer.height, kernelSize: kernelSize)
        let bBlur = PhotoMakerColorMath.gaussianApproxBlur(bChannel, width: buffer.width, height: buffer.height, kernelSize: kernelSize)

        let amount = PhotoMakerConstants.enhanceQualityUnsharpAmount
        var out = buffer
        for i in 0..<pixelCount {
            let r = rChannel[i] * (1 + amount) - rBlur[i] * amount
            let g = gChannel[i] * (1 + amount) - gBlur[i] * amount
            let b = bChannel[i] * (1 + amount) - bBlur[i] * amount
            let o = i * 4
            out.pixels[o] = UInt8(max(0, min(255, r.rounded())))
            out.pixels[o + 1] = UInt8(max(0, min(255, g.rounded())))
            out.pixels[o + 2] = UInt8(max(0, min(255, b.rounded())))
        }
        guard let outCG = out.makeCGImage() else { return upscaled }
        return UIImage(cgImage: outCG)
    }

    // MARK: - Manual brightness/contrast (toolbar cycle + AI Auto Fix step 2)

    /// levels are in {-1, 0, 1}, matching the toolbar's tap-cycle. When `mask` is provided, only
    /// person pixels are touched (used while a background swap is active); nil applies whole-frame.
    func applyAdjustments(_ image: UIImage, brightnessLevel: Int, contrastLevel: Int, mask: PersonSegmentationMask?) -> UIImage {
        guard brightnessLevel != 0 || contrastLevel != 0 else { return image }
        guard let cgImage = image.cgImage else { return image }
        var buffer = RGBA8Buffer(image: cgImage)

        let contrast = 1 + Double(contrastLevel) * PhotoMakerConstants.manualContrastStep
        let translate = (1 - contrast) * 128 + Double(brightnessLevel) * PhotoMakerConstants.manualBrightnessStep

        for y in 0..<buffer.height {
            for x in 0..<buffer.width {
                if let mask, mask.confidence(atImageX: x, y: y, imageWidth: buffer.width, imageHeight: buffer.height) <= PhotoMakerConstants.personConfidenceThreshold {
                    continue
                }
                let p = buffer.pixel(x: x, y: y)
                let r = UInt8(max(0, min(255, (Double(p.r) * contrast + translate).rounded())))
                let g = UInt8(max(0, min(255, (Double(p.g) * contrast + translate).rounded())))
                let b = UInt8(max(0, min(255, (Double(p.b) * contrast + translate).rounded())))
                buffer.setPixel(x: x, y: y, r: r, g: g, b: b, a: p.a)
            }
        }
        guard let outCG = buffer.makeCGImage() else { return image }
        return UIImage(cgImage: outCG)
    }

    // MARK: - Export

    func exportPNGData(_ image: UIImage) -> Data? { image.pngData() }

    func exportJPGData(_ image: UIImage, quality: CGFloat = 0.9) -> Data? { image.jpegData(compressionQuality: quality) }

    func exportPDFData(_ image: UIImage) -> Data {
        let pageRect = CGRect(origin: .zero, size: image.size)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { ctx in
            ctx.beginPage()
            image.draw(in: pageRect)
        }
    }

    // MARK: - Helpers

    private func personMaskTest(_ mask: PersonSegmentationMask?, buffer: RGBA8Buffer) -> ((Int, Int) -> Bool)? {
        guard let mask else { return nil }
        return { x, y in
            mask.confidence(atImageX: x, y: y, imageWidth: buffer.width, imageHeight: buffer.height) > PhotoMakerConstants.personConfidenceThreshold
        }
    }
}
