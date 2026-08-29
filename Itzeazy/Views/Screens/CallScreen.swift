import SwiftUI
import UIKit

struct CallScreen: View {
    var onBackToHome: (() -> Void)? = nil
    @EnvironmentObject private var tabBarState: TabBarState
    @Environment(\.presentationMode) private var presentationMode
    
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
    private let darkHeader  = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let lightBG     = Color(red: 0.96, green: 0.96, blue: 0.96)
    private let accentRed   = Color.red

    // Replace with your real support number if available
    private let supportNumberDisplay = "9020978686"
    private let supportNumberDial    = "9020978686"

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                // .vertical only — an all-edges ignoresSafeArea on a ZStack sizing child expands
                // horizontally past the window in iPad's compatibility mode and drags the whole
                // screen (and MainTabView's tab bar) off the right edge. See HomeView.swift.
                darkHeader.ignoresSafeArea(edges: .vertical)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        header

                        VStack {
                            Spacer().frame(height: 120)

                            centerContent

                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, max(24, tabBarState.height + 16))
                    }
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .top)
                    .background(Color.white)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header (tab root — no back button)
    private var header: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(strokeColor)
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
                .padding(.horizontal, 1)

            darkHeader
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))

            HStack(spacing: 12) {
                Button(action: {
                    if let onBackToHome { onBackToHome() }
                    else { presentationMode.wrappedValue.dismiss() }
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                }

                Text("Call")
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
        }
    }

    // MARK: - Center content
    private var centerContent: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 72, height: 72)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                Image(systemName: "headphones")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(accentRed)
            }

            Text("Need immediate assistance?")
                .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))

            Button(action: callSupport) {
                HStack(spacing: 8) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Call Now")
                        .font(Font.custom("Inter", size: 16).weight(.semibold))
                }
                .foregroundColor(.white)
                .frame(width: 260, height: 52)
                .background(accentRed)
                .clipShape(Capsule())
                .shadow(color: accentRed.opacity(0.22), radius: 12, x: 0, y: 6)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions
    private func callSupport() {
        guard let url = URL(string: "tel://\(supportNumberDial)") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

#Preview {
    NavigationView {
        CallScreen()
            .environmentObject(TabBarState())
            .navigationBarHidden(true)
    }
}

