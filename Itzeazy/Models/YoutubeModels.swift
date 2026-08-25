import Foundation

struct YoutubePlaylistResponse: Decodable {
    let kind: String
    let etag: String
    let items: [YoutubePlaylistItem]
    let pageInfo: YoutubePageInfo
}

struct YoutubePlaylistItem: Decodable {
    let id: String
    let kind: String
    let etag: String
    let snippet: YoutubePlaylistSnippet
    let contentDetails: YoutubeContentDetails
}

struct YoutubePlaylistSnippet: Decodable {
    let title: String
    let description: String
    let thumbnails: YoutubeThumbnails
    let playlistId: String
    let position: Int
    let publishedAt: String?
    let channelTitle: String?
    let resourceId: YoutubeResourceId
}

struct YoutubeThumbnails: Decodable {
    let `default`: YoutubeThumbnail?
    let medium: YoutubeThumbnail?
    let high: YoutubeThumbnail?
    let standard: YoutubeThumbnail?
    let maxres: YoutubeThumbnail?
}

struct YoutubeThumbnail: Decodable {
    let url: String
    let width: Int
    let height: Int
}

struct YoutubeContentDetails: Decodable {
    let videoId: String
    let videoPublishedAt: String?
    let videoUrl: String?
}

struct YoutubeResourceId: Decodable {
    let kind: String
    let videoId: String
}

struct YoutubePageInfo: Decodable {
    let resultsPerPage: Int
    let totalResults: Int
}

// MARK: - youtube/search/videos — a separate, simpler endpoint from the playlist one above.
// Category tiles on Home's Video Tutorials section (RTO, Passport, Visa, etc.) each pass their
// own `q` to this search endpoint rather than a fixed curated playlist.

struct VideoSearchResponse: Decodable {
    let items: [VideoSearchItem]
}

struct VideoSearchItem: Decodable {
    let id: VideoSearchId
    let snippet: VideoSearchSnippet
}

struct VideoSearchId: Decodable {
    let videoId: String
    let videoUrl: String
}

struct VideoSearchSnippet: Decodable {
    let title: String
    let description: String
    let channelId: String
    let publishedAt: String
    let thumbnails: VideoSearchThumbnails
}

struct VideoSearchThumbnails: Decodable {
    let `default`: VideoSearchThumbnail?
}

struct VideoSearchThumbnail: Decodable {
    let url: String
}
