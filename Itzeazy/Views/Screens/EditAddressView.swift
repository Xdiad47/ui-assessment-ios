import SwiftUI

struct EditAddressView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: EditAddressViewModel

    private let dark        = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
    private let bgColor     = Color(red: 0.96, green: 0.96, blue: 0.96)

    init(mode: EditAddressMode) {
        _viewModel = StateObject(wrappedValue: EditAddressViewModel(mode: mode))
    }

    var body: some View {
        ZStack(alignment: .top) {
            dark.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar

                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .red))
                        .scaleEffect(1.2)
                    Spacer()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            formCard
                            saveButton
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                    .background(bgColor)
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: viewModel.didSaveSuccessfully) { success in
            if success { presentationMode.wrappedValue.dismiss() }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil && !viewModel.isSaving },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(strokeColor)
                .frame(maxWidth: .infinity, maxHeight: 62)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
                .padding(.horizontal, 1)

            dark
                .frame(maxWidth: .infinity, maxHeight: 60)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))

            HStack(spacing: 12) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)

                Text(viewModel.navigationTitle)
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
        }
    }

    // MARK: - Form Card

    private var formCard: some View {
        VStack(spacing: 0) {
            AddressTextField(label: "Full Name",          text: $viewModel.userName,  keyboardType: .default)
            fieldDivider
            AddressTextField(label: "Mobile Number",      text: $viewModel.mobile,    keyboardType: .phonePad)
            fieldDivider
            AddressTextField(label: "Email",              text: $viewModel.email,     keyboardType: .emailAddress)
            fieldDivider
            AddressTextField(label: "Flat / House No.",   text: $viewModel.flatHouse, keyboardType: .default)
            fieldDivider
            AddressTextField(label: "Area / Colony",      text: $viewModel.area,      keyboardType: .default)
            fieldDivider
            AddressTextField(label: "Landmark",           text: $viewModel.landmark,  keyboardType: .default)
            fieldDivider
            AddressTextField(label: "City",               text: $viewModel.city,      keyboardType: .default)
            fieldDivider
            AddressTextField(label: "State",              text: $viewModel.state,     keyboardType: .default)
            fieldDivider
            AddressTextField(label: "Country",            text: $viewModel.country,   keyboardType: .default)
            fieldDivider
            AddressTextField(label: "Pin Code",           text: $viewModel.pinCode,   keyboardType: .numberPad)
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(strokeColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var fieldDivider: some View {
        Divider()
            .overlay(Color.black.opacity(0.06))
            .padding(.horizontal, 16)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: { viewModel.save() }) {
            ZStack {
                if viewModel.isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("SAVE ADDRESS")
                        .font(Font.custom("PlusJakartaSans-ExtraBold", size: 15))
                        .foregroundColor(.white)
                        .tracking(0.5)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(viewModel.isSaving ? Color.red.opacity(0.7) : Color.red)
            .cornerRadius(16)
            .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(viewModel.isSaving)
    }
}

// MARK: - Reusable Text Field Row

private struct AddressTextField: View {
    let label: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(Font.custom("Inter", size: 11).weight(.medium))
                .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))

            TextField("", text: $text)
                .font(Font.custom("PlusJakartaSans-SemiBold", size: 14))
                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationView {
        EditAddressView(mode: .create)
    }
}
