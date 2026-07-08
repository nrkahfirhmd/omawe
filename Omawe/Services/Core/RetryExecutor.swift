//
//  RetryExecutor.swift
//  Omawe
//

import CloudKit

/// NFR-3: jittered exponential backoff with a hard ceiling well inside
/// AD-5's 30s propagation budget — a retry policy that could itself consume
/// the whole budget on backoff delay would defeat AD-5's purpose. Short,
/// aggressive initial retries (hundreds of ms), not a generic multi-second
/// scheme meant for less time-sensitive operations. Jitter (not a fixed
/// interval) so many devices hitting the same transient regional CloudKit
/// issue spread their retries out instead of syncing up into a retry storm.
struct RetryBackoff {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval

    static let locationSync = RetryBackoff(maxAttempts: 4, baseDelay: 0.2, maxDelay: 2.0)

    func delay(forAttempt attempt: Int) -> TimeInterval {
        let exponential = baseDelay * pow(2, Double(attempt))
        let capped = min(exponential, maxDelay)
        return TimeInterval.random(in: (capped / 2)...capped)
    }
}

enum RetryExecutor {
    /// Retries `operation` while the thrown error is a `CKError` that
    /// `CKErrorRetryClassifier` marks retryable, up to `policy.maxAttempts`
    /// total attempts. Anything else — a non-retryable `CKError`, a
    /// non-`CKError`, or the final attempt — is rethrown immediately, no
    /// further delay. `sleep` is injected so tests can assert on attempt
    /// counts/backoff values without waiting on real delays.
    static func run<T>(
        policy: RetryBackoff = .locationSync,
        sleep: (TimeInterval) async -> Void = { seconds in
            try? await Task.sleep(nanoseconds: UInt64(max(0, seconds) * 1_000_000_000))
        },
        operation: () async throws -> T
    ) async throws -> T {
        precondition(policy.maxAttempts >= 1)
        var attempt = 0

        while true {
            do {
                return try await operation()
            } catch let error as CKError where CKErrorRetryClassifier.isRetryable(error.code) && attempt < policy.maxAttempts - 1 {
                await sleep(policy.delay(forAttempt: attempt))
                attempt += 1
            }
        }
    }
}
