//
//  CreateTripView.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 02/07/26.
//


import SwiftUI
import SwiftData

enum CreateTripStep: Int, CaseIterable {
    case tripName
    case dateAndArrival
    case destination
}

private struct DynamicBoxSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct CreateTripView: View {
    @Binding var draft: TripDraft
    @Binding var selectedTripAction: TripAction?
    @Binding var nextStepRequest: Int
    @Binding var isNextStepEnabled: Bool
    @Binding var isInvitationPreviewPresented: Bool
    @Binding var isCalendarPresented: Bool
    @Binding var isLocationSheetPresented: Bool
    
    @State private var currentStep: CreateTripStep = .tripName {
        didSet {
            updateNextStepAvailability()
        }
    }
    @State private var locationSearchQuery = ""
    @StateObject private var locationSearchService = LocationSearchService()
    @State private var isResolvingLocation = false
    
    
    init(
        draft: Binding<TripDraft>,
        selectedTripAction: Binding<TripAction?>,
        nextStepRequest: Binding<Int>,
        isNextStepEnabled: Binding<Bool>,
        isInvitationPreviewPresented: Binding<Bool> = .constant(false),
        isCalendarPresented: Binding<Bool> = .constant(false),
        isLocationSheetPresented: Binding<Bool> = .constant(false),
        initialStep: CreateTripStep = .tripName,
        initiallyPresentLocationSheet: Bool = false
    ) {
        self._draft = draft
        self._selectedTripAction = selectedTripAction
        self._nextStepRequest = nextStepRequest
        self._isNextStepEnabled = isNextStepEnabled
        self._isInvitationPreviewPresented = isInvitationPreviewPresented
        self._isCalendarPresented = isCalendarPresented
        self._isLocationSheetPresented = isLocationSheetPresented
        self._currentStep = State(initialValue: initialStep)
        if initiallyPresentLocationSheet {
            self._isLocationSheetPresented = isLocationSheetPresented
            self._isLocationSheetPresented.wrappedValue = true
        }
    }
    
    private var title: String {
        switch currentStep {
        case .tripName:
            return "Enter your trip name"
        case .destination:
            return "Destination"
        case .dateAndArrival:
            return "Date and Arrival time"
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
        }
    }

    private var icon: String {
        switch currentStep {
        case .tripName:
            return "map"
        case .destination:
            return "location.viewfinder"
        case .dateAndArrival:
            return "clock.badge.checkmark"
        }
    }

    private var helperText: String {
        switch currentStep {
        case .tripName, .destination, .dateAndArrival:
            return "Compulsory. This appears on the invitation"
        }
    }

    private var footerTitle: String {
        "Creating a trip"
    }
    
    private var trimmedTripName: String {
        draft.trimmedName
    }
    
    private var trimmedLocationName: String {
        draft.trimmedLocationName
    }
    
    private func goToNextStep() {
        guard currentStep != .tripName || !trimmedTripName.isEmpty else { return }
        guard currentStep != .destination || !trimmedLocationName.isEmpty else { return }

        switch currentStep {
        case .tripName, .dateAndArrival:
            if let nextStep = CreateTripStep(rawValue: currentStep.rawValue + 1) {
                withAnimation(.spring(response: 0.48, dampingFraction: 0.9)) {
                    currentStep = nextStep
                }
            }
        case .destination:
            // Instead of advancing step, trigger invitation preview navigation
            isInvitationPreviewPresented = true
        }
    }
    
    private func updateNextStepAvailability() {
        switch currentStep {
        case .tripName:
            isNextStepEnabled = !trimmedTripName.isEmpty
        case .destination:
            isNextStepEnabled = !trimmedLocationName.isEmpty
        case .dateAndArrival:
            isNextStepEnabled = true
        }
    }
    
    private func resetCreateTripFlow(closeFlow: Bool) {
        currentStep = .tripName
        locationSearchQuery = ""
        isResolvingLocation = false
        nextStepRequest = 0
        updateNextStepAvailability()

        guard closeFlow else { return }

        withAnimation(.spring(response: 0.72, dampingFraction: 0.88)) {
            selectedTripAction = nil
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
            TripLocationPickerSheet(
                draft: $draft,
                locationSearchQuery: $locationSearchQuery,
                isLocationSheetPresented: $isLocationSheetPresented,
                isResolvingLocation: $isResolvingLocation,
                locationSearchService: locationSearchService
            )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(32)
                .presentationBackground(.ultraThinMaterial)
        }
        .onChange(of: nextStepRequest) { _, _ in
            goToNextStep()
        }
        .onChange(of: draft.name) { _, _ in
            updateNextStepAvailability()
        }
        .onChange(of: draft.locationName) { _, _ in
            updateNextStepAvailability()
        }
        .onChange(of: selectedTripAction) { _, action in
            guard action != .create else { return }
            resetCreateTripFlow(closeFlow: false)
        }
        .onAppear {
            updateNextStepAvailability()
        }
    }
    
    @ViewBuilder
    private var tripNameStep: some View {
        TripNameDraftField(name: $draft.name, color: .white)
    }
    
    @ViewBuilder
    private var destinationStep: some View {
        TripDestinationDraftSection(
            draft: $draft,
            isLocationSheetPresented: $isLocationSheetPresented
        )
    }
    
    @ViewBuilder
    private var dateAndArrivalStep: some View {
        TripDateTimeDraftPicker(
            arrivalDate: $draft.arrivalDate,
            isCalendarPresented: $isCalendarPresented,
            color: .white
        )
    }
    

}

private struct CreateTripStepPreview: View {
    let step: CreateTripStep
    let initiallyPresentLocationSheet: Bool
    
    @State private var selectedTripAction: TripAction? = .create
    @State private var nextStepRequest = 0
    @State private var isNextStepEnabled = true
    @State private var isInvitationPreviewPresented = false
    @State private var draft = TripDraft()
    @State private var isCalendarPresented = false
    @State private var isLocationSheetPresented = false
    
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
                draft: $draft,
                selectedTripAction: $selectedTripAction,
                nextStepRequest: $nextStepRequest,
                isNextStepEnabled: $isNextStepEnabled,
                isInvitationPreviewPresented: $isInvitationPreviewPresented,
                isCalendarPresented: $isCalendarPresented,
                isLocationSheetPresented: $isLocationSheetPresented,
                initialStep: step,
                initiallyPresentLocationSheet: initiallyPresentLocationSheet
            )
            .padding(.top, 10)
            .modelContainer(
                for: [
                    TripModel.self,
                    TripMember.self,
                    LocationUpdate.self,
                    UserProfile.self
                ],
                inMemory: true
            )
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
