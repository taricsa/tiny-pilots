//
//  DailyRunServiceProtocol.swift
//  Tiny Pilots
//
//  Created by Kiro on Production Readiness Implementation
//

import Foundation

/// Protocol defining daily run service functionality
protocol DailyRunServiceProtocol {
    /// Get the current daily run challenge
    /// - Parameter completion: Completion handler with daily run or error
    func getCurrentDailyRun(completion: @escaping (Result<DailyRun, Error>) -> Void)
    
    /// Submit a daily run score
    /// - Parameters:
    ///   - score: The score achieved
    ///   - completion: Completion handler with optional error
    func submitDailyRunScore(_ score: Int, completion: @escaping (Error?) -> Void)
    
    /// Get daily run leaderboard
    /// - Parameter completion: Completion handler with leaderboard entries or error
    func getDailyRunLeaderboard(completion: @escaping (Result<[DailyRunLeaderboardEntry], Error>) -> Void)
    
    /// Get player's daily run streak information
    /// - Parameter completion: Completion handler with streak info or error
    func getStreakInfo(completion: @escaping (Result<DailyRunStreak, Error>) -> Void)
    
    /// Check if player has completed today's daily run
    /// - Returns: True if completed, false otherwise
    func hasCompletedTodaysDailyRun() -> Bool
    
    /// Get daily run history for the player
    /// - Parameter completion: Completion handler with history or error
    func getDailyRunHistory(completion: @escaping (Result<[DailyRunResult], Error>) -> Void)
    
    /// Generate a shareable daily run result
    /// - Parameters:
    ///   - result: The daily run result to share
    ///   - completion: Completion handler with share data or error
    func generateShareableResult(_ result: DailyRunResult, completion: @escaping (Result<DailyRunShareData, Error>) -> Void)
    
    /// Compare player's performance with friends
    /// - Parameter completion: Completion handler with comparison data or error
    func getFriendsComparison(completion: @escaping (Result<[DailyRunFriendComparison], Error>) -> Void)
}

/// Represents a daily run challenge
struct DailyRun: Codable {
    let id: String
    let date: Date
    let seed: Int
    let challengeData: DailyRunChallengeData
    let difficulty: DailyRunDifficulty
    let rewards: DailyRunRewards
    let expiresAt: Date
}

/// Daily run challenge configuration
struct DailyRunChallengeData: Codable {
    let environmentType: String
    let obstacles: [ObstacleConfiguration]
    let collectibles: [CollectibleConfiguration]
    let weatherConditions: WeatherConfiguration
    let specialModifiers: [DailyRunModifier]
    let targetDistance: Int?
    let timeLimit: TimeInterval?
}

/// Daily run difficulty levels
enum DailyRunDifficulty: String, CaseIterable, Codable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    case extreme = "extreme"
    
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .extreme: return "Extreme"
        }
    }
    
    var scoreMultiplier: Double {
        switch self {
        case .easy: return 1.0
        case .medium: return 1.2
        case .hard: return 1.5
        case .extreme: return 2.0
        }
    }
}

/// Special modifiers for daily runs
enum DailyRunModifier: String, CaseIterable, Codable {
    case doubleCoins = "double_coins"
    case strongWind = "strong_wind"
    case foggyWeather = "foggy_weather"
    case nightMode = "night_mode"
    case speedBoost = "speed_boost"
    case fragileAirplane = "fragile_airplane"
    
    var displayName: String {
        switch self {
        case .doubleCoins: return "Double Coins"
        case .strongWind: return "Strong Wind"
        case .foggyWeather: return "Foggy Weather"
        case .nightMode: return "Night Mode"
        case .speedBoost: return "Speed Boost"
        case .fragileAirplane: return "Fragile Airplane"
        }
    }
    
    var description: String {
        switch self {
        case .doubleCoins: return "Collect twice as many coins"
        case .strongWind: return "Strong wind affects flight"
        case .foggyWeather: return "Reduced visibility"
        case .nightMode: return "Dark environment"
        case .speedBoost: return "Increased airplane speed"
        case .fragileAirplane: return "One hit ends the run"
        }
    }
}

/// Daily run rewards
struct DailyRunRewards: Codable {
    let baseCoins: Int
    let streakBonus: Int
    let difficultyBonus: Int
    let achievements: [String]
}

/// Daily run leaderboard entry
struct DailyRunLeaderboardEntry: Codable {
    let playerID: String
    let displayName: String
    let score: Int
    let rank: Int
    let completionTime: Date
    let isCurrentPlayer: Bool
}

/// Player's daily run streak information
struct DailyRunStreak: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let lastCompletionDate: Date?
    let nextRewardAt: Int
    let streakRewards: [DailyRunStreakReward]
}

/// Streak reward information
struct DailyRunStreakReward: Codable {
    let streakLength: Int
    let coins: Int
    let title: String?
    let achievement: String?
}

/// Daily run result
struct DailyRunResult: Codable {
    let id: String
    let dailyRunId: String
    let playerID: String
    let score: Int
    let distance: Double
    let coinsCollected: Int
    let completionTime: Date
    let duration: TimeInterval
    let rank: Int?
    let rewards: DailyRunRewards
}

/// Shareable daily run data
struct DailyRunShareData: Codable {
    let text: String
    let image: Data?
    let url: String?
    let hashtags: [String]
}

/// Friend comparison data
struct DailyRunFriendComparison: Codable {
    let friendID: String
    let friendName: String
    let friendScore: Int
    let playerScore: Int
    let scoreDifference: Int
    let isPlayerBetter: Bool
}

/// Daily run service errors
enum DailyRunServiceError: Error, LocalizedError {
    case noDailyRunAvailable
    case alreadyCompleted
    case networkError
    case invalidScore
    case notAuthenticated
    case dataCorrupted
    
    var errorDescription: String? {
        switch self {
        case .noDailyRunAvailable:
            return "No daily run available for today. Please try again later."
        case .alreadyCompleted:
            return "You have already completed today's daily run. Come back tomorrow!"
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .invalidScore:
            return "Invalid score submitted. Please try again."
        case .notAuthenticated:
            return "Please sign in to Game Center to participate in daily runs."
        case .dataCorrupted:
            return "Daily run data is corrupted. Please restart the app."
        }
    }
}