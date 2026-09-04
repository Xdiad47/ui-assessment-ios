import SwiftUI
import UniformTypeIdentifiers

// MARK: - DocumentScannerReviewView
// Mirrors Android's DocumentScannerReviewScreen.kt — shows either a freshly-saved scan session's
// result, or an already-saved document opened from My PDFs (possibly password-decrypted to a temp
// copy for viewing). Has a "related documents" family strip (root + every Split/Rearrange/e-Sign
// derivative). The single cover thumbnail + page-count pill is the entire in-place page preview —
// multi-page browsing happens on the separate View PDF screen.

struct DocumentScannerReviewView: View {
    let session: ScanSession?
    let existingDocumentId: String?
    let unlockedPdfPath: String?
    let onBack: () -> Void
    let onDeleted: () -> Void
    let onAddMore: (ScannedDocument) -> Void
    let onSplitPdf: (ScannedDocument) -> Void
    let onRearrangePdf: (ScannedDocument) -> Void
    let onESign: (ScannedDocument) -> Void
    let onOcr: (ScannedDocument) -> Void
    let onMoveToFolder: (ScannedDocument) -> Void
    let onViewPdf: (ScannedDocument) -> Void
    let onImportedPdf: (ScannedDocument) -> Void
    let onFromFolder: () -> Void
    /// Set only when this Review screen is being shown immediately after Split/Rearrange/e-Sign
    /// completes, so the user gets an explicit, unmissable confirmation of the new derived
    /// document's name right when they land here — the "Versions of this scan" strip further
    /// down is easy to not notice, this toast can't be missed. `nil` for every other entry path
    /// (opened from My PDFs, a fresh scan session), where there's nothing new to announce. A
    /// binding (not a plain value) so it can be consumed exactly once: `.onAppear` nils it out
    /// on the flow host's side right after showing the toast, so navigating away (e.g. to View
    /// PDF) and back doesn't replay the same "Saved as..." toast on every re-appearance.
    var justSavedDocName: Binding<String?> = .constant(nil)

    @StateObject private var viewModel = DocumentScannerReviewViewModel()

    @State private var showRenameDialog = false
    @State private var renameText = ""
    @State private var showDeleteDialog = false
    @State private var showActionsMenu = false
    @State private var showAddSheet = false
    @State private var showShareSheet = false
    @State private var showEditSheet = false
    @State private var showCompressPopup = false
    @State private var showAddPasswordSheet = false
    @State private var showEmptyFoldersDialog = false
    @State private var showPDFPicker = false

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if viewModel.isSaving && viewModel.document == nil {
                        ProgressView().tint(.red).frame(maxWidth: .infinity).padding(.top, 60)
                    } else if viewModel.document != nil {
                        thumbnailCard.padding(.top, 20).padding(.horizontal, 16)
                    }
                    relatedDocumentsSection
                    Spacer(minLength: 100)
                }
                // Without this, the ScrollView centers a VStack that's narrower than the screen
                // (the leading `alignment:` only orders children *within* the VStack — it doesn't
                // position the VStack itself), which is why the 168pt-wide card was rendering
                // centered instead of pinned to the left like the Figma layout.
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            bottomTabBar
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .onAppear {
            if let session { viewModel.initSession(session) }
            else if let existingDocumentId { viewModel.loadExistingDocument(existingDocumentId, unlockedPdfPath: unlockedPdfPath) }
            viewModel.refreshDocument()
            if let savedName = justSavedDocName.wrappedValue {
                viewModel.toastMessage = "Saved as \(savedName)"
                justSavedDocName.wrappedValue = nil
            }
        }
        // Safety net: this screen is expected to get a fresh instance (and fresh @StateObject)
        // every time the flow host switches to it, so `.onAppear` alone should always be enough —
        // but if that assumption ever doesn't hold, an existingDocumentId change (e.g. e-Sign/
        // Split/Rearrange completing and handing back a different derived document) must still
        // reload the document and its "Versions of this scan" family, not silently keep showing
        // whatever was loaded before.
        .onChange(of: existingDocumentId) { _, newValue in
            guard let newValue else { return }
            viewModel.loadExistingDocument(newValue, unlockedPdfPath: unlockedPdfPath)
            viewModel.refreshDocument()
        }
        .overlay(alignment: .bottom) { toastOverlay }
        .fileImporter(isPresented: $showPDFPicker, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let url):
                let name = url.deletingPathExtension().lastPathComponent
                let needsAccess = url.startAccessingSecurityScopedResource()
                viewModel.importPDF(from: url, displayName: name) { newDoc in
                    if needsAccess { url.stopAccessingSecurityScopedResource() }
                    onImportedPdf(newDoc)
                }
            case .failure:
                break
            }
        }
        .sheet(isPresented: $showAddSheet) { addSheet }
        .sheet(isPresented: $showShareSheet) {
            if let doc = viewModel.document {
                DocumentShareOptionsSheet(document: doc, onShareJPG: {
                    showShareSheet = false
                    // Deferred: this options sheet is still animating out, and presenting the
                    // system share sheet on a controller mid-dismissal silently does nothing.
                    viewModel.shareAsJPG { urls in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            presentShareSheet(items: urls)
                        }
                    }
                }, onSharePDF: {
                    showShareSheet = false
                    // doc.pdfPath is only a decrypted temp copy if this document was opened via
                    // the unlock-with-password flow — locking a document and sharing it from the
                    // same Review session without ever leaving/re-entering it still points here at
                    // the encrypted original, which most built-in share targets can't preview and
                    // exclude themselves from entirely, leaving an app-icon-fallback empty sheet.
                    let url = URL(fileURLWithPath: doc.pdfPath)
                    guard !DocumentScannerPDFService.isEncrypted(url: url) else {
                        viewModel.toastMessage = "This document is password protected. Open it from My PDFs and unlock it before sharing."
                        return
                    }
                    // Same deferral as the JPG branch — wait for this options sheet to finish
                    // dismissing before presenting the system share sheet.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        presentShareSheet(items: [url])
                    }
                })
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let doc = viewModel.document {
                DocumentEditOptionsSheet(
                    document: doc,
                    onCompress: { showCompressPopup = true },
                    onSplit: { onSplitPdf(doc) },
                    onRearrange: { onRearrangePdf(doc) },
                    onESign: { onESign(doc) },
                    onAddPassword: { showAddPasswordSheet = true },
                    onOcr: { onOcr(doc) },
                    onSelect: { showEditSheet = false }
                )
            }
        }
        .sheet(isPresented: $showAddPasswordSheet) {
            AddPasswordSheetContent(onDismiss: { showAddPasswordSheet = false }, onAdd: { password in
                showAddPasswordSheet = false
                viewModel.addPassword(password)
            })
            .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $showCompressPopup) {
            if let doc = viewModel.document {
                ZStack {
                    Color.black.opacity(0.45).ignoresSafeArea()
                    CompressPopupCard(document: doc, onDismiss: { showCompressPopup = false }, onSave: { scale, superCompress in
                        showCompressPopup = false
                        viewModel.compressConfirm(scale: scale, superCompress: superCompress)
                    })
                    .padding(.horizontal, 24)
                }
                .presentationBackground(.clear)
            }
        }
        .alert("Rename document", isPresented: $showRenameDialog) {
            TextField("Document name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Save") { viewModel.renameConfirmed(renameText) }
        }
        .alert("Delete document?", isPresented: $showDeleteDialog) {
            Button("No", role: .cancel) {}
            Button("Yes", role: .destructive) {
                viewModel.delete()
                onDeleted()
            }
        } message: {
            Text("This can't be undone.")
        }
        .alert("No documents yet", isPresented: $showEmptyFoldersDialog) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your folders are empty — scan or add a document first.")
        }
        .confirmationDialog("", isPresented: $showActionsMenu, titleVisibility: .hidden) {
            Button("Print") { viewModel.printDocument() }
            Button("Move to Folder") { if let doc = viewModel.document { onMoveToFolder(doc) } }
            Button("Delete File", role: .destructive) { showDeleteDialog = true }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    Button(action: onBack) {
                        Image("back_arrow").resizable().scaledToFit().frame(width: 24, height: 24)
                    }
                    Spacer()
                    HStack(spacing: 16) {
                        Button(action: { showActionsMenu = true }) {
                            Image(systemName: "square.and.arrow.down").font(.system(size: 20)).foregroundColor(.white)
                        }
                        Button(action: { showDeleteDialog = true }) {
                            Image(systemName: "ellipsis").font(.system(size: 20)).foregroundColor(.white)
                        }
                    }
                }
                VStack(spacing: 1) {
                    Text(viewModel.document?.name ?? "Scanning...")
                        .font(Font.custom("Inter", size: 14).weight(.semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text("(Tap to rename)")
                        .font(Font.custom("Inter", size: 12))
                        .foregroundColor(Color(hex: "#8E8E93"))
                }
                .frame(maxWidth: 200)
                .onTapGesture {
                    guard let doc = viewModel.document else { return }
                    renameText = doc.name
                    showRenameDialog = true
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)

            if let doc = viewModel.document {
                metadataRow(doc).padding(.top, 14)
            }
        }
        .padding(.bottom, 16)
        .background(
            Color(hex: "#191C1D")
                .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                .edgesIgnoringSafeArea(.top)
        )
    }

    private func metadataRow(_ doc: ScannedDocument) -> some View {
        HStack(spacing: 24) {
            metaChip(icon: "folder", text: doc.folderName.isEmpty ? unnamedFolderName : doc.folderName)
            metaChip(icon: "doc.text", text: "\(doc.pageCount) Page\(doc.pageCount == 1 ? "" : "s")")
            metaChip(icon: "cylinder", text: formattedFileSize(doc.fileSizeBytes))
        }
    }

    private func metaChip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(.red)
            Text(text).font(Font.custom("Inter", size: 13).weight(.medium)).foregroundColor(.red).lineLimit(1)
        }
    }

    // MARK: - Thumbnail card

    private var thumbnailCard: some View {
        Button(action: { if let doc = viewModel.document { onViewPdf(doc) } }) {
            ZStack(alignment: .bottom) {
                DocumentThumbnailImage(path: viewModel.document?.thumbnailPath ?? "")
                if let doc = viewModel.document {
                    Text("\(doc.pageCount) page\(doc.pageCount == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.black.opacity(0.65))
                    if doc.isPasswordProtected {
                        VStack {
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle().fill(Color.white).frame(width: 22, height: 22)
                                    Image(systemName: "lock.fill").font(.system(size: 10)).foregroundColor(.red)
                                }
                                .padding(6)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .frame(width: 168, height: 256)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#E5E5EA"), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Related documents ("versions of this scan")

    private var relatedDocumentsSection: some View {
        Group {
            if viewModel.relatedDocuments.count > 1 {
                VStack(alignment: .leading, spacing: 10) {
                    Divider().padding(.horizontal, 16)
                    HStack(spacing: 6) {
                        Text("Versions of this scan")
                            .font(Font.custom("Inter", size: 15).weight(.bold))
                            .foregroundColor(Color(hex: "#1A1A1A"))
                        Text("\(viewModel.relatedDocuments.count)")
                            .font(Font.custom("Inter", size: 12).weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 16)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.relatedDocuments) { doc in
                                relatedDocumentCard(doc)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 20)
            }
        }
    }

    private func relatedDocumentCard(_ doc: ScannedDocument) -> some View {
        let isSelected = doc.id == viewModel.document?.id
        return Button(action: { selectRelated(doc) }) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    DocumentThumbnailImage(path: doc.thumbnailPath)
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color.red : Color(hex: "#E5E5EA"), lineWidth: isSelected ? 2 : 1))
                    if doc.isPasswordProtected {
                        ZStack {
                            Circle().fill(Color.white).frame(width: 16, height: 16)
                            Image(systemName: "lock.fill").font(.system(size: 8)).foregroundColor(.red)
                        }
                        .padding(3)
                    }
                }
                Text(doc.name)
                    .font(Font.custom("Inter", size: 11).weight(isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .red : Color(hex: "#3C3C43"))
                    .lineLimit(1)
            }
            .frame(width: 84)
        }
        .buttonStyle(.plain)
    }

    private func selectRelated(_ doc: ScannedDocument) {
        if doc.isPasswordProtected {
            viewModel.toastMessage = "\"\(doc.name)\" is password protected. Open it from My PDFs to unlock it."
        } else {
            onViewPdf(doc)
        }
    }

    // MARK: - Bottom tab bar

    private var bottomTabBar: some View {
        HStack {
            tabItem(icon: "plus", label: "Add") { showAddSheet = true }
            Spacer()
            tabItem(icon: "square.and.arrow.up", label: "Share") { if viewModel.document != nil { showShareSheet = true } }
            Spacer()
            tabItem(icon: "pencil", label: "Edit") { if viewModel.document != nil { showEditSheet = true } }
            Spacer()
            tabItem(icon: "eye", label: "View PDF") { if let doc = viewModel.document { onViewPdf(doc) } }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .background(Color.white)
        // The Figma bar sits flush against the physical bottom edge with its own 20pt cushion as
        // the only clearance (matches the now-hidden system tab bar's own bottom padding for this
        // screen). Left to respect the safe area, iOS adds its own ~34pt home-indicator inset on
        // top of that 20pt, roughly doubling the intended gap.
        .ignoresSafeArea(edges: .bottom)
    }

    private func tabItem(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 20)).foregroundColor(Color(hex: "#5C5C5C"))
                Text(label).font(Font.custom("Inter", size: 11).weight(.medium)).foregroundColor(Color(hex: "#5C5C5C"))
            }
            .frame(width: 64)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add sheet

    private var addSheetHeight: CGFloat {
        let headerHeight: CGFloat = viewModel.document != nil
            ? SheetLayoutMetrics.headerRowHeight + SheetLayoutMetrics.dividerHeight
            : 0
        return headerHeight + 3 * SheetLayoutMetrics.actionRowHeight
            + SheetLayoutMetrics.bottomSpacer + SheetLayoutMetrics.safetyBuffer
    }

    private var addSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let doc = viewModel.document {
                DocumentSheetHeaderRow(document: doc)
                Divider()
            }
            sheetActionRow(icon: "doc.badge.plus", title: "Scan New page") {
                showAddSheet = false
                if let doc = viewModel.document { onAddMore(doc) }
            }
            sheetActionRow(icon: "doc.badge.plus", title: "Add New PDF") {
                showAddSheet = false
                showPDFPicker = true
            }
            sheetActionRow(icon: "folder", title: "From Folder") {
                showAddSheet = false
                if viewModel.hasAnyDocuments() {
                    onFromFolder()
                } else {
                    showEmptyFoldersDialog = true
                }
            }
            Spacer(minLength: 20)
        }
        .presentationDetents([.height(addSheetHeight)])
    }

    // MARK: - Toast

    private var toastOverlay: some View {
        Group {
            if let message = viewModel.toastMessage {
                ToastView(icon: "checkmark.circle.fill", message: message)
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

// Previews the "just finished scanning" entry path (`session:`). The "opened an already-saved
// document" path (`existingDocumentId:`) reads from DocumentScannerRepository's on-device index,
// which a preview shouldn't seed — that would leave permanent extra entries in the real document
// list on every canvas refresh.
#if DEBUG
#Preview {
    DocumentScannerReviewView(
        session: DocumentScannerPreviewSupport.sampleSession(),
        existingDocumentId: nil,
        unlockedPdfPath: nil,
        onBack: {},
        onDeleted: {},
        onAddMore: { _ in },
        onSplitPdf: { _ in },
        onRearrangePdf: { _ in },
        onESign: { _ in },
        onOcr: { _ in },
        onMoveToFolder: { _ in },
        onViewPdf: { _ in },
        onImportedPdf: { _ in },
        onFromFolder: {}
    )
}
#endif
