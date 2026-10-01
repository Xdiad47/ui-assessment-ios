import SwiftUI
import UIKit

// MARK: - DummyTicketHotelPersonalDetailsView
// Figma: "Route Details" frame, shown on-screen as "Personal Details" (node 3497:7146) — the
// Hotel flow's own step 2, reached from DummyTicketHotelRouteDetailsView's NEXT button. The
// header's own stepper labels this step "Guest Details", not "Passenger Details" — matching that,
// this screen calls its primary guest "Guest 1 (Primary)" and its add-another action "Add Guest +"
// rather than reusing Flight's "Passenger"/"+ Add Passenger" wording.
//
// Reuses Guest 1's OWN fields directly from the shared DummyTicketBookingViewModel — title,
// firstName, lastName, dateOfBirth, nationality, passportNumber — same properties Flight's
// DummyTicketPersonalDetailsView reads/writes, just without `gender` (Figma's Guest card has no
// gender field; Nationality shares DOB's row instead of getting its own row below Passport, unlike
// Flight's layout). NEXT pushes DummyTicketHotelAdditionalDetailsView — Hotel's own step 3 (node
// 3497:7346), not Flight's DummyTicketAdditionalDetailsView; none of that screen's fields (travel
// purpose, WhatsApp/Email PDF copy, Urgent Processing) apply to a hotel stay.
//
// New here, with no Flight equivalent: Stay Preferences (Smoking Preference, Bed Configuration).

struct DummyTicketHotelPersonalDetailsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var tabBarState: TabBarState
    @EnvironmentObject private var booking: DummyTicketBookingViewModel
    @FocusState private var focusedField: Field?

    @State private var showTitlePicker = false
    @State private var showNationalityPicker = false
    @State private var showDOBPicker = false

    private enum Field {
        case mobile, email, firstName, lastName, passport
    }

    private let titleOptions = ["Mr.", "Mrs.", "Ms.", "Dr."]

    private let brandRed = Color(red: 1, green: 0, blue: 0)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
    private let darkCard = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let darkText = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let mutedGray = Color(red: 0.42, green: 0.447, blue: 0.502)
    private let fieldLabelGray = Color(red: 0.373, green: 0.369, blue: 0.369)
    private let sectionLabelGray = Color(red: 0.10, green: 0.11, blue: 0.11).opacity(0.6)
    private let unselectedFill = Color(red: 0.953, green: 0.957, blue: 0.961)

    private static let dobFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    private var dobText: String {
        guard let dob = booking.dateOfBirth else { return "DD / MM / YYYY" }
        return Self.dobFormatter.string(from: dob)
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
                    destination: DummyTicketHotelAdditionalDetailsView().environmentObject(booking),
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
            (2, "Guest\nDetails"),
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
            guest1Card

            ForEach($booking.additionalGuests) { $guest in
                DummyTicketHotelGuestCard(
                    guest: $guest,
                    number: guestNumber(for: guest.id),
                    onRemove: { booking.removeGuest(guest.id) }
                )
            }

            stayPreferencesCard
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

    private func guestNumber(for id: DummyTicketGuest.ID) -> Int {
        (booking.additionalGuests.firstIndex(where: { $0.id == id }).map { $0 + 2 }) ?? 2
    }

    // MARK: - Contact Information card

    private var contactInformationCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "person.text.rectangle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                Text("CONTACT INFORMATION")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 14))
                    .tracking(1.4)
                    .foregroundColor(.white)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 17)
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(darkCard)

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    staticBoxField(value: "+\(booking.mobileCountry.phoneCode.filter(\.isNumber))")
                        .frame(width: 80)
                    editableBoxField(label: "Mobile Number", value: $booking.mobileNumber, placeholder: "Mobile Number", keyboardType: .numberPad, focus: .mobile)
                }
                editableBoxField(label: "Email Address", value: $booking.emailAddress, placeholder: "Email Address", keyboardType: .emailAddress, focus: .email)
            }
            .padding(10)
        }
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func staticBoxField(value: String) -> some View {
        Text(value)
            .font(Font.custom("Inter", size: 16).weight(.medium))
            .foregroundColor(darkText)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(16.8)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 0.8))
    }

    private func editableBoxField(label: String, value: Binding<String>, placeholder: String, keyboardType: UIKeyboardType = .default, focus: Field) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Font.custom("Inter", size: 12))
                .foregroundColor(mutedGray)
            TextField(placeholder, text: value)
                .font(Font.custom("Inter", size: 16).weight(.medium))
                .foregroundColor(darkText)
                .keyboardType(keyboardType)
                .focused($focusedField, equals: focus)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16.8)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 0.8))
    }

    // MARK: - Guest 1 (Primary) card

    private var guest1Card: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "person.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)

                (
                    Text("Guest 1 ")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                    + Text("(Primary)")
                        .font(Font.custom("PlusJakartaSans-Regular", size: 12))
                )
                .foregroundColor(.white)

                Spacer(minLength: 8)

                Button(action: { booking.addGuest() }) {
                    Text("Add Guest +")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 14))
                        .foregroundColor(brandRed)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 17)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(darkCard)

            VStack(spacing: 20) {
                HStack(alignment: .top, spacing: 16) {
                    guestDropdownField(label: "TITLE", value: booking.title, action: { showTitlePicker = true })
                        .frame(width: 102)
                    guestFormField(label: "FIRST NAME", value: $booking.firstName, placeholder: "First Name", focus: .firstName)
                }

                guestFormField(label: "LAST NAME", value: $booking.lastName, placeholder: "Last Name", focus: .lastName)

                HStack(alignment: .top, spacing: 16) {
                    guestDOBField(dateText: dobText, isPlaceholder: booking.dateOfBirth == nil) { showDOBPicker = true }
                        .frame(maxWidth: .infinity)
                    guestDropdownField(label: "NATIONALITY", value: booking.nationality.name, action: { showNationalityPicker = true })
                        .frame(maxWidth: .infinity)
                }

                guestFormField(label: "PASSPORT NUMBER", value: $booking.passportNumber, placeholder: "Enter passport if applicable", focus: .passport)
            }
            .padding(20)
        }
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Shared guest field styles (also used by DummyTicketHotelGuestCard's own private copies)

    private func guestFormField(label: String, value: Binding<String>, placeholder: String, focus: Field) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Font.custom("Inter-Bold", size: 10))
                .tracking(0.5)
                .foregroundColor(fieldLabelGray)

            TextField(placeholder, text: value)
                .font(Font.custom("Inter", size: 14).weight(.medium))
                .foregroundColor(darkText)
                .focused($focusedField, equals: focus)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 0.8))
        }
    }

    private func guestDropdownField(label: String, value: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Font.custom("Inter-Bold", size: 10))
                .tracking(0.5)
                .foregroundColor(fieldLabelGray)
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
                        .foregroundColor(mutedGray)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 0.8))
            }
            .buttonStyle(.plain)
        }
    }

    private func guestDOBField(dateText: String, isPlaceholder: Bool, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DATE OF BIRTH")
                .font(Font.custom("Inter-Bold", size: 10))
                .tracking(0.5)
                .foregroundColor(fieldLabelGray)

            Button(action: action) {
                HStack {
                    Text(dateText)
                        .font(Font.custom("Inter", size: 14).weight(.medium))
                        .foregroundColor(isPlaceholder ? mutedGray : darkText)
                    Spacer()
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(mutedGray)
                }
                .padding(12)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 0.8))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Stay preferences card

    private var stayPreferencesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 14))
                    .foregroundColor(brandRed)
                    .frame(width: 28, height: 28)
                    .background(Color.white)
                    .clipShape(Circle())
                Text("STAY PREFERENCES")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 14))
                    .tracking(1.4)
                    .foregroundColor(.white)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 17)
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(darkCard)

            VStack(alignment: .leading, spacing: 16) {
                Text("SMOKING PREFERENCE")
                    .font(Font.custom("Inter-Bold", size: 12))
                    .tracking(-0.3)
                    .foregroundColor(sectionLabelGray)

                HStack(spacing: 16) {
                    smokingPreferenceButton(
                        isSelected: booking.smokingPreference == .nonSmoking,
                        assetName: "non_smoking_icon",
                        label: "Non-Smoking"
                    ) { booking.smokingPreference = .nonSmoking }

                    smokingPreferenceButton(
                        isSelected: booking.smokingPreference == .smoking,
                        assetName: "smoking_icon",
                        label: "Smoking"
                    ) { booking.smokingPreference = .smoking }
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 16)

            VStack(alignment: .leading, spacing: 16) {
                Text("BED CONFIGURATION")
                    .font(Font.custom("Inter-Bold", size: 12))
                    .tracking(-0.3)
                    .foregroundColor(sectionLabelGray)

                HStack(spacing: 16) {
                    bedPreferenceButton(
                        isSelected: booking.bedConfiguration == .kingBed,
                        assetName: "king_bed_icon",
                        label: "King Bed"
                    ) { booking.bedConfiguration = .kingBed }

                    bedPreferenceButton(
                        isSelected: booking.bedConfiguration == .twinBeds,
                        assetName: "twin_beds_icon",
                        label: "Twin Beds"
                    ) { booking.bedConfiguration = .twinBeds }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 16)
        }
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func smokingPreferenceButton(isSelected: Bool, assetName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(assetName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 21, height: 21)
                    .foregroundColor(isSelected ? brandRed : mutedGray)
                Text(label)
                    .font(Font.custom("Inter-Bold", size: 12))
                    .foregroundColor(isSelected ? brandRed : mutedGray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(isSelected ? brandRed.opacity(0.05) : unselectedFill)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? brandRed : strokeColor, lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private func bedPreferenceButton(isSelected: Bool, assetName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(assetName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 14)
                    .foregroundColor(isSelected ? brandRed : mutedGray)
                Text(label)
                    .font(Font.custom("Inter-Bold", size: 12))
                    .foregroundColor(isSelected ? brandRed : mutedGray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(isSelected ? brandRed.opacity(0.05) : unselectedFill)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? brandRed : strokeColor, lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
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

    // MARK: - Date of birth sheet (Guest 1)

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

// MARK: - DummyTicketHotelGuestCard
// One "Guest N" card for a guest added via "Add Guest +" — self-contained (its own picker sheets
// bound to `guest` instead of the shared booking model), mirroring DummyTicketAdditionalPassengerCard
// on the Flight side but without a gender field, matching Guest 1's own field set above.
private struct DummyTicketHotelGuestCard: View {
    @Binding var guest: DummyTicketGuest
    let number: Int
    let onRemove: () -> Void

    @FocusState private var focusedField: Field?
    @State private var showTitlePicker = false
    @State private var showNationalityPicker = false
    @State private var showDOBPicker = false

    private enum Field {
        case firstName, lastName, passport
    }

    private let titleOptions = ["Mr.", "Mrs.", "Ms.", "Dr."]

    private let brandRed = Color(red: 1, green: 0, blue: 0)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
    private let darkCard = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let darkText = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let mutedGray = Color(red: 0.42, green: 0.447, blue: 0.502)
    private let fieldLabelGray = Color(red: 0.373, green: 0.369, blue: 0.369)

    private static let dobFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    private var dobText: String {
        guard let dob = guest.dateOfBirth else { return "DD / MM / YYYY" }
        return Self.dobFormatter.string(from: dob)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "person.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                Text("Guest \(number)")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                    .foregroundColor(.white)
                Spacer(minLength: 8)
                Button(action: onRemove) {
                    Text("Remove")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 14))
                        .foregroundColor(brandRed)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 17)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(darkCard)

            VStack(spacing: 20) {
                HStack(alignment: .top, spacing: 16) {
                    dropdownField(label: "TITLE", value: guest.title, action: { showTitlePicker = true })
                        .frame(width: 102)
                    formField(label: "FIRST NAME", value: $guest.firstName, placeholder: "First Name", focus: .firstName)
                }

                formField(label: "LAST NAME", value: $guest.lastName, placeholder: "Last Name", focus: .lastName)

                HStack(alignment: .top, spacing: 16) {
                    dobField.frame(maxWidth: .infinity)
                    dropdownField(label: "NATIONALITY", value: guest.nationality.name, action: { showNationalityPicker = true })
                        .frame(maxWidth: .infinity)
                }

                formField(label: "PASSPORT NUMBER", value: $guest.passportNumber, placeholder: "Enter passport if applicable", focus: .passport)
            }
            .padding(20)
        }
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showTitlePicker) {
            PickerSheetView(
                title: "Choose Title",
                items: titleOptions.map { IdentifiableString(value: $0) },
                displayText: { $0.value },
                onSelect: { guest.title = $0.value }
            )
        }
        .sheet(isPresented: $showNationalityPicker) {
            PickerSheetView(
                title: "Choose Nationality",
                items: countries,
                displayText: { $0.name },
                isSearchable: true,
                onSelect: { guest.nationality = $0 }
            )
        }
        .sheet(isPresented: $showDOBPicker) {
            dobPickerSheet
        }
    }

    private var dobField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DATE OF BIRTH")
                .font(Font.custom("Inter-Bold", size: 10))
                .tracking(0.5)
                .foregroundColor(fieldLabelGray)

            Button(action: { showDOBPicker = true }) {
                HStack {
                    Text(dobText)
                        .font(Font.custom("Inter", size: 14).weight(.medium))
                        .foregroundColor(guest.dateOfBirth == nil ? mutedGray : darkText)
                    Spacer()
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(mutedGray)
                }
                .padding(12)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 0.8))
            }
            .buttonStyle(.plain)
        }
    }

    private func formField(label: String, value: Binding<String>, placeholder: String, focus: Field) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Font.custom("Inter-Bold", size: 10))
                .tracking(0.5)
                .foregroundColor(fieldLabelGray)

            TextField(placeholder, text: value)
                .font(Font.custom("Inter", size: 14).weight(.medium))
                .foregroundColor(darkText)
                .focused($focusedField, equals: focus)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 0.8))
        }
    }

    private func dropdownField(label: String, value: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Font.custom("Inter-Bold", size: 10))
                .tracking(0.5)
                .foregroundColor(fieldLabelGray)
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
                        .foregroundColor(mutedGray)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 0.8))
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
                    get: { guest.dateOfBirth ?? Date() },
                    set: { guest.dateOfBirth = $0 }
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
        DummyTicketHotelPersonalDetailsView()
            .environmentObject(TabBarState())
            .environmentObject(DummyTicketBookingViewModel())
    }
}
