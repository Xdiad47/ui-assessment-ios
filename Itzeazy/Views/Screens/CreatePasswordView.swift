import SwiftUI

struct CreatePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var forgotPasswordViewModel: ForgotPasswordViewModel
    @StateObject private var viewModel = CreatePasswordViewModel()

    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var focusedField: PasswordField?

    private enum PasswordField {
        case newPassword
        case confirmPassword
    }

    private var isKeyboardPresented: Bool {
        keyboardHeight > 0
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Color.white
                    .ignoresSafeArea()
                    .onTapGesture {
                        focusedField = nil
                    }

                heroSection(in: geometry)
                    .opacity(isKeyboardPresented ? 0.42 : 1)
                    .offset(y: isKeyboardPresented ? -52 : 0)
                    .animation(.easeInOut(duration: 0.28), value: isKeyboardPresented)

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: isKeyboardPresented ? geometry.safeAreaInsets.top + 10 : 288)

                    VStack(spacing: 32) {
                        headerSection
                        passwordSection
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 18)
                    .padding(.bottom, isKeyboardPresented ? max(28, keyboardHeight - geometry.safeAreaInsets.bottom + 20) : 48)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(Color.white)
                    .clipShape(CustomCorners(corners: [.topLeft, .topRight], radius: 40))
                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: -10)
                }
                .offset(y: isKeyboardPresented ? -12 : 0)
                .animation(.easeInOut(duration: 0.28), value: isKeyboardPresented)
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.light)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            updateKeyboardHeight(from: notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.28)) {
                keyboardHeight = 0
            }
        }
    }

    private func heroSection(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Color.white
                .frame(height: max(geometry.safeAreaInsets.top, 59))

            ZStack(alignment: .top) {
                Color(hex: "#191c1d")

                Image("create_password_image")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: 320)
                    .clipped()
                    .opacity(0.9)

                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#191c1d"), Color(hex: "#191c1d").opacity(0)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 160)

                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image("back_arrow")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .padding(4)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 22)

                HStack {
                    Text("Itzeazy")
                        .font(Font.custom("PlusJakartaSans-ExtraBold", size: 24))
                        .foregroundColor(.white)
                        .tracking(-1.2)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 64)
            }
            .frame(height: 320)

            Spacer()
        }
        .ignoresSafeArea(edges: .top)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Create Password")
                .font(Font.custom("PlusJakartaSans-ExtraBold", size: 24))
                .foregroundColor(.red)
                .tracking(-0.9)

            Text("This password will be used whenever you login.")
                .font(Font.custom("Inter", size: 16).weight(.medium))
                .foregroundColor(Color(hex: "#5f5e5e"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var passwordSection: some View {
        VStack(spacing: 20) {
            passwordField(
                title: "New Password",
                text: $viewModel.newPassword,
                error: viewModel.newPasswordError,
                field: .newPassword
            )

            passwordField(
                title: "New Password Again",
                text: $viewModel.confirmPassword,
                error: viewModel.confirmPasswordError,
                field: .confirmPassword
            )

            if let apiError = forgotPasswordViewModel.errorMessage {
                Text(apiError)
                    .font(Font.custom("Inter", size: 12))
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                focusedField = nil
                guard viewModel.validatePasswords() else { return }
                forgotPasswordViewModel.updatePassword(
                    newPassword: viewModel.newPassword,
                    confirmPassword: viewModel.confirmPassword
                )
            } label: {
                Group {
                    if forgotPasswordViewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Save changes and Login")
                            .font(Font.custom("PlusJakartaSans-SemiBold", size: 18))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red)
                .clipShape(Capsule())
            }
            .disabled(forgotPasswordViewModel.isLoading)
            .padding(.top, 4)
        }
    }

    private func passwordField(
        title: String,
        text: Binding<String>,
        error: String?,
        field: PasswordField
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Font.custom("Inter", size: 14).weight(.semibold))
                .foregroundColor(Color(hex: "#191c1d"))

            SecureField("Enter new password", text: text)
                .font(Font.custom("Inter", size: 14))
                .foregroundColor(Color(hex: "#191c1d"))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .focused($focusedField, equals: field)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(Color(hex: "#f3f4f5"))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            focusedField == field ? Color.red : Color(hex: "#b7b7b7"),
                            lineWidth: focusedField == field ? 1.5 : 1
                        )
                )
                .cornerRadius(24)

            if let error {
                Text(error)
                    .font(Font.custom("Inter", size: 12))
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }
        }
        .onChange(of: text.wrappedValue) { _, _ in
            viewModel.clearErrors()
        }
    }

    private func updateKeyboardHeight(from notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        withAnimation(.easeInOut(duration: 0.28)) {
            keyboardHeight = frame.height
        }
    }
}

#Preview {
    NavigationStack {
        CreatePasswordView(forgotPasswordViewModel: ForgotPasswordViewModel())
    }
}
