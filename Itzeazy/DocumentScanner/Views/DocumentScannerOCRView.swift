import SwiftUI
import UIKit

// MARK: - DocumentScannerOCRView
// Mirrors Android's DocumentScannerOcrScreen.kt — selectable text in a bordered scrollable card,
// one "Copy" button (no Share button in this design), Latin-script recognition only.

struct DocumentScannerOCRView: View {
    let document: ScannedDocument
    let onBack: () -> Void

    @StateObject private var viewModel = DocumentScannerOCRViewModel()
    @State private var showCopiedToast = false

    var body: some View {
        VStack(spacing: 0) {
            ScannerFlowHeader(title: document.name, subtitle: "(OCR)", onBack: onBack)
            content
            copyButton
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .onAppear { viewModel.initDocument(document) }
        .scannerToast($viewModel.toastMessage)
        .overlay(alignment: .bottom) { copiedToastOverlay }
    }

    private var content: some View {
        Group {
            if viewModel.isLoading {
                ProgressView().tint(.red)
            } else if let text = viewModel.recognizedText {
                ScrollView {
                    Text(text)
                        .font(Font.custom("Inter", size: 14))
                        .foregroundColor(Color(hex: "#1C1C1E"))
                        .lineSpacing(6)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#E5E5E5"), lineWidth: 1))
                .padding(16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var copyButton: some View {
        Button(action: copyText) {
            Text("Copy")
                .font(Font.custom("Inter", size: 16).weight(.bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(canCopy ? Color.red : Color(hex: "#C4C4C6"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!canCopy)
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 20)
    }

    private var canCopy: Bool {
        guard let text = viewModel.recognizedText else { return false }
        return !text.isEmpty
    }

    /// Unlike every other toast in this feature, this confirmation is pure UI-layer logic (no
    /// view-model round trip needed) — matching Android's OCR screen exactly, where Copy is the
    /// one toast not sourced from the ViewModel.
    private func copyText() {
        guard let text = viewModel.recognizedText, !text.isEmpty else { return }
        UIPasteboard.general.string = text
        withAnimation { showCopiedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showCopiedToast = false }
        }
    }

    private var copiedToastOverlay: some View {
        Group {
            if showCopiedToast {
                ToastView(icon: "checkmark.circle.fill", message: "Copied to clipboard")
                    .padding(.bottom, 90)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

#Preview {
    DocumentScannerOCRView(
        document: DocumentScannerPreviewSupport.sampleDocument(name: "Electricity Bill"),
        onBack: {}
    )
}
