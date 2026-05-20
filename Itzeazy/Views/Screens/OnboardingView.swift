import SwiftUI

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
                        Button(action: completeOnboarding) {
                            Text("Skip")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "#191c1d"))
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
                // Title: Plus Jakarta Sans Bold, 32px, line-height 40px
                VStack(alignment: .leading, spacing: 0) {
                    Text(viewModel.pages[viewModel.currentPage].titleLine1)
                        .font(Font.custom("PlusJakartaSans-Bold", size: 32))
                        .foregroundColor(Color(hex: "#191c1d"))
                        .tracking(-0.8)
                        .lineSpacing(8)  // 40px line-height on 32px font ≈ 8pt extra
                    Text(viewModel.pages[viewModel.currentPage].titleLine2)
                        .font(Font.custom("PlusJakartaSans-Bold", size: 32))
                        .foregroundColor(viewModel.pages[viewModel.currentPage].titleLine2Color)
                        .tracking(-0.8)
                        .lineSpacing(8)
                }
                // Subtitle: Inter Regular, 18px, line-height ~29.25px
                Text(viewModel.pages[viewModel.currentPage].subtitle)
                    .font(Font.custom("Inter", size: 18))
                    .foregroundColor(Color(hex: "#5f5e5e"))
                    .lineSpacing(5.25) // 29.25 - 18*1.165... ≈ 5.25pt extra leading
                    .fixedSize(horizontal: false, vertical: true)
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
