import SwiftUI

// MARK: - DocumentScannerSplitView
// Mirrors Android's DocumentScannerSplitScreen.kt — a fixed 2-column checkbox grid, all pages
// start selected ("uncheck what you don't want"), tap anywhere on a card to toggle. Note: the
// Figma reference's banner text ("Long press & drag page to move it") is a leftover copy-paste
// from the Rearrange frame — the real interaction here is select-then-extract, so this uses the
// correct instructional copy instead, per Android's actual (and correct) behavior.

struct DocumentScannerSplitView: View {
    let document: ScannedDocument
    let onBack: () -> Void
    let onSplitComplete: (ScannedDocument) -> Void

    @StateObject private var viewModel = DocumentScannerSplitViewModel()

    private let columns = [GridItem(.flexible(), spacing: 13), GridItem(.flexible(), spacing: 13)]

    var body: some View {
        VStack(spacing: 0) {
            ScannerFlowHeader(title: document.name, subtitle: "(Split PDF)", onBack: onBack)
            banner
            if viewModel.isLoading {
                ProgressView().tint(.red).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { index, image in
                            pageCard(image: image, index: index)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            bottomActions
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .onAppear { viewModel.initDocument(document) }
        .scannerToast($viewModel.toastMessage)
    }

    private var banner: some View {
        Text("Select the pages to include in the split")
            .font(Font.custom("Inter", size: 15).weight(.semibold))
            .foregroundColor(Color(hex: "#2C2205"))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(hex: "#FED166"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(12)
    }

    private func pageCard(image: UIImage, index: Int) -> some View {
        let isSelected = viewModel.selectedIndices.contains(index)
        return Button(action: { viewModel.toggleSelected(index) }) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 0) {
                    Image(uiImage: image).resizable().scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 26)
                        .background(Color(hex: "#B0B0B0"))
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 4).fill(isSelected ? Color.red : Color(hex: "#3A3839"))
                    if isSelected {
                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                    }
                }
                .frame(width: 18, height: 18)
                .padding(12)
            }
            .aspectRatio(172.0 / 244.0, contentMode: .fit)
            .background(Color(hex: "#F6F6F6"))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#D3D3D3"), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
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
                    viewModel.split(document: document, onComplete: onSplitComplete)
                }) {
                    Group {
                        if viewModel.isSplitting {
                            ProgressView().tint(.white)
                        } else {
                            Text("Split").font(Font.custom("Inter", size: 16).weight(.semibold)).foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(viewModel.isSplitting)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
        }
        .background(Color.white)
    }
}

#Preview {
    DocumentScannerSplitView(
        document: DocumentScannerPreviewSupport.sampleDocument(name: "Bank Statement", pageCount: 4),
        onBack: {},
        onSplitComplete: { _ in }
    )
}
