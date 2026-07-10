import CloudKit

protocol ZoneServiceProtocol {
    var database: CKDatabase { get }
    func createZone(named name: String) async throws -> CKRecordZone
    func fetchZone(with zoneID: CKRecordZone.ID) async throws -> CKRecordZone?
    func deleteZone(with zoneID: CKRecordZone.ID) async throws
}

final class CloudKitZoneService: ZoneServiceProtocol {
    let database = CloudKitContainer.shared.privateDatabase

    func createZone(named name: String) async throws -> CKRecordZone {
        do {
            let zone = CKRecordZone(zoneName: name)
            return try await database.save(zone)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }

    func fetchZone(with zoneID: CKRecordZone.ID) async throws -> CKRecordZone? {
        do {
            return try await database.recordZone(for: zoneID)
        } catch let error as CKError where error.code == .zoneNotFound {
            return nil
        } catch {
            throw CloudKitError.unknown(error)
        }
    }

    func deleteZone(with zoneID: CKRecordZone.ID) async throws {
        do {
            _ = try await database.deleteRecordZone(withID: zoneID)
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
}
