import SwiftUI
import PhotosUI

// MARK: - PhotoMakerView
// Entry point for the Photo Maker feature (ID-photo background removal, auto-crop, and
// AI-assisted adjustments) — mirrors Android's PhotoMakerScreen.kt: an upload card, a Continue
// button, and a static features list. Editing happens on EditPhotoMakerView.

struct PhotoMakerView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = PhotoMakerViewModel()

    @State private var showSourceDialog = false
    @State private var showPhotosPicker = false
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var navigateToEditor = false
    @State private var editorStartingImage: UIImage?

    private let cardBg = Color(red: 0.098, green: 0.110, blue: 0.114)
    private let cardDashedBorder = Color(red: 1.0, green: 0.169, blue: 0.169).opacity(0.2)
    private let featureIconBg = Color(red: 1.0, green: 0.945, blue: 0.945)
    private let featureTitleColor = Color(red: 0.102, green: 0.102, blue: 0.102)
    private let featureSubtitleColor = Color(red: 0.4, green: 0.4, blue: 0.4)

    var body: some View {
        VStack(spacing: 0) {
            header

            NavigationLink(
                destination: Group {
                    if let editorStartingImage {
                        EditPhotoMakerView(initialImage: editorStartingImage)
                    }
                },
                isActive: $navigateToEditor
            ) { EmptyView() }.hidden()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    uploadCard
                    continueButton
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(Font.custom("Inter", size: 13).weight(.medium))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    featuresSection
                }
                .padding(20)
            }
            .background(Color.white)
        }
        .navigationBarHidden(true)
        .confirmationDialog("Add Photo", isPresented: $showSourceDialog, titleVisibility: .hidden) {
            Button("Browse Files") { showPhotosPicker = true }
            Button("Take Photo") { showCamera = true }
            Button("Recent Photos") { showPhotosPicker = true }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $photosPickerItem, matching: .images)
        .onChange(of: photosPickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    viewModel.setSelectedImage(data: data)
                }
                photosPickerItem = nil
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView { data in
                if let data { viewModel.setSelectedImage(data: data) }
                showCamera = false
            }
            .ignoresSafeArea()
        }
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

            Text("Photo Maker")
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
    }

    // MARK: - Upload card

    private var uploadCard: some View {
        Button(action: { showSourceDialog = true }) {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 88, height: 88)
                        .overlay(Circle().stroke(Color(hex: "#F3F4F6"), lineWidth: 1))

                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 84, height: 84)
                            .clipShape(Circle())
                    } else {
                        ZStack {
                            Image("retake_icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)

                        }
                    }
                }

                Text(viewModel.selectedImage == nil ? "Upload Photo" : "Change Photo")
                    .font(Font.custom("PlusJakartaSans-SemiBold", size: 16))
                    .foregroundColor(.white)

                Text("JPG or PNG, clear front-facing photo works best")
                    .font(Font.custom("Inter", size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(cardBg)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(cardDashedBorder, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Continue button

    private var continueButton: some View {
        Button(action: {
            guard let image = viewModel.onContinueTapped() else { return }
            editorStartingImage = image
            navigateToEditor = true
        }) {
            Text("Continue")
                .font(Font.custom("Inter", size: 16).weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.red)
                .clipShape(Capsule())
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.features) { feature in
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(featureIconBg)
                            .frame(width: 44, height: 44)
                        Image(systemName: feature.iconSystemName)
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(Font.custom("PlusJakartaSans-SemiBold", size: 15))
                            .foregroundColor(featureTitleColor)
                        Text(feature.description)
                            .font(Font.custom("Inter", size: 12))
                            .foregroundColor(featureSubtitleColor)
                    }

                    Spacer()
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

#Preview {
    NavigationView { PhotoMakerView() }
}

