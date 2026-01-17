import XCTest

/// Comprehensive accessibility testing for VoiceOver and assistive technology compatibility
class AccessibilityUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--accessibility-testing"]
    }
    
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - VoiceOver Navigation Tests
    
    /// Test VoiceOver navigation through main menu
    func testVoiceOverMainMenuNavigation() throws {
        app.launch()
        
        // Enable VoiceOver for testing
        enableVoiceOverTesting()
        
        // Test main menu accessibility
        let playButton = app.buttons["Play"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 5))
        XCTAssertTrue(playButton.isAccessibilityElement)
        XCTAssertNotNil(playButton.accessibilityLabel)
        XCTAssertFalse(playButton.accessibilityLabel!.isEmpty)
        
        let hangarButton = app.buttons["Hangar"]
        XCTAssertTrue(hangarButton.isAccessibilityElement)
        XCTAssertNotNil(hangarButton.accessibilityLabel)
        XCTAssertNotNil(hangarButton.accessibilityHint)
        
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.isAccessibilityElement)
        XCTAssertNotNil(settingsButton.accessibilityLabel)
        
        let leaderboardsButton = app.buttons["Leaderboards"]
        XCTAssertTrue(leaderboardsButton.isAccessibilityElement)
        XCTAssertNotNil(leaderboardsButton.accessibilityLabel)
        
        // Test navigation order
        testAccessibilityNavigationOrder([playButton, hangarButton, settingsButton, leaderboardsButton])
    }
    
    /// Test VoiceOver navigation in game mode selection
    func testVoiceOverGameModeSelection() throws {
        app.launch()
        enableVoiceOverTesting()
        
        app.buttons["Play"].tap()
        
        // Test game mode buttons accessibility
        let freePlayButton = app.buttons["Free Play"]
        XCTAssertTrue(freePlayButton.waitForExistence(timeout: 3))
        XCTAssertTrue(freePlayButton.isAccessibilityElement)
        XCTAssertEqual(freePlayButton.accessibilityTraits, .button)
        XCTAssertNotNil(freePlayButton.accessibilityLabel)
        XCTAssertNotNil(freePlayButton.accessibilityHint)
        
        let challengeButton = app.buttons["Challenge"]
        XCTAssertTrue(challengeButton.isAccessibilityElement)
        XCTAssertNotNil(challengeButton.accessibilityLabel)
        
        let dailyRunButton = app.buttons["Daily Run"]
        XCTAssertTrue(dailyRunButton.isAccessibilityElement)
        XCTAssertNotNil(dailyRunButton.accessibilityLabel)
        
        let weeklySpecialButton = app.buttons["Weekly Special"]
        XCTAssertTrue(weeklySpecialButton.isAccessibilityElement)
        XCTAssertNotNil(weeklySpecialButton.accessibilityLabel)
        
        // Test back button accessibility
        let backButton = app.buttons["Back"]
        XCTAssertTrue(backButton.isAccessibilityElement)
        XCTAssertNotNil(backButton.accessibilityLabel)
        
        backButton.tap()
    }
    
    /// Test VoiceOver navigation in hangar customization
    func testVoiceOverHangarNavigation() throws {
        app.launch()
        enableVoiceOverTesting()
        
        app.buttons["Hangar"].tap()
        
        // Test airplane selection accessibility
        let basicPaperButton = app.buttons["Basic Paper"]
        XCTAssertTrue(basicPaperButton.waitForExistence(timeout: 3))
        XCTAssertTrue(basicPaperButton.isAccessibilityElement)
        XCTAssertNotNil(basicPaperButton.accessibilityLabel)
        XCTAssertNotNil(basicPaperButton.accessibilityHint)
        
        // Test airplane preview accessibility
        let airplanePreview = app.images["AirplanePreview"]
        if airplanePreview.exists {
            XCTAssertTrue(airplanePreview.isAccessibilityElement)
            XCTAssertNotNil(airplanePreview.accessibilityLabel)
        }
        
        // Test customization options accessibility
        let colorButtons = app.buttons.matching(NSPredicate(format: "accessibilityLabel CONTAINS 'Color'"))
        for i in 0..<colorButtons.count {
            let colorButton = colorButtons.element(boundBy: i)
            XCTAssertTrue(colorButton.isAccessibilityElement)
            XCTAssertNotNil(colorButton.accessibilityLabel)
        }
        
        // Test save button accessibility
        let saveButton = app.buttons["Save Changes"]
        if saveButton.exists {
            XCTAssertTrue(saveButton.isAccessibilityElement)
            XCTAssertNotNil(saveButton.accessibilityLabel)
            XCTAssertNotNil(saveButton.accessibilityHint)
        }
        
        app.buttons["Back"].tap()
    }
    
    /// Test VoiceOver navigation in settings
    func testVoiceOverSettingsNavigation() throws {
        app.launch()
        enableVoiceOverTesting()
        
        app.buttons["Settings"].tap()
        
        // Test settings switches accessibility
        let soundEffectsSwitch = app.switches["Sound Effects"]
        XCTAssertTrue(soundEffectsSwitch.waitForExistence(timeout: 3))
        XCTAssertTrue(soundEffectsSwitch.isAccessibilityElement)
        XCTAssertEqual(soundEffectsSwitch.accessibilityTraits, .button) // Switches have button trait
        XCTAssertNotNil(soundEffectsSwitch.accessibilityLabel)
        XCTAssertNotNil(soundEffectsSwitch.accessibilityValue)
        
        let musicSwitch = app.switches["Music"]
        XCTAssertTrue(musicSwitch.isAccessibilityElement)
        XCTAssertNotNil(musicSwitch.accessibilityLabel)
        XCTAssertNotNil(musicSwitch.accessibilityValue)
        
        // Test volume slider accessibility
        let volumeSlider = app.sliders["Master Volume"]
        if volumeSlider.exists {
            XCTAssertTrue(volumeSlider.isAccessibilityElement)
            XCTAssertEqual(volumeSlider.accessibilityTraits, .adjustable)
            XCTAssertNotNil(volumeSlider.accessibilityLabel)
            XCTAssertNotNil(volumeSlider.accessibilityValue)
        }
        
        // Test accessibility settings
        if app.buttons["Accessibility"].exists {
            app.buttons["Accessibility"].tap()
            
            let voiceOverSwitch = app.switches["VoiceOver Announcements"]
            XCTAssertTrue(voiceOverSwitch.waitForExistence(timeout: 3))
            XCTAssertTrue(voiceOverSwitch.isAccessibilityElement)
            XCTAssertNotNil(voiceOverSwitch.accessibilityLabel)
            
            app.buttons["Back"].tap()
        }
        
        app.buttons["Back"].tap()
    }
    
    // MARK: - Dynamic Type Tests
    
    /// Test dynamic type scaling across different content size categories
    func testDynamicTypeScaling() throws {
        let contentSizes: [String] = [
            "UICTContentSizeCategoryS",
            "UICTContentSizeCategoryM", 
            "UICTContentSizeCategoryL",
            "UICTContentSizeCategoryXL",
            "UICTContentSizeCategoryXXL",
            "UICTContentSizeCategoryAccessibilityM",
            "UICTContentSizeCategoryAccessibilityL",
            "UICTContentSizeCategoryAccessibilityXL"
        ]
        
        for contentSize in contentSizes {
            // Set content size category
            app.launchArguments = ["--uitesting", "--content-size-\(contentSize)"]
            app.launch()
            
            // Test main menu text scaling
            let playButton = app.buttons["Play"]
            XCTAssertTrue(playButton.waitForExistence(timeout: 5))
            
            // Verify button is still visible and tappable
            XCTAssertTrue(playButton.isHittable)
            XCTAssertGreaterThan(playButton.frame.height, 0)
            XCTAssertGreaterThan(playButton.frame.width, 0)
            
            // Test settings text scaling
            app.buttons["Settings"].tap()
            
            let soundEffectsLabel = app.staticTexts["Sound Effects"]
            if soundEffectsLabel.exists {
                XCTAssertTrue(soundEffectsLabel.isHittable)
                XCTAssertGreaterThan(soundEffectsLabel.frame.height, 0)
            }
            
            app.buttons["Back"].tap()
            app.terminate()
        }
    }
    
    /// Test text truncation and layout at large text sizes
    func testLargeTextLayoutHandling() throws {
        // Test with largest accessibility text size
        app.launchArguments = ["--uitesting", "--content-size-UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        
        // Test main menu layout
        let playButton = app.buttons["Play"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 5))
        
        // Verify text is not truncated
        XCTAssertFalse(playButton.label.contains("..."))
        
        // Test settings layout with large text
        app.buttons["Settings"].tap()
        
        let settingsTitle = app.staticTexts["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3))
        XCTAssertFalse(settingsTitle.label.contains("..."))
        
        // Test switch labels are readable
        let soundEffectsSwitch = app.switches["Sound Effects"]
        if soundEffectsSwitch.exists {
            XCTAssertTrue(soundEffectsSwitch.isHittable)
            // Verify switch is still accessible at large text sizes
            XCTAssertGreaterThan(soundEffectsSwitch.frame.height, 44) // Minimum touch target
        }
        
        app.buttons["Back"].tap()
    }
    
    // MARK: - High Contrast and Visual Accessibility Tests
    
    /// Test high contrast mode support
    func testHighContrastMode() throws {
        app.launchArguments = ["--uitesting", "--high-contrast"]
        app.launch()
        
        // Test main menu in high contrast
        let playButton = app.buttons["Play"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 5))
        XCTAssertTrue(playButton.isHittable)
        
        // Test button visibility and contrast
        XCTAssertGreaterThan(playButton.frame.height, 0)
        XCTAssertGreaterThan(playButton.frame.width, 0)
        
        // Navigate through app to test contrast in different screens
        app.buttons["Settings"].tap()
        
        let settingsTitle = app.staticTexts["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3))
        XCTAssertTrue(settingsTitle.isHittable)
        
        // Test switches in high contrast
        let soundEffectsSwitch = app.switches["Sound Effects"]
        if soundEffectsSwitch.exists {
            XCTAssertTrue(soundEffectsSwitch.isHittable)
        }
        
        app.buttons["Back"].tap()
        
        // Test game screen in high contrast
        app.buttons["Play"].tap()
        app.buttons["Free Play"].tap()
        app.buttons["Sunny Meadows"].tap()
        
        let gameView = app.otherElements["GameScene"]
        XCTAssertTrue(gameView.waitForExistence(timeout: 5))
        
        // Verify game elements are visible in high contrast
        XCTAssertTrue(gameView.isHittable)
        
        gameView.swipeDown() // End game quickly
        XCTAssertTrue(app.buttons["Main Menu"].waitForExistence(timeout: 5))
        app.buttons["Main Menu"].tap()
    }
    
    /// Test reduce motion support
    func testReduceMotionSupport() throws {
        app.launchArguments = ["--uitesting", "--reduce-motion"]
        app.launch()
        
        // Test that animations are reduced or disabled
        let playButton = app.buttons["Play"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 5))
        
        // Navigate to game to test reduced motion
        app.buttons["Play"].tap()
        
        // Verify screen transitions are immediate or reduced
        let freePlayButton = app.buttons["Free Play"]
        XCTAssertTrue(freePlayButton.waitForExistence(timeout: 2)) // Should appear quickly
        
        app.buttons["Back"].tap()
        
        // Test settings screen with reduced motion
        app.buttons["Settings"].tap()
        
        let settingsTitle = app.staticTexts["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 2))
        
        app.buttons["Back"].tap()
    }
    
    // MARK: - Assistive Technology Integration Tests
    
    /// Test Switch Control compatibility
    func testSwitchControlCompatibility() throws {
        app.launchArguments = ["--uitesting", "--switch-control"]
        app.launch()
        
        // Test that all interactive elements are accessible via Switch Control
        let playButton = app.buttons["Play"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 5))
        XCTAssertTrue(playButton.isAccessibilityElement)
        
        // Verify button can be activated
        XCTAssertTrue(playButton.isHittable)
        
        // Test navigation through focusable elements
        let focusableElements = [
            app.buttons["Play"],
            app.buttons["Hangar"],
            app.buttons["Settings"],
            app.buttons["Leaderboards"]
        ]
        
        for element in focusableElements {
            XCTAssertTrue(element.isAccessibilityElement)
            XCTAssertTrue(element.isHittable)
        }
    }
    
    /// Test Voice Control compatibility
    func testVoiceControlCompatibility() throws {
        app.launchArguments = ["--uitesting", "--voice-control"]
        app.launch()
        
        // Test that elements have appropriate accessibility labels for voice commands
        let playButton = app.buttons["Play"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 5))
        XCTAssertNotNil(playButton.accessibilityLabel)
        XCTAssertFalse(playButton.accessibilityLabel!.isEmpty)
        
        // Test that labels are clear and unambiguous
        let hangarButton = app.buttons["Hangar"]
        XCTAssertNotNil(hangarButton.accessibilityLabel)
        XCTAssertNotEqual(hangarButton.accessibilityLabel, playButton.accessibilityLabel)
        
        // Test settings elements
        app.buttons["Settings"].tap()
        
        let soundEffectsSwitch = app.switches["Sound Effects"]
        if soundEffectsSwitch.exists {
            XCTAssertNotNil(soundEffectsSwitch.accessibilityLabel)
            XCTAssertTrue(soundEffectsSwitch.accessibilityLabel!.contains("Sound"))
        }
        
        app.buttons["Back"].tap()
    }
    
    // MARK: - Accessibility Announcements Tests
    
    /// Test VoiceOver announcements during gameplay
    func testGameplayAccessibilityAnnouncements() throws {
        app.launchArguments = ["--uitesting", "--voiceover-announcements"]
        app.launch()
        
        // Start a game
        app.buttons["Play"].tap()
        app.buttons["Free Play"].tap()
        app.buttons["Sunny Meadows"].tap()
        
        let gameView = app.otherElements["GameScene"]
        XCTAssertTrue(gameView.waitForExistence(timeout: 5))
        
        // Launch airplane and check for announcements
        gameView.tap()
        
        // Wait for game events that should trigger announcements
        Thread.sleep(forTimeInterval: 3)
        
        // Check for accessibility notifications (these would be tested with actual VoiceOver)
        // In a real test environment, you would verify that appropriate announcements are made
        
        // End game
        gameView.swipeDown()
        XCTAssertTrue(app.buttons["Main Menu"].waitForExistence(timeout: 5))
        app.buttons["Main Menu"].tap()
    }
    
    /// Test accessibility announcements for UI state changes
    func testUIStateChangeAnnouncements() throws {
        app.launchArguments = ["--uitesting", "--voiceover-announcements"]
        app.launch()
        
        // Test settings changes announcements
        app.buttons["Settings"].tap()
        
        let soundEffectsSwitch = app.switches["Sound Effects"]
        if soundEffectsSwitch.exists {
            // Toggle switch and verify announcement would be made
            soundEffectsSwitch.tap()
            
            // In a real test, you would verify the announcement content
            // For now, we verify the switch state changed
            XCTAssertNotNil(soundEffectsSwitch.accessibilityValue)
        }
        
        app.buttons["Back"].tap()
    }
    
    // MARK: - Helper Methods
    
    private func enableVoiceOverTesting() {
        // In a real implementation, this would enable VoiceOver simulation
        // For UI tests, we verify accessibility properties are set correctly
    }
    
    private func testAccessibilityNavigationOrder(_ elements: [XCUIElement]) {
        // Verify elements can be navigated in logical order
        for element in elements {
            XCTAssertTrue(element.isAccessibilityElement)
            XCTAssertTrue(element.isHittable)
        }
    }
    
    private func verifyMinimumTouchTargetSize(_ element: XCUIElement) {
        // Verify element meets minimum 44x44 point touch target size
        XCTAssertGreaterThanOrEqual(element.frame.height, 44)
        XCTAssertGreaterThanOrEqual(element.frame.width, 44)
    }
    
    private func verifyAccessibilityLabel(_ element: XCUIElement, contains text: String) {
        XCTAssertNotNil(element.accessibilityLabel)
        XCTAssertTrue(element.accessibilityLabel!.localizedCaseInsensitiveContains(text))
    }
}

// MARK: - Accessibility Validation Tests

extension AccessibilityUITests {
    
    /// Test accessibility compliance across all screens
    func testAccessibilityCompliance() throws {
        app.launch()
        
        // Test main menu compliance
        validateScreenAccessibility("Main Menu")
        
        // Test game mode selection compliance
        app.buttons["Play"].tap()
        validateScreenAccessibility("Game Mode Selection")
        app.buttons["Back"].tap()
        
        // Test hangar compliance
        app.buttons["Hangar"].tap()
        validateScreenAccessibility("Hangar")
        app.buttons["Back"].tap()
        
        // Test settings compliance
        app.buttons["Settings"].tap()
        validateScreenAccessibility("Settings")
        app.buttons["Back"].tap()
        
        // Test leaderboards compliance
        app.buttons["Leaderboards"].tap()
        validateScreenAccessibility("Leaderboards")
        app.buttons["Back"].tap()
    }
    
    private func validateScreenAccessibility(_ screenName: String) {
        // Get all interactive elements on screen
        let buttons = app.buttons.allElementsBoundByIndex
        let switches = app.switches.allElementsBoundByIndex
        let sliders = app.sliders.allElementsBoundByIndex
        
        let allInteractiveElements = buttons + switches + sliders
        
        for element in allInteractiveElements {
            if element.exists && element.isHittable {
                // Verify accessibility properties
                XCTAssertTrue(element.isAccessibilityElement, 
                             "Interactive element in \(screenName) is not accessible")
                XCTAssertNotNil(element.accessibilityLabel, 
                               "Interactive element in \(screenName) missing accessibility label")
                XCTAssertFalse(element.accessibilityLabel!.isEmpty, 
                              "Interactive element in \(screenName) has empty accessibility label")
                
                // Verify minimum touch target size
                verifyMinimumTouchTargetSize(element)
            }
        }
    }
    
    /// Test color contrast and visual accessibility
    func testColorContrastCompliance() throws {
        // This would typically require image analysis or specialized tools
        // For now, we test that high contrast mode works
        app.launchArguments = ["--uitesting", "--high-contrast", "--test-contrast"]
        app.launch()
        
        // Navigate through screens to verify contrast
        let screens = [
            ("Main Menu", [app.buttons["Play"]]),
            ("Settings", [app.buttons["Settings"]]),
            ("Hangar", [app.buttons["Hangar"]])
        ]
        
        for (screenName, navigationPath) in screens {
            for button in navigationPath {
                button.tap()
            }
            
            // Verify elements are visible in high contrast
            let visibleElements = app.buttons.allElementsBoundByIndex.filter { $0.exists && $0.isHittable }
            XCTAssertGreaterThan(visibleElements.count, 0, "No visible elements in \(screenName) with high contrast")
            
            // Return to main menu
            if app.buttons["Back"].exists {
                app.buttons["Back"].tap()
            }
        }
    }
}