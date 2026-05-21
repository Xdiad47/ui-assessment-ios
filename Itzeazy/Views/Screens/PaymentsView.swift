import SwiftUI

struct PaymentsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = PaymentsViewModel()

    private let backgroundColor = Color(red: 0.96, green: 0.96, blue: 0.96)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                backgroundColor.ignoresSafeArea()

                Color(red: 0.10, green: 0.11, blue: 0.11)
                    .frame(height: proxy.safeAreaInsets.top)
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(edges: .top)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        PaymentsHeaderView(strokeColor: strokeColor) {
                            presentationMode.wrappedValue.dismiss()
                        }

                        welcomeCard
                            .padding(.horizontal, 16)

                        sectionHeaderCard
                            .padding(.horizontal, 16)

                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var welcomeCard: some View {
        HStack {
            Text("Welcome, \(viewModel.welcomeName)")
                .font(Font.custom("PlusJakartaSans-SemiBold", size: 16))
                .foregroundColor(.white)

            Spacer()

            Button(action: {
                // Book Service action
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("Book Service")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 12))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(Color.red)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
        .background(Color(red: 0.10, green: 0.11, blue: 0.11))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var sectionHeaderCard: some View {
        HStack {
            Text(viewModel.sectionTitle)
                .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
            Spacer()
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(strokeColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct PaymentsHeaderView: View {
    let strokeColor: Color
    let onBack: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(strokeColor)
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
                .padding(.horizontal, 1)

            Color(red: 0.10, green: 0.11, blue: 0.11)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))

            HStack(spacing: 12) {
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                }

                Text("Payments")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
        }
    }
}

#Preview {
    NavigationView {
        PaymentsView()
    }
}
