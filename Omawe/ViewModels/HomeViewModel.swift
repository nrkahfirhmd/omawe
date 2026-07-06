//
//  HomeViewModel.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 05/07/26.
//

import SwiftUI
import SwiftData

@Observable
class HomeViewModel {
    // MARK: - Services
    private let tripCreationService = TripCreationService()

    // MARK: - Trip Draft

    var createTripDraft = TripDraft()

    // MARK: - Create Trip Flow

    var nextStepRequest = 0
    var isNextStepEnabled = false

    // MARK: - Navigation / Presentation

    var isInvitationPresented = false
    var isCalendarPresented = false
    var isLocationPresented = false
    var isEditingInvitationDetails = false

    // MARK: - Creation State

    var isSavingTrip = false
    var hasCreatedTrip = false
    var creationErrorMessage: String?

    // MARK: - Computed Properties
    var canConfirmTripCreation: Bool {
        createTripDraft.canCreateTrip &&
        !isSavingTrip &&
        !hasCreatedTrip
    }

    // MARK: - Actions

    func resetCreateTripFlow() {
        createTripDraft.reset()
        nextStepRequest = 0
        isNextStepEnabled = false

        isInvitationPresented = false
        isCalendarPresented = false
        isLocationPresented = false
        isEditingInvitationDetails = false

        isSavingTrip = false
        hasCreatedTrip = false
        creationErrorMessage = nil
    }

    func confirmTripCreation(using modelContext: ModelContext) async {
        guard canConfirmTripCreation else {
            creationErrorMessage = "Please add a trip name and location before creating the trip."
            return
        }

        isSavingTrip = true
        creationErrorMessage = nil

        do {
            let trip = try await tripCreationService.createTrip(
                from: createTripDraft.creationInput,
                in: modelContext
            )

            print("[TripCreation] HomeViewModel received successful trip creation: id=\(trip.id.uuidString)")

            createTripDraft.invitationCode = trip.tripCode
            isSavingTrip = false
            hasCreatedTrip = true
        } catch {
            isSavingTrip = false
            creationErrorMessage = error.localizedDescription
            print("[TripCreation] HomeViewModel trip creation failed: \(error.localizedDescription)")
        }
    }
}
