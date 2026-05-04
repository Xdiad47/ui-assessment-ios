import SwiftUI

struct HomeValuePropositionView: View {

    // (label, SF Symbol name)
    let props: [(String, String)] = [
        ("Reliable",              "checkmark.seal.fill"),
        ("Expert\nConsultation",  "brain.head.profile"),
        ("Timely Delivery",       "bolt.fill"),
        ("Door Step\nDelivery",   "building.2.fill")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // ── Title ──────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 0) {
                Text("Why Choose Itzeazy")
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 24))
                    .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))

                Rectangle()
                    .fill(Color.red)
                    .frame(width: 225)
                    .frame(height: 2)
            }

            // ── 2 × 2 Card Grid ────────────────────────────────────
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 16),
                          GridItem(.flexible(), spacing: 16)],
                spacing: 16
            ) {
                ForEach(props, id: \.0) { prop in
                    PropCard(label: prop.0, icon: prop.1)
                }
            }
        }
        .padding(EdgeInsets(top: 24, leading: 24, bottom: 30, trailing: 24))
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color(red: 0.894, green: 0.894, blue: 0.894),
                            Color(red: 0.729, green: 0.729, blue: 0.729)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
       // .padding(.horizontal, 16)
        .padding(.bottom, 82)
    }
}

// MARK: - Individual Card

private struct PropCard: View {
    let label: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Icon
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundColor(Color(red: 0.93, green: 0.13, blue: 0.14))

            // Label
            Text(label)
                .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 1)
    }
}

// MARK: - Preview

struct HomeValuePropositionView_Previews: PreviewProvider {
    static var previews: some View {
        HomeValuePropositionView()
            .padding(.vertical, 32)
            //.background(Color(red: 0.94, green: 0.94, blue: 0.94))
            .previewLayout(.sizeThatFits)
    }
}
