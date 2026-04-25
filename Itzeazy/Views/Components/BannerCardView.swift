import SwiftUI

struct BannerCardView: View {
    let tag: String
    let title: String
    let subtitle: String
    let buttonText: String
    let backgroundImage: String
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background Image or Fallback Color
            Group {
                if UIImage(named: backgroundImage) != nil {
                    Image(backgroundImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    // Fallback gradient if image is missing
                    LinearGradient(
                        gradient: Gradient(colors: [Color.gray.opacity(0.8), Color.black]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .frame(height: 280)
            .frame(maxWidth: .infinity)
            
            // Gradient Overlay
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.1), Color.black.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 280)
            .frame(maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 12) {
                // Tag
                Text(tag)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red)
                    .cornerRadius(8)
                
                // Title
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Subtitle
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.trailing, 40)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                // Button
                Button(action: {
                    // Start now action
                }) {
                    Text(buttonText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(24)
                }
            }
            .padding(24)
        }
        .frame(height: 280)
        .cornerRadius(24)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct BannerCardView_Previews: PreviewProvider {
    static var previews: some View {
        BannerCardView(
            tag: "HOTTEST CHOICE",
            title: "Driving License\nRenewal",
            subtitle: "Skip the queues at the RTO. 100% online process with doorstep delivery.",
            buttonText: "Start Now",
            backgroundImage: "banner_bg"
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
