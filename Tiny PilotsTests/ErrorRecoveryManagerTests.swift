//
//  ErrorRecoveryManagerTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on Production Readiness Implementation
//

import XCTest
@testable import Tiny_Pilots

class ErrorRecoveryManagerTests: XCTestCase {
    
    var errorRecoveryManager: ErrorRecoveryManager!
    
    override func setUp() {
        super.setUp()
        errorRecoveryManager = ErrorRecoveryManager.shared
        
        // Reset all retry counters before each test
        errorRecoveryManager.resetRetryCounter(for: "test_operation")
        errorRecoveryManager.resetRetryCounter(for: "network_operation")
        errorRecoveryManager.resetRetryCounter(for: "gamecenter_operation")
    }
    
    override func tearDown() {
        errorRecoveryManager = nil
        super.tearDown()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testSharedInstance() {
        let instance1 = ErrorRecoveryManager.shared
        let instance2 = ErrorRecoveryManager.shared
        
        XCTAssertTrue(instance1 === instance2, "ErrorRecoveryManager should be a singleton")
    }
    
    func testErrorContextInitialization() {
        let context = ErrorContext(
            operation: "test_operation",
            userFacing: true,
            retryCount: 2,
            additionalInfo: ["key": "value"]
        )
        
        XCTAssertEqual(context.operation, "test_operation")
        XCTAssertTrue(context.userFacing)
        XCTAssertEqual(context.retryCount, 2)
        XCTAssertEqual(context.additionalInfo["key"] as? String, "value")
    }
    
    func testErrorContextDefaultValues() {
        let context = ErrorContext(operation: "test_operation")
        
        XCTAssertEqual(context.operation, "test_operation")
        XCTAssertFalse(context.userFacing)
        XCTAssertEqual(context.retryCount, 0)
        XCTAssertTrue(context.additionalInfo.isEmpty)
    }
    
    // MARK: - Error Recovery Action Tests
    
    func testNetworkErrorRecovery() {
        let error = TinyPilotsError.networkUnavailable
        let context = ErrorContext(operation: "network_test", userFacing: true)
        
        let action = errorRecoveryManager.handleError(error, context: context)
        
        switch action {
        case .fallback:
            XCTAssertTrue(true, "Network errors should result in fallback action")
        default:
            XCTFail("Expected fallback action for network error, got \(action)")
        }
    }
    
    func testGameCenterErrorRecovery() {
        let error = TinyPilotsError.gameCenterUnavailable
        let context = ErrorContext(operation: "gamecenter_test", userFacing: true)
        
        let action = errorRecoveryManager.handleError(error, context: context)
        
        switch action {
        case .gracefulDegradation:
            XCTAssertTrue(true, "Game Center errors should result in graceful degradation")
        default:
            XCTFail("Expected graceful degradation for Game Center error, got \(action)")
        }
    }
    
    func testDataCorruptionErrorRecovery() {
        let error = TinyPilotsError.dataCorruption
        let context = ErrorContext(operation: "data_test", userFacing: true)
        
        let action = errorRecoveryManager.handleError(error, context: context)
        
        switch action {
        case .userIntervention(let message):
            XCTAssertTrue(message.contains("corruption"), "Message should mention corruption")
        default:
            XCTFail("Expected user intervention for data corruption, got \(action)")
        }
    }
    
    func testValidationErrorRecovery() {
        let error = TinyPilotsError.validationError("Invalid input")
        let context = ErrorContext(operation: "validation_test", userFacing: true)
        
        let action = errorRecoveryManager.handleError(error, context: context)
        
        switch action {
        case .userIntervention(let message):
            XCTAssertEqual(message, "Invalid input")
        default:
            XCTFail("Expected user intervention for validation error, got \(action)")
        }
    }
    
    // MARK: - Retry Logic Tests
    
    func testRetryCounterManagement() {
        let operation = "test_operation"
        
        // Initial count should be 0
        XCTAssertEqual(errorRecoveryManager.getRetryCount(for: operation), 0)
        
        // Simulate retry attempts
        let error = TinyPilotsError.networkUnavailable
        let context1 = ErrorContext(operation: operation, retryCount: 0)
        let context2 = ErrorContext(operation: operation, retryCount: 1)
        let context3 = ErrorContext(operation: operation, retryCount: 2)
        
        // First attempt should allow retry
        let action1 = errorRecoveryManager.handleError(error, context: context1)
        switch action1 {
        case .retry, .fallback:
            XCTAssertTrue(true, "First attempt should allow retry or fallback")
        default:
            XCTFail("Expected retry or fallback for first attempt")
        }
        
        // Second attempt should still allow retry
        let action2 = errorRecoveryManager.handleError(error, context: context2)
        switch action2 {
        case .retry, .fallback:
            XCTAssertTrue(true, "Second attempt should allow retry or fallback")
        default:
            XCTFail("Expected retry or fallback for second attempt")
        }
        
        // Third attempt should not retry (max attempts reached)
        let action3 = errorRecoveryManager.handleError(error, context: context3)
        switch action3 {
        case .retry:
            XCTFail("Should not retry after max attempts")
        default:
            XCTAssertTrue(true, "Should not retry after max attempts")
        }
    }
    
    func testRetryCounterReset() {
        let operation = "reset_test"
        
        // Simulate some retry attempts
        let error = TinyPilotsError.networkUnavailable
        let context = ErrorContext(operation: operation, retryCount: 2)
        _ = errorRecoveryManager.handleError(error, context: context)
        
        // Reset counter
        errorRecoveryManager.resetRetryCounter(for: operation)
        
        // Count should be back to 0
        XCTAssertEqual(errorRecoveryManager.getRetryCount(for: operation), 0)
    }
    
    // MARK: - Error Recovery Capability Tests
    
    func testCanRecoverFromRecoverableErrors() {
        let recoverableErrors: [Error] = [
            TinyPilotsError.networkUnavailable,
            TinyPilotsError.gameCenterUnavailable,
            TinyPilotsError.serviceUnavailable("TestService"),
            TinyPilotsError.unknownError(NSError(domain: "Test", code: 1))
        ]
        
        for error in recoverableErrors {
            XCTAssertTrue(
                errorRecoveryManager.canRecover(from: error),
                "Should be able to recover from \(error)"
            )
        }
    }
    
    func testCannotRecoverFromNonRecoverableErrors() {
        let nonRecoverableErrors: [Error] = [
            TinyPilotsError.dataCorruption,
            TinyPilotsError.insufficientStorage,
            TinyPilotsError.configurationError("Test"),
            TinyPilotsError.validationError("Test")
        ]
        
        for error in nonRecoverableErrors {
            XCTAssertFalse(
                errorRecoveryManager.canRecover(from: error),
                "Should not be able to recover from \(error)"
            )
        }
    }
    
    func testSystemErrorRecovery() {
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
        let cocoaError = NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoSuchFileError)
        
        XCTAssertTrue(errorRecoveryManager.canRecover(from: networkError))
        XCTAssertFalse(errorRecoveryManager.canRecover(from: cocoaError))
    }
    
    // MARK: - Async Recovery Tests
    
    func testAsyncRecoveryAttempt() async {
        let error = TinyPilotsError.networkUnavailable
        let context = ErrorContext(operation: "async_test", retryCount: 0)
        
        let recoveryResult = await errorRecoveryManager.attemptRecovery(from: error, context: context)
        
        // For network errors, recovery should succeed (mocked)
        XCTAssertTrue(recoveryResult, "Network error recovery should succeed")
    }
    
    func testAsyncRecoveryWithMaxRetries() async {
        let error = TinyPilotsError.networkUnavailable
        let context = ErrorContext(operation: "max_retry_test", retryCount: 3)
        
        let recoveryResult = await errorRecoveryManager.attemptRecovery(from: error, context: context)
        
        // Should fail when max retries exceeded
        XCTAssertFalse(recoveryResult, "Recovery should fail when max retries exceeded")
    }
    
    // MARK: - TinyPilotsError Tests
    
    func testTinyPilotsErrorDescriptions() {
        let errors: [(TinyPilotsError, String)] = [
            (.networkUnavailable, "Network connection is not available"),
            (.gameCenterUnavailable, "Game Center is not available"),
            (.dataCorruption, "Data corruption detected"),
            (.insufficientStorage, "Insufficient storage space"),
            (.configurationError("test"), "Configuration error: test"),
            (.serviceUnavailable("TestService"), "TestService service is unavailable"),
            (.validationError("test validation"), "Validation error: test validation")
        ]
        
        for (error, expectedDescription) in errors {
            XCTAssertEqual(error.errorDescription, expectedDescription)
        }
    }
    
    func testTinyPilotsErrorRecoverySuggestions() {
        let networkError = TinyPilotsError.networkUnavailable
        XCTAssertNotNil(networkError.recoverySuggestion)
        XCTAssertTrue(networkError.recoverySuggestion!.contains("internet connection"))
        
        let gameCenterError = TinyPilotsError.gameCenterUnavailable
        XCTAssertNotNil(gameCenterError.recoverySuggestion)
        XCTAssertTrue(gameCenterError.recoverySuggestion!.contains("Game Center"))
    }
    
    // MARK: - Global Function Tests
    
    func testGlobalHandleErrorFunction() {
        let error = TinyPilotsError.networkUnavailable
        
        let action = handleError(error, operation: "global_test", userFacing: true)
        
        switch action {
        case .fallback:
            XCTAssertTrue(true, "Global function should work correctly")
        default:
            XCTFail("Expected fallback action from global function")
        }
    }
    
    func testGlobalAttemptErrorRecoveryFunction() async {
        let error = TinyPilotsError.networkUnavailable
        
        let result = await attemptErrorRecovery(error, operation: "global_recovery_test")
        
        XCTAssertTrue(result, "Global recovery function should work correctly")
    }
    
    // MARK: - Performance Tests
    
    func testErrorHandlingPerformance() {
        let error = TinyPilotsError.networkUnavailable
        let context = ErrorContext(operation: "performance_test")
        
        measure {
            for _ in 0..<1000 {
                _ = errorRecoveryManager.handleError(error, context: context)
            }
        }
    }
    
    func testConcurrentErrorHandling() {
        let expectation = XCTestExpectation(description: "Concurrent error handling")
        expectation.expectedFulfillmentCount = 10
        
        let error = TinyPilotsError.networkUnavailable
        
        for i in 0..<10 {
            DispatchQueue.global(qos: .background).async {
                let context = ErrorContext(operation: "concurrent_test_\(i)")
                _ = self.errorRecoveryManager.handleError(error, context: context)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyOperationName() {
        let error = TinyPilotsError.networkUnavailable
        let context = ErrorContext(operation: "")
        
        let action = errorRecoveryManager.handleError(error, context: context)
        
        // Should still handle the error gracefully
        XCTAssertNotNil(action)
    }
    
    func testNilAdditionalInfo() {
        let context = ErrorContext(operation: "test", additionalInfo: [:])
        
        XCTAssertTrue(context.additionalInfo.isEmpty)
    }
}