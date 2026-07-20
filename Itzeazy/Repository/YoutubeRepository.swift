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
}
