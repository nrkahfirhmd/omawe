//
//  OwnershipTransferPolicy.swift
//  Omawe
//

import Foundation

/// TRIP-2's new-owner selection policy, kept pure and CloudKit-free so it's
/// unit-testable against plain `Participant` values rather than a live
/// `ParticipantServiceProtocol`.
enum OwnershipTransferPolicy {

    /// Earliest `joinedAt` among `remaining` wins (deterministic, simple —
    /// per the ticket's recommendation absent a product-specified policy).
    /// Returns nil if `remaining` is empty (no one left to promote — that's
    /// TRIP-3's "last participant leaves" boundary, not this policy's concern)
    /// or if the earliest-joined participant is already `.owner` (nothing to
    /// do — this happens when a racing device's transfer already landed).
    static func selectNewOwner(remaining: [Participant]) -> Participant? {
        guard let candidate = remaining.min(by: { $0.joinedAt < $1.joinedAt }) else {
            return nil
        }
        return candidate.role == .owner ? nil : candidate
    }
}
