//
//  GameManagerTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on Build Fixes Implementation
//

import XCTest
import Combine
@testable import Tiny_Pilots

final class GameManagerTests: XCTestCase {
    
    var gameManager: GameManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        gameManager = GameManager.shared
        gameManager.reset() // Start with clean state
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        gameManager.reset()
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertEqual(gameManager.score, 0)
        XCTAssertEqual(gameManager.level, 1)
        XCTAssertEqual(gameManager.gameState.status, .notStarted)
    }
    
    func testInitializeGame() {
        let expectation = XCTestExpectation(description: "Game should initialize")
        
        gameManager.scorePublisher
            .sink { score in
                if score == 0 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        gameManager.initializeGame(mode: .freePlay, environmentType: "meadow")
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(gameManager.score, 0)
        XCTAssertEqual(gameManager.level, 1)
        XCTAssertEqual(gameManager.gameState.status, .playing)
        XCTAssertEqual(gameManager.gameState.mode, .freePlay)
        XCTAssertEqual(gameManager.gameState.environmentType, "meadow")
    }
    
    // MARK: - Score Management Tests
    
    func testUpdateScore() {
        gameManager.initializeGame()
        
        let expectation = XCTestExpectation(description: "Score should update")
        
        gameManager.scorePublisher
            .dropFirst() // Skip initial 0
            .sink { score in
                if score == 150 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        gameManager.updateScore(150)
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(gameManager.score, 150)
        XCTAssertEqual(gameManager.gameState.score, 150)
    }
    
    func testAddScore() {
        gameManager.initializeGame()
        gameManager.updateScore(100)
        
        gameManager.addScore(50)
        
        XCTAssertEqual(gameManager.score, 150)
    }
    
    func testNegativeScoreHandling() {
        gameManager.initializeGame()
        
        gameManager.updateScore(-50)
        
        XCTAssertEqual(gameManager.score, 0) // Should not go below 0
    }
    
    // MARK: - Level Progression Tests
    
    func testLevelProgression() {
        gameManager.initializeGame()
        
        let expectation = XCTestExpectation(description: "Level should advance")
        
        gameManager.levelPublisher
            .dropFirst() // Skip initial level 1
            .sink { level in
                if level == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Score enough to reach next level (1000 points for level 2)
        gameManager.updateScore(1000)
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(gameManager.level, 2)
    }
    
    func testCanProgressToNextLevel() {
        gameManager.initializeGame()
        
        XCTAssertFalse(gameManager.canProgressToNextLevel())
        
        gameManager.updateScore(1000)
        XCTAssertTrue(gameManager.canProgressToNextLevel())
    }
    
    func testGetNextLevelThreshold() {
        gameManager.initializeGame()
        
        XCTAssertEqual(gameManager.getNextLevelThreshold(), 1000) // Level 1 → 2
        
        gameManager.updateScore(1000) // Advance to level 2
        XCTAssertEqual(gameManager.getNextLevelThreshold(), 2000) // Level 2 → 3
    }
    
    func testNextLevel() {
        gameManager.initializeGame()
        
        gameManager.nextLevel()
        
        XCTAssertEqual(gameManager.level, 2)
    }
    
    // MARK: - Collision Handling Tests
    
    func testObstacleCollision() {
        gameManager.initializeGame()
        
        let expectation = XCTestExpectation(description: "Game should end on obstacle collision")
        
        // Observe game state changes
        gameManager.$gameState
            .sink { state in
                if state.status == .ended {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        gameManager.handleCollision(.obstacle)
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(gameManager.gameState.status, .ended)
    }
    
    func testCollectibleCollision() {
        gameManager.initializeGame()
        let initialScore = gameManager.score
        
        gameManager.handleCollision(.collectible)
        
        XCTAssertGreaterThan(gameManager.score, initialScore)
        XCTAssertEqual(gameManager.gameState.coinsCollected, 1)
    }
    
    func testPowerUpCollision() {
        gameManager.initializeGame()
        let initialScore = gameManager.score
        
        gameManager.handleCollision(.powerUp)
        
        XCTAssertGreaterThan(gameManager.score, initialScore)
        // Power-ups should give more points than collectibles
    }
    
    func testBoundaryCollision() {
        gameManager.initializeGame()
        let initialState = gameManager.gameState.status
        
        gameManager.handleCollision(.boundary)
        
        // Boundary collision should not end the game
        XCTAssertEqual(gameManager.gameState.status, initialState)
    }
    
    // MARK: - Game Configuration Tests
    
    func testGetGameConfiguration() {
        gameManager.initializeGame(mode: .challenge, environmentType: "alpine")
        
        let config = gameManager.getGameConfiguration()
        
        XCTAssertEqual(config.level, 1)
        XCTAssertEqual(config.difficulty, 1.0)
        XCTAssertEqual(config.environmentType, "alpine")
        XCTAssertEqual(config.mode, .challenge)
        XCTAssertEqual(config.targetScore, 1000)
        XCTAssertNotNil(config.timeLimit) // Challenge mode should have time limit
    }
    
    func testDifficultyCalculation() {
        gameManager.initializeGame()
        
        let config1 = gameManager.getGameConfiguration()
        XCTAssertEqual(config1.difficulty, 1.0)
        
        gameManager.updateScore(1000) // Advance to level 2
        let config2 = gameManager.getGameConfiguration()
        XCTAssertGreaterThan(config2.difficulty, 1.0)
    }
    
    func testSpecialRulesForModes() {
        // Test tutorial mode
        gameManager.initializeGame(mode: .tutorial)
        let tutorialConfig = gameManager.getGameConfiguration()
        XCTAssertTrue(tutorialConfig.specialRules["showHints"] as? Bool ?? false)
        
        // Test daily run mode
        gameManager.reset()
        gameManager.initializeGame(mode: .dailyRun)
        let dailyRunConfig = gameManager.getGameConfiguration()
        XCTAssertTrue(dailyRunConfig.specialRules["fixedSeed"] as? Bool ?? false)
        XCTAssertNotNil(dailyRunConfig.timeLimit)
    }
    
    // MARK: - Reset Tests
    
    func testReset() {
        gameManager.initializeGame()
        gameManager.updateScore(500)
        gameManager.nextLevel()
        
        gameManager.reset()
        
        XCTAssertEqual(gameManager.score, 0)
        XCTAssertEqual(gameManager.level, 1)
        XCTAssertEqual(gameManager.gameState.status, .notStarted)
    }
    
    // MARK: - Statistics Tests
    
    func testGetGameStatistics() {
        gameManager.initializeGame(mode: .freePlay, environmentType: "meadow")
        gameManager.updateScore(250)
        
        let stats = gameManager.getGameStatistics()
        
        XCTAssertEqual(stats.score, 250)
        XCTAssertEqual(stats.level, 1)
        XCTAssertEqual(stats.mode, .freePlay)
        XCTAssertEqual(stats.environmentType, "meadow")
        XCTAssertGreaterThan(stats.difficulty, 0)
    }
    
    func testGetPerformanceMetrics() {
        gameManager.initializeGame()
        gameManager.updateScore(100)
        
        let metrics = gameManager.getPerformanceMetrics()
        
        XCTAssertNotNil(metrics["score_per_second"])
        XCTAssertNotNil(metrics["level_progression_rate"])
        XCTAssertNotNil(metrics["coins_per_minute"])
        XCTAssertNotNil(metrics["distance_per_second"])
    }
    
    // MARK: - Publisher Tests
    
    func testScorePublisher() {
        let expectation = XCTestExpectation(description: "Should receive score updates")
        expectation.expectedFulfillmentCount = 2 // Initial + updated
        
        gameManager.scorePublisher
            .sink { score in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        gameManager.initializeGame()
        gameManager.updateScore(100)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLevelPublisher() {
        let expectation = XCTestExpectation(description: "Should receive level updates")
        expectation.expectedFulfillmentCount = 2 // Initial + advanced
        
        gameManager.levelPublisher
            .sink { level in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        gameManager.initializeGame()
        gameManager.nextLevel()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Integration Tests
    
    func testGameManagerGameStateManagerIntegration() {
        // Test that GameManager properly syncs with GameStateManager
        gameManager.initializeGame()
        
        // Update score through GameManager
        gameManager.updateScore(150)
        
        // Verify GameStateManager has the same score
        let gameStateManager = GameStateManager.shared
        XCTAssertEqual(gameStateManager.currentState.score, 150)
        
        // Update score through GameStateManager
        gameStateManager.updateScore(200)
        
        // Verify GameManager syncs the change
        XCTAssertEqual(gameManager.score, 200)
    }
    
    func testNotificationPosting() {
        let expectation = XCTestExpectation(description: "Should post level change notification")
        
        NotificationCenter.default.addObserver(
            forName: .gameManagerLevelChanged,
            object: nil,
            queue: .main
        ) { notification in
            expectation.fulfill()
        }
        
        gameManager.initializeGame()
        gameManager.nextLevel()
        
        wait(for: [expectation], timeout: 1.0)
    }
}