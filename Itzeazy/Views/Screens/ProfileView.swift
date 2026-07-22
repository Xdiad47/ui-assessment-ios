import SwiftUI

//Here enable web view for the My orders, payment screens etc, and remove old ones. Use links and input web generate token API
//In bottom nav bar enable My Orders button to launch web view (website) with web generate token API,
//In Visa Apply now button should launch web view

struct ProfileView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject private var userSession: UserSessionViewModel
    @EnvironmentObject private var authGate: AuthGateController
    @State private var naturalHeight: CGFloat = 0
    @State private var showDeleteConfirmation = false
    let onBackToHome: (() -> Void)?

    private let backgroundColor = Color(red: 0.96, green: 0.96, blue: 0.96)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color(red: 0.10, green: 0.11, blue: 0.11).ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 14) {
                        ProfileHeaderView(strokeColor: strokeColor, onBackToHome: onBackToHome)

                        ProfileUserInfoCardView(
                            name: userSession.displayFullName,
                            email: userSession.displayEmail,
                            strokeColor: strokeColor
                        )
                        .padding(.horizontal, 14)

                        VStack(spacing: 14) {
                            ForEach(Array(viewModel.primarySections.enumerated()), id: \.offset) { _, section in
                                ProfileMenuCardView(items: section, strokeColor: strokeColor, onBackToHome: onBackToHome)
                            }

                            ProfileSocialCardView(items: viewModel.socialItems, strokeColor: strokeColor)

                            Button(action: {
                                withAnimation {
                                    isLoggedIn = false
                                }
                                authGate.chooseLogin()
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

                            Button(action: { showDeleteConfirmation = true }) {
                                HStack(spacing: 8) {
                                    if userSession.isDeletingAccount {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image("delete_button_icon")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 16, height: 16)
                                    }

                                    Text("Delete Account")
                                        .font(Font.custom("Inter", size: 14).weight(.semibold))
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .frame(height: 24)
                            }
                            .disabled(userSession.isDeletingAccount)
                            .padding(.top, 4)
                            .padding(.bottom, 80)
                            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                                Button("Cancel", role: .cancel) {}
                                Button("Yes, Delete", role: .destructive) {
                                    userSession.deleteAccount()
                                }
                            } message: {
                                Text("This will permanently remove your account and all your data. This action cannot be undone.")
                            }
                            .alert("Something went wrong", isPresented: Binding(
                                get: { userSession.deleteError != nil },
                                set: { if !$0 { userSession.deleteError = nil } }
                            )) {
                                Button("OK", role: .cancel) {}
                            } message: {
                                Text(userSession.deleteError ?? "")
                            }
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

private struct ProfileUserInfoCardView: View {
    let name: String
    let email: String
    let strokeColor: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.15))
                    .frame(width: 52, height: 52)

                Text(
                    name.components(separatedBy: " ")
                        .prefix(2)
                        .compactMap { $0.first.map { String($0) } }
                        .joined()
                        .uppercased()
                )
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 22))
                    .foregroundColor(.red)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(name.isEmpty ? "—" : name)
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 16))
                    .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                    .lineLimit(1)

                Text(email.isEmpty ? "—" : email)
                    .font(Font.custom("Inter", size: 13).weight(.medium))
                    .foregroundColor(Color(red: 0.37, green: 0.37, blue: 0.37))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(strokeColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct ProfileHeaderView: View {
    @Environment(\.dismiss) private var dismiss
    let strokeColor: Color
    let onBackToHome: (() -> Void)?

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
                Button {
                    if let onBackToHome {
                        onBackToHome()
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)

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
    let onBackToHome: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if item.title == "Overview" {
                    NavigationLink(destination: OverviewView(onBackToHome: onBackToHome)) {
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
                    NavigationLink(destination: MyAddressView(onBackToHome: onBackToHome)) {
                        ProfileMenuRowView(item: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else if item.title == "Video Tutorials" {
                    NavigationLink(destination: VideoTutorialsView()) {
                        ProfileMenuRowView(item: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else if item.title == "FAQs" {
                    NavigationLink(destination: FAQsView()) {
                        ProfileMenuRowView(item: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else if item.title == "Help & Support" {
                    NavigationLink(destination: HelpSupportView()) {
                        ProfileMenuRowView(item: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else if item.title == "Shipping Details" {
                    NavigationLink(destination: CitizenServicesWebView(url: "https://itzeazy.in/shipping-policy", title: "Shipping Details")) {
                        ProfileMenuRowView(item: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else if item.title == "Return Policy" {
                    NavigationLink(destination: CitizenServicesWebView(url: "https://itzeazy.in/refund-policy", title: "Return Policy")) {
                        ProfileMenuRowView(item: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else if item.title == "Privacy Policy" {
                    NavigationLink(destination: CitizenServicesWebView(url: "https://itzeazy.in/privacy-policy", title: "Privacy Policy")) {
                        ProfileMenuRowView(item: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else if item.title == "Terms and Conditions" {
                    NavigationLink(destination: CitizenServicesWebView(url: "https://itzeazy.in/terms", title: "Terms and Conditions")) {
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
                    Button(action: { openSocial(item.title) }) {
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
                    .buttonStyle(.plain)
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

    private func openSocial(_ platform: String) {
        switch platform {
        case "Youtube":
            openAppOrBrowser(appURL: "youtube://www.youtube.com/@itzeazyindia",
                             fallback: "https://www.youtube.com/@itzeazyindia")
        case "Whatsapp":
            openAppOrBrowser(appURL: "whatsapp://send?phone=919020978686",
                             fallback: "https://wa.me/919020978686")
        case "Instagram":
            openAppOrBrowser(appURL: "instagram://user?username=itzeazyindia",
                             fallback: "https://www.instagram.com/itzeazyindia")
        case "Facebook":
            openUniversalOrBrowser("https://www.facebook.com/Itzeazycom/")
        case "LinkedIn":
            openAppOrBrowser(appURL: "linkedin://company/itzeazy-com",
                             fallback: "https://www.linkedin.com/company/itzeazy-com/")
        default:
            break
        }
    }

    private func openAppOrBrowser(appURL: String, fallback: String) {
        guard let url = URL(string: appURL) else { return }
        UIApplication.shared.open(url) { success in
            if !success, let fallbackURL = URL(string: fallback) {
                UIApplication.shared.open(fallbackURL)
            }
        }
    }

    // Opens via universal link (hands off to the installed app at the exact page).
    // Falls back to Safari if the app is not installed.
    private func openUniversalOrBrowser(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url, options: [.universalLinksOnly: true]) { success in
            if !success {
                UIApplication.shared.open(url)
            }
        }
    }

    private func open(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
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
    ProfileView(onBackToHome: nil)
        .environmentObject(UserSessionViewModel())
        .environmentObject(AuthGateController())
}
