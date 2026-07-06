//
//  TripCreationService.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 03/07/26.
//

import Foundation
import SwiftData

struct TripCreationInput {
    var name: String
    var startDate: Date
    var meetTime: Date
    var locationName: String
    var locationAddress: String?
    var locationNote: String?
    var locationDisplayName: String?
    var latitude: Double?
    var longitude: Double?

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedLocationName: String {
        locationName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValid: Bool {
        !trimmedName.isEmpty && !trimmedLocationName.isEmpty
    }
}

enum TripCreationError: LocalizedError {
    case missingRequiredFields

    var errorDescription: String? {
        switch self {
        case .missingRequiredFields:
            return "Please add a trip name and location before creating the trip."
        }
    }
}

@MainActor
struct TripCreationService {
    private let identityService: CloudKitIdentityService

    init(identityService: CloudKitIdentityService = CloudKitIdentityService()) {
        self.identityService = identityService
    }

    func createTrip(from input: TripCreationInput, in modelContext: ModelContext) async throws -> TripModel {
        guard input.isValid else {
            print("[TripCreation] blocked: missing required fields")
            throw TripCreationError.missingRequiredFields
        }

        print("[TripCreation] started")
        let ownerUserID = try await identityService.currentUserID()
        let now = Date()
        try ensureUserProfileExists(userID: ownerUserID, now: now, in: modelContext)

        let trip = TripModel(
            name: input.trimmedName,
            startDate: input.startDate,
            meetTime: input.meetTime,
            locationName: input.trimmedLocationName,
            locationAddress: input.locationAddress?.nilIfBlank,
            locationNote: input.locationNote?.nilIfBlank,
            locationDisplayName: input.locationDisplayName?.nilIfBlank,
            latitude: input.latitude,
            longitude: input.longitude,
            ownerUserID: ownerUserID,
            createdAt: now,
            updatedAt: now,
            memberIdentifiers: [ownerUserID],
            invitationCode: Self.makeInvitationCode()
        )
        print("[TripCreation] prepared TripModel insert: id=\(trip.id.uuidString), ownerUserID=\(ownerUserID)")

        let ownerMember = TripMember(
            tripID: trip.id,
            userID: ownerUserID,
            role: "owner",
            joinedAt: now,
            createdAt: now,
            updatedAt: now
        )
        print("[TripCreation] prepared TripMember insert: id=\(ownerMember.id.uuidString), tripID=\(trip.id.uuidString)")

        modelContext.insert(trip)
        modelContext.insert(ownerMember)

        do {
            try modelContext.save()
            print("[TripCreation] local SwiftData save succeeded for trip id=\(trip.id.uuidString)")
        } catch {
            print("[TripCreation] local SwiftData save failed: \(error.localizedDescription)")
            throw error
        }

        return trip
    }

    private func ensureUserProfileExists(userID: String, now: Date, in modelContext: ModelContext) throws {
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { profile in
                profile.userID == userID
            }
        )

        if let profile = try modelContext.fetch(descriptor).first {
            profile.updatedAt = now
            print("[TripCreation] updated existing UserProfile for CloudKit userID=\(userID)")
            return
        }

        modelContext.insert(
            UserProfile(
                userID: userID,
                createdAt: now,
                updatedAt: now
            )
        )
        print("[TripCreation] prepared UserProfile insert for CloudKit userID=\(userID)")
    }

    private static func makeInvitationCode() -> String {
        String(UUID().uuidString.prefix(8)).uppercased()
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
