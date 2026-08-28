import SwiftUI

// MARK: - CardFramesKey
// Tracks every visible card's current frame (in the grid's own coordinate space) so a drag can
// hit-test which card is currently under the dragged card's center.

private struct CardFramesKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

// MARK: - DocumentScannerRearrangeView
// Mirrors Android's DocumentScannerRearrangeScreen.kt — long-press-then-drag reordering on a
// fixed 2-column grid. The reorder itself is screen-local (`order`) until the "Rearrange" button
// commits it; Cancel is always free since nothing is persisted mid-drag.
//
// Porting note: Android's Compose implementation had to manually rebase the drag offset onto each
// target slot's center after every cascade move, since Compose's DragGesture only reports
// per-event incremental deltas. SwiftUI's DragGesture reports the finger's *absolute* location
// within a named coordinate space directly, which simplifies the same "keep tracking the finger
// smoothly across a cascade of moves" requirement to one offset recomputation per event, using the
// dragged card's currently-believed rest frame as the baseline (rebased at each move).

struct DocumentScannerRearrangeView: View {
    let document: ScannedDocument
    let onBack: () -> Void
    let onRearrangeComplete: (ScannedDocument) -> Void

    @StateObject private var viewModel = DocumentScannerRearrangeViewModel()

    @State private var order: [Int] = []
    @State private var draggingOriginalIndex: Int?
    @State private var draggingOriginFrame: CGRect = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var cardFrames: [Int: CGRect] = [:]

    private let columns = [GridItem(.flexible(), spacing: 13), GridItem(.flexible(), spacing: 13)]

    var body: some View {
        VStack(spacing: 0) {
            ScannerFlowHeader(title: document.name, subtitle: "(Rearrange PDF)", onBack: onBack)
            banner
            if viewModel.isLoading {
                ProgressView().tint(.red).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(order, id: \.self) { originalIndex in
                            card(for: originalIndex)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                .coordinateSpace(name: "rearrangeGrid")
                .onPreferenceChange(CardFramesKey.self) { cardFrames = $0 }
            }
            bottomActions
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .onAppear { viewModel.initDocument(document) }
        .onChange(of: viewModel.pages.count) { _, newCount in
            if newCount > 0 && order.isEmpty { order = Array(0..<newCount) }
        }
        .scannerToast($viewModel.toastMessage)
    }

    private var banner: some View {
        Text("Long press & drag page to move it")
            .font(Font.custom("Inter", size: 15).weight(.semibold))
            .foregroundColor(Color(hex: "#2C2205"))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(hex: "#FED166"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(12)
    }

    // MARK: - Card

    private func displayPosition(of originalIndex: Int) -> Int {
        order.firstIndex(of: originalIndex) ?? 0
    }

    private func card(for originalIndex: Int) -> some View {
        let isDragging = draggingOriginalIndex == originalIndex
        return VStack(spacing: 0) {
            Image(uiImage: viewModel.pages[originalIndex]).resizable().scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            Text("\(displayPosition(of: originalIndex) + 1)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 26)
                .background(Color(hex: "#B0B0B0"))
        }
        .aspectRatio(172.0 / 244.0, contentMode: .fit)
        .background(Color(hex: "#F6F6F6"))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#D3D3D3"), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: CardFramesKey.self, value: [originalIndex: geo.frame(in: .named("rearrangeGrid"))])
            }
        )
        .scaleEffect(isDragging ? 1.04 : 1.0)
        .shadow(color: isDragging ? Color.black.opacity(0.25) : .clear, radius: isDragging ? 16 : 0)
        .zIndex(isDragging ? 1 : 0)
        .offset(isDragging ? dragOffset : .zero)
        .gesture(
            LongPressGesture(minimumDuration: 0.3)
                .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named("rearrangeGrid")))
                .onChanged { value in
                    if case .second(true, let drag) = value, let drag {
                        handleDragChanged(originalIndex: originalIndex, location: drag.location)
                    }
                }
                .onEnded { _ in
                    draggingOriginalIndex = nil
                    dragOffset = .zero
                }
        )
    }

    private func handleDragChanged(originalIndex: Int, location: CGPoint) {
        if draggingOriginalIndex == nil {
            draggingOriginalIndex = originalIndex
            draggingOriginFrame = cardFrames[originalIndex] ?? .zero
        }
        guard draggingOriginalIndex == originalIndex else { return }

        dragOffset = CGSize(width: location.x - draggingOriginFrame.midX, height: location.y - draggingOriginFrame.midY)

        guard let targetOriginalIndex = cardFrames.first(where: { key, frame in key != originalIndex && frame.contains(location) })?.key else { return }
        guard let fromPos = order.firstIndex(of: originalIndex), let toPos = order.firstIndex(of: targetOriginalIndex), fromPos != toPos else { return }

        let newSlotFrame = cardFrames[targetOriginalIndex] ?? draggingOriginFrame
        withAnimation(.spring(response: 0.35, dampingFraction: 1)) {
            let destination = toPos > fromPos ? toPos + 1 : toPos
            order.move(fromOffsets: IndexSet(integer: fromPos), toOffset: destination)
        }
        draggingOriginFrame = newSlotFrame
        dragOffset = CGSize(width: location.x - newSlotFrame.midX, height: location.y - newSlotFrame.midY)
    }

    // MARK: - Bottom actions

    private var bottomActions: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Text("Cancel").font(Font.custom("Inter", size: 16).weight(.semibold)).foregroundColor(.red)
                        .frame(maxWidth: .infinity).frame(height: 50)
                }
                Button(action: {
                    viewModel.rearrange(document: document, newOrder: order, onComplete: onRearrangeComplete)
                }) {
                    Group {
                        if viewModel.isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Rearrange").font(Font.custom("Inter", size: 16).weight(.semibold)).foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(viewModel.isSaving)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
        }
        .background(Color.white)
    }
}

#Preview {
    DocumentScannerRearrangeView(
        document: DocumentScannerPreviewSupport.sampleDocument(name: "Insurance Policy", pageCount: 4),
        onBack: {},
        onRearrangeComplete: { _ in }
    )
}
