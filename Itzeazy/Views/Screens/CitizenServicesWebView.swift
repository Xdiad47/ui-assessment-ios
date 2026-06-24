import SwiftUI
import WebKit

// MARK: - WKWebView Representable

struct WebViewRepresentable: UIViewRepresentable {
    let url: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let requestUrl = URL(string: url) else { return }
        // Only load once — prevents reload on every SwiftUI re-render
        if webView.url == nil {
            let request = URLRequest(url: requestUrl)
            webView.load(request)
        }
    }
}

// MARK: - CitizenServicesWebView

struct CitizenServicesWebView: View {
    let url: String
    @Environment(\.presentationMode) private var presentationMode
    @State private var isLoading = true

    var body: some View {
        ZStack(alignment: .top) {
            // Full dark background — fills entire screen incl. status bar area
            Color(red: 0.10, green: 0.11, blue: 0.11).ignoresSafeArea()

            VStack(spacing: 0) {
                navHeader
                webContent
            }
        }
        // No navigationBarHidden needed — presented as fullScreenCover
    }

    // MARK: - Custom Nav Header (matches VehicleSearchResultsView / RTOServiceInitialView style)
    private var navHeader: some View {
        ZStack(alignment: .top) {
            // Back card: grey, slightly taller — peeks below the dark card
            Rectangle()
                .fill(Color(red: 0.72, green: 0.72, blue: 0.72))
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
                .padding(.horizontal, 1)

            // Front card: dark header
            Color(red: 0.10, green: 0.11, blue: 0.11)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))

            // Content row
            HStack(spacing: 0) {
                // Left: back arrow + title
                HStack(spacing: 12) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image("back_arrow")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }

                    Text("Citizen Services")
                        .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                        .foregroundColor(.white)
                }

                Spacer()

                // Right: bell + profile avatar
                HStack(spacing: 16) {
                    Image(systemName: "bell")
                        .font(.system(size: 18))
                        .foregroundColor(.white)

                    ZStack {
                        Circle()
                            .fill(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                            .frame(width: 30, height: 30)
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 20)
            .frame(height: 60)
        }
    }

    // MARK: - Web Content with Loading State
    private var webContent: some View {
        ZStack {
            WebViewRepresentable(url: url)
                .background(Color.white)

            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.85, green: 0.2, blue: 0.2)))
                        .scaleEffect(1.4)
                    Text("Loading…")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        withAnimation(.easeOut(duration: 0.3)) { isLoading = false }
                    }
                }
            }
        }
    }
}

struct CitizenServicesWebView_Previews: PreviewProvider {
    static var previews: some View {
        CitizenServicesWebView(url: "https://itzeazy.in")
    }
}
