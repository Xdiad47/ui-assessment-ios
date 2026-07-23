import SwiftUI

// Home screen's hamburger drawer — mirrors the Android drawer (HamburgerDrawerContent.kt)
// item-for-item: same 7 destinations, Logout, and dynamic app version footer.
enum HomeDrawerDestination: String, Identifiable {
    case myOrders, overview, videoTutorials, faqs, helpSupport, privacyPolicy, terms
    var id: String { rawValue }

    var label: String {
        switch self {
        case .myOrders: return "My Orders"
        case .overview: return "Overview"
        case .videoTutorials: return "Video Tutorials"
        case .faqs: return "FAQs"
        case .helpSupport: return "Help & Support"
        case .privacyPolicy: return "Privacy Policy"
        case .terms: return "Terms and Conditions"
        }
    }

    var iconName: String {
        switch self {
        case .myOrders: return "shippingbox"
        case .overview: return "square.grid.2x2"
        case .videoTutorials: return "play.circle"
        case .faqs: return "info.circle"
        case .helpSupport: return "questionmark.circle"
        case .privacyPolicy: return "lock"
        case .terms: return "doc.text"
        }
    }
}

struct HamburgerDrawerView: View {
    let appVersion: String
    let isLoggedIn: Bool
    let onItemTap: (HomeDrawerDestination) -> Void
    let onLogoutTap: () -> Void
    let onCloseTap: () -> Void

    private let allItems: [HomeDrawerDestination] = [
        .myOrders, .overview, .videoTutorials, .faqs, .helpSupport, .privacyPolicy, .terms
    ]

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──
            // No manual safe-area math here — the background (below) is the only
            // part that ignores the safe area, so this content is automatically
            // kept clear of the status bar by SwiftUI itself. The extra top padding
            // is just breathing room on top of that.
            HStack {
                Text("itzeazy")
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 22))
                    .foregroundColor(.red)

                Spacer()

                Button(action: onCloseTap) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                        .padding(6)
                        .background(Color(red: 0.95, green: 0.96, blue: 0.96))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            // ── Menu list ──
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(allItems) { item in
                        Button(action: { onItemTap(item) }) {
                            HStack(spacing: 12) {
                                Image(systemName: item.iconName)
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                                    .frame(width: 22)

                                Text(item.label)
                                    .font(Font.custom("Inter", size: 14).weight(.medium))
                                    .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical, 8)
            }

            Divider()

            // ── Bottom section ──
            VStack(spacing: 12) {
                if isLoggedIn {
                    Button(action: onLogoutTap) {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Logout")
                                .font(Font.custom("Inter", size: 14).weight(.semibold))
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Text("Version \(appVersion)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.42, green: 0.42, blue: 0.42))
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .frame(maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
        .clipShape(RoundedCorner(radius: 16, corners: [.topRight, .bottomRight]))
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 4, y: 0)
    }
}

extension Bundle {
    var shortVersion: String { infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0" }
    var buildNumber: String { infoDictionary?["CFBundleVersion"] as? String ?? "1" }
}
