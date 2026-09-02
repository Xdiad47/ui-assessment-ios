import SwiftUI

// MARK: - DocumentScannerListTab

enum DocumentScannerListTab: Equatable {
    case myPDFs
    case myFolders
}

// MARK: - DocumentScannerListView
// Mirrors Android's DocumentScannerScreen.kt — My PDFs / My Folders tabs, a document grid/list,
// folder CRUD, a per-document 3-dot menu, and an Add-Folder flow. Folder "drill-in" is not a
// separate screen — tapping a folder switches to My PDFs filtered by that folder's name, same as
// Android. Each sheet/dialog target is its own independent @State (not one shared enum) so that
// dismissing one sheet immediately after tapping a row inside it can't clobber the document
// reference the next sheet/dialog needs — mirrors an explicit design comment in the Android source.

struct DocumentScannerListView: View {
    let startOnFoldersTab: Bool
    let onStartScan: () -> Void
    let onOpenDocument: (ScannedDocument, String?) -> Void
    let onSplitPdf: (ScannedDocument) -> Void
    let onRearrangePdf: (ScannedDocument) -> Void
    let onESign: (ScannedDocument) -> Void
    let onOcr: (ScannedDocument) -> Void
    let onMoveToFolder: (ScannedDocument) -> Void
    let onBack: () -> Void

    @StateObject private var viewModel = DocumentScannerListViewModel()

    @State private var selectedTab: DocumentScannerListTab
    @State private var folderFilter: String?

    @State private var actionsSheetDocument: ScannedDocument?
    @State private var shareSheetDocument: ScannedDocument?
    @State private var editSheetDocument: ScannedDocument?
    @State private var compressPopupDocument: ScannedDocument?
    @State private var addPasswordSheetDocument: ScannedDocument?
    @State private var renameDocumentTarget: ScannedDocument?
    @State private var renameDocumentText = ""
    @State private var deleteDocumentTarget: ScannedDocument?
    @State private var passwordPromptDocument: ScannedDocument?
    @State private var passwordPromptText = ""
    @State private var isVerifyingPassword = false
    @State private var passwordError = false

    @State private var showAddFolderSheet = false
    @State private var newFolderName = ""
    @State private var folderMenuTarget: DocumentFolder?
    @State private var renameFolderTarget: DocumentFolder?
    @State private var renameFolderText = ""
    @State private var deleteFolderTarget: DocumentFolder?


    init(
        startOnFoldersTab: Bool,
        onStartScan: @escaping () -> Void,
        onOpenDocument: @escaping (ScannedDocument, String?) -> Void,
        onSplitPdf: @escaping (ScannedDocument) -> Void,
        onRearrangePdf: @escaping (ScannedDocument) -> Void,
        onESign: @escaping (ScannedDocument) -> Void,
        onOcr: @escaping (ScannedDocument) -> Void,
        onMoveToFolder: @escaping (ScannedDocument) -> Void,
        onBack: @escaping () -> Void
    ) {
        self.startOnFoldersTab = startOnFoldersTab
        self.onStartScan = onStartScan
        self.onOpenDocument = onOpenDocument
        self.onSplitPdf = onSplitPdf
        self.onRearrangePdf = onRearrangePdf
        self.onESign = onESign
        self.onOcr = onOcr
        self.onMoveToFolder = onMoveToFolder
        self.onBack = onBack
        _selectedTab = State(initialValue: startOnFoldersTab ? .myFolders : .myPDFs)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ZStack(alignment: .bottomTrailing) {
                Color(hex: "#EEEEF0").ignoresSafeArea()
                switch selectedTab {
                case .myPDFs: myPDFsContent
                case .myFolders: myFoldersContent
                }
                // The empty "My PDFs" state already has its own full-width Start Scan button
                // (matches the Figma empty state, which shows no floating action button).
                if !(selectedTab == .myPDFs && viewModel.documents.isEmpty) {
                    fab
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { viewModel.refresh() }
        .overlay(alignment: .bottom) { toastOverlay }
        // MARK: Document sheets/dialogs
        .sheet(item: $actionsSheetDocument) { doc in documentActionsSheet(doc) }
        .sheet(item: $shareSheetDocument) { doc in shareOptionsSheet(doc) }
        .sheet(item: $editSheetDocument) { doc in editOptionsSheet(doc) }
        .sheet(item: $addPasswordSheetDocument) { doc in addPasswordSheet(doc) }
        .sheet(isPresented: $showAddFolderSheet) { addFolderSheet }
        .fullScreenCover(item: $compressPopupDocument) { doc in
            compressPopup(doc).presentationBackground(.clear)
        }
        .fullScreenCover(item: $passwordPromptDocument) { doc in
            passwordUnlockDialog(doc).presentationBackground(.clear)
        }
        .alert("Rename document", isPresented: renameDocumentBinding) {
            TextField("Document name", text: $renameDocumentText)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                if let doc = renameDocumentTarget { viewModel.renameDocument(id: doc.id, newName: renameDocumentText) }
            }
        }
        .alert("Delete document?", isPresented: Binding(get: { deleteDocumentTarget != nil }, set: { if !$0 { deleteDocumentTarget = nil } })) {
            Button("No", role: .cancel) {}
            Button("Yes", role: .destructive) {
                if let doc = deleteDocumentTarget { viewModel.deleteDocument(id: doc.id) }
            }
        } message: {
            Text("This can't be undone.")
        }
        .alert("Rename folder", isPresented: renameFolderBinding) {
            TextField("Folder name", text: $renameFolderText)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                if let folder = renameFolderTarget { viewModel.renameFolder(id: folder.id, newName: renameFolderText) }
            }
        }
        .alert("Delete Folder?", isPresented: Binding(get: { deleteFolderTarget != nil }, set: { if !$0 { deleteFolderTarget = nil } })) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let folder = deleteFolderTarget { viewModel.deleteFolder(id: folder.id) }
            }
        } message: {
            Text("This can't be undone. Documents inside will move to Unnamed Folder.")
        }
        .confirmationDialog(folderMenuTarget?.name ?? "", isPresented: Binding(get: { folderMenuTarget != nil }, set: { if !$0 { folderMenuTarget = nil } }), titleVisibility: .visible) {
            Button("Rename") {
                if let folder = folderMenuTarget { renameFolderText = folder.name; renameFolderTarget = folder }
            }
            Button("Delete", role: .destructive) {
                if let folder = folderMenuTarget { deleteFolderTarget = folder }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var renameDocumentBinding: Binding<Bool> {
        Binding(get: { renameDocumentTarget != nil }, set: { if !$0 { renameDocumentTarget = nil } })
    }
    private var renameFolderBinding: Binding<Bool> {
        Binding(get: { renameFolderTarget != nil }, set: { if !$0 { renameFolderTarget = nil } })
    }

    // MARK: - Header

    // The tab track lives inside the same dark card as the back button/title (its second row),
    // not as a separate element below it — matches the Figma header, which wraps both in one
    // rounded-bottom-corner "Header - Top Navigation Shell" container.
    private var header: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Image("back_arrow").resizable().scaledToFit().frame(width: 24, height: 24)
                }
                Text("Document Scanner")
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                    .kerning(-0.9)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)

            tabTrack
                .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .background(
            Color(hex: "#191C1D")
                .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                .edgesIgnoringSafeArea(.top)
        )
        .shadow(color: Color(hex: "#191C1D").opacity(0.04), radius: 8, x: 0, y: 8)
    }

    private var tabTrack: some View {
        HStack(spacing: 0) {
            tabButton(title: "My PDFs", isActive: selectedTab == .myPDFs) {
                selectedTab = .myPDFs
            }
            tabButton(title: "My Folders", isActive: selectedTab == .myFolders) {
                selectedTab = .myFolders
                folderFilter = nil
            }
        }
        .padding(3)
        .background(Color(hex: "#F2F2F7"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func tabButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Font.custom("Inter", size: 14).weight(.semibold))
                .foregroundColor(isActive ? .white : Color(hex: "#6E6E73"))
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(isActive ? Color.red : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }

    // MARK: - My PDFs tab

    private var filteredDocuments: [ScannedDocument] {
        guard let folderFilter else { return viewModel.documents }
        return viewModel.documents.filter { $0.folderName == folderFilter }
    }

    private var myPDFsContent: some View {
        Group {
            if viewModel.documents.isEmpty {
                emptyPDFsState
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        if let folderFilter {
                            folderFilterChip(folderFilter)
                        }
                        ForEach(filteredDocuments) { doc in
                            DocumentRowView(document: doc, onTap: { openDocument(doc) }, onMenu: { actionsSheetDocument = doc })
                        }
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private func folderFilterChip(_ name: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "folder.fill").font(.system(size: 12)).foregroundColor(.red)
            Text(name).font(Font.custom("Inter", size: 13).weight(.medium)).foregroundColor(.red)
            Image(systemName: "xmark").font(.system(size: 10, weight: .bold)).foregroundColor(.red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(hex: "#FFDAD6"))
        .clipShape(Capsule())
        .padding(.vertical, 8)
        .onTapGesture { folderFilter = nil }
    }

    private var emptyPDFsState: some View {
        VStack(spacing: 28) {
            Image("scanner_empty_hero").resizable().scaledToFit().frame(width: 255, height: 191)
            Text("Fast, secure document scanning.")
                .font(Font.custom("Inter", size: 22).weight(.heavy))
                .foregroundColor(Color(hex: "#111111"))
                .multilineTextAlignment(.center)
            Button(action: onStartScan) {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                    Text("Start Scan").font(Font.custom("Inter", size: 16).weight(.bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color(red: 0.898, green: 0.145, blue: 0.129, opacity: 0.2), radius: 6, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    // MARK: - My Folders tab

    private var myFoldersContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(viewModel.folders) { folder in
                    FolderRowView(
                        folder: folder,
                        count: viewModel.documents.filter { $0.folderName == folder.name }.count,
                        onTap: {
                            folderFilter = folder.name
                            selectedTab = .myPDFs
                        },
                        trailing: AnyView(
                            Button(action: { folderMenuTarget = folder }) {
                                Image(systemName: "ellipsis").font(.system(size: 18)).foregroundColor(Color(hex: "#6E6E73"))
                            }
                        )
                    )
                }
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - FAB

    private var fab: some View {
        Button(action: {
            switch selectedTab {
            case .myPDFs: onStartScan()
            case .myFolders: showAddFolderSheet = true
            }
        }) {
            Image(systemName: selectedTab == .myPDFs ? "camera.fill" : "folder.badge.plus")
                .font(.system(size: 22))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(selectedTab == .myPDFs ? Color.red : Color(hex: "#191C1D"))
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 4)
        }
        .padding(.trailing, 20)
        // This view respects the safe area (only the header ignores it), but MainTabView's
        // CustomTabBar ignores the safe area and pins itself flush to the physical bottom edge —
        // so a padding value here already sits above the safe-area boundary before it's added.
        // 60pt lands the FAB a clean ~16-20pt above the ~77pt-tall tab bar instead of the ~57pt
        // gap the two mismatched safe-area treatments produced before.
        .padding(.bottom, 60)
    }

    // MARK: - Open document (password-gated)

    private func openDocument(_ document: ScannedDocument) {
        if document.isPasswordProtected {
            passwordError = false
            passwordPromptText = ""
            passwordPromptDocument = document
        } else {
            onOpenDocument(document, nil)
        }
    }

    // MARK: - Toast

    private var toastOverlay: some View {
        Group {
            if let message = viewModel.toastMessage {
                ToastView(icon: "checkmark.circle.fill", message: message)
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            if viewModel.toastMessage == message { viewModel.toastMessage = nil }
                        }
                    }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.toastMessage)
    }

    // MARK: - Password unlock dialog

    private func passwordUnlockDialog(_ document: ScannedDocument) -> some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(Color(hex: "#FFDAD6")).frame(width: 56, height: 56)
                    Image(systemName: "lock.fill").font(.system(size: 22)).foregroundColor(.red)
                }
                Text("Enter Password").font(Font.custom("PlusJakartaSans-SemiBold", size: 18)).foregroundColor(Color(hex: "#1A1C1D"))
                Text("\"\(document.name)\" is password protected.")
                    .font(Font.custom("Inter", size: 13)).foregroundColor(Color(hex: "#6E6E73"))
                    .multilineTextAlignment(.center)

                SecureField("Password", text: $passwordPromptText)
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .background(Color(hex: "#F5F5F7"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                if passwordError {
                    Text("Incorrect password").font(Font.custom("Inter", size: 12)).foregroundColor(.red)
                }

                HStack(spacing: 12) {
                    Button(action: { passwordPromptDocument = nil }) {
                        Text("Cancel").foregroundColor(Color(hex: "#1A1C1D"))
                            .frame(maxWidth: .infinity).frame(height: 46)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#E2E2E4"), lineWidth: 1))
                    }
                    Button(action: submitPasswordUnlock) {
                        Text(isVerifyingPassword ? "Checking..." : "Unlock").foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 46)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(passwordPromptText.isEmpty || isVerifyingPassword)
                    .opacity(passwordPromptText.isEmpty || isVerifyingPassword ? 0.5 : 1)
                }
            }
            .padding(24)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.2), radius: 30, x: 0, y: 10)
            .padding(.horizontal, 32)
        }
    }

    private func submitPasswordUnlock() {
        guard let document = passwordPromptDocument else { return }
        isVerifyingPassword = true
        passwordError = false
        viewModel.verifyPassword(document: document, password: passwordPromptText) { unlockedPath in
            isVerifyingPassword = false
            if let unlockedPath {
                let doc = document
                passwordPromptDocument = nil
                onOpenDocument(doc, unlockedPath)
            } else {
                passwordError = true
            }
        }
    }

    // MARK: - Document actions sheet (3-dot menu)

    private func documentActionsSheet(_ document: ScannedDocument) -> some View {
        // Wrapped in a ScrollView: the header row + 8 action rows are taller than the .medium
        // detent, and an un-scrollable VStack inside a sheet clips overflow from the *top*
        // (the sheet's fixed-height frame anchors to its bottom), hiding the document identity
        // row instead of just letting the user scroll to see everything.
        ScrollView {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                DocumentThumbnailImage(path: document.thumbnailPath).frame(width: 48, height: 48).clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text(document.name).font(Font.custom("Inter", size: 15).weight(.semibold)).foregroundColor(Color(hex: "#1E1E1E"))
                    Text("\(document.pageCount) Page(s) • (\(formattedFileSize(document.fileSizeBytes)))")
                        .font(Font.custom("Inter", size: 13)).foregroundColor(Color(hex: "#616161"))
                }
                Spacer()
            }
            .padding(20)
            Divider()
            actionRow(icon: "square.and.arrow.up", title: "Share Document", chevron: true) {
                actionsSheetDocument = nil
                shareSheetDocument = document
            }
            actionRow(icon: "doc.richtext", title: "Save as PDF") {
                actionsSheetDocument = nil
                // A password-protected document accessed straight from this 3-dot menu was never
                // decrypted — document.pdfPath is still the encrypted original here. Handing that
                // straight to UIActivityViewController makes it come up with the app's own icon as
                // a generic fallback and no usable destinations, since most built-in share targets
                // can't preview content they can't decrypt. Block it with a clear message instead.
                let url = URL(fileURLWithPath: document.pdfPath)
                guard !DocumentScannerPDFService.isEncrypted(url: url) else {
                    viewModel.toastMessage = "This document is password protected. Open it and unlock it before sharing."
                    return
                }
                // Deferred: the 3-dot actions sheet is still animating out, and presenting the
                // system share sheet on a controller mid-dismissal silently does nothing.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    presentShareSheet(items: [url])
                }
            }
            actionRow(icon: "photo", title: "Save as Image") {
                actionsSheetDocument = nil
                viewModel.shareAsJPG(document: document) { urls in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        presentShareSheet(items: urls)
                    }
                }
            }
            actionRow(icon: "pencil", title: "Rename") {
                actionsSheetDocument = nil
                renameDocumentText = document.name
                renameDocumentTarget = document
            }
            actionRow(icon: "folder", title: "Move to Folder", chevron: true) {
                actionsSheetDocument = nil
                onMoveToFolder(document)
            }
            actionRow(icon: "arrow.down.right.and.arrow.up.left", title: "Compress", chevron: true) {
                actionsSheetDocument = nil
                compressPopupDocument = document
            }
            actionRow(icon: "slider.horizontal.3", title: "Edit", chevron: true) {
                actionsSheetDocument = nil
                editSheetDocument = document
            }
            actionRow(icon: "trash", title: "Delete File", destructive: true) {
                actionsSheetDocument = nil
                deleteDocumentTarget = document
            }
            Spacer(minLength: 20)
        }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func actionRow(icon: String, title: String, chevron: Bool = false, destructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 17)).foregroundColor(destructive ? .red : Color(hex: "#1C1C1E")).frame(width: 22)
                Text(title).font(Font.custom("Inter", size: 16)).foregroundColor(destructive ? .red : Color(hex: "#1C1C1E"))
                Spacer()
                if chevron { Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(Color(hex: "#B0B0B0")) }
            }
            .padding(.horizontal, 20)
            .frame(height: 52)
        }
        .buttonStyle(.plain)
        Divider().padding(.leading, 56)
    }

    // MARK: - Share options sheet

    private func shareOptionsSheet(_ document: ScannedDocument) -> some View {
        DocumentShareOptionsSheet(
            document: document,
            onShareJPG: {
                shareSheetDocument = nil
                viewModel.shareAsJPG(document: document) { urls in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        presentShareSheet(items: urls)
                    }
                }
            },
            onSharePDF: {
                shareSheetDocument = nil
                // Same guard as "Save as PDF" above — document.pdfPath is the encrypted original
                // for a protected document opened straight from this menu, and PDFKit-based share
                // targets exclude themselves from a file they can't decrypt.
                let url = URL(fileURLWithPath: document.pdfPath)
                guard !DocumentScannerPDFService.isEncrypted(url: url) else {
                    viewModel.toastMessage = "This document is password protected. Open it and unlock it before sharing."
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    presentShareSheet(items: [url])
                }
            }
        )
    }

    // MARK: - Edit options sheet

    private func editOptionsSheet(_ document: ScannedDocument) -> some View {
        DocumentEditOptionsSheet(
            document: document,
            onCompress: { compressPopupDocument = document },
            onSplit: { onSplitPdf(document) },
            onRearrange: { onRearrangePdf(document) },
            onESign: { onESign(document) },
            onAddPassword: { addPasswordSheetDocument = document },
            onOcr: { onOcr(document) },
            onSelect: { editSheetDocument = nil }
        )
    }

    // MARK: - Compress popup

    private func compressPopup(_ document: ScannedDocument) -> some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            CompressPopupCard(document: document, onDismiss: { compressPopupDocument = nil }, onSave: { scale, superCompress in
                compressPopupDocument = nil
                viewModel.compress(document: document, scale: scale, superCompress: superCompress)
            })
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Add Password sheet

    private func addPasswordSheet(_ document: ScannedDocument) -> some View {
        AddPasswordSheetContent(onDismiss: { addPasswordSheetDocument = nil }, onAdd: { password in
            addPasswordSheetDocument = nil
            viewModel.addPassword(document: document, password: password)
        })
        .presentationDetents([.medium])
    }

    // MARK: - Add Folder sheet

    private var addFolderSheet: some View {
        AddFolderSheetContent(onDismiss: {
            showAddFolderSheet = false
        }, onAdd: { name in
            showAddFolderSheet = false
            viewModel.addFolder(name: name)
        })
        .presentationDetents([.medium])
    }
}

// MARK: - DocumentRowView

private struct DocumentRowView: View {
    let document: ScannedDocument
    let onTap: () -> Void
    let onMenu: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    DocumentThumbnailImage(path: document.thumbnailPath)
                        .frame(width: 60, height: 76)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    if document.isPasswordProtected {
                        ZStack {
                            Circle().fill(Color.white).frame(width: 18, height: 18)
                            Image(systemName: "lock.fill").font(.system(size: 9)).foregroundColor(.red)
                        }
                        .padding(4)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.name)
                        .font(Font.custom("Inter", size: 15).weight(.semibold))
                        .foregroundColor(Color(hex: "#1A1A1A"))
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill").font(.system(size: 11)).foregroundColor(Color(hex: "#9A9A9A"))
                        Text(document.folderName.isEmpty ? unnamedFolderName : document.folderName)
                            .font(Font.custom("Inter", size: 12)).foregroundColor(Color(hex: "#6E6E73"))
                    }
                    Text(formattedDate(document.createdAtMillis))
                        .font(Font.custom("Inter", size: 11)).foregroundColor(Color(hex: "#9A9A9A"))
                }
                Spacer()
                Button(action: onMenu) {
                    Image(systemName: "ellipsis").font(.system(size: 18)).foregroundColor(Color(hex: "#6E6E73")).frame(width: 32, height: 32)
                }
            }
            .padding(12)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#E5E5EA"), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .padding(.vertical, 6)
    }

    private func formattedDate(_ millis: Int64) -> String {
        let date = Date(timeIntervalSince1970: Double(millis) / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yy"
        return formatter.string(from: date)
    }
}

// MARK: - FolderRowView

private struct FolderRowView: View {
    let folder: DocumentFolder
    let count: Int
    let onTap: () -> Void
    let trailing: AnyView

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 16) {
                    Image(systemName: folder.id == unnamedFolderId ? "xmark.circle" : "folder")
                        .font(.system(size: 20))
                        .foregroundColor(folder.id == unnamedFolderId ? .blue : Color(hex: "#1A1A1A"))
                        .frame(width: 24, height: 24)
                    Text(folder.name)
                        .font(Font.custom("Inter", size: 16).weight(.semibold))
                        .foregroundColor(Color(hex: "#1A1A1A"))
                    Spacer()
                    Text("\(count)")
                        .font(Font.custom("Inter", size: 12).weight(.semibold))
                        .foregroundColor(Color(hex: "#555555"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#F1F1F3"))
                        .clipShape(Capsule())
                    trailing
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .buttonStyle(.plain)
            Divider()
        }
    }
}

#Preview {
    DocumentScannerListView(
        startOnFoldersTab: false,
        onStartScan: {},
        onOpenDocument: { _, _ in },
        onSplitPdf: { _ in },
        onRearrangePdf: { _ in },
        onESign: { _ in },
        onOcr: { _ in },
        onMoveToFolder: { _ in },
        onBack: {}
    )
}

#Preview("Folders tab") {
    DocumentScannerListView(
        startOnFoldersTab: true,
        onStartScan: {},
        onOpenDocument: { _, _ in },
        onSplitPdf: { _ in },
        onRearrangePdf: { _ in },
        onESign: { _ in },
        onOcr: { _ in },
        onMoveToFolder: { _ in },
        onBack: {}
    )
}
