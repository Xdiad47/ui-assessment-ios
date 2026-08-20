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
    // Screens presented as a NavigationLink push (RTO/Passport/Visa/etc.) leave this nil
    // and rely on presentationMode.dismiss(). Screens hosting this as tab-root content
    // (e.g. MyOrdersView) have nothing to dismiss, so they pass their own back action.
    var onBack: (() -> Void)? = nil
    // Blocking "Important Notice" popup before the page loads. Screens whose own native
    // flow already showed this (Passport/Marriage/Birth/PAN's "Get Assistance") pass false
    // here to avoid asking twice in a row; everything else defaults to showing it.
    var showGovDisclaimer: Bool = false
    // Independent of the popup above — shows the slim translucent banner for the whole time
    // the page is up. Defaults to mirroring showGovDisclaimer, but can be forced true even
    // when the popup itself is skipped (still a private portal, even if already acknowledged).
    var showGovBanner: Bool
    // When set, showGovDisclaimer is additionally gated by the 3-shows/7-days cap for this
    // key (see GovDisclaimerFrequencyStore) instead of showing unconditionally every visit.
    let disclaimerServiceKey: String?

    @StateObject private var vm: WebViewModel
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var tabBarState: TabBarState
    @EnvironmentObject private var authGate: AuthGateController
    @State private var navigateToProfile = false
    @State private var disclaimerAcknowledged: Bool
    // Guards the .onAppear cap check below from re-running — belt and suspenders alongside
    // @State's own once-per-identity semantics.
    @State private var didCheckDisclaimerCap = false

    init(
        url: String,
        title: String = "Citizen Services",
        onBack: (() -> Void)? = nil,
        showGovDisclaimer: Bool = false,
        showGovBanner: Bool? = nil,
        disclaimerServiceKey: String? = nil
    ) {
        self.url     = url
        self.title   = title
        self.onBack  = onBack
        self.showGovDisclaimer = showGovDisclaimer
        self.showGovBanner = showGovBanner ?? showGovDisclaimer
        self.disclaimerServiceKey = disclaimerServiceKey
        _vm = StateObject(wrappedValue: WebViewModel(title: title, urlString: url))
        // When capped, the actual show/no-show decision is a UserDefaults side effect (see
        // GovDisclaimerFrequencyStore) — deferred to .onAppear below (fires once per genuine
        // appearance) rather than done here. NavigationLink's legacy destination: closure can
        // construct this struct's init multiple times per render pass, including when the
        // screen never actually appears, so a side effect here would corrupt the counter.
        _disclaimerAcknowledged = State(initialValue: disclaimerServiceKey != nil ? true : !showGovDisclaimer)
    }

    var body: some View {
        ZStack(alignment: .top) {
            NavigationLink(destination: ProfileView(onBackToHome: nil), isActive: $navigateToProfile) {
                EmptyView()
            }.hidden()

            Color(red: 0.10, green: 0.11, blue: 0.11).ignoresSafeArea()

            VStack(spacing: 0) {
                navHeader
                if disclaimerAcknowledged {
                    if showGovBanner { GovDisclaimerBanner() }
                    webContent
                }
            }

            if showGovDisclaimer && !disclaimerAcknowledged {
                GovDisclaimerPopupView(
                    onAcknowledge: { disclaimerAcknowledged = true },
                    onDismiss: { onBack?() ?? presentationMode.wrappedValue.dismiss() }
                )
                .zIndex(30)
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .onAppear {
            guard !didCheckDisclaimerCap, showGovDisclaimer, let key = disclaimerServiceKey else { return }
            didCheckDisclaimerCap = true
            let store = GovDisclaimerFrequencyStore.shared
            if store.shouldShow(key) {
                store.recordShown(key)
                disclaimerAcknowledged = false
            }
        }
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
                Button(action: { onBack?() ?? presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
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

                    Button(action: {
                        guard authGate.requireAuth() else { return }
                        navigateToProfile = true
                    }) {
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
