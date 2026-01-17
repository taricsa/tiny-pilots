//
//  GameCenterIntegrationTests.swift
//  Tiny PilotsTests
//
//  Created for Game Center integration testing after architecture refactor
//

import XCTest
import SwiftData
@testable import Tiny_Pilots

/// Integration tests specifically for Game Center functionality
/// to ensure all Game Center features work correctly after the MVVM refactor
class GameCenterIntegrationTests: XCTestCase {
    
    // MARK: - Properties
    
    var container: ModelContainer!
    var context: ModelContext!
    var mockGameCenterService: MockGameCenterService!
    var gameViewModel: GameViewModel!
    var mainMenuViewModel: MainMenuViewModel!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Setup in-memory SwiftData container
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: PlayerData.self, GameResult.self, Achievement.self, configurations: config)
        context = ModelContext(container)
        
        // Create mock Game Center service
        mockGameCenterService = MockGameCenterService()
        
        // Configure dependency injection for testing
        try configureDependencyInjection()
        
        // Create ViewModels
        try createViewModels()
    }
    
    override func tearDownWithError() throws {
        gameViewModel?.cleanup()
        mainMenuViewModel?.cleanup()
        DIContainer.shared.reset()
        try super.tearDownWithError()
    }
    
    // MARK: - Test Configuration
    
    private func configureDependencyInjection() throws {
        DIContainer.shared.register(AudioServiceProtocol.self) {
            MockAudioService()
        }
        
        DIContainer.shared.register(PhysicsServiceProtocol.self) {
            MockPhysicsService()
        }
        
        DIContainer.shared.register(GameCenterServiceProtocol.self) {
            self.mockGameCenterService
        }
        
        DIContainer.shared.register(ModelContext.self) {
            self.context
        }
    }
    
    private func createViewModels() throws {
        gameViewModel = try GameViewModel(
            physicsService: DIContainer.shared.resolve(PhysicsServiceProtocol.self),
            audioService: DIContainer.shared.resolve(AudioServiceProtocol.self),
            gameCenterService: DIContainer.shared.resolve(GameCenterServiceProtocol.self),
            modelContext: DIContainer.shared.resolve(ModelContext.self)
        )
        
        mainMenuViewModel = try MainMenuViewModel(
            gameCenterService: DIContainer.shared.resolve(GameCenterServiceProtocol.self),
            audioService: DIContainer.shared.resolve(AudioServiceProtocol.self),
            modelContext: DIContainer.shared.resolve(ModelContext.self)
        )
    }
    
    // MARK: - Authentication Tests
    
    /// Test Game Center authentication flow
    func testGameCenterAuthentication() throws {
        print("🧪 Testing Game Center authentication...")
        
        // Test successful authentication
        mockGameCenterService.isAvailable = true
        mockGameCenterService.shouldSucceedAuthentication = true
        
        let authExpectation = expectation(description: "Authentication completion")
        
        mockGameCenterService.authenticate { success, error in
            XCTAssertTrue(success, "Authentication should succeed")
            XCTAssertNil(error, "No error should occur on successful authentication")
            authExpectation.fulfill()
        }
        
        wait(for: [authExpectation], timeout: 2.0)
        
        // Verify authentication was called
        XCTAssertTrue(mockGameCenterService.authenticateCalled, "Authenticate should be called")
        
        // Test failed authentication
        mockGameCenterService.reset()
        mockGameCenterService.isAvailable = true
        mockGameCenterService.shouldSucceedAuthentication = false
        
        let failAuthExpectation = expectation(description: "Failed authentication completion")
        
        mockGameCenterService.authenticate { success, error in
            XCTAssertFalse(success, "Authentication should fail")
            XCTAssertNotNil(error, "Error should be present on failed authentication")
            failAuthExpectation.fulfill()
        }
        
        wait(for: [failAuthExpectation], timeout: 2.0)
        
        print("✅ Game Center authentication test passed")
    }
    
    /// Test Game Center availability detection
    func testGameCenterAvailability() throws {
        print("🧪 Testing Game Center availability detection...")
        
        // Test when Game Center is available
        mockGameCenterService.isAvailable = true
        mainMenuViewModel.initialize()
        
        XCTAssertTrue(mainMenuViewModel.isGameCenterAvailable, "Game Center should be available")
        
        // Test when Game Center is not available
        mockGameCenterService.isAvailable = false
        mainMenuViewModel.initialize()
        
        XCTAssertFalse(mainMenuViewModel.isGameCenterAvailable, "Game Center should not be available")
        
        print("✅ Game Center availability detection test passed")
    }
    
    // MARK: - Leaderboard Tests
    
    /// Test leaderboard score submission
    func testLeaderboardScoreSubmission() throws {
        print("🧪 Testing leaderboard score submission...")
        
        mockGameCenterService.isAvailable = true
        mockGameCenterService.shouldSucceedAuthentication = true
        
        // Test score submission for different game modes
        let testScores = [
            ("distance_freeplay", 1500),
            ("distance_challenge", 2000),
            ("distance_dailyrun", 1200),
            ("distance_weeklyspecial", 1800)
        ]
        
        for (category, score) in testScores {
            let scoreExpectation = expectation(description: "Score submission for \(category)")
            
            mockGameCenterService.submitScore(score, category: category) { error in
                XCTAssertNil(error, "Score submission should succeed for \(category)")
                scoreExpectation.fulfill()
            }
            
            wait(for: [scoreExpectation], timeout: 1.0)
            
            // Verify the score was submitted correctly
            XCTAssertTrue(mockGameCenterService.submitScoreCalled, "Submit score should be called")
            XCTAssertEqual(mockGameCenterService.lastSubmittedScore, score, "Score should match")
            XCTAssertEqual(mockGameCenterService.lastSubmittedCategory, category, "Category should match")
            
            mockGameCenterService.reset()
        }
        
        print("✅ Leaderboard score submission test passed")
    }
    
    /// Test leaderboard loading
    func testLeaderboardLoading() throws {
        print("🧪 Testing leaderboard loading...")
        
        mockGameCenterService.isAvailable = true
        
        let loadExpectation = expectation(description: "Leaderboard loading")
        
        mockGameCenterService.loadLeaderboard(category: "distance_freeplay") { entries, error in
            XCTAssertNil(error, "Leaderboard loading should succeed")
            XCTAssertNotNil(entries, "Leaderboard entries should be returned")
            XCTAssertGreaterThan(entries?.count ?? 0, 0, "Should have mock leaderboard entries")
            loadExpectation.fulfill()
        }
        
        wait(for: [loadExpectation], timeout: 1.0)
        
        XCTAssertTrue(mockGameCenterService.loadLeaderboardCalled, "Load leaderboard should be called")
        
        print("✅ Leaderboard loading test passed")
    }
    
    /// Test score submission through game flow
    func testScoreSubmissionThroughGameFlow() throws {
        print("🧪 Testing score submission through game flow...")
        
        mockGameCenterService.isAvailable = true
        mockGameCenterService.shouldSucceedAuthentication = true
        
        // Initialize and start a game
        gameViewModel.initialize()
        gameViewModel.startGame(mode: .freePlay)
        
        // Simulate gameplay
        gameViewModel.updateDistance(500.0)
        gameViewModel.addCoin()
        gameViewModel.addCoin()
        
        // End the game (this should trigger score submission)
        gameViewModel.endGame()
        
        // Verify score was submitted
        XCTAssertTrue(mockGameCenterService.submitScoreCalled, "Score should be submitted when game ends")
        XCTAssertGreaterThan(mockGameCenterService.lastSubmittedScore, 0, "Submitted score should be greater than 0")
        
        print("✅ Score submission through game flow test passed")
    }
    
    // MARK: - Achievement Tests
    
    /// Test achievement reporting
    func testAchievementReporting() throws {
        print("🧪 Testing achievement reporting...")
        
        mockGameCenterService.isAvailable = true
        
        let testAchievements = [
            ("first_flight", 100.0),
            ("distance_100", 50.0),
            ("coin_collector", 75.0),
            ("speed_demon", 25.0)
        ]
        
        for (achievementId, progress) in testAchievements {
            let achievementExpectation = expectation(description: "Achievement reporting for \(achievementId)")
            
            mockGameCenterService.reportAchievement(achievementId, percentComplete: progress) { error in
                XCTAssertNil(error, "Achievement reporting should succeed for \(achievementId)")
                achievementExpectation.fulfill()
            }
            
            wait(for: [achievementExpectation], timeout: 1.0)
            
            // Verify achievement was reported correctly
            XCTAssertTrue(mockGameCenterService.reportAchievementCalled, "Report achievement should be called")
            XCTAssertEqual(mockGameCenterService.lastAchievementID, achievementId, "Achievement ID should match")
            XCTAssertEqual(mockGameCenterService.lastAchievementProgress, progress, "Achievement progress should match")
            
            mockGameCenterService.reset()
        }
        
        print("✅ Achievement reporting test passed")
    }
    
    /// Test achievement loading
    func testAchievementLoading() throws {
        print("🧪 Testing achievement loading...")
        
        mockGameCenterService.isAvailable = true
        
        let loadExpectation = expectation(description: "Achievement loading")
        
        mockGameCenterService.loadAchievements { achievements, error in
            XCTAssertNil(error, "Achievement loading should succeed")
            XCTAssertNotNil(achievements, "Achievements should be returned")
            XCTAssertGreaterThan(achievements?.count ?? 0, 0, "Should have mock achievements")
            loadExpectation.fulfill()
        }
        
        wait(for: [loadExpectation], timeout: 1.0)
        
        XCTAssertTrue(mockGameCenterService.loadAchievementsCalled, "Load achievements should be called")
        
        print("✅ Achievement loading test passed")
    }
    
    /// Test achievement tracking through gameplay
    func testAchievementTrackingThroughGameplay() throws {
        print("🧪 Testing achievement tracking through gameplay...")
        
        mockGameCenterService.isAvailable = true
        mockGameCenterService.shouldSucceedAuthentication = true
        
        // Initialize game
        gameViewModel.initialize()
        gameViewModel.startGame(mode: .freePlay)
        
        // Simulate actions that should trigger achievements
        gameViewModel.updateDistance(100.0) // Should trigger distance achievement
        gameViewModel.addCoin() // Should trigger coin collection achievement
        gameViewModel.endGame() // Should trigger first flight achievement
        
        // Verify achievements were tracked
        XCTAssertTrue(mockGameCenterService.loadAchievementsCalled, "Achievements should be loaded for tracking")
        
        print("✅ Achievement tracking through gameplay test passed")
    }
    
    // MARK: - Offline/Online Mode Tests
    
    /// Test offline mode behavior
    func testOfflineModeBehavior() throws {
        print("🧪 Testing offline mode behavior...")
        
        // Set Game Center as unavailable
        mockGameCenterService.isAvailable = false
        
        // Initialize ViewModels
        gameViewModel.initialize()
        mainMenuViewModel.initialize()
        
        // Verify Game Center features are disabled
        XCTAssertFalse(mainMenuViewModel.isGameCenterAvailable, "Game Center should not be available in offline mode")
        
        // Test that gameplay still works
        gameViewModel.startGame(mode: .freePlay)
        gameViewModel.updateDistance(200.0)
        gameViewModel.addCoin()
        gameViewModel.endGame()
        
        // Verify game state is correct even without Game Center
        XCTAssertEqual(gameViewModel.gameState.status, .gameOver, "Game should end properly in offline mode")
        XCTAssertEqual(gameViewModel.gameState.distance, 200.0, "Distance should be tracked in offline mode")
        XCTAssertEqual(gameViewModel.gameState.coinsCollected, 1, "Coins should be tracked in offline mode")
        
        // Verify no Game Center calls were made
        XCTAssertFalse(mockGameCenterService.submitScoreCalled, "No scores should be submitted in offline mode")
        XCTAssertFalse(mockGameCenterService.reportAchievementCalled, "No achievements should be reported in offline mode")
        
        print("✅ Offline mode behavior test passed")
    }
    
    /// Test online mode transition
    func testOnlineModeTransition() throws {
        print("🧪 Testing online mode transition...")
        
        // Start in offline mode
        mockGameCenterService.isAvailable = false
        mainMenuViewModel.initialize()
        XCTAssertFalse(mainMenuViewModel.isGameCenterAvailable, "Should start in offline mode")
        
        // Transition to online mode
        mockGameCenterService.isAvailable = true
        mockGameCenterService.shouldSucceedAuthentication = true
        
        // Re-initialize to simulate app becoming active
        mainMenuViewModel.initialize()
        XCTAssertTrue(mainMenuViewModel.isGameCenterAvailable, "Should transition to online mode")
        
        // Test that Game Center features now work
        let authExpectation = expectation(description: "Authentication after transition")
        
        mockGameCenterService.authenticate { success, error in
            XCTAssertTrue(success, "Authentication should work after transition to online")
            authExpectation.fulfill()
        }
        
        wait(for: [authExpectation], timeout: 1.0)
        
        print("✅ Online mode transition test passed")
    }
    
    /// Test network error handling
    func testNetworkErrorHandling() throws {
        print("🧪 Testing network error handling...")
        
        mockGameCenterService.isAvailable = true
        mockGameCenterService.shouldSimulateNetworkError = true
        
        // Test authentication with network error
        let authExpectation = expectation(description: "Authentication with network error")
        
        mockGameCenterService.authenticate { success, error in
            XCTAssertFalse(success, "Authentication should fail with network error")
            XCTAssertNotNil(error, "Error should be present")
            authExpectation.fulfill()
        }
        
        wait(for: [authExpectation], timeout: 1.0)
        
        // Test score submission with network error
        let scoreExpectation = expectation(description: "Score submission with network error")
        
        mockGameCenterService.submitScore(1000, category: "distance_freeplay") { error in
            XCTAssertNotNil(error, "Score submission should fail with network error")
            scoreExpectation.fulfill()
        }
        
        wait(for: [scoreExpectation], timeout: 1.0)
        
        // Test achievement reporting with network error
        let achievementExpectation = expectation(description: "Achievement reporting with network error")
        
        mockGameCenterService.reportAchievement("first_flight", percentComplete: 100.0) { error in
            XCTAssertNotNil(error, "Achievement reporting should fail with network error")
            achievementExpectation.fulfill()
        }
        
        wait(for: [achievementExpectation], timeout: 1.0)
        
        print("✅ Network error handling test passed")
    }
    
    // MARK: - Integration Test Summary
    
    /// Run all Game Center integration tests
    func testGameCenterIntegrationSuite() throws {
        print("\n🎮 Starting Game Center Integration Test Suite")
        print("=" * 60)
        
        let testMethods: [(String, () throws -> Void)] = [
            ("Game Center Authentication", testGameCenterAuthentication),
            ("Game Center Availability Detection", testGameCenterAvailability),
            ("Leaderboard Score Submission", testLeaderboardScoreSubmission),
            ("Leaderboard Loading", testLeaderboardLoading),
            ("Score Submission Through Game Flow", testScoreSubmissionThroughGameFlow),
            ("Achievement Reporting", testAchievementReporting),
            ("Achievement Loading", testAchievementLoading),
            ("Achievement Tracking Through Gameplay", testAchievementTrackingThroughGameplay),
            ("Offline Mode Behavior", testOfflineModeBehavior),
            ("Online Mode Transition", testOnlineModeTransition),
            ("Network Error Handling", testNetworkErrorHandling)
        ]
        
        var passedTests = 0
        var failedTests = 0
        
        for (testName, testMethod) in testMethods {
            do {
                try testMethod()
                passedTests += 1
            } catch {
                print("❌ \(testName) FAILED: \(error)")
                failedTests += 1
            }
        }
        
        print("\n" + "=" * 60)
        print("🏁 Game Center Integration Test Suite Complete")
        print("✅ Passed: \(passedTests)")
        print("❌ Failed: \(failedTests)")
        print("📊 Success Rate: \(Int((Double(passedTests) / Double(testMethods.count)) * 100))%")
        
        if failedTests == 0 {
            print("🎉 All Game Center integration tests passed!")
        } else {
            print("⚠️  Some Game Center tests failed. Review the failures above.")
        }
        
        XCTAssertEqual(failedTests, 0, "All Game Center integration tests should pass")
    }
}

// MARK: - String Extension for Test Output

private extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}