import SwiftUI

struct VideoTutorialsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = VideoTutorialsViewModel()
    @State private var selectedVideoURL: String? = nil
    @State private var selectedVideoTitle: String = ""

    private let darkBg      = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let lightBg     = Color(red: 0.96, green: 0.96, blue: 0.96)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
    private let primaryRed  = Color.red

    var body: some View {
        ZStack(alignment: .top) {
            darkBg.ignoresSafeArea()

            // Hidden NavigationLink — activated when a video is selected
            NavigationLink(
                destination: Group {
                    if let url = selectedVideoURL {
                        YoutubePlayerView(videoURL: url, title: selectedVideoTitle)
                    }
                },
                isActive: Binding(
                    get: { selectedVideoURL != nil },
                    set: { if !$0 { selectedVideoURL = nil } }
                )
            ) { EmptyView() }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    topBar
                    headerCard.padding(.horizontal, 16)
                    videosSectionHeader.padding(.horizontal, 16)
                    tutorialsGrid.padding(.horizontal, 16)
                    playlistsSection
                    Spacer(minLength: 80)
                }
                .padding(.bottom, 16)
                .background(lightBg)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(strokeColor)
                .frame(maxWidth: .infinity, maxHeight: 62)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
                .padding(.horizontal, 1)

            darkBg
                .frame(maxWidth: .infinity, maxHeight: 60)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))

            HStack(spacing: 12) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                }

                Text("Video Tutorials")
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        HStack {
            Text("Video Tutorials")
                .font(Font.custom("PlusJakartaSans-SemiBold", size: 16))
                .foregroundColor(.white)

            Spacer()

            Button(action: {}) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("Book Service")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 12))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(primaryRed)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 72)
        .background(darkBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Videos Section Header

    private var videosSectionHeader: some View {
        HStack {
            Text("Videos")
                .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                .foregroundColor(darkBg)

            Spacer()

            Button(action: { openInBrowser("https://www.youtube.com/@itzeazyindia/shorts") }) {
                HStack(spacing: 4) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(primaryRed)
                    Text("See More on YouTube")
                        .font(Font.custom("PlusJakartaSans-SemiBold", size: 12))
                        .foregroundColor(primaryRed)
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Tutorials Grid

    private var tutorialsGrid: some View {
        let rows = viewModel.tutorialVideos.chunked(into: 2)
        return VStack(spacing: 16) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, pair in
                HStack(spacing: 16) {
                    ForEach(pair) { video in
                        TutorialVideoCard(video: video, darkBg: darkBg)
                            .frame(maxWidth: .infinity)
                            .onTapGesture { openPlayer(url: video.videoURL, title: video.title) }
                    }
                    if pair.count == 1 { Spacer().frame(maxWidth: .infinity) }
                }
            }
        }
    }

    // MARK: - Playlists Section

    private var playlistsSection: some View {
        VStack(spacing: 16) {
            if !viewModel.playlistSections.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(primaryRed)
                    Text("Playlists")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                        .foregroundColor(darkBg)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(strokeColor, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 16)

                ForEach(viewModel.playlistSections) { playlist in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(primaryRed)
                                .frame(width: 4, height: 18)
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                            Text(playlist.name)
                                .font(Font.custom("PlusJakartaSans-Bold", size: 14))
                                .foregroundColor(darkBg)
                        }
                        .padding(.horizontal, 16)

                        if playlist.isLoading {
                            HStack {
                                Spacer()
                                ProgressView().tint(primaryRed)
                                Spacer()
                            }
                            .frame(height: 80)
                        } else if playlist.error != nil {
                            HStack {
                                Spacer()
                                Text("Could not load videos")
                                    .font(Font.custom("PlusJakartaSans-Regular", size: 13))
                                    .foregroundColor(Color(red: 0.62, green: 0.62, blue: 0.62))
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        } else {
                            let rows = playlist.videos.chunked(into: 2)
                            VStack(spacing: 12) {
                                ForEach(Array(rows.enumerated()), id: \.offset) { _, pair in
                                    HStack(spacing: 16) {
                                        ForEach(pair) { video in
                                            PlaylistVideoCard(video: video, darkBg: darkBg)
                                                .frame(maxWidth: .infinity)
                                                .onTapGesture { openPlayer(url: video.videoURL, title: video.title) }
                                        }
                                        if pair.count == 1 { Spacer().frame(maxWidth: .infinity) }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func openPlayer(url: String, title: String) {
        selectedVideoTitle = title
        selectedVideoURL = url
    }

    private func openInBrowser(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Tutorial Video Card

private struct TutorialVideoCard: View {
    let video: TutorialVideo
    let darkBg: Color

    var body: some View {
        ZStack {
            AsyncImage(url: URL(string: video.thumbnailURL)) { phase in
                switch phase {
                case .success(let image): image.resizable().scaledToFill()
                default: Color(red: 0.82, green: 0.76, blue: 0.76)
                }
            }
            .clipped()

            Color.black.opacity(0.2)

            Image(systemName: "play.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.85))
        }
        .aspectRatio(1.6, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Playlist Video Card

private struct PlaylistVideoCard: View {
    let video: PlaylistVideo
    let darkBg: Color

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                AsyncImage(url: URL(string: video.thumbnailURL)) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    default: Color(red: 0.82, green: 0.76, blue: 0.76)
                    }
                }
                .clipped()

                Color.black.opacity(0.2)

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.85))
            }
            .aspectRatio(1.6, contentMode: .fit)

            Text(video.title)
                .font(Font.custom("PlusJakartaSans-SemiBold", size: 11))
                .foregroundColor(darkBg)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Array helper

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

#Preview {
    NavigationView { VideoTutorialsView() }
}
