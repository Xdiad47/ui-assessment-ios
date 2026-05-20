import SwiftUI

struct LoginView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @State private var emailOrMobile: String = ""
    @State private var navigateToCreateAccount = false
    @FocusState private var isInputFocused: Bool
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    // Background
                    Color.white
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            isInputFocused = false
                        }
                    
                    // Top Illustration Section & White Status Bar
                    VStack(spacing: 0) {
                        Color.white
                            .frame(height: geometry.safeAreaInsets.top)
                        
                        ZStack(alignment: .top) {
                            Color(hex: "#191c1d")
                            
                            Image("login_img")
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width, height: 320)
                                .clipped()
                                .opacity(0.9)
                            
                            // Top gradient overlay
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
                            isInputFocused = false
                        }
                        
                        Spacer()
                    }
                    .edgesIgnoringSafeArea(.top)
                    
                    // Bottom Card Section
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: geometry.safeAreaInsets.top + 218) // Adjust to overlap image dynamically
                        
                        VStack(spacing: 32) {
                            // Headline
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
                            
                            // Form
                            VStack(spacing: 28) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Email or Mobile Number")
                                        .font(Font.custom("Inter", size: 14).weight(.semibold))
                                        .foregroundColor(Color(hex: "#191c1d"))
                                    
                                    HStack {
                                        TextField("Enter your Email / Mobile number", text: $emailOrMobile)
                                            .font(Font.custom("Inter", size: 16))
                                            .foregroundColor(Color(hex: "#191c1d"))
                                            .keyboardType(.emailAddress)
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                            .focused($isInputFocused)
                                        
                                        Image(systemName: "person")
                                            .foregroundColor(isInputFocused ? .red : Color.gray.opacity(0.4))
                                            .scaleEffect(isInputFocused ? 1.1 : 1.0)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isInputFocused)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 18)
                                    .background(Color(hex: "#f3f4f5"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(isInputFocused ? Color.red : Color(hex: "#b7b7b7"), lineWidth: isInputFocused ? 1.5 : 1)
                                    )
                                    .cornerRadius(24)
                                    .animation(.easeInOut(duration: 0.2), value: isInputFocused)
                                    
                                    if let errorMessage = errorMessage {
                                        Text(errorMessage)
                                            .font(Font.custom("Inter", size: 12))
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 4)
                                            .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }
                                
                                Button(action: {
                                    isInputFocused = false
                                    withAnimation {
                                        isLoggedIn = true
                                    }
                                }) {
                                    Text("Continue")
                                        .font(Font.custom("PlusJakartaSans-SemiBold", size: 18))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.red)
                                        .clipShape(Capsule())
                                        .shadow(color: Color.red.opacity(0.3), radius: 10, x: 0, y: 5)
                                }
                            }
                            
                            // Footer Links
                            VStack(spacing: 32) {
                                HStack {
                                    Rectangle()
                                        .fill(Color(hex: "#e1e3e4"))
                                        .frame(height: 1)
                                    Text("OR")
                                        .font(Font.custom("Inter", size: 12).weight(.medium))
                                        .foregroundColor(Color(hex: "#5f5e5e"))
                                        .tracking(1.2)
                                        .padding(.horizontal, 8)
                                    Rectangle()
                                        .fill(Color(hex: "#e1e3e4"))
                                        .frame(height: 1)
                                }
                                
                                NavigationLink(destination: CreateAccountView(), isActive: $navigateToCreateAccount) {
                                    HStack(spacing: 4) {
                                        Text("New to ItzEazy?")
                                            .font(Font.custom("Inter", size: 15).weight(.medium))
                                            .foregroundColor(Color(hex: "#191c1d"))
                                        Text("Create your itzEazy account")
                                            .font(Font.custom("Inter", size: 15).weight(.bold))
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 32)
                        .padding(.bottom, 48)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .background(Color.white)
                        .clipShape(CustomCorners(corners: [.topLeft, .topRight], radius: 40))
                        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: -10)
                    }
                    .edgesIgnoringSafeArea(.bottom)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(.light)
    }
    
    private func validateInput() -> Bool {
        let input = emailOrMobile.trimmingCharacters(in: .whitespacesAndNewlines)
        if input.isEmpty {
            withAnimation {
                errorMessage = "Please enter your Email or Mobile number."
            }
            return false
        }
        
        let mobileRegex = "^[0-9]{10}$"
        let mobilePredicate = NSPredicate(format: "SELF MATCHES %@", mobileRegex)
        let isMobile = mobilePredicate.evaluate(with: input)
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        let isEmail = emailPredicate.evaluate(with: input)
        
        if isMobile || isEmail {
            withAnimation {
                errorMessage = nil
            }
            return true
        } else {
            withAnimation {
                errorMessage = "Please enter a valid Email or 10-digit Mobile number."
            }
            return false
        }
    }
}

#Preview {
    LoginView()
}


