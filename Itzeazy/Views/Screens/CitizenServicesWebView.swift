import SwiftUI
import WebKit

// MARK: - WKWebView Representable

struct WebViewRepresentable: UIViewRepresentable {
    let url: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let requestUrl = URL(string: url) else { return }
        if webView.url == nil {
            webView.load(URLRequest(url: requestUrl))
        }
    }
}

// MARK: - CitizenServicesWebView

struct CitizenServicesWebView: View {
    let url: String
    var title: String = "Citizen Services"

    @StateObject private var vm: WebViewModel
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var tabBarState: TabBarState

    init(url: String, title: String = "Citizen Services") {
        self.url   = url
        self.title = title
        _vm = StateObject(wrappedValue: WebViewModel(title: title, urlString: url))
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.10, green: 0.11, blue: 0.11).ignoresSafeArea()

            VStack(spacing: 0) {
                navHeader
                webContent
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }

    // MARK: - Custom Nav Header
    // Same design as HomeHeaderView — back arrow instead of hamburger.
    private var navHeader: some View {
        ZStack(alignment: .top) {
            // Back card (grey peeks below)
            Rectangle()
                .fill(Color(red: 0.72, green: 0.72, blue: 0.72))
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
                .padding(.horizontal, 1)

            // Front card (dark)
            Color(red: 0.10, green: 0.11, blue: 0.11)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))

            // Content row
            HStack(spacing: 0) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.red)
                }

                Spacer().frame(width: 12)

                Text(title)
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                    .foregroundColor(.white)

                Spacer()

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

    // MARK: - Web Content
    // WKWebView frame ends exactly at the tab bar top via dynamic padding.
    // tabBarState.height is measured at runtime from the real CustomTabBar.
    private var webContent: some View {
        ZStack {
            WebViewRepresentable(url: url)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                //.padding(.bottom, tabBarState.height)
                .padding(.bottom, 50) 

            if vm.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(
                            tint: Color(red: 0.85, green: 0.2, blue: 0.2)))
                        .scaleEffect(1.4)
                    Text("Loading…")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        withAnimation(.easeOut(duration: 0.3)) { vm.didFinishLoading() }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

struct CitizenServicesWebView_Previews: PreviewProvider {
    static var previews: some View {
        CitizenServicesWebView(url: "https://itzeazy.in")
            .environmentObject(TabBarState())
    }
}
