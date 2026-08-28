import SwiftUI

// MARK: - DocumentScannerFilterView
// Mirrors Android's DocumentScannerFilterScreen.kt — a horizontally-scrolling 5-filter carousel
// with real per-filter thumbnail previews loading incrementally, and a large preview of the
// current page with the selected filter applied. Filter selection is global (all pages), matching
// the on-screen copy — this screen has no per-page picker.

struct DocumentScannerFilterView: View {
    let pageURLs: [URL]
    let onBack: () -> Void
    let onNext: ([URL]) -> Void

    @StateObject private var viewModel = DocumentScannerFilterViewModel()

    private var pageCount: Int { pageURLs.count }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 24) {
                    instructionHeader
                    previewFrame
                }
                .padding(.top, 24)
            }
            filtersCarousel
            navigationFooter
        }
        .background(Color(hex: "#030302"))
        .navigationBarHidden(true)
        .onAppear { viewModel.initSession(pageURLs) }
        .overlay(loadingOverlay)
        .overlay(alignment: .bottom) { toastOverlay }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image("back_arrow").resizable().scaledToFit().frame(width: 24, height: 24)
            }
            Text("Back")
                .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(height: 56)
        .background(
            Color(hex: "#191C1D")
                .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                .edgesIgnoringSafeArea(.top)
        )
    }

    private var instructionHeader: some View {
        VStack(spacing: 2) {
            Text("Filter will be applied to all the pages")
                .font(Font.custom("Inter", size: 16).weight(.medium))
                .foregroundColor(.white)
            Text("(can be changed later)")
                .font(Font.custom("Inter", size: 13))
                .foregroundColor(Color(hex: "#8E8E93"))
            Text("\(pageCount) page\(pageCount == 1 ? "" : "s")")
                .font(Font.custom("Inter", size: 13).weight(.semibold))
                .foregroundColor(.white)
        }
        .multilineTextAlignment(.center)
    }

    private var previewFrame: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).stroke(Color(hex: "#38383A"), lineWidth: 1)
            if let preview = viewModel.previewImage {
                Image(uiImage: preview).resizable().scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(1)
            } else {
                ProgressView().tint(.white)
            }
        }
        .frame(width: 337, height: 366)
    }

    // MARK: - Filters carousel

    private var filtersCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(DocScanFilter.allCases) { filter in
                    filterChip(filter)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
    }

    private func filterChip(_ filter: DocScanFilter) -> some View {
        let isSelected = viewModel.selectedFilter == filter
        return Button(action: { viewModel.selectFilter(filter) }) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#1C1C1E"))
                    if let thumb = viewModel.thumbnails[filter] {
                        Image(uiImage: thumb).resizable().aspectRatio(contentMode: .fill)
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else if viewModel.isLoadingPreviews {
                        ProgressView().tint(.white).scaleEffect(0.7)
                    }
                }
                .frame(width: 64, height: 64)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color(hex: "#0084FF") : Color.clear, lineWidth: 3))

                Text(filter.label)
                    .font(Font.custom("Inter", size: 12).weight(isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : Color(hex: "#8E8E93"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 72)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Navigation footer

    private var navigationFooter: some View {
        HStack {
            footerButton(icon: "chevron.left", label: "Back", tint: Color(hex: "#2C2C2E"), action: onBack)
            Spacer()
            footerButton(icon: "chevron.right", label: "Next", tint: Color(hex: "#00D690"), disabled: viewModel.isProcessing) {
                viewModel.next(onDone: onNext)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
    }

    private func footerButton(icon: String, label: String, tint: Color, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(tint).frame(width: 40, height: 40)
                    if disabled {
                        ProgressView().tint(.white).scaleEffect(0.7)
                    } else {
                        Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    }
                }
                Text(label).font(Font.custom("Inter", size: 12).weight(.medium)).foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    // MARK: - Loading overlay

    // Matches EditPhotoMakerView's loadingOverlay exactly — same dimmed scrim, white rounded
    // card, red-tinted spinner, and label font/size/color — so a "processing" moment reads the
    // same way across the app instead of introducing a one-off design just for this screen.
    private var loadingOverlay: some View {
        Group {
            if viewModel.isApplyingFilter || viewModel.isProcessing {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    VStack(spacing: 14) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .red))
                            .scaleEffect(1.3)
                        Text(viewModel.isProcessing ? "Processing pages..." : "Applying filter...")
                            .font(Font.custom("PlusJakartaSans-SemiBold", size: 15))
                            .foregroundColor(Color(hex: "#191c1d"))
                    }
                    .frame(width: 160, height: 110)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 10)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: viewModel.isApplyingFilter)
        .animation(.easeInOut(duration: 0.15), value: viewModel.isProcessing)
    }

    // MARK: - Toast

    private var toastOverlay: some View {
        Group {
            if let message = viewModel.toastMessage {
                ToastView(icon: "exclamationmark.triangle.fill", message: message)
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            if viewModel.toastMessage == message { viewModel.toastMessage = nil }
                        }
                    }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.toastMessage)
    }
}

#Preview {
    DocumentScannerFilterView(
        pageURLs: DocumentScannerPreviewSupport.samplePageURLs(),
        onBack: {},
        onNext: { _ in }
    )
}
