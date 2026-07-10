import CloudKit

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
    /// Retries `operation` while the error is a `CKErrorRetryClassifier`-retryable
    /// `CKError`, up to `policy.maxAttempts`. `sleep` is injected so tests can
    /// assert on attempt counts/backoff without real delays.
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
