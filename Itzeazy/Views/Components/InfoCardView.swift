import SwiftUI

struct InfoCardView: View {
    let title: String
    let description: String
    let price: String
    let iconName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.08))
                    .frame(width: 48, height: 48)
                
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(.red)
            }
            
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
            
            Text(description)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)
                .lineSpacing(4)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FEE STARTING AT")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.gray)
                        .tracking(1)
                    
                    Text(price)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(24)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

struct InfoCardView_Previews: PreviewProvider {
    static var previews: some View {
        InfoCardView(
            title: "International Driving\nPermit",
            description: "Planning a road trip abroad? Get your IDP processed in just 48 hours.",
            price: "₹2,499",
            iconName: "medal.fill"
        )
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color(white: 0.95))
    }
}
