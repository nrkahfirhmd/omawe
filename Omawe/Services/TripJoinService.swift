//
//  TripJoinService.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 05/07/26.
//

import Foundation
import SwiftData

enum TripJoinError: LocalizedError {
    case invalidCode
    case tripNotFound

    var errorDescription: String? {
        switch self {
        case .invalidCode:
            return "Enter a valid 6-character invitation code."
        case .tripNotFound:
            return "No trip found for that invitation code."
        }
    }
}

@MainActor
struct TripJoinService {
    static let allowedCharacters = Set("ABCDEFGHJKMNPQRSTUVWXYZ23456789")

    private let identityService: CloudKitIdentityService

    init(identityService: CloudKitIdentityService = CloudKitIdentityService()) {
        self.identityService = identityService
    }

    func joinTrip(invitationCode: String, in modelContext: ModelContext) async throws -> TripModel {
        let normalizedCode = Self.normalizedCode(invitationCode)
        guard normalizedCode.count == 6 else {
            throw TripJoinError.invalidCode
        }

        let descriptor = FetchDescriptor<TripModel>(
            predicate: #Predicate { trip in
                trip.invitationCode == normalizedCode
            }
        )

        guard let trip = try modelContext.fetch(descriptor).first else {
            throw TripJoinError.tripNotFound
        }

        let userID = try await identityService.currentUserID()
        let now = Date()
        try ensureUserProfileExists(userID: userID, now: now, in: modelContext)
        try ensureTripMemberExists(trip: trip, userID: userID, now: now, in: modelContext)

        trip.updatedAt = now
        if !trip.memberIdentifiers.contains(userID) {
            trip.memberIdentifiers.append(userID)
        }

        try modelContext.save()
        return trip
    }

    static func normalizedCode(_ code: String) -> String {
        String(
            code.uppercased().filter { character in
                allowedCharacters.contains(character)
            }
        )
    }

    private func ensureTripMemberExists(
        trip: TripModel,
        userID: String,
        now: Date,
        in modelContext: ModelContext
    ) throws {
        let tripID = trip.id
        let descriptor = FetchDescriptor<TripMember>(
            predicate: #Predicate { member in
                member.tripID == tripID && member.userID == userID
            }
        )

        if let member = try modelContext.fetch(descriptor).first {
            member.updatedAt = now
            return
        }

        modelContext.insert(
            TripMember(
                tripID: tripID,
                userID: userID,
                role: "member",
                joinedAt: now,
                createdAt: now,
                updatedAt: now
            )
        )
    }

    private func ensureUserProfileExists(userID: String, now: Date, in modelContext: ModelContext) throws {
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { profile in
                profile.userID == userID
            }
        )

        if let profile = try modelContext.fetch(descriptor).first {
            profile.updatedAt = now
            return
        }

        modelContext.insert(
            UserProfile(
                userID: userID,
                createdAt: now,
                updatedAt: now
            )
        )
    }
}
