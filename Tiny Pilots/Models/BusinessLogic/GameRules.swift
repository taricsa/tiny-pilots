//
//  GameRules.swift
//  Tiny Pilots
//
//  Created on 2025-03-01.
//

import Foundation

/// Business logic class for game rules validation and scoring
class GameRules {
    
    // MARK: - Game State Rules
    
    /// Validate if a game state transition is allowed
    /// - Parameters:
    ///   - from: Current game state status
    ///   - to: Target game state status
    ///   - playerLevel: Current player level
    /// - Returns: True if transition is valid
    static func canTransitionGameState(from: GameState.Status, to: GameState.Status, playerLevel: Int) -> Bool {
        // Use the existing GameState validation
        let dummyState = GameState(
            mode: .freePlay,
            status: from,
            score: 0,
            distance: 0,
            timeElapsed: 0,
            coinsCollected: 0,
            environmentType: "standard"
        )
        
        return dummyState.canTransition(to: to)
    }
    
    /// Check if a game mode is unlocked for the given player level
    /// - Parameters:
    ///   - mode: Game mode to check
    ///   - playerLevel: Current player level
    /// - Returns: True if mode is unlocked
    static func isGameModeUnlocked(_ mode: GameState.Mode, playerLevel: Int) -> Bool {
        switch mode {
        case .tutorial:
            return true // Always available
        case .freePlay:
            return true // Always available
        case .challenge:
            return playerLevel >= 3
        case .dailyRun:
            return playerLevel >= 5
        case .weeklySpecial:
            return playerLevel >= 10
        }
    }
    
    // MARK: - Scoring Rules
    
    /// Calculate base score from distance and time
    /// - Parameters:
    ///   - distance: Distance traveled in meters
    ///   - time: Time elapsed in seconds
    ///   - coins: Number of coins collected
    /// - Returns: Calculated base score
    static func calculateBaseScore(distance: Float, time: TimeInterval, coins: Int) -> Int {
        let distanceScore = Int(distance * 10) // 10 points per meter
        let timeBonus = Int(time / 10) // 1 point per 10 seconds
        let coinBonus = coins * 100 // 100 points per coin
        
        return distanceScore + timeBonus + coinBonus
    }
    
    /// Apply score penalty for obstacle collision
    /// - Parameters:
    ///   - currentScore: Current score before penalty
    ///   - obstacleType: Type of obstacle hit
    /// - Returns: Score after penalty applied
    static func applyObstaclePenalty(currentScore: Int, obstacleType: ObstacleType) -> Int {
        let penalty: Int
        
        switch obstacleType {
        case .building:
            penalty = 100
        case .tree:
            penalty = 75
        case .rock:
            penalty = 50
        case .fence:
            penalty = 25
        default:
            penalty = 50 // Default penalty for other obstacles
        }
        
        return max(0, currentScore - penalty)
    }
    
    /// Calculate bonus multiplier based on game mode
    /// - Parameter mode: Current game mode
    /// - Returns: Score multiplier
    static func getScoreMultiplier(for mode: GameState.Mode) -> Float {
        switch mode {
        case .tutorial:
            return 0.5 // Reduced score for tutorial
        case .freePlay:
            return 1.0 // Standard scoring
        case .challenge:
            return 1.5 // Bonus for challenge mode
        case .dailyRun:
            return 2.0 // High bonus for daily runs
        case .weeklySpecial:
            return 2.5 // Highest bonus for weekly specials
        }
    }
    
    // MARK: - Content Unlock Rules
    
    /// Check if content can be unlocked based on player progress
    /// - Parameters:
    ///   - contentId: ID of content to unlock
    ///   - type: Type of content
    ///   - playerLevel: Current player level
    ///   - totalScore: Player's total score
    ///   - completedChallenges: Number of completed challenges
    /// - Returns: True if content can be unlocked
    static func canUnlockContent(
        contentId: String,
        type: ContentType,
        playerLevel: Int,
        totalScore: Int,
        completedChallenges: Int
    ) -> Bool {
        switch type {
        case .airplane:
            return canUnlockAirplane(contentId, playerLevel: playerLevel, totalScore: totalScore)
        case .environment:
            return canUnlockEnvironment(contentId, playerLevel: playerLevel, completedChallenges: completedChallenges)
        }
    }
    
    /// Check if airplane type can be unlocked
    private static func canUnlockAirplane(_ airplaneId: String, playerLevel: Int, totalScore: Int) -> Bool {
        switch airplaneId {
        case "basic":
            return true // Always unlocked
        case "speedy":
            return playerLevel >= 3 && totalScore >= 5000
        case "sturdy":
            return playerLevel >= 5 && totalScore >= 15000
        case "glider":
            return playerLevel >= 8 && totalScore >= 30000
        default:
            return false
        }
    }
    
    /// Check if environment can be unlocked
    private static func canUnlockEnvironment(_ environmentId: String, playerLevel: Int, completedChallenges: Int) -> Bool {
        switch environmentId {
        case "standard":
            return true // Always unlocked
        case "alpine":
            return playerLevel >= 4
        case "coastal":
            return playerLevel >= 6 && completedChallenges >= 3
        case "urban":
            return playerLevel >= 8 && completedChallenges >= 8
        case "desert":
            return playerLevel >= 10 && completedChallenges >= 15
        default:
            return false
        }
    }
    
    // MARK: - Daily Run Rules
    
    /// Validate daily run streak logic
    /// - Parameters:
    ///   - lastRunDate: Date of last daily run
    ///   - currentStreak: Current streak count
    /// - Returns: New streak count
    static func calculateDailyRunStreak(lastRunDate: Date?, currentStreak: Int) -> Int {
        let calendar = Calendar.current
        
        guard let lastDate = lastRunDate else {
            return 1 // First daily run
        }
        
        if calendar.isDateInToday(lastDate) {
            return currentStreak // Already completed today
        } else if calendar.isDateInYesterday(lastDate) {
            return currentStreak + 1 // Consecutive day
        } else {
            return 1 // Streak broken, reset to 1
        }
    }
    
    /// Get daily run streak bonus multiplier
    /// - Parameter streak: Current streak count
    /// - Returns: Bonus multiplier
    static func getDailyRunStreakBonus(streak: Int) -> Float {
        switch streak {
        case 1...2:
            return 1.0
        case 3...6:
            return 1.2
        case 7...13:
            return 1.5
        case 14...29:
            return 2.0
        default:
            return 2.5 // 30+ day streak
        }
    }
    
    // MARK: - Challenge Rules
    
    /// Validate if challenge requirements are met
    /// - Parameters:
    ///   - challengeId: ID of the challenge
    ///   - score: Final score
    ///   - distance: Distance traveled
    ///   - time: Time elapsed
    ///   - coins: Coins collected
    /// - Returns: True if challenge is completed
    static func isChallengeCompleted(
        challengeId: String,
        score: Int,
        distance: Float,
        time: TimeInterval,
        coins: Int
    ) -> Bool {
        switch challengeId {
        case "distance_500":
            return distance >= 500
        case "score_5000":
            return score >= 5000
        case "time_120":
            return time >= 120
        case "coins_10":
            return coins >= 10
        case "perfect_flight":
            return score >= 3000 && distance >= 300 && coins >= 5
        default:
            return false
        }
    }
}

