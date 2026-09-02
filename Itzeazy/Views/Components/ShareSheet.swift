import SwiftUI
import UIKit

// MARK: - Share sheet presentation
//
// UIActivityViewController is built to PRESENT ITSELF modally — it is not designed to be embedded
// as a child view controller. Wrapping it in a UIViewControllerRepresentable and handing that to a
// SwiftUI `.sheet()` does exactly that: SwiftUI builds its own presentation container (a hosting
// controller in a sheet) and installs the activity controller inside it as a child. The result is
// a sheet that renders as an empty panel — just a close button and the app's own icon as a generic
// preview fallback — with no destinations listed at all, indistinguishable from the share button
// doing nothing. That was the long-standing bug behind "share isn't working": the file being shared
// was fine the whole time, the presentation was wrong.
//
// Presenting it directly on the top-most view controller is the supported path, and is also what
// makes third-party destinations (WhatsApp, Instagram, etc.) appear — those come from whatever
// share extensions are installed on the device, which the system fills in only once the controller
// is presented properly. Note the Simulator has no third-party apps installed, so it will only ever
// offer Apple's own destinations there regardless.

/// Presents the system share sheet for [items] on the top-most presented view controller.
///
/// Items should be local `file://` URLs — WhatsApp and most other external apps only accept a real
/// on-disk file, not in-memory `Data` or an `https://` link.
@MainActor
func presentShareSheet(items: [Any]) {
    guard !items.isEmpty,
          let scene = UIApplication.shared.connectedScenes
              .compactMap({ $0 as? UIWindowScene })
              .first(where: { $0.activationState == .foregroundActive }) ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
          let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }

    // Walk to whatever is actually on screen — the scanner's screens live inside sheets and
    // full-screen covers, and presenting on the root controller while one of those is up would
    // silently do nothing.
    var presenter = root
    while let presented = presenter.presentedViewController, !presented.isBeingDismissed {
        presenter = presented
    }

    let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)

    // Required on iPad — without an anchor the popover has nowhere to attach and UIKit raises.
    if let popover = activityVC.popoverPresentationController {
        popover.sourceView = presenter.view
        popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
        popover.permittedArrowDirections = []
    }

    presenter.present(activityVC, animated: true)
}

/// Writes [data] to a temp file named [fileName] and returns its `file://` URL, replacing any
/// existing file of the same name. Use when sharing bytes that aren't already on disk — external
/// apps need a real file with the correct extension.
func createTemporaryFileURL(fileName: String, data: Data) -> URL? {
    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    do {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    } catch {
        return nil
    }
}
