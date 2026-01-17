//
//  CodableTypesTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on 7/17/25.
//

import XCTest
@testable import Tiny_Pilots

final class CodableTypesTests: XCTestCase {
    
    // MARK: - GameState Tests
    
    func testGameStateEncodingDecoding() throws {
        // Given
        let originalGameState = GameState(
            mode: .freePlay,
            status: .playing,
            score: 1500,
            distance: 250.5,
            timeElapsed: 120.0,
            coinsCollected: 15,
            environmentType: "meadow",
            startTime: Date(),
            endTime: nil
        )
        
        // When
        let encodedData = try JSONEncoder().encode(originalGameState)
        let decodedGameState = try JSONDecoder().decode(GameState.self, from: encodedData)
        
        // Then
        XCTAssertEqual(originalGameState.mode, decodedGameState.mode)
        XCTAssertEqual(originalGameState.status, decodedGameState.status)
        XCTAssertEqual(originalGameState.score, decodedGameState.score)
        XCTAssertEqual(originalGameState.distance, decodedGameState.distance, accuracy: 0.01)
        XCTAssertEqual(originalGameState.timeElapsed, decodedGameState.timeElapsed, accuracy: 0.01)
        XCTAssertEqual(originalGameState.coinsCollected, decodedGameState.coinsCollected)
        XCTAssertEqual(originalGameState.environmentType, decodedGameState.environmentType)
    }
    
    // MARK: - TiltData Tests
    
    func testTiltDataEncodingDecoding() throws {
        // Given
        let originalTiltData = TiltData(x: 0.5, y: -0.3, z: 0.1)
        
        // When
        let encodedData = try JSONEncoder().encode(originalTiltData)
        let decodedTiltData = try JSONDecoder().decode(TiltData.self, from: encodedData)
        
        // Then
        XCTAssertEqual(originalTiltData.x, decodedTiltData.x, accuracy: 0.001)
        XCTAssertEqual(originalTiltData.y, decodedTiltData.y, accuracy: 0.001)
        XCTAssertEqual(originalTiltData.z, decodedTiltData.z, accuracy: 0.001)
    }
    
    func testTiltDataZeroValue() throws {
        // Given
        let zeroTiltData = TiltData.zero
        
        // When
        let encodedData = try JSONEncoder().encode(zeroTiltData)
        let decodedTiltData = try JSONDecoder().decode(TiltData.self, from: encodedData)
        
        // Then
        XCTAssertEqual(decodedTiltData.x, 0.0, accuracy: 0.001)
        XCTAssertEqual(decodedTiltData.y, 0.0, accuracy: 0.001)
        XCTAssertEqual(decodedTiltData.z, 0.0, accuracy: 0.001)
    }
    
    // MARK: - BackgroundLayer Tests
    
    func testBackgroundLayerEncodingDecoding() throws {
        // Given
        let originalLayer = BackgroundLayer(
            textureName: "clouds_background",
            scrollSpeed: 0.5,
            zPosition: -50,
            opacity: 0.8,
            tintColor: "blue",
            repeatsHorizontally: true,
            repeatsVertically: false
        )
        
        // When
        let encodedData = try JSONEncoder().encode(originalLayer)
        let decodedLayer = try JSONDecoder().decode(BackgroundLayer.self, from: encodedData)
        
        // Then
        XCTAssertEqual(originalLayer.textureName, decodedLayer.textureName)
        XCTAssertEqual(originalLayer.scrollSpeed, decodedLayer.scrollSpeed, accuracy: 0.01)
        XCTAssertEqual(originalLayer.zPosition, decodedLayer.zPosition, accuracy: 0.01)
        XCTAssertEqual(originalLayer.opacity, decodedLayer.opacity, accuracy: 0.01)
        XCTAssertEqual(originalLayer.tintColor, decodedLayer.tintColor)
        XCTAssertEqual(originalLayer.repeatsHorizontally, decodedLayer.repeatsHorizontally)
        XCTAssertEqual(originalLayer.repeatsVertically, decodedLayer.repeatsVertically)
    }
    
    func testBackgroundLayerPredefinedLayers() throws {
        // Given
        let predefinedLayers = [
            BackgroundLayer.cloudLayer,
            BackgroundLayer.mountainLayer,
            BackgroundLayer.hillLayer,
            BackgroundLayer.treeLayer
        ]
        
        // When & Then
        for layer in predefinedLayers {
            let encodedData = try JSONEncoder().encode(layer)
            let decodedLayer = try JSONDecoder().decode(BackgroundLayer.self, from: encodedData)
            
            XCTAssertEqual(layer.textureName, decodedLayer.textureName)
            XCTAssertEqual(layer.scrollSpeed, decodedLayer.scrollSpeed, accuracy: 0.01)
            XCTAssertEqual(layer.zPosition, decodedLayer.zPosition, accuracy: 0.01)
        }
    }
    
    // MARK: - WeatherConfiguration Tests
    
    func testWeatherConfigurationEncodingDecoding() throws {
        // Given
        let originalWeather = WeatherConfiguration(
            windSpeed: 0.7,
            windDirection: 45.0,
            turbulence: 0.3,
            visibility: 0.9
        )
        
        // When
        let encodedData = try JSONEncoder().encode(originalWeather)
        let decodedWeather = try JSONDecoder().decode(WeatherConfiguration.self, from: encodedData)
        
        // Then
        XCTAssertEqual(originalWeather.windSpeed, decodedWeather.windSpeed, accuracy: 0.01)
        XCTAssertEqual(originalWeather.windDirection, decodedWeather.windDirection, accuracy: 0.01)
        XCTAssertEqual(originalWeather.turbulence, decodedWeather.turbulence, accuracy: 0.01)
        XCTAssertEqual(originalWeather.visibility, decodedWeather.visibility, accuracy: 0.01)
    }
    
    // MARK: - ObstacleConfiguration Tests
    
    func testObstacleConfigurationEncodingDecoding() throws {
        // Given
        let originalObstacle = ObstacleConfiguration(
            type: "tree",
            position: CGPoint(x: 100, y: 200),
            size: CGSize(width: 50, height: 100),
            rotation: 15.0,
            properties: ["difficulty": "medium", "animated": "true"]
        )
        
        // When
        let encodedData = try JSONEncoder().encode(originalObstacle)
        let decodedObstacle = try JSONDecoder().decode(ObstacleConfiguration.self, from: encodedData)
        
        // Then
        XCTAssertEqual(originalObstacle.type, decodedObstacle.type)
        XCTAssertEqual(originalObstacle.position.x, decodedObstacle.position.x, accuracy: 0.01)
        XCTAssertEqual(originalObstacle.position.y, decodedObstacle.position.y, accuracy: 0.01)
        XCTAssertEqual(originalObstacle.size.width, decodedObstacle.size.width, accuracy: 0.01)
        XCTAssertEqual(originalObstacle.size.height, decodedObstacle.size.height, accuracy: 0.01)
        XCTAssertEqual(originalObstacle.rotation, decodedObstacle.rotation, accuracy: 0.01)
        XCTAssertEqual(originalObstacle.properties, decodedObstacle.properties)
    }
    
    // MARK: - CollectibleConfiguration Tests
    
    func testCollectibleConfigurationEncodingDecoding() throws {
        // Given
        let originalCollectible = CollectibleConfiguration(
            type: "coin",
            position: CGPoint(x: 150, y: 250),
            value: 100,
            properties: ["sparkle": "true", "sound": "coin_collect"]
        )
        
        // When
        let encodedData = try JSONEncoder().encode(originalCollectible)
        let decodedCollectible = try JSONDecoder().decode(CollectibleConfiguration.self, from: encodedData)
        
        // Then
        XCTAssertEqual(originalCollectible.type, decodedCollectible.type)
        XCTAssertEqual(originalCollectible.position.x, decodedCollectible.position.x, accuracy: 0.01)
        XCTAssertEqual(originalCollectible.position.y, decodedCollectible.position.y, accuracy: 0.01)
        XCTAssertEqual(originalCollectible.value, decodedCollectible.value)
        XCTAssertEqual(originalCollectible.properties, decodedCollectible.properties)
    }
    
    // MARK: - Challenge Tests
    
    func testChallengeEncodingDecoding() throws {
        // Given
        let challengeData = ChallengeData(
            environmentType: "meadow",
            obstacles: [
                ObstacleConfiguration(type: "tree", position: CGPoint(x: 100, y: 200))
            ],
            collectibles: [
                CollectibleConfiguration(type: "coin", position: CGPoint(x: 150, y: 250))
            ],
            weatherConditions: WeatherConfiguration(windSpeed: 0.5),
            difficulty: .medium
        )
        
        let originalChallenge = Challenge(
            title: "Test Challenge",
            description: "A test challenge for unit testing",
            courseData: challengeData,
            createdBy: "test-user",
            targetScore: 1000
        )
        
        // When
        let encodedData = try JSONEncoder().encode(originalChallenge)
        let decodedChallenge = try JSONDecoder().decode(Challenge.self, from: encodedData)
        
        // Then
        XCTAssertEqual(originalChallenge.title, decodedChallenge.title)
        XCTAssertEqual(originalChallenge.description, decodedChallenge.description)
        XCTAssertEqual(originalChallenge.createdBy, decodedChallenge.createdBy)
        XCTAssertEqual(originalChallenge.targetScore, decodedChallenge.targetScore)
        XCTAssertEqual(originalChallenge.courseData.environmentType, decodedChallenge.courseData.environmentType)
        XCTAssertEqual(originalChallenge.courseData.difficulty, decodedChallenge.courseData.difficulty)
    }
    
    // MARK: - WeeklySpecial Tests
    
    func testWeeklySpecialEncodingDecoding() throws {
        // Given
        let courseData = WeeklySpecialCourseData(
            obstacles: [
                ObstacleConfiguration(type: "building", position: CGPoint(x: 200, y: 300))
            ],
            collectibles: [
                CollectibleConfiguration(type: "star", position: CGPoint(x: 250, y: 350))
            ],
            weatherConditions: WeatherConfiguration(windSpeed: 0.8),
            specialFeatures: [
                WeeklySpecialFeature(type: .boostRing, position: CGPoint(x: 300, y: 400))
            ]
        )
        
        let rewards = WeeklySpecialRewards(
            xpReward: 500,
            bonusItems: [
                WeeklySpecialBonusItem(
                    type: .paperDesign,
                    name: "Golden Glider",
                    description: "A special golden design",
                    rarity: .rare
                )
            ]
        )
        
        let originalWeeklySpecial = WeeklySpecial(
            title: "Sky High Challenge",
            description: "Reach new heights!",
            startDate: Date(),
            endDate: Date().addingTimeInterval(604800), // 1 week
            courseData: courseData,
            rewards: rewards,
            difficulty: .hard
        )
        
        // When
        let encodedData = try JSONEncoder().encode(originalWeeklySpecial)
        let decodedWeeklySpecial = try JSONDecoder().decode(WeeklySpecial.self, from: encodedData)
        
        // Then
        XCTAssertEqual(originalWeeklySpecial.title, decodedWeeklySpecial.title)
        XCTAssertEqual(originalWeeklySpecial.description, decodedWeeklySpecial.description)
        XCTAssertEqual(originalWeeklySpecial.difficulty, decodedWeeklySpecial.difficulty)
        XCTAssertEqual(originalWeeklySpecial.rewards.xpReward, decodedWeeklySpecial.rewards.xpReward)
    }
    
    // MARK: - GameMode Tests
    
    func testGameModeEncodingDecoding() throws {
        // Given
        let gameModes: [GameMode] = [.tutorial, .freePlay, .challenge, .dailyRun, .weeklySpecial]
        
        // When & Then
        for mode in gameModes {
            let encodedData = try JSONEncoder().encode(mode)
            let decodedMode = try JSONDecoder().decode(GameMode.self, from: encodedData)
            
            XCTAssertEqual(mode, decodedMode)
            XCTAssertEqual(mode.rawValue, decodedMode.rawValue)
        }
    }
    
    // MARK: - PerformanceMetric Tests
    
    func testPerformanceMetricEncodingDecoding() throws {
        // Given
        let originalMetric = PerformanceMetric(
            name: "frame_rate",
            value: 60.0,
            unit: "fps",
            category: "performance",
            additionalInfo: ["scene": "game", "device": "iPhone"]
        )
        
        // When
        let encodedData = try JSONEncoder().encode(originalMetric)
        let decodedMetric = try JSONDecoder().decode(PerformanceMetric.self, from: encodedData)
        
        // Then
        XCTAssertEqual(originalMetric.name, decodedMetric.name)
        XCTAssertEqual(originalMetric.value, decodedMetric.value, accuracy: 0.01)
        XCTAssertEqual(originalMetric.unit, decodedMetric.unit)
        XCTAssertEqual(originalMetric.category, decodedMetric.category)
        XCTAssertEqual(originalMetric.additionalInfo, decodedMetric.additionalInfo)
    }
    
    // MARK: - AnalyticsConsentStatus Tests
    
    func testAnalyticsConsentStatusEncodingDecoding() throws {
        // Given
        let statuses: [AnalyticsConsentStatus] = [.notRequested, .granted, .denied, .expired]
        
        // When & Then
        for status in statuses {
            let encodedData = try JSONEncoder().encode(status)
            let decodedStatus = try JSONDecoder().decode(AnalyticsConsentStatus.self, from: encodedData)
            
            XCTAssertEqual(status, decodedStatus)
            XCTAssertEqual(status.rawValue, decodedStatus.rawValue)
        }
    }
}