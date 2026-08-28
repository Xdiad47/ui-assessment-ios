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
    @Published var isProcessing = false
    @Published var toastMessage: String?

    private let repository = DocumentScannerRepository.shared
    private var sourceImage: UIImage?
    private var lastLoadedURLs: [URL]?

    func initSession(_ pageURLs: [URL]) {
        guard lastLoadedURLs != pageURLs else { return }
        lastLoadedURLs = pageURLs
        selectedFilter = .original
        sourceImage = nil
        self.pageURLs = pageURLs
        guard let firstURL = pageURLs.first else { return }

        isLoadingPreviews = true
        let repo = repository
        Task.detached(priority: .userInitiated) {
            do {
                let image = try repo.decodeSampledImage(at: firstURL)
                let small = Self.scaleDown(image, maxDimension: DocumentScannerConstants.filterThumbnailMaxDimension)
                var newThumbnails: [DocScanFilter: UIImage] = [:]
                for filter in DocScanFilter.allCases {
                    newThumbnails[filter] = DocumentScannerFilterService.applyFilter(small, filter: filter)
                }
                await MainActor.run { [weak self] in
                    self?.sourceImage = image
                    self?.previewImage = image
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
        guard let base = sourceImage else { return }
        Task.detached(priority: .userInitiated) {
            let filtered = DocumentScannerFilterService.applyFilter(base, filter: filter)
            await MainActor.run { [weak self] in
                self?.previewImage = filtered
            }
        }
    }

    /// Applies the chosen filter to every full-resolution page and hands back their URLs.
    func next(onDone: @escaping ([URL]) -> Void) {
        guard !isProcessing, !pageURLs.isEmpty else { return }
        isProcessing = true
        let filter = selectedFilter
        let urls = pageURLs
        let repo = repository
        Task.detached(priority: .userInitiated) {
            do {
                var results: [URL] = []
                for url in urls {
                    let image = try repo.decodeSampledImage(at: url)
                    let filtered = DocumentScannerFilterService.applyFilter(image, filter: filter)
                    results.append(try repo.saveImageToCache(filtered, subdir: "document_scanner_filtered"))
                }
                let finalResults = results
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
