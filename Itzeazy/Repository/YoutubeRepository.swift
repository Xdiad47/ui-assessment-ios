import Foundation

final class YoutubeRepository {
    private let baseURL = AppEnvironment.current.baseURL + "youtube/playlist/videos"

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }()

    func getPlaylistVideos(playlistId: String) async throws -> YoutubePlaylistResponse {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [URLQueryItem(name: "playlistId", value: playlistId)]
        guard let url = components.url else { throw URLError(.badURL) }
        let (data, _) = try await session.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(YoutubePlaylistResponse.self, from: data)
    }

    private let searchURL = AppEnvironment.current.baseURL + "youtube/search/videos"

    /// Backs the Home Video Tutorials category tiles — a live search scoped to whichever
    /// category was tapped, distinct from the fixed curated playlists above.
    func searchVideos(query: String, maxResults: Int = 30) async throws -> VideoSearchResponse {
        var components = URLComponents(string: searchURL)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "maxResults", value: String(maxResults))
        ]
        guard let url = components.url else { throw URLError(.badURL) }
        let (data, _) = try await session.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(VideoSearchResponse.self, from: data)
    }
}
