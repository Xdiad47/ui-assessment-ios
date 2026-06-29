import SwiftUI

struct ToastView: View {
    let icon: String
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.93, green: 0.13, blue: 0.14))
                .frame(width: 32, height: 32)
                .background(Color(red: 0.93, green: 0.13, blue: 0.14).opacity(0.12))
                .clipShape(Circle())

            Text(message)
                .font(Font.custom("Inter", size: 13).weight(.medium))
                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.14), radius: 16, x: 0, y: 6)
        .padding(.horizontal, 20)
    }
}
