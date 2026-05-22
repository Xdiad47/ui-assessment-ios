import SwiftUI

struct VideoTutorialsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = VideoTutorialsViewModel()
    @State private var naturalHeight: CGFloat = 0

    private let backgroundColor = Color(red: 0.96, green: 0.96, blue: 0.96)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)

    private let thumbSize = CGSize(width: 163, height: 100)

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color(red: 0.10, green: 0.11, blue: 0.11).ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        header

                        titleStrip
                            .padding(.horizontal, 16)

                        videosHeader
                            .padding(.horizontal, 16)

                        tutorialsGrid
                            .padding(.horizontal, 16)

                        Spacer(minLength: 0)
                    }
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: ContentHeightKey.self, value: geo.size.height)
                    })
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .top)
                    .background(backgroundColor)
                }
                .scrollDisabled(naturalHeight <= proxy.size.height)
                .onPreferenceChange(ContentHeightKey.self) { naturalHeight = $0 }
            }
        }
        .navigationBarHidden(true)
    }

    private var header: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(strokeColor)
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
                .padding(.horizontal, 1)

            Color(red: 0.10, green: 0.11, blue: 0.11)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))

            HStack(spacing: 12) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                }

                Text(viewModel.pageTitle)
                    .font(Font.custom("PlusJakartaSans-SemiBold", size: 16))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
        }
    }

    private var titleStrip: some View {
        HStack {
            Text(viewModel.pageTitle)
                .font(Font.custom("PlusJakartaSans-SemiBold", size: 16))
                .foregroundColor(.white)

            Spacer()

            Button(action: {
                // Book Service action
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("Book Service")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 12))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(Color.red)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color(red: 0.10, green: 0.11, blue: 0.11))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var videosHeader: some View {
        HStack {
            Text(viewModel.sectionTitle)
                .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 15))
                    .foregroundColor(.red)

                Text(viewModel.seeMoreTitle)
                    .font(Font.custom("Inter", size: 12).weight(.semibold))
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(strokeColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var tutorialsGrid: some View {
        VStack(spacing: 16) {
            HStack(spacing: 21) {
                tutorialThumb(url: viewModel.tutorials[0].imageURL)
                tutorialThumb(url: viewModel.tutorials[1].imageURL)
                Spacer(minLength: 0)
            }

            HStack(spacing: 21) {
                tutorialThumb(url: viewModel.tutorials[2].imageURL)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tutorialThumb(url: String) -> some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure(_):
                Color(red: 0.82, green: 0.76, blue: 0.76)
            case .empty:
                Color(red: 0.82, green: 0.76, blue: 0.76)
            @unknown default:
                Color(red: 0.82, green: 0.76, blue: 0.76)
            }
        }
        .frame(width: thumbSize.width, height: thumbSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private struct ContentHeightKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
}

#Preview {
    NavigationView {
        VideoTutorialsView()
    }
}
