import SwiftUI

/// Entry point for the Document Scanner feature (capture, filter, OCR, e-sign, password
/// protection) — mirrors Android's `DocumentScannerScreen.kt`. The full 11-screen flow
/// (VisionKit capture, Core Image filters, PDFKit page tools, Vision OCR) lands in a later
/// pass; this is a real, navigable screen matching the app's standard header pattern rather
/// than a dead-end placeholder.
struct DocumentScannerView: View {
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image("back_arrow")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }

                Text("Document Scanner")
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                Color(red: 0.10, green: 0.11, blue: 0.11)
                    .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                    .edgesIgnoringSafeArea(.top)
            )

            VStack(spacing: 16) {
                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
                Text("Document Scanner is coming soon")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                    .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                Text("Scan, filter, sign, and organize your documents right from your phone.")
                    .font(Font.custom("Inter", size: 14))
                    .foregroundColor(Color(red: 0.37, green: 0.37, blue: 0.37))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    DocumentScannerView()
}
