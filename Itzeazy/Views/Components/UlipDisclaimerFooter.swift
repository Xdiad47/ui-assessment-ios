import SwiftUI

// Shown as a persistent, fixed footer (via .safeAreaInset(edge: .bottom)) on
// every screen that surfaces ULIP-sourced government data, so users never
// mistake this app for an official government service. Always visible —
// across idle, loading, error, and results states — never buried inside
// scrollable content.
struct UlipDisclaimerFooter: View {
    /// Whichever screen embeds this passes the actual background color behind
    /// the footer in its *current* state (these screens swap between a dark
    /// header/idle background and a light results background), so the text
    /// stays legible instead of blending into whatever is currently behind it.
    var isOnDarkBackground: Bool = false

    private var textColor: Color {
        isOnDarkBackground ? Color.white.opacity(0.85) : Color(red: 0.45, green: 0.45, blue: 0.45)
    }

    var body: some View {
        VStack(spacing: 2) {
            Text("Not an official government app.")
                .font(.system(size: 11))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
            Text("Data source: ULIP (Government of India)")
                .font(.system(size: 11))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
