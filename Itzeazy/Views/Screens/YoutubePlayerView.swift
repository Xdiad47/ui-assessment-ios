import SwiftUI
import WebKit

// MARK: - YoutubePlayerView

struct YoutubePlayerView: View {
    let videoURL: String
    let title: String

    @Environment(\.presentationMode) private var presentationMode

    private let darkBg      = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)

    private var videoId: String? { extractYouTubeVideoId(from: videoURL) }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                if let videoId {
                    YoutubeWebPlayer(videoId: videoId)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Spacer()
                    Text("Could not load video")
                        .foregroundColor(.white.opacity(0.6))
                        .font(Font.custom("PlusJakartaSans-Regular", size: 15))
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
    }

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
                Text(title)
                    .font(Font.custom("PlusJakartaSans-SemiBold", size: 16))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
        }
    }
}

// MARK: - WKWebView Wrapper

private struct YoutubeWebPlayer: UIViewRepresentable {
    let videoId: String

    private var embedURL: String {
        "https://www.youtube-nocookie.com/embed/\(videoId)"
        + "?autoplay=1&playsinline=1&rel=0&showinfo=0"
        + "&modestbranding=1&controls=1&fs=1&enablejsapi=1&iv_load_policy=3"
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black
        webView.isOpaque = false
        // Clean Safari-style UA — no embedded WebView markers
        webView.customUserAgent =
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) " +
            "AppleWebKit/605.1.15 (KHTML, like Gecko) " +
            "Version/17.0 Mobile/15E148 Safari/604.1"
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard webView.url == nil, let url = URL(string: embedURL) else { return }
        // Referer header — mirrors Android: loadUrl(embedUrl, mapOf("Referer" to "https://io.xdiad.itzeazy"))
        // YouTube uses this to validate the embed origin; without it the player shows an error
        var request = URLRequest(url: url)
        request.setValue("https://io.xdiad.itzeazy", forHTTPHeaderField: "Referer")
        webView.load(request)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate {

        func webView(_ webView: WKWebView,
                     decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = action.request.url, let host = url.host else {
                decisionHandler(.allow); return
            }
            // Block non-embed YouTube URLs (related video clicks, full site navigation)
            // Mirrors Android: if (isYouTube && !url.contains("/embed/")) return true (blocked)
            if (host.contains("youtube") || host.contains("youtu.be"))
                && !url.absoluteString.contains("/embed/") {
                decisionHandler(.cancel); return
            }
            let allowed = ["youtube.com", "youtu.be", "ytimg.com", "ggpht.com",
                           "googlevideo.com", "google.com", "googleapis.com",
                           "youtube-nocookie.com", "doubleclick.net", "googlesyndication.com"]
            decisionHandler(allowed.contains(where: { host.hasSuffix($0) }) ? .allow : .cancel)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Inject 3× with delays — mirrors Android's 0s/2s/4s delayed injection
            // YouTube renders end-screen overlays after the page load event fires
            for delay in [0.0, 2.0, 4.0] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak webView] in
                    webView?.evaluateJavaScript(hideOverlaysJS, completionHandler: nil)
                }
            }
        }
    }
}

// MARK: - JS: hide end-screen overlays (mirrors Android's HIDE_MORE_VIDEOS_JS)

private let hideOverlaysJS = """
(function(){
  if(!document.getElementById('itz-hide')){
    var s=document.createElement('style');
    s.id='itz-hide';
    s.textContent='.ytp-pause-overlay,.ytp-pause-overlay-container,.ytp-endscreen-content,.ytp-ce-element,.ytp-ce-covering-overlay,.ytp-ce-element-shadow,.ytp-endscreen-previous,.ytp-endscreen-next,.ytp-watermark,.ytp-impression-link,.ytp-paid-content-overlay,.iv-branding,.branding-img-container,.ytp-cards-teaser,.ytp-cards-button,.annotation{display:none!important;height:0!important;visibility:hidden!important;pointer-events:none!important;}';
    document.head.appendChild(s);
  }
  var all=document.querySelectorAll('a,button,span,div');
  for(var i=0;i<all.length;i++){
    if(all[i].textContent.trim()==='More videos'){
      all[i].style.display='none';
      if(all[i].parentElement)all[i].parentElement.style.display='none';
    }
  }
})();
"""

// MARK: - Video ID extractor (mirrors Android's extractYouTubeVideoId)

private func extractYouTubeVideoId(from url: String) -> String? {
    let patterns = [
        #"youtu\.be/([a-zA-Z0-9_\-]{11})"#,
        #"youtube\.com/watch\?.*v=([a-zA-Z0-9_\-]{11})"#,
        #"youtube\.com/embed/([a-zA-Z0-9_\-]{11})"#
    ]
    for pattern in patterns {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)),
              let range = Range(match.range(at: 1), in: url) else { continue }
        return String(url[range])
    }
    return nil
}
