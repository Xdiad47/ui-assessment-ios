import SwiftUI
import UIKit

// MARK: - DummyTicketBothPersonalDetailsView
// Figma: "Passenger Details", shown on-screen as "Personal Details" (node 3497:8738) — the Both
// flow's own step 2, reached from DummyTicketBothRouteDetailsView's NEXT button. Contact
// Information and Passenger cards are the same fully-editable fields/behavior as Flight's own
// DummyTicketPersonalDetailsView (same "Edit" -> coming-soon-toast convention on Contact
// Information — its fields are already inline-editable right here, so that link has nowhere real
// to go, exactly like Flight's own screen — and the same "+ Add Passenger" mechanism), just
// re-styled with this frame's own thin-border card look instead of Flight's thicker rounded cards.
//
// New here, with no Flight equivalent: a Hotel Guest Preferences card (Bedding Preference, Smoking
// Preference, Special Requests) and a Booking Summary card (FLIGHT+HOTEL+Taxes+TOTAL) in place of
// Flight's own single-service Flight Summary card. Both reuse fields already established elsewhere
// in this flow rather than introducing new ones: Bedding Preference is booking.bedConfiguration
// (from the Hotel Personal Details screen, and reuses the very same king_bed_icon/twin_beds_icon
// assets), Smoking Preference is booking.smokingPreference — rendered here as a single toggle per
// this frame's design rather than Hotel's own two-button picker, but both read/write the identical
// field — and Special Requests is booking.hotelSpecialRequests. The Booking Summary card mirrors
// DummyTicketBothRouteDetailsView's own card exactly, including its recomputed ₹1,178 total; see
// that file's top comment for why.
//
// NEXT pushes DummyTicketBothAdditionalDetailsView (Both's dedicated step 3, node 3497:8399).

struct DummyTicketBothPersonalDetailsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var tabBarState: TabBarState
    @EnvironmentObject private var booking: DummyTicketBookingViewModel
    @FocusState private var focusedField: Field?

    @State private var showTitlePicker = false
    @State private var showGenderPicker = false
    @State private var showNationalityPicker = false
    @State private var showCountryCodePicker = false
    @State private var showDOBPicker = false

    private enum Field {
        case mobile, email, firstName, lastName, passport, specialRequests
    }

    private let titleOptions = ["Mr.", "Mrs.", "Ms.", "Dr."]
    private let genderOptions = ["Male", "Female", "Other"]

    private let brandRed = Color(red: 1, green: 0, blue: 0)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
    private let darkCard = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let darkText = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let labelGray = Color(red: 0.631, green: 0.631, blue: 0.667)
    private let placeholderGray = Color(red: 0.42, green: 0.447, blue: 0.502)
    private let dimText = Color(red: 0.714, green: 0.714, blue: 0.722)
    private let lightFill = Color(red: 0.953, green: 0.957, blue: 0.961)

    // Same fixed placeholder fees as DummyTicketBothRouteDetailsView — see that file's top comment.
    private let flightFee = "₹499"
    private let hotelFee = "₹499"
    private let taxesText = "₹180"
    private let totalText = "₹1,178"

    private static let dobFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    private var dobText: String {
        guard let dob = booking.dateOfBirth else { return "DD / MM / YYYY" }
        return Self.dobFormatter.string(from: dob)
    }

    private var isNonSmoking: Binding<Bool> {
        Binding(
            get: { booking.smokingPreference == .nonSmoking },
            set: { booking.smokingPreference = $0 ? .nonSmoking : .smoking }
        )
    }

    private var routeOriginText: String {
        booking.fromLocation.isEmpty ? "—" : booking.fromLocation
    }

    private var routeDestinationText: String {
        booking.toLocation.isEmpty ? "—" : booking.toLocation
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color.white.ignoresSafeArea(.container, edges: .vertical)

                VStack(spacing: 0) {
                    header(safeAreaTop: proxy.safeAreaInsets.top)

                    ScrollView(showsIndicators: false) {
                        content
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                NavigationLink(
                    destination: DummyTicketBothAdditionalDetailsView().environmentObject(booking),
                    isActive: $booking.showAdditionalDetails
                ) {
                    EmptyView()
                }
                .hidden()
            }
            .ignoresSafeArea(.container, edges: .vertical)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showTitlePicker) {
            PickerSheetView(
                title: "Choose Title",
                items: titleOptions.map { IdentifiableString(value: $0) },
                displayText: { $0.value },
                onSelect: { booking.title = $0.value }
            )
            .environmentObject(booking)
        }
        .sheet(isPresented: $showGenderPicker) {
            PickerSheetView(
                title: "Choose Gender",
                items: genderOptions.map { IdentifiableString(value: $0) },
                displayText: { $0.value },
                onSelect: { booking.gender = $0.value }
            )
            .environmentObject(booking)
        }
        .sheet(isPresented: $showNationalityPicker) {
            PickerSheetView(
                title: "Choose Nationality",
                items: countries,
                displayText: { $0.name },
                isSearchable: true,
                onSelect: { booking.nationality = $0 }
            )
            .environmentObject(booking)
        }
        .sheet(isPresented: $showCountryCodePicker) {
            PickerSheetView(
                title: "Choose Country Code",
                items: countries,
                displayText: { "\($0.name) (\($0.phoneCode))" },
                isSearchable: true,
                onSelect: { booking.mobileCountry = $0 }
            )
            .environmentObject(booking)
        }
        .sheet(isPresented: $showDOBPicker) {
            dobPickerSheet
                .environmentObject(booking)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            tabBarState.isHidden = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            tabBarState.isHidden = false
        }
        .onDisappear {
            tabBarState.isHidden = false
        }
    }

    // MARK: - Header (back row + 5-step progress)

    private func header(safeAreaTop: CGFloat) -> some View {
        VStack(spacing: 0) {
            darkCard.frame(height: safeAreaTop)

            HStack(spacing: 6) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text("Back")
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                    .tracking(-0.9)
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "bell")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            .frame(height: 50)

            flowStepper
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .background(darkCard)
        .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
    }

    private var flowStepper: some View {
        let currentStep = 2
        let steps: [(number: Int, label: String)] = [
            (1, "Route\nDetails"),
            (2, "Passenger\nDetails"),
            (3, "Additional\nDetails"),
            (4, "Review\nBooking"),
            (5, "Payment")
        ]

        return HStack(alignment: .top, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(step.number <= currentStep ? brandRed : Color(red: 0.906, green: 0.910, blue: 0.914))
                            .frame(width: 28, height: 28)
                        if step.number <= currentStep {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(step.number)")
                                .font(Font.custom("PlusJakartaSans-Bold", size: 12))
                                .foregroundColor(Color(red: 0.373, green: 0.369, blue: 0.369))
                        }
                    }
                    Text(step.label)
                        .font(Font.custom("PlusJakartaSans-Bold", size: 9))
                        .foregroundColor(step.number <= currentStep ? .white : Color(red: 0.792, green: 0.792, blue: 0.792))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .fixedSize()
                }
                .frame(maxWidth: .infinity)

                if index < steps.count - 1 {
                    Rectangle()
                        .fill(step.number < currentStep ? brandRed : Color(red: 0.929, green: 0.933, blue: 0.937))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 14)
                }
            }
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Personal Details")
                .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                .tracking(-0.75)
                .foregroundColor(darkText)

            contactInformationCard
            passengerCard
            hotelGuestPreferencesCard
            bookingSummaryCard
            navigationButtons
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, max(24, tabBarState.height + 16))
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = nil
        }
    }

    // MARK: - Card shell (dark header + white body)

    private func infoCard<Content: View>(
        icon: String,
        title: String,
        trailingLabel: String? = nil,
        trailingAction: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                Text(title)
                    .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                    .foregroundColor(.white)
                Spacer(minLength: 8)
                if let trailingLabel, let trailingAction {
                    Button(action: trailingAction) {
                        Text(trailingLabel)
                            .font(Font.custom("Inter-Bold", size: 14))
                            .foregroundColor(brandRed)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(darkCard)

            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .padding(20)
            .background(Color.white)
        }
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Contact Information card

    private var contactInformationCard: some View {
        infoCard(icon: "phone.circle.fill", title: "Contact Information", trailingLabel: "Edit", trailingAction: { focusedField = .mobile }) {
            mobileNumberField
            formField(label: "EMAIL ADDRESS", value: $booking.emailAddress, placeholder: "Email Address", keyboardType: .emailAddress, focus: .email)
        }
    }

    private var mobileNumberField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MOBILE NUMBER")
                .font(Font.custom("Inter-Bold", size: 11))
                .tracking(1.1)
                .foregroundColor(labelGray)

            HStack(spacing: 8) {
                Button(action: { showCountryCodePicker = true }) {
                    HStack(spacing: 6) {
                        Text(booking.mobileCountry.phoneCode)
                            .font(Font.custom("Inter", size: 14).weight(.medium))
                            .foregroundColor(darkText)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(placeholderGray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 13)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(strokeColor, lineWidth: 0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                TextField("Mobile Number", text: $booking.mobileNumber)
                    .font(Font.custom("Inter", size: 14))
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .mobile)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(strokeColor, lineWidth: 0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Passenger card

    private var passengerCard: some View {
        VStack(spacing: 16) {
            infoCard(icon: "person.crop.circle.fill", title: "Passenger", trailingLabel: "+ Add Passenger", trailingAction: { booking.addPassenger() }) {
                HStack(alignment: .top, spacing: 12) {
                    dropdownField(label: "TITLE", value: booking.title, action: { showTitlePicker = true })
                        .frame(width: 92)
                    formField(label: "FIRST NAME", value: $booking.firstName, placeholder: "First Name", focus: .firstName)
                }

                formField(label: "LAST NAME", value: $booking.lastName, placeholder: "Last Name", focus: .lastName)

                HStack(alignment: .top, spacing: 12) {
                    dobField.frame(maxWidth: .infinity)
                    dropdownField(label: "GENDER", value: booking.gender, action: { showGenderPicker = true })
                        .frame(maxWidth: .infinity)
                }

                formField(label: "PASSPORT NUMBER", value: $booking.passportNumber, placeholder: "Passport Number", focus: .passport)

                dropdownField(label: "NATIONALITY", value: booking.nationality.name, action: { showNationalityPicker = true })
            }

            ForEach($booking.additionalPassengers) { $passenger in
                DummyTicketBothAdditionalPassengerCard(
                    passenger: $passenger,
                    number: passengerNumber(for: passenger.id),
                    onRemove: { booking.removePassenger(passenger.id) }
                )
            }
        }
    }

    private func passengerNumber(for id: DummyTicketPassenger.ID) -> Int {
        (booking.additionalPassengers.firstIndex(where: { $0.id == id }).map { $0 + 2 }) ?? 2
    }

    private var dobField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DATE OF BIRTH")
                .font(Font.custom("Inter-Bold", size: 11))
                .tracking(1.1)
                .foregroundColor(labelGray)

            Button(action: { showDOBPicker = true }) {
                HStack {
                    Text(dobText)
                        .font(Font.custom("Inter", size: 14).weight(.medium))
                        .foregroundColor(booking.dateOfBirth == nil ? placeholderGray : darkText)
                    Spacer()
                    Image(systemName: "calendar")
                        .font(.system(size: 13))
                        .foregroundColor(placeholderGray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(strokeColor, lineWidth: 0.8))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Shared field styles

    private func formField(label: String, value: Binding<String>, placeholder: String, keyboardType: UIKeyboardType = .default, focus: Field) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Font.custom("Inter-Bold", size: 11))
                .tracking(1.1)
                .foregroundColor(labelGray)

            TextField(placeholder, text: value)
                .font(Font.custom("Inter", size: 14))
                .keyboardType(keyboardType)
                .focused($focusedField, equals: focus)
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(strokeColor, lineWidth: 0.8))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func dropdownField(label: String, value: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Font.custom("Inter-Bold", size: 11))
                .tracking(1.1)
                .foregroundColor(labelGray)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Button(action: action) {
                HStack(spacing: 4) {
                    Text(value)
                        .font(Font.custom("Inter", size: 14).weight(.medium))
                        .foregroundColor(darkText)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(placeholderGray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 13)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(strokeColor, lineWidth: 0.8))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Hotel Guest Preferences card

    private var hotelGuestPreferencesCard: some View {
        infoCard(icon: "bed.double.fill", title: "Hotel Guest Preferences") {
            VStack(alignment: .leading, spacing: 16) {
                Text("BEDDING PREFERENCE")
                    .font(Font.custom("Inter-Bold", size: 11))
                    .tracking(1.1)
                    .foregroundColor(labelGray)

                HStack(spacing: 12) {
                    beddingButton(isSelected: booking.bedConfiguration == .kingBed, assetName: "king_bed_icon", label: "King Bed") {
                        booking.bedConfiguration = .kingBed
                    }
                    beddingButton(isSelected: booking.bedConfiguration == .twinBeds, assetName: "twin_beds_icon", label: "Twin Beds") {
                        booking.bedConfiguration = .twinBeds
                    }
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("SMOKING PREFERENCE")
                    .font(Font.custom("Inter-Bold", size: 11))
                    .tracking(1.1)
                    .foregroundColor(labelGray)

                HStack(spacing: 12) {
                    Image("non_smoking_icon")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 21, height: 21)
                        .foregroundColor(darkText)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Non-Smoking Room")
                            .font(Font.custom("Inter-Bold", size: 14))
                            .foregroundColor(darkText)
                        Text("Subject to availability")
                            .font(Font.custom("Inter", size: 10))
                            .foregroundColor(placeholderGray)
                    }

                    Spacer()

                    Toggle("", isOn: isNonSmoking)
                        .labelsHidden()
                        .tint(brandRed)
                }
                .padding(16)
                .background(lightFill)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Special Requests (Optional)")
                    .font(Font.custom("Inter", size: 12).weight(.medium))
                    .foregroundColor(placeholderGray)

                TextEditor(text: $booking.hotelSpecialRequests)
                    .font(Font.custom("Inter", size: 14).weight(.medium))
                    .foregroundColor(darkText)
                    .focused($focusedField, equals: .specialRequests)
                    .frame(height: 70)
                    .scrollContentBackground(.hidden)
                    .overlay(
                        Group {
                            if booking.hotelSpecialRequests.isEmpty {
                                Text("e.g. High floor, quiet room, late check-in...")
                                    .font(Font.custom("Inter", size: 14).weight(.medium))
                                    .foregroundColor(strokeColor)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )
                    .padding(.horizontal, 2)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(strokeColor, lineWidth: 0.6))
            }
        }
    }

    private func beddingButton(isSelected: Bool, assetName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(assetName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15, height: 10.5)
                    .foregroundColor(isSelected ? brandRed : placeholderGray)
                Text(label)
                    .font(Font.custom("Inter-Bold", size: 12))
                    .foregroundColor(isSelected ? brandRed : Color(red: 0.373, green: 0.369, blue: 0.369))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? brandRed.opacity(0.05) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? brandRed : Color(red: 0.906, green: 0.910, blue: 0.914), lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Booking Summary card

    private var bookingSummaryCard: some View {
        VStack(spacing: 0) {
            Text("Booking Summary")
                .font(Font.custom("Inter-Bold", size: 16))
                .tracking(-0.4)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .frame(height: 57)
                .background(brandRed)

            VStack(spacing: 16) {
                summaryRow(icon: "airplane", label: "FLIGHT", detail: "\(routeOriginText) → \(routeDestinationText)", price: flightFee)
                summaryRow(icon: "bed.double.fill", label: "HOTEL", detail: booking.hotelCity.isEmpty ? "—" : booking.hotelCity, price: hotelFee)

                HStack {
                    Text("Taxes (GST)")
                        .font(Font.custom("Inter", size: 12))
                        .foregroundColor(dimText)
                    Spacer()
                    Text(taxesText)
                        .font(Font.custom("Inter-Bold", size: 14))
                        .foregroundColor(dimText)
                }
                .padding(.top, 17)
                .overlay(Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1), alignment: .top)

                HStack(alignment: .lastTextBaseline) {
                    Text("TOTAL")
                        .font(Font.custom("Inter-Bold", size: 20))
                        .tracking(1.2)
                        .foregroundColor(.white)
                    Spacer()
                    Text(totalText)
                        .font(Font.custom("Inter-Bold", size: 24))
                        .foregroundColor(brandRed)
                }
                .padding(.top, 18)
                .overlay(Rectangle().fill(Color.white.opacity(0.15)).frame(height: 2), alignment: .top)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(darkCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func summaryRow(icon: String, label: String, detail: String, price: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.white).frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(darkCard)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Font.custom("Inter-Bold", size: 12))
                    .tracking(0.6)
                    .foregroundColor(.white)
                Text(detail)
                    .font(Font.custom("Inter", size: 14).weight(.semibold))
                    .foregroundColor(dimText)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(price)
                .font(Font.custom("Inter-Bold", size: 14))
                .foregroundColor(dimText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Previous / Next

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(brandRed)
                    Text("PREVIOUS")
                        .font(Font.custom("Inter-Bold", size: 14))
                        .foregroundColor(darkText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .overlay(Capsule().stroke(brandRed, lineWidth: 1))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button(action: { booking.showAdditionalDetails = true }) {
                HStack(spacing: 8) {
                    Text("NEXT")
                        .font(Font.custom("Inter-Bold", size: 14))
                        .foregroundColor(.white)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(brandRed)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Date of birth sheet

    private var dobPickerSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { showDOBPicker = false }
                    .foregroundColor(.secondary)
                Spacer()
                Text("Date of Birth")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                Spacer()
                Button("Done") { showDOBPicker = false }
                    .font(.body.bold())
                    .foregroundColor(brandRed)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            DatePicker(
                "Date of Birth",
                selection: Binding(
                    get: { booking.dateOfBirth ?? Date() },
                    set: { booking.dateOfBirth = $0 }
                ),
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(brandRed)
            .labelsHidden()
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .presentationDetents([.height(420)])
    }
}

// MARK: - DummyTicketBothAdditionalPassengerCard
// One "Passenger N" card for a passenger added via "+ Add Passenger" — mirrors
// DummyTicketPersonalDetailsView's own DummyTicketAdditionalPassengerCard exactly (that one is
// file-private to its own file, so this is a duplicate rather than a shared type, matching the
// established pattern of a self-contained per-flow card already used for
// DummyTicketHotelGuestCard).
private struct DummyTicketBothAdditionalPassengerCard: View {
    @Binding var passenger: DummyTicketPassenger
    let number: Int
    let onRemove: () -> Void

    @FocusState private var focusedField: Field?
    @State private var showTitlePicker = false
    @State private var showGenderPicker = false
    @State private var showNationalityPicker = false
    @State private var showDOBPicker = false

    private enum Field {
        case firstName, lastName, passport
    }

    private let titleOptions = ["Mr.", "Mrs.", "Ms.", "Dr."]
    private let genderOptions = ["Male", "Female", "Other"]

    private let brandRed = Color(red: 1, green: 0, blue: 0)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
    private let darkCard = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let darkText = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let labelGray = Color(red: 0.631, green: 0.631, blue: 0.667)
    private let placeholderGray = Color(red: 0.42, green: 0.447, blue: 0.502)

    private static let dobFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    private var dobText: String {
        guard let dob = passenger.dateOfBirth else { return "DD / MM / YYYY" }
        return Self.dobFormatter.string(from: dob)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                Text("Passenger \(number)")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                    .foregroundColor(.white)
                Spacer(minLength: 8)
                Button(action: onRemove) {
                    Text("Remove")
                        .font(Font.custom("Inter-Bold", size: 14))
                        .foregroundColor(brandRed)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(darkCard)

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    dropdownField(label: "TITLE", value: passenger.title, action: { showTitlePicker = true })
                        .frame(width: 92)
                    formField(label: "FIRST NAME", value: $passenger.firstName, placeholder: "First Name", focus: .firstName)
                }

                formField(label: "LAST NAME", value: $passenger.lastName, placeholder: "Last Name", focus: .lastName)

                HStack(alignment: .top, spacing: 12) {
                    dobField.frame(maxWidth: .infinity)
                    dropdownField(label: "GENDER", value: passenger.gender, action: { showGenderPicker = true })
                        .frame(maxWidth: .infinity)
                }

                formField(label: "PASSPORT NUMBER", value: $passenger.passportNumber, placeholder: "Passport Number", focus: .passport)

                dropdownField(label: "NATIONALITY", value: passenger.nationality.name, action: { showNationalityPicker = true })
            }
            .padding(20)
            .background(Color.white)
        }
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showTitlePicker) {
            PickerSheetView(
                title: "Choose Title",
                items: titleOptions.map { IdentifiableString(value: $0) },
                displayText: { $0.value },
                onSelect: { passenger.title = $0.value }
            )
        }
        .sheet(isPresented: $showGenderPicker) {
            PickerSheetView(
                title: "Choose Gender",
                items: genderOptions.map { IdentifiableString(value: $0) },
                displayText: { $0.value },
                onSelect: { passenger.gender = $0.value }
            )
        }
        .sheet(isPresented: $showNationalityPicker) {
            PickerSheetView(
                title: "Choose Nationality",
                items: countries,
                displayText: { $0.name },
                isSearchable: true,
                onSelect: { passenger.nationality = $0 }
            )
        }
        .sheet(isPresented: $showDOBPicker) {
            dobPickerSheet
        }
    }

    private var dobField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DATE OF BIRTH")
                .font(Font.custom("Inter-Bold", size: 11))
                .tracking(1.1)
                .foregroundColor(labelGray)

            Button(action: { showDOBPicker = true }) {
                HStack {
                    Text(dobText)
                        .font(Font.custom("Inter", size: 14).weight(.medium))
                        .foregroundColor(passenger.dateOfBirth == nil ? placeholderGray : darkText)
                    Spacer()
                    Image(systemName: "calendar")
                        .font(.system(size: 13))
                        .foregroundColor(placeholderGray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(strokeColor, lineWidth: 0.8))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }

    private func formField(label: String, value: Binding<String>, placeholder: String, focus: Field) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Font.custom("Inter-Bold", size: 11))
                .tracking(1.1)
                .foregroundColor(labelGray)

            TextField(placeholder, text: value)
                .font(Font.custom("Inter", size: 14))
                .focused($focusedField, equals: focus)
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(strokeColor, lineWidth: 0.8))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func dropdownField(label: String, value: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Font.custom("Inter-Bold", size: 11))
                .tracking(1.1)
                .foregroundColor(labelGray)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Button(action: action) {
                HStack(spacing: 4) {
                    Text(value)
                        .font(Font.custom("Inter", size: 14).weight(.medium))
                        .foregroundColor(darkText)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(placeholderGray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 13)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(strokeColor, lineWidth: 0.8))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }

    private var dobPickerSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { showDOBPicker = false }
                    .foregroundColor(.secondary)
                Spacer()
                Text("Date of Birth")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                Spacer()
                Button("Done") { showDOBPicker = false }
                    .font(.body.bold())
                    .foregroundColor(brandRed)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            DatePicker(
                "Date of Birth",
                selection: Binding(
                    get: { passenger.dateOfBirth ?? Date() },
                    set: { passenger.dateOfBirth = $0 }
                ),
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(brandRed)
            .labelsHidden()
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .presentationDetents([.height(420)])
    }
}

#Preview {
    NavigationView {
        DummyTicketBothPersonalDetailsView()
            .environmentObject(TabBarState())
            .environmentObject(DummyTicketBookingViewModel())
    }
}
