import SwiftUI

struct ServiceCardView: View {
    let service: ServiceItem
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.red.opacity(0.08))
                    .frame(width: 60, height: 60)
                
                Image(systemName: service.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.red)
            }
            
            Text(service.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 8)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

struct ServiceCardView_Previews: PreviewProvider {
    static var previews: some View {
        ServiceCardView(service: ServiceItem(title: "RTO Services", iconName: "car.fill"))
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color(white: 0.95))
    }
}
