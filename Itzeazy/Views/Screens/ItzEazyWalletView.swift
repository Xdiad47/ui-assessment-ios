import SwiftUI

struct ItzEazyWalletView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = ItzEazyWalletViewModel()

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
                        WalletHeaderView(strokeColor: strokeColor) {
                            presentationMode.wrappedValue.dismiss()
                        }

                        titleBar
                            .padding(.horizontal, 16)

                        balanceCard
                            .padding(.horizontal, 16)

                        whatsNewCard
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var titleBar: some View {
        HStack {
            Text(viewModel.walletTitle)
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

    private var balanceCard: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.red)

            Image("wallet_illustration")
                .resizable()
                .scaledToFill()
                .frame(width: 128, height: 128)
                .clipped()
                .clipShape(RoundedCorner(radius: 40, corners: [.topLeft]))

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MY BALANCE")
                            .font(Font.custom("Inter", size: 14))
                            .foregroundColor(Color.white.opacity(0.82))

                        Text(viewModel.balanceText)
                            .font(Font.custom("PlusJakartaSans-Bold", size: 36))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text("View Transaction History")
                            .font(Font.custom("Inter", size: 12).weight(.medium))
                            .foregroundColor(Color.white.opacity(0.92))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.92))
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
    }

    private var whatsNewCard: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("What's new")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                    .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))

                RoundedRectangle(cornerRadius: 99)
                    .fill(Color.red)
                    .frame(width: 32, height: 4)
            }
            .padding(.top, 8)

            VStack(spacing: 12) {
                ForEach(viewModel.whatsNewItems) { item in
                    WalletFeatureRow(item: item)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

private struct WalletHeaderView: View {
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

                Text("ItzEazy Wallet")
                    .font(Font.custom("PlusJakartaSans-SemiBold", size: 16))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
        }
    }
}

private struct WalletFeatureRow: View {
    let item: WalletFeatureItem

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.95, green: 0.96, blue: 0.96))
                    .frame(width: 48, height: 48)

                Image(item.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(Font.custom("PlusJakartaSans-Bold", size: 15))
                    .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))

                ForEach(item.descriptionLines.indices, id: \.self) { idx in
                    Text(item.descriptionLines[idx])
                        .font(Font.custom("Inter", size: 14))
                        .foregroundColor(Color(red: 0.37, green: 0.37, blue: 0.37))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(Color(red: 0.97, green: 0.97, blue: 0.97))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.72, green: 0.72, blue: 0.72).opacity(0.8), lineWidth: 0.6)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationView {
        ItzEazyWalletView()
    }
}
