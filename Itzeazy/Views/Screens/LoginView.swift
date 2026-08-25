import SwiftUI
import AuthenticationServices


//Coonect the app with dev server that is dev.itzeazy.in
//Login dev API

/// Handles the result of the native Apple Sign-In sheet: extracts the
/// identityToken JWT (the only piece the backend needs — never the
/// authorizationCode) and hands it to AuthViewModel.loginWithApple, which
/// tries login first and falls back to create-account if no account exists
/// yet for this Apple ID. Surfaces failures through the same
/// authViewModel.errorMessage the password/OTP flows already use.
func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>, authViewModel: AuthViewModel) {
    switch result {
    case .success(let authorization):
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = credential.identityToken.flatMap({ String(data: $0, encoding: .utf8) })
        else {
            authViewModel.errorMessage = "Apple Sign-In failed. Please try again."
            return
        }
        authViewModel.loginWithApple(identityToken: identityToken)
    case .failure(let error):
        // User cancelling the Apple sheet also lands here — don't show an
        // error toast for that, ASAuthorizationError.canceled is expected.
        let nsError = error as NSError
        guard nsError.domain == ASAuthorizationError.errorDomain,
              nsError.code == ASAuthorizationError.canceled.rawValue
        else {
            authViewModel.errorMessage = "Apple Sign-In failed. Please try again."
            return
        }
    }
}

struct LoginView: View {
    /// When true, immediately pushes to CreateAccountView on appear — used when the
    /// AuthGatePopupView's "Create Account" action presents this view.
    var startAtCreateAccount: Bool = false

    private let countryDropdownWidth: CGFloat = 220

    @StateObject private var authViewModel = AuthViewModel()

    @State private var emailOrMobile: String = ""
    @State private var selectedCountry = countries.first(where: { $0.isoCode == "IN" }) ?? countries[0]
    @State private var isCountryPickerPresented = false
    @State private var navigateToPassword = false
    @State private var navigateToCreateAccount = false
    @State private var emailOrMobileError: String?
    @State private var keyboardHeight: CGFloat = 0
    @State private var countryButtonFrame: CGRect = .zero
    @FocusState private var isContactFieldFocused: Bool

    private var trimmedInput: String {
        emailOrMobile.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isEmailInput: Bool {
        let value = trimmedInput
        return value.contains("@") || value.rangeOfCharacter(from: .letters) != nil
    }

    private var shouldShowCountrySelector: Bool {
        !isEmailInput
    }

    private var formattedContactInfo: String {
        shouldShowCountrySelector ? "\(selectedCountry.phoneCode) \(trimmedInput)" : trimmedInput
    }

    private var isKeyboardPresented: Bool {
        keyboardHeight > 0
    }

    var body: some View {
        NavigationStack {
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
                            footerSection
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

                    if isCountryPickerPresented && shouldShowCountrySelector {
                        Color.black.opacity(0.08)
                            .ignoresSafeArea()
                            .transition(.opacity)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isCountryPickerPresented = false
                                }
                            }

                        CountryCodeDropdownView(
                            selectedCountry: $selectedCountry,
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

                    if authViewModel.isLoading {
                        Color.black.opacity(0.45)
                            .ignoresSafeArea()
                            .transition(.opacity)

                        VStack(spacing: 14) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                .scaleEffect(1.3)

                            Text("Loading...")
                                .font(Font.custom("PlusJakartaSans-SemiBold", size: 15))
                                .foregroundColor(Color(hex: "#191c1d"))
                        }
                        .frame(width: 130, height: 110)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.15), value: authViewModel.isLoading)
                .coordinateSpace(name: "loginRoot")
            }
            .toolbar(.hidden, for: .navigationBar)
            .preferredColorScheme(.light)
            .navigationDestination(isPresented: $navigateToPassword) {
                PasswordEntryView(
                    contactInfo: formattedContactInfo,
                    rawContact: trimmedInput,
                    isPhoneContact: shouldShowCountrySelector,
                    authViewModel: authViewModel
                )
            }
            .navigationDestination(isPresented: $navigateToCreateAccount) {
                CreateAccountView()
            }
            .onChange(of: emailOrMobile) { _, newValue in
                handleContactInputChange(newValue)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                updateKeyboardHeight(from: notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeInOut(duration: 0.28)) {
                    keyboardHeight = 0
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .passwordUpdated)) { _ in
                navigateToPassword = false
            }
            .onAppear {
                if startAtCreateAccount {
                    navigateToCreateAccount = true
                }
            }
        }
    }

    private func heroSection(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Color.white
                .frame(height: max(geometry.safeAreaInsets.top, 59))

            ZStack(alignment: .top) {
                Color(hex: "#191c1d")

                Image("login_img")
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
                    Text("Itzeazy")
                        .font(Font.custom("PlusJakartaSans-ExtraBold", size: 24))
                        .foregroundColor(.white)
                        .tracking(-1.2)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
            .frame(height: 320)
            .onTapGesture {
                isContactFieldFocused = false
                isCountryPickerPresented = false
            }

            Spacer()
        }
        .ignoresSafeArea(edges: .top)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Login")
                .font(Font.custom("PlusJakartaSans-ExtraBold", size: 24))
                .foregroundColor(.red)
                .tracking(-0.9)

            Text("Welcome back to your Digital Concierge.")
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
                    if shouldShowCountrySelector {
                        Button {
                            isContactFieldFocused = false
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isCountryPickerPresented.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text("\(selectedCountry.isoCode) \(selectedCountry.phoneCode)")
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
                                        countryButtonFrame = proxy.frame(in: .named("loginRoot"))
                                    }
                                    .onChange(of: proxy.frame(in: .named("loginRoot"))) { _, newValue in
                                        countryButtonFrame = newValue
                                    }
                            }
                        }
                        .zIndex(3)
                    }

                    ZStack(alignment: .leading) {
                        if emailOrMobile.isEmpty {
                            Text("Enter your Email / Mobile number")
                                .font(Font.custom("Inter", size: 12))
                                .foregroundColor(Color(hex: "#c2c5cb"))
                                .padding(.horizontal, 20)
                        }

                        TextField("", text: $emailOrMobile)
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
                .animation(.easeInOut(duration: 0.2), value: shouldShowCountrySelector)

                if let emailOrMobileError {
                    Text(emailOrMobileError)
                        .font(Font.custom("Inter", size: 12))
                        .foregroundColor(.red)
                        .padding(.horizontal, 4)
                }
            }

            Button {
                isContactFieldFocused = false
                isCountryPickerPresented = false

                guard validateContactInput() else {
                    return
                }

                navigateToPassword = true
            } label: {
                Text("Continue")
                    .font(Font.custom("PlusJakartaSans-SemiBold", size: 18))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.red)
                    .clipShape(Capsule())
            }
        }
    }

    private var footerSection: some View {
        VStack(spacing: 32) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color(hex: "#e1e3e4"))
                    .frame(width: 48, height: 1)

                Text("OR")
                    .font(Font.custom("Inter", size: 12).weight(.medium))
                    .foregroundColor(Color(hex: "#5f5e5e"))
                    .tracking(1.2)

                Rectangle()
                    .fill(Color(hex: "#e1e3e4"))
                    .frame(width: 48, height: 1)
            }
            .frame(maxWidth: .infinity)

            Button {
                navigateToCreateAccount = true
            } label: {
                HStack(spacing: 9) {
                    Text("New to ItzEazy?")
                        .font(Font.custom("Inter", size: 15).weight(.medium))
                        .foregroundColor(Color(hex: "#191c1d"))

                    Text("Create your itzEazy account")
                        .font(Font.custom("Inter", size: 15).weight(.bold))
                        .foregroundColor(.red)
                }
            }
            .buttonStyle(.plain)

            AppleSignInButton(label: .signIn) { result in
                handleAppleSignInResult(result, authViewModel: authViewModel)
            }
        }
    }

    private func handleContactInputChange(_ newValue: String) {
        if newValue.rangeOfCharacter(from: .letters) == nil && !newValue.contains("@") {
            let digitsOnly = newValue.filter(\.isNumber)
            if digitsOnly != newValue {
                emailOrMobile = String(digitsOnly.prefix(15))
                return
            }

            if digitsOnly.count > 15 {
                emailOrMobile = String(digitsOnly.prefix(15))
                return
            }
        }

        emailOrMobileError = nil
    }

    private func updateKeyboardHeight(from notification: Notification) {
        guard
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else {
            return
        }

        withAnimation(.easeInOut(duration: 0.28)) {
            keyboardHeight = frame.height
        }
    }

    private func validateContactInput() -> Bool {
        let value = trimmedInput

        guard !value.isEmpty else {
            withAnimation(.easeInOut(duration: 0.2)) {
                emailOrMobileError = "Please enter your Email or Mobile number."
            }
            return false
        }

        if shouldShowCountrySelector {
            let isPhoneValid = (6...15).contains(value.count)
            withAnimation(.easeInOut(duration: 0.2)) {
                emailOrMobileError = isPhoneValid ? nil : "Please enter a valid Mobile number."
            }
            return isPhoneValid
        } else {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            let isEmailValid = emailPredicate.evaluate(with: value)

            withAnimation(.easeInOut(duration: 0.2)) {
                emailOrMobileError = isEmailValid ? nil : "Please enter a valid Email address."
            }
            return isEmailValid
        }
    }
}

private struct PasswordEntryView: View {
    @Environment(\.dismiss) private var dismiss

    let contactInfo: String
    let rawContact: String
    let isPhoneContact: Bool
    @ObservedObject var authViewModel: AuthViewModel

    @State private var password = ""
    @State private var passwordError: String?
    @State private var navigateToOTP = false
    @State private var navigateToForgotPassword = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var isPasswordVisible = false
    @State private var showLoginErrorToast = false
    @FocusState private var isPasswordFieldFocused: Bool

    private var isKeyboardPresented: Bool {
        keyboardHeight > 0
    }

    /// Extra vertical space the "Get OTP on your phone" button (plus its stack spacing)
    /// takes up, only present for phone contacts — used to grow the white card upward
    /// so the Apple Sign-In button keeps its bottom breathing room instead of being
    /// squeezed against the screen edge.
    private static let otpButtonBlockHeight: CGFloat = 76
    private static let defaultCardTopOffset: CGFloat = 288

    private var cardTopOffset: CGFloat {
        isPhoneContact ? Self.defaultCardTopOffset - Self.otpButtonBlockHeight : Self.defaultCardTopOffset
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ZStack(alignment: .top) {
                Color.white
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPasswordFieldFocused = false
                    }

                VStack(spacing: 0) {
                    Color.white
                        .frame(height: max(geometry.safeAreaInsets.top, 59))

                    ZStack(alignment: .top) {
                        Color(hex: "#191c1d")

                        Image("login_img")
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
                            Text("Itzeazy")
                                .font(Font.custom("PlusJakartaSans-ExtraBold", size: 24))
                                .foregroundColor(.white)
                                .tracking(-1.2)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                    .frame(height: 320)

                    Spacer()
                }
                .opacity(isKeyboardPresented ? 0.42 : 1)
                .offset(y: isKeyboardPresented ? -52 : 0)
                .animation(.easeInOut(duration: 0.28), value: isKeyboardPresented)
                .ignoresSafeArea(edges: .top)

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: isKeyboardPresented ? geometry.safeAreaInsets.top + 10 : cardTopOffset)

                    VStack(spacing: 32) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Login")
                                .font(Font.custom("PlusJakartaSans-ExtraBold", size: 24))
                                .foregroundColor(.red)
                                .tracking(-0.9)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(contactInfo)
                                        .font(Font.custom("Inter", size: 16).weight(.medium))
                                        .foregroundColor(Color(hex: "#5f5e5e"))

                                    Button("Change") {
                                        dismiss()
                                    }
                                    .font(Font.custom("Inter", size: 14).weight(.semibold))
                                    .foregroundColor(.red)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Password")
                                        .font(Font.custom("Inter", size: 14).weight(.semibold))
                                        .foregroundColor(Color(hex: "#191c1d"))

                                    Spacer()

                                    Button("Forgot Password") {
                                        navigateToForgotPassword = true
                                    }
                                    .font(Font.custom("Inter", size: 14).weight(.semibold))
                                    .foregroundColor(.red)
                                }

                                HStack(spacing: 0) {
                                    Group {
                                        if isPasswordVisible {
                                            TextField("Enter your password", text: $password)
                                        } else {
                                            SecureField("Enter your password", text: $password)
                                        }
                                    }
                                    .font(Font.custom("Inter", size: 14))
                                    .foregroundColor(Color(hex: "#191c1d"))
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .focused($isPasswordFieldFocused)

                                    Button {
                                        isPasswordVisible.toggle()
                                    } label: {
                                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                            .font(.system(size: 15))
                                            .foregroundColor(Color(hex: "#5f5e5e"))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 18)
                                .background(Color(hex: "#f3f4f5"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(
                                            isPasswordFieldFocused ? Color.red : Color(hex: "#b7b7b7"),
                                            lineWidth: isPasswordFieldFocused ? 1.5 : 1
                                        )
                                )
                                .cornerRadius(24)

                                if let passwordError {
                                    Text(passwordError)
                                        .font(Font.custom("Inter", size: 12))
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 4)
                                }
                            }

                            if let error = authViewModel.errorMessage {
                                Text(error)
                                    .font(Font.custom("Inter", size: 12))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Button {
                                isPasswordFieldFocused = false
                                authViewModel.errorMessage = nil

                                guard validatePassword() else { return }
                                authViewModel.loginWithPassword(
                                    username: rawContact,
                                    password: password
                                )
                            } label: {
                                Group {
                                    if authViewModel.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Login")
                                            .font(Font.custom("PlusJakartaSans-SemiBold", size: 18))
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.red)
                                .clipShape(Capsule())
                            }
                            .disabled(authViewModel.isLoading)

                            if isPhoneContact {
                                Button {
                                    isPasswordFieldFocused = false
                                    authViewModel.errorMessage = nil
                                    authViewModel.sendOTP(mobile: rawContact)
                                } label: {
                                    Group {
                                        if authViewModel.isLoading {
                                            ProgressView()
                                                .tint(.red)
                                        } else {
                                            Text("Get OTP on your phone")
                                                .font(Font.custom("PlusJakartaSans-SemiBold", size: 18))
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white)
                                    .overlay(Capsule().stroke(Color.red, lineWidth: 1))
                                }
                                .disabled(authViewModel.isLoading)
                            }
                        }

                        VStack(spacing: 32) {
                            HStack(spacing: 8) {
                                Rectangle()
                                    .fill(Color(hex: "#e1e3e4"))
                                    .frame(width: 48, height: 1)

                                Text("OR")
                                    .font(Font.custom("Inter", size: 12).weight(.medium))
                                    .foregroundColor(Color(hex: "#5f5e5e"))
                                    .tracking(1.2)

                                Rectangle()
                                    .fill(Color(hex: "#e1e3e4"))
                                    .frame(width: 48, height: 1)
                            }
                            .frame(maxWidth: .infinity)

                            NavigationLink(destination: CreateAccountView()) {
                                HStack(spacing: 9) {
                                    Text("New to ItzEazy?")
                                        .font(Font.custom("Inter", size: 15).weight(.medium))
                                        .foregroundColor(Color(hex: "#191c1d"))

                                    Text("Create your itzEazy account")
                                        .font(Font.custom("Inter", size: 15).weight(.bold))
                                        .foregroundColor(.red)
                                }
                            }

                            AppleSignInButton(label: .signIn) { result in
                                handleAppleSignInResult(result, authViewModel: authViewModel)
                            }
                        }
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

                if showLoginErrorToast, let error = authViewModel.errorMessage {
                    ToastView(icon: "exclamationmark.circle.fill", message: error)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 140)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showLoginErrorToast)
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.light)
        .navigationDestination(isPresented: $navigateToOTP) {
            EnterOTPView(
                contactInfo: contactInfo,
                rawContact: rawContact,
                isPhoneContact: isPhoneContact,
                authViewModel: authViewModel
            )
        }
        .navigationDestination(isPresented: $navigateToForgotPassword) {
            ForgotPasswordView()
        }
        .onChange(of: authViewModel.otpSent) { _, sent in
            if sent { navigateToOTP = true }
        }
        .onChange(of: authViewModel.errorMessage) { _, message in
            guard message != nil else { return }
            showLoginErrorToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showLoginErrorToast = false
            }
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

    private func validatePassword() -> Bool {
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let isValid = !trimmedPassword.isEmpty

        withAnimation(.easeInOut(duration: 0.2)) {
            passwordError = isValid ? nil : "Please enter your password."
        }

        return isValid
    }

    private func updateKeyboardHeight(from notification: Notification) {
        guard
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else {
            return
        }

        withAnimation(.easeInOut(duration: 0.28)) {
            keyboardHeight = frame.height
        }
    }
}

#Preview {
    LoginView()
}
