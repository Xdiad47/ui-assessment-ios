import SwiftUI

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private struct SizeReader: View {
    var onChange: (CGSize) -> Void

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(key: SizePreferenceKey.self, value: proxy.size)
        }
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

/// "Video Tutorials" Home-screen section — a dark card of 8 circular category tiles (icon + play
/// badge + label), 4 per row. Tapping a tile opens a live YouTube search scoped to that category.
/// Mirrors Android's `VideoTutorialsSection.kt`.
struct VideoTutorialsGridView: View {

    private struct TutorialCategory {
        let title: String
        let icon: String
        let query: String
    }

    // `query` is what's sent to the search API — not always identical to the tile label,
    // matching Android's VideoTutorialsSection.kt (e.g. "Marraige Registration" tile searches
    // the correctly-spelled "Marriage Registration").
    private let categories: [TutorialCategory] = [
        TutorialCategory(title: "RTO Services", icon: "rto_service_icon", query: "RTO"),
        TutorialCategory(title: "Passport", icon: "passport_icon", query: "Passport"),
        TutorialCategory(title: "Visa", icon: "visa_icon", query: "Visa"),
        TutorialCategory(title: "Driving License", icon: "dl_icon", query: "Driving License"),
        TutorialCategory(title: "Birth Certificate", icon: "birth_icon", query: "Birth Certificate"),
        TutorialCategory(title: "Marraige Registration", icon: "marraige_icon", query: "Marriage Registration"),
        TutorialCategory(title: "Aadhar Card", icon: "adhar_icon", query: "Aadhaar Card"),
        TutorialCategory(title: "Pan card", icon: "pan_icon", query: "PAN Card")
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    @State private var selectedTitle: String = ""
    @State private var selectedQuery: String = ""
    @State private var navigateToSearch = false
    @State private var titleSize: CGSize = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            NavigationLink(
                destination: VideoSearchView(category: selectedTitle, query: selectedQuery),
                isActive: $navigateToSearch
            ) { EmptyView() }
            .hidden()

            VStack(alignment: .leading, spacing: 6) {
                Text("Video Tutorials")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                    .foregroundColor(.white)
                    .background(
                        SizeReader { size in
                            if size != titleSize {
                                titleSize = size
                            }
                        }
                    )

                Rectangle()
                    .fill(Color.red)
                    .frame(width: titleSize.width, height: 2)
                    .cornerRadius(1)
            }

            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(categories, id: \.title) { category in
                    Button {
                        selectedTitle = category.title
                        selectedQuery = category.query
                        navigateToSearch = true
                    } label: {
                        VideoTutorialTile(title: category.title, icon: category.icon)
                    }
                    .buttonStyle(NoHighlightButtonStyle())
                }
            }
        }
        .padding(20)
        .background(Color(red: 0.10, green: 0.11, blue: 0.11))
        .cornerRadius(30)
    }
}

private struct VideoTutorialTile: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color(red: 0.165, green: 0.180, blue: 0.184))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                    )

                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                    )
            }

            Text(title)
                .font(Font.custom("PlusJakartaSans-Bold", size: 9))
                .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.85))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    VideoTutorialsGridView()
        .background(Color.white)
}
