import XCTest
import CloudKit
@testable import Omawe

final class CKErrorRetryClassifierTests: XCTestCase {

    private let retryableCodes: [CKError.Code] = [
        .networkUnavailable,
        .networkFailure,
        .serviceUnavailable,
        .requestRateLimited,
        .zoneBusy,
        .serverResponseLost,
        .internalError,
        .accountTemporarilyUnavailable
    ]

    private let nonRetryableCodes: [CKError.Code] = [
        .badContainer,
        .missingEntitlement,
        .notAuthenticated,
        .permissionFailure,
        .unknownItem,
        .invalidArguments,
        .resultsTruncated,
        .serverRecordChanged,
        .serverRejectedRequest,
        .assetFileNotFound,
        .assetFileModified,
        .incompatibleVersion,
        .constraintViolation,
        .operationCancelled,
        .changeTokenExpired,
        .batchRequestFailed,
        .badDatabase,
        .quotaExceeded,
        .zoneNotFound,
        .limitExceeded,
        .userDeletedZone,
        .tooManyParticipants,
        .alreadyShared,
        .referenceViolation,
        .managedAccountRestricted,
        .participantMayNeedVerification,
        .assetNotAvailable,
        .partialFailure
    ]

    func testIsRetryable_transientCodes_areRetryable() {
        for code in retryableCodes {
            XCTAssertTrue(CKErrorRetryClassifier.isRetryable(code), "\(code) should be retryable")
        }
    }

    func testIsRetryable_permanentOrUnresolvableCodes_areNotRetryable() {
        for code in nonRetryableCodes {
            XCTAssertFalse(CKErrorRetryClassifier.isRetryable(code), "\(code) should not be retryable")
        }
    }

    /// Regression guard: every `CKError.Code` must land in exactly one list,
    /// so a new Apple case can't silently default to "not retryable" unnoticed.
    func testEveryKnownCode_isCoveredByExactlyOneList() {
        let allCases = Set(retryableCodes).union(nonRetryableCodes)
        XCTAssertEqual(retryableCodes.count + nonRetryableCodes.count, allCases.count, "A code appears in both lists")
    }
}
