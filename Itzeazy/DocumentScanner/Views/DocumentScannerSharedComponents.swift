import SwiftUI

// MARK: - DocumentScannerSharedComponents
// Small pieces reused verbatim across List/Review/ViewPdf — Android reuses the exact same
// EditOptionsBottomSheet/ShareOptionsBottomSheet/CompressPdfPopup/AddPasswordBottomSheet
// composables from multiple screens, so this file keeps the iOS port equally DRY.

// MARK: - ScannerFlowHeader
// The dark, rounded-bottom-corner header shared by every scanner sub-screen — mirrors Android's
// ScannerFlowTopBar. Back button + optional centered title/subtitle.

struct ScannerFlowHeader: View {
    let title: String
    var subtitle: String? = nil
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image("back_arrow").resizable().scaledToFit().frame(width: 24, height: 24)
            }
            Spacer()
            VStack(spacing: 1) {
                Text(title).font(Font.custom("Inter", size: 16).weight(.semibold)).foregroundColor(.white).lineLimit(1)
                if let subtitle {
                    Text(subtitle).font(Font.custom("Inter", size: 12)).foregroundColor(Color(hex: "#8E8E93"))
                }
            }
            Spacer()
            Color.clear.frame(width: 24, height: 24)
        }
        .padding(.horizontal, 24)
        .frame(height: 56)
        .background(
            Color(hex: "#191C1D")
                .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                .edgesIgnoringSafeArea(.top)
        )
    }
}

// MARK: - Scanner toast overlay (auto-dismissing, matches ToastView's app-wide convention)

struct ScannerToastOverlay: ViewModifier {
    @Binding var message: String?
    var icon: String = "exclamationmark.triangle.fill"

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            Group {
                if let message {
                    ToastView(icon: icon, message: message)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                if self.message == message { self.message = nil }
                            }
                        }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: message)
        }
    }
}

extension View {
    func scannerToast(_ message: Binding<String?>, icon: String = "exclamationmark.triangle.fill") -> some View {
        modifier(ScannerToastOverlay(message: message, icon: icon))
    }
}

// MARK: - DocumentThumbnailImage

struct DocumentThumbnailImage: View {
    let path: String
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color.black
            if let image {
                Image(uiImage: image).resizable().aspectRatio(contentMode: .fill)
            }
        }
        .clipped()
        .onAppear {
            if image == nil { image = UIImage(contentsOfFile: path) }
        }
    }
}

// MARK: - DocumentSheetHeaderRow

struct DocumentSheetHeaderRow: View {
    let document: ScannedDocument

    var body: some View {
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
    }
}

// MARK: - Dynamic sheet height
// A live GeometryReader measurement feeding straight back into `.presentationDetents([.height(
// _))])` on the same view turned out to be an unstable feedback loop in this hierarchy — it kept
// settling on a collapsed, too-small height instead of the true content size. These row-count
// sheets have simple, fixed-height rows, so it's far more reliable to just calculate the height
// directly from known row metrics — still fully dynamic per item count, no runtime measurement,
// no flicker while it settles.
enum SheetLayoutMetrics {
    static let headerRowHeight: CGFloat = 88        // DocumentSheetHeaderRow: 48pt thumbnail + 20pt top/bottom padding
    static let dividerHeight: CGFloat = 1
    static let actionRowHeight: CGFloat = 52         // sheetActionRow's explicit .frame(height:)
    static let gridCardHeight: CGFloat = 90
    static let gridCardSpacing: CGFloat = 12
    static let gridPadding: CGFloat = 32             // DocumentEditOptionsSheet's .padding(16), top + bottom
    static let bottomSpacer: CGFloat = 20            // trailing Spacer(minLength:)
    static let safetyBuffer: CGFloat = 12            // headroom against Dynamic Type / hairline rounding
}

// MARK: - DocumentShareOptionsSheet

struct DocumentShareOptionsSheet: View {
    let document: ScannedDocument
    let onShareJPG: () -> Void
    let onSharePDF: () -> Void

    private var sheetHeight: CGFloat {
        SheetLayoutMetrics.headerRowHeight + SheetLayoutMetrics.dividerHeight
            + 2 * SheetLayoutMetrics.actionRowHeight
            + SheetLayoutMetrics.bottomSpacer + SheetLayoutMetrics.safetyBuffer
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DocumentSheetHeaderRow(document: document)
            Divider()
            sheetActionRow(icon: "photo", title: "Share as JPG", action: onShareJPG)
            sheetActionRow(icon: "doc.richtext", title: "Share as PDF", action: onSharePDF)
            Spacer(minLength: 20)
        }
        .presentationDetents([.height(sheetHeight)])
    }
}

// MARK: - DocumentEditActionCard

struct DocumentEditActionCard {
    let title: String
    let icon: String
    /// True for a named color asset from Assets.xcassets (rendered as-is, its own baked-in
    /// color); false for an SF Symbol fallback (rendered with `.foregroundColor`) — used only
    /// for Split PDF until its `split_pdf` asset is added to the catalog.
    var iconIsAsset: Bool = true
    let action: () -> Void
}

// MARK: - DocumentEditOptionsSheet

struct DocumentEditOptionsSheet: View {
    let document: ScannedDocument
    let onCompress: () -> Void
    let onSplit: () -> Void
    let onRearrange: () -> Void
    let onESign: () -> Void
    let onAddPassword: () -> Void
    let onOcr: () -> Void
    /// Called before any of the above — lets the caller dismiss this sheet first.
    let onSelect: () -> Void

    private var cards: [DocumentEditActionCard] {
        var cards: [DocumentEditActionCard] = [
            DocumentEditActionCard(title: "Compress", icon: "compress_icon", action: onCompress)
        ]
        if document.pageCount > 2 {
            // No `split_pdf` asset in Assets.xcassets yet — falls back to the SF Symbol until
            // it's added, rather than pointing at a catalog entry that doesn't exist.
            cards.append(DocumentEditActionCard(title: "Split PDF", icon: "square.split.2x1", iconIsAsset: false, action: onSplit))
            cards.append(DocumentEditActionCard(title: "Rearrange", icon: "rearrange_icon", action: onRearrange))
        }
        cards.append(DocumentEditActionCard(title: "e-Sign", icon: "e_sign_icon", action: onESign))
        cards.append(DocumentEditActionCard(title: "Add Password", icon: "add_password_icon", action: onAddPassword))
        cards.append(DocumentEditActionCard(title: "OCR", icon: "ocr_icon", action: onOcr))
        return cards
    }

    /// 3 cards per row, matching the LazyVGrid's 3 flexible columns below.
    private var sheetHeight: CGFloat {
        let rows = CGFloat((cards.count + 2) / 3)
        return SheetLayoutMetrics.headerRowHeight + SheetLayoutMetrics.dividerHeight
            + SheetLayoutMetrics.gridPadding
            + rows * SheetLayoutMetrics.gridCardHeight + max(0, rows - 1) * SheetLayoutMetrics.gridCardSpacing
            + SheetLayoutMetrics.bottomSpacer + SheetLayoutMetrics.safetyBuffer
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DocumentSheetHeaderRow(document: document)
            Divider()
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(cards, id: \.title) { card in
                    Button(action: { onSelect(); card.action() }) {
                        VStack(spacing: 10) {
                            Group {
                                if card.iconIsAsset {
                                    Image(card.icon).resizable().scaledToFit()
                                } else {
                                    Image(systemName: card.icon).font(.system(size: 22)).foregroundColor(Color(hex: "#333333"))
                                }
                            }
                            .frame(width: 22, height: 22)
                            Text(card.title).font(Font.custom("Inter", size: 13).weight(.medium)).foregroundColor(Color(hex: "#333333")).multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 90)
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#F0F0F0"), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            Spacer(minLength: 20)
        }
        .presentationDetents([.height(sheetHeight)])
    }
}

@ViewBuilder
func sheetActionRow(icon: String, title: String, destructive: Bool = false, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 17)).foregroundColor(destructive ? .red : Color(hex: "#1C1C1E")).frame(width: 22)
            Text(title).font(Font.custom("Inter", size: 16)).foregroundColor(destructive ? .red : Color(hex: "#1C1C1E"))
            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(height: 52)
    }
    .buttonStyle(.plain)
    Divider().padding(.leading, 56)
}

// MARK: - CompressPopupCard

struct CompressPopupCard: View {
    let document: ScannedDocument
    let onDismiss: () -> Void
    let onSave: (CGFloat, Bool) -> Void

    @State private var sliderValue: Double = 0.85
    @State private var superCompress = false

    private var estimatedBytes: Int64 {
        let effectiveScale = superCompress ? sliderValue * 0.7 : sliderValue
        return max(1, Int64(Double(document.fileSizeBytes) * effectiveScale * effectiveScale))
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(formattedFileSize(estimatedBytes))
                .font(Font.custom("PlusJakartaSans-Bold", size: 28))
                .foregroundColor(Color(hex: "#1A1C1D"))

            Slider(value: $sliderValue, in: 0.3...1.0)
                .tint(Color(hex: "#2B76DC"))

            HStack(spacing: 12) {
                Image(systemName: "wind").font(.system(size: 22)).foregroundColor(Color(hex: "#8E41FA"))
                Text("Super Compress").font(Font.custom("Inter", size: 15).weight(.bold)).foregroundColor(Color(hex: "#1A1C1D"))
                Spacer()
                Toggle("", isOn: $superCompress).labelsHidden().tint(Color(hex: "#8E41FA"))
            }
            .padding(.horizontal, 16)
            .frame(height: 64)
            .background(Color(hex: "#FAF8FF"))
            .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color(hex: "#8E41FA"), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 32))

            HStack(spacing: 12) {
                Button("Cancel", action: onDismiss)
                    .foregroundColor(Color(hex: "#FF5B60"))
                    .frame(maxWidth: .infinity)
                Button(action: { onSave(sliderValue, superCompress) }) {
                    Text("Save").foregroundColor(.white)
                        .frame(width: 170, height: 54)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.2), radius: 30, x: 0, y: 10)
    }
}

// MARK: - AddPasswordSheetContent

struct AddPasswordSheetContent: View {
    let onDismiss: () -> Void
    let onAdd: (String) -> Void

    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var passwordVisible = false
    @State private var confirmVisible = false

    private var isTooShort: Bool { !password.isEmpty && password.count < DocumentScannerConstants.minPasswordLength }
    private var isMismatch: Bool { !confirmPassword.isEmpty && password != confirmPassword }
    private var canSubmit: Bool { password.count >= DocumentScannerConstants.minPasswordLength && password == confirmPassword }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 10) {
                Image(systemName: "lock.fill").foregroundColor(Color(hex: "#1A1A1A"))
                Text("Add Password").font(Font.custom("Inter", size: 20).weight(.semibold)).foregroundColor(Color(hex: "#1A1A1A"))
            }
            Divider()

            passwordField(label: "Password", text: $password, isVisible: $passwordVisible, errorText: isTooShort ? "Password must be at least 6 characters" : nil)
            passwordField(label: "Confirm Password", text: $confirmPassword, isVisible: $confirmVisible, errorText: isMismatch ? "Passwords do not match" : nil)

            HStack(spacing: 12) {
                Button("Cancel", action: onDismiss).foregroundColor(.red)
                Spacer()
                Button(action: { onAdd(password) }) {
                    Text("Add").foregroundColor(.white)
                        .frame(width: 160, height: 48)
                        .background(canSubmit ? Color.red : Color(hex: "#C4C4C6"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canSubmit)
            }
        }
        .padding(20)
    }

    private func passwordField(label: String, text: Binding<String>, isVisible: Binding<Bool>, errorText: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(Font.custom("Inter", size: 13).weight(.medium)).foregroundColor(Color(hex: "#6B7280"))
            HStack {
                Group {
                    if isVisible.wrappedValue { TextField("", text: text) } else { SecureField("", text: text) }
                }
                Button(action: { isVisible.wrappedValue.toggle() }) {
                    Image(systemName: isVisible.wrappedValue ? "eye.slash" : "eye").foregroundColor(Color(hex: "#6B7280"))
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 56)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(errorText != nil ? Color.red : Color(hex: "#E5E5EA"), lineWidth: 1))
            if let errorText {
                Text(errorText).font(Font.custom("Inter", size: 11)).foregroundColor(.red)
            }
        }
    }
}

// MARK: - AddFolderSheetContent

struct AddFolderSheetContent: View {
    let onDismiss: () -> Void
    let onAdd: (String) -> Void

    @State private var name = ""
    private var isValid: Bool { name.trimmingCharacters(in: .whitespaces).count > 6 }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 10) {
                Image(systemName: "folder.badge.plus").foregroundColor(.red)
                Text("Add Folder").font(Font.custom("Inter", size: 22).weight(.bold)).foregroundColor(Color(hex: "#1C1C1E"))
            }
            Divider()
            VStack(alignment: .leading, spacing: 12) {
                Text("Folder Name").font(Font.custom("Inter", size: 16).weight(.semibold)).foregroundColor(Color(hex: "#1C1C1E"))
                TextField("Type the folder name", text: $name)
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#E5E5EA"), lineWidth: 1))
            }
            HStack {
                Button("Cancel", action: onDismiss).foregroundColor(.red)
                Spacer()
                Button(action: { onAdd(name) }) {
                    Text("Add Folder").foregroundColor(.white)
                        .padding(.horizontal, 40).padding(.vertical, 12)
                        .background(isValid ? Color.red : Color(hex: "#C4C4C7"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isValid)
            }
        }
        .padding(20)
    }
}

// MARK: - formattedFileSize

func formattedFileSize(_ bytes: Int64) -> String {
    let kb = Double(bytes) / 1024.0
    if kb < 1024 { return String(format: "%.0f KB", kb) }
    return String(format: "%.2f MB", kb / 1024.0)
}

// MARK: - Previews

#Preview("ScannerFlowHeader") {
    VStack(spacing: 0) {
        ScannerFlowHeader(title: "Split PDF", subtitle: "3 pages selected", onBack: {})
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("DocumentShareOptionsSheet") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            DocumentShareOptionsSheet(
                document: DocumentScannerPreviewSupport.sampleDocument(),
                onShareJPG: {},
                onSharePDF: {}
            )
        }
}

#Preview("DocumentEditOptionsSheet") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            DocumentEditOptionsSheet(
                document: DocumentScannerPreviewSupport.sampleDocument(pageCount: 3),
                onCompress: {}, onSplit: {}, onRearrange: {}, onESign: {},
                onAddPassword: {}, onOcr: {}, onSelect: {}
            )
        }
}

#Preview("CompressPopupCard") {
    ZStack {
        Color.black.opacity(0.4).ignoresSafeArea()
        CompressPopupCard(document: DocumentScannerPreviewSupport.sampleDocument(), onDismiss: {}, onSave: { _, _ in })
            .padding(24)
    }
}

#Preview("AddPasswordSheetContent") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            AddPasswordSheetContent(onDismiss: {}, onAdd: { _ in })
        }
}

#Preview("AddFolderSheetContent") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            AddFolderSheetContent(onDismiss: {}, onAdd: { _ in })
        }
}
