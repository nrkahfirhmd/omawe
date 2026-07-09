//
//  TripStore.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 07/07/26.
//

import SwiftUI
import CloudKit
import SwiftData
import Foundation

@Observable
@MainActor
final class TripStore {
    static let shared = TripStore()
    
    private let tripService = CloudKitTripService()
    private let participantService = CloudKitParticipantService()
    private let sharingService = CloudKitSharingService()
    
    var trips: [Trip] = []
    var participants: [Participant] = []
    var lastLoadErrorMessage: String?

    /// Trip record names the current user has left — persisted to UserDefaults
    /// so they are filtered out immediately on every fetch without a participant round-trip.
    private var leftTripIDs: Set<String> {
        didSet { Self.saveLeftTripIDs(leftTripIDs) }
    }

    private let cacheFileName = "OmaweTripCache.json"

    private init() {
        self.leftTripIDs = Self.loadLeftTripIDs()
        loadFromCache()
    }

    // MARK: - Left-trip blocklist persistence

    private static let leftTripIDsKey = "OmaweLeftTripIDs"

    private static func loadLeftTripIDs() -> Set<String> {
        let array = UserDefaults.standard.stringArray(forKey: leftTripIDsKey) ?? []
        return Set(array)
    }

    private static func saveLeftTripIDs(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids), forKey: leftTripIDsKey)
    }

    /// Call this when the user leaves a trip so it's immediately blocklisted.
    func markTripAsLeft(_ tripID: CKRecord.ID) {
        leftTripIDs.insert(tripID.recordName)
    }

    /// Call this when the user (re-)joins a trip so it's removed from the blocklist.
    func unmarkTripAsLeft(_ tripID: CKRecord.ID) {
        leftTripIDs.remove(tripID.recordName)
    }

    func loadTrips() async {
        do {
            async let owned = tripService.fetchOwnedTrips()
            async let shared = sharingService.fetchSharedTrips()

            let (ownedTrips, sharedTrips) = try await (owned, shared)

            // Filter out trips the user has previously left
            let allTrips = (ownedTrips + sharedTrips).filter { trip in
                guard let id = trip.id else { return true }
                return !leftTripIDs.contains(id.recordName)
            }

            self.trips = allTrips.sorted {
                $0.updatedAt > $1.updatedAt
            }
            lastLoadErrorMessage = nil

            // Save trips to cache immediately so UI can display them
            saveToCache()

            // Load participants in background so we don't block the trip list render
            Task {
                await loadParticipants()
                // Save again once participants are loaded
                saveToCache()
            }
        } catch {
            print("[TripStore] Failed to load trips: \(error.localizedDescription)")
            lastLoadErrorMessage = ErrorHelper.simplify(error)
        }
    }
    
    func loadParticipants() async {
        let currentTrips = self.trips
        var loadedParticipants: [Participant] = []
        
        await withTaskGroup(of: [Participant]?.self) { group in
            for trip in currentTrips {
                guard let tripID = trip.id else { continue }
                group.addTask {
                    do {
                        return try await self.participantService.fetchParticipants(for: tripID)
                    } catch {
                        debugLog("[TripStore] Failed to fetch participants for trip \(tripID.recordName): \(error)")
                        return nil
                    }
                }
            }
            
            for await result in group {
                if let members = result {
                    loadedParticipants.append(contentsOf: members)
                }
            }
        }
        
        self.participants = loadedParticipants
        
        // Discover any shared trips where the user is no longer a participant
        // and add them to the persistent blocklist so they stay hidden.
        let identityService = CloudKitIdentityService()
        if let currentUserID = try? await identityService.currentUserRecordID() {
            var didFilter = false
            for trip in currentTrips {
                guard let tripID = trip.id else { continue }
                let isOwned = tripID.zoneID.ownerName == currentUserID.recordName || tripID.zoneID.ownerName == CKCurrentUserDefaultName
                if !isOwned {
                    let isUserParticipant = loadedParticipants.contains { $0.tripID == trip.id && $0.userID == currentUserID }
                    if !isUserParticipant {
                        leftTripIDs.insert(tripID.recordName)
                        didFilter = true
                    }
                }
            }
            if didFilter {
                self.trips = currentTrips.filter { trip in
                    guard let id = trip.id else { return true }
                    return !leftTripIDs.contains(id.recordName)
                }
            }
        }
    }
    
    // MARK: - Caching
    
    private func saveToCache() {
        let cachedTrips = trips.map { CachedTrip(from: $0) }
        let cachedParticipants = participants.map { CachedParticipant(from: $0) }
        let cacheData = CacheData(trips: cachedTrips, participants: cachedParticipants)
        
        do {
            let data = try JSONEncoder().encode(cacheData)
            let url = getCacheURL()
            try data.write(to: url)
        } catch {
            debugLog("[TripStore] Failed to save cache: \(error)")
        }
    }
    
    private func loadFromCache() {
        let url = getCacheURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        
        do {
            let data = try Data(contentsOf: url)
            let cacheData = try JSONDecoder().decode(CacheData.self, from: data)
            self.trips = cacheData.trips.compactMap { $0.toTrip() }
            self.participants = cacheData.participants.compactMap { $0.toParticipant() }
        } catch {
            debugLog("[TripStore] Failed to load cache: \(error)")
        }
    }
    
    private func getCacheURL() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(cacheFileName)
    }
}

// MARK: - Cache Models

fileprivate struct CacheData: Codable {
    let trips: [CachedTrip]
    let participants: [CachedParticipant]
}

fileprivate struct CachedCKRecordID: Codable {
    let recordName: String
    let zoneName: String
    let ownerName: String
    
    init(id: CKRecord.ID) {
        self.recordName = id.recordName
        self.zoneName = id.zoneID.zoneName
        self.ownerName = id.zoneID.ownerName
    }
    
    func toID() -> CKRecord.ID {
        CKRecord.ID(recordName: recordName, zoneID: CKRecordZone.ID(zoneName: zoneName, ownerName: ownerName))
    }
}

fileprivate struct CachedTrip: Codable {
    let id: CachedCKRecordID?
    let title: String
    let destination: String
    let startDate: Date
    let endDate: Date
    let ownerID: CachedCKRecordID
    let ownerDisplayName: String?
    let invitationCode: String
    let status: String
    let locationAddress: String?
    let apartmentUnitFloor: String?
    let locationNickname: String?
    let createdAt: Date
    let updatedAt: Date

    init(from trip: Trip) {
        self.id = trip.id.map { CachedCKRecordID(id: $0) }
        self.title = trip.title
        self.destination = trip.destination
        self.startDate = trip.startDate
        self.endDate = trip.endDate
        self.ownerID = CachedCKRecordID(id: trip.ownerID)
        self.ownerDisplayName = trip.ownerDisplayName
        self.invitationCode = trip.invitationCode
        self.status = trip.status.rawValue
        self.locationAddress = trip.locationAddress
        self.apartmentUnitFloor = trip.apartmentUnitFloor
        self.locationNickname = trip.locationNickname
        self.createdAt = trip.createdAt
        self.updatedAt = trip.updatedAt
    }

    // Custom decode so cache files written before `status` existed still load,
    // defaulting to .notStarted instead of failing the whole decode.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(CachedCKRecordID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        destination = try container.decode(String.self, forKey: .destination)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        ownerID = try container.decode(CachedCKRecordID.self, forKey: .ownerID)
        ownerDisplayName = try container.decodeIfPresent(String.self, forKey: .ownerDisplayName)
        invitationCode = try container.decode(String.self, forKey: .invitationCode)
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? TripStatus.notStarted.rawValue
        locationAddress = try container.decodeIfPresent(String.self, forKey: .locationAddress)
        apartmentUnitFloor = try container.decodeIfPresent(String.self, forKey: .apartmentUnitFloor)
        locationNickname = try container.decodeIfPresent(String.self, forKey: .locationNickname)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func toTrip() -> Trip {
        Trip(
            id: id?.toID(),
            title: title,
            destination: destination,
            startDate: startDate,
            endDate: endDate,
            ownerID: ownerID.toID(),
            ownerDisplayName: ownerDisplayName,
            invitationCode: invitationCode,
            status: TripStatus(rawValue: status) ?? .notStarted,
            locationAddress: locationAddress,
            apartmentUnitFloor: apartmentUnitFloor,
            locationNickname: locationNickname,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

fileprivate struct CachedParticipant: Codable {
    let id: CachedCKRecordID?
    let tripID: CachedCKRecordID
    let userID: CachedCKRecordID
    let displayName: String?
    let role: String
    let joinedAt: Date
    
    init(from participant: Participant) {
        self.id = participant.id.map { CachedCKRecordID(id: $0) }
        self.tripID = CachedCKRecordID(id: participant.tripID)
        self.userID = CachedCKRecordID(id: participant.userID)
        self.displayName = participant.displayName
        self.role = participant.role.rawValue
        self.joinedAt = participant.joinedAt
    }
    
    func toParticipant() -> Participant {
        Participant(
            id: id?.toID(),
            tripID: tripID.toID(),
            userID: userID.toID(),
            displayName: displayName,
            role: ParticipantRole(rawValue: role) ?? .member,
            joinedAt: joinedAt
        )
    }
}
