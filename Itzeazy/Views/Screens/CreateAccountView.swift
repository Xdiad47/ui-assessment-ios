import SwiftUI

struct CreateAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @State private var name: String = ""
    @State private var mobileNumber: String = ""
    @State private var emailAddress: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @FocusState private var focusedField: Field?
    
    @StateObject private var registerViewModel = RegisterViewModel()

    @State private var navigateToOTP: Bool = false
    @State private var selectedContactInfo: String = ""
    @State private var selectedOTPIsPhoneContact: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var selectedCountry: CountryInfo = countries.first(where: { $0.isoCode == "IN" }) ?? countries[0]
    @State private var isCountryPickerPresented = false
    @State private var countryButtonFrame: CGRect = .zero
    @State private var nameError: String?
    @State private var mobileError: String?
    @State private var emailError: String?
    @State private var passwordError: String?
    
    enum Field {
        case name, mobile, email, password
    }

    private var isKeyboardPresented: Bool {
        keyboardHeight > 0
    }

    private let countryDropdownWidth: CGFloat = 220
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Color.white
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        dismissInputUI()
                    }

                VStack(spacing: 0) {
                    Color.white
                        .frame(height: max(geometry.safeAreaInsets.top, 59))
                    
                    ZStack(alignment: .top) {
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#191c1d"), Color(hex: "#2e3132")]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        
                        Circle()
                            .fill(Color(red: 187/255, green: 0, blue: 17/255, opacity: 0.1))
                            .frame(width: 256, height: 256)
                            .blur(radius: 32)
                            .opacity(0.3)
                        
                        Image("create_account_image")
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: 320)
                            .clipped()
                        
                        HStack {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
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
                    .onTapGesture {
                        focusedField = nil
                    }
                    
                    Spacer()
                }
                .opacity(isKeyboardPresented ? 0.42 : 1)
                .offset(y: isKeyboardPresented ? -52 : 0)
                .animation(.easeInOut(duration: 0.28), value: isKeyboardPresented)
                .edgesIgnoringSafeArea(.top)
                
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: isKeyboardPresented ? geometry.safeAreaInsets.top + 10 : geometry.safeAreaInsets.top + 218)
                        
                    VStack(spacing: 16) {
                            HStack {
                                Text("Create Account")
                                    .font(Font.custom("PlusJakartaSans-Bold", size: 24))
                                    .foregroundColor(.red)
                                    .tracking(-0.7)
                                Spacer()
                            }
                            
                            VStack(spacing: 12) {
                                TextField("Your Name", text: $name)
                                    .font(Font.custom("Inter", size: 16))
                                    .foregroundColor(Color(hex: "#191c1d"))
                                    .focused($focusedField, equals: .name)
                                    .padding(.horizontal, 20)
                                    .frame(height: 52)
                                    .background(Color(hex: "#f3f4f5"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(focusedField == .name ? Color.red : Color(hex: "#b7b7b7"), lineWidth: focusedField == .name ? 1.5 : 1)
                                    )
                                    .cornerRadius(8)
                                    .animation(.easeInOut(duration: 0.2), value: focusedField)

                                if let nameError {
                                    errorLabel(nameError)
                                }
                                
                                HStack(spacing: 12) {
                                    Button {
                                        focusedField = nil
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            isCountryPickerPresented.toggle()
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text("\(selectedCountry.isoCode) \(selectedCountry.phoneCode)")
                                                .font(Font.custom("Inter", size: 14))
                                                .foregroundColor(Color(hex: "#191c1d"))
                                                .lineLimit(1)

                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(Color(hex: "#191c1d"))
                                        }
                                        .frame(width: 88, height: 52)
                                        .background(Color(hex: "#f3f4f5"))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color(hex: "#b7b7b7"), lineWidth: 1)
                                        )
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                    .frame(width: 88, height: 52)
                                    .background {
                                        GeometryReader { proxy in
                                            Color.clear
                                                .onAppear {
                                                    countryButtonFrame = proxy.frame(in: .named("createAccountRoot"))
                                                }
                                                .onChange(of: proxy.frame(in: .named("createAccountRoot"))) { _, newValue in
                                                    countryButtonFrame = newValue
                                                }
                                        }
                                    }
                                    
                                    TextField("Mobile Number", text: $mobileNumber)
                                        .font(Font.custom("Inter", size: 16))
                                        .foregroundColor(Color(hex: "#191c1d"))
                                        .keyboardType(.numberPad)
                                        .focused($focusedField, equals: .mobile)
                                        .padding(.horizontal, 20)
                                        .frame(height: 52)
                                        .background(Color(hex: "#f3f4f5"))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(focusedField == .mobile ? Color.red : Color(hex: "#b7b7b7"), lineWidth: focusedField == .mobile ? 1.5 : 1)
                                        )
                                        .cornerRadius(8)
                                        .animation(.easeInOut(duration: 0.2), value: focusedField)
                                }

                                if let mobileError {
                                    errorLabel(mobileError)
                                }
                                
                                TextField("Email Address", text: $emailAddress)
                                    .font(Font.custom("Inter", size: 16))
                                    .foregroundColor(Color(hex: "#191c1d"))
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .focused($focusedField, equals: .email)
                                    .padding(.horizontal, 20)
                                    .frame(height: 52)
                                    .background(Color(hex: "#f3f4f5"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(focusedField == .email ? Color.red : Color(hex: "#b7b7b7"), lineWidth: focusedField == .email ? 1.5 : 1)
                                    )
                                    .cornerRadius(8)
                                    .animation(.easeInOut(duration: 0.2), value: focusedField)

                                if let emailError {
                                    errorLabel(emailError)
                                }
                                
                                HStack {
                                    if showPassword {
                                        TextField("Set Password", text: $password)
                                            .font(Font.custom("Inter", size: 16))
                                            .foregroundColor(Color(hex: "#191c1d"))
                                            .focused($focusedField, equals: .password)
                                    } else {
                                        SecureField("Set Password", text: $password)
                                            .font(Font.custom("Inter", size: 16))
                                            .foregroundColor(Color(hex: "#191c1d"))
                                            .focused($focusedField, equals: .password)
                                    }
                                    
                                    Button(action: {
                                        showPassword.toggle()
                                    }) {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .foregroundColor(Color.gray.opacity(0.6))
                                            .frame(width: 22, height: 15)
                                    }
                                }
                                .padding(.leading, 20)
                                .padding(.trailing, 20)
                                .frame(height: 52)
                                .background(Color(hex: "#f3f4f5"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(focusedField == .password ? Color.red : Color(hex: "#b7b7b7"), lineWidth: focusedField == .password ? 1.5 : 1)
                                )
                                .cornerRadius(8)
                                .animation(.easeInOut(duration: 0.2), value: focusedField)

                                if let passwordError {
                                    errorLabel(passwordError)
                                }
                            }
                            
                            VStack(spacing: 10) {
                                Button(action: {
                                    dismissInputUI()
                                    guard validateForm() else { return }
                                    let trimmedEmail = emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)
                                    registerViewModel.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                                    registerViewModel.email = trimmedEmail
                                    registerViewModel.mobile = mobileNumber
                                    registerViewModel.password = password
                                    selectedContactInfo = trimmedEmail
                                    selectedOTPIsPhoneContact = false
                                    registerViewModel.sendEmailOTP()
                                }) {
                                    Group {
                                        if registerViewModel.isLoading && !selectedOTPIsPhoneContact {
                                            ProgressView().tint(.white)
                                        } else {
                                            Text("Get verification code on Email")
                                                .font(Font.custom("Inter", size: 16).weight(.semibold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(registerViewModel.isLoading && !selectedOTPIsPhoneContact ? Color.red.opacity(0.7) : Color.red)
                                    .clipShape(Capsule())
                                    .shadow(color: Color(red: 187/255, green: 0, blue: 17/255, opacity: 0.2), radius: 15, x: 0, y: 10)
                                    .shadow(color: Color(red: 187/255, green: 0, blue: 17/255, opacity: 0.2), radius: 6, x: 0, y: 4)
                                }
                                .disabled(registerViewModel.isLoading)

                                Button(action: {
                                    dismissInputUI()
                                    guard validateForm() else { return }
                                    registerViewModel.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                                    registerViewModel.email = emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)
                                    registerViewModel.mobile = mobileNumber
                                    registerViewModel.password = password
                                    selectedContactInfo = "\(selectedCountry.phoneCode) \(mobileNumber)"
                                    selectedOTPIsPhoneContact = true
                                    registerViewModel.sendMobileOTP()
                                }) {
                                    Group {
                                        if registerViewModel.isLoading && selectedOTPIsPhoneContact {
                                            ProgressView().tint(.red)
                                        } else {
                                            Text("Get verification code on Mobile")
                                                .font(Font.custom("Inter", size: 16).weight(.semibold))
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(Color(hex: "#f3f4f5"))
                                    .overlay(Capsule().stroke(Color(hex: "#b7b7b7"), lineWidth: 1))
                                    .clipShape(Capsule())
                                }
                                .disabled(registerViewModel.isLoading)

                                if let error = registerViewModel.errorMessage {
                                    Text(error)
                                        .font(Font.custom("Inter", size: 13).weight(.medium))
                                        .foregroundColor(.red)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 4)
                                }
                            }
                            
                            HStack(spacing: 4) {
                                Text("Already have an account?")
                                    .font(Font.custom("Inter", size: 14).weight(.medium))
                                    .foregroundColor(Color(hex: "#191c1d"))
                                Button(action: {
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Text("Login to your account")
                                        .font(Font.custom("Inter", size: 14).weight(.bold))
                                        .foregroundColor(.red)
                                }
                            }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 18)
                    .padding(.bottom, isKeyboardPresented ? max(28, keyboardHeight - geometry.safeAreaInsets.bottom + 20) : 42)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(Color.white.ignoresSafeArea(.container, edges: .bottom))
                    .clipShape(CustomCorners(corners: [.topLeft, .topRight], radius: 32))
                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: -10)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissInputUI()
                    }
                }
                .offset(y: isKeyboardPresented ? -12 : 0)
                .animation(.easeInOut(duration: 0.28), value: isKeyboardPresented)
                .edgesIgnoringSafeArea(.bottom)

                if isCountryPickerPresented {
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
            }
            .coordinateSpace(name: "createAccountRoot")
            .edgesIgnoringSafeArea(.top)
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.light)
        .navigationDestination(isPresented: $navigateToOTP) {
            RegisterOTPView(
                contactInfo: selectedContactInfo,
                isPhoneContact: selectedOTPIsPhoneContact,
                registerViewModel: registerViewModel
            )
        }
        .onChange(of: registerViewModel.otpSent) { _, sent in
            if sent { navigateToOTP = true }
        }
        .onChange(of: name) { _, _ in
            nameError = nil
        }
        .onChange(of: mobileNumber) { _, newValue in
            let digitsOnly = newValue.filter(\.isNumber)
            if digitsOnly != newValue {
                mobileNumber = String(digitsOnly.prefix(15))
                return
            }

            if digitsOnly.count > 15 {
                mobileNumber = String(digitsOnly.prefix(15))
                return
            }

            mobileError = nil
        }
        .onChange(of: emailAddress) { _, _ in
            emailError = nil
        }
        .onChange(of: password) { _, _ in
            passwordError = nil
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

    private func dismissInputUI() {
        focusedField = nil
        isCountryPickerPresented = false
    }

    private func validateForm() -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        var isValid = true

        if trimmedName.isEmpty {
            nameError = "Please enter your name."
            isValid = false
        }

        if mobileNumber.isEmpty {
            mobileError = "Please enter your mobile number."
            isValid = false
        } else if !(6...15).contains(mobileNumber.count) {
            mobileError = "Please enter a valid mobile number."
            isValid = false
        }

        if trimmedEmail.isEmpty {
            emailError = "Please enter your email address."
            isValid = false
        } else {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            if !emailPredicate.evaluate(with: trimmedEmail) {
                emailError = "Please enter a valid email address."
                isValid = false
            }
        }

        if trimmedPassword.isEmpty {
            passwordError = "Please set your password."
            isValid = false
        }

        return isValid
    }

    private func errorLabel(_ text: String) -> some View {
        Text(text)
            .font(Font.custom("Inter", size: 12))
            .foregroundColor(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }
}

#Preview {
    NavigationView {
        CreateAccountView()
    }
}
