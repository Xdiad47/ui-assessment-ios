import SwiftUI
import Combine

/// Blocking acknowledgement popup shown before any private-portal screen (native service
/// flow or WebView). Both dismiss paths (backdrop tap, "I Understand & Proceed") resolve to
/// a callback — there is no silent way to end up past this screen without one of the two.
/// Frequency is capped by GovDisclaimerGate/GovDisclaimerFrequencyStore, not by this view.
struct GovDisclaimerPopupView: View {
    var onAcknowledge: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 16) {
                Text("Important Notice")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 20))
                    .foregroundColor(Color(hex: "#191c1d"))

                Text(
                    "Itzeazy is an independent service provider. Its role is limited to " +
                    "guidance, documentation, filing the forms accurately and doorstep " +
                    "facilitation. Itzeazy is not affiliated with any government department, " +
                    "embassy or authority. Documents approval and issuance are handled by the " +
                    "concerned Govt. authorities."
                )
                .font(Font.custom("Inter", size: 14))
                .foregroundColor(Color(hex: "#5f5e5e"))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

                Button(action: onAcknowledge) {
                    Text("I Understand & Proceed")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 15))
                        .foregroundColor(.red)
                }
                .padding(.top, 4)
            }
            .padding(28)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 32)
            .shadow(color: Color.black.opacity(0.25), radius: 30, x: 0, y: 14)
        }
    }
}

/// Slim, translucent banner reminding the user, for the duration of the session, that the
/// page underneath is a private portal and not a government one.
struct GovDisclaimerBanner: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#B45309"))

            Text("Private service portal — not affiliated with any government authority")
                .font(Font.custom("Inter", size: 10).weight(.semibold))
                .foregroundColor(Color(hex: "#B45309"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
        .background(Color(hex: "#FFC107").opacity(0.14))
    }
}

/// Wires up the frequency-capped entry disclaimer (max 3 shows/day for `serviceKey`, reset
/// the next calendar day) for a screen. Own one of these as a `@StateObject` in the screen
/// that should show the popup on entry, call `checkOnAppear()` from `.onAppear`, and render
/// `GovDisclaimerPopupView` when `isPresented` is true.
@MainActor
final class GovDisclaimerGate: ObservableObject {
    @Published var isPresented = false

    let serviceKey: String
    private let store = GovDisclaimerFrequencyStore.shared

    init(serviceKey: String) {
        self.serviceKey = serviceKey
    }

    /// Call once when the owning screen appears. Re-entering the flow (a fresh navigation
    /// push, not just this same instance re-appearing) creates a new gate instance, so this
    /// re-evaluates the cap on every real entry — matching the Android behavior exactly.
    func checkOnAppear() {
        guard store.shouldShow(serviceKey) else { return }
        store.recordShown(serviceKey)
        isPresented = true
    }

    func acknowledge() {
        isPresented = false
    }
}

/// Short justification card shown on service detail screens, right below the "Get
/// Assistance" button, explaining what the Itzeazy fee (as opposed to the govt. fee) covers.
struct GovDisclaimerJustificationCard: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Font.custom("Inter", size: 14))
            .foregroundColor(.black)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.white, Color(white: 0.94)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(red: 0.72, green: 0.72, blue: 0.72), lineWidth: 1)
            )
    }
}

#Preview {
    GovDisclaimerPopupView(onAcknowledge: {}, onDismiss: {})
}
