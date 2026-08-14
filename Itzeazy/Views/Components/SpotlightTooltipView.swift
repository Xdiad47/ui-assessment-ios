import SwiftUI

// One-time coach mark shown on Home to prove RTO Services and Visa are
// browsable without signing in — before a guest might otherwise hit a login
// wall elsewhere (e.g. the hero "Get Started" button) and assume the whole
// app is gated. (Originally targeted Vehicle/Challan/DL Info, but those
// require a login-gated ULIP session token even to browse — RTO Services /
// Visa only need login at "Apply Now", so they're the ones that are
// genuinely guest-accessible.)
// Dimmed backdrop with a punched-out hole around RTO Services + Visa (first
// column, rows 1 and 2) in the Services card, a themed callout, and a single
// "Got it" dismissal. Shown once — the caller tracks that via UserDefaults
// (HomeView's `hasSeenServicesSpotlight`).

// Reports the exact rendered frame of the whole Services card (the rounded
// gradient box containing all service cells), resolved in the
// "homeSpotlightSpace" named coordinate space defined on HomeView's own
// root. Measuring the *card* instead of an individual cell keeps this to a
// single, stable GeometryReader (no per-cell / lazy-grid timing issues).
struct SpotlightRectKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

struct SpotlightTooltipView: View {
    /// The whole Services card's measured frame, in "homeSpotlightSpace".
    let cardRect: CGRect
    let screenSize: CGSize
    let onDismiss: () -> Void

    // MARK: - Tunable highlight box
    // Edit these directly to reposition/resize the highlighted area. All
    // values are offsets from `cardRect` (the Services card), not the
    // screen, so the box still lands correctly on different device sizes.
    // RTO Services (row 1) and Visa (row 2) sit in the grid's first column,
    // not side by side — so this is a tall single-column box spanning two
    // stacked rows, not a wide single-row one.

    /// Distance from the card's left edge to the left edge of the highlight.
    private let highlightLeadingInset: CGFloat = 12
    /// Distance from the card's top edge to the top edge of the highlight
    /// (the card's own top padding is 12, then the "Services We Provide"
    /// title block sits above the grid — increase this to push the box
    /// further down).
    private let highlightTopInset: CGFloat = 4
    /// Height of one grid row. Increase if labels wrap to a 3rd line on
    /// narrow devices and get clipped — re-tune against the real rendered
    /// cell height, same as before.
    private let rowHeight: CGFloat = 96
    /// Vertical gap between grid rows — must match the LazyVGrid's own row
    /// spacing (8) or the box will drift from the real cell edges.
    private let rowSpacing: CGFloat = 8
    /// How many stacked rows to cover — 2 spans RTO Services + Visa.
    private let highlightRowCount: CGFloat = 2
    /// Grid's own column spacing/padding — must match HomeServicesGridView
    /// (`columns` spacing: 8, LazyVGrid `.padding(12)`) or the box will
    /// drift from the real cell edges.
    private let gridColumnCount: CGFloat = 5
    private let gridColumnSpacing: CGFloat = 8
    private let gridHorizontalPadding: CGFloat = 12

    // Matches the accent red already used elsewhere in HomeView (hero button,
    // section-title underlines) rather than SwiftUI's default .red.
    private let accentRed = Color(red: 0.85, green: 0.2, blue: 0.2)
    private let holePadding: CGFloat = 6
    private let holeCornerRadius: CGFloat = 16
    private let bubbleWidth: CGFloat = 260 // this is text that shows about the tool tip
    private let bubbleHalfHeight: CGFloat = 90

    /// Computed from `cardRect` + the tunable insets above — this is the
    /// actual highlighted rectangle (before the extra `holePadding` ring gap).
    private var targetRect: CGRect {
        let cellWidth = (cardRect.width - 2 * gridHorizontalPadding - (gridColumnCount - 1) * gridColumnSpacing) / gridColumnCount
        let height = highlightRowCount * rowHeight + (highlightRowCount - 1) * rowSpacing
        let x = cardRect.minX + highlightLeadingInset
        let y = cardRect.minY + highlightTopInset
        return CGRect(x: x, y: y, width: cellWidth, height: height)
    }

    private var holeRect: CGRect {
        targetRect.insetBy(dx: -holePadding, dy: -holePadding)
    }

    // Show the bubble below the hole if there's room, otherwise above it.
    private var bubbleAbove: Bool {
        holeRect.maxY + (bubbleHalfHeight * 2) + 24 > screenSize.height
    }

    private var clampedBubbleX: CGFloat {
        let half = bubbleWidth / 2
        guard screenSize.width > (half + 16) * 2 else { return screenSize.width / 2 }
        return min(max(targetRect.midX, half + 16), screenSize.width - half - 16)
    }

    var body: some View {
        ZStack {
            // No .ignoresSafeArea() here on purpose: holeRect is measured in
            // "homeSpotlightSpace", a coordinate space anchored at the safe
            // area's top edge (same origin the ring below uses). Adding
            // ignoresSafeArea() to *this* shape shifts its own local origin
            // up above the status bar while holeRect's numbers stay relative
            // to the old origin — that mismatch is what was pushing the
            // white hole away from the red ring.
            SpotlightScrimShape(holeRect: holeRect, cornerRadius: holeCornerRadius)
                .fill(Color.black.opacity(0.72), style: FillStyle(eoFill: true))
                .onTapGesture(perform: onDismiss)

            RoundedRectangle(cornerRadius: holeCornerRadius, style: .continuous)
                .stroke(accentRed, lineWidth: 2.5)
                .frame(width: holeRect.width, height: holeRect.height)
                .position(x: holeRect.midX, y: holeRect.midY)
                .shadow(color: accentRed.opacity(0.55), radius: 10)
                .allowsHitTesting(false)

            bubble
                .position(
                    x: clampedBubbleX,
                    y: bubbleAbove
                        ? holeRect.minY - bubbleHalfHeight - 14
                        : holeRect.maxY + bubbleHalfHeight + 14
                )
        }
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 6) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(accentRed)
                Text("No sign-in needed")
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 14))
                    .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
            }

            Text("Browse RTO services and Visa info right here — free, no account needed until you apply.")
                .font(Font.custom("Inter", size: 12.5))
                .foregroundColor(Color(red: 0.37, green: 0.37, blue: 0.37))
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onDismiss) {
                Text("Got it")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 13))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(accentRed)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .padding(14)
        .frame(width: bubbleWidth, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 6)
    }
}

/// Full-bounds rectangle with a rounded-rect hole subtracted via the
/// even-odd fill rule — draws in one pass, in the shape's own final rect,
/// so there's no separate masking pass that can drift out of alignment.
private struct SpotlightScrimShape: Shape {
    let holeRect: CGRect
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        path.addPath(Path(roundedRect: holeRect, cornerRadius: cornerRadius, style: .continuous))
        return path
    }
}
