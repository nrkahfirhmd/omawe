//
//  CreateTripView.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 02/07/26.
//


import SwiftUI
import MapKit

enum CreateTripStep: Int, CaseIterable {
    case tripName
    case dateAndArrival
    case destination
    case invitationPreview
}

private struct DynamicBoxSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct CreateTripView: View {
    @Binding var selectedTripAction: TripAction?
    @Binding var nextStepRequest: Int
    @Binding var isNextStepEnabled: Bool

    @State private var currentStep: CreateTripStep = .tripName {
        didSet {
            updateNextStepAvailability()
        }
    }
    @State private var tripName = ""
    @State private var arrivalDate = Date()
    @State private var selectedTimeZone = TimeZone.current.identifier
    @State private var isCalendarPresented = false
    @State private var isEditingInvitationDetails = false
    @State private var locationName = ""
    @State private var locationAddress = ""
    @State private var locationSearchQuery = ""
    @State private var apartmentUnitFloor = ""
    @State private var locationNameOpt = ""
    @State private var isEditingLocation = false
    @State private var isLocationSheetPresented = false
    @StateObject private var locationSearchService = LocationSearchService()
    @State private var selectedLocationCoordinate: CLLocationCoordinate2D?
    @State private var isResolvingLocation = false

    init(
        selectedTripAction: Binding<TripAction?>,
        nextStepRequest: Binding<Int>,
        isNextStepEnabled: Binding<Bool>,
        initialStep: CreateTripStep = .tripName,
        initiallyPresentLocationSheet: Bool = false
    ) {
        self._selectedTripAction = selectedTripAction
        self._nextStepRequest = nextStepRequest
        self._isNextStepEnabled = isNextStepEnabled
        self._currentStep = State(initialValue: initialStep)
        self._isLocationSheetPresented = State(initialValue: initiallyPresentLocationSheet)
    }

    private var title: String {
        switch currentStep {
        case .tripName:
            return "Text will go here"
        case .destination:
            return "Destination"
        case .dateAndArrival:
            return "Date and Arrival time"
        case .invitationPreview:
            return "Invitation Preview"
        }
    }

    private var subtitle: String {
        switch currentStep {
        case .tripName:
            return "What should we call this adventure?"
        case .destination:
            return "Where will you be landing?"
        case .dateAndArrival:
            return "Let us know so we can track the schedule"
        case .invitationPreview:
            return "Review what your guests will receive"
        }
    }

    private var icon: String {
        switch currentStep {
        case .tripName:
            return "motorcycle"
        case .destination:
            return "location.north.circle"
        case .dateAndArrival:
            return "clock.badge.checkmark"
        case .invitationPreview:
            return "balloon.2"
        }
    }

    private var helperText: String {
        switch currentStep {
        case .tripName, .destination, .dateAndArrival:
            return "Compulsory. This appears on the invitation"
        case .invitationPreview:
            return "This is what guests will see"
        }
    }

    private var footerTitle: String {
        currentStep == .invitationPreview ? "Invitation Preview" : "Creating a trip"
    }

    private var trimmedTripName: String {
        tripName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func goToNextStep() {
        guard currentStep != .invitationPreview else { return }
        guard currentStep != .tripName || !trimmedTripName.isEmpty else { return }
        guard currentStep != .destination || !locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        guard let nextStep = CreateTripStep(rawValue: currentStep.rawValue + 1) else { return }

        withAnimation(.spring(response: 0.48, dampingFraction: 0.9)) {
            currentStep = nextStep
        }
    }

    private func updateNextStepAvailability() {
        switch currentStep {
        case .tripName:
            isNextStepEnabled = !trimmedTripName.isEmpty
        case .destination:
            isNextStepEnabled = !locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .dateAndArrival, .invitationPreview:
            isNextStepEnabled = true
        }
    }
    
    var body: some View {
        Group {
            if selectedTripAction == .create {
                DynamicBox(
                    theme: Theme.themePrimary,
                    icon: icon,
                    title: title,
                    subtitle: subtitle,
                    helperText: helperText,
                    footerTitle: footerTitle
                ) {
                    Group {
                        switch currentStep {
                        case .tripName:
                            tripNameStep
                        case .dateAndArrival:
                            dateAndArrivalStep
                        case .destination:
                            destinationStep
                        case .invitationPreview:
                            invitationPreviewStep
                        }
                    }
                    .padding(.horizontal, 24)
                    .id(currentStep)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
                .transition(.scale(scale: 0.18, anchor: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(isPresented: $isLocationSheetPresented) {
            locationPickerSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(32)
                .presentationBackground(.ultraThinMaterial)
        }
        .onChange(of: nextStepRequest) { _, _ in
            goToNextStep()
        }
        .onChange(of: tripName) { _, _ in
            updateNextStepAvailability()
        }
        .onChange(of: locationName) { _, _ in
            updateNextStepAvailability()
        }
        .onAppear {
            updateNextStepAvailability()
        }
    }

    @ViewBuilder
    private var tripNameStep: some View {
        VStack(spacing: 20) {
            TextField("Trip name", text: $tripName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .tint(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(.white.opacity(0.42))
                        .frame(height: 1)
                }
        }
    }

    @ViewBuilder
    private var destinationStep: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Event Location")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))

                if locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                            isLocationSheetPresented = true
                        }
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white.opacity(0.9))
                                .frame(width: 52, height: 52)
                                .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                            VStack(alignment: .leading, spacing: 5) {
                                Text("Choose a location")
                                    .font(.system(size: 21, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)

                                Text("Search for a place to set your meeting point")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.68))
                                    .multilineTextAlignment(.leading)
                            }

                            Spacer(minLength: 0)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white.opacity(0.62))
                        }
                        .padding(16)
                        .background(.white.opacity(0.13), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Choose event location")
                } else {
                    HStack(spacing: 16) {
                        Image(systemName: "location.north.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(.cyan.opacity(0.92), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                        VStack(alignment: .leading, spacing: 5) {
                            Text(locationName)
                                .font(.system(size: 21, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)

                            Text(locationAddress)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.72))
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)

                        Button {
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                                isLocationSheetPresented = true
                            }
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 19, weight: .bold))
                                .foregroundStyle(.white.opacity(0.82))
                                .frame(width: 42, height: 42)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Edit location")
                    }
                    .padding(16)
                    .background(.white.opacity(0.13), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                }
            }

            if !apartmentUnitFloor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(apartmentUnitFloor)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.74))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
            }
        }
    }

    @ViewBuilder
    private var locationPickerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(.black.opacity(0.82))

                        TextField("Search a place", text: $locationSearchQuery)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundStyle(.black)
                            .tint(.black)

                        Image(systemName: "mic.fill")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(.black.opacity(0.68))
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 64)
                    .background(.gray.opacity(0.1), in: Capsule())
                    .onChange(of: locationSearchQuery) { _, query in
                        locationSearchService.search(query)
                    }

                    if !locationSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            if isResolvingLocation {
                                HStack(spacing: 10) {
                                    ProgressView()
                                        .tint(.black)
                                    Text("Getting location details…")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(.black.opacity(0.62))
                                }
                                .padding(.vertical, 6)
                            } else if locationSearchService.completions.isEmpty {
                                Text("No matching places yet")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(.black.opacity(0.55))
                                    .padding(.vertical, 6)
                            } else {
                                ForEach(locationSearchService.completions, id: \.self) { completion in
                                    Button {
                                        Task {
                                            isResolvingLocation = true
                                            defer { isResolvingLocation = false }

                                            guard let item = await locationSearchService.select(completion) else {
                                                return
                                            }

                                            locationName = item.name ?? completion.title
                                            locationAddress = item.placemark.title ?? completion.subtitle
                                            selectedLocationCoordinate = item.placemark.coordinate
                                            locationSearchQuery = ""
                                        }
                                    } label: {
                                        HStack(alignment: .top, spacing: 14) {
                                            Image(systemName: "mappin.and.ellipse")
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundStyle(.cyan)
                                                .frame(width: 28)

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(completion.title)
                                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                                    .foregroundStyle(.black)
                                                    .multilineTextAlignment(.leading)

                                                if !completion.subtitle.isEmpty {
                                                    Text(completion.subtitle)
                                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                                        .foregroundStyle(.black.opacity(0.58))
                                                        .multilineTextAlignment(.leading)
                                                }
                                            }

                                            Spacer(minLength: 0)
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 14)
                                        .background(.black.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Selected Location")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.black.opacity(0.62))

                        if locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            HStack(spacing: 16) {
                                Image(systemName: "mappin.slash")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.black.opacity(0.55))
                                    .frame(width: 52, height: 52)
                                    .background(.gray.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                                VStack(alignment: .leading, spacing: 5) {
                                    Text("No location selected")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundStyle(.black.opacity(0.82))

                                    Text("Search above and choose one of the results.")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(.black.opacity(0.56))
                                }

                                Spacer(minLength: 0)
                            }
                            .padding(16)
                            .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                        } else {
                            HStack(spacing: 16) {
                                Image(systemName: "location.north.fill")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 52, height: 52)
                                    .background(.cyan.opacity(0.92), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(locationName)
                                        .font(.system(size: 21, weight: .bold, design: .rounded))
                                        .foregroundStyle(.black)
                                        .lineLimit(2)

                                    Text(locationAddress)
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(.gray.opacity(0.72))
                                        .lineLimit(2)
                                }

                                Spacer(minLength: 0)

                                Button {
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                                        locationName = ""
                                        locationAddress = ""
                                        apartmentUnitFloor = ""
                                        locationSearchQuery = ""
                                        selectedLocationCoordinate = nil
                                        locationSearchService.search("")
                                    }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 38, height: 38)
                                        .background(.gray.opacity(0.62), in: Circle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Remove selected location")
                            }
                            .padding(16)
                            .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                        }
                    }

                    VStack(alignment: .leading, spacing: 9) {
                        Text("Apartment, Unit, or Floor")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.black.opacity(0.62))

                        TextField("Example: Apt 1A", text: $apartmentUnitFloor)
                            .font(.system(size: 19, weight: .medium, design: .rounded))
                            .foregroundStyle(.black)
                            .tint(.black)
                            .padding(.horizontal, 18)
                            .frame(height: 58)
                            .background(.gray.opacity(0.1), in: Capsule())

                        Text("Optional")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.black.opacity(0.48))
                    }
                    
                    VStack(alignment: .leading, spacing: 9) {
                        Text("Loctation Name")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.black.opacity(0.62))

                        TextField("Example: Kuta Beach Apt", text: $locationNameOpt)
                            .font(.system(size: 19, weight: .medium, design: .rounded))
                            .foregroundStyle(.black)
                            .tint(.black)
                            .padding(.horizontal, 18)
                            .frame(height: 58)
                            .background(.gray.opacity(0.1), in: Capsule())

                        Text("Optional")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.black.opacity(0.48))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .navigationTitle("Pick Location")
            .navigationBarTitleDisplayMode(.inline)
            .background {
                Image(.homeBackground)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        locationSearchQuery = ""
                        locationSearchService.search("")
                        isLocationSheetPresented = false
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.cyan)
                    .fontWeight(.semibold)
                    .disabled(locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .preferredColorScheme(.light)
        }
    }

    private var selectedHour: Binding<Int> {
        Binding(
            get: {
                Calendar.current.component(.hour, from: arrivalDate)
            },
            set: { newHour in
                let calendar = Calendar.current
                let minute = calendar.component(.minute, from: arrivalDate)
                arrivalDate = calendar.date(
                    bySettingHour: newHour,
                    minute: minute,
                    second: 0,
                    of: arrivalDate
                ) ?? arrivalDate
            }
        )
    }

    private var selectedMinute: Binding<Int> {
        Binding(
            get: {
                Calendar.current.component(.minute, from: arrivalDate)
            },
            set: { newMinute in
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: arrivalDate)
                arrivalDate = calendar.date(
                    bySettingHour: hour,
                    minute: newMinute,
                    second: 0,
                    of: arrivalDate
                ) ?? arrivalDate
            }
        )
    }

    @ViewBuilder
    private var dateAndArrivalStep: some View {
        ZStack {
            VStack(spacing: 30) {
                Button {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                        isCalendarPresented = true
                    }
                } label: {
                    Text(arrivalDate.formatted(.dateTime.day().month(.abbreviated).year()))
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 13)
                        .background(.white.opacity(0.18), in: Capsule())
                }
                .buttonStyle(.plain)

                VStack(spacing: 18) {
                    Text("Time picker")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)

                    HStack(spacing: 18) {
                        customTimeWheel(
                            selection: selectedHour,
                            values: Array(0...23)
                        )

                        Text(":")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        customTimeWheel(
                            selection: selectedMinute,
                            values: Array(0...59)
                        )
                    }
                    .frame(height: 180)
                }
            }

            if isCalendarPresented {
                VStack(spacing: 0) {
                    DatePicker(
                        "Arrival date",
                        selection: $arrivalDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .tint(.cyan)
                    .colorScheme(.dark)
                }
                .frame(width: 300)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(.white.opacity(0.5), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 12)
                .transition(.scale(scale: 0.92).combined(with: .opacity))
                .onChange(of: arrivalDate) { _, _ in
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                        isCalendarPresented = false
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func customTimeWheel(
        selection: Binding<Int>,
        values: [Int]
    ) -> some View {
        Picker("", selection: selection) {
            ForEach(values, id: \.self) { value in
                Text(String(format: "%02d", value))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .tag(value)
            }
        }
        .labelsHidden()
        .pickerStyle(.wheel)
        .frame(width: 150, height: 180)
        .clipped()
        .colorScheme(.dark)
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.black.opacity(0.38))
                .allowsHitTesting(false)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var invitationPreviewStep: some View {
        VStack(spacing: 18) {
            HStack(spacing: -10) {
                previewAvatar(initials: "B", tint: .orange)
                previewAvatar(initials: "K", tint: .brown)
                previewAvatar(initials: "A", tint: .yellow)

                Text("+3")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.leading, 18)
            }

            if isEditingInvitationDetails {
                ZStack {
                    VStack(spacing: 22) {
                        VStack(spacing: 12) {
                            Text("Event Date")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.56))

                            Button {
                                withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                                    isCalendarPresented = true
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "calendar")
                                    Text(arrivalDate.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                                }
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .frame(height: 52)
                                .background(.white.opacity(0.14), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }

                        VStack(spacing: 12) {
                            Text("Meet Time")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.56))

                            HStack(spacing: 14) {
                                customTimeWheel(
                                    selection: selectedHour,
                                    values: Array(0...23)
                                )

                                Text(":")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)

                                customTimeWheel(
                                    selection: selectedMinute,
                                    values: Array(0...59)
                                )
                            }
                            .frame(height: 150)
                            .scaleEffect(0.82)
                            .frame(height: 150)
                        }

                        VStack(spacing: 12) {
                            Text("Location")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.56))

                            Button {
                                withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                                    isLocationSheetPresented = true
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "mappin.and.ellipse" : "location.north.fill")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 42, height: 42)
                                        .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Choose a location" : locationName)
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                            .lineLimit(1)

                                        Text(locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Search using MapKit" : locationAddress)
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.68))
                                            .lineLimit(1)
                                    }

                                    Spacer(minLength: 0)

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.62))
                                }
                                .padding(12)
                                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Choose invitation location")
                        }
                    }

                    if isCalendarPresented {
                        DatePicker(
                            "Event date",
                            selection: $arrivalDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .tint(.cyan)
                        .colorScheme(.dark)
                        .frame(width: 300)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(.white.opacity(0.5), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 12)
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
                        .onChange(of: arrivalDate) { _, _ in
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                                isCalendarPresented = false
                            }
                        }
                    }
                }
            } else {
                invitationDetail(
                    label: "Event Date",
                    value: arrivalDate.formatted(.dateTime.weekday(.wide).day().month(.wide)),
                    valueFont: .system(size: 20, weight: .bold, design: .rounded)
                )

                invitationDetail(
                    label: "Meet Time",
                    value: arrivalDate.formatted(date: .omitted, time: .shortened),
                    valueFont: .system(size: 20, weight: .bold, design: .rounded)
                )

                VStack(spacing: 10) {
                    Text("Location")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.56))

                    if locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("No location selected")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.8))
                    } else {
                        Text(locationName)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)

                        Text(locationAddress)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.82))
                            .lineSpacing(2)
                    }
                }
            }
            Spacer()

            if isEditingInvitationDetails {
                Button {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                        isCalendarPresented = false
                        isEditingInvitationDetails = false
                    }
                } label: {
                    Text("Done")
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                }
                .buttonStyle(.glass)
                .accessibilityLabel("Save invitation details")
            } else {
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                            isEditingInvitationDetails = true
                        }
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 55, height: 55)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel("Edit invitation details")

                    Button { } label: {
                        HStack(spacing: 14) {
                            Text("Share link")
                            Image(systemName: "link")
                        }
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                    }
                    .buttonStyle(.glass)
                }
            }
        }
    }

    private func invitationDetail(
        label: String,
        value: String,
        valueFont: Font
    ) -> some View {
        VStack(spacing: 12) {
            Text(label)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.56))

            Text(value)
                .font(valueFont)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
        }
    }

    private func previewAvatar(initials: String, tint: Color) -> some View {
        Text(initials)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(.black.opacity(0.74))
            .frame(width: 48, height: 48)
            .background(tint.opacity(0.9), in: Circle())
            .overlay {
                Circle()
                    .stroke(.black.opacity(0.55), lineWidth: 3)
            }
    }
}

private struct CreateTripStepPreview: View {
    let step: CreateTripStep
    let initiallyPresentLocationSheet: Bool

    @State private var selectedTripAction: TripAction? = .create
    @State private var nextStepRequest = 0
    @State private var isNextStepEnabled = true

    init(
        step: CreateTripStep,
        initiallyPresentLocationSheet: Bool = false
    ) {
        self.step = step
        self.initiallyPresentLocationSheet = initiallyPresentLocationSheet
    }

    var body: some View {
        ZStack {
            Color(hex: "#F5F8FF")
                .ignoresSafeArea()

            CreateTripView(
                selectedTripAction: $selectedTripAction,
                nextStepRequest: $nextStepRequest,
                isNextStepEnabled: $isNextStepEnabled,
                initialStep: step,
                initiallyPresentLocationSheet: initiallyPresentLocationSheet
            )
            .padding(.top, 10)
        }
    }
}

#Preview("Trip Name") {
    CreateTripStepPreview(step: .tripName)
}

#Preview("Date & Arrival") {
    CreateTripStepPreview(step: .dateAndArrival)
}

#Preview("Destination") {
    CreateTripStepPreview(step: .destination)
}

#Preview("Pick Location Sheet") {
    CreateTripStepPreview(
        step: .destination,
        initiallyPresentLocationSheet: true
    )
}

#Preview("Invitation Preview") {
    CreateTripStepPreview(step: .invitationPreview)
}
