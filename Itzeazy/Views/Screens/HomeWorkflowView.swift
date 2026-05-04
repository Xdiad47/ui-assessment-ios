import SwiftUI

struct HomeWorkflowView: View {
    let steps = [
        ("1", "Choose Location"),
        ("2", "Book Service"),
        ("3", "Upload Documents"),
        ("4", "Sit back & Relax")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            // Title with full-width red underline
            VStack(alignment: .leading, spacing: 6) {
                Text("How Itzeazy Works")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 24))
                    .foregroundColor(.white)
                Rectangle()
                    .fill(Color.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 2)
            }

            // Steps with vertical timeline connector
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 20) {

                        // Circle + connecting line column
                        VStack(spacing: 0) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.93, green: 0.13, blue: 0.14))
                                    .frame(width: 28, height: 28)
                                Text(step.0)
                                    .font(Font.custom("Inter-Bold", size: 12))
                                    .foregroundColor(.white)
                            }
                            if index < steps.count - 1 {
                                Rectangle()
                                    .fill(Color(red: 0.93, green: 0.13, blue: 0.14).opacity(0.30))
                                    .frame(width: 2, height: 40)
                            }
                        }

                        Text(step.1)
                            .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                            .foregroundColor(.white)
                            .padding(.top, 4)

                        Spacer()
                    }
                }
            }

            // Illustration image with bezel frame
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.20, green: 0.20, blue: 0.20))

                Image("how_itzeazy_works")
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 224)
        }
        .padding(24)
        //.frame(maxWidth: .infinity)
        .background(Color(red: 0.05, green: 0.05, blue: 0.05))
        .cornerRadius(30)
//        .overlay(
//            RoundedRectangle(cornerRadius: 40)
//                .stroke(Color.white.opacity(0.08), lineWidth: 1)
//        )
        //.padding(.horizontal)
    }
}

struct HomeWorkflowView_Previews: PreviewProvider {
    static var previews: some View {
        HomeWorkflowView()
            .padding(.vertical, 32)
            //.background(Color(red: 0.11, green: 0.11, blue: 0.11))
            .previewLayout(.sizeThatFits)
    }
}
