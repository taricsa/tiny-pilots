//
//  GameStateTests.swift
//  Tiny PilotsTests
//
//  Created on 2025-01-15.
//

import XCTest
@testable import Tiny_Pilots

final class GameStateTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        let gameState = GameState(
            mode: .freePlay,
            status: .playing,
            score: 100,
            distance: 50.5,
            timeElapsed: 30.0,
            coinsCollected: 5,
            environmentType: "mountain"
        )
        
        XCTAssertEqual(gameState.mode, .freePlay)
        XCTAssertEqual(gameState.status, .playing)
        XCTAssertEqual(gameState.score, 100)
        XCTAssertEqual(gameState.distance, 50.5)
        XCTAssertEqual(gameState.timeElapsed, 30.0)
        XCTAssertEqual(gameState.coinsCollected, 5)
        XCTAssertEqual(gameState.environmentType, "mountain")
    }
    
    func testInitializationWithNegativeValues() {
        let gameState = GameState(
            mode: .challenge,
            status: .playing,
            score: -10,
            distance: -5.0,
            timeElapsed: -1.0,
            coinsCollected: -2,
            environmentType: "desert"
        )
        
        // Negative values should be clamped to 0
        XCTAssertEqual(gameState.score, 0)
        XCTAssertEqual(gameState.distance, 0.0)
        XCTAssertEqual(gameState.timeElapsed, 0.0)
        XCTAssertEqual(gameState.coinsCollected, 0)
    }
    
    func testInitialState() {
        let initialState = GameState.initial
        
        XCTAssertEqual(initialState.mode, .freePlay)
        XCTAssertEqual(initialState.status, .notStarted)
        XCTAssertEqual(initialState.score, 0)
        XCTAssertEqual(initialState.distance, 0.0)
        XCTAssertEqual(initialState.timeElapsed, 0.0)
        XCTAssertEqual(initialState.coinsCollected, 0)
        XCTAssertEqual(initialState.environmentType, "standard")
        XCTAssertNil(initialState.startTime)
        XCTAssertNil(initialState.endTime)
    }
    
    // MARK: - Computed Properties Tests
    
    func testIsActive() {
        let playingState = GameState(
            mode: .freePlay,
            status: .playing,
            score: 0,
            distance: 0,
            timeElapsed: 0,
            coinsCollected: 0,
            environmentType: "standard"
        )
        XCTAssertTrue(playingState.isActive)
        
        let pausedState = playingState.pause()
        XCTAssertTrue(pausedState.isActive)
        
        let endedState = playingState.end()
        XCTAssertFalse(endedState.isActive)
        
        let notStartedState = GameState.initial
        XCTAssertFalse(notStartedState.isActive)
    }
    
    func testIsCompleted() {
        let playingState = GameState(
            mode: .freePlay,
            status: .playing,
            score: 0,
            distance: 0,
            timeElapsed: 0,
            coinsCollected: 0,
            environmentType: "standard"
        )
        XCTAssertFalse(playingState.isCompleted)
        
        let endedState = playingState.end()
        XCTAssertTrue(endedState.isCompleted)
    }
    
    func testCanPause() {
        let playingState = GameState(
            mode: .freePlay,
            status: .playing,
            score: 0,
            distance: 0,
            timeElapsed: 0,
            coinsCollected: 0,
            environmentType: "standard"
        )
        XCTAssertTrue(playingState.canPause)
        
        let pausedState = playingState.pause()
        XCTAssertFalse(pausedState.canPause)
        
        let endedState = playingState.end()
        XCTAssertFalse(endedState.canPause)
    }
    
    func testCanResume() {
        let playingState = GameState(
            mode: .freePlay,
            status: .playing,
            score: 0,
            distance: 0,
            timeElapsed: 0,
            coinsCollected: 0,
            environmentType: "standard"
        )
        XCTAssertFalse(playingState.canResume)
        
        let pausedState = playingState.pause()
        XCTAssertTrue(pausedState.canResume)
        
        let endedState = playingState.end()
        XCTAssertFalse(endedState.canResume)
    }
    
    func testCanStart() {
        let notStartedState = GameState.initial
        XCTAssertTrue(notStartedState.canStart)
        
        let playingState = notStartedState.start()
        XCTAssertFalse(playingState.canStart)
    }
    
    // MARK: - State Transition Tests
    
    func testStartTransition() {
        let initialState = GameState.initial
        let startedState = initialState.start()
        
        XCTAssertEqual(startedState.status, .playing)
        XCTAssertEqual(startedState.score, 0)
        XCTAssertEqual(startedState.distance, 0.0)
        XCTAssertEqual(startedState.timeElapsed, 0.0)
        XCTAssertEqual(startedState.coinsCollected, 0)
        XCTAssertNotNil(startedState.startTime)
        XCTAssertNil(startedState.endTime)
    }
    
    func testStartTransitionFromInvalidState() {
        let playingState = GameState(
            mode: .freePlay,
            status: .playing,
            score: 100,
            distance: 50.0,
            timeElapsed: 30.0,
            coinsCollected: 5,
            environmentType: "standard"
        )
        
        let attemptedStart = playingState.start()
        XCTAssertEqual(attemptedStart, playingState) // Should remain unchanged
    }
    
    func testPauseTransition() {
        let playingState = GameState(
            mode: .freePlay,
            status: .playing,
            score: 100,
            distance: 50.0,
            timeElapsed: 30.0,
            coinsCollected: 5,
            environmentType: "standard"
        )
        
        let pausedState = playingState.pause()
        
        XCTAssertEqual(pausedState.status, .paused)
        XCTAssertEqual(pausedState.score, 100)
        XCTAssertEqual(pausedState.distance, 50.0)
        XCTAssertEqual(pausedState.timeElapsed, 30.0)
        XCTAssertEqual(pausedState.coinsCollected, 5)
    }
    
    func testPauseTransitionFromInvalidState() {
        let notStartedState = GameState.initial
        let attemptedPause = notStartedState.pause()
        XCTAssertEqual(attemptedPause, notStartedState) // Should remain unchanged
    }
    
    func testResumeTransition() {
        let pausedState = GameState(
            mode: .freePlay,
            status: .paused,
            score: 100,
            distance: 50.0,
            timeElapsed: 30.0,
            coinsCollected: 5,
            environmentType: "standard"
        )
        
        let resumedState = pausedState.resume()
        
        XCTAssertEqual(resumedState.status, .playing)
        XCTAssertEqual(resumedState.score, 100)
        XCTAssertEqual(resumedState.distance, 50.0)
        XCTAssertEqual(resumedState.timeElapsed, 30.0)
        XCTAssertEqual(resumedState.coinsCollected, 5)
    }
    
    func testResumeTransitionFromInvalidState() {
        let playingState = GameState(
            mode: .freePlay,
            status: .playing,
            score: 100,
            distance: 50.0,
            timeElapsed: 30.0,
            coinsCollected: 5,
            environmentType: "standard"
        )
        
        let attemptedResume = playingState.resume()
        XCTAssertEqual(attemptedResume, playingState) // Should remain unchanged
    }
    
    func testEndTransition() {
        let playingState = GameState(
            mode: .freePlay,
            status: .playing,
            score: 100,
            distance: 50.0,
            timeElapsed: 30.0,
            coinsCollected: 5,
            environmentType: "standard",
            startTime: Date()
        )
        
        let endedState = playingState.end()
        
        XCTAssertEqual(endedState.status, .ended)
        XCTAssertEqual(endedState.score, 100)
        XCTAssertEqual(endedState.distance, 50.0)
        XCTAssertEqual(endedState.timeElapsed, 30.0)
        XCTAssertEqual(endedState.coinsCollected, 5)
        XCTAssertNotNil(endedState.endTime)
    }
    
    func testEndTransitionFromPausedState() {
        let pausedState = GameState(
            mode: .freePlay,
            status: .paused,
            score: 100,
            distance: 50.0,
            timeElapsed: 30.0,
            coinsCollected: 5,
            environmentType: "standard",
            startTime: Date()
        )
        
        let endedState = pausedState.end()
        XCTAssertEqual(endedState.status, .ended)
        XCTAssertNotNil(endedState.endTime)
    }
    
    func testEndTransitionFromInvalidState() {
        let notStartedState = GameState.initial
        let attemptedEnd = notStartedState.end()
        XCTAssertEqual(attemptedEnd, notStartedState) // Should remain unchanged
    }
    
    // MARK: - Game Progress Update Tests
    
    func testWithScore() {
        let playingState = GameState(
            mode: .freePlay,
            status: .playing,
            score: 100,
            distance: 50.0,
            timeElapsed: 30.0,
            coinsCollected: 5,
            environmentType: "standard"
        )
        
        let updatedState = playingState.withScore(200)
        XCTAssertEqual(updatedState.score, 200)
        XCTAssertEqual(updatedState.distance, 50.0) // Other values unchanged
    }
    
    func testWithScoreNegativeValue() {
        let playingState = GameState(
            mode: .freePlay,
            status: .playing,
            score: 100,
            distance: 50.0,
            timeElapsed: 30.0,
            coinsCollected: 5,
            environmentType: "standard"
        )
        
        let updatedState = playingState.withScore(-10)
        XCTAssertEqual(updatedState.score, 0) // Should be clamped to 0
    }
    
    func testWithScoreFromInvalidState() {
        let notStartedState = GameState.initial
        let attemptedUpdate = notStartedState.withScore(100)
        XCTAssertEqual(attemptedUpdate, notStartedState) // Should remain unchanged
    }
    
    func testAddingScore() {
        let playingState = GameState(
            mode: .freePlay,
            status: .playing,
            score: 100,
            distance: 50.0,
            timeElapsed: 30.0,
            coinsCollected: 5,
            environmentType: "standard"
        )
        
        let updatedState = playingState.addingScore(50)
        XCTAssertEqual(updatedState.score, 150)
    }
    
    func testWithDistance() {
        let playingState = GameState(
            mode: .freePlay,
            status: .playing,
            score: 100,
            distance: 50.0,
            timeElapsed: 30.0,
            coinsCollected: 5,
            environmentType: "standard"
        )
        
        let updatedState = playingState.withDistance(75.5)
        XCTAssertEqual(updatedState.distance, 75.5)
        XCTAssertEqual(updatedState.score, 100) // Other values unchanged
    }
    
    func testAddingDistance() {
        let playingState = GameState(
            mode: .freePlay,
            status: .playing,
            score: 100,
            distance: 50.0,
            timeElapsed: 30.0,
            coinsCollected: 5,
            environmentType: "standard"
        )
        
        let updatedState = playingState.addingDistance(25.5)
        XCTAssertEqual(updatedState.distance, 75.5)
    }
    
    func testWithTimeElapsed() {
        let playingState = GameState(
            mode: .freePlay,
            status: .playing,
            score: 100,
            distance: 50.0,
            timeElapsed: 30.0,
            coinsCollected: 5,
            environmentType: "standard"
        )
        
        let updatedState = playingState.withTimeElapsed(45.0)
        XCTAssertEqual(updatedState.timeElapsed, 45.0)
        XCTAssertEqual(updatedState.score, 100) // Other values unchanged
    }
    
    func testWithCoinsCollected() {
        let playingState = GameState(
            mode: .freePlay,
            status: .playing,
            score: 100,
            distance: 50.0,
            timeElapsed: 30.0,
            coinsCollected: 5,
            environmentType: "standard"
        )
        
        let updatedState = playingState.withCoinsCollected(8)
        XCTAssertEqual(updatedState.coinsCollected, 8)
        XCTAssertEqual(updatedState.score, 100) // Other values unchanged
    }
    
    func testAddingCoin() {
        let playingState = GameState(
            mode: .freePlay,
            status: .playing,
            score: 100,
            distance: 50.0,
            timeElapsed: 30.0,
            coinsCollected: 5,
            environmentType: "standard"
        )
        
        let updatedState = playingState.addingCoin()
        XCTAssertEqual(updatedState.coinsCollected, 6)
    }
    
    func testWithEnvironmentType() {
        let playingState = GameState(
            mode: .freePlay,
            status: .playing,
            score: 100,
            distance: 50.0,
            timeElapsed: 30.0,
            coinsCollected: 5,
            environmentType: "standard"
        )
        
        let updatedState = playingState.withEnvironmentType("mountain")
        XCTAssertEqual(updatedState.environmentType, "mountain")
        XCTAssertEqual(updatedState.score, 100) // Other values unchanged
    }
    
    // MARK: - Business Rules Validation Tests
    
    func testCanTransition() {
        // Valid transitions
        XCTAssertTrue(GameState.initial.canTransition(to: .playing))
        
        let playingState = GameState(
            mode: .freePlay,
            status: .playing,
            score: 0,
            distance: 0,
            timeElapsed: 0,
            coinsCollected: 0,
            environmentType: "standard"
        )
        XCTAssertTrue(playingState.canTransition(to: .paused))
        XCTAssertTrue(playingState.canTransition(to: .ended))
        
        let pausedState = playingState.pause()
        XCTAssertTrue(pausedState.canTransition(to: .playing))
        XCTAssertTrue(pausedState.canTransition(to: .ended))
        
        let endedState = playingState.end()
        XCTAssertTrue(endedState.canTransition(to: .notStarted))
        
        // Invalid transitions
        XCTAssertFalse(GameState.initial.canTransition(to: .paused))
        XCTAssertFalse(GameState.initial.canTransition(to: .ended))
        XCTAssertFalse(playingState.canTransition(to: .notStarted))
        XCTAssertFalse(pausedState.canTransition(to: .notStarted))
        XCTAssertFalse(endedState.canTransition(to: .playing))
        XCTAssertFalse(endedState.canTransition(to: .paused))
    }
    
    func testIsValid() {
        // Valid initial state
        XCTAssertTrue(GameState.initial.isValid)
        
        // Valid playing state
        let playingState = GameState(
            mode: .freePlay,
            status: .playing,
            score: 100,
            distance: 50.0,
            timeElapsed: 30.0,
            coinsCollected: 5,
            environmentType: "standard",
            startTime: Date()
        )
        XCTAssertTrue(playingState.isValid)
        
        // Valid ended state
        let endedState = playingState.end()
        XCTAssertTrue(endedState.isValid)
        
        // Invalid state - negative values (should be prevented by init)
        let invalidState = GameState(
            mode: .freePlay,
            status: .playing,
            score: -10,
            distance: 0,
            timeElapsed: 0,
            coinsCollected: 0,
            environmentType: "standard"
        )
        // Even with negative input, init should clamp to 0, making it valid
        XCTAssertTrue(invalidState.isValid)
        
        // Invalid state - playing without start time
        let invalidPlayingState = GameState(
            mode: .freePlay,
            status: .playing,
            score: 100,
            distance: 50.0,
            timeElapsed: 30.0,
            coinsCollected: 5,
            environmentType: "standard",
            startTime: nil
        )
        XCTAssertFalse(invalidPlayingState.isValid)
    }
    
    // MARK: - Equatable Tests
    
    func testEquality() {
        let state1 = GameState(
            mode: .freePlay,
            status: .playing,
            score: 100,
            distance: 50.0,
            timeElapsed: 30.0,
            coinsCollected: 5,
            environmentType: "standard"
        )
        
        let state2 = GameState(
            mode: .freePlay,
            status: .playing,
            score: 100,
            distance: 50.0,
            timeElapsed: 30.0,
            coinsCollected: 5,
            environmentType: "standard"
        )
        
        XCTAssertEqual(state1, state2)
        
        let state3 = state1.withScore(200)
        XCTAssertNotEqual(state1, state3)
    }
    
    // MARK: - Codable Tests
    
    func testCodable() throws {
        let originalState = GameState(
            mode: .challenge,
            status: .playing,
            score: 150,
            distance: 75.5,
            timeElapsed: 45.0,
            coinsCollected: 8,
            environmentType: "mountain",
            startTime: Date(),
            endTime: nil
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalState)
        
        let decoder = JSONDecoder()
        let decodedState = try decoder.decode(GameState.self, from: data)
        
        XCTAssertEqual(originalState.mode, decodedState.mode)
        XCTAssertEqual(originalState.status, decodedState.status)
        XCTAssertEqual(originalState.score, decodedState.score)
        XCTAssertEqual(originalState.distance, decodedState.distance)
        XCTAssertEqual(originalState.timeElapsed, decodedState.timeElapsed)
        XCTAssertEqual(originalState.coinsCollected, decodedState.coinsCollected)
        XCTAssertEqual(originalState.environmentType, decodedState.environmentType)
    }
    
    // MARK: - Description Tests
    
    func testDescription() {
        let gameState = GameState(
            mode: .freePlay,
            status: .playing,
            score: 100,
            distance: 50.5,
            timeElapsed: 30.0,
            coinsCollected: 5,
            environmentType: "mountain"
        )
        
        let description = gameState.description
        XCTAssertTrue(description.contains("Free Play"))
        XCTAssertTrue(description.contains("Playing"))
        XCTAssertTrue(description.contains("100"))
        XCTAssertTrue(description.contains("50.5"))
        XCTAssertTrue(description.contains("30.0"))
        XCTAssertTrue(description.contains("5"))
        XCTAssertTrue(description.contains("mountain"))
    }
}