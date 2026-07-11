import SwiftUI

/// Shown when a signed-out user taps an action that requires an account (wallet, orders,
/// profile, citizen-service checkout). Guest-accessible ULIP lookups never trigger this.
struct AuthGatePopupView: View {
    var onLogin: () -> Void
    var onCreateAccount: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 64, height: 64)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.red)
                }

                VStack(spacing: 8) {
                    Text("Login Required")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 20))
                        .foregroundColor(Color(hex: "#191c1d"))

                    Text("Please login or create your itzEazy account to access this feature.")
                        .font(Font.custom("Inter", size: 14))
                        .foregroundColor(Color(hex: "#5f5e5e"))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 12) {
                    Button(action: onLogin) {
                        Text("Login")
                            .font(Font.custom("PlusJakartaSans-SemiBold", size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .shadow(color: Color(red: 187/255, green: 0, blue: 17/255, opacity: 0.2), radius: 12, x: 0, y: 6)
                    }

                    Button(action: onCreateAccount) {
                        Text("Create Account")
                            .font(Font.custom("PlusJakartaSans-SemiBold", size: 16))
                            .foregroundColor(Color(hex: "#191c1d"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white)
                            .overlay(Capsule().stroke(Color(hex: "#b7b7b7"), lineWidth: 1))
                            .clipShape(Capsule())
                    }

                    Button("Maybe later", action: onDismiss)
                        .font(Font.custom("Inter", size: 14).weight(.semibold))
                        .foregroundColor(Color(hex: "#5f5e5e"))
                        .padding(.top, 2)
                }
            }
            .padding(28)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .padding(.horizontal, 32)
            .shadow(color: Color.black.opacity(0.25), radius: 30, x: 0, y: 14)
        }
    }
}

#Preview {
    AuthGatePopupView(onLogin: {}, onCreateAccount: {}, onDismiss: {})
}
