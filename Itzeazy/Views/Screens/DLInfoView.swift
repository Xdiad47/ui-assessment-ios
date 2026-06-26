import SwiftUI
import UIKit

struct DLInfoView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = DLInfoViewModel()
    @FocusState private var focusedField: Field?

    private enum Field {
        case dlNumber
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.10, green: 0.11, blue: 0.11).edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    ZStack(alignment: .top) {
                        Rectangle()
                            .fill(Color(red: 0.72, green: 0.72, blue: 0.72))
                            .frame(maxWidth: .infinity)
                            .frame(height: 62)
                            .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
                            .padding(.horizontal, 1)

                        Color(red: 0.10, green: 0.11, blue: 0.11)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))

                        HStack(spacing: 0) {
                            HStack(spacing: 12) {
                                Button(action: {
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Image("back_arrow")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                }
                                Text("DL DETAILS")
                                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            HStack(spacing: 16) {
                                Image(systemName: "bell")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)

                                ZStack {
                                    Circle()
                                        .fill(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                                        .frame(width: 30, height: 30)
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .frame(height: 60)
                    }

                    Spacer().frame(height: 32)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("DRIVING LICENCE NO")
                                .font(Font.custom("Inter", size: 12).weight(.semibold))
                                .foregroundColor(.white)

                            TextField(
                                "",
                                text: Binding(
                                    get: { viewModel.dlNumber },
                                    set: { viewModel.dlNumber = $0.uppercased() }
                                ),
                                prompt: Text("HR-654365124512445")
                                    .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                            )
                                .font(Font.custom("Inter", size: 13))
                                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)
                                .background(Color.white)
                                .cornerRadius(12)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .dlNumber)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("DATE OF BIRTH (DOB)")
                                .font(Font.custom("Inter", size: 12).weight(.semibold))
                                .foregroundColor(.white)

                            DOBTextField(text: $viewModel.dob)
                                .frame(height: 48)
                                .padding(.horizontal, 16)
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer().frame(height: 24)

                    HStack(spacing: 16) {
                        Button(action: {
                            viewModel.reset()
                        }) {
                            Text("RESET")
                                .font(Font.custom("Inter", size: 12).weight(.semibold))
                                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                                .frame(width: 115, height: 40)
                                .background(Color(red: 0.88, green: 0.89, blue: 0.89))
                                .clipShape(Capsule())
                        }

                        let canSearch = !viewModel.dlNumber.trimmingCharacters(in: .whitespaces).isEmpty
                                     && !viewModel.dob.trimmingCharacters(in: .whitespaces).isEmpty

                        Button(action: {
                            focusedField = nil
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            viewModel.getDetails()
                        }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(canSearch ? Color.red : Color.red.opacity(0.4))
                                    .clipShape(Capsule())
                            } else {
                                Text("CHECK STATUS")
                                    .font(Font.custom("Inter", size: 12).weight(.semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(canSearch ? Color.red : Color.red.opacity(0.4))
                                    .clipShape(Capsule())
                                    .shadow(color: Color.red.opacity(0.3), radius: 6, x: 0, y: 4)
                            }
                        }
                        .disabled(!canSearch || viewModel.isLoading)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                }
                .background(
                    Color(red: 0.10, green: 0.11, blue: 0.11)
                        .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                )

                Group {
                    if viewModel.isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.10, green: 0.11, blue: 0.11)))
                                .scaleEffect(1.3)
                            Text("FETCHING DL DETAILS…")
                                .font(Font.custom("Inter", size: 14))
                                .foregroundColor(Color(white: 0.5))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, 60)
                        .padding(.bottom, 85)

                    } else if let err = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundColor(Color(red: 0.93, green: 0.13, blue: 0.14))
                            Text(err.uppercased())
                                .font(Font.custom("Inter", size: 14))
                                .foregroundColor(Color(white: 0.4))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, 60)
                        .padding(.bottom, 85)

                    } else if viewModel.hasSearched, let info = viewModel.dlInfo {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 24) {
                                DLBasicInfoSection(info: info)
                                DLInitialDetailsSection(info: info)
                                DLValiditySection(info: info)
                                DLCOVSection(info: info)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 24)
                            .padding(.bottom, 85)
                        }

                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "creditcard.viewfinder")
                                .font(.system(size: 36))
                                .foregroundColor(Color(white: 0.75))
                            Text("ENTER DL NUMBER AND DATE OF BIRTH\nTO VIEW DETAILS")
                                .font(Font.custom("Inter", size: 14))
                                .foregroundColor(Color(white: 0.55))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, 60)
                        .padding(.bottom, 85)
                    }
                }
                .background(Color(white: 0.98).edgesIgnoringSafeArea(.bottom))
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Section Components

private struct DLSectionHeader: View {
    let title: String
    @State private var lineWidth: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(Font.custom("PlusJakartaSans-ExtraBold", size: 15))
                .foregroundColor(.black)
                .background(
                    GeometryReader { geo in
                        Color.clear.onAppear { lineWidth = geo.size.width }
                    }
                )
            Rectangle()
                .fill(Color.red)
                .frame(width: lineWidth + 5, height: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DLInfoCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(white: 0.88), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

private struct DLInfoRow: View {
    let label: String
    var isLast: Bool = false
    @ViewBuilder let valueContent: () -> AnyView

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(label.uppercased())
                    .font(Font.custom("Inter", size: 13).weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 140, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 16)
                    .frame(maxHeight: .infinity)
                    .background(Color(red: 0.10, green: 0.11, blue: 0.11))

                Rectangle()
                    .fill(Color(white: 0.85))
                    .frame(width: 1)

                valueContent()
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 16)
                    .background(Color.white)
            }

            if !isLast {
                Rectangle()
                    .fill(Color(white: 0.88))
                    .frame(height: 1)
            }
        }
    }
}

// MARK: - Section Views

private struct DLBasicInfoSection: View {
    let info: DLInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DLSectionHeader(title: "DETAILS OF DRIVING LICENSE: \(info.dlNumber)")

            DLInfoCard {
                DLInfoRow(label: "Current Status") {
                    AnyView(
                        Text(info.currentStatus.uppercased())
                            .font(Font.custom("Inter", size: 11).weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color(red: 0.18, green: 0.72, blue: 0.42))
                            .cornerRadius(6)
                    )
                }
                DLInfoRow(label: "Holder Name") {
                    AnyView(
                        Text(info.holderName.uppercased())
                            .font(Font.custom("Inter", size: 13))
                            .foregroundColor(Color(white: 0.2))
                    )
                }
                DLInfoRow(label: "Old/New DL No.") {
                    AnyView(
                        Text(info.oldNewDLNumber.uppercased())
                            .font(Font.custom("Inter", size: 13))
                            .foregroundColor(Color(white: 0.2))
                    )
                }
                DLInfoRow(label: "Source Of Data", isLast: true) {
                    AnyView(
                        Text(info.sourceOfData.uppercased())
                            .font(Font.custom("Inter", size: 13))
                            .foregroundColor(Color(white: 0.2))
                    )
                }
            }
        }
    }
}

private struct DLInitialDetailsSection: View {
    let info: DLInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DLSectionHeader(title: "DRIVING LICENS INITIAL DETAILS")

            DLInfoCard {
                DLInfoRow(label: "Initial Issue Date") {
                    AnyView(
                        Text(info.initialIssueDate.uppercased())
                            .font(Font.custom("Inter", size: 13))
                            .foregroundColor(Color(white: 0.2))
                    )
                }
                DLInfoRow(label: "Initial Issuing Office", isLast: true) {
                    AnyView(
                        Text(info.initialIssuingOffice.uppercased())
                            .font(Font.custom("Inter", size: 13))
                            .foregroundColor(Color(white: 0.2))
                    )
                }
            }
        }
    }
}

private struct DLValiditySection: View {
    let info: DLInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DLSectionHeader(title: "DRIVING LICENS VALIDITY DETAILS")

            DLInfoCard {
                // Non-Transport row
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text("NON-TRANSPORT")
                            .font(Font.custom("Inter", size: 13).weight(.semibold))
                            .foregroundColor(.white)
                            .frame(width: 140, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 16)
                            .frame(maxHeight: .infinity)
                            .background(Color(red: 0.10, green: 0.11, blue: 0.11))

                        Rectangle()
                            .fill(Color(white: 0.85))
                            .frame(width: 1)

                        HStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("FROM:")
                                    .font(Font.custom("Inter", size: 11))
                                    .foregroundColor(Color(white: 0.55))
                                Text(info.nonTransportFrom.uppercased())
                                    .font(Font.custom("Inter", size: 13))
                                    .foregroundColor(Color(white: 0.2))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 14)

                            Rectangle()
                                .fill(Color(white: 0.88))
                                .frame(width: 1)
                                .padding(.vertical, 8)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("TO:")
                                    .font(Font.custom("Inter", size: 11))
                                    .foregroundColor(Color(white: 0.55))
                                Text(info.nonTransportTo.uppercased())
                                    .font(Font.custom("Inter", size: 13))
                                    .foregroundColor(Color(white: 0.2))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 10)
                            .padding(.trailing, 14)
                        }
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                    }

                    Rectangle()
                        .fill(Color(white: 0.88))
                        .frame(height: 1)
                }

                // Transport row
                HStack(spacing: 0) {
                    Text("TRANSPORT")
                        .font(Font.custom("Inter", size: 13).weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 140, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 16)
                        .frame(maxHeight: .infinity)
                        .background(Color(red: 0.10, green: 0.11, blue: 0.11))

                    Rectangle()
                        .fill(Color(white: 0.85))
                        .frame(width: 1)

                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("FROM:")
                                .font(Font.custom("Inter", size: 11))
                                .foregroundColor(Color(white: 0.55))
                            Text(info.transportFrom.uppercased())
                                .font(Font.custom("Inter", size: 13))
                                .foregroundColor(Color(white: 0.2))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 14)

                        Rectangle()
                            .fill(Color(white: 0.88))
                            .frame(width: 1)
                            .padding(.vertical, 8)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("TO:")
                                .font(Font.custom("Inter", size: 11))
                                .foregroundColor(Color(white: 0.55))
                            Text(info.transportTo.uppercased())
                                .font(Font.custom("Inter", size: 13))
                                .foregroundColor(Color(white: 0.2))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 10)
                        .padding(.trailing, 14)
                    }
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                }
            }
        }
    }
}

private struct DLCOVSection: View {
    let info: DLInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DLSectionHeader(title: "CLASS OF VEHICLE DETAILS")

            VStack(spacing: 0) {
                // Header row
                HStack(spacing: 0) {
                    Text("COV CATEGORY")
                        .font(Font.custom("Inter", size: 12).weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.10, green: 0.11, blue: 0.11))

                    Rectangle()
                        .fill(Color(white: 0.25))
                        .frame(width: 1)

                    Text("CLASS OF VEHICLE")
                        .font(Font.custom("Inter", size: 12).weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.10, green: 0.11, blue: 0.11))

                    Rectangle()
                        .fill(Color(white: 0.25))
                        .frame(width: 1)

                    Text("COV ISSUE DATE")
                        .font(Font.custom("Inter", size: 12).weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.10, green: 0.11, blue: 0.11))
                }

                // Data rows
                ForEach(Array(info.covDetails.enumerated()), id: \.element.id) { index, detail in
                    Rectangle()
                        .fill(Color(white: 0.88))
                        .frame(height: 1)

                    HStack(spacing: 0) {
                        Text(detail.category.uppercased())
                            .font(Font.custom("Inter", size: 13))
                            .foregroundColor(Color(white: 0.2))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)

                        Rectangle()
                            .fill(Color(white: 0.88))
                            .frame(width: 1)

                        Text(detail.classOfVehicle.uppercased())
                            .font(Font.custom("Inter", size: 13))
                            .foregroundColor(Color(white: 0.2))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)

                        Rectangle()
                            .fill(Color(white: 0.88))
                            .frame(width: 1)

                        Text(detail.issueDate.uppercased())
                            .font(Font.custom("Inter", size: 13))
                            .foregroundColor(Color(white: 0.2))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                    }
                }
            }
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(white: 0.88), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
        }
    }
}

// MARK: - DOB Text Field

private struct DOBTextField: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.keyboardType = .numberPad
        tf.delegate = context.coordinator
        tf.font = UIFont(name: "Inter", size: 13) ?? .systemFont(ofSize: 13)
        tf.textColor = UIColor(red: 0.10, green: 0.11, blue: 0.11, alpha: 1)
        tf.attributedPlaceholder = NSAttributedString(
            string: "DD-MM-YYYY",
            attributes: [
                .foregroundColor: UIColor(red: 0.42, green: 0.45, blue: 0.50, alpha: 1),
                .font: UIFont(name: "Inter", size: 13) ?? UIFont.systemFont(ofSize: 13)
            ]
        )
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text { uiView.text = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        init(text: Binding<String>) { _text = text }

        func textField(_ textField: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            let current = textField.text ?? ""
            guard let r = Range(range, in: current) else { return false }
            let proposed = current.replacingCharacters(in: r, with: string)

            if string.isEmpty {
                var v = proposed
                if v.hasSuffix("-") { v = String(v.dropLast()) }
                textField.text = v
                text = v
            } else {
                guard string.allSatisfy(\.isNumber) else { return false }
                let formatted = DLInfoViewModel.formatDOBInput(proposed)
                guard formatted.count <= 10 else { return false }
                textField.text = formatted
                text = formatted
            }
            return false
        }
    }
}

#Preview {
    DLInfoView()
}
