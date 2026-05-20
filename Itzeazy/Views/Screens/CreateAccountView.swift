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
    
    enum Field {
        case name, mobile, email, password
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Background
                Color.white
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        focusedField = nil
                    }
                
                // Top Hero Section & White Status Bar
                VStack(spacing: 0) {
                    Color.white
                        .frame(height: geometry.safeAreaInsets.top)
                    
                    ZStack(alignment: .top) {
                        // Dark gradient background
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#191c1d"), Color(hex: "#2e3132")]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        
                        // Blurred red overlay
                        Circle()
                            .fill(Color(red: 187/255, green: 0, blue: 17/255, opacity: 0.1))
                            .frame(width: 256, height: 256)
                            .blur(radius: 32)
                            .opacity(0.3)
                        
                        // Hero illustration
                        Image("create_account_image")
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: 320)
                            .clipped()
                        
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
                        focusedField = nil
                    }
                    
                    Spacer()
                }
                .edgesIgnoringSafeArea(.top)
                
                // Bottom Form Card (Fixed)
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: geometry.safeAreaInsets.top + 218)
                        
                        VStack(spacing: 16) {
                            // Title
                            HStack {
                                Text("Create Account")
                                    .font(Font.custom("PlusJakartaSans-Bold", size: 24))
                                    .foregroundColor(.red)
                                    .tracking(-0.7)
                                Spacer()
                            }
                            
                            // Input Fields
                            VStack(spacing: 12) {
                                // Name Input
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
                                
                                // Mobile Number
                                HStack(spacing: 12) {
                                    HStack {
                                        Text("IN +91")
                                            .font(Font.custom("Inter", size: 14))
                                            .foregroundColor(Color(hex: "#191c1d"))
                                    }
                                    .frame(width: 68, height: 52)
                                    .background(Color(hex: "#f3f4f5"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(hex: "#b7b7b7"), lineWidth: 1)
                                    )
                                    .cornerRadius(8)
                                    
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
                                
                                // Email Input
                                TextField("Email Address", text: $emailAddress)
                                    .font(Font.custom("Inter", size: 16))
                                    .foregroundColor(Color(hex: "#191c1d"))
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
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
                                
                                // Password Input
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
                            }
                            
                            // Action Buttons
                            VStack(spacing: 10) {
                                Button(action: {
                                    focusedField = nil
                                    // Logic for Email verification
                                    withAnimation {
                                        isLoggedIn = true
                                    }
                                }) {
                                    Text("Get verification code on Email")
                                        .font(Font.custom("Inter", size: 16).weight(.semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 52)
                                        .background(Color.red)
                                        .clipShape(Capsule())
                                        .shadow(color: Color(red: 187/255, green: 0, blue: 17/255, opacity: 0.2), radius: 15, x: 0, y: 10)
                                        .shadow(color: Color(red: 187/255, green: 0, blue: 17/255, opacity: 0.2), radius: 6, x: 0, y: 4)
                                }
                                
                                Button(action: {
                                    focusedField = nil
                                    // Logic for Mobile verification
                                }) {
                                    Text("Get verification code on Mobile")
                                        .font(Font.custom("Inter", size: 16).weight(.semibold))
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 52)
                                        .background(Color(hex: "#f3f4f5"))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color(hex: "#b7b7b7"), lineWidth: 1)
                                        )
                                        .clipShape(Capsule())
                                }
                            }
                            
                            // Footer
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
                        .padding(.bottom, 24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .background(Color.white)
                        .clipShape(CustomCorners(corners: [.topLeft, .topRight], radius: 32))
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: -10)
                    }
                    .edgesIgnoringSafeArea(.bottom)
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.light)
    }
}

#Preview {
    CreateAccountView()
}

