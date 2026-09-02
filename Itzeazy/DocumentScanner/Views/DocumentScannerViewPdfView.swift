import SwiftUI

// MARK: - DocumentScannerViewPdfView
// Mirrors Android's DocumentScannerViewPdfScreen.kt — dark theme (the only dark-themed screen
// besides the header bars elsewhere), reuses DocumentScannerReviewViewModel's methods rather than
// owning separate load logic, continuous vertical scroll of every page (no paginated/swipe
// viewer), bottom-left pill "EDIT" FAB (non-standard placement) opening the same Edit sheet Review
// uses.

struct DocumentScannerViewPdfView: View {
    let document: ScannedDocument
    let onBack: () -> Void
    let onSplitPdf: (ScannedDocument) -> Void
    let onRearrangePdf: (ScannedDocument) -> Void
    let onESign: (ScannedDocument) -> Void
    let onOcr: (ScannedDocument) -> Void

    @StateObject private var viewModel = DocumentScannerReviewViewModel()
    @State private var showEditSheet = false
    @State private var showCompressPopup = false
    @State private var showAddPasswordSheet = false

    private var liveDocument: ScannedDocument { viewModel.document ?? document }

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .background(Color(hex: "#0F0F11"))
        .navigationBarHidden(true)
        .overlay(alignment: .bottomLeading) { editFab }
        .onAppear {
            // The incoming `document` may carry a temp, already-decrypted pdfPath: opening a
            // password-protected file from My PDFs verifies the password, decrypts to a temp copy,
            // and hands that path down through Review. Calling loadExistingDocument(_:) without
            // passing it re-reads pdfPath from the persisted index — the still-encrypted original —
            // and PDFKit renders no pages from a locked document, so the viewer came up blank right
            // after a successful unlock. Forwarding the path keeps this session pointed at the
            // decrypted copy; the persisted entry and the real encrypted file stay untouched.
            viewModel.loadExistingDocument(
                document.id,
                unlockedPdfPath: document.isPasswordProtected ? document.pdfPath : nil
            )
            viewModel.refreshDocument()
            viewModel.loadPagesForViewing()
        }
        .scannerToast($viewModel.toastMessage, icon: "checkmark.circle.fill")
        .sheet(isPresented: $showEditSheet) {
            DocumentEditOptionsSheet(
                document: liveDocument,
                onCompress: { showCompressPopup = true },
                onSplit: { onSplitPdf(liveDocument) },
                onRearrange: { onRearrangePdf(liveDocument) },
                onESign: { onESign(liveDocument) },
                onAddPassword: { showAddPasswordSheet = true },
                onOcr: { onOcr(liveDocument) },
                onSelect: { showEditSheet = false }
            )
        }
        .sheet(isPresented: $showAddPasswordSheet) {
            AddPasswordSheetContent(onDismiss: { showAddPasswordSheet = false }, onAdd: { password in
                showAddPasswordSheet = false
                viewModel.addPassword(password)
            })
            .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $showCompressPopup) {
            ZStack {
                Color.black.opacity(0.45).ignoresSafeArea()
                CompressPopupCard(document: liveDocument, onDismiss: { showCompressPopup = false }, onSave: { scale, superCompress in
                    showCompressPopup = false
                    viewModel.compressConfirm(scale: scale, superCompress: superCompress)
                })
                .padding(.horizontal, 24)
            }
            .presentationBackground(.clear)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color(hex: "#1A1A1E"))
                    .clipShape(Circle())
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(liveDocument.name).font(Font.custom("Inter", size: 15).weight(.semibold)).foregroundColor(.white).lineLimit(1)
                Text("Scanned • \(formattedFileSize(liveDocument.fileSizeBytes))").font(Font.custom("Inter", size: 12)).foregroundColor(Color(hex: "#9CA3AF"))
            }
            Spacer()
            Button(action: shareDocument) {
                Image(systemName: "square.and.arrow.up").font(.system(size: 16)).foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color(hex: "#1A1A1E"))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "#191C1D").edgesIgnoringSafeArea(.top))
    }

    private var content: some View {
        Group {
            if viewModel.pagesLoading && viewModel.pages.isEmpty {
                ProgressView().tint(.red).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.pages.isEmpty {
                Text("Couldn't load this document.")
                    .font(Font.custom("Inter", size: 14))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { _, image in
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(image.size.width / max(image.size.height, 1), contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .shadow(color: Color.black.opacity(0.4), radius: 12, x: 4, y: 6)
                        }
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
        }
    }

    // Shares liveDocument.pdfPath — for a password-protected document that's currently unlocked,
    // that's the decrypted temp copy, not the encrypted original. That's a deliberate choice, not
    // an oversight: an earlier version of this method re-read the persisted (still-encrypted) path
    // instead, on the reasoning that sharing a locked document should keep it locked. In practice
    // that made the system share sheet come up with the presenting app's own icon as a generic
    // fallback and an empty destination list — most built-in share targets (Mail, Messages, Save
    // to Files) can't preview or validate content they can't decrypt, so they exclude themselves
    // entirely, and the share button looked broken. Sharing the same file the user is already
    // looking at is guaranteed valid and works with every installed destination — EXCEPT when
    // liveDocument.pdfPath is still the encrypted original, which happens if this document was
    // locked and shared from this same screen without ever going through the unlock-with-password
    // flow (that's the only step that swaps pdfPath to a decrypted copy). The isEncrypted check
    // below catches that case explicitly instead of silently handing PDFKit an encrypted file.
    private func shareDocument() {
        let url = URL(fileURLWithPath: liveDocument.pdfPath)
        guard FileManager.default.fileExists(atPath: url.path) else {
            viewModel.toastMessage = "Couldn't share this document. Please try again."
            return
        }
        guard !DocumentScannerPDFService.isEncrypted(url: url) else {
            viewModel.toastMessage = "This document is password protected. Open it from My PDFs and unlock it before sharing."
            return
        }
        presentShareSheet(items: [url])
    }

    private var editFab: some View {
        Button(action: { showEditSheet = true }) {
            HStack(spacing: 8) {
                Image(systemName: "pencil").font(.system(size: 15, weight: .bold))
                Text("EDIT").font(Font.custom("Inter", size: 15).weight(.bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color.red)
            .clipShape(Capsule())
            .shadow(color: Color.red.opacity(0.4), radius: 8, x: 0, y: 8)
        }
        .padding(.leading, 24)
        .padding(.bottom, 24)
    }
}

#Preview {
    DocumentScannerViewPdfView(
        document: DocumentScannerPreviewSupport.sampleDocument(name: "Passport", pageCount: 2),
        onBack: {},
        onSplitPdf: { _ in },
        onRearrangePdf: { _ in },
        onESign: { _ in },
        onOcr: { _ in }
    )
}
