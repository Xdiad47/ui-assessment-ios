import SwiftUI
import VisionKit

// MARK: - DocumentScannerCameraView
// Mirrors Android's DocumentScannerCameraScreen.kt — NOT a live camera preview screen. A plain,
// light-themed chooser (Document Scan vs ID Scan, and for ID Scan a One-side/Two-side modal) that
// hands off entirely to the system document scanner (VNDocumentCameraViewController) for actual
// capture. No custom camera UI is built here, matching the explicit product decision to use the
// system scanner rather than try to reproduce a live-camera design VisionKit doesn't expose any
// way to skin. No gallery-import fallback either — scanning only, matching Android exactly.
//
// Two-Side ID Scan is deliberately two independent single-page scanner sessions (front, then
// back) rather than one two-page session, so this screen can reappear between them to show
// "Front done, now scan Back" — an app-level UX decision, not a VisionKit constraint.

struct DocumentScannerCameraView: View {
    let onClose: () -> Void
    let onProceed: (DocumentScanProceedResult) -> Void

    @StateObject private var viewModel = DocumentScannerCameraViewModel()
    private let repository = DocumentScannerRepository.shared

    @State private var showIdScanModal = false
    @State private var pendingMode: DocumentScanTab = .documentScan
    @State private var pendingSideOption: IdScanSideOption?
    @State private var capturedFrontURL: URL?
    @State private var showCameraCapture = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                ScrollView {
                    Group {
                        if capturedFrontURL != nil {
                            frontCapturedState
                        } else {
                            chooserState
                        }
                    }
                    .padding(20)
                }
            }
            .background(Color.white)

            if showIdScanModal { idScanModal }
        }
        .overlay(alignment: .bottom) { toastOverlay }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showCameraCapture) {
            DocumentCameraCaptureView { result in
                showCameraCapture = false
                handleCaptureResult(result)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onClose) {
                Image(systemName: "chevron.left").font(.system(size: 18, weight: .semibold)).foregroundColor(Color(hex: "#1A1A1A"))
            }
            Text("Scan Document")
                .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                .foregroundColor(Color(hex: "#1A1A1A"))
            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
        .background(Color.white)
        .overlay(Rectangle().fill(Color(hex: "#E5E5EA")).frame(height: 1), alignment: .bottom)
    }

    // MARK: - Default chooser state

    private var chooserState: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("What would you like to scan?")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 20))
                    .foregroundColor(Color(hex: "#1A1A1A"))
                Text("We'll open the scanner and detect the edges automatically.")
                    .font(Font.custom("Inter", size: 13))
                    .foregroundColor(Color(hex: "#6E6E73"))
            }
            scanOptionCard(icon: "doc.text.fill", title: "Document Scan", subtitle: "Scan one or more pages of a document") {
                pendingMode = .documentScan
                pendingSideOption = nil
                launchScanner()
            }
            scanOptionCard(icon: "person.text.rectangle.fill", title: "ID Scan", subtitle: "Scan a single or two-sided ID card") {
                showIdScanModal = true
            }
        }
    }

    private func scanOptionCard(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color(hex: "#FFF0EF")).frame(width: 52, height: 52)
                    Image(systemName: icon).font(.system(size: 20)).foregroundColor(.red)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Font.custom("Inter", size: 16).weight(.semibold)).foregroundColor(Color(hex: "#1A1A1A"))
                    Text(subtitle).font(Font.custom("Inter", size: 12)).foregroundColor(Color(hex: "#6E6E73"))
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 14)).foregroundColor(Color(hex: "#C4C4C6"))
            }
            .padding(16)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#E5E5EA"), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Front-captured state (mid Two-Side ID Scan)

    private var frontCapturedState: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 40)).foregroundColor(.green)
            Text("Front side captured")
                .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                .foregroundColor(Color(hex: "#1A1A1A"))
            Text("Now scan the back of the ID card.")
                .font(Font.custom("Inter", size: 13))
                .foregroundColor(Color(hex: "#6E6E73"))
            scanOptionCard(icon: "arrow.turn.up.right", title: "Back Side", subtitle: "Tap to scan the back of the ID card") {
                launchScanner()
            }
            Button(action: { capturedFrontURL = nil }) {
                Text("Cancel and start over")
                    .font(Font.custom("Inter", size: 14).weight(.medium))
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - ID Scan side-selection modal

    private var idScanModal: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
                .onTapGesture { showIdScanModal = false }
            VStack(spacing: 0) {
                idScanOptionRow(icon: "person.text.rectangle", title: "One side ID Scan", subtitle: "Make a single sided ID Card") {
                    showIdScanModal = false
                    pendingMode = .idScan
                    pendingSideOption = .oneSide
                    launchScanner()
                }
                Divider()
                idScanOptionRow(icon: "rectangle.on.rectangle", title: "Two side ID Scan", subtitle: "Make a two sided ID Card") {
                    showIdScanModal = false
                    capturedFrontURL = nil
                    pendingMode = .idScan
                    pendingSideOption = .twoSide
                    launchScanner()
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color(hex: "#E5E5EA"), lineWidth: 1))
            .padding(.horizontal, 20)
        }
    }

    private func idScanOptionRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color(hex: "#F5F5F7")).frame(width: 56, height: 56)
                    Image(systemName: icon).font(.system(size: 22)).foregroundColor(Color(hex: "#1A1A1A"))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Font.custom("Inter", size: 15).weight(.semibold)).foregroundColor(Color(hex: "#1A1A1A"))
                    Text(subtitle).font(Font.custom("Inter", size: 12)).foregroundColor(Color(hex: "#6E6E73"))
                }
                Spacer()
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Scanner launch / result handling

    private func launchScanner() {
        guard VNDocumentCameraViewController.isSupported else {
            viewModel.onScanIssue("Document scanner isn't available on this device. Please try again.")
            return
        }
        showCameraCapture = true
    }

    private func handleCaptureResult(_ result: Result<[UIImage], DocumentCameraCaptureError>) {
        switch result {
        case .success(let images):
            guard !images.isEmpty else {
                viewModel.onScanIssue("We couldn't process that scan. Please try again.")
                return
            }
            do {
                // Mid Two-Side flow, front not yet captured — this result IS the front side; stash
                // it and stay on this screen instead of proceeding.
                if pendingSideOption == .twoSide, capturedFrontURL == nil {
                    capturedFrontURL = try repository.saveImageToCache(images[0], subdir: "document_scanner_raw")
                    return
                }

                var allURLs: [URL] = []
                if let front = capturedFrontURL { allURLs.append(front) }
                let pagesToSave = pendingMode == .documentScan ? images : [images[0]]
                for image in pagesToSave {
                    allURLs.append(try repository.saveImageToCache(image, subdir: "document_scanner_raw"))
                }
                capturedFrontURL = nil
                if let proceedResult = viewModel.buildProceedResult(mode: pendingMode, idSideOption: pendingSideOption, pageURLs: allURLs) {
                    onProceed(proceedResult)
                }
            } catch {
                viewModel.onScanIssue("We couldn't process that scan. Please try again.")
            }
        case .failure(.cancelled):
            // Any already-stashed front side is left in place so the user can retry the back side.
            break
        case .failure(.failed):
            viewModel.onScanIssue("Document scanner isn't available on this device. Please try again.")
        }
    }

    // MARK: - Toast

    private var toastOverlay: some View {
        Group {
            if let message = viewModel.toastMessage {
                ToastView(icon: "exclamationmark.triangle.fill", message: message)
                    .padding(.bottom, 40)
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
    DocumentScannerCameraView(onClose: {}, onProceed: { _ in })
}
