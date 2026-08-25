import Foundation
import UIKit
import Combine

struct VideoSearchResult: Identifiable {
    let videoId: String
    let videoUrl: String
    let title: String
    let description: String
    let thumbnailUrl: String
    let publishedAt: String

    var id: String { videoId }
}

enum VideoSearchUiState {
    case loading
    case success([VideoSearchResult])
    case error(String)
}

private extension VideoSearchItem {
    func toResult() -> VideoSearchResult {
        VideoSearchResult(
            videoId: id.videoId,
            videoUrl: id.videoUrl,
            title: snippet.title.unescapingHTMLEntities(),
            description: snippet.description.unescapingHTMLEntities(),
            thumbnailUrl: snippet.thumbnails.default?.url ?? "",
            publishedAt: snippet.publishedAt
        )
    }
}

private extension String {
    /// Unescapes HTML entities the API leaves in raw text (e.g. "Renewal &amp; RTO Rules",
    /// "Don&#39;t") — mirrors Android's `HtmlCompat.fromHtml(...)` call in the same spot.
    func unescapingHTMLEntities() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        guard let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return self
        }
        return attributed.string
    }
}

/// Backs `VideoSearchView` — the detail view opened when a category tile in Home's Video
/// Tutorials section is tapped. Mirrors Android's `VideoSearchViewModel.kt`: `search(query:)`
/// guards on the query already loaded rather than always re-fetching on `.task`/re-appearance,
/// while still re-fetching when a different category is opened.
@MainActor
final class VideoSearchViewModel: ObservableObject {
    @Published private(set) var uiState: VideoSearchUiState = .loading

    private let repository = YoutubeRepository()
    private var lastQuery: String?

    func search(query: String, maxResults: Int = 30) {
        guard lastQuery != query else { return }
        lastQuery = query
        uiState = .loading
        Task {
            do {
                let response = try await repository.searchVideos(query: query, maxResults: maxResults)
                uiState = .success(response.items.map { $0.toResult() })
            } catch {
                uiState = .error(error.localizedDescription)
            }
        }
    }

    func retry(query: String, maxResults: Int = 30) {
        lastQuery = nil
        search(query: query, maxResults: maxResults)
    }
}
