//
//  CKErrorRetryClassifier.swift
//  Omawe
//

import CloudKit

/// NFR-3: classifies every `CKError.Code` as retryable (a transient
/// condition that plausibly resolves itself if the same request is retried
/// shortly after) or not (retrying wastes the AD-5 30s propagation budget on
/// an operation that's doomed to fail the same way again). Kept as a pure,
/// exhaustively-tested function rather than folded into the backoff loop
/// itself — misclassifying a permission error as retryable wastes budget,
/// and misclassifying a transient error as non-retryable silently drops
/// data, so this list is correctness-critical on its own.
enum CKErrorRetryClassifier {
    static func isRetryable(_ code: CKError.Code) -> Bool {
        switch code {
        // Transient — network/server hiccups a short retry can plausibly ride out.
        case .networkUnavailable,
             .networkFailure,
             .serviceUnavailable,
             .requestRateLimited,
             .zoneBusy,
             .serverResponseLost,
             .internalError,
             .accountTemporarilyUnavailable:
            return true

        // Everything else is either a permanent condition (permission,
        // missing record/zone, bad request shape) or something a blind
        // retry can't meaningfully resolve (a conflict needs a real
        // read-modify-write, not a resend; a cancelled operation was
        // cancelled on purpose).
        default:
            return false
        }
    }
}
