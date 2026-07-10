import XCTest
import CloudKit
@testable import Omawe

private struct DummyError: Error {}

final class RetryExecutorTests: XCTestCase {

    private let policy = RetryBackoff(maxAttempts: 4, baseDelay: 0.2, maxDelay: 2.0)

    func testRun_succeedsFirstTry_doesNotSleepOrRetry() async throws {
        var callCount = 0
        var sleepCount = 0

        let result = try await RetryExecutor.run(
            policy: policy,
            sleep: { _ in sleepCount += 1 }
        ) {
            callCount += 1
            return "ok"
        }

        XCTAssertEqual(result, "ok")
        XCTAssertEqual(callCount, 1)
        XCTAssertEqual(sleepCount, 0)
    }

    func testRun_retryableErrorThenSuccess_retriesAndSucceeds() async throws {
        var callCount = 0
        var sleepCount = 0

        let result = try await RetryExecutor.run(
            policy: policy,
            sleep: { _ in sleepCount += 1 }
        ) { () throws -> String in
            callCount += 1
            if callCount < 3 {
                throw CKError(.networkUnavailable)
            }
            return "ok"
        }

        XCTAssertEqual(result, "ok")
        XCTAssertEqual(callCount, 3)
        XCTAssertEqual(sleepCount, 2, "Should sleep once between each of the 2 failed attempts and the eventual success")
    }

    func testRun_nonRetryableError_failsImmediatelyWithoutRetrying() async {
        var callCount = 0
        var sleepCount = 0

        do {
            _ = try await RetryExecutor.run(
                policy: policy,
                sleep: { _ in sleepCount += 1 }
            ) { () throws -> String in
                callCount += 1
                throw CKError(.permissionFailure)
            }
            XCTFail("Expected to throw")
        } catch {
            XCTAssertEqual(callCount, 1)
            XCTAssertEqual(sleepCount, 0)
        }
    }

    func testRun_retryableErrorExhaustsAllAttempts_throwsAfterMaxAttempts() async {
        var callCount = 0
        var sleepCount = 0

        do {
            _ = try await RetryExecutor.run(
                policy: policy,
                sleep: { _ in sleepCount += 1 }
            ) { () throws -> String in
                callCount += 1
                throw CKError(.networkUnavailable)
            }
            XCTFail("Expected to throw")
        } catch {
            XCTAssertEqual(callCount, policy.maxAttempts)
            XCTAssertEqual(sleepCount, policy.maxAttempts - 1, "Sleeps between attempts, not after the final exhausted attempt")
        }
    }

    func testRun_nonCKError_isNotRetried() async {
        var callCount = 0

        do {
            _ = try await RetryExecutor.run(policy: policy, sleep: { _ in }) { () throws -> String in
                callCount += 1
                throw DummyError()
            }
            XCTFail("Expected to throw")
        } catch {
            XCTAssertEqual(callCount, 1)
            XCTAssertTrue(error is DummyError)
        }
    }

    func testBackoff_delayNeverExceedsMaxDelay() {
        let policy = RetryBackoff(maxAttempts: 10, baseDelay: 0.2, maxDelay: 1.5)
        for attempt in 0..<10 {
            let delay = policy.delay(forAttempt: attempt)
            XCTAssertLessThanOrEqual(delay, 1.5)
            XCTAssertGreaterThanOrEqual(delay, 0)
        }
    }
}
