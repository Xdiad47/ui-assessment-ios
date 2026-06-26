import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ForgotPasswordViewModel()

    private let countryDropdownWidth: CGFloat = 220

    @State private var isCountryPickerPresented = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var countryButtonFrame: CGRect = .zero
    @State private var navigateToOTP = false
    @FocusState private var isContactFieldFocused: Bool

    private var isKeyboardPresented: Bool {
        keyboardHeight > 0
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Color.white
                    .ignoresSafeArea()
                    .onTapGesture {
                        isContactFieldFocused = false
                        isCountryPickerPresented = false
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
                        contactSection
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

                if isCountryPickerPresented && viewModel.shouldShowCountrySelector {
                    Color.black.opacity(0.08)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isCountryPickerPresented = false
                            }
                        }

                    CountryCodeDropdownView(
                        selectedCountry: $viewModel.selectedCountry,
                        isPresented: $isCountryPickerPresented,
                        width: countryDropdownWidth
                    )
                    .position(
                        x: countryButtonFrame.minX + (countryDropdownWidth / 2),
                        y: countryButtonFrame.maxY + 12 + 130
                    )
                    .transition(.scale(scale: 0.96, anchor: .topLeading).combined(with: .opacity))
                    .zIndex(5)
                }
            }
            .coordinateSpace(name: "forgotPasswordRoot")
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.light)
        .navigationDestination(isPresented: $navigateToOTP) {
            ForgotPasswordOTPView(
                contactInfo: viewModel.formattedContactInfo,
                isPhoneContact: viewModel.shouldShowCountrySelector,
                viewModel: viewModel
            )
        }
        .onChange(of: viewModel.emailOrMobile) { _, newValue in
            viewModel.handleContactInputChange(newValue)
        }
        .onChange(of: viewModel.otpSent) { _, sent in
            if sent { navigateToOTP = true }
        }
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

                Image("forgot_password_image")
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
            Text("Forgot Password")
                .font(Font.custom("PlusJakartaSans-ExtraBold", size: 24))
                .foregroundColor(.red)
                .tracking(-0.9)

            Text("Enter the email address or mobile num associated with your ItzEazy account.")
                .font(Font.custom("Inter", size: 16).weight(.medium))
                .foregroundColor(Color(hex: "#5f5e5e"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var contactSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Email or Mobile Number")
                    .font(Font.custom("Inter", size: 14).weight(.semibold))
                    .foregroundColor(Color(hex: "#191c1d"))

                HStack(alignment: .top, spacing: 12) {
                    if viewModel.shouldShowCountrySelector {
                        Button {
                            isContactFieldFocused = false
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isCountryPickerPresented.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text("\(viewModel.selectedCountry.isoCode) \(viewModel.selectedCountry.phoneCode)")
                                    .font(Font.custom("Inter", size: 14))
                                    .foregroundColor(Color(hex: "#0d0d0d"))
                                    .lineLimit(1)

                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(hex: "#0d0d0d"))
                            }
                            .frame(width: 88, height: 51)
                            .background(Color(hex: "#f3f3f3"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(hex: "#b7b7b7"), lineWidth: 1)
                            )
                            .cornerRadius(16)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 88, height: 51, alignment: .topLeading)
                        .background {
                            GeometryReader { proxy in
                                Color.clear
                                    .onAppear {
                                        countryButtonFrame = proxy.frame(in: .named("forgotPasswordRoot"))
                                    }
                                    .onChange(of: proxy.frame(in: .named("forgotPasswordRoot"))) { _, newValue in
                                        countryButtonFrame = newValue
                                    }
                            }
                        }
                    }

                    ZStack(alignment: .leading) {
                        if viewModel.emailOrMobile.isEmpty {
                            Text("Enter your Email / Mobile number")
                                .font(Font.custom("Inter", size: 12))
                                .foregroundColor(Color(hex: "#c2c5cb"))
                                .padding(.horizontal, 20)
                        }

                        TextField("", text: $viewModel.emailOrMobile)
                            .font(Font.custom("Inter", size: 14))
                            .foregroundColor(Color(hex: "#191c1d"))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .keyboardType(.default)
                            .focused($isContactFieldFocused)
                            .padding(.horizontal, 20)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 51)
                    .background(Color(hex: "#f3f4f5"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                isContactFieldFocused ? Color.red : Color(hex: "#b7b7b7"),
                                lineWidth: isContactFieldFocused ? 1.5 : 1
                            )
                    )
                    .cornerRadius(24)
                }

                if let error = viewModel.emailOrMobileError {
                    Text(error)
                        .font(Font.custom("Inter", size: 12))
                        .foregroundColor(.red)
                        .padding(.horizontal, 4)
                }
            }

            if let apiError = viewModel.errorMessage {
                Text(apiError)
                    .font(Font.custom("Inter", size: 12))
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                isContactFieldFocused = false
                isCountryPickerPresented = false
                guard viewModel.validateContactInput() else { return }
                viewModel.sendOTP()
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Continue")
                            .font(Font.custom("PlusJakartaSans-SemiBold", size: 18))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red)
                .clipShape(Capsule())
            }
            .disabled(viewModel.isLoading)
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
        ForgotPasswordView()
    }
}
