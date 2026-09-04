import SwiftUI

// MARK: - DocumentScannerMoveToFolderView
// Mirrors Android's DocumentScannerMoveToFolderScreen.kt — full-screen folder picker. Pre-selects
// the document's current folder; "Move here" commits immediately (no confirmation dialog).
// Creating a folder mid-move also immediately selects it — the whole reason to add one here is to
// file this document into it, unlike the List screen's own Add Folder flow which has no
// "selection" concept.

struct DocumentScannerMoveToFolderView: View {
    let document: ScannedDocument
    let onBack: () -> Void
    let onMoved: () -> Void

    @StateObject private var viewModel = DocumentScannerListViewModel()
    @State private var selectedFolderName: String
    @State private var showAddFolderSheet = false

    init(document: ScannedDocument, onBack: @escaping () -> Void, onMoved: @escaping () -> Void) {
        self.document = document
        self.onBack = onBack
        self.onMoved = onMoved
        _selectedFolderName = State(initialValue: document.folderName)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScannerFlowHeader(title: "Move to Folder", onBack: onBack)
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.folders) { folder in
                            folderRow(folder)
                        }
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                }
                fab
            }
            bottomActions
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .onAppear { viewModel.refresh() }
        .scannerToast($viewModel.toastMessage, icon: "checkmark.circle.fill")
        .sheet(isPresented: $showAddFolderSheet) {
            AddFolderSheetContent(onDismiss: { showAddFolderSheet = false }, onAdd: { name in
                showAddFolderSheet = false
                viewModel.addFolder(name: name)
                selectedFolderName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            })
            .presentationDetents([.medium])
        }
    }

    private func folderRow(_ folder: DocumentFolder) -> some View {
        let count = viewModel.documents.filter { $0.folderName == folder.name }.count
        let isSelected = selectedFolderName == folder.name
        return VStack(spacing: 0) {
            Button(action: { selectedFolderName = folder.name }) {
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
                    Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .red : Color(hex: "#C4C4C6"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .buttonStyle(.plain)
            Divider()
        }
    }

    private var fab: some View {
        Button(action: { showAddFolderSheet = true }) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 22))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color(hex: "#191C1D"))
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }

    private var bottomActions: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Text("Cancel").font(Font.custom("Inter", size: 16).weight(.semibold)).foregroundColor(.red)
                        .frame(maxWidth: .infinity).frame(height: 50)
                }
                Button(action: {
                    viewModel.moveDocument(document, toFolder: selectedFolderName)
                    onMoved()
                }) {
                    Text("Move here").foregroundColor(.white)
                        .frame(width: 170, height: 54)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
        }
        .background(Color.white)
    }
}

#if DEBUG
#Preview {
    DocumentScannerMoveToFolderView(
        document: DocumentScannerPreviewSupport.sampleDocument(withRealFiles: false),
        onBack: {},
        onMoved: {}
    )
}
#endif
