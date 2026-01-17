//
//  LoggerTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on Production Readiness Implementation
//

import XCTest
@testable import Tiny_Pilots

class LoggerTests: XCTestCase {
    
    var logger: Logger!
    var notificationObserver: NSObjectProtocol?
    
    override func setUp() {
        super.setUp()
        logger = Logger.shared
        logger.setMinimumLogLevel(.debug) // Ensure all messages are logged during tests
    }
    
    override func tearDown() {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
            notificationObserver = nil
        }
        logger = nil
        super.tearDown()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testSharedInstance() {
        let instance1 = Logger.shared
        let instance2 = Logger.shared
        
        XCTAssertTrue(instance1 === instance2, "Logger should be a singleton")
    }
    
    func testLogLevelComparison() {
        XCTAssertTrue(LogLevel.debug < LogLevel.info)
        XCTAssertTrue(LogLevel.info < LogLevel.warning)
        XCTAssertTrue(LogLevel.warning < LogLevel.error)
        XCTAssertTrue(LogLevel.error < LogLevel.critical)
    }
    
    func testLogLevelProperties() {
        XCTAssertEqual(LogLevel.debug.name, "DEBUG")
        XCTAssertEqual(LogLevel.info.name, "INFO")
        XCTAssertEqual(LogLevel.warning.name, "WARNING")
        XCTAssertEqual(LogLevel.error.name, "ERROR")
        XCTAssertEqual(LogLevel.critical.name, "CRITICAL")
        
        XCTAssertEqual(LogLevel.debug.emoji, "🔍")
        XCTAssertEqual(LogLevel.info.emoji, "ℹ️")
        XCTAssertEqual(LogLevel.warning.emoji, "⚠️")
        XCTAssertEqual(LogLevel.error.emoji, "❌")
        XCTAssertEqual(LogLevel.critical.emoji, "💥")
    }
    
    func testLogCategoryValues() {
        XCTAssertEqual(LogCategory.app.rawValue, "App")
        XCTAssertEqual(LogCategory.game.rawValue, "Game")
        XCTAssertEqual(LogCategory.network.rawValue, "Network")
        XCTAssertEqual(LogCategory.gameCenter.rawValue, "GameCenter")
        XCTAssertEqual(LogCategory.audio.rawValue, "Audio")
        XCTAssertEqual(LogCategory.physics.rawValue, "Physics")
        XCTAssertEqual(LogCategory.ui.rawValue, "UI")
        XCTAssertEqual(LogCategory.accessibility.rawValue, "Accessibility")
        XCTAssertEqual(LogCategory.performance.rawValue, "Performance")
        XCTAssertEqual(LogCategory.data.rawValue, "Data")
        XCTAssertEqual(LogCategory.security.rawValue, "Security")
    }
    
    // MARK: - Log Level Management Tests
    
    func testSetAndGetMinimumLogLevel() {
        logger.setMinimumLogLevel(.warning)
        
        // Wait for async operation to complete
        let expectation = XCTestExpectation(description: "Log level set")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.logger.getMinimumLogLevel(), .warning)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLogLevelFiltering() {
        logger.setMinimumLogLevel(.error)
        
        // These should not trigger notifications (below minimum level)
        logger.debug("Debug message")
        logger.info("Info message")
        logger.warning("Warning message")
        
        // This should trigger notification (at minimum level)
        let expectation = XCTestExpectation(description: "Error notification")
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .loggerErrorOccurred,
            object: nil,
            queue: .main
        ) { notification in
            XCTAssertNotNil(notification.userInfo)
            expectation.fulfill()
        }
        
        logger.error("Error message")
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Logging Method Tests
    
    func testDebugLogging() {
        // Test that debug logging doesn't crash
        logger.debug("Debug message", category: .game)
        logger.debug("Debug with default category")
        
        XCTAssertTrue(true, "Debug logging should execute without crashing")
    }
    
    func testInfoLogging() {
        // Test that info logging doesn't crash
        logger.info("Info message", category: .network)
        logger.info("Info with default category")
        
        XCTAssertTrue(true, "Info logging should execute without crashing")
    }
    
    func testWarningLogging() {
        // Test that warning logging doesn't crash
        logger.warning("Warning message", category: .audio)
        logger.warning("Warning with default category")
        
        XCTAssertTrue(true, "Warning logging should execute without crashing")
    }
    
    func testErrorLogging() {
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: ["key": "value"])
        
        let expectation = XCTestExpectation(description: "Error notification")
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .loggerErrorOccurred,
            object: nil,
            queue: .main
        ) { notification in
            guard let userInfo = notification.userInfo else {
                XCTFail("Error notification should have userInfo")
                return
            }
            
            XCTAssertEqual(userInfo["level"] as? String, "ERROR")
            XCTAssertEqual(userInfo["category"] as? String, "Physics")
            XCTAssertNotNil(userInfo["message"])
            XCTAssertNotNil(userInfo["timestamp"])
            
            expectation.fulfill()
        }
        
        logger.error("Error message", error: testError, category: .physics)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCriticalLogging() {
        let testError = NSError(domain: "CriticalDomain", code: 456, userInfo: nil)
        
        let expectation = XCTestExpectation(description: "Critical notification")
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .loggerErrorOccurred,
            object: nil,
            queue: .main
        ) { notification in
            guard let userInfo = notification.userInfo else {
                XCTFail("Critical notification should have userInfo")
                return
            }
            
            XCTAssertEqual(userInfo["level"] as? String, "CRITICAL")
            XCTAssertEqual(userInfo["category"] as? String, "Security")
            
            expectation.fulfill()
        }
        
        logger.critical("Critical message", error: testError, category: .security)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Global Function Tests
    
    func testGlobalLoggingFunctions() {
        // Test that global functions don't crash
        logDebug("Global debug")
        logInfo("Global info")
        logWarning("Global warning")
        
        let expectation = XCTestExpectation(description: "Global error notification")
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .loggerErrorOccurred,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        
        logError("Global error")
        logCritical("Global critical")
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Error Context Tests
    
    func testErrorContextLogging() {
        let nsError = NSError(
            domain: "TestDomain",
            code: 789,
            userInfo: [
                "description": "Test error description",
                "failureReason": "Test failure reason"
            ]
        )
        
        let expectation = XCTestExpectation(description: "Error context notification")
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .loggerErrorOccurred,
            object: nil,
            queue: .main
        ) { notification in
            guard let message = notification.userInfo?["message"] as? String else {
                XCTFail("Should have message in userInfo")
                return
            }
            
            // Verify error context is included
            XCTAssertTrue(message.contains("TestDomain"))
            XCTAssertTrue(message.contains("789"))
            XCTAssertTrue(message.contains("description"))
            XCTAssertTrue(message.contains("failureReason"))
            
            expectation.fulfill()
        }
        
        logger.error("Error with context", error: nsError, category: .data)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Performance Tests
    
    func testLoggingPerformance() {
        measure {
            for i in 0..<1000 {
                logger.info("Performance test message \(i)", category: .performance)
            }
        }
    }
    
    func testFilteredLoggingPerformance() {
        logger.setMinimumLogLevel(.critical)
        
        measure {
            for i in 0..<1000 {
                logger.debug("Filtered debug message \(i)", category: .performance)
                logger.info("Filtered info message \(i)", category: .performance)
                logger.warning("Filtered warning message \(i)", category: .performance)
            }
        }
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentLogging() {
        let expectation = XCTestExpectation(description: "Concurrent logging")
        expectation.expectedFulfillmentCount = 10
        
        for i in 0..<10 {
            DispatchQueue.global(qos: .background).async {
                self.logger.info("Concurrent message \(i)", category: .app)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testConcurrentLogLevelChanges() {
        let expectation = XCTestExpectation(description: "Concurrent log level changes")
        expectation.expectedFulfillmentCount = 5
        
        let levels: [LogLevel] = [.debug, .info, .warning, .error, .critical]
        
        for level in levels {
            DispatchQueue.global(qos: .background).async {
                self.logger.setMinimumLogLevel(level)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}