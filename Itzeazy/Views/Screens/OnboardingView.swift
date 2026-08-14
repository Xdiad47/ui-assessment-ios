import SwiftUI
import UIKit

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let safeTop      = geometry.safeAreaInsets.top
            let safeBottom   = geometry.safeAreaInsets.bottom
            let width        = geometry.size.width
            let headerHeight: CGFloat = 48
            // Content box height = everything below the status bar + header
            // Mirrors Android: Box(modifier = Modifier.fillMaxSize()) after the header
            let contentHeight = geometry.size.height - headerHeight
            let imageHeight   = contentHeight * 0.46   // Android: fillMaxHeight(0.46f)
            let sheetHeight   = contentHeight * 0.60   // Android: fillMaxHeight(0.60f)
            let buttonShadow  = Color(red: 187/255, green: 0, blue: 17/255, opacity: 0.2)

            ZStack(alignment: .top) {

                // ── Dark background ──────────────────────────────────────────
                // Android: Box background Color(0xFF191C1D)
                Color(hex: "#191c1d").ignoresSafeArea()

                // ── Image carousel (top 46% of content box) ─────────────────
                // Android: Box .fillMaxHeight(0.46f) .align(TopCenter)
                TabView(selection: $viewModel.currentPage) {
                    ForEach(0..<viewModel.pages.count, id: \.self) { index in
                        Image(viewModel.pages[index].image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: width, height: imageHeight)
                            .clipped()
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(width: width, height: imageHeight)
                .padding(.top, 40)
                //.padding(.top, headerHeight - 20)

                // ── White sheet (bottom 60% of content box) ─────────────────
                // Android: Box .fillMaxHeight(0.60f) .align(BottomCenter)
                // Overlaps image by 6% of contentHeight — rounded corners sit on image
                VStack {
                    Spacer()
                    sheetContent(safeBottom: safeBottom, buttonShadow: buttonShadow)
                        .frame(height: sheetHeight + safeBottom)
                        .background(Color.white)
                        .clipShape(CustomCorners(corners: [.topLeft, .topRight], radius: 32))
                }
                .ignoresSafeArea(edges: .bottom)

                // ── Header (rendered last = on top) ──────────────────────────
                // Android: OnboardingHeader with clip(RoundedCornerShape(bottomStart=10, bottomEnd=10))
                VStack(spacing: 0) {
                    Color.white.frame(height: safeTop)

                    HStack {
                        Text("Itzeazy")
                            .font(Font.custom("PlusJakartaSans-ExtraBold", size: 20))
                            .foregroundColor(.red)
                            .tracking(-1)
                        Spacer()
                        if !viewModel.isLastPage {
                            Button(action: { viewModel.skipToDisclaimer() }) {
                                Text("Skip")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "#191c1d"))
                            }
                        }
                    }
                    .frame(height: headerHeight)
                    .padding(.horizontal, 24)
                    .background(Color.white)

                    // Android: Box .height(1.dp) .background(Color(0xFFB7B7B7))
                    Rectangle()
                        .fill(Color(hex: "#b7b7b7"))
                        .frame(height: 1)
                }
                .clipShape(CustomCorners(corners: [.bottomLeft, .bottomRight], radius: 16))
                .ignoresSafeArea(edges: .top)
            }
        }
    }

    // ── Sheet content ────────────────────────────────────────────────────────
    @ViewBuilder
    private func sheetContent(safeBottom: CGFloat, buttonShadow: Color) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                // Title: Plus Jakarta Sans Bold — size/line-height vary per page
                let page = viewModel.pages[viewModel.currentPage]
                Group {
                    if page.titleInline {
                        (
                            Text(page.titleLine1).foregroundColor(Color(hex: "#191c1d"))
                            + Text(page.titleLine2).foregroundColor(page.titleLine2Color)
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(page.titleLine1)
                                .foregroundColor(Color(hex: "#191c1d"))
                            if !page.titleLine2.isEmpty {
                                Text(page.titleLine2)
                                    .foregroundColor(page.titleLine2Color)
                            }
                        }
                    }
                }
                .font(Font.custom("PlusJakartaSans-Bold", size: page.titleFontSize))
                .tracking(-0.8)
                .lineSpacing(page.titleLineSpacing)
                // Subtitle: Inter Regular — size/line-height vary per page
                Text(page.subtitle)
                    .font(Font.custom("Inter", size: page.subtitleFontSize))
                    .foregroundColor(Color(hex: "#5f5e5e"))
                    .lineSpacing(page.subtitleLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)

                if page.showLegalLinks {
                    legalLinksRow
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
            .padding(.top, 36)

            Spacer(minLength: 24)

            // Page indicator — Figma: 6px dots, 8px gap, active = red 24px capsule
            HStack(spacing: 8) {
                ForEach(0..<viewModel.pages.count, id: \.self) { index in
                    if index == viewModel.currentPage {
                        Capsule()
                            .fill(Color.red)
                            .frame(width: 24, height: 6)
                    } else {
                        Circle()
                            .fill(Color(hex: "#e1e3e4"))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .padding(.bottom, 28)

            // Next / Get Started button — Figma: dual shadow, red bg, capsule
            Button(action: {
                viewModel.isLastPage ? completeOnboarding() : viewModel.goToNext()
            }) {
                HStack(spacing: 8) {
                    Text(viewModel.buttonTitle)
                        .font(Font.custom("PlusJakartaSans-SemiBold", size: 18))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(hex: "#ff0000"))
                .clipShape(Capsule())
                // Figma: shadow 0px 10px 15px -3px + 0px 4px 6px -4px, both rgba(187,0,17,0.2)
                .shadow(color: Color(red: 187/255, green: 0, blue: 17/255, opacity: 0.2),
                        radius: 15, x: 0, y: 10)
                .shadow(color: Color(red: 187/255, green: 0, blue: 17/255, opacity: 0.2),
                        radius: 6, x: 0, y: 4)
            }
            .padding(.horizontal, 32) // Figma: 32px horizontal to match container
            .padding(.bottom, max(24, safeBottom + 10))
        }
    }

    private func completeOnboarding() {
        withAnimation { hasSeenOnboarding = true }
    }

    // Mirrors Android's LegalLinksRow — two separately tappable links,
    // opened in the external browser like every other outbound link in the app.
    private var legalLinksRow: some View {
        HStack(spacing: 6) {
            Button(action: { openURL("https://itzeazy.in/terms") }) {
                Text("Terms & Conditions")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.red)
                    .underline()
            }
            Text("•")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#5f5e5e"))
            Button(action: { openURL("https://itzeazy.in/privacy-policy") }) {
                Text("Privacy Policy")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.red)
                    .underline()
            }
        }
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

struct CustomCorners: Shape {
    var corners: UIRectCorner
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    OnboardingView()
}
