//
//  GameStateManagerTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on Build Fixes Implementation
//

import XCTest
import Combine
@testable import Tiny_Pilots

final class GameStateManagerTests: XCTestCase {
    
    var gameStateManager: GameStateManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        // Create a fresh instance for each test
        gameStateManager = GameStateManager.shared
        gameStateManager.resetGame() // Start with clean state
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        gameStateManager.resetGame()
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertEqual(gameStateManager.currentState.status, .notStarted)
        XCTAssertEqual(gameStateManager.currentState.score, 0)
        XCTAssertEqual(gameStateManager.currentState.distance, 0)
        XCTAssertEqual(gameStateManager.currentState.timeElapsed, 0)
        XCTAssertEqual(gameStateManager.currentState.coinsCollected, 0)
        XCTAssertFalse(gameStateManager.isGameActive)
    }
    
    // MARK: - Game Lifecycle Tests
    
    func testStartGame() {
        let expectation = XCTestExpectation(description: "Game state should change to playing")
        
        gameStateManager.gameStatePublisher
            .sink { state in
                if state.status == .playing {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        gameStateManager.startGame(mode: .freePlay, environmentType: "meadow")
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(gameStateManager.currentState.status, .playing)
        XCTAssertEqual(gameStateManager.currentState.mode, .freePlay)
        XCTAssertEqual(gameStateManager.currentState.environmentType, "meadow")
        XCTAssertTrue(gameStateManager.isGameActive)
        XCTAssertNotNil(gameStateManager.currentState.startTime)
        XCTAssertNil(gameStateManager.currentState.endTime)
    }
    
    func testPauseGame() {
        gameStateManager.startGame()
        
        let expectation = XCTestExpectation(description: "Game state should change to paused")
        
        gameStateManager.gameStatePublisher
            .dropFirst() // Skip the initial playing state
            .sink { state in
                if state.status == .paused {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        gameStateManager.pauseGame()
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(gameStateManager.currentState.status, .paused)
        XCTAssertTrue(gameStateManager.isGameActive)
    }
    
    func testResumeGame() {
        gameStateManager.startGame()
        gameStateManager.pauseGame()
        
        let expectation = XCTestExpectation(description: "Game state should change back to playing")
        
        gameStateManager.gameStatePublisher
            .dropFirst(2) // Skip initial and paused states
            .sink { state in
                if state.status == .playing {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        gameStateManager.resumeGame()
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(gameStateManager.currentState.status, .playing)
        XCTAssertTrue(gameStateManager.isGameActive)
    }
    
    func testEndGame() {
        gameStateManager.startGame()
        
        let expectation = XCTestExpectation(description: "Game state should change to ended")
        
        gameStateManager.gameStatePublisher
            .dropFirst() // Skip the initial playing state
            .sink { state in
                if state.status == .ended {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        gameStateManager.endGame()
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(gameStateManager.currentState.status, .ended)
        XCTAssertFalse(gameStateManager.isGameActive)
        XCTAssertNotNil(gameStateManager.currentState.endTime)
    }
    
    func testResetGame() {
        gameStateManager.startGame()
        gameStateManager.addScore(100)
        gameStateManager.addDistance(50.0)
        
        gameStateManager.resetGame()
        
        XCTAssertEqual(gameStateManager.currentState.status, .notStarted)
        XCTAssertEqual(gameStateManager.currentState.score, 0)
        XCTAssertEqual(gameStateManager.currentState.distance, 0)
        XCTAssertFalse(gameStateManager.isGameActive)
    }
    
    // MARK: - Invalid State Transition Tests
    
    func testPauseGameWhenNotPlaying() {
        // Should not be able to pause when not playing
        gameStateManager.pauseGame()
        XCTAssertEqual(gameStateManager.currentState.status, .notStarted)
    }
    
    func testResumeGameWhenNotPaused() {
        gameStateManager.startGame()
        // Should not be able to resume when already playing
        gameStateManager.resumeGame()
        XCTAssertEqual(gameStateManager.currentState.status, .playing)
    }
    
    func testEndGameWhenNotActive() {
        // Should not be able to end when not active
        gameStateManager.endGame()
        XCTAssertEqual(gameStateManager.currentState.status, .notStarted)
    }
    
    // MARK: - Score and Progress Tests
    
    func testUpdateScore() {
        gameStateManager.startGame()
        
        gameStateManager.updateScore(150)
        XCTAssertEqual(gameStateManager.currentState.score, 150)
        
        gameStateManager.addScore(50)
        XCTAssertEqual(gameStateManager.currentState.score, 200)
    }
    
    func testUpdateDistance() {
        gameStateManager.startGame()
        
        gameStateManager.updateDistance(25.5)
        XCTAssertEqual(gameStateManager.currentState.distance, 25.5)
        
        gameStateManager.addDistance(10.0)
        XCTAssertEqual(gameStateManager.currentState.distance, 35.5)
    }
    
    func testUpdateTimeElapsed() {
        gameStateManager.startGame()
        
        gameStateManager.updateTimeElapsed(30.0)
        XCTAssertEqual(gameStateManager.currentState.timeElapsed, 30.0)
    }
    
    func testUpdateCoinsCollected() {
        gameStateManager.startGame()
        
        gameStateManager.updateCoinsCollected(5)
        XCTAssertEqual(gameStateManager.currentState.coinsCollected, 5)
        
        gameStateManager.addCoin()
        XCTAssertEqual(gameStateManager.currentState.coinsCollected, 6)
    }
    
    func testChangeEnvironment() {
        gameStateManager.startGame(environmentType: "meadow")
        XCTAssertEqual(gameStateManager.currentState.environmentType, "meadow")
        
        gameStateManager.changeEnvironment("alpine")
        XCTAssertEqual(gameStateManager.currentState.environmentType, "alpine")
    }
    
    // MARK: - Progress Updates Only Work When Playing
    
    func testScoreUpdateOnlyWhenPlaying() {
        // Should not update score when not playing
        gameStateManager.updateScore(100)
        XCTAssertEqual(gameStateManager.currentState.score, 0)
        
        gameStateManager.startGame()
        gameStateManager.updateScore(100)
        XCTAssertEqual(gameStateManager.currentState.score, 100)
        
        gameStateManager.pauseGame()
        gameStateManager.updateScore(200)
        XCTAssertEqual(gameStateManager.currentState.score, 100) // Should not change when paused
    }
    
    // MARK: - Persistence Tests
    
    func testSaveAndLoadGameState() {
        gameStateManager.startGame(mode: .challenge, environmentType: "alpine")
        gameStateManager.updateScore(250)
        gameStateManager.updateDistance(75.0)
        gameStateManager.updateCoinsCollected(3)
        
        // Save the current state
        gameStateManager.saveGameState()
        
        // Reset and load
        gameStateManager.resetGame()
        XCTAssertEqual(gameStateManager.currentState.score, 0)
        
        gameStateManager.loadGameState()
        
        XCTAssertEqual(gameStateManager.currentState.mode, .challenge)
        XCTAssertEqual(gameStateManager.currentState.environmentType, "alpine")
        XCTAssertEqual(gameStateManager.currentState.score, 250)
        XCTAssertEqual(gameStateManager.currentState.distance, 75.0)
        XCTAssertEqual(gameStateManager.currentState.coinsCollected, 3)
    }
    
    func testClearSavedState() {
        gameStateManager.startGame()
        gameStateManager.updateScore(100)
        gameStateManager.saveGameState()
        
        gameStateManager.clearSavedState()
        gameStateManager.resetGame()
        gameStateManager.loadGameState()
        
        // Should be back to initial state
        XCTAssertEqual(gameStateManager.currentState.status, .notStarted)
        XCTAssertEqual(gameStateManager.currentState.score, 0)
    }
    
    // MARK: - Helper Method Tests
    
    func testCanStartMode() {
        XCTAssertTrue(gameStateManager.canStartMode(.freePlay))
        XCTAssertTrue(gameStateManager.canStartMode(.challenge))
        
        gameStateManager.startGame()
        XCTAssertFalse(gameStateManager.canStartMode(.freePlay))
    }
    
    func testGetCurrentSessionDuration() {
        XCTAssertNil(gameStateManager.getCurrentSessionDuration())
        
        gameStateManager.startGame()
        
        // Should have a duration when active
        let duration = gameStateManager.getCurrentSessionDuration()
        XCTAssertNotNil(duration)
        XCTAssertGreaterThanOrEqual(duration!, 0)
        
        gameStateManager.endGame()
        
        // Should still have a duration when ended
        let finalDuration = gameStateManager.getCurrentSessionDuration()
        XCTAssertNotNil(finalDuration)
    }
    
    // MARK: - Publisher Tests
    
    func testGameStatePublisher() {
        let expectation = XCTestExpectation(description: "Should receive state updates")
        expectation.expectedFulfillmentCount = 2 // Initial + playing
        
        gameStateManager.gameStatePublisher
            .sink { state in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        gameStateManager.startGame()
        
        wait(for: [expectation], timeout: 1.0)
    }
}