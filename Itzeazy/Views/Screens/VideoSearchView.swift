import SwiftUI

/// Video search results for one Video Tutorials category (RTO, Passport, Visa, ...) — opened
/// when a tile in `VideoTutorialsGridView` is tapped. Renders only fields the
/// `youtube/search/videos` API actually returns (title, description, thumbnail, published date)
/// — no fabricated duration/view-count stats. Mirrors Android's `VideoSearchScreen.kt`.
struct VideoSearchView: View {
    let category: String
    let query: String

    @StateObject private var viewModel = VideoSearchViewModel()
    @Environment(\.presentationMode) private var presentationMode
    @State private var selectedVideoURL: String?
    @State private var selectedVideoTitle: String = ""

    private let darkBg = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let cardBg = Color(red: 0.149, green: 0.165, blue: 0.169)
    private let primaryRed = Color.red
    private let borderColor = Color(red: 0.72, green: 0.72, blue: 0.72)
    private let descriptionGray = Color(red: 0.72, green: 0.72, blue: 0.72)

    private var curated: [CuratedVideo] { CuratedVideos.forCategory(query) }

    var body: some View {
        ZStack(alignment: .top) {
            darkBg.ignoresSafeArea()

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

            VStack(spacing: 0) {
                topBar

                switch viewModel.uiState {
                case .loading:
                    Spacer()
                    ProgressView().tint(primaryRed)
                    Spacer()

                case .error(let message):
                    Spacer()
                    VStack(spacing: 16) {
                        Text(message)
                            .font(Font.custom("Inter", size: 14))
                            .foregroundColor(descriptionGray)
                            .multilineTextAlignment(.center)
                        Button {
                            viewModel.retry(query: query)
                        } label: {
                            Text("Retry")
                                .font(Font.custom("PlusJakartaSans-SemiBold", size: 14))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(primaryRed)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(24)
                    Spacer()

                case .success(let videos):
                    if videos.isEmpty && curated.isEmpty {
                        Spacer()
                        Text("No videos found for \(category)")
                            .font(Font.custom("Inter", size: 14))
                            .foregroundColor(descriptionGray)
                        Spacer()
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 0) {
                                if !curated.isEmpty {
                                    CuratedVideoGrid(videos: curated, primaryRed: primaryRed) { video in
                                        openPlayer(url: video.videoUrl, title: video.title)
                                    }
                                    .padding(.top, 16)

                                    Text("All \(category) Videos")
                                        .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                                        .foregroundColor(.white)
                                        .padding(.top, 28)
                                        .padding(.bottom, 16)
                                }

                                if videos.isEmpty {
                                    Text("No videos found for \(category)")
                                        .font(Font.custom("Inter", size: 14))
                                        .foregroundColor(descriptionGray)
                                        .padding(.vertical, 24)
                                } else {
                                    // Single-column list — mirrors Android's VideoSearchScreen.kt,
                                    // which uses a LazyColumn of VideoCard here, not a grid.
                                    VStack(spacing: 14) {
                                        ForEach(videos) { video in
                                            VideoResultCard(video: video, cardBg: cardBg, descriptionGray: descriptionGray) {
                                                openPlayer(url: video.videoUrl, title: video.title)
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task { viewModel.search(query: query) }
    }

    private func openPlayer(url: String, title: String) {
        selectedVideoTitle = title
        selectedVideoURL = url
    }

    private var topBar: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(borderColor)
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
                .padding(.horizontal, 1)

            darkBg
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))

            HStack(spacing: 12) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text(category)
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(height: 60)
        }
    }
}

// MARK: - Curated grid (top of screen — hand-picked 6 videos, 2 per row)

private struct CuratedVideoGrid: View {
    let videos: [CuratedVideo]
    let primaryRed: Color
    let onTap: (CuratedVideo) -> Void

    // Mirrors Android's CuratedVideoGrid exactly: videos.chunked(2) into a Row per pair with
    // weight(1f) per card — not a LazyVGrid. Ported literally after the grid-based version kept
    // misbehaving; explicit row-pairing sidesteps LazyVGrid's flexible-column sizing entirely.
    private var rows: [[CuratedVideo]] {
        stride(from: 0, to: videos.count, by: 2).map {
            Array(videos[$0..<min($0 + 2, videos.count)])
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, rowItems in
                HStack(spacing: 12) {
                    ForEach(Array(rowItems.enumerated()), id: \.offset) { _, video in
                        CuratedVideoCard(video: video, primaryRed: primaryRed) { onTap(video) }
                            .frame(maxWidth: .infinity)
                    }
                    // Odd video count on the last row — Android adds a weight(1f) Spacer so the
                    // lone card stays half-width instead of stretching full-width.
                    if rowItems.count == 1 {
                        Spacer().frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

// *** THE UPDATE IS IN THIS STRUCT ***
private struct CuratedVideoCard: View {
    let video: CuratedVideo
    let primaryRed: Color
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onTap) {
                // 1. Establish the strict layout bounds FIRST
                Color(red: 0.82, green: 0.76, blue: 0.76)
                    .aspectRatio(3.0/4.0, contentMode: .fit)
                    .overlay(
                        // 2. Load the image INSIDE the overlay so it inherits bounds and cannot stretch the layout
                        AsyncImage(url: URL(string: video.thumbnailUrl)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                Color.clear
                            }
                        }
                    )
                    .overlay(
                        // 3. Keep your UI elements positioned on top
                        // !!! FIX IS HERE: Default alignment is center !!!
                        ZStack {
                            // This element will now automatically center in the ZStack
                            Circle()
                                .fill(Color.white.opacity(0.25))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                // !!! FIX IS HERE: Removing bottom padding !!!
                                // .padding(.bottom, 16)

                            // The red progress bar needs to explicitly pin itself to the bottom
                            Rectangle()
                                .fill(primaryRed)
                                .frame(height: 2)
                                .frame(maxWidth: .infinity)
                                // !!! FIX IS HERE: Forces frame expansion and pins the red box to bottom !!!
                                .frame(maxHeight: .infinity, alignment: .bottom)
                        }
                    )
                    // 4. Clip the visual overflow from contentMode: .fill
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(white: 0.91), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)

            Text(video.title)
                .font(Font.custom("PlusJakartaSans-Bold", size: 11))
                .foregroundColor(.white)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Live search result row

private struct VideoResultCard: View {
    let video: VideoSearchResult
    let cardBg: Color
    let descriptionGray: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    AsyncImage(url: URL(string: video.thumbnailUrl)) { phase in
                        switch phase {
                        case .success(let image): image.resizable().aspectRatio(contentMode: .fill)
                        default: Color(red: 0.82, green: 0.76, blue: 0.76)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                    Color.black.opacity(0.3)

                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                        )
                }
                .frame(width: 96, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(video.title)
                        .font(Font.custom("PlusJakartaSans-Bold", size: 13))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    Text(video.description)
                        .font(Font.custom("Inter", size: 11))
                        .foregroundColor(descriptionGray)
                        .lineLimit(2)
                    Text(video.publishedAt.toFriendlyDate())
                        .font(Font.custom("Inter", size: 10))
                        .foregroundColor(descriptionGray)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(13)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Date formatting

private extension String {
    /// Parses the API's ISO-8601 `publishedAt` into "MMM d, yyyy" — falls back to the raw
    /// string if parsing fails, mirroring Android's try/catch fallback.
    func toFriendlyDate() -> String {
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        isoFormatter.locale = Locale(identifier: "en_US_POSIX")
        isoFormatter.timeZone = TimeZone(identifier: "UTC")

        guard let date = isoFormatter.date(from: self) else { return self }

        let friendlyFormatter = DateFormatter()
        friendlyFormatter.dateFormat = "MMM d, yyyy"
        friendlyFormatter.locale = Locale(identifier: "en_US")
        return friendlyFormatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        VideoSearchView(category: "RTO", query: "RTO")
    }
}
