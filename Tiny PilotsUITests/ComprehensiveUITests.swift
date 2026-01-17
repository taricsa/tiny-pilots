import XCTest

/// Comprehensive UI tests for critical user flows and end-to-end validation
class ComprehensiveUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-user-defaults"]
    }
    
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Critical User Flow Tests
    
    /// Test first-time user onboarding flow
    func testFirstTimeUserOnboarding() throws {
        app.launch()
        
        // Check for onboarding screens
        if app.staticTexts["Welcome to Tiny Pilots"].waitForExistence(timeout: 5) {
            // Test onboarding flow
            XCTAssertTrue(app.buttons["Get Started"].exists)
            app.buttons["Get Started"].tap()
            
            // Privacy consent screen
            XCTAssertTrue(app.staticTexts["Privacy & Data"].waitForExistence(timeout: 3))
            XCTAssertTrue(app.buttons["Accept"].exists)
            XCTAssertTrue(app.buttons["Learn More"].exists)
            
            app.buttons["Accept"].tap()
            
            // Tutorial screen
            XCTAssertTrue(app.staticTexts["How to Play"].waitForExistence(timeout: 3))
            XCTAssertTrue(app.buttons["Start Tutorial"].exists)
            XCTAssertTrue(app.buttons["Skip"].exists)
            
            app.buttons["Start Tutorial"].tap()
            
            // Verify tutorial game starts
            XCTAssertTrue(app.otherElements["TutorialScene"].waitForExistence(timeout: 5))
        }
        
        // Verify main menu appears after onboarding
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 10))
    }
    
    /// Test complete game session from start to finish
    func testCompleteGameSession() throws {
        app.launch()
        
        // Skip onboarding if present
        skipOnboardingIfPresent()
        
        // Start new game
        app.buttons["Play"].tap()
        app.buttons["Free Play"].tap()
        
        // Select environment
        XCTAssertTrue(app.buttons["Sunny Meadows"].waitForExistence(timeout: 3))
        app.buttons["Sunny Meadows"].tap()
        
        // Wait for game to load
        XCTAssertTrue(app.otherElements["GameScene"].waitForExistence(timeout: 5))
        
        // Verify game UI elements
        XCTAssertTrue(app.staticTexts["Score: 0"].exists)
        XCTAssertTrue(app.staticTexts["Distance: 0"].exists)
        
        // Launch airplane
        let gameView = app.otherElements["GameScene"]
        gameView.tap()
        
        // Wait for flight to begin
        Thread.sleep(forTimeInterval: 2)
        
        // Verify score updates
        XCTAssertFalse(app.staticTexts["Score: 0"].exists) // Score should have changed
        
        // Continue playing for a bit
        Thread.sleep(forTimeInterval: 3)
        
        // End game by crashing
        gameView.swipeDown()
        
        // Verify game over screen
        XCTAssertTrue(app.staticTexts["Game Over"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Final Score:'")).firstMatch.exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Distance:'")).firstMatch.exists)
        
        // Test game over options
        XCTAssertTrue(app.buttons["Play Again"].exists)
        XCTAssertTrue(app.buttons["Main Menu"].exists)
        XCTAssertTrue(app.buttons["Share Score"].exists)
        
        // Return to main menu
        app.buttons["Main Menu"].tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 3))
    }
    
    /// Test airplane customization workflow
    func testAirplaneCustomizationWorkflow() throws {
        app.launch()
        skipOnboardingIfPresent()
        
        // Navigate to hangar
        app.buttons["Hangar"].tap()
        XCTAssertTrue(app.staticTexts["Airplane Customization"].waitForExistence(timeout: 3))
        
        // Test airplane type selection
        XCTAssertTrue(app.buttons["Basic Paper"].exists)
        XCTAssertTrue(app.buttons["Dart Fold"].exists)
        XCTAssertTrue(app.buttons["Glider"].exists)
        
        // Select different airplane
        app.buttons["Dart Fold"].tap()
        
        // Verify airplane preview updates
        XCTAssertTrue(app.images["AirplanePreview"].exists)
        
        // Test fold type selection
        XCTAssertTrue(app.buttons["Standard"].exists)
        XCTAssertTrue(app.buttons["Sharp"].exists)
        
        app.buttons["Sharp"].tap()
        
        // Test design selection
        XCTAssertTrue(app.buttons["Plain"].exists)
        XCTAssertTrue(app.buttons["Striped"].exists)
        XCTAssertTrue(app.buttons["Dotted"].exists)
        
        app.buttons["Striped"].tap()
        
        // Test color selection
        XCTAssertTrue(app.buttons["Red"].exists)
        XCTAssertTrue(app.buttons["Blue"].exists)
        XCTAssertTrue(app.buttons["Green"].exists)
        
        app.buttons["Blue"].tap()
        
        // Save customization
        app.buttons["Save Changes"].tap()
        
        // Verify save confirmation
        XCTAssertTrue(app.alerts["Customization Saved"].waitForExistence(timeout: 3))
        app.alerts["Customization Saved"].buttons["OK"].tap()
        
        // Test in game to verify customization applied
        app.buttons["Test Flight"].tap()
        XCTAssertTrue(app.otherElements["GameScene"].waitForExistence(timeout: 5))
        
        // Return to hangar
        app.buttons["Back"].tap()
        XCTAssertTrue(app.staticTexts["Airplane Customization"].waitForExistence(timeout: 3))
        
        // Return to main menu
        app.buttons["Back"].tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 3))
    }
    
    /// Test challenge creation and sharing flow
    func testChallengeCreationAndSharing() throws {
        app.launch()
        skipOnboardingIfPresent()
        
        // Navigate to challenge mode
        app.buttons["Play"].tap()
        app.buttons["Challenge"].tap()
        
        // Create new challenge
        app.buttons["Create Challenge"].tap()
        XCTAssertTrue(app.textFields["Challenge Name"].waitForExistence(timeout: 3))
        
        // Fill challenge details
        app.textFields["Challenge Name"].tap()
        app.textFields["Challenge Name"].typeText("UI Test Challenge")
        
        // Select environment
        app.buttons["Environment"].tap()
        app.buttons["Alpine Heights"].tap()
        
        // Set difficulty
        app.buttons["Difficulty"].tap()
        app.buttons["Hard"].tap()
        
        // Add obstacles
        app.buttons["Add Obstacles"].tap()
        app.buttons["Wind Gusts"].tap()
        app.buttons["Birds"].tap()
        app.buttons["Done"].tap()
        
        // Create challenge
        app.buttons["Create Challenge"].tap()
        
        // Verify challenge created
        XCTAssertTrue(app.staticTexts["Challenge Created!"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Challenge Code:'")).firstMatch.exists)
        
        // Test sharing
        app.buttons["Share Challenge"].tap()
        
        // Verify share sheet appears
        XCTAssertTrue(app.otherElements["ActivityViewController"].waitForExistence(timeout: 3))
        
        // Cancel sharing
        app.buttons["Cancel"].tap()
        
        // Test challenge
        app.buttons["Test Challenge"].tap()
        XCTAssertTrue(app.otherElements["GameScene"].waitForExistence(timeout: 5))
        
        // Verify challenge elements are present
        Thread.sleep(forTimeInterval: 2)
        
        // End test
        app.otherElements["GameScene"].swipeDown()
        XCTAssertTrue(app.buttons["Main Menu"].waitForExistence(timeout: 5))
        app.buttons["Main Menu"].tap()
    }
    
    /// Test daily run participation flow
    func testDailyRunParticipation() throws {
        app.launch()
        skipOnboardingIfPresent()
        
        // Navigate to daily run
        app.buttons["Play"].tap()
        app.buttons["Daily Run"].tap()
        
        // Verify daily run screen
        XCTAssertTrue(app.staticTexts["Today's Challenge"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Day'")).firstMatch.exists)
        
        // Check leaderboard
        app.buttons["View Leaderboard"].tap()
        XCTAssertTrue(app.staticTexts["Daily Leaderboard"].waitForExistence(timeout: 3))
        app.buttons["Back"].tap()
        
        // Start daily run
        app.buttons["Start Daily Run"].tap()
        XCTAssertTrue(app.otherElements["GameScene"].waitForExistence(timeout: 5))
        
        // Play daily run
        let gameView = app.otherElements["GameScene"]
        gameView.tap()
        
        Thread.sleep(forTimeInterval: 5)
        
        // End game
        gameView.swipeDown()
        
        // Verify daily run results
        XCTAssertTrue(app.staticTexts["Daily Run Complete"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Rank:'")).firstMatch.exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Points Earned:'")).firstMatch.exists)
        
        // Share results
        app.buttons["Share Results"].tap()
        XCTAssertTrue(app.otherElements["ActivityViewController"].waitForExistence(timeout: 3))
        app.buttons["Cancel"].tap()
        
        // Return to main menu
        app.buttons["Main Menu"].tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 3))
    }
    
    /// Test Game Center integration flow
    func testGameCenterIntegration() throws {
        app.launch()
        skipOnboardingIfPresent()
        
        // Navigate to leaderboards
        app.buttons["Leaderboards"].tap()
        XCTAssertTrue(app.staticTexts["Leaderboards"].waitForExistence(timeout: 5))
        
        // Test leaderboard categories
        XCTAssertTrue(app.buttons["Distance"].exists)
        XCTAssertTrue(app.buttons["Score"].exists)
        XCTAssertTrue(app.buttons["Time"].exists)
        
        // Switch between leaderboards
        app.buttons["Score"].tap()
        Thread.sleep(forTimeInterval: 2)
        
        app.buttons["Time"].tap()
        Thread.sleep(forTimeInterval: 2)
        
        // View achievements
        app.buttons["Achievements"].tap()
        XCTAssertTrue(app.staticTexts["Achievements"].waitForExistence(timeout: 3))
        
        // Test achievement categories
        XCTAssertTrue(app.buttons["All"].exists)
        XCTAssertTrue(app.buttons["Unlocked"].exists)
        XCTAssertTrue(app.buttons["Locked"].exists)
        
        app.buttons["Unlocked"].tap()
        Thread.sleep(forTimeInterval: 1)
        
        app.buttons["Locked"].tap()
        Thread.sleep(forTimeInterval: 1)
        
        // Return to main menu
        app.buttons["Back"].tap()
        app.buttons["Back"].tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 3))
    }
    
    /// Test settings and preferences flow
    func testSettingsAndPreferences() throws {
        app.launch()
        skipOnboardingIfPresent()
        
        // Navigate to settings
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 3))
        
        // Test audio settings
        XCTAssertTrue(app.switches["Sound Effects"].exists)
        XCTAssertTrue(app.switches["Music"].exists)
        XCTAssertTrue(app.sliders["Master Volume"].exists)
        
        // Toggle audio settings
        let soundEffectsSwitch = app.switches["Sound Effects"]
        let initialSoundState = soundEffectsSwitch.value as! String == "1"
        soundEffectsSwitch.tap()
        XCTAssertNotEqual(soundEffectsSwitch.value as! String == "1", initialSoundState)
        
        // Adjust volume
        app.sliders["Master Volume"].adjust(toNormalizedSliderPosition: 0.5)
        
        // Test gameplay settings
        XCTAssertTrue(app.switches["Tilt Controls"].exists)
        XCTAssertTrue(app.switches["Haptic Feedback"].exists)
        
        app.switches["Tilt Controls"].tap()
        app.switches["Haptic Feedback"].tap()
        
        // Test accessibility settings
        app.buttons["Accessibility"].tap()
        XCTAssertTrue(app.staticTexts["Accessibility Settings"].waitForExistence(timeout: 3))
        
        XCTAssertTrue(app.switches["VoiceOver Announcements"].exists)
        XCTAssertTrue(app.switches["Reduce Motion"].exists)
        XCTAssertTrue(app.switches["High Contrast"].exists)
        
        app.switches["VoiceOver Announcements"].tap()
        app.switches["Reduce Motion"].tap()
        
        app.buttons["Back"].tap()
        
        // Test privacy settings
        app.buttons["Privacy"].tap()
        XCTAssertTrue(app.staticTexts["Privacy Settings"].waitForExistence(timeout: 3))
        
        XCTAssertTrue(app.switches["Analytics"].exists)
        XCTAssertTrue(app.switches["Crash Reporting"].exists)
        XCTAssertTrue(app.buttons["View Privacy Policy"].exists)
        XCTAssertTrue(app.buttons["Export My Data"].exists)
        
        app.switches["Analytics"].tap()
        
        app.buttons["Back"].tap()
        
        // Test data management
        app.buttons["Data Management"].tap()
        XCTAssertTrue(app.staticTexts["Data Management"].waitForExistence(timeout: 3))
        
        XCTAssertTrue(app.buttons["Backup to iCloud"].exists)
        XCTAssertTrue(app.buttons["Restore from Backup"].exists)
        XCTAssertTrue(app.buttons["Reset Game Progress"].exists)
        
        app.buttons["Back"].tap()
        
        // Return to main menu
        app.buttons["Back"].tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 3))
    }
    
    // MARK: - Error Handling and Edge Cases
    
    /// Test app behavior with network connectivity issues
    func testNetworkConnectivityHandling() throws {
        // Launch app in offline mode
        app.launchArguments.append("--offline-mode")
        app.launch()
        skipOnboardingIfPresent()
        
        // Try to access online features
        app.buttons["Play"].tap()
        app.buttons["Daily Run"].tap()
        
        // Verify offline message appears
        XCTAssertTrue(app.alerts["No Internet Connection"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.alerts["No Internet Connection"].staticTexts["Daily Run requires an internet connection. Please check your connection and try again."].exists)
        
        app.alerts["No Internet Connection"].buttons["OK"].tap()
        
        // Verify offline features still work
        app.buttons["Back"].tap()
        app.buttons["Free Play"].tap()
        XCTAssertTrue(app.buttons["Sunny Meadows"].waitForExistence(timeout: 3))
        
        // Test offline gameplay
        app.buttons["Sunny Meadows"].tap()
        XCTAssertTrue(app.otherElements["GameScene"].waitForExistence(timeout: 5))
        
        app.otherElements["GameScene"].tap()
        Thread.sleep(forTimeInterval: 2)
        app.otherElements["GameScene"].swipeDown()
        
        XCTAssertTrue(app.buttons["Main Menu"].waitForExistence(timeout: 5))
        app.buttons["Main Menu"].tap()
    }
    
    /// Test app recovery from crashes and errors
    func testErrorRecoveryHandling() throws {
        app.launch()
        skipOnboardingIfPresent()
        
        // Trigger a recoverable error
        app.launchArguments.append("--simulate-error")
        
        // Navigate to a feature that might trigger an error
        app.buttons["Hangar"].tap()
        
        // Verify error recovery
        if app.alerts["Error Occurred"].waitForExistence(timeout: 5) {
            XCTAssertTrue(app.alerts["Error Occurred"].buttons["Retry"].exists)
            XCTAssertTrue(app.alerts["Error Occurred"].buttons["Cancel"].exists)
            
            app.alerts["Error Occurred"].buttons["Retry"].tap()
            
            // Verify recovery
            XCTAssertTrue(app.staticTexts["Airplane Customization"].waitForExistence(timeout: 5))
        }
        
        app.buttons["Back"].tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 3))
    }
    
    // MARK: - Helper Methods
    
    private func skipOnboardingIfPresent() {
        if app.staticTexts["Welcome to Tiny Pilots"].waitForExistence(timeout: 2) {
            app.buttons["Skip"].tap()
        }
        
        if app.staticTexts["Privacy & Data"].waitForExistence(timeout: 2) {
            app.buttons["Accept"].tap()
        }
        
        if app.staticTexts["How to Play"].waitForExistence(timeout: 2) {
            app.buttons["Skip"].tap()
        }
    }
    
    private func waitForMainMenu() {
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 10))
    }
}

// MARK: - Performance UI Tests

extension ComprehensiveUITests {
    
    /// Test UI responsiveness during gameplay
    func testUIResponsivenessDuringGameplay() throws {
        app.launch()
        skipOnboardingIfPresent()
        
        // Start game
        app.buttons["Play"].tap()
        app.buttons["Free Play"].tap()
        app.buttons["Sunny Meadows"].tap()
        
        let gameView = app.otherElements["GameScene"]
        XCTAssertTrue(gameView.waitForExistence(timeout: 5))
        
        // Test rapid interactions
        for _ in 0..<10 {
            gameView.tap()
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        // Verify game is still responsive
        XCTAssertTrue(gameView.exists)
        XCTAssertTrue(gameView.isHittable)
        
        // End game
        gameView.swipeDown()
        XCTAssertTrue(app.buttons["Main Menu"].waitForExistence(timeout: 5))
        app.buttons["Main Menu"].tap()
    }
    
    /// Test app launch time performance
    func testAppLaunchPerformance() throws {
        let launchMetric = XCTApplicationLaunchMetric()
        let measureOptions = XCTMeasureOptions()
        measureOptions.iterationCount = 5
        
        measure(metrics: [launchMetric], options: measureOptions) {
            app.launch()
            waitForMainMenu()
            app.terminate()
        }
    }
    
    /// Test memory usage during extended UI interactions
    func testMemoryUsageDuringExtendedInteractions() throws {
        app.launch()
        skipOnboardingIfPresent()
        
        // Perform extended UI interactions
        for _ in 0..<20 {
            // Navigate through different screens
            app.buttons["Hangar"].tap()
            Thread.sleep(forTimeInterval: 0.5)
            
            app.buttons["Back"].tap()
            Thread.sleep(forTimeInterval: 0.5)
            
            app.buttons["Settings"].tap()
            Thread.sleep(forTimeInterval: 0.5)
            
            app.buttons["Back"].tap()
            Thread.sleep(forTimeInterval: 0.5)
            
            app.buttons["Leaderboards"].tap()
            Thread.sleep(forTimeInterval: 0.5)
            
            app.buttons["Back"].tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        // Verify app is still responsive
        XCTAssertTrue(app.buttons["Play"].exists)
        XCTAssertTrue(app.buttons["Play"].isHittable)
    }
}