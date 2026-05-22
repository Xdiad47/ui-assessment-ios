import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var naturalHeight: CGFloat = 0

    private let backgroundColor = Color(red: 0.96, green: 0.96, blue: 0.96)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color(red: 0.10, green: 0.11, blue: 0.11).ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 14) {
                        ProfileHeaderView(strokeColor: strokeColor)

                        VStack(spacing: 14) {
                            ForEach(Array(viewModel.primarySections.enumerated()), id: \.offset) { _, section in
                                ProfileMenuCardView(items: section, strokeColor: strokeColor)
                            }

                            ProfileSocialCardView(items: viewModel.socialItems, strokeColor: strokeColor)

                            Button(action: {
                                // Logout action
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("Logout")
                                        .font(Font.custom("Inter", size: 14).weight(.semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.red)
                                .clipShape(Capsule())
                            }
                            .padding(.horizontal, 14)
                            .padding(.top, 6)
                            .padding(.bottom, 120)
                        }
                        .padding(.horizontal, 14)
                    }
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: ContentHeightKey.self, value: geo.size.height)
                    })
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .top)
                    .background(backgroundColor)
                }
                .scrollDisabled(naturalHeight <= proxy.size.height)
                .onPreferenceChange(ContentHeightKey.self) { naturalHeight = $0 }
            }
        }
        .navigationBarHidden(true)
    }

    private struct ContentHeightKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
}

private struct ProfileHeaderView: View {
    let strokeColor: Color

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
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)

                Text("Profile")
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
        }
    }
}

private struct ProfileMenuCardView: View {
    let items: [ProfileMenuItem]
    let strokeColor: Color

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if item.title == "Overview" {
                    NavigationLink(destination: OverviewView()) {
                        ProfileMenuRowView(item: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else if item.title == "My Orders" {
                    NavigationLink(destination: MyOrdersView()) {
                        ProfileMenuRowView(item: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else if item.title == "Payment" {
                    NavigationLink(destination: PaymentsView()) {
                        ProfileMenuRowView(item: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else if item.title == "ItzEazy Wallet" {
                    NavigationLink(destination: ItzEazyWalletView()) {
                        ProfileMenuRowView(item: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else if item.title == "My Address" {
                    NavigationLink(destination: MyAddressView()) {
                        ProfileMenuRowView(item: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else if item.title == "Video Tutorials" {
                    NavigationLink(destination: VideoTutorialsView()) {
                        ProfileMenuRowView(item: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    ProfileMenuRowView(item: item)
                }

                if index != items.count - 1 {
                    Divider()
                        .overlay(Color.black.opacity(0.04))
                }
            }
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(strokeColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct ProfileMenuRowView: View {
    let item: ProfileMenuItem

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.red)
                .frame(width: 20)

            Text(item.title)
                .font(Font.custom("PlusJakartaSans-SemiBold", size: 15))
                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(red: 0.73, green: 0.71, blue: 0.71))
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Color.white)
    }
}

private struct ProfileSocialCardView: View {
    let items: [ProfileMenuItem]
    let strokeColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Connect with us")
                .font(Font.custom("Plus Jakarta Sans", size: 14).weight(.bold))
                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))

            HStack(spacing: 8) {
                ForEach(items) { item in
                    VStack(spacing: 4) {
                        Image(socialIconName(for: item.title))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 34, height: 34)

                        Text(item.title)
                            .font(Font.custom("Plus Jakarta Sans", size: 10).weight(.semibold))
                            .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(strokeColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func socialIconName(for platform: String) -> String {
        switch platform {
        case "Instagram":
            return "instagram"
        case "Facebook":
            return "facebook"
        case "Whatsapp":
            return "whatsapp"
        case "Youtube":
            return "youtube"
        case "LinkedIn":
            return "linkedin"
        default:
            return "instagram"
        }
    }
}

#Preview {
    ProfileView()
}
