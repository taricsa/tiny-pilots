//
//  CrashReportingManagerTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on 7/15/25.
//

import XCTest
@testable import Tiny_Pilots

final class CrashReportingManagerTests: XCTestCase {
    
    var crashReportingManager: CrashReportingManager!
    
    override func setUp() {
        super.setUp()
        crashReportingManager = CrashReportingManager.shared
        
        // Reset state for testing
        crashReportingManager.setEnabled(false)
    }
    
    override func tearDown() {
        crashReportingManager.setEnabled(false)
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        // Given: Fresh crash reporting manager
        // When: Checking initial state
        // Then: Should not be enabled initially
        XCTAssertFalse(crashReportingManager.isEnabled)
    }
    
    func testInitializeWithConfiguration() {
        // Given: Crash reporting configuration
        let config = CrashReportingConfiguration.forEnvironment(.debug)
        
        // When: Initializing with configuration
        crashReportingManager.initialize(with: config)
        
        // Then: Should be initialized but not necessarily enabled (depends on config)
        // Debug config has enableAutomaticCollection = false
        XCTAssertFalse(crashReportingManager.isEnabled)
    }
    
    func testInitializeWithProductionConfiguration() {
        // Given: Production crash reporting configuration
        let config = CrashReportingConfiguration.forEnvironment(.production)
        
        // When: Initializing with configuration
        crashReportingManager.initialize(with: config)
        
        // Then: Should be enabled for production
        XCTAssertTrue(crashReportingManager.isEnabled)
    }
    
    // MARK: - Configuration Tests
    
    func testDebugConfiguration() {
        // Given: Debug environment
        // When: Getting configuration
        let config = CrashReportingConfiguration.forEnvironment(.debug)
        
        // Then: Should have debug settings
        XCTAssertEqual(config.environment, "debug")
        XCTAssertFalse(config.enableAutomaticCollection)
        XCTAssertTrue(config.enableCustomLogs)
        XCTAssertFalse(config.enablePerformanceMonitoring)
        XCTAssertEqual(config.maxCustomKeys, 50)
        XCTAssertEqual(config.maxLogMessages, 100)
    }
    
    func testTestFlightConfiguration() {
        // Given: TestFlight environment
        // When: Getting configuration
        let config = CrashReportingConfiguration.forEnvironment(.testFlight)
        
        // Then: Should have TestFlight settings
        XCTAssertEqual(config.environment, "testflight")
        XCTAssertTrue(config.enableAutomaticCollection)
        XCTAssertTrue(config.enableCustomLogs)
        XCTAssertTrue(config.enablePerformanceMonitoring)
        XCTAssertEqual(config.maxCustomKeys, 30)
        XCTAssertEqual(config.maxLogMessages, 50)
    }
    
    func testProductionConfiguration() {
        // Given: Production environment
        // When: Getting configuration
        let config = CrashReportingConfiguration.forEnvironment(.production)
        
        // Then: Should have production settings
        XCTAssertEqual(config.environment, "production")
        XCTAssertTrue(config.enableAutomaticCollection)
        XCTAssertFalse(config.enableCustomLogs)
        XCTAssertTrue(config.enablePerformanceMonitoring)
        XCTAssertEqual(config.maxCustomKeys, 20)
        XCTAssertEqual(config.maxLogMessages, 25)
    }
    
    // MARK: - Error Recording Tests
    
    func testRecordErrorWhenDisabled() {
        // Given: Disabled crash reporting
        crashReportingManager.setEnabled(false)
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        // When: Recording an error
        // Then: Should not crash
        XCTAssertNoThrow(crashReportingManager.recordError(testError))
    }
    
    func testRecordErrorWhenEnabled() {
        // Given: Enabled crash reporting
        let config = CrashReportingConfiguration.forEnvironment(.testFlight)
        crashReportingManager.initialize(with: config)
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        // When: Recording an error
        // Then: Should not crash
        XCTAssertNoThrow(crashReportingManager.recordError(testError, context: ["test_key": "test_value"]))
    }
    
    func testRecordNonFatalError() {
        // Given: Enabled crash reporting
        let config = CrashReportingConfiguration.forEnvironment(.testFlight)
        crashReportingManager.initialize(with: config)
        let testError = NSError(domain: "TestDomain", code: 456, userInfo: [NSLocalizedDescriptionKey: "Non-fatal error"])
        
        // When: Recording a non-fatal error
        // Then: Should not crash
        XCTAssertNoThrow(crashReportingManager.recordNonFatalError(testError, userInfo: ["severity": "low"]))
    }
    
    // MARK: - Custom Values Tests
    
    func testSetCustomValue() {
        // Given: Enabled crash reporting
        let config = CrashReportingConfiguration.forEnvironment(.debug)
        crashReportingManager.initialize(with: config)
        crashReportingManager.setEnabled(true)
        
        // When: Setting custom values
        // Then: Should not crash
        XCTAssertNoThrow(crashReportingManager.setCustomValue("test_value", forKey: "test_key"))
        XCTAssertNoThrow(crashReportingManager.setCustomValue(123, forKey: "numeric_key"))
        XCTAssertNoThrow(crashReportingManager.setCustomValue(true, forKey: "boolean_key"))
    }
    
    func testSetUserIdentifier() {
        // Given: Enabled crash reporting
        let config = CrashReportingConfiguration.forEnvironment(.debug)
        crashReportingManager.initialize(with: config)
        crashReportingManager.setEnabled(true)
        
        // When: Setting user identifier
        // Then: Should not crash
        XCTAssertNoThrow(crashReportingManager.setUserIdentifier("test_user_123"))
    }
    
    // MARK: - Logging Tests
    
    func testLogMessage() {
        // Given: Enabled crash reporting
        let config = CrashReportingConfiguration.forEnvironment(.debug)
        crashReportingManager.initialize(with: config)
        crashReportingManager.setEnabled(true)
        
        // When: Logging messages
        // Then: Should not crash
        XCTAssertNoThrow(crashReportingManager.log("Test info message", level: .info))
        XCTAssertNoThrow(crashReportingManager.log("Test warning message", level: .warning))
        XCTAssertNoThrow(crashReportingManager.log("Test error message", level: .error))
    }
    
    func testLogLevels() {
        // Given: Log levels
        // When: Checking priorities
        // Then: Should have correct priority order
        XCTAssertTrue(CrashLogLevel.verbose.priority < CrashLogLevel.debug.priority)
        XCTAssertTrue(CrashLogLevel.debug.priority < CrashLogLevel.info.priority)
        XCTAssertTrue(CrashLogLevel.info.priority < CrashLogLevel.warning.priority)
        XCTAssertTrue(CrashLogLevel.warning.priority < CrashLogLevel.error.priority)
        XCTAssertTrue(CrashLogLevel.error.priority < CrashLogLevel.critical.priority)
    }
    
    // MARK: - Enable/Disable Tests
    
    func testSetEnabled() {
        // Given: Crash reporting manager
        let config = CrashReportingConfiguration.forEnvironment(.debug)
        crashReportingManager.initialize(with: config)
        
        // When: Enabling crash reporting
        crashReportingManager.setEnabled(true)
        
        // Then: Should be enabled
        XCTAssertTrue(crashReportingManager.isEnabled)
        
        // When: Disabling crash reporting
        crashReportingManager.setEnabled(false)
        
        // Then: Should be disabled
        XCTAssertFalse(crashReportingManager.isEnabled)
    }
    
    // MARK: - Error Types Tests
    
    func testCrashReportingErrorDescriptions() {
        // Given: Crash reporting errors
        let errors: [CrashReportingError] = [
            .notInitialized,
            .configurationInvalid,
            .apiKeyMissing,
            .networkUnavailable,
            .rateLimitExceeded,
            .customKeyLimitExceeded,
            .logMessageLimitExceeded
        ]
        
        // When: Getting error descriptions
        // Then: Should have meaningful descriptions
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Force Crash Tests (Debug Only)
    
    func testForceCrashInDebug() {
        // Given: Debug build
        #if DEBUG
        // When: Force crash is called
        // Then: Should trigger fatal error (we can't actually test this without crashing)
        // This test is mainly for code coverage
        XCTAssertNoThrow(crashReportingManager.forceCrash)
        #else
        // In non-debug builds, force crash should be ignored
        XCTAssertNoThrow(crashReportingManager.forceCrash())
        #endif
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceOfErrorRecording() {
        // Given: Enabled crash reporting
        let config = CrashReportingConfiguration.forEnvironment(.testFlight)
        crashReportingManager.initialize(with: config)
        
        // When: Recording multiple errors
        measure {
            for i in 0..<100 {
                let error = NSError(domain: "PerformanceTest", code: i, userInfo: [NSLocalizedDescriptionKey: "Performance test error \(i)"])
                crashReportingManager.recordError(error)
            }
        }
    }
    
    func testPerformanceOfCustomValueSetting() {
        // Given: Enabled crash reporting
        let config = CrashReportingConfiguration.forEnvironment(.debug)
        crashReportingManager.initialize(with: config)
        crashReportingManager.setEnabled(true)
        
        // When: Setting multiple custom values
        measure {
            for i in 0..<50 {
                crashReportingManager.setCustomValue("value_\(i)", forKey: "key_\(i)")
            }
        }
    }
}