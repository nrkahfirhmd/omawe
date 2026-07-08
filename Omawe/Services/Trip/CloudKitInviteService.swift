//
//  CloudKitInviteService.swift
//  Omawe
//
//  Created by Muhammad Bintang Al-Fath on 06/07/26.
//

import CloudKit
import Foundation

protocol InviteServiceProtocol {
    func generateInvitationCode() -> String
    func publishInvite(code: String, shareURL: URL) async throws
    func findInvite(by invitationCode: String) async throws -> TripInvite?
}

final class CloudKitInviteService: InviteServiceProtocol {

    private let database = CloudKitContainer.shared.publicDatabase

    func generateInvitationCode() -> String {
        let characters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).compactMap { _ in characters.randomElement() })
    }

    func publishInvite(code: String, shareURL: URL) async throws {
        print("📤 Publishing invite...")
        print("Code:", code)
        print("URL:", shareURL)

        let invite = TripInvite(
            id: nil,
            code: code,
            shareURL: shareURL,
            createdAt: Date()
        )

        let record = TripInviteRecordMapper.makeRecord(from: invite)

        do {
            let saved = try await database.save(record)
            print("✅ TripInvite saved:", saved.recordID.recordName)
        } catch {
            print("❌ PublishInvite Error:", error)

            if let ckError = error as? CKError {
                print("CKError Code:", ckError.code)
                print("CKError:", ckError)
            }

            throw error
        }
    }

    func findInvite(by invitationCode: String) async throws -> TripInvite? {
        let normalizedCode = invitationCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let predicate = NSPredicate(format: "code == %@", normalizedCode)
        let query = CKQuery(recordType: TripInviteRecordMapper.recordType, predicate: predicate)
        do {
            let result = try await database.records(matching: query, resultsLimit: 1)
            guard let (_, matchResult) = result.matchResults.first else {
                return nil
            }
            switch matchResult {
            case .success(let record):
                return try TripInviteRecordMapper.makeModel(from: record)
            case .failure:
                return nil
            }
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
}
