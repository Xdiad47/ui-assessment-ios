import SwiftUI

struct RTOServiceDetailView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: RTOServiceDetailViewModel

    init(serviceTitle: String, city: String = "Bengaluru") {
        _viewModel = StateObject(
            wrappedValue: RTOServiceDetailViewModel(serviceTitle: serviceTitle, city: city)
        )
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.edgesIgnoringSafeArea(.all)

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

                        Text(viewModel.serviceDetail.navigationTitle)
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

                        // Metric cards row
                        HStack(spacing: 16) {
                            RTOMetricCard(
                                icon: "processing_rto",
                                label: "PROCESSING",
                                value: viewModel.serviceDetail.processingTime
                            )
                            RTOMetricCard(
                                icon: "document_rto",
                                label: "DOCUMENT\nCOLLECTION",
                                value: viewModel.serviceDetail.documentCollection
                            )
                            RTOMetricCard(
                                icon: "visit_rto",
                                label: "VISIT\nREQUIRED",
                                value: viewModel.serviceDetail.visitRequired
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                        .padding(.bottom, 28)

                        // Apply Now button
                        Button(action: {
                            // Apply action — wire to API later
                        }) {
                            ZStack {
                                Text("APPLY NOW")
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
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.red)
                            .cornerRadius(16)
                            .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, 48)
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
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(viewModel.serviceDetail.requiredDocuments, id: \.self) { doc in
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
