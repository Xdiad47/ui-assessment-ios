import SwiftUI

struct VehicleSearchCardView: View {
    @State private var vehicleNo: String = ""
    @State private var chassisNo: String = ""
    var onCheckStatus: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                inputField(
                    label: "VEHICLE NO",
                    placeholder: "HR-2620120142433",
                    text: $vehicleNo
                )
                inputField(
                    label: "CHASSIS NO (LAST 5 DIGITS)",
                    placeholder: "6933345345",
                    text: $chassisNo
                )
            }

            HStack(spacing: 8) {
                Button(action: { vehicleNo = ""; chassisNo = "" }) {
                    Text("Reset")
                        .font(Font.custom("Inter", size: 12).weight(.bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 9)
                        .frame(minWidth: 100)
                }
                .background(Color(red: 0.15, green: 0.15, blue: 0.16))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color(red: 0.88, green: 0.89, blue: 0.89).opacity(0.30), lineWidth: 0.50)
                )

                Button(action: { onCheckStatus?() }) {
                    Text("Check Status")
                        .font(Font.custom("Inter", size: 12).weight(.bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                }
                .background(Color(red: 0.93, green: 0.13, blue: 0.14))
                .clipShape(Capsule())
                .shadow(
                    color: Color(red: 0.93, green: 0.13, blue: 0.14).opacity(0.20),
                    radius: 6, y: 4
                )
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color(red: 0.10, green: 0.11, blue: 0.11))
        .cornerRadius(20)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func inputField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Font.custom("Inter", size: 9).weight(.semibold))
                .tracking(0.45)
                .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
                .fixedSize(horizontal: false, vertical: true)

            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(Font.custom("Plus Jakarta Sans", size: 12).weight(.semibold))
                        .foregroundColor(Color.white.opacity(0.40))
                        .padding(.horizontal, 12)
                }
                TextField("", text: text)
                    .font(Font.custom("Plus Jakarta Sans", size: 12).weight(.semibold))
                    .foregroundColor(Color.white.opacity(0.80))
                    .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            }
            .background(Color.white.opacity(0.10))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.20), lineWidth: 0.50)
            )
        }
        .frame(maxWidth: .infinity)
    }
}

struct VehicleSearchCardView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(white: 0.97).edgesIgnoringSafeArea(.all)
            VehicleSearchCardView()
        }
        .previewLayout(.sizeThatFits)
        .padding(.vertical)
    }
}
