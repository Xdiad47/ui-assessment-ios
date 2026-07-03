import SwiftUI

// MARK: - PaymentsView
//
// This screen used to render a static/mock "Payments" placeholder UI (kept
// below, commented out, for reference). It now reuses the app's shared
// CitizenServicesWebView (the same WebView used for RTO/Passport/Visa/My
// Orders/etc.) to show the user's payments, loaded via the
// generate-web-login-token flow (WebLoginViewModel) with redirect path
// "/profile/payment".
struct PaymentsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var webLoginVM = WebLoginViewModel()

    private let paymentURL = "https://itzeazy.in/profile/payment"

    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.11, blue: 0.11).ignoresSafeArea()

            if let url = webLoginVM.generatedURL {
                CitizenServicesWebView(url: url, title: "Payments", onBack: goBack)
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.4)
                    Text("Loading…")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: loadPayments)
        .alert("Something went wrong", isPresented: Binding(
            get: { webLoginVM.errorMessage != nil },
            set: { if !$0 { webLoginVM.errorMessage = nil } }
        )) {
            Button("Retry") { loadPayments() }
            Button("Cancel", role: .cancel) { goBack() }
        } message: {
            Text(webLoginVM.errorMessage ?? "")
        }
    }

    private func loadPayments() {
        guard webLoginVM.generatedURL == nil, !webLoginVM.isLoading else { return }
        webLoginVM.generateToken(urlString: paymentURL, title: "Payments")
    }

    private func goBack() {
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    NavigationView {
        PaymentsView()
    }
}

// MARK: - Original static "Payments" placeholder UI (superseded by the live WebView above)
//
// struct PaymentsViewLegacy: View {
//     @Environment(\.presentationMode) private var presentationMode
//     @StateObject private var viewModel = PaymentsViewModel()
//     @State private var naturalHeight: CGFloat = 0
//
//     private let backgroundColor = Color(red: 0.96, green: 0.96, blue: 0.96)
//     private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
//
//     var body: some View {
//         GeometryReader { proxy in
//             ZStack(alignment: .top) {
//                 Color(red: 0.10, green: 0.11, blue: 0.11).ignoresSafeArea()
//
//                 ScrollView(.vertical, showsIndicators: false) {
//                     VStack(spacing: 16) {
//                         PaymentsHeaderView(strokeColor: strokeColor) {
//                             presentationMode.wrappedValue.dismiss()
//                         }
//
//                         welcomeCard
//                             .padding(.horizontal, 16)
//
//                         sectionHeaderCard
//                             .padding(.horizontal, 16)
//                     }
//                     .background(GeometryReader { geo in
//                         Color.clear.preference(key: ContentHeightKey.self, value: geo.size.height)
//                     })
//                     .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .top)
//                     .background(backgroundColor)
//                 }
//                 .scrollDisabled(naturalHeight <= proxy.size.height)
//                 .onPreferenceChange(ContentHeightKey.self) { naturalHeight = $0 }
//             }
//         }
//         .navigationBarHidden(true)
//     }
//
//     private struct ContentHeightKey: PreferenceKey {
//         static var defaultValue: CGFloat = 0
//         static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
//             value = max(value, nextValue())
//         }
//     }
//
//     private var welcomeCard: some View {
//         HStack {
//             Text("Welcome, \(viewModel.welcomeName)")
//                 .font(Font.custom("PlusJakartaSans-SemiBold", size: 16))
//                 .foregroundColor(.white)
//
//             Spacer()
//
//             Button(action: {
//                 // Book Service action
//             }) {
//                 HStack(spacing: 6) {
//                     Image(systemName: "plus")
//                         .font(.system(size: 11, weight: .bold))
//                     Text("Book Service")
//                         .font(Font.custom("PlusJakartaSans-Bold", size: 12))
//                 }
//                 .foregroundColor(.white)
//                 .padding(.horizontal, 16)
//                 .frame(height: 36)
//                 .background(Color.red)
//                 .clipShape(Capsule())
//             }
//         }
//         .padding(.horizontal, 16)
//         .frame(height: 58)
//         .background(Color(red: 0.10, green: 0.11, blue: 0.11))
//         .clipShape(RoundedRectangle(cornerRadius: 16))
//         .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
//     }
//
//     private var sectionHeaderCard: some View {
//         HStack {
//             Text(viewModel.sectionTitle)
//                 .font(Font.custom("PlusJakartaSans-Bold", size: 16))
//                 .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
//             Spacer()
//         }
//         .padding(.horizontal, 14)
//         .frame(height: 52)
//         .background(Color.white)
//         .overlay(
//             RoundedRectangle(cornerRadius: 10)
//                 .stroke(strokeColor, lineWidth: 1)
//         )
//         .clipShape(RoundedRectangle(cornerRadius: 10))
//     }
// }
//
// private struct PaymentsHeaderView: View {
//     let strokeColor: Color
//     let onBack: () -> Void
//
//     var body: some View {
//         ZStack(alignment: .top) {
//             Rectangle()
//                 .fill(strokeColor)
//                 .frame(maxWidth: .infinity)
//                 .frame(height: 62)
//                 .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
//                 .padding(.horizontal, 1)
//
//             Color(red: 0.10, green: 0.11, blue: 0.11)
//                 .frame(maxWidth: .infinity)
//                 .frame(height: 60)
//                 .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
//
//             HStack(spacing: 12) {
//                 Button(action: onBack) {
//                     Image(systemName: "arrow.left")
//                         .font(.system(size: 16, weight: .semibold))
//                         .foregroundColor(.white)
//                         .frame(width: 28, height: 28)
//                 }
//
//                 Text("Payments")
//                     .font(Font.custom("PlusJakartaSans-Bold", size: 18))
//                     .foregroundColor(.white)
//
//                 Spacer()
//             }
//             .padding(.horizontal, 16)
//             .frame(height: 60)
//         }
//     }
// }
