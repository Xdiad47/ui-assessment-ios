import SwiftUI
import Combine

// MARK: - EditPhotoMakerViewModel
// Mirrors Android's EditPhotoMakerViewModel.kt — the orchestration brain for the editor screen.
//
// Baseline/undo architecture (the trickiest part to port faithfully):
// - `baseImage` = last committed "geometry" state (original, or after a destructive edit).
//   Destructive edits (Rotate, manual Crop, Auto Crop, Face Center, Auto Resize, Enhance
//   Quality, AI Auto Fix) each push the *previous* baseImage onto `undoStack`, then bake the
//   currently-visible result (transient filters included) in as the new baseImage.
// - Transient state (brightness/contrast level, background fill, the 4 toggle filters) is never
//   baked into baseImage until a destructive edit or Undo commits it — every toggle just
//   re-derives `displayedImage` from baseImage via `rebuildPreview()`, in a fixed pipeline
//   order: background composite -> Remove Shadow -> Brightness Fix -> Contrast Balance ->
//   Skin Tone Balance -> manual brightness/contrast.
// - When a background swap is active, Remove Shadow/Brightness Fix/Contrast Balance/manual
//   brightness-contrast are all person-region-restricted (share the same mask) so the flat
//   background fill stays pixel-exact; without an active swap they run whole-frame. Skin Tone
//   Balance is *always* person-restricted regardless.
// - Size-preset selection is special: it doesn't stack — it re-crops from a remembered
//   `preSizePresetBaseImage` (captured once, on first preset pick after a fresh photo or manual
//   edit) every time, so Passport -> PAN Card doesn't crop an already-cropped image. A manual
//   destructive edit or Undo invalidates this baseline.

@MainActor
final class EditPhotoMakerViewModel: ObservableObject {

    // MARK: Published UI state

    @Published private(set) var displayedImage: UIImage?
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var toastMessage: String?
    /// One-shot signal the view watches to scroll to + highlight the Quick Size Selector card —
    /// used instead of a blocking alert when Auto Resize / Print Sheet need a preset picked first,
    /// since "OK" on an alert didn't actually get the user any closer to fixing it.
    @Published var promptSizePreset = false

    @Published private(set) var selectedPreset: PhotoSizePreset?
    @Published private(set) var brightnessLevel: Int = 0   // -1, 0, 1 — cycles 0 -> 1 -> -1 -> 0
    @Published private(set) var contrastLevel: Int = 0

    @Published private(set) var backgroundFillColor: UIColor?
    @Published private(set) var isTransparentBackground = false

    @Published private(set) var removeShadowActive = false
    @Published private(set) var brightnessFixActive = false
    @Published private(set) var contrastBalanceActive = false
    @Published private(set) var skinToneActive = false

    let aiAdjustments: [AiAdjustmentOption]
    let sizePresets: [PhotoSizePreset]

    var cropGuideAspectRatio: CGFloat? {
        selectedPreset?.aspectRatio.map { CGFloat($0) }
    }

    var canUndo: Bool { !undoStack.isEmpty }

    // MARK: Baseline / undo

    private var baseImage: UIImage
    private var undoStack: [UIImage] = []
    private var preSizePresetBaseImage: UIImage?
    private let repository = PhotoMakerRepository.shared

    init(initialImage: UIImage) {
        self.baseImage = initialImage
        self.displayedImage = initialImage
        self.aiAdjustments = PhotoMakerRepository.shared.getAiAdjustments()
        self.sizePresets = PhotoMakerRepository.shared.getSizePresets()
    }

    // MARK: - AI adjustment tile dispatch

    func handleAiAdjustment(_ option: AiAdjustmentOption) {
        switch option.id {
        case "AI Auto Fix": runAutoFix()
        case "BG Remove": selectTransparentBackground()
        case "White BG": selectBackgroundFill(.white)
        case "Auto Crop": applyAutoCrop()
        case "Auto Resize": applyAutoResize()
        case "Enhance Quality": applyEnhanceQuality()
        case "Remove Shadow": toggleRemoveShadow()
        case "Brightness Fix": toggleBrightnessFix()
        case "Contrast Balance": toggleContrastBalance()
        case "Skin Tone Balance": toggleSkinTone()
        case "Face Center": applyFaceCenter()
        default: break
        }
    }

    // MARK: - Toolbar

    func rotate(clockwise: Bool) {
        runDestructiveEdit { repo, source in repo.rotate90(source, clockwise: clockwise) }
    }

    func applyManualCrop(to rect: CGRect) {
        runDestructiveEdit { repo, source in repo.crop(source, to: rect) }
    }

    func cycleBrightness() {
        brightnessLevel = nextCycleValue(brightnessLevel)
        rebuildPreview()
    }

    func cycleContrast() {
        contrastLevel = nextCycleValue(contrastLevel)
        rebuildPreview()
    }

    private func nextCycleValue(_ current: Int) -> Int {
        switch current {
        case 0: return 1
        case 1: return -1
        default: return 0
        }
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        baseImage = previous
        preSizePresetBaseImage = nil
        resetTransientState()
        displayedImage = previous
    }

    // MARK: - Background

    func selectBackgroundFill(_ color: UIColor) {
        backgroundFillColor = color
        isTransparentBackground = false
        rebuildPreview()
    }

    func selectTransparentBackground() {
        backgroundFillColor = nil
        isTransparentBackground = true
        rebuildPreview()
    }

    func clearBackgroundFill() {
        backgroundFillColor = nil
        isTransparentBackground = false
        rebuildPreview()
    }

    // MARK: - Toggle filters (Lab-channel + gray-world)

    func toggleRemoveShadow() {
        removeShadowActive.toggle()
        rebuildPreview()
    }

    func toggleBrightnessFix() {
        brightnessFixActive.toggle()
        rebuildPreview()
    }

    func toggleContrastBalance() {
        contrastBalanceActive.toggle()
        rebuildPreview()
    }

    func toggleSkinTone() {
        skinToneActive.toggle()
        rebuildPreview()
    }

    // MARK: - Size presets

    func selectSizePreset(_ preset: PhotoSizePreset) {
        selectedPreset = preset
        guard let aspectRatio = preset.aspectRatio else { return }   // Custom, not yet applied

        if preSizePresetBaseImage == nil {
            preSizePresetBaseImage = baseImage
        }
        guard let source = preSizePresetBaseImage else { return }

        errorMessage = nil
        let repo = repository
        Task.detached(priority: .userInitiated) {
            let cropped = repo.cropToAspectRatio(source, aspectRatio: CGFloat(aspectRatio))
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.baseImage = cropped
                self.rebuildPreview()
            }
        }
    }

    func applyCustomSize(widthMm: Double, heightMm: Double) {
        selectSizePreset(PhotoSizePreset(label: "Custom", widthMm: widthMm, heightMm: heightMm))
    }

    // MARK: - Destructive AI edits

    private func applyAutoCrop() {
        let aspectRatio = cropGuideAspectRatio   // snapshot on MainActor before crossing to background
        runDestructiveEdit(successMessage: "Photo auto-cropped") { repo, source in
            let face = try repo.detectFace(in: source)
            return repo.autoCropToFace(source, face: face, targetAspectRatio: aspectRatio)
        }
    }

    private func applyFaceCenter() {
        runDestructiveEdit(successMessage: "Face centered") { repo, source in
            let face = try repo.detectFace(in: source)
            return repo.autoCropToFace(source, face: face, targetAspectRatio: nil)
        }
    }

    private func applyAutoResize() {
        guard let preset = selectedPreset else {
            promptSizePreset = true
            return
        }
        runDestructiveEdit(successMessage: "Resized to \(preset.label)") { repo, source in try repo.resizeToOfficialDimensions(source, preset: preset) }
    }

    private func applyEnhanceQuality() {
        runDestructiveEdit(successMessage: "Photo quality enhanced") { repo, source in repo.enhanceQuality(source) }
    }

    /// Deliberately a light, fixed 3-step pipeline (matches Android — an earlier version chaining
    /// all 6 heavy filters looked bad). Atomic: nothing commits unless every step succeeds.
    private func runAutoFix() {
        runDestructiveEdit(successMessage: "AI Auto Fix applied") { repo, source in
            let mask = try repo.segmentPerson(in: source)
            var working = repo.compositeBackground(source, mask: mask, fillColor: .white)
            working = repo.applyAdjustments(working, brightnessLevel: 1, contrastLevel: -1, mask: mask)
            working = repo.enhanceQuality(working)
            return working
        }
    }

    // MARK: - Preview pipeline

    private func rebuildPreview() {
        let base = baseImage
        let bgFill = backgroundFillColor
        let transparentBG = isTransparentBackground
        let removeShadow = removeShadowActive
        let brightnessFix = brightnessFixActive
        let contrastBalance = contrastBalanceActive
        let skinTone = skinToneActive
        let brightness = brightnessLevel
        let contrast = contrastLevel

        let bgActive = transparentBG || bgFill != nil
        let needsMask = bgActive || skinTone
        let needsFace = brightnessFix

        // Only the size-preset tap path reaches this with literally nothing to do (a plain crop,
        // no filters active) — skip the loading dialog there so picking Passport/Visa/PAN reads as
        // an instant tab switch instead of flashing a spinner for a no-op rebuild.
        let hasRealWork = needsMask || needsFace || removeShadow || contrastBalance || brightness != 0 || contrast != 0
        if hasRealWork { isProcessing = true }
        errorMessage = nil
        let repo = repository

        Task.detached(priority: .userInitiated) {
            do {
                var mask: PersonSegmentationMask?
                if needsMask {
                    mask = try repo.segmentPerson(in: base)
                }
                var face: DetectedFace?
                if needsFace {
                    face = try? repo.detectFace(in: base)   // graceful no-op fallback if no face found
                }

                var working = base
                if transparentBG, let mask {
                    working = repo.compositeBackground(working, mask: mask, fillColor: nil)
                } else if let bgFill, let mask {
                    working = repo.compositeBackground(working, mask: mask, fillColor: bgFill)
                }

                let personRestrictMask = bgActive ? mask : nil

                if removeShadow {
                    working = repo.normalizeIllumination(working, mask: personRestrictMask)
                }
                if brightnessFix, let face {
                    working = repo.adjustTowardTargetLuminance(working, faceBoundingBox: face.boundingBox, mask: personRestrictMask)
                }
                if contrastBalance {
                    working = repo.applyContrastBalance(working, mask: personRestrictMask)
                }
                if skinTone, let mask {
                    working = try repo.balanceSkinTone(working, mask: mask)
                }
                if brightness != 0 || contrast != 0 {
                    working = repo.applyAdjustments(working, brightnessLevel: brightness, contrastLevel: contrast, mask: personRestrictMask)
                }

                let result = working
                await MainActor.run { [weak self] in
                    self?.displayedImage = result
                    self?.isProcessing = false
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.errorMessage = (error as? LocalizedError)?.errorDescription ?? "Something went wrong. Please try again."
                    self?.isProcessing = false
                }
            }
        }
    }

    // MARK: - Destructive edit helper

    private func runDestructiveEdit(successMessage: String? = nil, _ work: @escaping (PhotoMakerRepository, UIImage) throws -> UIImage) {
        guard !isProcessing, let source = displayedImage else { return }
        isProcessing = true
        errorMessage = nil
        let repo = repository

        Task.detached(priority: .userInitiated) {
            do {
                let result = try work(repo, source)
                await MainActor.run { [weak self] in
                    self?.commitDestructiveEdit(result)
                    if let successMessage { self?.toastMessage = successMessage }
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.errorMessage = (error as? LocalizedError)?.errorDescription ?? "Something went wrong. Please try again."
                    self?.isProcessing = false
                }
            }
        }
    }

    private func commitDestructiveEdit(_ newImage: UIImage) {
        undoStack.append(baseImage)
        baseImage = newImage
        preSizePresetBaseImage = nil
        resetTransientState()
        displayedImage = newImage
        isProcessing = false
    }

    private func resetTransientState() {
        brightnessLevel = 0
        contrastLevel = 0
        backgroundFillColor = nil
        isTransparentBackground = false
        removeShadowActive = false
        brightnessFixActive = false
        contrastBalanceActive = false
        skinToneActive = false
    }

    // MARK: - Export

    func exportPNGData() -> Data? {
        displayedImage.flatMap { repository.exportPNGData($0) }
    }

    func exportJPGData() -> Data? {
        displayedImage.flatMap { repository.exportJPGData($0) }
    }

    func exportPDFData() -> Data? {
        displayedImage.map { repository.exportPDFData($0) }
    }
}
