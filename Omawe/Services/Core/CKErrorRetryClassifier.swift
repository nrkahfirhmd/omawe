import CloudKit

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

        // Everything else is permanent (permission, missing record) or needs
        // more than a resend (a conflict needs read-modify-write).
        default:
            return false
        }
    }
}
