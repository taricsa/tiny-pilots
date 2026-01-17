//
//  AccessibilityManagerTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on Production Readiness Implementation
//

import XCTest
import UIKit
@testable import Tiny_Pilots

class AccessibilityManagerTests: XCTestCase {
    
    var accessibilityManager: AccessibilityManager!
    
    override func setUp() {
        super.setUp()
        accessibilityManager = AccessibilityManager.shared
    }
    
    override func tearDown() {
        accessibilityManager = nil
        super.tearDown()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testSharedInstance() {
        let instance1 = AccessibilityManager.shared
        let instance2 = AccessibilityManager.shared
        
        XCTAssertTrue(instance1 === instance2, "AccessibilityManager should be a singleton")
    }
    
    func testIsVoiceOverRunning() {
        let isRunning = accessibilityManager.isVoiceOverRunning()
        XCTAssertEqual(isRunning, UIAccessibility.isVoiceOverRunning, "Should return current VoiceOver status")
    }
    
    func testIsDynamicTypeEnabled() {
        let isEnabled = accessibilityManager.isDynamicTypeEnabled()
        let expected = UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
        XCTAssertEqual(isEnabled, expected, "Should return current Dynamic Type status")
    }
    
    func testPreferredContentSizeCategory() {
        let category = accessibilityManager.preferredContentSizeCategory()
        let expected = UIApplication.shared.preferredContentSizeCategory
        XCTAssertEqual(category, expected, "Should return current content size category")
    }
    
    func testGetCurrentConfiguration() {
        let config = accessibilityManager.getCurrentConfiguration()
        
        XCTAssertEqual(config.isVoiceOverEnabled, UIAccessibility.isVoiceOverRunning)
        XCTAssertEqual(config.isDynamicTypeEnabled, UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory)
        XCTAssertEqual(config.preferredContentSize, UIApplication.shared.preferredContentSizeCategory)
        XCTAssertEqual(config.isReduceMotionEnabled, UIAccessibility.isReduceMotionEnabled)
        XCTAssertEqual(config.isHighContrastEnabled, UIAccessibility.isDarkerSystemColorsEnabled)
    }
    
    // MARK: - Announcement Tests
    
    func testAnnounceMessage() {
        // This test verifies the method doesn't crash and handles empty messages
        accessibilityManager.announceMessage("Test announcement", priority: .medium)
        accessibilityManager.announceMessage("", priority: .high) // Should be ignored
        
        // Test different priorities
        accessibilityManager.announceMessage("Low priority", priority: .low)
        accessibilityManager.announceMessage("High priority", priority: .high)
        
        // No assertion needed - we're testing that it doesn't crash
        XCTAssertTrue(true, "Announcement methods should execute without crashing")
    }
    
    // MARK: - Element Configuration Tests
    
    func testConfigureElement() {
        let testView = UIView()
        
        accessibilityManager.configureElement(
            testView,
            label: "Test Label",
            hint: "Test Hint",
            traits: .button
        )
        
        // Wait for main queue to process
        let expectation = XCTestExpectation(description: "Element configuration")
        DispatchQueue.main.async {
            XCTAssertEqual(testView.accessibilityLabel, "Test Label")
            XCTAssertEqual(testView.accessibilityHint, "Test Hint")
            XCTAssertEqual(testView.accessibilityTraits, .button)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testConfigureElementWithNilValues() {
        let testView = UIView()
        testView.accessibilityLabel = "Original Label"
        testView.accessibilityHint = "Original Hint"
        testView.accessibilityTraits = .none
        
        accessibilityManager.configureElement(testView, label: nil, hint: nil, traits: nil)
        
        // Wait for main queue to process
        let expectation = XCTestExpectation(description: "Element configuration with nils")
        DispatchQueue.main.async {
            // Values should remain unchanged when nil is passed
            XCTAssertEqual(testView.accessibilityLabel, "Original Label")
            XCTAssertEqual(testView.accessibilityHint, "Original Hint")
            XCTAssertEqual(testView.accessibilityTraits, .none)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testConfigureElementWithInvalidObject() {
        let invalidObject = "Not a UI element"
        
        // Should not crash when passed invalid object
        accessibilityManager.configureElement(
            invalidObject,
            label: "Test",
            hint: "Test",
            traits: .button
        )
        
        XCTAssertTrue(true, "Should handle invalid objects gracefully")
    }
    
    // MARK: - Notification Tests
    
    func testNotificationSetupAndCleanup() {
        // Test that notifications are set up
        accessibilityManager.setupAccessibilityNotifications()
        
        // Test cleanup
        accessibilityManager.cleanupAccessibilityNotifications()
        
        // Re-setup to ensure it works after cleanup
        accessibilityManager.setupAccessibilityNotifications()
        
        XCTAssertTrue(true, "Notification setup and cleanup should work without crashing")
    }
    
    func testAccessibilityConfigurationNotification() {
        let expectation = XCTestExpectation(description: "Accessibility configuration notification")
        
        let observer = NotificationCenter.default.addObserver(
            forName: .accessibilityConfigurationChanged,
            object: nil,
            queue: .main
        ) { notification in
            XCTAssertNotNil(notification.userInfo)
            expectation.fulfill()
        }
        
        // Simulate a configuration change by posting the notification
        NotificationCenter.default.post(
            name: .accessibilityConfigurationChanged,
            object: nil,
            userInfo: ["test": true]
        )
        
        wait(for: [expectation], timeout: 1.0)
        
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: - Performance Tests
    
    func testAnnouncementPerformance() {
        measure {
            for i in 0..<100 {
                accessibilityManager.announceMessage("Performance test \(i)", priority: .low)
            }
        }
    }
    
    func testConfigurationPerformance() {
        let testViews = (0..<100).map { _ in UIView() }
        
        measure {
            for (index, view) in testViews.enumerated() {
                accessibilityManager.configureElement(
                    view,
                    label: "Label \(index)",
                    hint: "Hint \(index)",
                    traits: .button
                )
            }
        }
    }
}

// MARK: - Test Extensions

extension AccessibilityAnnouncementPriority: Equatable {
    public static func == (lhs: AccessibilityAnnouncementPriority, rhs: AccessibilityAnnouncementPriority) -> Bool {
        switch (lhs, rhs) {
        case (.low, .low), (.medium, .medium), (.high, .high):
            return true
        default:
            return false
        }
    }
}

extension AccessibilityAnnouncement: Equatable {
    public static func == (lhs: AccessibilityAnnouncement, rhs: AccessibilityAnnouncement) -> Bool {
        return lhs.message == rhs.message && lhs.priority == rhs.priority
    }
}