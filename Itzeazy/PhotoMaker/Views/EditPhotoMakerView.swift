import SwiftUI

// MARK: - EditPhotoMakerView
// Mirrors Android's EditPhotoMakerScreen.kt — a single scrollable screen with four stacked
// cards: preview (pinch-zoom/pan + crop guide + floating toolbar), AI adjustments grid +
// background color row, quick size selector, download/export/print.
//
// Grids use the chunked-row VStack/HStack pattern (not LazyVGrid) — this codebase hit repeated
// LazyVGrid sizing/overlap bugs elsewhere (VideoTutorialsGridView, HomeView's service grids)
// that were only reliably fixed by switching to explicit row-chunking, so new grids here start
// with that pattern rather than risking the same class of bug.

struct EditPhotoMakerView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: EditPhotoMakerViewModel

    @State private var cropUserScale: CGFloat = 1
    @State private var cropUserOffset: CGSize = .zero
    @GestureState private var cropGestureScale: CGFloat = 1
    @GestureState private var cropGestureOffset: CGSize = .zero
    @State private var previewContainerSize: CGSize = .zero

    @State private var showColorPicker = false
    @State private var customColorPickerSelection: Color = .white
    @State private var customColors: [Color] = []

    @State private var showCustomSizeDialog = false
    @State private var customWidthText = ""
    @State private var customHeightText = ""


    @State private var highlightSizeSelector = false
    @State private var isExporting = false

    init(initialImage: UIImage) {
        _viewModel = StateObject(wrappedValue: EditPhotoMakerViewModel(initialImage: initialImage))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        previewCard
                        aiAdjustmentsCard
                        quickSizeSelectorCard
                        downloadExportCard
                        Spacer(minLength: 80)
                    }
                    .padding(16)
                }
                .background(Color(hex: "#EEEEF0"))
                .onChange(of: viewModel.promptSizePreset) { _, needsPrompt in
                    guard needsPrompt else { return }
                    promptForSizePreset(scrollProxy: scrollProxy)
                }
            }
        }
        .navigationBarHidden(true)
        .overlay(loadingOverlay)
        .overlay(alignment: .bottom) { toastOverlay }
        .sheet(isPresented: $showColorPicker) { colorPickerSheet }
        .fullScreenCover(isPresented: $showCustomSizeDialog) {
            customSizeSheet.presentationBackground(.clear)
        }
        .alert("Couldn't complete that", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    /// Scrolls to and briefly highlights the Quick Size Selector card — used instead of a plain
    /// alert when Auto Resize / Print Sheet need a preset picked first, so the user actually lands
    /// on where to fix it rather than just being told to.
    private func promptForSizePreset(scrollProxy: ScrollViewProxy) {
        withAnimation { scrollProxy.scrollTo("quickSizeSelector", anchor: .center) }
        withAnimation(.easeInOut(duration: 0.2)) { highlightSizeSelector = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation { highlightSizeSelector = false }
        }
        viewModel.promptSizePreset = false
    }

    // MARK: - Toast

    private var toastOverlay: some View {
        Group {
            if let message = viewModel.toastMessage {
                ToastView(icon: "checkmark.circle.fill", message: message)
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            if viewModel.toastMessage == message { viewModel.toastMessage = nil }
                        }
                    }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.toastMessage)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image("back_arrow")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            Text("Back")
                .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "bell")
                .font(.system(size: 18))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(
            Color(red: 0.10, green: 0.11, blue: 0.11)
                .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                .edgesIgnoringSafeArea(.top)
        )
    }

    // MARK: - Preview card

    /// Default portrait shape (~266:332 from the Figma mock) used whenever no size preset picks
    /// a specific aspect ratio yet.
    private var previewAspectRatio: CGFloat { viewModel.cropGuideAspectRatio ?? (266.0 / 332.0) }

    private var previewCard: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ZStack {
                    Color(hex: "#F5F5F7")

                    if let image = viewModel.displayedImage {
                        let containerSize = geo.size
                        let baseScale = max(containerSize.width / image.size.width, containerSize.height / image.size.height)
                        let totalScale = baseScale * cropUserScale * cropGestureScale
                        let displaySize = CGSize(width: image.size.width * totalScale, height: image.size.height * totalScale)
                        let combinedOffset = CGSize(
                            width: cropUserOffset.width + cropGestureOffset.width,
                            height: cropUserOffset.height + cropGestureOffset.height
                        )

                        Image(uiImage: image)
                            .resizable()
                            .frame(width: displaySize.width, height: displaySize.height)
                            .position(x: containerSize.width / 2 + combinedOffset.width, y: containerSize.height / 2 + combinedOffset.height)
                    }

                    // Faint oval face-alignment reticle, matching the Figma reference.
                    Ellipse()
                        .stroke(Color(red: 0.73, green: 0, blue: 0.07).opacity(0.15), lineWidth: 1.5)
                        .frame(width: geo.size.width * 0.78, height: geo.size.height * 0.85)
                }
                .clipped()
                .contentShape(Rectangle())
                .gesture(
                    SimultaneousGesture(
                        MagnificationGesture()
                            .updating($cropGestureScale) { value, state, _ in state = value }
                            .onEnded { value in cropUserScale = max(1, min(4, cropUserScale * value)) },
                        DragGesture()
                            .updating($cropGestureOffset) { value, state, _ in state = value.translation }
                            .onEnded { value in
                                cropUserOffset.width += value.translation.width
                                cropUserOffset.height += value.translation.height
                            }
                    )
                )
                .onAppear { previewContainerSize = geo.size }
                .onChange(of: geo.size) { _, newValue in previewContainerSize = newValue }
            }
            .aspectRatio(previewAspectRatio, contentMode: .fit)
            .frame(maxWidth: 280)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color(hex: "#E8BCB7"), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(editToolbar, alignment: .bottom)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#B7B7B7"), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    /// Maps the dashed-border viewport (now the full preview container — the design wraps the
    /// whole aspect-locked frame, not a smaller inset guide) back into the source image's pixel
    /// space, given the current pan/zoom transform — the geometry underlying the toolbar's
    /// "Crop" action.
    private func currentCropRectInImagePixels(image: UIImage, containerSize: CGSize) -> CGRect {
        let baseScale = max(containerSize.width / image.size.width, containerSize.height / image.size.height)
        let totalScale = baseScale * cropUserScale

        let imageDisplaySize = CGSize(width: image.size.width * totalScale, height: image.size.height * totalScale)
        let imageOrigin = CGPoint(
            x: containerSize.width / 2 - imageDisplaySize.width / 2 + cropUserOffset.width,
            y: containerSize.height / 2 - imageDisplaySize.height / 2 + cropUserOffset.height
        )

        let cropX = -imageOrigin.x / totalScale
        let cropY = -imageOrigin.y / totalScale
        let cropW = containerSize.width / totalScale
        let cropH = containerSize.height / totalScale

        let clampedW = min(cropW, image.size.width)
        let clampedH = min(cropH, image.size.height)
        let clampedX = max(0, min(cropX, image.size.width - clampedW))
        let clampedY = max(0, min(cropY, image.size.height - clampedH))
        return CGRect(x: clampedX, y: clampedY, width: clampedW, height: clampedH)
    }

    private var editToolbar: some View {
        HStack(spacing: 4) {
            // Static hints — pinch-to-zoom / drag-to-pan are always-on gestures on the photo
            // above, so these two are non-interactive reminders, matching the Figma reference.
            toolbarButton(systemName: "magnifyingglass", interactive: false) {}
            toolbarButton(systemName: "hand.draw", interactive: false) {}
            toolbarButton(systemName: "rotate.right") { viewModel.rotate(clockwise: true) }

            toolbarDivider

            toolbarButton(systemName: "sun.max", label: cycleLabel(viewModel.brightnessLevel)) { viewModel.cycleBrightness() }
            toolbarButton(systemName: "circle.lefthalf.filled", label: cycleLabel(viewModel.contrastLevel)) { viewModel.cycleContrast() }
            toolbarButton(systemName: "crop") { commitManualCrop() }

            toolbarDivider

            toolbarButton(systemName: "arrow.uturn.backward", disabled: !viewModel.canUndo) { viewModel.undo() }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Color(hex: "#191C1D").opacity(0.9)
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.bottom, -20)
    }

    private var toolbarDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.2))
            .frame(width: 1, height: 24)
    }

    private func cycleLabel(_ level: Int) -> String {
        switch level {
        case 1: return "+"
        case -1: return "−"
        default: return ""
        }
    }

    private func commitManualCrop() {
        guard let image = viewModel.displayedImage, previewContainerSize != .zero else { return }
        let rect = currentCropRectInImagePixels(image: image, containerSize: previewContainerSize)
        viewModel.applyManualCrop(to: rect)
        cropUserScale = 1
        cropUserOffset = .zero
    }

    private func toolbarButton(systemName: String, label: String = "", disabled: Bool = false, interactive: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Image(systemName: systemName).font(.system(size: 15))
                if !label.isEmpty {
                    Text(label).font(.system(size: 10, weight: .bold))
                }
            }
            .foregroundColor(disabled ? .white.opacity(0.3) : .white)
            .frame(width: 30, height: 32)
        }
        .disabled(disabled || !interactive)
    }

    // MARK: - AI Adjustments card

    private var aiAdjustmentsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeaderStrip("AI INTELLIGENCE ADJUSTMENTS")
                .padding(.top, -16)
                .padding(.horizontal, -16)

            aiAdjustmentsGrid
                .padding(.top, 14)

            sectionHeaderStrip("BACKGROUND COLOR")
                .padding(.horizontal, -16)
                .padding(.top, 14)

            backgroundColorRow
                .padding(.top, 14)
        }
        .padding(16)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#B7B7B7"), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func sectionHeaderStrip(_ title: String) -> some View {
        Text(title)
            .font(Font.custom("Inter", size: 12))
            .foregroundColor(.white)
            .tracking(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .frame(height: 41)
            .background(Color(hex: "#191C1D"))
    }

    private var aiAdjustmentsGrid: some View {
        let rows = viewModel.aiAdjustments.chunked(into: 2)
        return VStack(spacing: 10) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 10) {
                    ForEach(row) { option in
                        aiAdjustmentButton(option).frame(maxWidth: .infinity)
                    }
                    if row.count == 1 { Spacer().frame(maxWidth: .infinity) }
                }
            }
        }
    }

    private func aiAdjustmentButton(_ option: AiAdjustmentOption) -> some View {
        let isActive = isAdjustmentActive(option)
        return Button(action: { viewModel.handleAiAdjustment(option) }) {
            HStack(spacing: 8) {
                Image(option.iconAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                Text(option.label)
                    .font(Font.custom("Inter", size: 12))
                    .foregroundColor(isActive ? .red : Color(hex: "#1A1C1D"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .frame(height: 46)
            .background(isActive ? Color(hex: "#FFDAD6") : Color.white)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isActive ? Color.red : Color(hex: "#E8BCB7"), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func isAdjustmentActive(_ option: AiAdjustmentOption) -> Bool {
        switch option.id {
        case "Remove Shadow": return viewModel.removeShadowActive
        case "Brightness Fix": return viewModel.brightnessFixActive
        case "Contrast Balance": return viewModel.contrastBalanceActive
        case "Skin Tone Balance": return viewModel.skinToneActive
        case "BG Remove": return viewModel.isTransparentBackground
        case "White BG": return viewModel.backgroundFillColor != nil && !viewModel.isTransparentBackground
        default: return false
        }
    }

    private var backgroundColorRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                backgroundSwatch(color: .white, isSelected: isFillSelected(.white)) { viewModel.selectBackgroundFill(.white) }
                backgroundSwatch(color: Color(hex: "#E5E7EB"), isSelected: isFillSelected(UIColor(Color(hex: "#E5E7EB")))) { viewModel.selectBackgroundFill(UIColor(Color(hex: "#E5E7EB"))) }
                backgroundSwatch(color: Color(hex: "#DBEAFE"), isSelected: isFillSelected(UIColor(Color(hex: "#DBEAFE")))) { viewModel.selectBackgroundFill(UIColor(Color(hex: "#DBEAFE"))) }

                ForEach(customColors.indices, id: \.self) { i in
                    backgroundSwatch(color: customColors[i], isSelected: isFillSelected(UIColor(customColors[i]))) { viewModel.selectBackgroundFill(UIColor(customColors[i])) }
                }

                transparentSwatch
                addColorButton
            }
            .padding(.vertical, 2)
        }
    }

    private func isFillSelected(_ color: UIColor) -> Bool {
        !viewModel.isTransparentBackground && viewModel.backgroundFillColor == color
    }

    private func backgroundSwatch(color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 34, height: 34)
                .overlay(Circle().stroke(isSelected ? Color.red : Color(hex: "#E8BCB7"), lineWidth: isSelected ? 3 : 1))
        }
        .buttonStyle(.plain)
    }

    private var transparentSwatch: some View {
        Button(action: { viewModel.selectTransparentBackground() }) {
            CheckerboardPattern()
                .frame(width: 34, height: 34)
                .clipShape(Circle())
                .overlay(Circle().stroke(viewModel.isTransparentBackground ? Color.red : Color(hex: "#E8BCB7"), lineWidth: viewModel.isTransparentBackground ? 3 : 1))
        }
        .buttonStyle(.plain)
    }

    private var addColorButton: some View {
        Button(action: { showColorPicker = true }) {
            Circle()
                .fill(Color.white)
                .frame(width: 34, height: 34)
                .overlay(Image(systemName: "plus").font(.system(size: 13, weight: .bold)).foregroundColor(Color(hex: "#1A1C1D")))
                .overlay(Circle().stroke(Color(hex: "#E8BCB7"), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Size Selector card

    private var quickSizeSelectorCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeaderStrip("QUICK SIZE SELECTOR")
                .padding(.top, -16)
                .padding(.horizontal, -16)

            FlowLayout(horizontalSpacing: 10, verticalSpacing: 10) {
                ForEach(viewModel.sizePresets) { preset in
                    sizePresetChip(preset)
                }
            }
            .padding(.top, 16)
        }
        .padding(16)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(highlightSizeSelector ? Color.red : Color(hex: "#B7B7B7"), lineWidth: highlightSizeSelector ? 2 : 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .scaleEffect(highlightSizeSelector ? 1.02 : 1)
        .id("quickSizeSelector")
    }

    private func sizePresetChip(_ preset: PhotoSizePreset) -> some View {
        let isSelected = viewModel.selectedPreset?.id == preset.id
        return Button(action: {
            if preset.label == "Custom" {
                showCustomSizeDialog = true
            } else {
                viewModel.selectSizePreset(preset)
            }
        }) {
            Text(preset.label)
                .font(Font.custom("Inter", size: 12))
                .foregroundColor(isSelected ? .white : Color(hex: "#1A1C1D"))
                .fixedSize()
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(isSelected ? Color.red : Color.white)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.red : Color(hex: "#E8BCB7"), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Download / Export card

    private var downloadExportCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Download & Export")
                .font(Font.custom("PlusJakartaSans-Regular", size: 16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(Color(hex: "#191C1D"))
                .padding(.top, -16)
                .padding(.horizontal, -16)

            VStack(spacing: 12) {
                Button(action: printSheet) {
                    HStack(spacing: 10) {
                        Image(systemName: "printer.fill")
                        Text("Print Sheet")
                    }
                    .font(Font.custom("PlusJakartaSans-Regular", size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                HStack(spacing: 12) {
                    exportTile(title: "Download PNG", systemImage: "photo") { exportAndShare(fileExtension: "png") { PhotoMakerRepository.shared.exportPNGData($0) } }
                    exportTile(title: "Download JPG", systemImage: "photo.fill") { exportAndShare(fileExtension: "jpg") { PhotoMakerRepository.shared.exportJPGData($0) } }
                }

                Button(action: { exportAndShare(fileExtension: "pdf") { PhotoMakerRepository.shared.exportPDFData($0) } }) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.richtext")
                        Text("Save as PDF")
                    }
                    .font(Font.custom("Inter", size: 12))
                    .foregroundColor(Color(hex: "#1A1C1D"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#E8BCB7"), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.top, 21)
        }
        .padding(16)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#B7B7B7"), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func exportTile(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage).font(.system(size: 16))
                Text(title)
                    .font(Font.custom("Inter", size: 12))
            }
            .foregroundColor(Color(hex: "#1A1C1D"))
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#E8BCB7"), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    /// Encoding a large (post-Enhance-Quality) image to PNG/JPG/PDF data can take a visible
    /// moment — runs off the main thread with a loading dialog so the tap doesn't look ignored.
    private func exportAndShare(fileExtension: String, makeData: @escaping (UIImage) -> Data?) {
        guard let image = viewModel.displayedImage, !isExporting else { return }
        isExporting = true
        Task.detached(priority: .userInitiated) {
            let data = makeData(image)
            await MainActor.run {
                isExporting = false
                guard let data else {
                    viewModel.errorMessage = "Couldn't prepare the file for export."
                    return
                }
                let filename = "Itzeazy_Photo_\(Int(Date().timeIntervalSince1970)).\(fileExtension)"
                let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                do {
                    try data.write(to: url, options: .atomic)
                    presentShareSheet(items: [url])
                } catch {
                    viewModel.errorMessage = "Couldn't prepare the file for export."
                }
            }
        }
    }

    private func printSheet() {
        guard let image = viewModel.displayedImage,
              let preset = viewModel.selectedPreset,
              let widthMm = preset.widthMm, let heightMm = preset.heightMm else {
            viewModel.promptSizePreset = true
            return
        }
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .photo
        printInfo.jobName = "Itzeazy Photo Sheet"

        let printController = UIPrintInteractionController.shared
        printController.printInfo = printInfo
        printController.printPageRenderer = PhotoSheetPrintRenderer(image: image, tileWidthMm: CGFloat(widthMm), tileHeightMm: CGFloat(heightMm))
        printController.present(animated: true, completionHandler: nil)
    }

    // MARK: - Loading overlay

    private var loadingOverlay: some View {
        Group {
            if viewModel.isProcessing || isExporting {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    VStack(spacing: 14) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .red))
                            .scaleEffect(1.3)
                        Text(isExporting ? "Preparing file..." : "Loading...")
                            .font(Font.custom("PlusJakartaSans-SemiBold", size: 15))
                            .foregroundColor(Color(hex: "#191c1d"))
                    }
                    .frame(width: 150, height: 110)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 10)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: viewModel.isProcessing)
        .animation(.easeInOut(duration: 0.15), value: isExporting)
    }

    // MARK: - Color picker sheet

    private var colorPickerSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                ColorPicker("Choose a background color", selection: $customColorPickerSelection, supportsOpacity: false)
                    .padding()

                Button(action: {
                    customColors.append(customColorPickerSelection)
                    viewModel.selectBackgroundFill(UIColor(customColorPickerSelection))
                    showColorPicker = false
                }) {
                    Text("Use this color")
                        .font(Font.custom("Inter", size: 16).weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Mix a Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showColorPicker = false }
                }
            }
        }
    }

    // MARK: - Custom size sheet

    private var customSizeSheet: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { showCustomSizeDialog = false }

            customSizeCard
                .padding(.horizontal, 24)
        }
    }

    private var customSizeCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Custom Photo Size")
                        .font(Font.custom("PlusJakartaSans-SemiBold", size: 24))
                        .foregroundColor(Color(hex: "#1A1C1D"))
                    Text("Enter your preferred photo dimensions.")
                        .font(Font.custom("Inter", size: 12).weight(.medium))
                        .foregroundColor(Color(red: 0.369, green: 0.247, blue: 0.231).opacity(0.7))
                }
                Spacer()
                Button(action: { showCustomSizeDialog = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#1A1C1D").opacity(0.4))
                }
            }
            .padding(.bottom, 20)

            HStack(spacing: 12) {
                customSizeField(text: $customWidthText, placeholder: "35")
                Text("×")
                    .font(Font.custom("Inter", size: 16).weight(.medium))
                    .foregroundColor(Color(hex: "#1A1C1D").opacity(0.3))
                customSizeField(text: $customHeightText, placeholder: "45")
                Text("mm")
                    .font(Font.custom("Inter", size: 12).weight(.medium))
                    .foregroundColor(Color(red: 0.369, green: 0.247, blue: 0.231).opacity(0.6))
            }
            .padding(.bottom, 8)

            Text("Example: Passport = 35 × 45 mm")
                .font(Font.custom("Inter", size: 11))
                .foregroundColor(Color(red: 0.369, green: 0.247, blue: 0.231).opacity(0.5))
                .padding(.bottom, 20)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(PhotoMakerConstants.customSizeQuickFills.prefix(3), id: \.label) { fill in
                        quickFillPill(fill)
                    }
                }
                HStack(spacing: 8) {
                    ForEach(PhotoMakerConstants.customSizeQuickFills.dropFirst(3), id: \.label) { fill in
                        quickFillPill(fill)
                    }
                    Spacer()
                }
            }
            .padding(.bottom, 24)

            HStack(spacing: 12) {
                Button(action: { showCustomSizeDialog = false }) {
                    Text("Cancel")
                        .font(Font.custom("Inter", size: 16))
                        .foregroundColor(Color(hex: "#1A1C1D"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#E2E2E4"), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button(action: {
                    guard let w = Double(customWidthText), let h = Double(customHeightText), w > 0, h > 0 else { return }
                    viewModel.applyCustomSize(widthMm: w, heightMm: h)
                    showCustomSizeDialog = false
                }) {
                    Text("Apply Size")
                        .font(Font.custom("Inter", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.2), radius: 30, x: 0, y: 10)
    }

    private func quickFillPill(_ fill: (label: String, widthMm: Double, heightMm: Double)) -> some View {
        Button(action: {
            customWidthText = String(format: "%g", fill.widthMm)
            customHeightText = String(format: "%g", fill.heightMm)
        }) {
            Text(fill.label)
                .font(Font.custom("Inter", size: 12).weight(.medium))
                .foregroundColor(Color(hex: "#1A1C1D").opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: "#F5F5F7"))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func customSizeField(text: Binding<String>, placeholder: String) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(.decimalPad)
            .font(Font.custom("Inter", size: 16))
            .foregroundColor(Color(hex: "#1A1C1D"))
            .padding(.horizontal, 16)
            .frame(height: 42)
            .background(Color(hex: "#F5F5F7"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - FlowLayout
// Left-to-right wrapping layout for content-sized chips (Quick Size Selector) — each chip sizes
// to its own label rather than stretching to equal columns, and wraps to a new row when it no
// longer fits, matching the Figma reference exactly.

private struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                totalHeight += rowHeight + verticalSpacing
                totalWidth = max(totalWidth, x - horizontalSpacing)
                x = 0
                rowHeight = 0
            }
            x += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        totalWidth = max(totalWidth, x - horizontalSpacing)
        return CGSize(width: min(totalWidth, maxWidth), height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - CheckerboardPattern

private struct CheckerboardPattern: View {
    var body: some View {
        GeometryReader { geo in
            let cell = geo.size.width / 2
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Color(white: 0.85).frame(width: cell, height: cell)
                    Color.white.frame(width: cell, height: cell)
                }
                HStack(spacing: 0) {
                    Color.white.frame(width: cell, height: cell)
                    Color(white: 0.85).frame(width: cell, height: cell)
                }
            }
        }
    }
}

#Preview {
    NavigationView { EditPhotoMakerView(initialImage: UIImage(systemName: "photo") ?? UIImage()) }
}
