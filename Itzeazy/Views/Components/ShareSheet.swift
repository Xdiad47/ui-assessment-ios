import SwiftUI
import UIKit

// MARK: - ShareSheet
// Thin UIActivityViewController bridge — SwiftUI has no native share sheet. Reused by Photo
// Maker's PNG/JPG/PDF export and Document Scanner's Share/Save actions.

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
