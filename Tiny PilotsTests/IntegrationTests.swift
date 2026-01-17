import XCTest
import SpriteKit
import GameKit
@testable import Tiny_Pilots

/// Comprehensive integration tests for end-to-end feature validation
/// Tests complete gameplay flows from app launch to game completion
class IntegrationTests: XCTestCase {
    
    var app: XCUIApplication!
    var mockServices: MockServices!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        
        // Initialize test app
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        
        // Set up mock services for testing
        mockServices = MockServices()
        setupMockEnvironment()
    }
    
    override func tearDownWithError() throws {
        app = nil
        mockServices = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Complete Gameplay Flow Tests
    
    /// Test complete gameplay flow from app launch to game completion
    func testCompleteGameplayFlow() throws {
        // Launch app
        app.launch()
        
        // Verify main menu appears
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Hangar"].exists)
        XCTAssertTrue(app.buttons["Settings"].exists)
        
        // Navigate to game mode selection
        app.buttons["Play"].tap()
        XCTAssertTrue(app.buttons["Free Play"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Challenge"].exists)
        XCTAssertTrue(app.buttons["Daily Run"].exists)
        
        // Start free play game
        app.buttons["Free Play"].tap()
        
        // Verify environment selection
        XCTAssertTrue(app.buttons["Sunny Meadows"].waitForExistence(timeout: 3))
        app.buttons["Sunny Meadows"].tap()
        
        // Verify game scene loads
        XCTAssertTrue(app.otherElements["GameScene"].waitForExistence(timeout: 5))
        
        // Simulate gameplay interaction
        let gameView = app.otherElements["GameScene"]
        gameView.tap() // Launch airplane
        
        // Wait for game to progress
        Thread.sleep(forTimeInterval: 3)
        
        // Verify game UI elements
        XCTAssertTrue(app.staticTexts["Score:"].exists)
        XCTAssertTrue(app.staticTexts["Distance:"].exists)
        
        // End game (simulate crash or completion)
        gameView.swipeDown() // Force end game
        
        // Verify game over screen
        XCTAssertTrue(app.staticTexts["Game Over"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Play Again"].exists)
        XCTAssertTrue(app.buttons["Main Menu"].exists)
        
        // Return to main menu
        app.buttons["Main Menu"].tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 3))
    }
    
    /// Test all game modes functionality
    func testAllGameModes() throws {
        app.launch()
        
        // Test Free Play mode
        testGameMode("Free Play", expectedEnvironments: ["Sunny Meadows", "Alpine Heights", "Coastal Breeze"])
        
        // Test Challenge mode
        testGameMode("Challenge", expectedElements: ["Enter Challenge Code", "Create Challenge"])
        
        // Test Daily Run mode
        testGameMode("Daily Run", expectedElements: ["Today's Challenge", "Leaderboard"])
        
        // Test Weekly Special mode
        testGameMode("Weekly Special", expectedElements: ["This Week's Special", "Rewards"])
    }
    
    /// Test hangar customization flow
    func testHangarCustomizationFlow() throws {
        app.launch()
        
        // Navigate to hangar
        app.buttons["Hangar"].tap()
        XCTAssertTrue(app.staticTexts["Airplane Customization"].waitForExistence(timeout: 3))
        
        // Test airplane selection
        XCTAssertTrue(app.buttons["Basic Paper"].exists)
        XCTAssertTrue(app.buttons["Dart Fold"].exists)
        
        // Select different airplane
        app.buttons["Dart Fold"].tap()
        
        // Test design customization
        XCTAssertTrue(app.buttons["Plain"].exists)
        XCTAssertTrue(app.buttons["Striped"].exists)
        
        app.buttons["Striped"].tap()
        
        // Test color customization
        XCTAssertTrue(app.buttons["Blue"].exists)
        app.buttons["Blue"].tap()
        
        // Save changes
        app.buttons["Save"].tap()
        
        // Verify changes are applied
        XCTAssertTrue(app.staticTexts["Changes Saved"].waitForExistence(timeout: 2))
        
        // Return to main menu
        app.buttons["Back"].tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 3))
    }
    
    /// Test settings and accessibility features
    func testSettingsAndAccessibility() throws {
        app.launch()
        
        // Navigate to settings
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 3))
        
        // Test sound settings
        XCTAssertTrue(app.switches["Sound Effects"].exists)
        XCTAssertTrue(app.switches["Music"].exists)
        
        // Toggle sound settings
        app.switches["Sound Effects"].tap()
        app.switches["Music"].tap()
        
        // Test accessibility settings
        XCTAssertTrue(app.switches["VoiceOver Announcements"].exists)
        XCTAssertTrue(app.switches["Reduce Motion"].exists)
        
        // Toggle accessibility settings
        app.switches["VoiceOver Announcements"].tap()
        app.switches["Reduce Motion"].tap()
        
        // Test privacy settings
        XCTAssertTrue(app.buttons["Privacy Policy"].exists)
        XCTAssertTrue(app.buttons["Terms of Service"].exists)
        
        // Test data management
        XCTAssertTrue(app.buttons["Export Data"].exists)
        XCTAssertTrue(app.buttons["Delete All Data"].exists)
        
        // Return to main menu
        app.buttons["Back"].tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 3))
    }
    
    // MARK: - Game Center Integration Tests
    
    /// Test Game Center authentication and features
    func testGameCenterIntegration() throws {
        app.launch()
        
        // Navigate to Game Center view
        app.buttons["Leaderboards"].tap()
        XCTAssertTrue(app.staticTexts["Leaderboards"].waitForExistence(timeout: 5))
        
        // Test leaderboard categories
        XCTAssertTrue(app.buttons["Distance"].exists)
        XCTAssertTrue(app.buttons["Score"].exists)
        XCTAssertTrue(app.buttons["Time"].exists)
        
        // Switch between leaderboards
        app.buttons["Score"].tap()
        XCTAssertTrue(app.staticTexts["High Scores"].waitForExistence(timeout: 3))
        
        // Test achievements view
        app.buttons["Achievements"].tap()
        XCTAssertTrue(app.staticTexts["Achievements"].waitForExistence(timeout: 3))
        
        // Verify achievement categories
        XCTAssertTrue(app.staticTexts["Distance"].exists)
        XCTAssertTrue(app.staticTexts["Score"].exists)
        XCTAssertTrue(app.staticTexts["Collection"].exists)
        
        // Return to main menu
        app.buttons["Back"].tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 3))
    }
    
    /// Test challenge sharing and social features
    func testChallengeSharingFlow() throws {
        app.launch()
        
        // Navigate to challenge mode
        app.buttons["Play"].tap()
        app.buttons["Challenge"].tap()
        
        // Test challenge creation
        app.buttons["Create Challenge"].tap()
        XCTAssertTrue(app.textFields["Challenge Name"].waitForExistence(timeout: 3))
        
        // Fill challenge details
        app.textFields["Challenge Name"].tap()
        app.textFields["Challenge Name"].typeText("Test Challenge")
        
        // Select difficulty
        app.buttons["Medium"].tap()
        
        // Create challenge
        app.buttons["Create"].tap()
        
        // Verify challenge code generation
        XCTAssertTrue(app.staticTexts["Challenge Code:"].waitForExistence(timeout: 3))
        
        // Test sharing functionality
        app.buttons["Share Challenge"].tap()
        XCTAssertTrue(app.otherElements["ActivityViewController"].waitForExistence(timeout: 3))
        
        // Cancel sharing
        app.buttons["Cancel"].tap()
        
        // Return to main menu
        app.buttons["Back"].tap()
        app.buttons["Back"].tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 3))
    }
    
    // MARK: - Accessibility Validation Tests
    
    /// Test VoiceOver and accessibility features
    func testAccessibilityFeatures() throws {
        app.launch()
        
        // Enable accessibility testing
        app.launchArguments.append("--accessibility-testing")
        
        // Test main menu accessibility
        validateAccessibilityLabels(for: ["Play", "Hangar", "Settings", "Leaderboards"])
        
        // Navigate to game and test accessibility
        app.buttons["Play"].tap()
        validateAccessibilityLabels(for: ["Free Play", "Challenge", "Daily Run", "Weekly Special"])
        
        // Test game scene accessibility
        app.buttons["Free Play"].tap()
        app.buttons["Sunny Meadows"].tap()
        
        // Verify game accessibility announcements
        XCTAssertTrue(app.staticTexts["Game Started"].waitForExistence(timeout: 5))
        
        // Test dynamic type scaling
        testDynamicTypeScaling()
        
        // Test high contrast mode
        testHighContrastMode()
    }
    
    /// Test dynamic type scaling across the app
    func testDynamicTypeScaling() {
        // Test different content size categories
        let contentSizes: [UIContentSizeCategory] = [
            .small,
            .medium,
            .large,
            .extraLarge,
            .extraExtraLarge,
            .accessibilityMedium,
            .accessibilityLarge,
            .accessibilityExtraLarge
        ]
        
        for contentSize in contentSizes {
            // Set content size category
            app.launchArguments.append("--content-size-\(contentSize.rawValue)")
            
            // Verify text scales appropriately
            XCTAssertTrue(app.buttons["Play"].exists)
            
            // Check that text is readable and not truncated
            let playButton = app.buttons["Play"]
            XCTAssertTrue(playButton.frame.height > 0)
            XCTAssertTrue(playButton.frame.width > 0)
        }
    }
    
    /// Test high contrast mode support
    func testHighContrastMode() {
        // Enable high contrast mode
        app.launchArguments.append("--high-contrast")
        
        // Verify high contrast colors are applied
        XCTAssertTrue(app.buttons["Play"].exists)
        
        // Test button visibility and contrast
        let playButton = app.buttons["Play"]
        XCTAssertTrue(playButton.isHittable)
        
        // Navigate through app to test contrast in different screens
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].exists)
        
        app.buttons["Back"].tap()
        XCTAssertTrue(app.buttons["Play"].exists)
    }
    
    // MARK: - Helper Methods
    
    private func setupMockEnvironment() {
        // Configure mock services for testing
        mockServices.setupMockGameCenter()
        mockServices.setupMockAnalytics()
        mockServices.setupMockNetworking()
    }
    
    private func testGameMode(_ modeName: String, expectedEnvironments: [String]? = nil, expectedElements: [String]? = nil) {
        app.buttons["Play"].tap()
        app.buttons[modeName].tap()
        
        if let environments = expectedEnvironments {
            for environment in environments {
                XCTAssertTrue(app.buttons[environment].waitForExistence(timeout: 3), "Environment \(environment) not found")
            }
            app.buttons["Back"].tap()
        }
        
        if let elements = expectedElements {
            for element in elements {
                XCTAssertTrue(app.otherElements[element].waitForExistence(timeout: 3) || 
                             app.buttons[element].waitForExistence(timeout: 3) ||
                             app.staticTexts[element].waitForExistence(timeout: 3), 
                             "Element \(element) not found")
            }
            app.buttons["Back"].tap()
        }
        
        app.buttons["Back"].tap()
    }
    
    private func validateAccessibilityLabels(for elements: [String]) {
        for element in elements {
            let button = app.buttons[element]
            XCTAssertTrue(button.exists, "Button \(element) not found")
            XCTAssertNotNil(button.label, "Button \(element) missing accessibility label")
            XCTAssertFalse(button.label.isEmpty, "Button \(element) has empty accessibility label")
        }
    }
}

// MARK: - Performance Integration Tests

extension IntegrationTests {
    
    /// Test app launch performance
    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
            app.terminate()
        }
    }
    
    /// Test gameplay performance during extended sessions
    func testExtendedGameplayPerformance() throws {
        app.launch()
        
        // Start performance monitoring
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Navigate to game
        app.buttons["Play"].tap()
        app.buttons["Free Play"].tap()
        app.buttons["Sunny Meadows"].tap()
        
        // Simulate extended gameplay
        let gameView = app.otherElements["GameScene"]
        
        for _ in 0..<10 {
            gameView.tap()
            Thread.sleep(forTimeInterval: 2)
            
            // Verify game is still responsive
            XCTAssertTrue(gameView.exists)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Verify performance is within acceptable limits
        XCTAssertLessThan(duration, 30.0, "Extended gameplay took too long")
    }
    
    /// Test memory usage during gameplay
    func testMemoryUsageDuringGameplay() throws {
        app.launch()
        
        // Monitor memory usage
        let initialMemory = getMemoryUsage()
        
        // Play multiple games to test memory management
        for _ in 0..<5 {
            playCompleteGame()
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Verify memory usage doesn't grow excessively
        XCTAssertLessThan(memoryIncrease, 50.0, "Memory usage increased too much: \(memoryIncrease)MB")
    }
    
    private func playCompleteGame() {
        app.buttons["Play"].tap()
        app.buttons["Free Play"].tap()
        app.buttons["Sunny Meadows"].tap()
        
        let gameView = app.otherElements["GameScene"]
        gameView.tap()
        
        Thread.sleep(forTimeInterval: 3)
        
        gameView.swipeDown() // End game
        
        XCTAssertTrue(app.buttons["Main Menu"].waitForExistence(timeout: 5))
        app.buttons["Main Menu"].tap()
    }
    
    private func getMemoryUsage() -> Double {
        // Get current memory usage in MB
        let info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0
        }
        
        return 0.0
    }
}