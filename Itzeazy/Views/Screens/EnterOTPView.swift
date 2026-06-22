import SwiftUI
import Combine

struct EnterOTPView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    // We'll receive the contact info (email or mobile) from the previous screen
    var contactInfo: String = "john.doe@email.com"
    
    @State private var otpText: String = ""
    @FocusState private var isKeyboardShowing: Bool
    
    // Timer properties
    @State private var timeRemaining = 299 // 4:59 in seconds

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Background
                Color.white
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        isKeyboardShowing = false
                    }
                
                // Top Hero Section & White Status Bar
                VStack(spacing: 0) {
                    Color.white
                        .frame(height: geometry.safeAreaInsets.top)
                    
                    ZStack(alignment: .top) {
                        // Background gradient
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#191c1d"), Color(hex: "#2e3132")]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        
                        // Hero illustration
                        Image("otp_image")
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: 320)
                            .clipped()
                            .opacity(0.9)
                        
                        // Back arrow button
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
                        
                        // Itzeazy branding
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
                .edgesIgnoringSafeArea(.top)
                
                // Bottom Form Card
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: geometry.safeAreaInsets.top + 218)
                    
                    VStack(spacing: 16) {
                        // Header
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Enter OTP")
                                .font(Font.custom("PlusJakartaSans-ExtraBold", size: 24))
                                .foregroundColor(.red)
                                .tracking(-0.7)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Enter the 6-digit verification code sent to")
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
                        
                        // OTP Input Area
                        ZStack {
                            // Invisible text field for handling input
                            TextField("", text: $otpText)
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .focused($isKeyboardShowing)
                                .opacity(0)
                                .onChange(of: otpText) { newValue in
                                    if newValue.count > 6 {
                                        otpText = String(newValue.prefix(6))
                                    }
                                }
                            
                            // Visual OTP Boxes
                            HStack(spacing: 8) {
                                ForEach(0..<6, id: \.self) { index in
                                    OTPBox(index: index, text: otpText, isFocused: isKeyboardShowing)
                                }
                            }
                            .onTapGesture {
                                isKeyboardShowing = true
                            }
                        }
                        .padding(.top, 8)
                        
                        // Timer Section
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
                        
                        // Action Buttons
                        VStack(spacing: 16) {
                            Button(action: {
                                isKeyboardShowing = false
                                withAnimation {
                                    isLoggedIn = true
                                }
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
                                // Resend OTP Logic
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
                        
                        // Footer
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
                    .padding(.bottom, 76)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(Color.white)
                    .clipShape(CustomCorners(corners: [.topLeft, .topRight], radius: 40))
                    .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: -10)
                }
                .edgesIgnoringSafeArea(.bottom)
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.light)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isKeyboardShowing = true
            }
        }
    }
    
    // Helper to format time
    func timeString(time: Int) -> String {
        let minutes = time / 60
        let seconds = time % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct OTPBox: View {
    var index: Int
    var text: String
    var isFocused: Bool
    
    var body: some View {
        let char = character(at: index)
        let isActive = isFocused && text.count == index
        let isFilled = !char.isEmpty
        
        Text(char)
            .font(Font.custom("Inter", size: 24).weight(.bold))
            .foregroundColor(Color(hex: "#191c1d"))
            .frame(width: 48, height: 56)
            .background(Color(hex: "#f3f4f5"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive || isFilled ? Color.blue : Color.red.opacity(0.3), lineWidth: isActive || isFilled ? 1.5 : 1)
            )
    }
    
    func character(at index: Int) -> String {
        guard index < text.count else { return "" }
        let stringIndex = text.index(text.startIndex, offsetBy: index)
        return String(text[stringIndex])
    }
}

#Preview {
    NavigationView {
        EnterOTPView()
    }
}
