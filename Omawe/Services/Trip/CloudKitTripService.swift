//
//  CloudKitTripService.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 06/07/26.
//

import CloudKit

protocol TripServiceProtocol {
    func createTrip(_ trip: Trip) async throws -> Trip
    func fetchTrip(id: CKRecord.ID) async throws -> Trip
    func fetchOwnedTrips() async throws -> [Trip]
    func updateTrip(_ trip: Trip) async throws -> Trip
    func deleteTrip(id: CKRecord.ID) async throws
}

final class CloudKitTripService: TripServiceProtocol {
    
    private let database = CloudKitContainer.shared.privateDatabase
    private let identityService = CloudKitIdentityService()
    private let zoneService = CloudKitZoneService()
    
    func createTrip(_ trip: Trip) async throws -> Trip {
        do {
            _ = try await identityService.currentUserRecordID()

            let recordName = UUID().uuidString

            let zone = try await zoneService.createZone(
                named: "Trip-\(recordName)"
            )
            
            print("Returned Zone Name:", zone.zoneID.zoneName)
            print("Returned Owner:", zone.zoneID.ownerName)
            
            print("Zone ID:", zone.zoneID)

            let recordID = CKRecord.ID(
                recordName: recordName,
                zoneID: zone.zoneID
            )

            let record = TripRecordMapper.makeRecord(
                from: trip,
                recordID: recordID
            )
            
            print("Created Zone:", record.recordID.zoneID.zoneName)
            print("Created Record:", record.recordID.recordName)

            let savedRecord = try await database.save(record)

            print("Saved Zone:", savedRecord.recordID.zoneID.zoneName)
            print("Saved Record:", savedRecord.recordID.recordName)

            return try TripRecordMapper.makeModel(from: savedRecord)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    func fetchTrip(id: CKRecord.ID) async throws -> Trip {
        do {
            let record = try await database.record(for: id)
            return try TripRecordMapper.makeModel(from: record)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    func fetchOwnedTrips() async throws -> [Trip] {
        do {
            let zones = try await database.allRecordZones()

            var trips: [Trip] = []

            for zone in zones {
                let query = CKQuery(
                    recordType: TripRecordMapper.recordType,
                    predicate: NSPredicate(value: true)
                )

                let result = try await database.records(
                    matching: query,
                    inZoneWith: zone.zoneID
                )

                // A single unreadable record must not blank out every other
                // trip in every other zone — decode failures are skipped,
                // not propagated, so one bad/legacy record can't hide the rest.
                let zoneTrips = result.matchResults.compactMap { _, matchResult -> Trip? in
                    switch matchResult {
                    case .success(let record):
                        do {
                            return try TripRecordMapper.makeModel(from: record)
                        } catch {
                            print("[CloudKitTripService] Skipping unreadable Trip record \(record.recordID.recordName): \(error)")
                            return nil
                        }
                    case .failure(let error):
                        print("[CloudKitTripService] Match failure in zone \(zone.zoneID.zoneName): \(error)")
                        return nil
                    }
                }

                trips.append(contentsOf: zoneTrips)
            }

            return trips
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    func updateTrip(_ trip: Trip) async throws -> Trip {
        let record = TripRecordMapper.makeRecord(from: trip)
        
        do {
            let savedRecord = try await database.save(record)
            return try TripRecordMapper.makeModel(from: savedRecord)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    func deleteTrip(id: CKRecord.ID) async throws {
        do {
            _ = try await database.deleteRecord(withID: id)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
}
