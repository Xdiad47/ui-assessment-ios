import SwiftUI

private struct HomeTitleSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private struct HomeTitleSizeReader: View {
    var onChange: (CGSize) -> Void

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(key: HomeTitleSizePreferenceKey.self, value: proxy.size)
        }
        .onPreferenceChange(HomeTitleSizePreferenceKey.self, perform: onChange)
    }
}

struct HomeWorkflowView: View {
    let steps = [
        ("1", "Choose Location"),
        ("2", "Book Service"),
        ("3", "Upload Documents"),
        ("4", "Sit back & Relax")
    ]

    @State private var titleSize: CGSize = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            // Title with text-width red underline
            VStack(alignment: .leading, spacing: 6) {
                Text("How Itzeazy Works")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 24))
                    .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                    .background(
                        HomeTitleSizeReader { size in
                            if size != titleSize {
                                titleSize = size
                            }
                        }
                    )

                Rectangle()
                    .fill(Color.red)
                    .frame(width: titleSize.width, height: 2)
                    .cornerRadius(1)
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
                            .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                            .padding(.top, 4)

                        Spacer()
                    }
                }
            }

            // Illustration image with bezel frame
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.95, green: 0.95, blue: 0.95))

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
        .background(Color.white)
        .cornerRadius(30)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color(red: 0.72, green: 0.72, blue: 0.72), lineWidth: 3)
        )
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
