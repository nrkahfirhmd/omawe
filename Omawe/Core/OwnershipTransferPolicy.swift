import Foundation

enum OwnershipTransferPolicy {
    /// Earliest `joinedAt` among `remaining` wins (deterministic, simple).
    /// Returns nil if `remaining` is empty 
    static func selectNewOwner(remaining: [Participant]) -> Participant? {
        guard let candidate = remaining.min(by: { $0.joinedAt < $1.joinedAt }) else {
            return nil
        }
        return candidate.role == .owner ? nil : candidate
    }
}
