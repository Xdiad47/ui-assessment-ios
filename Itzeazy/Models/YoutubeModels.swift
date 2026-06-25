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
