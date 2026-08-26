import SwiftUI
import Combine

// MARK: - PhotoMakerViewModel
// Mirrors Android's PhotoMakerViewModel.kt — holds the picked photo and validates before
// handing off to the editor.

@MainActor
final class PhotoMakerViewModel: ObservableObject {
    @Published var selectedImageData: Data?
    @Published var selectedImage: UIImage?
    @Published var errorMessage: String?

    let features: [PhotoMakerFeature] = PhotoMakerRepository.shared.getFeatures()

    func setSelectedImage(data: Data) {
        errorMessage = nil
        selectedImageData = data
        selectedImage = UIImage(data: data)
    }

    func clearSelectedImage() {
        selectedImageData = nil
        selectedImage = nil
    }

    /// Returns the decoded, sampled starting image for the editor, or nil (with errorMessage
    /// set) if nothing was picked yet — mirrors Android's "Please upload a photo first" toast.
    func onContinueTapped() -> UIImage? {
        guard let selectedImageData else {
            errorMessage = "Please upload a photo first"
            return nil
        }
        do {
            return try PhotoMakerRepository.shared.decodeSampledImage(data: selectedImageData)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Couldn't read the photo."
            return nil
        }
    }
}
