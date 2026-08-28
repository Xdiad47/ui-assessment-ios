import CoreGraphics
import UIKit

// MARK: - RGBA8Buffer
// Raw RGBA8 (8-bit, premultiplied-last) pixel access for a CGImage. Every source image in this
// pipeline is either fully opaque (alpha 255) or a hard cutout (alpha 0 or 255 — see
// PhotoMakerRepository.compositeBackground), so premultiplication never changes an RGB value
// here; there is no partial-alpha case to worry about.

struct RGBA8Buffer {
    var pixels: [UInt8]   // width*height*4, RGBA order
    let width: Int
    let height: Int

    init(image: CGImage) {
        let w = image.width
        let h = image.height
        var buffer = [UInt8](repeating: 0, count: w * h * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        buffer.withUnsafeMutableBytes { ptr in
            guard let context = CGContext(
                data: ptr.baseAddress,
                width: w, height: h,
                bitsPerComponent: 8, bytesPerRow: w * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return }
            context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        width = w
        height = h
        pixels = buffer
    }

    init(width: Int, height: Int, pixels: [UInt8]) {
        self.width = width
        self.height = height
        self.pixels = pixels
    }

    func makeCGImage() -> CGImage? {
        var mutablePixels = pixels
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        return mutablePixels.withUnsafeMutableBytes { ptr -> CGImage? in
            guard let context = CGContext(
                data: ptr.baseAddress,
                width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return nil }
            return context.makeImage()
        }
    }

    @inline(__always) func offset(x: Int, y: Int) -> Int { (y * width + x) * 4 }

    @inline(__always) func pixel(x: Int, y: Int) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        let o = offset(x: x, y: y)
        return (pixels[o], pixels[o + 1], pixels[o + 2], pixels[o + 3])
    }

    @inline(__always) mutating func setPixel(x: Int, y: Int, r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        let o = offset(x: x, y: y)
        pixels[o] = r; pixels[o + 1] = g; pixels[o + 2] = b; pixels[o + 3] = a
    }
}

// MARK: - PhotoMakerColorMath
// CIE L*a*b* conversion (D65 white point, standard sRGB companding) plus a hand-rolled box-blur
// and CLAHE — the primitives Android's OpenCV-based filters are built from. Operating in true
// Lab (not OpenCV's shifted 8-bit byte encoding) is simpler and behaviorally equivalent: every
// filter here only needs "adjust lightness, leave color alone," which any consistent Lab
// representation gives us.

enum PhotoMakerColorMath {

    // MARK: RGB <-> Lab (per-pixel)

    // The sRGB gamma-decode step only ever takes a UInt8 (0...255), so there are exactly 256
    // possible outputs — computing them all once here and looking them up is bit-for-bit
    // identical to calling `pow()` fresh each time, just without repeating the (expensive,
    // transcendental) math for the same 256 inputs millions of times over. `rgbToLab` is the
    // single hottest function in every Document Scanner filter but B&W (called once or twice per
    // pixel per filter application), so this alone removes a large fraction of the `pow()` calls
    // that were driving that screen's lag — Android's equivalent filters route through OpenCV's
    // native, SIMD-optimized `cvtColor`, which has no analogous per-call cost to eliminate.
    private static let sRGBToLinearLUT: [Double] = (0...255).map { byte in
        let v = Double(byte) / 255.0
        return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
    }

    static func rgbToLab(r: UInt8, g: UInt8, b: UInt8) -> (l: Double, a: Double, b: Double) {
        func toLinear(_ c: UInt8) -> Double { sRGBToLinearLUT[Int(c)] }
        let rl = toLinear(r), gl = toLinear(g), bl = toLinear(b)
        let x = rl * 0.4124564 + gl * 0.3575761 + bl * 0.1804375
        let y = rl * 0.2126729 + gl * 0.7151522 + bl * 0.0721750
        let z = rl * 0.0193339 + gl * 0.1191920 + bl * 0.9503041

        let xn = x / 0.95047, yn = y / 1.0, zn = z / 1.08883
        let delta = 6.0 / 29.0
        func f(_ t: Double) -> Double {
            t > delta * delta * delta ? cbrt(t) : t / (3 * delta * delta) + 4.0 / 29.0
        }
        let fx = f(xn), fy = f(yn), fz = f(zn)
        return (l: 116 * fy - 16, a: 500 * (fx - fy), b: 200 * (fy - fz))
    }

    static func labToRgb(l: Double, a: Double, b: Double) -> (r: UInt8, g: UInt8, b: UInt8) {
        let fy = (l + 16) / 116
        let fx = fy + a / 500
        let fz = fy - b / 200
        let delta = 6.0 / 29.0
        func finv(_ t: Double) -> Double {
            t > delta ? t * t * t : 3 * delta * delta * (t - 4.0 / 29.0)
        }
        let xn = finv(fx) * 0.95047
        let yn = finv(fy) * 1.0
        let zn = finv(fz) * 1.08883

        let rl = xn * 3.2404542 + yn * -1.5371385 + zn * -0.4985314
        let gl = xn * -0.9692660 + yn * 1.8760108 + zn * 0.0415560
        let bl = xn * 0.0556434 + yn * -0.2040259 + zn * 1.0572252
        func toSRGB(_ v: Double) -> Double {
            let c = max(0, min(1, v))
            return c <= 0.0031308 ? c * 12.92 : 1.055 * pow(c, 1 / 2.4) - 0.055
        }
        func to8(_ v: Double) -> UInt8 { UInt8(max(0, min(255, (v * 255).rounded()))) }
        return (to8(toSRGB(rl)), to8(toSRGB(gl)), to8(toSRGB(bl)))
    }

    /// Extracts the full L channel (0...100) from an RGBA8Buffer.
    static func lChannel(_ buffer: RGBA8Buffer) -> [Double] {
        var result = [Double](repeating: 0, count: buffer.width * buffer.height)
        for y in 0..<buffer.height {
            for x in 0..<buffer.width {
                let p = buffer.pixel(x: x, y: y)
                result[y * buffer.width + x] = rgbToLab(r: p.r, g: p.g, b: p.b).l
            }
        }
        return result
    }

    /// Rebuilds RGB from a (possibly modified) L channel + the original buffer's own a/b —
    /// color and hue are untouched, matching Android's Lab-channel-only filters. Alpha is
    /// always copied through from `original` unchanged.
    static func rebuildRGB(fromL newL: [Double], original: RGBA8Buffer, personMask: ((Int, Int) -> Bool)? = nil) -> RGBA8Buffer {
        var out = original
        for y in 0..<original.height {
            for x in 0..<original.width {
                if let personMask, !personMask(x, y) { continue }
                let p = original.pixel(x: x, y: y)
                let lab = rgbToLab(r: p.r, g: p.g, b: p.b)
                let rgb = labToRgb(l: newL[y * original.width + x], a: lab.a, b: lab.b)
                out.setPixel(x: x, y: y, r: rgb.r, g: rgb.g, b: rgb.b, a: p.a)
            }
        }
        return out
    }

    /// Same as `lChannel`, but also returns the a/b channels from the same pass instead of
    /// discarding them — for a caller that's about to rebuild RGB afterward (every Document
    /// Scanner filter but B&W), pairing this with `rebuildRGB(fromL:a:b:original:personMask:)`
    /// below does the RGB->Lab conversion for each pixel exactly ONCE instead of twice (once
    /// here, once again inside the original `rebuildRGB` to re-derive the same a/b it could have
    /// cached). Added alongside the existing `lChannel`/`rebuildRGB(fromL:original:personMask:)`
    /// rather than changing them, since those are also used by Photo Maker's own filters.
    static func labChannels(_ buffer: RGBA8Buffer) -> (l: [Double], a: [Double], b: [Double]) {
        var lArr = [Double](repeating: 0, count: buffer.width * buffer.height)
        var aArr = [Double](repeating: 0, count: buffer.width * buffer.height)
        var bArr = [Double](repeating: 0, count: buffer.width * buffer.height)
        for y in 0..<buffer.height {
            for x in 0..<buffer.width {
                let p = buffer.pixel(x: x, y: y)
                let lab = rgbToLab(r: p.r, g: p.g, b: p.b)
                let i = y * buffer.width + x
                lArr[i] = lab.l; aArr[i] = lab.a; bArr[i] = lab.b
            }
        }
        return (lArr, aArr, bArr)
    }

    /// Rebuilds RGB from a (possibly modified) L channel plus a/b already captured by
    /// `labChannels(_:)` on the SAME buffer — skips re-deriving a/b via a second `rgbToLab` pass
    /// per pixel, unlike the `original:`-based overload above.
    static func rebuildRGB(fromL newL: [Double], a: [Double], b: [Double], original: RGBA8Buffer, personMask: ((Int, Int) -> Bool)? = nil) -> RGBA8Buffer {
        var out = original
        for y in 0..<original.height {
            for x in 0..<original.width {
                if let personMask, !personMask(x, y) { continue }
                let i = y * original.width + x
                let p = original.pixel(x: x, y: y)
                let rgb = labToRgb(l: newL[i], a: a[i], b: b[i])
                out.setPixel(x: x, y: y, r: rgb.r, g: rgb.g, b: rgb.b, a: p.a)
            }
        }
        return out
    }

    // MARK: Box blur (3-pass approximates Gaussian — standard, cheap technique)

    static func boxBlur(_ channel: [Double], width: Int, height: Int, radius: Int) -> [Double] {
        guard radius > 0, width > 0, height > 0 else { return channel }
        let windowSize = Double(radius * 2 + 1)
        var horizontal = [Double](repeating: 0, count: width * height)

        for y in 0..<height {
            let rowStart = y * width
            var sum = 0.0
            for dx in -radius...radius {
                let x = min(width - 1, max(0, dx))
                sum += channel[rowStart + x]
            }
            horizontal[rowStart] = sum / windowSize
            for x in 1..<width {
                let addX = min(width - 1, x + radius)
                let removeX = max(0, x - radius - 1)
                sum += channel[rowStart + addX] - channel[rowStart + removeX]
                horizontal[rowStart + x] = sum / windowSize
            }
        }

        var result = [Double](repeating: 0, count: width * height)
        for x in 0..<width {
            var sum = 0.0
            for dy in -radius...radius {
                let y = min(height - 1, max(0, dy))
                sum += horizontal[y * width + x]
            }
            result[x] = sum / windowSize
            for y in 1..<height {
                let addY = min(height - 1, y + radius)
                let removeY = max(0, y - radius - 1)
                sum += horizontal[addY * width + x] - horizontal[removeY * width + x]
                result[y * width + x] = sum / windowSize
            }
        }
        return result
    }

    static func gaussianApproxBlur(_ channel: [Double], width: Int, height: Int, kernelSize: Int, passes: Int = 3) -> [Double] {
        let radius = max(1, kernelSize / 2)
        var result = channel
        for _ in 0..<passes {
            result = boxBlur(result, width: width, height: height, radius: radius)
        }
        return result
    }

    // MARK: CLAHE (Contrast Limited Adaptive Histogram Equalization)

    /// `channel` is L in 0...100. Returns a new L channel, same range. `clipLimit`/`tileGrid`
    /// mirror OpenCV's `createCLAHE` parameters.
    static func applyCLAHE(_ channel: [Double], width: Int, height: Int, clipLimit: Double, tileGrid: Int) -> [Double] {
        guard width > 0, height > 0, tileGrid > 0 else { return channel }
        let bins = 256
        let tilesX = tileGrid, tilesY = tileGrid
        let tileWidth = max(1, width / tilesX)
        let tileHeight = max(1, height / tilesY)

        var scaled = [Int](repeating: 0, count: width * height)
        for i in 0..<channel.count {
            scaled[i] = Int(max(0, min(255, (channel[i] / 100.0 * 255.0).rounded())))
        }

        var tileLUTs = [[Double]](repeating: [Double](repeating: 0, count: bins), count: tilesX * tilesY)

        for ty in 0..<tilesY {
            let yStart = ty * tileHeight
            let yEnd = (ty == tilesY - 1) ? height : min(height, yStart + tileHeight)
            for tx in 0..<tilesX {
                let xStart = tx * tileWidth
                let xEnd = (tx == tilesX - 1) ? width : min(width, xStart + tileWidth)

                var histogram = [Int](repeating: 0, count: bins)
                var count = 0
                for y in yStart..<yEnd {
                    for x in xStart..<xEnd {
                        histogram[scaled[y * width + x]] += 1
                        count += 1
                    }
                }
                guard count > 0 else { continue }

                let clipThreshold = max(1, Int((clipLimit * Double(count) / Double(bins)).rounded()))
                var excess = 0
                for b in 0..<bins where histogram[b] > clipThreshold {
                    excess += histogram[b] - clipThreshold
                    histogram[b] = clipThreshold
                }
                let redistribute = excess / bins
                let remainder = excess % bins
                for b in 0..<bins { histogram[b] += redistribute }
                for b in 0..<remainder { histogram[b] += 1 }

                var running = 0
                var lut = [Double](repeating: 0, count: bins)
                for b in 0..<bins {
                    running += histogram[b]
                    lut[b] = Double(running)
                }
                let total = Double(max(1, running))
                for b in 0..<bins { lut[b] = (lut[b] / total) * 255.0 }
                tileLUTs[ty * tilesX + tx] = lut
            }
        }

        let tileCentersX = (0..<tilesX).map { Double($0 * tileWidth) + Double(tileWidth) / 2.0 }
        let tileCentersY = (0..<tilesY).map { Double($0 * tileHeight) + Double(tileHeight) / 2.0 }

        // Precompute per-column tile indices/weights once (reused across every row).
        var tx0ForX = [Int](repeating: 0, count: width)
        var xWeightForX = [Double](repeating: 0, count: width)
        for x in 0..<width {
            var tx0 = 0
            for i in 0..<tilesX where tileCentersX[i] <= Double(x) { tx0 = i }
            let tx1 = min(tilesX - 1, tx0 + 1)
            tx0ForX[x] = tx0
            xWeightForX[x] = tx1 == tx0 ? 0 : (Double(x) - tileCentersX[tx0]) / (tileCentersX[tx1] - tileCentersX[tx0])
        }

        var result = [Double](repeating: 0, count: width * height)
        for y in 0..<height {
            var ty0 = 0
            for i in 0..<tilesY where tileCentersY[i] <= Double(y) { ty0 = i }
            let ty1 = min(tilesY - 1, ty0 + 1)
            let yWeight: Double = ty1 == ty0 ? 0 : (Double(y) - tileCentersY[ty0]) / (tileCentersY[ty1] - tileCentersY[ty0])

            for x in 0..<width {
                let tx0 = tx0ForX[x]
                let tx1 = min(tilesX - 1, tx0 + 1)
                let xWeight = xWeightForX[x]

                let v = scaled[y * width + x]
                let lut00 = tileLUTs[ty0 * tilesX + tx0][v]
                let lut10 = tileLUTs[ty0 * tilesX + tx1][v]
                let lut01 = tileLUTs[ty1 * tilesX + tx0][v]
                let lut11 = tileLUTs[ty1 * tilesX + tx1][v]

                let top = lut00 * (1 - xWeight) + lut10 * xWeight
                let bottom = lut01 * (1 - xWeight) + lut11 * xWeight
                result[y * width + x] = (top * (1 - yWeight) + bottom * yWeight) / 255.0 * 100.0
            }
        }
        return result
    }
}
