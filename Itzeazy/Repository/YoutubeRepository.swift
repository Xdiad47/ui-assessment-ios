import Foundation

final class YoutubeRepository {
    private let baseURL = "https://dev.itzeazy.in/api/v1/youtube/playlist/videos"

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
        return try JSONDecoder().decode(YoutubePlaylistResponse.self, from: data)
    }
}
