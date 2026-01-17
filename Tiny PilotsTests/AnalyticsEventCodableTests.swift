//
//  AnalyticsEventCodableTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on 7/17/25.
//

import XCTest
@testable import Tiny_Pilots

final class AnalyticsEventCodableTests: XCTestCase {
    
    // MARK: - Game Events Tests
    
    func testGameStartedEventEncodingDecoding() throws {
        // Given
        let originalEvent = AnalyticsEvent.gameStarted(mode: .freePlay, environment: "meadow")
        
        // When
        let encodedData = try JSONEncoder().encode(originalEvent)
        let decodedEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: encodedData)
        
        // Then
        if case let .gameStarted(mode, environment) = decodedEvent {
            XCTAssertEqual(mode, .freePlay)
            XCTAssertEqual(environment, "meadow")
        } else {
            XCTFail("Decoded event should be gameStarted")
        }
    }
    
    func testGameCompletedEventEncodingDecoding() throws {
        // Given
        let originalEvent = AnalyticsEvent.gameCompleted(
            mode: .challenge,
            score: 1500,
            duration: 120.5,
            environment: "alpine"
        )
        
        // When
        let encodedData = try JSONEncoder().encode(originalEvent)
        let decodedEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: encodedData)
        
        // Then
        if case let .gameCompleted(mode, score, duration, environment) = decodedEvent {
            XCTAssertEqual(mode, .challenge)
            XCTAssertEqual(score, 1500)
            XCTAssertEqual(duration, 120.5, accuracy: 0.01)
            XCTAssertEqual(environment, "alpine")
        } else {
            XCTFail("Decoded event should be gameCompleted")
        }
    }
    
    func testGamePausedEventEncodingDecoding() throws {
        // Given
        let originalEvent = AnalyticsEvent.gamePaused(duration: 45.0)
        
        // When
        let encodedData = try JSONEncoder().encode(originalEvent)
        let decodedEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: encodedData)
        
        // Then
        if case let .gamePaused(duration) = decodedEvent {
            XCTAssertEqual(duration, 45.0, accuracy: 0.01)
        } else {
            XCTFail("Decoded event should be gamePaused")
        }
    }
    
    func testGameResumedEventEncodingDecoding() throws {
        // Given
        let originalEvent = AnalyticsEvent.gameResumed
        
        // When
        let encodedData = try JSONEncoder().encode(originalEvent)
        let decodedEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: encodedData)
        
        // Then
        if case .gameResumed = decodedEvent {
            // Success
        } else {
            XCTFail("Decoded event should be gameResumed")
        }
    }
    
    func testGameAbandonedEventEncodingDecoding() throws {
        // Given
        let originalEvent = AnalyticsEvent.gameAbandoned(reason: "user_quit", duration: 30.0)
        
        // When
        let encodedData = try JSONEncoder().encode(originalEvent)
        let decodedEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: encodedData)
        
        // Then
        if case let .gameAbandoned(reason, duration) = decodedEvent {
            XCTAssertEqual(reason, "user_quit")
            XCTAssertEqual(duration, 30.0, accuracy: 0.01)
        } else {
            XCTFail("Decoded event should be gameAbandoned")
        }
    }
    
    // MARK: - User Interaction Events Tests
    
    func testAirplaneCustomizedEventEncodingDecoding() throws {
        // Given
        let originalEvent = AnalyticsEvent.airplaneCustomized(
            foldType: "classic",
            colorScheme: "blue"
        )
        
        // When
        let encodedData = try JSONEncoder().encode(originalEvent)
        let decodedEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: encodedData)
        
        // Then
        if case let .airplaneCustomized(foldType, colorScheme) = decodedEvent {
            XCTAssertEqual(foldType, "classic")
            XCTAssertEqual(colorScheme, "blue")
        } else {
            XCTFail("Decoded event should be airplaneCustomized")
        }
    }
    
    func testChallengeSharedEventEncodingDecoding() throws {
        // Given
        let originalEvent = AnalyticsEvent.challengeShared(challengeId: "challenge_123")
        
        // When
        let encodedData = try JSONEncoder().encode(originalEvent)
        let decodedEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: encodedData)
        
        // Then
        if case let .challengeShared(challengeId) = decodedEvent {
            XCTAssertEqual(challengeId, "challenge_123")
        } else {
            XCTFail("Decoded event should be challengeShared")
        }
    }
    
    func testAchievementUnlockedEventEncodingDecoding() throws {
        // Given
        let originalEvent = AnalyticsEvent.achievementUnlocked(achievementId: "first_flight")
        
        // When
        let encodedData = try JSONEncoder().encode(originalEvent)
        let decodedEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: encodedData)
        
        // Then
        if case let .achievementUnlocked(achievementId) = decodedEvent {
            XCTAssertEqual(achievementId, "first_flight")
        } else {
            XCTFail("Decoded event should be achievementUnlocked")
        }
    }
    
    func testSettingsChangedEventEncodingDecoding() throws {
        // Given
        let originalEvent = AnalyticsEvent.settingsChanged(setting: "music_volume", value: "0.8")
        
        // When
        let encodedData = try JSONEncoder().encode(originalEvent)
        let decodedEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: encodedData)
        
        // Then
        if case let .settingsChanged(setting, value) = decodedEvent {
            XCTAssertEqual(setting, "music_volume")
            XCTAssertEqual(value, "0.8")
        } else {
            XCTFail("Decoded event should be settingsChanged")
        }
    }
    
    // MARK: - Game Center Events Tests
    
    func testGameCenterAuthenticatedEventEncodingDecoding() throws {
        // Given
        let originalEvent = AnalyticsEvent.gameCenterAuthenticated
        
        // When
        let encodedData = try JSONEncoder().encode(originalEvent)
        let decodedEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: encodedData)
        
        // Then
        if case .gameCenterAuthenticated = decodedEvent {
            // Success
        } else {
            XCTFail("Decoded event should be gameCenterAuthenticated")
        }
    }
    
    func testGameCenterAuthenticationFailedEventEncodingDecoding() throws {
        // Given
        let originalEvent = AnalyticsEvent.gameCenterAuthenticationFailed(error: "network_error")
        
        // When
        let encodedData = try JSONEncoder().encode(originalEvent)
        let decodedEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: encodedData)
        
        // Then
        if case let .gameCenterAuthenticationFailed(error) = decodedEvent {
            XCTAssertEqual(error, "network_error")
        } else {
            XCTFail("Decoded event should be gameCenterAuthenticationFailed")
        }
    }
    
    func testLeaderboardScoreSubmittedEventEncodingDecoding() throws {
        // Given
        let originalEvent = AnalyticsEvent.leaderboardScoreSubmitted(category: "high_score", score: 2500)
        
        // When
        let encodedData = try JSONEncoder().encode(originalEvent)
        let decodedEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: encodedData)
        
        // Then
        if case let .leaderboardScoreSubmitted(category, score) = decodedEvent {
            XCTAssertEqual(category, "high_score")
            XCTAssertEqual(score, 2500)
        } else {
            XCTFail("Decoded event should be leaderboardScoreSubmitted")
        }
    }
    
    // MARK: - Performance Events Tests
    
    func testLowFrameRateDetectedEventEncodingDecoding() throws {
        // Given
        let originalEvent = AnalyticsEvent.lowFrameRateDetected(fps: 25.5, scene: "game_scene")
        
        // When
        let encodedData = try JSONEncoder().encode(originalEvent)
        let decodedEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: encodedData)
        
        // Then
        if case let .lowFrameRateDetected(fps, scene) = decodedEvent {
            XCTAssertEqual(fps, 25.5, accuracy: 0.01)
            XCTAssertEqual(scene, "game_scene")
        } else {
            XCTFail("Decoded event should be lowFrameRateDetected")
        }
    }
    
    func testHighMemoryUsageDetectedEventEncodingDecoding() throws {
        // Given
        let originalEvent = AnalyticsEvent.highMemoryUsageDetected(memoryMB: 512.0)
        
        // When
        let encodedData = try JSONEncoder().encode(originalEvent)
        let decodedEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: encodedData)
        
        // Then
        if case let .highMemoryUsageDetected(memoryMB) = decodedEvent {
            XCTAssertEqual(memoryMB, 512.0, accuracy: 0.01)
        } else {
            XCTFail("Decoded event should be highMemoryUsageDetected")
        }
    }
    
    func testSlowSceneTransitionEventEncodingDecoding() throws {
        // Given
        let originalEvent = AnalyticsEvent.slowSceneTransition(
            fromScene: "menu",
            toScene: "game",
            duration: 2.5
        )
        
        // When
        let encodedData = try JSONEncoder().encode(originalEvent)
        let decodedEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: encodedData)
        
        // Then
        if case let .slowSceneTransition(fromScene, toScene, duration) = decodedEvent {
            XCTAssertEqual(fromScene, "menu")
            XCTAssertEqual(toScene, "game")
            XCTAssertEqual(duration, 2.5, accuracy: 0.01)
        } else {
            XCTFail("Decoded event should be slowSceneTransition")
        }
    }
    
    // MARK: - Error Events Tests
    
    func testErrorOccurredEventEncodingDecoding() throws {
        // Given
        let originalEvent = AnalyticsEvent.errorOccurred(
            category: "network",
            message: "Connection timeout",
            isFatal: false
        )
        
        // When
        let encodedData = try JSONEncoder().encode(originalEvent)
        let decodedEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: encodedData)
        
        // Then
        if case let .errorOccurred(category, message, isFatal) = decodedEvent {
            XCTAssertEqual(category, "network")
            XCTAssertEqual(message, "Connection timeout")
            XCTAssertEqual(isFatal, false)
        } else {
            XCTFail("Decoded event should be errorOccurred")
        }
    }
    
    // MARK: - Feature Usage Events Tests
    
    func testTutorialCompletedEventEncodingDecoding() throws {
        // Given
        let originalEvent = AnalyticsEvent.tutorialCompleted(duration: 180.0)
        
        // When
        let encodedData = try JSONEncoder().encode(originalEvent)
        let decodedEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: encodedData)
        
        // Then
        if case let .tutorialCompleted(duration) = decodedEvent {
            XCTAssertEqual(duration, 180.0, accuracy: 0.01)
        } else {
            XCTFail("Decoded event should be tutorialCompleted")
        }
    }
    
    func testTutorialSkippedEventEncodingDecoding() throws {
        // Given
        let originalEvent = AnalyticsEvent.tutorialSkipped(step: "basic_controls")
        
        // When
        let encodedData = try JSONEncoder().encode(originalEvent)
        let decodedEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: encodedData)
        
        // Then
        if case let .tutorialSkipped(step) = decodedEvent {
            XCTAssertEqual(step, "basic_controls")
        } else {
            XCTFail("Decoded event should be tutorialSkipped")
        }
    }
    
    func testChallengeCodeEnteredEventEncodingDecoding() throws {
        // Given
        let originalEvent = AnalyticsEvent.challengeCodeEntered(isValid: true)
        
        // When
        let encodedData = try JSONEncoder().encode(originalEvent)
        let decodedEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: encodedData)
        
        // Then
        if case let .challengeCodeEntered(isValid) = decodedEvent {
            XCTAssertEqual(isValid, true)
        } else {
            XCTFail("Decoded event should be challengeCodeEntered")
        }
    }
    
    func testDailyRunCompletedEventEncodingDecoding() throws {
        // Given
        let originalEvent = AnalyticsEvent.dailyRunCompleted(score: 3000)
        
        // When
        let encodedData = try JSONEncoder().encode(originalEvent)
        let decodedEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: encodedData)
        
        // Then
        if case let .dailyRunCompleted(score) = decodedEvent {
            XCTAssertEqual(score, 3000)
        } else {
            XCTFail("Decoded event should be dailyRunCompleted")
        }
    }
    
    // MARK: - Privacy & Compliance Events Tests
    
    func testPrivacyPolicyAcceptedEventEncodingDecoding() throws {
        // Given
        let originalEvent = AnalyticsEvent.privacyPolicyAccepted
        
        // When
        let encodedData = try JSONEncoder().encode(originalEvent)
        let decodedEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: encodedData)
        
        // Then
        if case .privacyPolicyAccepted = decodedEvent {
            // Success
        } else {
            XCTFail("Decoded event should be privacyPolicyAccepted")
        }
    }
    
    func testComplianceValidationEventEncodingDecoding() throws {
        // Given
        let originalEvent = AnalyticsEvent.complianceValidation(isCompliant: true)
        
        // When
        let encodedData = try JSONEncoder().encode(originalEvent)
        let decodedEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: encodedData)
        
        // Then
        if case let .complianceValidation(isCompliant) = decodedEvent {
            XCTAssertEqual(isCompliant, true)
        } else {
            XCTFail("Decoded event should be complianceValidation")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidEventTypeDecoding() throws {
        // Given
        let invalidJSON = """
        {
            "type": "unknownEventType",
            "data": null
        }
        """.data(using: .utf8)!
        
        // When & Then
        XCTAssertThrowsError(try JSONDecoder().decode(AnalyticsEvent.self, from: invalidJSON)) { error in
            if case DecodingError.dataCorrupted(let context) = error {
                XCTAssertTrue(context.debugDescription.contains("Unknown event type"))
            } else {
                XCTFail("Expected dataCorrupted error")
            }
        }
    }
    
    func testInvalidEventDataDecoding() throws {
        // Given
        let invalidJSON = """
        {
            "type": "gameStarted",
            "data": {
                "invalidField": "value"
            }
        }
        """.data(using: .utf8)!
        
        // When & Then
        XCTAssertThrowsError(try JSONDecoder().decode(AnalyticsEvent.self, from: invalidJSON)) { error in
            if case DecodingError.dataCorrupted(let context) = error {
                XCTAssertTrue(context.debugDescription.contains("Invalid gameStarted data"))
            } else {
                XCTFail("Expected dataCorrupted error")
            }
        }
    }
    
    // MARK: - JSON Structure Tests
    
    func testEventJSONStructure() throws {
        // Given
        let event = AnalyticsEvent.gameStarted(mode: .freePlay, environment: "meadow")
        
        // When
        let encodedData = try JSONEncoder().encode(event)
        let jsonObject = try JSONSerialization.jsonObject(with: encodedData) as? [String: Any]
        
        // Then
        XCTAssertNotNil(jsonObject)
        XCTAssertEqual(jsonObject?["type"] as? String, "gameStarted")
        
        let data = jsonObject?["data"] as? [String: String]
        XCTAssertNotNil(data)
        XCTAssertEqual(data?["mode"], "free_play")
        XCTAssertEqual(data?["environment"], "meadow")
    }
}