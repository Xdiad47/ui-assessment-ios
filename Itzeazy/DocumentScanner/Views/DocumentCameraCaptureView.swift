import SwiftUI
import VisionKit

// MARK: - DocumentCameraCaptureError

enum DocumentCameraCaptureError: Error {
    case cancelled
    case failed
}

// MARK: - DocumentCameraCaptureView
// Wraps VNDocumentCameraViewController — the system document scanner (live capture, automatic
// edge detection/crop, multi-page capture, built-in review/retake, all owned entirely by
// VisionKit's own sealed UI). Mirrors Android's hand-off to ML Kit's external GmsDocumentScanning
// activity: this app provides no custom camera UI of its own, matching the explicit product
// decision to use the system scanner rather than attempt to reproduce it.

struct DocumentCameraCaptureView: UIViewControllerRepresentable {
    let onComplete: (Result<[UIImage], DocumentCameraCaptureError>) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onComplete: onComplete) }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onComplete: (Result<[UIImage], DocumentCameraCaptureError>) -> Void
        init(onComplete: @escaping (Result<[UIImage], DocumentCameraCaptureError>) -> Void) {
            self.onComplete = onComplete
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for index in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: index))
            }
            onComplete(.success(images))
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onComplete(.failure(.cancelled))
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            onComplete(.failure(.failed))
        }
    }
}
