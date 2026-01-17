//
//  AnalyticsEvent+Codable.swift
//  Tiny Pilots
//
//  Created by Kiro on 7/17/25.
//

import Foundation

// MARK: - AnalyticsEvent Codable Implementation

extension AnalyticsEvent {
    
    enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .gameStarted(let mode, let environment):
            try container.encode("gameStarted", forKey: .type)
            try container.encode(["mode": AnyCodable(mode.rawValue), "environment": AnyCodable(environment)], forKey: .data)
            
        case .gameCompleted(let mode, let score, let duration, let environment):
            try container.encode("gameCompleted", forKey: .type)
            try container.encode([
                "mode": AnyCodable(mode.rawValue),
                "score": AnyCodable(score),
                "duration": AnyCodable(duration),
                "environment": AnyCodable(environment)
            ], forKey: .data)
            
        case .gamePaused(let duration):
            try container.encode("gamePaused", forKey: .type)
            try container.encode(["duration": AnyCodable(duration)], forKey: .data)
            
        case .gameResumed:
            try container.encode("gameResumed", forKey: .type)
            try container.encodeNil(forKey: .data)
            
        case .gameAbandoned(let reason, let duration):
            try container.encode("gameAbandoned", forKey: .type)
            try container.encode(["reason": AnyCodable(reason), "duration": AnyCodable(duration)], forKey: .data)
            
        case .airplaneCustomized(let foldType, let colorScheme):
            try container.encode("airplaneCustomized", forKey: .type)
            try container.encode(["foldType": foldType, "colorScheme": colorScheme], forKey: .data)
            
        case .challengeShared(let challengeId):
            try container.encode("challengeShared", forKey: .type)
            try container.encode(["challengeId": challengeId], forKey: .data)
            
        case .achievementUnlocked(let achievementId):
            try container.encode("achievementUnlocked", forKey: .type)
            try container.encode(["achievementId": achievementId], forKey: .data)
            
        case .leaderboardViewed(let category):
            try container.encode("leaderboardViewed", forKey: .type)
            try container.encode(["category": category], forKey: .data)
            
        case .settingsChanged(let setting, let value):
            try container.encode("settingsChanged", forKey: .type)
            try container.encode(["setting": setting, "value": value], forKey: .data)
            
        case .gameCenterAuthenticated:
            try container.encode("gameCenterAuthenticated", forKey: .type)
            try container.encodeNil(forKey: .data)
            
        case .gameCenterAuthenticationFailed(let error):
            try container.encode("gameCenterAuthenticationFailed", forKey: .type)
            try container.encode(["error": error], forKey: .data)
            
        case .leaderboardScoreSubmitted(let category, let score):
            try container.encode("leaderboardScoreSubmitted", forKey: .type)
            try container.encode(["category": AnyCodable(category), "score": AnyCodable(score)], forKey: .data)
            
        case .achievementProgressUpdated(let achievementId, let progress):
            try container.encode("achievementProgressUpdated", forKey: .type)
            try container.encode(["achievementId": AnyCodable(achievementId), "progress": AnyCodable(progress)], forKey: .data)
            
        case .lowFrameRateDetected(let fps, let scene):
            try container.encode("lowFrameRateDetected", forKey: .type)
            try container.encode(["fps": AnyCodable(fps), "scene": AnyCodable(scene)], forKey: .data)
            
        case .highMemoryUsageDetected(let memoryMB):
            try container.encode("highMemoryUsageDetected", forKey: .type)
            try container.encode(["memoryMB": AnyCodable(memoryMB)], forKey: .data)
            
        case .slowSceneTransition(let fromScene, let toScene, let duration):
            try container.encode("slowSceneTransition", forKey: .type)
            try container.encode([
                "fromScene": AnyCodable(fromScene),
                "toScene": AnyCodable(toScene),
                "duration": AnyCodable(duration)
            ], forKey: .data)
            
        case .appLaunchCompleted(let duration):
            try container.encode("appLaunchCompleted", forKey: .type)
            try container.encode(["duration": AnyCodable(duration)], forKey: .data)
            
        case .errorOccurred(let category, let message, let isFatal):
            try container.encode("errorOccurred", forKey: .type)
            try container.encode([
                "category": AnyCodable(category),
                "message": AnyCodable(message),
                "isFatal": AnyCodable(isFatal)
            ], forKey: .data)
            
        case .crashRecovered(let context):
            try container.encode("crashRecovered", forKey: .type)
            try container.encode(["context": context], forKey: .data)
            
        case .networkConnectivityChanged(let isConnected):
            try container.encode("networkConnectivityChanged", forKey: .type)
            try container.encode(["isConnected": isConnected], forKey: .data)
            
        case .networkRequestFailed(let endpoint, let error):
            try container.encode("networkRequestFailed", forKey: .type)
            try container.encode(["endpoint": endpoint, "error": error], forKey: .data)
            
        case .offlineModeActivated:
            try container.encode("offlineModeActivated", forKey: .type)
            try container.encodeNil(forKey: .data)
            
        case .tutorialStarted:
            try container.encode("tutorialStarted", forKey: .type)
            try container.encodeNil(forKey: .data)
            
        case .tutorialCompleted(let duration):
            try container.encode("tutorialCompleted", forKey: .type)
            try container.encode(["duration": duration], forKey: .data)
            
        case .tutorialSkipped(let step):
            try container.encode("tutorialSkipped", forKey: .type)
            try container.encode(["step": step], forKey: .data)
            
        case .dailyRunStarted:
            try container.encode("dailyRunStarted", forKey: .type)
            try container.encodeNil(forKey: .data)
            
        case .weeklySpecialViewed:
            try container.encode("weeklySpecialViewed", forKey: .type)
            try container.encodeNil(forKey: .data)
            
        case .challengeCodeEntered(let isValid):
            try container.encode("challengeCodeEntered", forKey: .type)
            try container.encode(["isValid": isValid], forKey: .data)
            
        case .dailyRunGenerated(let difficulty):
            try container.encode("dailyRunGenerated", forKey: .type)
            try container.encode(["difficulty": difficulty], forKey: .data)
            
        case .dailyRunCompleted(let score):
            try container.encode("dailyRunCompleted", forKey: .type)
            try container.encode(["score": score], forKey: .data)
            
        case .privacyPolicyAccepted:
            try container.encode("privacyPolicyAccepted", forKey: .type)
            try container.encodeNil(forKey: .data)
            
        case .complianceValidation(let isCompliant):
            try container.encode("complianceValidation", forKey: .type)
            try container.encode(["isCompliant": isCompliant], forKey: .data)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "gameStarted":
            let data = try container.decode([String: String].self, forKey: .data)
            guard let modeString = data["mode"],
                  let mode = GameMode(rawValue: modeString),
                  let environment = data["environment"] else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid gameStarted data")
                )
            }
            self = .gameStarted(mode: mode, environment: environment)
            
        case "gameCompleted":
            let data = try container.decode([String: AnyCodable].self, forKey: .data)
            guard let modeString = data["mode"]?.value as? String,
                  let mode = GameMode(rawValue: modeString),
                  let score = data["score"]?.value as? Int,
                  let duration = data["duration"]?.value as? TimeInterval,
                  let environment = data["environment"]?.value as? String else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid gameCompleted data")
                )
            }
            self = .gameCompleted(mode: mode, score: score, duration: duration, environment: environment)
            
        case "gamePaused":
            let data = try container.decode([String: TimeInterval].self, forKey: .data)
            guard let duration = data["duration"] else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid gamePaused data")
                )
            }
            self = .gamePaused(duration: duration)
            
        case "gameResumed":
            self = .gameResumed
            
        case "gameAbandoned":
            let data = try container.decode([String: AnyCodable].self, forKey: .data)
            guard let reason = data["reason"]?.value as? String,
                  let duration = data["duration"]?.value as? TimeInterval else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid gameAbandoned data")
                )
            }
            self = .gameAbandoned(reason: reason, duration: duration)
            
        case "airplaneCustomized":
            let data = try container.decode([String: String].self, forKey: .data)
            guard let foldType = data["foldType"],
                  let colorScheme = data["colorScheme"] else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid airplaneCustomized data")
                )
            }
            self = .airplaneCustomized(foldType: foldType, colorScheme: colorScheme)
            
        case "challengeShared":
            let data = try container.decode([String: String].self, forKey: .data)
            guard let challengeId = data["challengeId"] else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid challengeShared data")
                )
            }
            self = .challengeShared(challengeId: challengeId)
            
        case "achievementUnlocked":
            let data = try container.decode([String: String].self, forKey: .data)
            guard let achievementId = data["achievementId"] else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid achievementUnlocked data")
                )
            }
            self = .achievementUnlocked(achievementId: achievementId)
            
        case "leaderboardViewed":
            let data = try container.decode([String: String].self, forKey: .data)
            guard let category = data["category"] else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid leaderboardViewed data")
                )
            }
            self = .leaderboardViewed(category: category)
            
        case "settingsChanged":
            let data = try container.decode([String: String].self, forKey: .data)
            guard let setting = data["setting"],
                  let value = data["value"] else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid settingsChanged data")
                )
            }
            self = .settingsChanged(setting: setting, value: value)
            
        case "gameCenterAuthenticated":
            self = .gameCenterAuthenticated
            
        case "gameCenterAuthenticationFailed":
            let data = try container.decode([String: String].self, forKey: .data)
            guard let error = data["error"] else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid gameCenterAuthenticationFailed data")
                )
            }
            self = .gameCenterAuthenticationFailed(error: error)
            
        case "leaderboardScoreSubmitted":
            let data = try container.decode([String: AnyCodable].self, forKey: .data)
            guard let category = data["category"]?.value as? String,
                  let score = data["score"]?.value as? Int else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid leaderboardScoreSubmitted data")
                )
            }
            self = .leaderboardScoreSubmitted(category: category, score: score)
            
        case "achievementProgressUpdated":
            let data = try container.decode([String: AnyCodable].self, forKey: .data)
            guard let achievementId = data["achievementId"]?.value as? String,
                  let progress = data["progress"]?.value as? Double else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid achievementProgressUpdated data")
                )
            }
            self = .achievementProgressUpdated(achievementId: achievementId, progress: progress)
            
        case "lowFrameRateDetected":
            let data = try container.decode([String: AnyCodable].self, forKey: .data)
            guard let fps = data["fps"]?.value as? Double,
                  let scene = data["scene"]?.value as? String else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid lowFrameRateDetected data")
                )
            }
            self = .lowFrameRateDetected(fps: fps, scene: scene)
            
        case "highMemoryUsageDetected":
            let data = try container.decode([String: Double].self, forKey: .data)
            guard let memoryMB = data["memoryMB"] else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid highMemoryUsageDetected data")
                )
            }
            self = .highMemoryUsageDetected(memoryMB: memoryMB)
            
        case "slowSceneTransition":
            let data = try container.decode([String: AnyCodable].self, forKey: .data)
            guard let fromScene = data["fromScene"]?.value as? String,
                  let toScene = data["toScene"]?.value as? String,
                  let duration = data["duration"]?.value as? TimeInterval else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid slowSceneTransition data")
                )
            }
            self = .slowSceneTransition(fromScene: fromScene, toScene: toScene, duration: duration)
            
        case "appLaunchCompleted":
            let data = try container.decode([String: TimeInterval].self, forKey: .data)
            guard let duration = data["duration"] else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid appLaunchCompleted data")
                )
            }
            self = .appLaunchCompleted(duration: duration)
            
        case "errorOccurred":
            let data = try container.decode([String: AnyCodable].self, forKey: .data)
            guard let category = data["category"]?.value as? String,
                  let message = data["message"]?.value as? String,
                  let isFatal = data["isFatal"]?.value as? Bool else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid errorOccurred data")
                )
            }
            self = .errorOccurred(category: category, message: message, isFatal: isFatal)
            
        case "crashRecovered":
            let data = try container.decode([String: String].self, forKey: .data)
            guard let context = data["context"] else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid crashRecovered data")
                )
            }
            self = .crashRecovered(context: context)
            
        case "networkConnectivityChanged":
            let data = try container.decode([String: Bool].self, forKey: .data)
            guard let isConnected = data["isConnected"] else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid networkConnectivityChanged data")
                )
            }
            self = .networkConnectivityChanged(isConnected: isConnected)
            
        case "networkRequestFailed":
            let data = try container.decode([String: String].self, forKey: .data)
            guard let endpoint = data["endpoint"],
                  let error = data["error"] else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid networkRequestFailed data")
                )
            }
            self = .networkRequestFailed(endpoint: endpoint, error: error)
            
        case "offlineModeActivated":
            self = .offlineModeActivated
            
        case "tutorialStarted":
            self = .tutorialStarted
            
        case "tutorialCompleted":
            let data = try container.decode([String: TimeInterval].self, forKey: .data)
            guard let duration = data["duration"] else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid tutorialCompleted data")
                )
            }
            self = .tutorialCompleted(duration: duration)
            
        case "tutorialSkipped":
            let data = try container.decode([String: String].self, forKey: .data)
            guard let step = data["step"] else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid tutorialSkipped data")
                )
            }
            self = .tutorialSkipped(step: step)
            
        case "dailyRunStarted":
            self = .dailyRunStarted
            
        case "weeklySpecialViewed":
            self = .weeklySpecialViewed
            
        case "challengeCodeEntered":
            let data = try container.decode([String: Bool].self, forKey: .data)
            guard let isValid = data["isValid"] else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid challengeCodeEntered data")
                )
            }
            self = .challengeCodeEntered(isValid: isValid)
            
        case "dailyRunGenerated":
            let data = try container.decode([String: String].self, forKey: .data)
            guard let difficulty = data["difficulty"] else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid dailyRunGenerated data")
                )
            }
            self = .dailyRunGenerated(difficulty: difficulty)
            
        case "dailyRunCompleted":
            let data = try container.decode([String: Int].self, forKey: .data)
            guard let score = data["score"] else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid dailyRunCompleted data")
                )
            }
            self = .dailyRunCompleted(score: score)
            
        case "privacyPolicyAccepted":
            self = .privacyPolicyAccepted
            
        case "complianceValidation":
            let data = try container.decode([String: Bool].self, forKey: .data)
            guard let isCompliant = data["isCompliant"] else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid complianceValidation data")
                )
            }
            self = .complianceValidation(isCompliant: isCompliant)
            
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown event type: \(type)")
            )
        }
    }
}

// MARK: - Helper Type for Mixed Value Decoding

struct AnyCodable: Codable {
    let value: Any
    
    init<T>(_ value: T?) {
        self.value = value ?? ()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if container.decodeNil() {
            value = ()
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type")
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        default:
            try container.encodeNil()
        }
    }
}