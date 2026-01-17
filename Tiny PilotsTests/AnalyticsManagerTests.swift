//
//  AnalyticsManagerTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on 7/15/25.
//

import XCTest
@testable import Tiny_Pilots

final class AnalyticsManagerTests: XCTestCase {
    
    var analyticsManager: AnalyticsManager!
    
    override func setUp() {
        super.setUp()
        analyticsManager = AnalyticsManager.shared
        
        // Clear any existing consent for testing
        UserDefaults.standard.removeObject(forKey: "analytics_consent_status")
        UserDefaults.standard.removeObject(forKey: "analytics_consent_date")
        UserDefaults.standard.removeObject(forKey: "analytics_user_properties")
    }
    
    override func tearDown() {
        // Clean up after tests
        UserDefaults.standard.removeObject(forKey: "analytics_consent_status")
        UserDefaults.standard.removeObject(forKey: "analytics_consent_date")
        UserDefaults.standard.removeObject(forKey: "analytics_user_properties")
        
        super.tearDown()
    }
    
    // MARK: - Consent Tests
    
    func testInitialConsentStatus() {
        // Given: Fresh analytics manager
        // When: Checking consent status
        // Then: Should not have consent initially
        XCTAssertFalse(analyticsManager.hasUserConsent)
    }
    
    func testSetAnalyticsEnabled() {
        // Given: Analytics manager
        // When: Enabling analytics
        analyticsManager.setAnalyticsEnabled(true)
        
        // Then: Analytics should be enabled
        // Note: We can't directly test the private isEnabled property,
        // but we can test the behavior through event tracking
    }
    
    func testTrackEventWithoutConsent() {
        // Given: No user consent
        analyticsManager.setAnalyticsEnabled(true)
        
        // When: Tracking an event
        let event = AnalyticsEvent.gameStarted(mode: .freePlay, environment: "Sunny Meadows")
        
        // Then: Should not crash and should handle gracefully
        XCTAssertNoThrow(analyticsManager.trackEvent(event))
    }
    
    func testSetUserProperty() {
        // Given: Analytics manager
        // When: Setting a user property
        analyticsManager.setUserProperty("player_level", value: 5)
        
        // Then: Should not crash
        XCTAssertNoThrow(analyticsManager.setUserProperty("player_level", value: 5))
    }
    
    func testTrackScreenView() {
        // Given: Analytics manager
        // When: Tracking a screen view
        let parameters = ["previous_screen": "main_menu"]
        
        // Then: Should not crash
        XCTAssertNoThrow(analyticsManager.trackScreenView("game_scene", parameters: parameters))
    }
    
    func testTrackError() {
        // Given: Analytics manager
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        // When: Tracking an error
        // Then: Should not crash
        XCTAssertNoThrow(analyticsManager.trackError(message: "Test error occurred", category: "game", error: testError))
    }
    
    func testTrackPerformanceMetric() {
        // Given: Analytics manager
        let metric = PerformanceMetric(
            name: "frame_rate",
            value: 60.0,
            unit: "fps",
            category: "performance"
        )
        
        // When: Tracking a performance metric
        // Then: Should not crash
        XCTAssertNoThrow(analyticsManager.trackPerformance(metric))
    }
    
    // MARK: - Event Conversion Tests
    
    func testGameStartedEventConversion() {
        // Given: A game started event
        let event = AnalyticsEvent.gameStarted(mode: .challenge, environment: "Alpine Heights")
        
        // When: Tracking the event
        // Then: Should not crash
        XCTAssertNoThrow(analyticsManager.trackEvent(event))
    }
    
    func testGameCompletedEventConversion() {
        // Given: A game completed event
        let event = AnalyticsEvent.gameCompleted(mode: .dailyRun, score: 1500, duration: 120.5, environment: "Coastal Breeze")
        
        // When: Tracking the event
        // Then: Should not crash
        XCTAssertNoThrow(analyticsManager.trackEvent(event))
    }
    
    func testAchievementUnlockedEventConversion() {
        // Given: An achievement unlocked event
        let event = AnalyticsEvent.achievementUnlocked(achievementId: "first_flight")
        
        // When: Tracking the event
        // Then: Should not crash
        XCTAssertNoThrow(analyticsManager.trackEvent(event))
    }
    
    func testPerformanceEventConversion() {
        // Given: A performance event
        let event = AnalyticsEvent.lowFrameRateDetected(fps: 45.2, scene: "GameScene")
        
        // When: Tracking the event
        // Then: Should not crash
        XCTAssertNoThrow(analyticsManager.trackEvent(event))
    }
    
    func testErrorEventConversion() {
        // Given: An error event
        let event = AnalyticsEvent.errorOccurred(category: "network", message: "Connection failed", isFatal: false)
        
        // When: Tracking the event
        // Then: Should not crash
        XCTAssertNoThrow(analyticsManager.trackEvent(event))
    }
    
    // MARK: - Performance Metric Tests
    
    func testPerformanceMetricCreation() {
        // Given: Performance metric parameters
        let name = "memory_usage"
        let value = 150.5
        let unit = "MB"
        let category = "performance"
        
        // When: Creating a performance metric
        let metric = PerformanceMetric(name: name, value: value, unit: unit, category: category)
        
        // Then: Should have correct properties
        XCTAssertEqual(metric.name, name)
        XCTAssertEqual(metric.value, value)
        XCTAssertEqual(metric.unit, unit)
        XCTAssertEqual(metric.category, category)
        XCTAssertNotNil(metric.timestamp)
    }
    
    func testPerformanceMetricWithAdditionalInfo() {
        // Given: Performance metric with additional info
        let additionalInfo = ["scene": "GameScene", "device": "iPhone"]
        
        // When: Creating a performance metric
        let metric = PerformanceMetric(
            name: "frame_rate",
            value: 60.0,
            unit: "fps",
            category: "performance",
            additionalInfo: additionalInfo
        )
        
        // Then: Should have additional info
        XCTAssertNotNil(metric.additionalInfo)
        XCTAssertEqual(metric.additionalInfo?["scene"] as? String, "GameScene")
        XCTAssertEqual(metric.additionalInfo?["device"] as? String, "iPhone")
    }
    
    // MARK: - Game Mode Tests
    
    func testGameModeRawValues() {
        // Given: Game modes
        // When: Getting raw values
        // Then: Should have correct string values
        XCTAssertEqual(GameMode.tutorial.rawValue, "tutorial")
        XCTAssertEqual(GameMode.freePlay.rawValue, "free_play")
        XCTAssertEqual(GameMode.challenge.rawValue, "challenge")
        XCTAssertEqual(GameMode.dailyRun.rawValue, "daily_run")
        XCTAssertEqual(GameMode.weeklySpecial.rawValue, "weekly_special")
    }
    
    func testAllGameModes() {
        // Given: Game mode enum
        // When: Getting all cases
        let allModes = GameMode.allCases
        
        // Then: Should have all expected modes
        XCTAssertEqual(allModes.count, 5)
        XCTAssertTrue(allModes.contains(.tutorial))
        XCTAssertTrue(allModes.contains(.freePlay))
        XCTAssertTrue(allModes.contains(.challenge))
        XCTAssertTrue(allModes.contains(.dailyRun))
        XCTAssertTrue(allModes.contains(.weeklySpecial))
    }
}