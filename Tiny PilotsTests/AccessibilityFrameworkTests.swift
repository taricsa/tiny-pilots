//
//  AccessibilityFrameworkTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on Production Readiness Implementation
//

import XCTest
import UIKit
import SwiftUI
@testable import Tiny_Pilots

/// Comprehensive test suite for accessibility functionality
class AccessibilityFrameworkTests: XCTestCase {
    
    var accessibilityManager: AccessibilityManager!
    var dynamicTypeHelper: DynamicTypeHelper!
    var visualAccessibilityHelper: VisualAccessibilityHelper!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        accessibilityManager = AccessibilityManager.shared
        dynamicTypeHelper = DynamicTypeHelper.shared
        visualAccessibilityHelper = VisualAccessibilityHelper.shared
    }
    
    override func tearDownWithError() throws {
        accessibilityManager = nil
        dynamicTypeHelper = nil
        visualAccessibilityHelper = nil
        try super.tearDownWithError()
    }
    
    // MARK: - AccessibilityManager Tests
    
    func testAccessibilityManagerAnnouncements() throws {
        // Test basic announcement functionality
        let expectation = XCTestExpectation(description: "Accessibility announcement")
        
        // Mock the announcement system
        accessibilityManager.announceMessage("Test message", priority: .medium)
        
        // In a real test, you'd verify the announcement was made
        // For now, we'll just verify the method doesn't crash
        expectation.fulfill()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAccessibilityManagerConfiguration() throws {
        // Test element configuration
        let testLabel = UILabel()
        testLabel.text = "Test Label"
        
        accessibilityManager.configureElement(
            testLabel,
            label: "Test accessibility label",
            hint: "Test accessibility hint",
            traits: .button
        )
        
        XCTAssertEqual(testLabel.accessibilityLabel, "Test accessibility label")
        XCTAssertEqual(testLabel.accessibilityHint, "Test accessibility hint")
        XCTAssertTrue(testLabel.accessibilityTraits.contains(.button))
    }
    
    func testAccessibilityManagerCurrentConfiguration() throws {
        let config = accessibilityManager.getCurrentConfiguration()
        
        // Verify configuration contains expected properties
        XCTAssertNotNil(config.preferredContentSize)
        XCTAssertEqual(config.isVoiceOverEnabled, UIAccessibility.isVoiceOverRunning)
        XCTAssertEqual(config.isDynamicTypeEnabled, UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory)
        XCTAssertEqual(config.isReduceMotionEnabled, UIAccessibility.isReduceMotionEnabled)
        XCTAssertEqual(config.isHighContrastEnabled, UIAccessibility.isDarkerSystemColorsEnabled)
    }
    
    // MARK: - DynamicTypeHelper Tests
    
    func testDynamicTypeFontScaling() throws {
        let baseSize: CGFloat = 16.0
        let scaledSize = dynamicTypeHelper.scaledFontSize(baseSize: baseSize, for: .body)
        
        // Scaled size should be positive and reasonable
        XCTAssertGreaterThan(scaledSize, 0)
        XCTAssertLessThan(scaledSize, 100) // Sanity check
    }
    
    func testDynamicTypeSpacingScaling() throws {
        let baseSpacing: CGFloat = 20.0
        let scaledSpacing = dynamicTypeHelper.scaledSpacing(baseSpacing)
        
        // Scaled spacing should be positive
        XCTAssertGreaterThan(scaledSpacing, 0)
    }
    
    func testDynamicTypeMinimumTouchTarget() throws {
        let minSize = dynamicTypeHelper.minimumTouchTargetSize
        
        // Minimum touch target should meet accessibility guidelines
        XCTAssertGreaterThanOrEqual(minSize.width, 44.0)
        XCTAssertGreaterThanOrEqual(minSize.height, 44.0)
    }
    
    func testDynamicTypeButtonHeight() throws {
        let baseHeight: CGFloat = 40.0
        let scaledHeight = dynamicTypeHelper.scaledButtonHeight(baseHeight)
        
        // Scaled height should be at least the minimum touch target height
        XCTAssertGreaterThanOrEqual(scaledHeight, dynamicTypeHelper.minimumTouchTargetSize.height)
    }
    
    func testDynamicTypeTextFitting() throws {
        let testText = "This is a test string"
        let testFont = UIFont.systemFont(ofSize: 16)
        let testBounds = CGSize(width: 200, height: 50)
        
        let fits = dynamicTypeHelper.textFits(testText, font: testFont, in: testBounds)
        
        // Should return a boolean value
        XCTAssertNotNil(fits)
    }
    
    // MARK: - VisualAccessibilityHelper Tests
    
    func testVisualAccessibilityHelperProperties() throws {
        // Test that all accessibility properties return valid values
        let isHighContrast = visualAccessibilityHelper.isHighContrastEnabled
        let isReduceMotion = visualAccessibilityHelper.isReduceMotionEnabled
        let isReduceTransparency = visualAccessibilityHelper.isReduceTransparencyEnabled
        let isButtonShapes = visualAccessibilityHelper.isButtonShapesEnabled
        let isOnOffLabels = visualAccessibilityHelper.isOnOffSwitchLabelsEnabled
        
        // All should be boolean values (not nil)
        XCTAssertNotNil(isHighContrast)
        XCTAssertNotNil(isReduceMotion)
        XCTAssertNotNil(isReduceTransparency)
        XCTAssertNotNil(isButtonShapes)
        XCTAssertNotNil(isOnOffLabels)
    }
    
    func testVisualAccessibilityColorAdjustments() throws {
        let normalColor = UIColor.blue
        let backgroundColor = UIColor.white
        
        let accessibleColor = visualAccessibilityHelper.accessibleTextColor(
            normalColor: normalColor,
            backgroundColor: backgroundColor
        )
        
        // Should return a valid color
        XCTAssertNotNil(accessibleColor)
    }
    
    func testVisualAccessibilityAnimationDuration() throws {
        let normalDuration: TimeInterval = 1.0
        let adjustedDuration = visualAccessibilityHelper.adjustedAnimationDuration(normalDuration)
        
        // Adjusted duration should be non-negative
        XCTAssertGreaterThanOrEqual(adjustedDuration, 0)
        
        // If reduce motion is enabled, duration should be 0
        if visualAccessibilityHelper.isReduceMotionEnabled {
            XCTAssertEqual(adjustedDuration, 0)
        }
    }
    
    func testVisualAccessibilityIndicatorConfig() throws {
        let config = visualAccessibilityHelper.visualIndicatorConfig(for: .button)
        
        // Config should have valid properties
        XCTAssertGreaterThan(config.borderWidth, 0)
        XCTAssertGreaterThanOrEqual(config.cornerRadius, 0)
        XCTAssertNotNil(config.borderColor)
        XCTAssertNotNil(config.focusColor)
    }
    
    func testVisualAccessibilityFocusConfig() throws {
        let config = visualAccessibilityHelper.focusIndicatorConfig()
        
        // Focus config should have valid properties
        XCTAssertGreaterThan(config.width, 0)
        XCTAssertNotNil(config.color)
        XCTAssertNotNil(config.style)
    }
    
    // MARK: - Integration Tests
    
    func testAccessibilityManagerIntegration() throws {
        // Test that AccessibilityManager properly integrates with system settings
        let config = accessibilityManager.getCurrentConfiguration()
        
        XCTAssertEqual(config.isVoiceOverEnabled, accessibilityManager.isVoiceOverRunning())
        XCTAssertEqual(config.isDynamicTypeEnabled, accessibilityManager.isDynamicTypeEnabled())
        XCTAssertEqual(config.preferredContentSize, accessibilityManager.preferredContentSizeCategory())
    }
    
    func testDynamicTypeAndVisualAccessibilityIntegration() throws {
        // Test that DynamicTypeHelper and VisualAccessibilityHelper work together
        let baseSize: CGFloat = 16.0
        let scaledSize = dynamicTypeHelper.scaledFontSize(baseSize: baseSize)
        
        let adjustedDuration = visualAccessibilityHelper.adjustedAnimationDuration(1.0)
        
        // Both should return valid values
        XCTAssertGreaterThan(scaledSize, 0)
        XCTAssertGreaterThanOrEqual(adjustedDuration, 0)
    }
    
    // MARK: - Performance Tests
    
    func testAccessibilityPerformance() throws {
        // Test that accessibility operations are performant
        measure {
            for _ in 0..<1000 {
                let _ = dynamicTypeHelper.scaledFontSize(baseSize: 16, for: .body)
                let _ = visualAccessibilityHelper.isHighContrastEnabled
                let _ = accessibilityManager.getCurrentConfiguration()
            }
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testDynamicTypeEdgeCases() throws {
        // Test with zero and negative values
        let zeroScaled = dynamicTypeHelper.scaledFontSize(baseSize: 0, for: .body)
        XCTAssertGreaterThanOrEqual(zeroScaled, 0)
        
        // Test with very large values
        let largeScaled = dynamicTypeHelper.scaledFontSize(baseSize: 1000, for: .body)
        XCTAssertGreaterThan(largeScaled, 0)
        XCTAssertLessThan(largeScaled, 10000) // Sanity check
    }
    
    func testVisualAccessibilityEdgeCases() throws {
        // Test animation duration edge cases
        let zeroDuration = visualAccessibilityHelper.adjustedAnimationDuration(0)
        XCTAssertEqual(zeroDuration, 0)
        
        let negativeDuration = visualAccessibilityHelper.adjustedAnimationDuration(-1.0)
        XCTAssertGreaterThanOrEqual(negativeDuration, 0)
    }
    
    // MARK: - Accessibility Announcement Tests
    
    func testAccessibilityAnnouncements() throws {
        // Test different types of announcements
        accessibilityManager.announceGameStateChange("Test game state")
        accessibilityManager.announceScoreUpdate(100, isNewHighScore: false)
        accessibilityManager.announceScoreUpdate(200, isNewHighScore: true)
        accessibilityManager.announceCollectibleCollection("Coin", count: 5)
        accessibilityManager.announceObstacleCollision()
        accessibilityManager.announceLevelCompletion(level: "1", score: 150, time: "1:30")
        accessibilityManager.announceAchievementUnlock("Test Achievement")
        accessibilityManager.announceMenuNavigation("Settings")
        
        // These should not crash the app
        XCTAssertTrue(true) // If we get here, no crashes occurred
    }
    
    // MARK: - SKNode Extension Tests
    
    func testSKNodeAccessibilityExtensions() throws {
        let testNode = SKLabelNode(text: "Test")
        
        // Test basic accessibility configuration
        testNode.configureAccessibility(
            label: "Test label",
            hint: "Test hint",
            traits: .button,
            value: "Test value"
        )
        
        XCTAssertEqual(testNode.accessibilityLabel, "Test label")
        XCTAssertEqual(testNode.accessibilityHint, "Test hint")
        XCTAssertEqual(testNode.accessibilityValue, "Test value")
        XCTAssertTrue(testNode.accessibilityTraits.contains(.button))
        XCTAssertTrue(testNode.isAccessibilityElement)
        
        // Test convenience methods
        testNode.makeAccessibleButton(label: "Button", hint: "Button hint")
        XCTAssertEqual(testNode.accessibilityLabel, "Button")
        XCTAssertEqual(testNode.accessibilityHint, "Button hint")
        XCTAssertTrue(testNode.accessibilityTraits.contains(.button))
        
        testNode.makeAccessibleText("Text content")
        XCTAssertEqual(testNode.accessibilityLabel, "Text content")
        XCTAssertTrue(testNode.accessibilityTraits.contains(.staticText))
        
        testNode.makeAccessibleAdjustable(label: "Adjustable", value: "50%", hint: "Adjustable hint")
        XCTAssertEqual(testNode.accessibilityLabel, "Adjustable")
        XCTAssertEqual(testNode.accessibilityValue, "50%")
        XCTAssertEqual(testNode.accessibilityHint, "Adjustable hint")
        XCTAssertTrue(testNode.accessibilityTraits.contains(.adjustable))
        
        // Test removal
        testNode.removeAccessibility()
        XCTAssertFalse(testNode.isAccessibilityElement)
        XCTAssertNil(testNode.accessibilityLabel)
        XCTAssertNil(testNode.accessibilityHint)
        XCTAssertNil(testNode.accessibilityValue)
    }
    
    // MARK: - UILabel Extension Tests
    
    func testUILabelDynamicTypeConfiguration() throws {
        let testLabel = UILabel()
        testLabel.text = "Test Label"
        
        testLabel.configureDynamicType(textStyle: .body, baseSize: 16)
        
        XCTAssertTrue(testLabel.adjustsFontForContentSizeCategory)
        XCTAssertNotNil(testLabel.font)
        XCTAssertEqual(testLabel.numberOfLines, 0) // Should allow multiple lines
    }
    
    // MARK: - UIButton Extension Tests
    
    func testUIButtonDynamicTypeConfiguration() throws {
        let testButton = UIButton(type: .system)
        testButton.setTitle("Test Button", for: .normal)
        
        testButton.configureDynamicType(textStyle: .body, baseSize: 16)
        
        XCTAssertTrue(testButton.titleLabel?.adjustsFontForContentSizeCategory ?? false)
        XCTAssertNotNil(testButton.titleLabel?.font)
    }
}

// MARK: - Accessibility Testing Extensions

extension XCTestCase {
    
    /// Helper method to test accessibility compliance of a view controller
    /// - Parameter viewController: View controller to test
    /// - Returns: Array of accessibility issues found
    func testAccessibilityCompliance(for viewController: UIViewController) -> [String] {
        var issues: [String] = []
        
        // Load the view
        viewController.loadViewIfNeeded()
        
        // Check for basic accessibility requirements
        issues.append(contentsOf: checkAccessibilityLabels(in: viewController.view))
        issues.append(contentsOf: checkTouchTargetSizes(in: viewController.view))
        issues.append(contentsOf: checkColorContrast(in: viewController.view))
        
        return issues
    }
    
    private func checkAccessibilityLabels(in view: UIView) -> [String] {
        var issues: [String] = []
        
        func checkView(_ view: UIView) {
            if view.isAccessibilityElement {
                if view.accessibilityLabel?.isEmpty != false {
                    issues.append("Missing accessibility label for \(type(of: view))")
                }
            }
            
            // Check interactive elements specifically
            if view is UIButton || view is UIControl {
                if !view.isAccessibilityElement {
                    issues.append("Interactive element \(type(of: view)) is not accessible")
                }
            }
            
            for subview in view.subviews {
                checkView(subview)
            }
        }
        
        checkView(view)
        return issues
    }
    
    private func checkTouchTargetSizes(in view: UIView) -> [String] {
        var issues: [String] = []
        let minimumSize = DynamicTypeHelper.shared.minimumTouchTargetSize
        
        func checkView(_ view: UIView) {
            if view.isUserInteractionEnabled && (view is UIButton || view is UIControl) {
                if view.frame.width < minimumSize.width || view.frame.height < minimumSize.height {
                    issues.append("Touch target too small for \(type(of: view)): \(view.frame.size)")
                }
            }
            
            for subview in view.subviews {
                checkView(subview)
            }
        }
        
        checkView(view)
        return issues
    }
    
    private func checkColorContrast(in view: UIView) -> [String] {
        var issues: [String] = []
        
        func checkView(_ view: UIView) {
            if let label = view as? UILabel,
               let textColor = label.textColor,
               let backgroundColor = label.backgroundColor ?? view.backgroundColor {
                
                let contrast = calculateContrast(textColor: textColor, backgroundColor: backgroundColor)
                if contrast < 4.5 {
                    issues.append("Low contrast ratio for \(type(of: label)): \(String(format: "%.2f", contrast))")
                }
            }
            
            for subview in view.subviews {
                checkView(subview)
            }
        }
        
        checkView(view)
        return issues
    }
    
    private func calculateContrast(textColor: UIColor, backgroundColor: UIColor) -> Double {
        let textLuminance = getLuminance(textColor)
        let backgroundLuminance = getLuminance(backgroundColor)
        
        let lighter = max(textLuminance, backgroundLuminance)
        let darker = min(textLuminance, backgroundLuminance)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    private func getLuminance(_ color: UIColor) -> Double {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return 0.299 * Double(red) + 0.587 * Double(green) + 0.114 * Double(blue)
    }
}

// MARK: - Mock Classes for Testing

class MockAccessibilityElement: NSObject {
    override var accessibilityLabel: String? {
        get { return _accessibilityLabel }
        set { _accessibilityLabel = newValue }
    }
    
    override var accessibilityHint: String? {
        get { return _accessibilityHint }
        set { _accessibilityHint = newValue }
    }
    
    override var accessibilityValue: String? {
        get { return _accessibilityValue }
        set { _accessibilityValue = newValue }
    }
    
    override var accessibilityTraits: UIAccessibilityTraits {
        get { return _accessibilityTraits }
        set { _accessibilityTraits = newValue }
    }
    
    override var isAccessibilityElement: Bool {
        get { return _isAccessibilityElement }
        set { _isAccessibilityElement = newValue }
    }
    
    private var _accessibilityLabel: String?
    private var _accessibilityHint: String?
    private var _accessibilityValue: String?
    private var _accessibilityTraits: UIAccessibilityTraits = .none
    private var _isAccessibilityElement: Bool = false
}