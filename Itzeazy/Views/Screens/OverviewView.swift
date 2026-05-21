import SwiftUI

struct OverviewView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = OverviewViewModel()

    private let backgroundColor = Color(red: 0.96, green: 0.96, blue: 0.96)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

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
                        OverviewHeaderView(strokeColor: strokeColor) {
                            presentationMode.wrappedValue.dismiss()
                        }

                        welcomeCard
                            .padding(.horizontal, 16)

                        LazyVGrid(columns: gridColumns, spacing: 16) {
                            ForEach(viewModel.cards) { card in
                                OverviewFeatureCard(item: card, strokeColor: strokeColor)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
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
        .frame(height: 68)
        .background(Color(red: 0.10, green: 0.11, blue: 0.11))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

private struct OverviewHeaderView: View {
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

                Text("Overview")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
        }
    }
}

private struct OverviewFeatureCard: View {
    let item: OverviewCardItem
    let strokeColor: Color

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 48, height: 48)

                Image(systemName: item.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.top, 20)

            Text(item.title)
                .font(Font.custom("PlusJakartaSans-Bold", size: 14))
                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                .multilineTextAlignment(.center)

            VStack(spacing: 2) {
                ForEach(item.detailLines.indices, id: \.self) { idx in
                    Text(item.detailLines[idx])
                        .font(Font.custom("Inter", size: 11))
                        .foregroundColor(Color(red: 0.37, green: 0.37, blue: 0.37))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: item.title.contains("Documents") ? 196 : 176)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(strokeColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

#Preview {
    NavigationView {
        OverviewView()
    }
}
