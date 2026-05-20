import SwiftUI

struct SplashScreenView: View {
    var onFinished: () -> Void = {}
    @State private var loadingProgress: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                // Branding Section
                VStack(spacing: 16) {
                    Image("itzeazy_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 181, height: 133)
                    
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 16, height: 1)
                        
                        Text("Gateway To Citizen Services".capitalized)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(hex: "#191c1d"))
                            .tracking(1.4)
                            .opacity(0.8)
                        
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 16, height: 1)
                    }
                }
                
                Spacer()
                
                // Bottom Loading Indicator
                VStack(spacing: 16) {
                    // Loading Track
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: .infinity)
                                .fill(Color(white: 0.88).opacity(0.5)) // fallback for rgba(225,227,228,0.1) but more visible
                                .frame(height: 4)
                            
                            RoundedRectangle(cornerRadius: .infinity)
                                .fill(Color.red)
                                .frame(width: geometry.size.width * loadingProgress, height: 4)
                                .shadow(color: Color.red.opacity(0.6), radius: 4, x: 0, y: 0)
                        }
                    }
                    .frame(height: 4)
                    
                    // Status Text
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text("ESTABLISHING SECURE CONNECTION")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: "#191c1d"))
                            .tracking(1.0)
                            .opacity(0.6)
                    }
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 60) // To account for bottom safe area spacing from 133px in design
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0)) {
                loadingProgress = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                onFinished()
            }
        }
    }
}

#Preview {
    SplashScreenView()
}

// Helper for Hex Colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
