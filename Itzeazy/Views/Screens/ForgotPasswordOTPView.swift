import SwiftUI
import Combine

struct ForgotPasswordOTPView: View {
    @Environment(\.presentationMode) private var presentationMode

    var contactInfo: String = "john.doe@email.com"
    var isPhoneContact: Bool = false

    @State private var otpText: String = ""
    @State private var navigateToCreatePassword = false
    @FocusState private var isKeyboardShowing: Bool
    @State private var keyboardHeight: CGFloat = 0
    @State private var timeRemaining = 299

    private var isKeyboardPresented: Bool {
        keyboardHeight > 0
    }

    private var otpLength: Int {
        isPhoneContact ? 4 : 6
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Color.white
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        isKeyboardShowing = false
                    }

                VStack(spacing: 0) {
                    Color.white
                        .frame(height: geometry.safeAreaInsets.top)

                    ZStack(alignment: .top) {
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#191c1d"), Color(hex: "#2e3132")]),
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        Image("otp_image")
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: 320)
                            .clipped()
                            .opacity(0.9)

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
                        isKeyboardShowing = false
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
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Enter OTP")
                                .font(Font.custom("PlusJakartaSans-ExtraBold", size: 24))
                                .foregroundColor(.red)
                                .tracking(-0.7)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Enter the \(otpLength)-digit verification code sent to")
                                    .font(Font.custom("Inter", size: 16).weight(.medium))
                                    .foregroundColor(Color(hex: "#5f5e5e"))

                                HStack(spacing: 6) {
                                    Text(contactInfo)
                                        .font(Font.custom("Inter", size: 16).weight(.bold))
                                        .foregroundColor(Color(hex: "#191c1d"))

                                    Button(action: {
                                        presentationMode.wrappedValue.dismiss()
                                    }) {
                                        Text("Change")
                                            .font(Font.custom("Inter", size: 16).weight(.bold))
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        ZStack {
                            TextField("", text: $otpText)
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .focused($isKeyboardShowing)
                                .opacity(0)
                                .onChange(of: otpText) { _, newValue in
                                    if newValue.count > otpLength {
                                        otpText = String(newValue.prefix(otpLength))
                                    }
                                }

                            HStack(spacing: 8) {
                                ForEach(0..<otpLength, id: \.self) { index in
                                    OTPBox(index: index, text: otpText, isFocused: isKeyboardShowing)
                                }
                            }
                            .onTapGesture {
                                isKeyboardShowing = true
                            }
                        }
                        .padding(.top, 8)

                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                                .foregroundColor(Color(hex: "#5f5e5e"))
                                .font(.system(size: 14))

                            HStack(spacing: 0) {
                                Text("This code will expire in ")
                                    .font(Font.custom("Inter", size: 14).weight(.medium))
                                    .foregroundColor(Color(hex: "#5f5e5e"))

                                Text(timeString(time: timeRemaining))
                                    .font(Font.custom("Inter", size: 14).weight(.bold))
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#f3f4f5"))
                        .clipShape(Capsule())
                        .padding(.top, 8)

                        VStack(spacing: 16) {
                            Button(action: {
                                isKeyboardShowing = false
                                navigateToCreatePassword = true
                            }) {
                                Text("Verify & Continue")
                                    .font(Font.custom("Inter", size: 18).weight(.bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                                    .shadow(color: Color(red: 187/255, green: 0, blue: 17/255, opacity: 0.2), radius: 15, x: 0, y: 10)
                                    .shadow(color: Color(red: 187/255, green: 0, blue: 17/255, opacity: 0.2), radius: 6, x: 0, y: 4)
                            }

                            Button(action: {
                                timeRemaining = 299
                                otpText = ""
                            }) {
                                Text("Resend OTP")
                                    .font(Font.custom("Inter", size: 18).weight(.bold))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.white)
                                    .overlay(
                                        Capsule()
                                            .stroke(Color(hex: "#b7b7b7"), lineWidth: 1)
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.top, 8)

                        HStack(spacing: 4) {
                            Text("Didn't receive the code?")
                                .font(Font.custom("Inter", size: 14).weight(.medium))
                                .foregroundColor(Color(hex: "#191c1d"))

                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Try another way")
                                    .font(Font.custom("Inter", size: 14).weight(.medium))
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    .padding(.bottom, isKeyboardPresented ? max(28, keyboardHeight - geometry.safeAreaInsets.bottom + 20) : 76)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(Color.white)
                    .clipShape(CustomCorners(corners: [.topLeft, .topRight], radius: 40))
                    .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: -10)
                }
                .offset(y: isKeyboardPresented ? -12 : 0)
                .animation(.easeInOut(duration: 0.28), value: isKeyboardPresented)
                .edgesIgnoringSafeArea(.bottom)
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.light)
        .navigationDestination(isPresented: $navigateToCreatePassword) {
            CreatePasswordView()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isKeyboardShowing = true
            }
        }
    }

    private func timeString(time: Int) -> String {
        let minutes = time / 60
        let seconds = time % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
    NavigationView {
        ForgotPasswordOTPView()
    }
}
