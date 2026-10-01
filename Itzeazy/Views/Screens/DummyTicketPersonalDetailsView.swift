import SwiftUI
import UIKit

// MARK: - DummyTicketPersonalDetailsView
// Figma: "Passenger Details" (node 3470:3733), shown on-screen as "Personal Details" — step 2 of 5
// in the Dummy Tickets booking flow, reached from DummyTicketRouteDetailsView's NEXT button.
// NEXT pushes DummyTicketAdditionalDetailsView (step 3). PREVIOUS pops back to Route Details.
//
// "+ Add Passenger" appends a blank DummyTicketPassenger to booking.additionalPassengers and a new
// "Passenger N" card opens right below the main Passenger card for it — see
// DummyTicketAdditionalPassengerCard at the bottom of this file. Passenger 1's own fields stay as
// plain top-level @Published properties on the shared model (unchanged), so this only handles
// passengers 2+. Review Booking / Payment don't currently reflect these extra passengers (count,
// pricing) — only this screen's own display of them was in scope.
//
// This is also where Review Booking's "Passenger Information" and "Contact Details" Edit links
// return to — since every field here reads/writes DummyTicketBookingViewModel (shared across the
// whole flow via .environmentObject) instead of a local copy, editing here and going back forward
// shows the updated values immediately, no re-entry required. Contact Information's own "Edit"
// link has nowhere else to go (its fields are already inline-editable right here), so it's left
// as the coming-soon toast.
//
// Has real text fields, so it proactively carries the same three fixes DummyTicketInitialView
// needed after user testing: tap-outside-to-dismiss-keyboard, keyboard-aware scrolling
// (.container-scoped ignoresSafeArea, not the default .all which also covers .keyboard), and
// hiding MainTabView's persistent tab bar for the keyboard's duration (it doesn't stay pinned to
// the bottom on its own — see MainTabView.swift / DummyTicketInitialView.swift for why).

struct DummyTicketPersonalDetailsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var tabBarState: TabBarState
    @EnvironmentObject private var booking: DummyTicketBookingViewModel
    @FocusState private var focusedField: Field?

    @State private var showTitlePicker = false
    @State private var showGenderPicker = false
    @State private var showNationalityPicker = false
    @State private var showCountryCodePicker = false
    @State private var showDOBPicker = false
    @State private var showComingSoonToast = false

    private enum Field {
        case mobile, email, firstName, lastName, passport
    }

    private let titleOptions = ["Mr.", "Mrs.", "Ms.", "Dr."]
    private let genderOptions = ["Male", "Female", "Other"]

    private let brandRed = Color(red: 1, green: 0, blue: 0)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
    private let darkCard = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let darkText = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let labelGray = Color(red: 0.631, green: 0.631, blue: 0.667)
    private let placeholderGray = Color(red: 0.42, green: 0.447, blue: 0.502)
    private let dimText = Color(red: 0.635, green: 0.635, blue: 0.635)

    // Same placeholder fare amounts as Route Details — one dummy ticket, one price, unchanged
    // as the user steps through the flow.
    private let routesCount = "1"
    private let baseFare = "₹699"
    private let gst = "₹126"
    private let totalAmount = "₹825"

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

                if showComingSoonToast {
                    VStack {
                        Spacer()
                        ToastView(icon: "hourglass", message: "Coming soon! We're working hard to bring this to you.")
                            .padding(.bottom, 24)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                NavigationLink(
                    destination: DummyTicketAdditionalDetailsView().environmentObject(booking),
                    isActive: $booking.showAdditionalDetails
                ) {
                    EmptyView()
                }
                .hidden()
            }
            // .container, not the default .all: .all also covers .keyboard, which would keep this
            // whole screen full-height and unaware the keyboard is covering part of it — the exact
            // bug fixed on DummyTicketInitialView. Scoping to .container keeps the header's bleed
            // behind the status bar while letting the keyboard shrink the ScrollView correctly.
            .ignoresSafeArea(.container, edges: .vertical)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showComingSoonToast)
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

    private func showComingSoon() {
        showComingSoonToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { showComingSoonToast = false }
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
        // Step 2 (this screen) renders the same completed/checkmark styling as step 1, matching
        // the Figma mock exactly — the CURRENT step gets the checkmark treatment too, not a
        // distinct "in progress" style.
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
            flightSummaryCard
            navigationButtons
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, max(24, tabBarState.height + 16))
        // Caps width on iPad's compatibility window — same treatment as the other Dummy Ticket
        // screens.
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity)
        // Tap outside any field/button to dismiss the keyboard — same established pattern as
        // DummyTicketInitialView / CreateAccountView. A plain tap gesture here coexists with the
        // ScrollView's own drag-to-scroll and doesn't shadow the buttons/fields inside it.
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = nil
        }
    }

    // MARK: - Card shell (dark header + white body)

    private func infoCard<Content: View>(
        icon: String,
        title: String,
        trailingLabel: String,
        trailingAction: @escaping () -> Void,
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
                Button(action: trailingAction) {
                    Text(trailingLabel)
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
        infoCard(icon: "phone.circle.fill", title: "Contact Information", trailingLabel: "Edit", trailingAction: showComingSoon) {
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

            // "+ Add Passenger" appends a blank DummyTicketPassenger to booking.additionalPassengers
            // (Passenger 1's own fields above stay untouched) — each one renders as its own card
            // here, right below the main Passenger card, matching the request that tapping
            // "+ Add Passenger" opens a new section to fill in below.
            ForEach($booking.additionalPassengers) { $passenger in
                DummyTicketAdditionalPassengerCard(
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

    // MARK: - Flight summary card

    private var flightSummaryCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                Text("Flight Summary")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                    .foregroundColor(.white)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(brandRed)

            VStack(spacing: 24) {
                HStack(alignment: .center, spacing: 12) {
                    airportCodeColumn(for: booking.fromLocation)
                        .frame(maxWidth: .infinity)

                    ZStack {
                        // Figma shows a dashed connector, not solid — a plain Rectangle can't
                        // express that. DashedLine is a Shape (not a raw Path), so it properly
                        // stretches to whatever width layout assigns it instead of drawing at a
                        // fixed coordinate.
                        DashedLine()
                            .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                            .frame(height: 1.5)
                        // Actual Figma icon (downloaded from the file, not an SF Symbol
                        // approximation). A plain rectangular dark patch behind it (not a circle)
                        // matches Figma's own "Background" box masking the dashed line.
                        Image("flight_route_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 16)
                            .padding(.horizontal, 6)
                            .background(darkCard)
                    }
                    .frame(maxWidth: .infinity)

                    airportCodeColumn(for: booking.toLocation)
                        .frame(maxWidth: .infinity)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TRAVEL DATE")
                            .font(Font.custom("Inter-Bold", size: 10))
                            .tracking(1)
                            .foregroundColor(dimText)
                        Text(booking.departureDateText)
                            .font(Font.custom("PlusJakartaSans-SemiBold", size: 14))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(16)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(spacing: 14) {
                    fareRow(label: "Routes", value: routesCount)
                    fareRow(label: "Amount x1", value: baseFare)
                    fareRow(label: "GST (18%)", value: gst)

                    HStack {
                        Text("Total Amount")
                            .font(Font.custom("Inter-Bold", size: 18))
                            .foregroundColor(.white)
                        Spacer()
                        Text(totalAmount)
                            .font(Font.custom("Inter-Bold", size: 22))
                            .foregroundColor(brandRed)
                    }
                    .padding(.top, 14)
                    .overlay(Rectangle().fill(Color.white.opacity(0.3)).frame(height: 1), alignment: .top)
                }
            }
            .padding(24)
        }
        .background(darkCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // Big bold code on top ("DEL"), full city name as the small caption below ("DELHI") — matches
    // the Figma "BOM" / "MUMBAI" two-line layout. The code isn't a real IATA lookup — no such data
    // exists upstream — it's a deterministic first-three-letters-uppercased derivation, per spec.
    private func airportCodeColumn(for city: String) -> some View {
        VStack(spacing: 4) {
            Text(Self.airportCode(for: city))
                .font(Font.custom("Inter-Bold", size: 24))
                .foregroundColor(.white)
                .lineLimit(1)
            Text(city.isEmpty ? "—" : city.uppercased())
                .font(Font.custom("Inter-Bold", size: 10))
                .tracking(1)
                .foregroundColor(dimText)
                .lineLimit(1)
        }
    }

    private static func airportCode(for city: String) -> String {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "—" }
        return String(trimmed.prefix(3)).uppercased()
    }

    private func fareRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Font.custom("Inter", size: 14))
                .foregroundColor(Color(red: 0.635, green: 0.635, blue: 0.635))
            Spacer()
            Text(value)
                .font(Font.custom("Inter-Bold", size: 14))
                .foregroundColor(.white)
        }
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

private struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

// MARK: - DummyTicketAdditionalPassengerCard
// One "Passenger N" card for a passenger added via "+ Add Passenger" on DummyTicketPersonalDetailsView.
// Self-contained (its own picker sheets bound to `passenger` instead of the shared booking model)
// since there can be any number of these on screen at once — mirrors the styling of the main
// Passenger card exactly, just scoped to one entry of booking.additionalPassengers via a Binding.
private struct DummyTicketAdditionalPassengerCard: View {
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
        DummyTicketPersonalDetailsView()
            .environmentObject(TabBarState())
            .environmentObject(DummyTicketBookingViewModel())
    }
}
