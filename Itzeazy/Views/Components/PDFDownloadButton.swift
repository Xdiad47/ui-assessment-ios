import SwiftUI

/// Full-page "download the whole report as a PDF" action, used on DL Info and Vehicle info
/// (Certificate of Registration) — screens with no popup to tuck a download link into, unlike
/// the challan detail popup's inline "Receipt" link. Ink-filled capsule so it reads as a
/// primary action distinct from the screen's own red CTA (Check Status), matching the
/// equivalent button already shipped on Android.
///
/// Always sized to its own content (`fixedSize`) and single-line — never placed in a shared
/// row with a long title, which is what caused the button to collapse into a wrapped, near-
/// circular blob on Android before that was fixed.
struct PDFDownloadButton: View {
    let isDownloading: Bool
    let onTap: () -> Void
    var label: String = "Download PDF"

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                if isDownloading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text(isDownloading ? "Preparing…" : label)
                    .font(Font.custom("Inter", size: 12).weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .fixedSize()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color(red: 0.10, green: 0.11, blue: 0.11))
            .clipShape(Capsule())
        }
        .fixedSize()
        .disabled(isDownloading)
    }
}

#Preview {
    VStack(spacing: 16) {
        PDFDownloadButton(isDownloading: false, onTap: {})
        PDFDownloadButton(isDownloading: true, onTap: {})
        PDFDownloadButton(isDownloading: false, onTap: {}, label: "Download Certificate")
    }
    .padding()
    .background(Color(white: 0.95))
}
