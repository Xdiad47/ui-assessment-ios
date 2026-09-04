import SwiftUI

// MARK: - DocumentScannerEditView
// Mirrors Android's DocumentScannerEditScreen.kt — rotate-only per-page edit (no crop step; see
// DocumentScannerEditViewModel). The Figma reference for this screen shows a draggable 8-handle
// crop overlay, but Android never built manual cropping (VisionKit/ML Kit already crop during
// capture), so this adopts the Figma's dark theme and toolbar styling without the crop handles —
// matching Android's real, defined behavior per the standing instruction to follow Android's flow
// where the design isn't fully specified.

struct DocumentScannerEditView: View {
    let rawPages: [CapturedPage]
    let onBack: () -> Void
    let onNext: ([URL]) -> Void

    @StateObject private var viewModel = DocumentScannerEditViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header
            previewArea
            if viewModel.pages.count > 1 {
                thumbnailStrip
            }
            bottomToolbar
        }
        .background(Color(hex: "#030302"))
        .navigationBarHidden(true)
        .onAppear { viewModel.initSession(rawPages) }
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

    // MARK: - Preview

    private var currentPage: ScanPageDraft? {
        viewModel.pages.indices.contains(viewModel.currentIndex) ? viewModel.pages[viewModel.currentIndex] : nil
    }

    private var previewArea: some View {
        RotatedPagePreview(page: currentPage)
            .padding(20)
            .frame(maxHeight: .infinity)
    }

    // MARK: - Thumbnail strip (page numbers only, matching Android — not real image thumbnails)

    private var thumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, _ in
                    Button(action: { viewModel.selectPage(index) }) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 50)
                            .background(Color(hex: "#222228"))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(index == viewModel.currentIndex ? Color(hex: "#0A84FF") : Color(hex: "#222228"), lineWidth: 2))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 64)
    }

    // MARK: - Bottom toolbar

    private var bottomToolbar: some View {
        HStack(spacing: 0) {
            toolbarButton(icon: "chevron.left", label: "Back", tint: Color(hex: "#0A84FF"), action: onBack)
            toolbarButton(icon: "rotate.left", label: "Left", tint: Color(hex: "#0A84FF"), action: viewModel.rotateLeft)
            toolbarButton(icon: "rotate.right", label: "Right", tint: Color(hex: "#0A84FF"), action: viewModel.rotateRight)
            toolbarButton(icon: "arrow.right", label: "Next", tint: Color(hex: "#30D158"), disabled: viewModel.isProcessing) {
                viewModel.next(onDone: onNext)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .background(Color(hex: "#16161A"))
        .overlay(Rectangle().fill(Color(hex: "#222228")).frame(height: 1), alignment: .top)
    }

    private func toolbarButton(icon: String, label: String, tint: Color, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(tint.opacity(0.1)).frame(width: 40, height: 40)
                    if disabled {
                        ProgressView().tint(tint).scaleEffect(0.7)
                    } else {
                        Image(systemName: icon).font(.system(size: 18)).foregroundColor(tint)
                    }
                }
                Text(label).font(Font.custom("Inter", size: 12).weight(.medium)).foregroundColor(tint)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
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

// MARK: - RotatedPagePreview

private struct RotatedPagePreview: View {
    let page: ScanPageDraft?
    @State private var displayImage: UIImage?

    private let repository = DocumentScannerRepository.shared

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16).fill(Color(hex: "#0F0F11"))
            if let displayImage {
                Image(uiImage: displayImage).resizable().scaledToFit().padding(4)
            } else {
                ProgressView().tint(.white)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .task(id: currentKey) {
            guard let page else { displayImage = nil; return }
            let repo = repository
            let url = page.sourceURL
            let degrees = page.rotationDegrees
            let image = await Task.detached(priority: .userInitiated) { () -> UIImage? in
                guard let loaded = try? repo.decodeSampledImage(at: url) else { return nil }
                return repo.rotateImage(loaded, degrees: degrees)
            }.value
            displayImage = image
        }
    }

    private var currentKey: String {
        guard let page else { return "" }
        return "\(page.sourceURL.absoluteString)|\(page.rotationDegrees)"
    }
}

#if DEBUG
#Preview {
    DocumentScannerEditView(
        rawPages: DocumentScannerPreviewSupport.sampleCapturedPages(),
        onBack: {},
        onNext: { _ in }
    )
}
#endif
