import SwiftUI
import UIKit
import PhotosUI

// MARK: - DocumentScannerESignView
// Mirrors Android's DocumentScannerESignScreen.kt — two modes on one screen (SELECT / DRAW), no
// nav-graph hop between them so page/signature state survives the round trip. A signature is
// either hand-drawn (Create) or an existing image (Upload) — no camera capture (a signature is
// something you draw, not photograph) and no typed/font option. Placement is drag-to-move +
// a single bottom-right resize handle (no rotation, no aspect lock, no pinch), in fraction (0-1)
// coordinates relative to a container deliberately sized to the page's own aspect ratio first
// (computed directly here, not inferred from an oversized GeometryReader) so there's no letterbox
// slack in the fraction math — see fittedSize(aspect:in:) below.

struct DocumentScannerESignView: View {
    let document: ScannedDocument
    let onBack: () -> Void
    let onSaveComplete: (ScannedDocument) -> Void

    @StateObject private var viewModel = DocumentScannerESignViewModel()

    private enum Mode { case select, draw }
    @State private var mode: Mode = .select

    @State private var currentPageIndex = 0
    @State private var pageSignatures: [Int: PageSignatureState] = [:]

    @State private var showImagePicker = false
    @State private var photoPickerItem: PhotosPickerItem?

    var body: some View {
        Group {
            switch mode {
            case .select: selectScreen
            case .draw:
                ESignDrawCanvas(documentName: document.name, onBack: { mode = .select }, onDone: { image in
                    placeOnCurrentPage(image)
                    mode = .select
                })
            }
        }
    }

    // MARK: - Select screen

    private var selectScreen: some View {
        VStack(spacing: 0) {
            header
            if viewModel.pages.count > 1 {
                pageSwitcher
            }
            contentArea
            bottomActions
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .onAppear { viewModel.initDocument(document) }
        .scannerToast($viewModel.toastMessage)
        .photosPicker(isPresented: $showImagePicker, selection: $photoPickerItem, matching: .images)
        .onChange(of: photoPickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    placeOnCurrentPage(image)
                }
                photoPickerItem = nil
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image("back_arrow").resizable().scaledToFit().frame(width: 24, height: 24)
            }
            Text(document.name)
                .font(Font.custom("PlusJakartaSans-ExtraBold", size: 16))
                .foregroundColor(.white)
                .lineLimit(1)
            Spacer()
            if !pageSignatures.isEmpty {
                Button(action: save) {
                    if viewModel.isSaving {
                        ProgressView().tint(.white).scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                    }
                }
                .disabled(viewModel.isSaving)
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
        .background(
            Color(hex: "#191C1D")
                .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                .edgesIgnoringSafeArea(.top)
        )
    }

    private var pageSwitcher: some View {
        HStack(spacing: 12) {
            Button(action: { currentPageIndex = max(0, currentPageIndex - 1) }) {
                Image(systemName: "chevron.left").foregroundColor(currentPageIndex == 0 ? Color(hex: "#C4C4C6") : Color(hex: "#1A1A1A"))
            }
            .disabled(currentPageIndex == 0)

            HStack(spacing: 4) {
                if pageSignatures[currentPageIndex] != nil {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 12)).foregroundColor(.blue)
                }
                Text("Page \(currentPageIndex + 1) of \(viewModel.pages.count)")
                    .font(Font.custom("Inter", size: 13))
                    .foregroundColor(Color(hex: "#1A1A1A"))
            }

            Button(action: { currentPageIndex = min(viewModel.pages.count - 1, currentPageIndex + 1) }) {
                Image(systemName: "chevron.right").foregroundColor(currentPageIndex == viewModel.pages.count - 1 ? Color(hex: "#C4C4C6") : Color(hex: "#1A1A1A"))
            }
            .disabled(currentPageIndex == viewModel.pages.count - 1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(Color.white)
    }

    private var currentPageImage: UIImage? {
        viewModel.pages.indices.contains(currentPageIndex) ? viewModel.pages[currentPageIndex] : nil
    }

    private var contentArea: some View {
        ZStack {
            Color(hex: "#B5B5B5")
            if viewModel.isLoading {
                ProgressView().tint(.white)
            } else if let pageImage = currentPageImage {
                GeometryReader { outerGeo in
                    let aspect = pageImage.size.width / pageImage.size.height
                    let fitted = fittedSize(aspect: aspect, in: outerGeo.size)
                    ZStack(alignment: .topLeading) {
                        Image(uiImage: pageImage).resizable().frame(width: fitted.width, height: fitted.height)
                        if pageSignatures[currentPageIndex] != nil {
                            SignatureOverlayView(
                                image: pageSignatures[currentPageIndex]!.image,
                                placement: Binding(
                                    get: { pageSignatures[currentPageIndex]?.placement ?? SignaturePlacement() },
                                    set: { pageSignatures[currentPageIndex]?.placement = $0 }
                                ),
                                containerSize: fitted
                            )
                            // Forces a fresh instance (and fresh @State) per page, so dragging a
                            // signature on one page can never carry stale live-drag state over to
                            // a different page's signature after switching pages.
                            .id(currentPageIndex)
                        }
                    }
                    .frame(width: fitted.width, height: fitted.height)
                    .position(x: outerGeo.size.width / 2, y: outerGeo.size.height / 2)
                }
                .padding(20)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
    }

    /// Computes the fitted container size directly (rather than relying on `.aspectRatio(.fit)`'s
    /// own layout, which could leave letterbox slack in whatever we measure) — the returned size
    /// is exactly the rendered image's footprint, so it's a pixel-accurate denominator for the
    /// signature's fractional placement math.
    private func fittedSize(aspect: CGFloat, in available: CGSize) -> CGSize {
        guard aspect > 0, available.width > 0, available.height > 0 else { return available }
        let availableAspect = available.width / available.height
        if availableAspect > aspect {
            return CGSize(width: available.height * aspect, height: available.height)
        } else {
            return CGSize(width: available.width, height: available.width / aspect)
        }
    }

    private var bottomActions: some View {
        HStack(spacing: 0) {
            actionTab(icon: "square.and.arrow.up", label: "Upload") { showImagePicker = true }
            actionTab(icon: "signature", label: "Create") { mode = .draw }
        }
        .padding(.vertical, 10)
        .padding(.bottom, 6)
        .overlay(Rectangle().fill(Color(hex: "#E5E5E5")).frame(height: 1), alignment: .top)
    }

    private func actionTab(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 22)).foregroundColor(Color(hex: "#1C1C1E"))
                Text(label).font(Font.custom("Inter", size: 12).weight(.medium)).foregroundColor(Color(hex: "#1C1C1E"))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Placement / save

    private func placeOnCurrentPage(_ image: UIImage) {
        if var existing = pageSignatures[currentPageIndex] {
            existing.image = image
            pageSignatures[currentPageIndex] = existing
        } else {
            pageSignatures[currentPageIndex] = PageSignatureState(image: image, placement: SignaturePlacement())
        }
    }

    private func save() {
        let signedPages: [Int: ESignPagePlacement] = pageSignatures.mapValues { state in
            ESignPagePlacement(signatureImage: state.image, xFraction: state.placement.x, yFraction: state.placement.y, widthFraction: state.placement.width, heightFraction: state.placement.height)
        }
        viewModel.saveSignatures(document: document, signedPages: signedPages, onComplete: onSaveComplete)
    }
}

// MARK: - SignaturePlacement / PageSignatureState

private struct SignaturePlacement: Equatable {
    var x: CGFloat = 0.25
    var y: CGFloat = 0.6
    var width: CGFloat = 0.5
    var height: CGFloat = 0.18
}

private struct PageSignatureState {
    var image: UIImage
    var placement: SignaturePlacement
}

// MARK: - SignatureOverlayView
// Drag-to-move (whole bounding box) + a single bottom-right resize handle, axis-aligned only — no
// rotation, no aspect lock, no pinch, matching Android exactly. Each gesture captures its own
// starting placement once (SwiftUI's DragGesture.translation is cumulative from gesture-start, not
// a per-event delta like Compose's — so the fix here is simpler than Android's rebase trick: just
// don't re-add the same cumulative value every frame).

// A rectangle with a square bite taken out of one corner, via even-odd fill: the corner square is
// added a second time on top of the full rect, so under the even-odd rule that doubly-covered
// region counts as "outside" the shape while the rest of the rect (covered once) stays "inside."
// Used as `SignatureOverlayView`'s move-gesture hit-test region so the resize handle's corner has
// no shared hit-test territory with the move gesture at all.
private struct NotchedRect: Shape {
    let notchSize: CGFloat
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        path.addRect(CGRect(x: rect.maxX - notchSize, y: rect.maxY - notchSize, width: notchSize, height: notchSize))
        return path
    }
}

private struct SignatureOverlayView: View {
    let image: UIImage
    @Binding var placement: SignaturePlacement
    let containerSize: CGSize

    // Drives the actual on-screen position/size *during* a drag. `placement` (the binding) lives
    // in the parent's `pageSignatures` dictionary — writing to it on every `.onChanged` frame (60+
    // times/sec) forced the parent's whole body, including the full-resolution page `Image`, to
    // re-render every frame, which is exactly what "hard to move" / "not smooth" feels like.
    // Mutating this local copy instead keeps every drag frame scoped to just this small view, and
    // `placement` is written back to the parent only once, at `.onEnded`.
    @State private var livePlacement: SignaturePlacement

    @State private var moveStartPlacement: SignaturePlacement?

    // Live width/height *during* an active resize drag. `@GestureState` is Apple's own mechanism
    // for driving continuous visual feedback while a gesture is in progress — unlike mutating
    // `@State` directly inside `.onChanged` (which is what the move gesture below still does, and
    // which turned out to be unreliable specifically for the resize handle: recognition worked,
    // but the box's visible size stayed frozen through the whole drag and only ever caught up to
    // the real value once something unrelated forced a fresh render), `@GestureState` automatically
    // resets to `.zero` the instant the gesture ends, and SwiftUI is specifically built to deliver
    // its updates on every frame regardless of how the surrounding view re-renders in between.
    @GestureState private var resizeDragTranslation: CGSize = .zero

    init(image: UIImage, placement: Binding<SignaturePlacement>, containerSize: CGSize) {
        self.image = image
        self._placement = placement
        self.containerSize = containerSize
        self._livePlacement = State(initialValue: placement.wrappedValue)
    }

    private var liveWidthFraction: CGFloat {
        let raw = livePlacement.width + resizeDragTranslation.width / containerSize.width
        return min(max(0.08, raw), 1 - livePlacement.x)
    }
    private var liveHeightFraction: CGFloat {
        let raw = livePlacement.height + resizeDragTranslation.height / containerSize.height
        return min(max(0.04, raw), 1 - livePlacement.y)
    }

    private var widthPx: CGFloat { liveWidthFraction * containerSize.width }
    private var heightPx: CGFloat { liveHeightFraction * containerSize.height }
    private var xPx: CGFloat { livePlacement.x * containerSize.width }
    private var yPx: CGFloat { livePlacement.y * containerSize.height }

    // The resize handle is a genuine SIBLING of the image — both direct children of this `Group`,
    // each with its own plain `.gesture()`, exactly mirroring how `moveGesture` is attached below
    // (which is the one gesture in this view that has reliably worked throughout every attempt at
    // fixing this). Two earlier structures — the handle nested inside an `.overlay()` with
    // `.highPriorityGesture()`, and before that a differently-shaped sibling attempt without the
    // notch — both failed to deliver the resize gesture AT ALL, regardless of which
    // priority/arbitration mechanism was layered on top. The common thread in every failure was
    // relying on SOME form of gesture-priority arbitration to resolve an overlap; this version
    // removes the overlap instead: `NotchedRect` (below) excludes the handle's corner from the
    // image's own hit-test region, so the two gestures' territories never touch, and neither needs
    // any special priority modifier — a plain `.gesture()` for each, same as the one attachment
    // style already proven to work.
    //
    // `Group`, not `ZStack` — a wrapping `ZStack` would need its own explicit `.frame(width:height:)`
    // to report a size upward, and that frame would clip the handle back down to the image's
    // bounds since the handle is centered ON the image's corner (half in, half out) by design.
    // `Group` imposes no frame of its own, so both children size and position themselves
    // independently against `contentArea`'s own (larger) coordinate space, with nothing clipping
    // either one.
    var body: some View {
        Group {
            Image(uiImage: image)
                .resizable()
                .frame(width: widthPx, height: heightPx)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color(hex: "#0A84FF"), lineWidth: 1))
                .contentShape(NotchedRect(notchSize: resizeHandleNotch), eoFill: true)
                .position(x: xPx + widthPx / 2, y: yPx + heightPx / 2)
                .gesture(moveGesture)

            resizeHandle
                .position(x: xPx + widthPx, y: yPx + heightPx)
        }
    }

    // The resize handle is 44x44 and centered exactly on the image's bottom-right corner (half in,
    // half out), so it overlaps the image's own bounds by a 22x22 square there. 26 gives that a
    // few points of margin, so the notch fully swallows the handle's hit area with room to spare.
    private let resizeHandleNotch: CGFloat = 26

    // Visually still a 28x28 badge, but its hit-testable area is the full 44x44 frame around it —
    // Apple's own minimum recommended tap target. At 28x28 alone, a touch that lands just outside
    // the visible badge (extremely easy at a screen corner) misses it entirely and falls through
    // to the move gesture instead — which looks exactly like "resize doesn't work, it just moves."
    private var resizeHandle: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color(hex: "#0A84FF"))
            Image(systemName: "arrow.up.left.and.arrow.down.right").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
        }
        .frame(width: 28, height: 28)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
        .gesture(resizeGesture)
    }

    // `minimumDistance: 0` on both gestures (instead of the default 10pt) — the default leaves a
    // small "dead zone" where the drag doesn't track at all until the touch has already moved
    // 10pt, then jumps to catch up. That reads as sluggish/laggy exactly like the reported "hard
    // to move, not smooth," independent of the render-cost fix above.
    private var moveGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let base = moveStartPlacement ?? livePlacement
                if moveStartPlacement == nil { moveStartPlacement = livePlacement }
                let newX = base.x + value.translation.width / containerSize.width
                let newY = base.y + value.translation.height / containerSize.height
                livePlacement.x = min(max(0, newX), 1 - livePlacement.width)
                livePlacement.y = min(max(0, newY), 1 - livePlacement.height)
            }
            .onEnded { _ in
                moveStartPlacement = nil
                placement = livePlacement
            }
    }

    // `livePlacement.width`/`.height` themselves are only ever touched in `.onEnded` here — during
    // the drag, `resizeDragTranslation` (via `.updating`) is the only thing changing, and
    // `liveWidthFraction`/`liveHeightFraction` above fold it in on top of the still-fixed
    // `livePlacement.width`/`.height`, so there's no need for a separate "base at drag start"
    // snapshot the way `moveGesture` needs one — `value.translation` is already cumulative from
    // this gesture's own start.
    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($resizeDragTranslation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let newWidth = livePlacement.width + value.translation.width / containerSize.width
                let newHeight = livePlacement.height + value.translation.height / containerSize.height
                livePlacement.width = min(max(0.08, newWidth), 1 - livePlacement.x)
                livePlacement.height = min(max(0.04, newHeight), 1 - livePlacement.y)
                placement = livePlacement
            }
    }
}

// MARK: - SignatureStroke

private struct SignatureStroke {
    var points: [CGPoint]
    let color: Color
    let width: CGFloat
}

// MARK: - ESignDrawCanvas
// The hand-drawn signature canvas — raw polylines through captured pointer positions, no
// smoothing/Bezier fitting, matching Android. Undo/redo are full stroke-list snapshots.

private struct ESignDrawCanvas: View {
    let documentName: String
    let onBack: () -> Void
    let onDone: (UIImage) -> Void

    @State private var strokes: [SignatureStroke] = []
    @State private var undoStack: [[SignatureStroke]] = []
    @State private var redoStack: [[SignatureStroke]] = []
    @State private var currentPoints: [CGPoint] = []
    @State private var currentColor: Color = Color(hex: "#007AFF")
    @State private var strokeWidth: CGFloat = 4
    @State private var showSizeTab = false
    @State private var canvasSize: CGSize = .zero

    private let colors: [Color] = [
        Color(hex: "#E0E0E0"), Color(hex: "#9E9E9E"), Color(hex: "#000000"),
        Color(hex: "#00008B"), Color(hex: "#007AFF"), Color(hex: "#34A8F4"), Color(hex: "#E50000")
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            VStack(spacing: 12) {
                canvas
                controlsRow
            }
            .padding(10)
            .frame(maxHeight: .infinity)
            bottomDrawer
        }
        .background(Color(hex: "#F2F3F5"))
        .navigationBarHidden(true)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image("back_arrow").resizable().scaledToFit().frame(width: 24, height: 24)
            }
            Text(documentName).font(Font.custom("PlusJakartaSans-ExtraBold", size: 16)).foregroundColor(.white).lineLimit(1)
            Spacer()
            Button(action: finishDrawing) {
                Text("Done").font(Font.custom("Inter", size: 16).weight(.semibold)).foregroundColor(Color(hex: "#0A84FF"))
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
        .background(
            Color(hex: "#191C1D")
                .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                .edgesIgnoringSafeArea(.top)
        )
    }

    private var canvas: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18).fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "#E5E5EA"), lineWidth: 1))

            if strokes.isEmpty && currentPoints.isEmpty {
                Text("Draw here").font(Font.custom("Inter", size: 14)).foregroundColor(Color(hex: "#8E8E93"))
                    .padding(.top, 20)
                    .frame(maxHeight: .infinity, alignment: .top)
            }

            Canvas { context, _ in
                for stroke in strokes {
                    drawStroke(stroke.points, color: stroke.color, width: stroke.width, in: &context)
                }
                if currentPoints.count > 1 {
                    drawStroke(currentPoints, color: currentColor, width: strokeWidth, in: &context)
                }
            }
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { canvasSize = geo.size }
                        .onChange(of: geo.size) { _, newSize in canvasSize = newSize }
                }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in currentPoints.append(value.location) }
                .onEnded { _ in
                    if currentPoints.count >= 2 {
                        commit(strokes + [SignatureStroke(points: currentPoints, color: currentColor, width: strokeWidth)])
                    }
                    currentPoints = []
                }
        )
    }

    private func drawStroke(_ points: [CGPoint], color: Color, width: CGFloat, in context: inout GraphicsContext) {
        guard points.count > 1 else { return }
        var path = Path()
        path.move(to: points[0])
        for point in points.dropFirst() { path.addLine(to: point) }
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    private func commit(_ newStrokes: [SignatureStroke]) {
        undoStack.append(strokes)
        redoStack.removeAll()
        strokes = newStrokes
    }

    /// Sets the active color AND recolors every stroke drawn so far. A signature is one color,
    /// not a per-stroke palette — without this, picking a new swatch only affected strokes drawn
    /// *after* that tap, so most of an already-drawn signature visibly stayed the old color and
    /// picking a color looked like it "did nothing."
    private func setColor(_ color: Color) {
        currentColor = color
        guard !strokes.isEmpty else { return }
        strokes = strokes.map { SignatureStroke(points: $0.points, color: color, width: $0.width) }
    }

    private var controlsRow: some View {
        HStack {
            HStack(spacing: 20) {
                Button(action: undo) {
                    Image(systemName: "arrow.uturn.backward").foregroundColor(undoStack.isEmpty ? Color(hex: "#C4C4C6") : Color(hex: "#1C1C1E"))
                }
                .disabled(undoStack.isEmpty)
                Button(action: redo) {
                    Image(systemName: "arrow.uturn.forward").foregroundColor(redoStack.isEmpty ? Color(hex: "#C4C4C6") : Color(hex: "#1C1C1E"))
                }
                .disabled(redoStack.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#E5E5EA"), lineWidth: 1))

            Spacer()

            Button(action: eraseAll) {
                Image(systemName: "eraser")
                    .foregroundColor(Color(hex: "#1C1C1E"))
                    .padding(10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#E5E5EA"), lineWidth: 1))
            }
        }
        .padding(.horizontal, 4)
    }

    private func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(strokes)
        strokes = previous
    }

    private func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(strokes)
        strokes = next
    }

    private func eraseAll() {
        guard !strokes.isEmpty else { return }
        commit([])
    }

    private var bottomDrawer: some View {
        VStack(spacing: 16) {
            Text(showSizeTab ? "Size" : "Color")
                .font(Font.custom("Inter", size: 13).weight(.medium))
                .foregroundColor(Color(hex: "#1C1C1E"))

            if showSizeTab {
                HStack(spacing: 14) {
                    Circle().fill(Color(hex: "#C4C4C6")).frame(width: 6, height: 6)
                    Slider(value: $strokeWidth, in: 1...12)
                    Text("\(Int(strokeWidth))").font(Font.custom("Inter", size: 14)).foregroundColor(.black)
                }
                .padding(.horizontal, 24)
            } else {
                HStack(spacing: 8) {
                    ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                        Button(action: { setColor(color) }) {
                            RoundedRectangle(cornerRadius: 8).fill(color)
                                .frame(width: 28, height: 28)
                                .padding(currentColor == color ? 3 : 0)
                                .overlay(RoundedRectangle(cornerRadius: 11).stroke(currentColor == color ? Color(hex: "#007AFF") : Color.clear, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }

            HStack(spacing: 96) {
                tabButton(icon: "pencil", label: "Size", isActive: showSizeTab) { showSizeTab = true }
                tabButton(icon: "paintpalette", label: "Color", isActive: !showSizeTab) { showSizeTab = false }
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 25)
        .background(Color.white.cornerRadius(32, corners: [.topLeft, .topRight]))
    }

    private func tabButton(icon: String, label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 18)).foregroundColor(isActive ? .red : Color(hex: "#8E8E93"))
                Text(label).font(Font.custom("Inter", size: 11).weight(isActive ? .semibold : .medium)).foregroundColor(isActive ? .red : Color(hex: "#8E8E93"))
            }
        }
        .buttonStyle(.plain)
    }

    private func finishDrawing() {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return }
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        let image = renderer.image { _ in
            for stroke in strokes {
                guard stroke.points.count > 1 else { continue }
                let path = UIBezierPath()
                path.move(to: stroke.points[0])
                for point in stroke.points.dropFirst() { path.addLine(to: point) }
                path.lineWidth = stroke.width
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                UIColor(stroke.color).setStroke()
                path.stroke()
            }
        }
        onDone(image)
    }
}

#if DEBUG
#Preview {
    DocumentScannerESignView(
        document: DocumentScannerPreviewSupport.sampleDocument(name: "Rental Agreement"),
        onBack: {},
        onSaveComplete: { _ in }
    )
}
#endif
