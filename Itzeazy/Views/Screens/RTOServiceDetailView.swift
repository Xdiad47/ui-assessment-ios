import SwiftUI

struct RTOServiceDetailView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var authGate: AuthGateController
    @StateObject private var viewModel: RTOServiceDetailViewModel
    @StateObject private var webLoginVM = WebLoginViewModel()
    @StateObject private var disclaimerGate = GovDisclaimerGate(serviceKey: "rto")
    @State private var showWebView = false

    // True only when this screen is entered directly (e.g. the Home hero card's "Get
    // Started"), bypassing RTOServiceInitialView's own disclaimer — the gate above uses the
    // same "rto" key so both entry paths share one daily counter.
    let showEntryDisclaimer: Bool

    init(serviceTitle: String, city: String = "Bengaluru", showEntryDisclaimer: Bool = false) {
        _viewModel = StateObject(
            wrappedValue: RTOServiceDetailViewModel(serviceTitle: serviceTitle, city: city)
        )
        self.showEntryDisclaimer = showEntryDisclaimer
    }

    var body: some View {
        ZStack(alignment: .top) {
            NavigationLink(
                destination: Group {
                    if let url = webLoginVM.generatedURL {
                        CitizenServicesWebView(
                            url: url,
                            title: webLoginVM.generatedTitle,
                            onBack: { showWebView = false },
                            showGovDisclaimer: true,
                            disclaimerServiceKey: "rto_apply"
                        )
                    }
                },
                isActive: $showWebView
            ) {
                EmptyView()
            }.hidden()

            Color.white.edgesIgnoringSafeArea(.all)

            if disclaimerGate.isPresented {
                GovDisclaimerPopupView(
                    onAcknowledge: disclaimerGate.acknowledge,
                    onDismiss: { presentationMode.wrappedValue.dismiss() }
                )
                .zIndex(30)
            }

            VStack(spacing: 0) {

                // ── Dark top nav bar ───────────────────────────────
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image("back_arrow")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        }

                        Text(viewModel.navigationTitle)
                            .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                }
                .background(
                    Color(red: 0.10, green: 0.11, blue: 0.11)
                        .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                        .edgesIgnoringSafeArea(.top)
                )
                .zIndex(1)

                // ── Scrollable content ────────────────────────────
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {

                        // Metric cards row — a pill only renders when the backend actually
                        // has a value for it; nothing is shown in its place otherwise.
                        HStack(spacing: 16) {
                            if !viewModel.processingTime.isEmpty {
                                RTOMetricCard(
                                    icon: "processing_rto",
                                    label: "PROCESSING",
                                    value: viewModel.processingTime
                                )
                            }
                            if !viewModel.documentCollection.isEmpty {
                                RTOMetricCard(
                                    icon: "document_rto",
                                    label: "DOCUMENT\nCOLLECTION",
                                    value: viewModel.documentCollection
                                )
                            }
                            if !viewModel.visitRequired.isEmpty {
                                RTOMetricCard(
                                    icon: "visit_rto",
                                    label: "VISIT\nREQUIRED",
                                    value: viewModel.visitRequired
                                )
                            }
                            if !viewModel.itzeazyFee.isEmpty {
                                RTOMetricCard(
                                    icon: "dl_extract",
                                    label: "ITZEAZY FEE",
                                    value: viewModel.itzeazyFee
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                        .padding(.bottom, 28)

                        // Apply Now button
                        Button(action: {
                            guard authGate.requireAuth() else { return }
                            if let path = viewModel.redirectPath {
                                webLoginVM.generateToken(
                                    urlString: "https://itzeazy.in\(path)",
                                    title: viewModel.serviceTitle
                                )
                            } else {
                                viewModel.showUnavailableAlert = true
                            }
                        }) {
                            ZStack {
                                if webLoginVM.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("GET ASSISTANCE")
                                        .font(Font.custom("PlusJakartaSans-ExtraBold", size: 14))
                                        .foregroundColor(.white)
                                        .tracking(0.35)

                                    HStack {
                                        Spacer()
                                        Image(systemName: "arrow.right")
                                            .foregroundColor(.white)
                                            .font(.system(size: 16, weight: .bold))
                                            .padding(.trailing, 24)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.red)
                            .cornerRadius(16)
                            .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(webLoginVM.isLoading)
                        .padding(.horizontal, 48)
                        .padding(.bottom, 24)

                        GovDisclaimerJustificationCard(
                            text: "Itzeazy fee covers document verification, form filling guidance, " +
                                "appointment booking assistance, and doorstep support."
                        )
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)

                        // Required Documents section
                        VStack(alignment: .leading, spacing: 16) {
                            // Section heading
                            HStack(spacing: 10) {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 20))

                                Text("Required Documents")
                                    .font(Font.custom("PlusJakartaSans-Bold", size: 20))
                                    .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                            }
                            .padding(.bottom, 4)

                            // Document list
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            } else if let documentsMessage = viewModel.documentsMessage {
                                Text(documentsMessage)
                                    .font(Font.custom("Inter", size: 14))
                                    .foregroundColor(Color(red: 0.37, green: 0.37, blue: 0.37))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(viewModel.requiredDocuments, id: \.self) { doc in
                                        HStack(alignment: .top, spacing: 12) {
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 6, height: 6)
                                                .padding(.top, 8)

                                            Text(doc)
                                                .font(Font.custom("Inter", size: 14))
                                                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if showEntryDisclaimer { disclaimerGate.checkOnAppear() }
        }
        .onChange(of: webLoginVM.generatedURL) { _, url in
            if url != nil { showWebView = true }
        }
        .onChange(of: showWebView) { _, isActive in
            if !isActive { webLoginVM.reset() }
        }
        .alert("Service Unavailable", isPresented: $viewModel.showUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This service is currently unavailable")
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { webLoginVM.errorMessage != nil },
            set: { if !$0 { webLoginVM.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(webLoginVM.errorMessage ?? "")
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Retry") { viewModel.fetchRequiredDocuments() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// MARK: - Metric Card Component

private struct RTOMetricCard: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)

            Text(label)
                .font(Font.custom("Inter", size: 9).weight(.semibold))
                .foregroundColor(Color(red: 0.37, green: 0.37, blue: 0.37))
                .multilineTextAlignment(.center)
                .tracking(0.5)
                .fixedSize(horizontal: false, vertical: true)

            Text(value)
                .font(Font.custom("PlusJakartaSans-Bold", size: 11))
                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(
            LinearGradient(
                stops: [
                    .init(color: Color.white, location: 0.0),
                    .init(color: Color(white: 0.60), location: 1.28)
                ],
                startPoint: .init(x: 0.5, y: 0.0),
                endPoint: .init(x: 0.5, y: 1.0)
            )
        )
        .cornerRadius(32)
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color(red: 0.72, green: 0.72, blue: 0.72), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
    }
}

#Preview {
    RTOServiceDetailView(serviceTitle: "Duplicate RC")
}
