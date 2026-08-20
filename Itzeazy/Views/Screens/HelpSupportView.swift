import SwiftUI

// MARK: - HelpSupportView
//
// This screen used to render a static/mock "raise a ticket" form (kept below,
// commented out, for reference). It now reuses the app's shared
// CitizenServicesWebView (the same WebView used for RTO/Passport/Visa/My
// Orders/Payments/ItzEazy Wallet/etc.) to show help & support, loaded via the
// generate-web-login-token flow (WebLoginViewModel) with redirect path
// "/profile/help-n-support".
struct HelpSupportView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var webLoginVM = WebLoginViewModel()

    private let helpSupportURL = "https://itzeazy.in/profile/help-n-support"

    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.11, blue: 0.11).ignoresSafeArea()

            if let url = webLoginVM.generatedURL {
                CitizenServicesWebView(
                    url: url,
                    title: "Help & Support",
                    onBack: goBack,
                    showGovDisclaimer: true,
                    disclaimerServiceKey: "help_support"
                )
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
        .onAppear(perform: loadHelpSupport)
        .alert("Something went wrong", isPresented: Binding(
            get: { webLoginVM.errorMessage != nil },
            set: { if !$0 { webLoginVM.errorMessage = nil } }
        )) {
            Button("Retry") { loadHelpSupport() }
            Button("Cancel", role: .cancel) { goBack() }
        } message: {
            Text(webLoginVM.errorMessage ?? "")
        }
    }

    private func loadHelpSupport() {
        guard webLoginVM.generatedURL == nil, !webLoginVM.isLoading else { return }
        webLoginVM.generateToken(urlString: helpSupportURL, title: "Help & Support")
    }

    private func goBack() {
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    NavigationView {
        HelpSupportView()
    }
}

// MARK: - Original static "Help & Support" form UI (superseded by the live WebView above)
//
// struct HelpSupportViewLegacy: View {
//     @Environment(\.presentationMode) private var presentationMode
//     @StateObject private var viewModel = HelpSupportViewModel()
//     @State private var naturalHeight: CGFloat = 0
//     @State private var isIssueExpanded: Bool = false
//
//     private let backgroundColor = Color(red: 0.96, green: 0.96, blue: 0.96)
//     private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
//
//     var body: some View {
//         GeometryReader { proxy in
//             ZStack(alignment: .top) {
//                 Color(red: 0.10, green: 0.11, blue: 0.11).ignoresSafeArea(edges: .top)
//                 backgroundColor.ignoresSafeArea(edges: .bottom)
//
//                 ScrollView(.vertical, showsIndicators: false) {
//                     VStack(spacing: 16) {
//                         header
//
//                         welcomeCard
//                             .padding(.horizontal, 16)
//
//                         ticketsHeader
//                             .padding(.horizontal, 16)
//
//                         tabSwitcher
//                             .padding(.horizontal, 16)
//
//                         formCard
//                             .padding(.horizontal, 16)
//                             .padding(.bottom, 40)
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
//     private var header: some View {
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
//                 Button(action: {
//                     presentationMode.wrappedValue.dismiss()
//                 }) {
//                     Image(systemName: "arrow.left")
//                         .font(.system(size: 16, weight: .semibold))
//                         .foregroundColor(.white)
//                         .frame(width: 28, height: 28)
//                 }
//
//                 Text(viewModel.pageTitle)
//                     .font(Font.custom("PlusJakartaSans-SemiBold", size: 16))
//                     .foregroundColor(.white)
//
//                 Spacer()
//             }
//             .padding(.horizontal, 16)
//             .frame(height: 60)
//         }
//     }
//
//     private var welcomeCard: some View {
//         HStack {
//             Text(viewModel.welcomeTitle)
//                 .font(Font.custom("PlusJakartaSans-SemiBold", size: 16))
//                 .foregroundColor(.white)
//
//             Spacer()
//
//             Button(action: {}) {
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
//         .frame(height: 62)
//         .background(Color(red: 0.10, green: 0.11, blue: 0.11))
//         .clipShape(RoundedRectangle(cornerRadius: 16))
//         .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
//     }
//
//     private var ticketsHeader: some View {
//         HStack {
//             Text(viewModel.ticketsSectionTitle)
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
//
//     private var tabSwitcher: some View {
//         HStack(spacing: 4) {
//             tabButton(title: HelpSupportViewModel.Tab.raiseTicket.rawValue, tab: .raiseTicket)
//             tabButton(title: HelpSupportViewModel.Tab.ticketsRaised.rawValue, tab: .ticketsRaised)
//         }
//         .padding(4)
//         .frame(height: 48)
//         .background(Color(red: 0.95, green: 0.96, blue: 0.96))
//         .clipShape(Capsule())
//     }
//
//     private func tabButton(title: String, tab: HelpSupportViewModel.Tab) -> some View {
//         Button(action: {
//             viewModel.selectedTab = tab
//         }) {
//             Text(title)
//                 .font(
//                     Font.custom(
//                         viewModel.selectedTab == tab ? "PlusJakartaSans-Bold" : "PlusJakartaSans-SemiBold",
//                         size: 14
//                     )
//                 )
//                 .foregroundColor(viewModel.selectedTab == tab ? .white : Color(red: 0.10, green: 0.11, blue: 0.11))
//                 .frame(maxWidth: .infinity)
//                 .frame(height: 40)
//                 .background(viewModel.selectedTab == tab ? Color.red : Color.white)
//                 .overlay(
//                     RoundedRectangle(cornerRadius: 999)
//                         .stroke(viewModel.selectedTab == tab ? Color.clear : strokeColor, lineWidth: 1)
//                 )
//                 .clipShape(Capsule())
//         }
//         .buttonStyle(PlainButtonStyle())
//     }
//
//     private var formCard: some View {
//         VStack(spacing: 16) {
//             pickerField(
//                 title: viewModel.orderLabel,
//                 selection: $viewModel.selectedOrderID,
//                 options: viewModel.orderIDs
//             )
//
//             issueField
//
//             descriptionField
//
//             attachmentBox
//
//             Button(action: {}) {
//                 Text("submit")
//                     .font(Font.custom("PlusJakartaSans-Bold", size: 16))
//                     .foregroundColor(.white)
//                     .frame(width: 205, height: 54)
//                     .background(Color.red)
//                     .clipShape(Capsule())
//                     .shadow(color: Color.red.opacity(0.22), radius: 12, x: 0, y: 6)
//             }
//             .padding(.top, 6)
//         }
//         .padding(.horizontal, 20)
//         .padding(.top, 24)
//         .padding(.bottom, 24)
//         .background(Color(red: 0.93, green: 0.93, blue: 0.93))
//         .clipShape(RoundedRectangle(cornerRadius: 28))
//     }
//
//     private func pickerField(title: String, selection: Binding<String>, options: [String]) -> some View {
//         VStack(alignment: .leading, spacing: 8) {
//             Text(title)
//                 .font(Font.custom("PlusJakartaSans-Bold", size: 14))
//                 .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
//
//             Menu {
//                 ForEach(options, id: \.self) { value in
//                     Button(value) { selection.wrappedValue = value }
//                 }
//             } label: {
//                 HStack {
//                     Text(selection.wrappedValue.isEmpty ? options.first ?? "" : selection.wrappedValue)
//                         .font(Font.custom("Inter", size: 16))
//                         .foregroundColor(Color(red: 0.17, green: 0.17, blue: 0.17))
//                     Spacer()
//                     Image(systemName: "chevron.down")
//                         .font(.system(size: 12, weight: .semibold))
//                         .foregroundColor(Color(red: 0.42, green: 0.46, blue: 0.52))
//                 }
//                 .padding(.horizontal, 16)
//                 .frame(height: 52)
//                 .background(Color.white)
//                 .overlay(
//                     RoundedRectangle(cornerRadius: 16)
//                         .stroke(strokeColor, lineWidth: 1)
//                 )
//                 .clipShape(RoundedRectangle(cornerRadius: 16))
//             }
//         }
//     }
//
//     private var issueField: some View {
//         VStack(alignment: .leading, spacing: 8) {
//             Text(viewModel.issueLabel)
//                 .font(Font.custom("PlusJakartaSans-Bold", size: 14))
//                 .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
//
//             // One unified container — border switches grey ↔ red
//             VStack(spacing: 0) {
//                 // Trigger row
//                 Button(action: {
//                     withAnimation(.easeInOut(duration: 0.2)) {
//                         isIssueExpanded.toggle()
//                     }
//                 }) {
//                     HStack {
//                         Text(viewModel.selectedIssue?.title ?? "-- Choose Issue --")
//                             .font(Font.custom("Inter", size: 16))
//                             .foregroundColor(isIssueExpanded ? .red : Color(red: 0.17, green: 0.17, blue: 0.17))
//                         Spacer()
//                         Image(systemName: isIssueExpanded ? "chevron.up" : "chevron.down")
//                             .font(.system(size: 16, weight: .semibold))
//                             .foregroundColor(isIssueExpanded ? .red : Color(red: 0.42, green: 0.46, blue: 0.52))
//                     }
//                     .padding(.horizontal, 20)
//                     .frame(height: 64)
//                     .background(Color.white)
//                     .contentShape(Rectangle())
//                 }
//                 .buttonStyle(PlainButtonStyle())
//
//                 // Expanded list — no gap, inside same container
//                 if isIssueExpanded {
//                     // Red separator between trigger and first item
//                     Rectangle()
//                         .fill(Color.red)
//                         .frame(height: 1)
//
//                     ForEach(Array(viewModel.issues.dropFirst().enumerated()), id: \.element.id) { index, issue in
//                         Button(action: {
//                             viewModel.selectedIssue = issue
//                             withAnimation(.easeInOut(duration: 0.2)) {
//                                 isIssueExpanded = false
//                             }
//                         }) {
//                             HStack {
//                                 Text(issue.title)
//                                     .font(Font.custom("Inter", size: 16))
//                                     .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
//                                 Spacer()
//                             }
//                             .padding(.horizontal, 20)
//                             .frame(height: 54)
//                             .background(Color.white)
//                             .contentShape(Rectangle())
//                         }
//                         .buttonStyle(PlainButtonStyle())
//
//                         if index < viewModel.issues.dropFirst().count - 1 {
//                             Rectangle()
//                                 .fill(strokeColor.opacity(0.7))
//                                 .frame(height: 1)
//                         }
//                     }
//                 }
//             }
//             .background(Color.white)
//             .overlay(
//                 RoundedRectangle(cornerRadius: 16)
//                     .stroke(isIssueExpanded ? Color.red : strokeColor, lineWidth: 1.5)
//             )
//             .clipShape(RoundedRectangle(cornerRadius: 16))
//         }
//     }
//
//     private var descriptionField: some View {
//         VStack(alignment: .leading, spacing: 8) {
//             Text(viewModel.descriptionLabel)
//                 .font(Font.custom("PlusJakartaSans-Bold", size: 14))
//                 .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
//
//             ZStack(alignment: .topLeading) {
//                 if viewModel.descriptionText.isEmpty {
//                     Text(viewModel.descriptionPlaceholder)
//                         .font(Font.custom("Inter", size: 16))
//                         .foregroundColor(Color(red: 0.64, green: 0.64, blue: 0.64))
//                         .padding(.horizontal, 16)
//                         .padding(.vertical, 14)
//                 }
//
//                 TextEditor(text: $viewModel.descriptionText)
//                     .font(Font.custom("Inter", size: 16))
//                     .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
//                     .scrollContentBackground(.hidden)
//                     .padding(.horizontal, 12)
//                     .padding(.vertical, 10)
//                     .frame(minHeight: 120, maxHeight: 120)
//             }
//             .background(Color.white)
//             .overlay(
//                 RoundedRectangle(cornerRadius: 16)
//                     .stroke(strokeColor, lineWidth: 1)
//             )
//             .clipShape(RoundedRectangle(cornerRadius: 16))
//         }
//     }
//
//     private var attachmentBox: some View {
//         VStack(spacing: 10) {
//             Image(systemName: "paperclip")
//                 .font(.system(size: 23, weight: .semibold))
//                 .foregroundColor(.red)
//                 .rotationEffect(.degrees(45))
//
//             Text(viewModel.attachLabel)
//                 .font(Font.custom("PlusJakartaSans-SemiBold", size: 14))
//                 .foregroundColor(Color(red: 0.32, green: 0.32, blue: 0.32))
//         }
//         .frame(maxWidth: .infinity)
//         .frame(height: 110)
//         .overlay(
//             RoundedRectangle(cornerRadius: 16)
//                 .stroke(Color(red: 0.86, green: 0.86, blue: 0.86), style: StrokeStyle(lineWidth: 2, dash: [6]))
//         )
//     }
// }
