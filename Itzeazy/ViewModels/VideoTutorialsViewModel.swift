import Foundation
import SwiftUI
import Combine

struct TutorialVideo: Identifiable {
    let id: String
    let title: String
    let thumbnailURL: String
    let videoURL: String
}

struct PlaylistVideo: Identifiable {
    let id: String
    let title: String
    let thumbnailURL: String
    let videoURL: String
}

struct PlaylistSection: Identifiable {
    let id = UUID()
    let name: String
    var videos: [PlaylistVideo] = []
    var isLoading: Bool = false
    var error: String? = nil
}

private struct PlaylistInfo {
    let name: String
    let id: String
}

private let playlists: [PlaylistInfo] = [
    PlaylistInfo(name: "South Africa Visa",     id: "PLTEkGxr26I483iQ77D-jRu0_QrU8yKGHm"),
    PlaylistInfo(name: "Visa",                  id: "PLTEkGxr26I4912T4PwbjnH7McXMV33q9a"),
    PlaylistInfo(name: "RTO Services",          id: "PLTEkGxr26I4_u1oAStS1flqooc5EpeNrE"),
    PlaylistInfo(name: "Dubai Visa",            id: "PLTEkGxr26I49TpvPkQ14DKDuSsbK8X5Qd"),
    PlaylistInfo(name: "Passport Requirements", id: "PLTEkGxr26I48hxGJQNArE_0_X01n38mM6")
]

@MainActor
final class VideoTutorialsViewModel: ObservableObject {

    @Published var tutorialVideos: [TutorialVideo] = [
        TutorialVideo(
            id: "LF4mp2tlImc",
            title: "How to book order on ItzEazy portal",
            thumbnailURL: "https://img.youtube.com/vi/LF4mp2tlImc/hqdefault.jpg",
            videoURL: "https://youtu.be/LF4mp2tlImc"
        ),
        TutorialVideo(
            id: "VuapjYB7I2s",
            title: "How to check service request status",
            thumbnailURL: "https://img.youtube.com/vi/VuapjYB7I2s/hqdefault.jpg",
            videoURL: "https://youtu.be/VuapjYB7I2s"
        ),
        TutorialVideo(
            id: "6IHDfs077mU",
            title: "How to raise a complaint ticket",
            thumbnailURL: "https://img.youtube.com/vi/6IHDfs077mU/hqdefault.jpg",
            videoURL: "https://youtu.be/6IHDfs077mU"
        )
    ]

    @Published var playlistSections: [PlaylistSection] = playlists.map {
        PlaylistSection(name: $0.name, isLoading: true)
    }

    private let repository = YoutubeRepository()

    init() {
        Task { await loadPlaylists() }
    }

    private func loadPlaylists() async {
        await withTaskGroup(of: (Int, Result<YoutubePlaylistResponse, Error>).self) { group in
            for (index, info) in playlists.enumerated() {
                group.addTask { [repository] in
                    do {
                        let response = try await repository.getPlaylistVideos(playlistId: info.id)
                        return (index, .success(response))
                    } catch {
                        return (index, .failure(error))
                    }
                }
            }
            for await (index, result) in group {
                switch result {
                case .success(let response):
                    let videos = response.items.map { item in
                        PlaylistVideo(
                            id: item.contentDetails.videoId,
                            title: item.snippet.title,
                            thumbnailURL: item.snippet.thumbnails.high?.url
                                ?? item.snippet.thumbnails.medium?.url
                                ?? item.snippet.thumbnails.default?.url
                                ?? "",
                            videoURL: item.contentDetails.videoUrl
                                ?? "https://youtu.be/\(item.contentDetails.videoId)"
                        )
                    }
                    playlistSections[index].videos = videos
                    playlistSections[index].isLoading = false
                    playlistSections[index].error = nil
                case .failure(let error):
                    playlistSections[index].isLoading = false
                    playlistSections[index].error = error.localizedDescription
                }
            }
        }
    }
}
