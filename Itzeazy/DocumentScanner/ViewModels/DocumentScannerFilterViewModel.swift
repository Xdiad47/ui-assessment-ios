import SwiftUI
import Combine

// MARK: - DocumentScannerFilterViewModel
// Mirrors Android's DocumentScannerFilterViewModel.kt — a pure display/selection surface; all
// bitmap work happens here via DocumentScannerFilterService, the screen just renders whatever's
// ready. Filter selection is global (applies to every page), matching the on-screen copy.

@MainActor
final class DocumentScannerFilterViewModel: ObservableObject {
    @Published private(set) var pageURLs: [URL] = []
    @Published private(set) var selectedFilter: DocScanFilter = .original
    @Published private(set) var previewImage: UIImage?
    @Published private(set) var thumbnails: [DocScanFilter: UIImage] = [:]
    @Published private(set) var isLoadingPreviews = false
    /// True while a tapped filter chip's preview is being computed — the per-pixel Lab/CLAHE math
    /// is slow enough on-device (no native/SIMD equivalent to Android's OpenCV here) that tapping
    /// a filter without any feedback reads as an unresponsive UI, not just "kind of slow."
    @Published var isApplyingFilter = false
    @Published var isProcessing = false
    @Published var toastMessage: String?

    private let repository = DocumentScannerRepository.shared
    private var sourceImage: UIImage?
    /// A downscaled copy of `sourceImage`, sized for the preview frame's actual on-screen
    /// footprint rather than the full working resolution — see `filterPreviewMaxDimension`.
    /// `selectFilter(_:)` runs the (expensive, per-pixel) filter math against this, not
    /// `sourceImage`, since the preview can never visually resolve more detail than this anyway.
    private var previewSourceImage: UIImage?
    private var lastLoadedURLs: [URL]?

    func initSession(_ pageURLs: [URL]) {
        guard lastLoadedURLs != pageURLs else { return }
        lastLoadedURLs = pageURLs
        selectedFilter = .original
        sourceImage = nil
        previewSourceImage = nil
        self.pageURLs = pageURLs
        guard let firstURL = pageURLs.first else { return }

        isLoadingPreviews = true
        let repo = repository
        Task.detached(priority: .userInitiated) {
            do {
                let image = try repo.decodeSampledImage(at: firstURL)
                let previewSource = Self.scaleDown(image, maxDimension: DocumentScannerConstants.filterPreviewMaxDimension)
                let small = Self.scaleDown(image, maxDimension: DocumentScannerConstants.filterThumbnailMaxDimension)
                var newThumbnails: [DocScanFilter: UIImage] = [:]
                for filter in DocScanFilter.allCases {
                    newThumbnails[filter] = DocumentScannerFilterService.applyFilter(small, filter: filter)
                }
                await MainActor.run { [weak self] in
                    self?.sourceImage = image
                    self?.previewSourceImage = previewSource
                    self?.previewImage = previewSource
                    self?.thumbnails = newThumbnails
                    self?.isLoadingPreviews = false
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.toastMessage = "Couldn't load previews. Please try again."
                    self?.isLoadingPreviews = false
                }
            }
        }
    }

    func selectFilter(_ filter: DocScanFilter) {
        selectedFilter = filter
        guard let base = previewSourceImage else { return }
        isApplyingFilter = true
        let start = DispatchTime.now()
        Task.detached(priority: .userInitiated) {
            let filtered = DocumentScannerFilterService.applyFilter(base, filter: filter)
            await Self.enforceMinimumDialogDuration(since: start)
            await MainActor.run { [weak self] in
                self?.previewImage = filtered
                self?.isApplyingFilter = false
            }
        }
    }

    /// Applies the chosen filter to every full-resolution page and hands back their URLs. Pages
    /// are filtered concurrently (bounded — see `maxConcurrent` below) instead of one at a time:
    /// each page's decode + Lab/blur/CLAHE pass is CPU-bound scalar work with no dependency on any
    /// other page, so a sequential loop left every core but one idle for a multi-page scan while
    /// wall-clock time scaled linearly with page count. `decodeSampledImage`/`saveImageToCache`
    /// are stateless (self-contained per call, no shared mutable state on the repository), so
    /// calling them concurrently from multiple tasks is safe.
    func next(onDone: @escaping ([URL]) -> Void) {
        guard !isProcessing, !pageURLs.isEmpty else { return }
        isProcessing = true
        let filter = selectedFilter
        let urls = pageURLs
        let repo = repository
        let start = DispatchTime.now()
        Task.detached(priority: .userInitiated) {
            do {
                // Capped rather than fully unbounded: each concurrent page holds a decoded
                // working-resolution bitmap plus several width*height Double buffers (Lab
                // channels, blur passes, CLAHE) alive at once, so letting a 20-page scan (the app's
                // own cap) all run simultaneously would spike memory a lot for little extra
                // wall-clock benefit past the device's actual core count.
                let maxConcurrent = max(1, min(4, ProcessInfo.processInfo.activeProcessorCount))
                var indexedResults: [(Int, URL)] = []
                indexedResults.reserveCapacity(urls.count)

                try await withThrowingTaskGroup(of: (Int, URL).self) { group in
                    var nextIndex = 0
                    func addNextTask() {
                        guard nextIndex < urls.count else { return }
                        let index = nextIndex
                        let url = urls[index]
                        nextIndex += 1
                        group.addTask {
                            let image = try repo.decodeSampledImage(at: url)
                            let filtered = DocumentScannerFilterService.applyFilter(image, filter: filter)
                            let savedURL = try repo.saveImageToCache(filtered, subdir: "document_scanner_filtered")
                            return (index, savedURL)
                        }
                    }
                    for _ in 0..<min(maxConcurrent, urls.count) { addNextTask() }
                    while let result = try await group.next() {
                        indexedResults.append(result)
                        addNextTask()
                    }
                }

                let finalResults = indexedResults.sorted { $0.0 < $1.0 }.map { $0.1 }
                await Self.enforceMinimumDialogDuration(since: start)
                await MainActor.run { [weak self] in
                    self?.isProcessing = false
                    onDone(finalResults)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.isProcessing = false
                    self?.toastMessage = "Couldn't apply the filter. Please try again."
                }
            }
        }
    }

    /// Keeps `loadingOverlay` (see DocumentScannerFilterView) visible for at least this long once
    /// shown, even if the underlying work finishes faster — without this, a fast operation (e.g.
    /// selecting a filter on a small preview after the resolution/LUT optimizations) can start and
    /// finish inside the overlay's own fade-in animation, which reads as a flicker or nothing at
    /// all rather than a deliberate loading dialog.
    nonisolated private static func enforceMinimumDialogDuration(since start: DispatchTime, minimum: Double = 1.5) async {
        let elapsedNanoseconds = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
        let remaining = minimum - Double(elapsedNanoseconds) / 1_000_000_000
        guard remaining > 0 else { return }
        try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
    }

    nonisolated private static func scaleDown(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let scale = maxDimension / max(image.size.width, image.size.height)
        guard scale < 1 else { return image }
        let targetSize = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { ctx in
            ctx.cgContext.interpolationQuality = .high
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
