//
//  ProgressionLogic.swift
//  Tiny Pilots
//
//  Created on 2025-03-01.
//

import Foundation

/// Business logic class for player progression, XP, and level calculations
class ProgressionLogic {
    
    // MARK: - Experience and Leveling
    
    /// Calculate experience points earned from a game result
    /// - Parameters:
    ///   - score: Final score achieved
    ///   - distance: Distance traveled in meters
    ///   - timeElapsed: Time spent playing in seconds
    ///   - coinsCollected: Number of coins collected
    ///   - gameMode: Game mode played
    /// - Returns: Experience points earned
    static func calculateExperienceEarned(
        score: Int,
        distance: Float,
        timeElapsed: TimeInterval,
        coinsCollected: Int,
        gameMode: GameState.Mode
    ) -> Int {
        // Base XP calculations
        let baseXP = score / 100 // 1 XP per 100 points
        let distanceXP = Int(distance / 50) // 1 XP per 50 units of distance
        let timeXP = Int(timeElapsed / 60) // 1 XP per minute
        let coinXP = coinsCollected * 2 // 2 XP per coin
        
        let totalBaseXP = baseXP + distanceXP + timeXP + coinXP
        
        // Apply game mode multiplier
        let modeMultiplier = getExperienceMultiplier(for: gameMode)
        let finalXP = Int(Float(totalBaseXP) * modeMultiplier)
        
        // Ensure minimum XP of 1
        return max(1, finalXP)
    }
    
    /// Get experience multiplier for different game modes
    /// - Parameter gameMode: Game mode
    /// - Returns: Experience multiplier
    static func getExperienceMultiplier(for gameMode: GameState.Mode) -> Float {
        switch gameMode {
        case .tutorial:
            return 0.5 // Reduced XP for tutorial
        case .freePlay:
            return 1.0 // Standard XP
        case .challenge:
            return 1.5 // Bonus XP for challenges
        case .dailyRun:
            return 2.0 // High bonus for daily runs
        case .weeklySpecial:
            return 2.5 // Highest bonus for weekly specials
        }
    }
    
    /// Calculate player level from total experience points
    /// - Parameter totalXP: Total experience points
    /// - Returns: Player level
    static func calculateLevel(from totalXP: Int) -> Int {
        // Level formula: Level = (XP / 100) + 1
        // This means 100 XP per level
        return (totalXP / 100) + 1
    }
    
    /// Calculate experience points required for a specific level
    /// - Parameter level: Target level
    /// - Returns: Total XP required to reach that level
    static func experienceRequiredForLevel(_ level: Int) -> Int {
        // XP required = (level - 1) * 100
        return max(0, (level - 1) * 100)
    }
    
    /// Calculate experience points needed to reach next level
    /// - Parameter currentXP: Current total experience points
    /// - Returns: XP needed for next level
    static func experienceToNextLevel(currentXP: Int) -> Int {
        let currentLevel = calculateLevel(from: currentXP)
        let nextLevelXP = experienceRequiredForLevel(currentLevel + 1)
        return nextLevelXP - currentXP
    }
    
    /// Calculate progress percentage towards next level
    /// - Parameter currentXP: Current total experience points
    /// - Returns: Progress percentage (0.0 to 1.0)
    static func progressToNextLevel(currentXP: Int) -> Float {
        let currentLevel = calculateLevel(from: currentXP)
        let currentLevelXP = experienceRequiredForLevel(currentLevel)
        let nextLevelXP = experienceRequiredForLevel(currentLevel + 1)
        
        let progressXP = currentXP - currentLevelXP
        let levelXPRange = nextLevelXP - currentLevelXP
        
        guard levelXPRange > 0 else { return 1.0 }
        
        return Float(progressXP) / Float(levelXPRange)
    }
    
    // MARK: - Content Unlocking
    
    /// Check what content is unlocked at a specific level
    /// - Parameter level: Player level
    /// - Returns: Array of unlocked content IDs
    static func getUnlockedContentAtLevel(_ level: Int) -> [String] {
        var unlockedContent: [String] = []
        
        // Airplane unlocks
        if level >= 1 { unlockedContent.append("airplane_basic") }
        if level >= 3 { unlockedContent.append("airplane_speedy") }
        if level >= 5 { unlockedContent.append("airplane_sturdy") }
        if level >= 8 { unlockedContent.append("airplane_glider") }
        
        // Fold type unlocks
        if level >= 1 { unlockedContent.append("fold_basic") }
        if level >= 3 { unlockedContent.append("fold_dart") }
        if level >= 5 { unlockedContent.append("fold_glider") }
        if level >= 8 { unlockedContent.append("fold_stunt") }
        if level >= 12 { unlockedContent.append("fold_fighter") }
        
        // Design unlocks
        if level >= 1 { unlockedContent.append("design_plain") }
        if level >= 2 { unlockedContent.append("design_striped") }
        if level >= 4 { unlockedContent.append("design_dotted") }
        if level >= 7 { unlockedContent.append("design_camouflage") }
        if level >= 10 { unlockedContent.append("design_flames") }
        if level >= 15 { unlockedContent.append("design_rainbow") }
        
        // Environment unlocks
        if level >= 1 { unlockedContent.append("environment_standard") }
        if level >= 4 { unlockedContent.append("environment_alpine") }
        if level >= 6 { unlockedContent.append("environment_coastal") }
        if level >= 8 { unlockedContent.append("environment_urban") }
        if level >= 10 { unlockedContent.append("environment_desert") }
        
        return unlockedContent
    }
    
    /// Get newly unlocked content when leveling up
    /// - Parameters:
    ///   - fromLevel: Previous level
    ///   - toLevel: New level
    /// - Returns: Array of newly unlocked content IDs
    static func getNewlyUnlockedContent(fromLevel: Int, toLevel: Int) -> [String] {
        let previousContent = Set(getUnlockedContentAtLevel(fromLevel))
        let currentContent = Set(getUnlockedContentAtLevel(toLevel))
        
        return Array(currentContent.subtracting(previousContent))
    }
    
    // MARK: - Achievement Progress
    
    /// Update achievement progress based on game result
    /// - Parameters:
    ///   - achievements: Current achievements (SwiftData models)
    ///   - score: Final score achieved
    ///   - distance: Distance traveled
    ///   - timeElapsed: Time elapsed
    ///   - coinsCollected: Coins collected
    /// - Returns: Updated achievements with progress
    static func updateAchievementProgress(
        achievements: [Achievement],
        score: Int,
        distance: Float,
        timeElapsed: TimeInterval,
        coinsCollected: Int
    ) -> [Achievement] {
        var updatedAchievements = achievements
        
        for i in 0..<updatedAchievements.count {
            let achievement = updatedAchievements[i]
            
            // Skip already unlocked achievements
            guard !achievement.isUnlocked else { continue }
            
            // Update progress based on achievement type
            let newProgress = calculateAchievementProgress(
                achievementId: achievement.id,
                currentProgress: achievement.progress,
                score: score,
                distance: distance,
                timeElapsed: timeElapsed,
                coinsCollected: coinsCollected
            )
            
            if newProgress > achievement.progress {
                updatedAchievements[i].updateProgress(newProgress)
            }
        }
        
        return updatedAchievements
    }
    
    /// Calculate achievement progress for a specific achievement
    /// - Parameters:
    ///   - achievementId: ID of the achievement
    ///   - currentProgress: Current progress value
    ///   - score: Game score
    ///   - distance: Distance traveled
    ///   - timeElapsed: Time elapsed
    ///   - coinsCollected: Coins collected
    /// - Returns: New progress value
    private static func calculateAchievementProgress(
        achievementId: String,
        currentProgress: Double,
        score: Int,
        distance: Float,
        timeElapsed: TimeInterval,
        coinsCollected: Int
    ) -> Double {
        switch achievementId {
        case "distance_master":
            return Double(distance)
        case "score_champion":
            return Double(score)
        case "time_pilot":
            return timeElapsed
        case "coin_collector":
            return Double(coinsCollected)
        case "speed_demon":
            // Calculate average speed
            let avgSpeed = timeElapsed > 0 ? Double(distance) / timeElapsed : 0
            return avgSpeed
        default:
            return currentProgress
        }
    }
    
    // MARK: - Streak Bonuses
    
    /// Calculate daily run streak bonus
    /// - Parameter streakDays: Number of consecutive days
    /// - Returns: Bonus multiplier
    static func calculateStreakBonus(streakDays: Int) -> Float {
        switch streakDays {
        case 1...2:
            return 1.0 // No bonus for first 2 days
        case 3...6:
            return 1.2 // 20% bonus
        case 7...13:
            return 1.5 // 50% bonus
        case 14...29:
            return 2.0 // 100% bonus
        default:
            return 2.5 // 150% bonus for 30+ days
        }
    }
    
    /// Calculate weekly special completion bonus
    /// - Parameter completionPercentage: Percentage of weekly special completed (0.0 to 1.0)
    /// - Returns: Bonus XP amount
    static func calculateWeeklySpecialBonus(completionPercentage: Float) -> Int {
        let baseBonus = 500 // Base bonus XP
        return Int(Float(baseBonus) * completionPercentage)
    }
    
    // MARK: - Leaderboard Ranking
    
    /// Calculate leaderboard rank based on score
    /// - Parameters:
    ///   - playerScore: Player's score
    ///   - allScores: All scores in leaderboard
    /// - Returns: Player's rank (1-based)
    static func calculateLeaderboardRank(playerScore: Int, allScores: [Int]) -> Int {
        let betterScores = allScores.filter { $0 > playerScore }
        return betterScores.count + 1
    }
    
    /// Calculate percentile ranking
    /// - Parameters:
    ///   - playerScore: Player's score
    ///   - allScores: All scores in leaderboard
    /// - Returns: Percentile (0.0 to 100.0)
    static func calculatePercentileRank(playerScore: Int, allScores: [Int]) -> Float {
        guard !allScores.isEmpty else { return 0.0 }
        
        let worseScores = allScores.filter { $0 < playerScore }
        return (Float(worseScores.count) / Float(allScores.count)) * 100.0
    }
    
    // MARK: - Difficulty Scaling
    
    /// Calculate difficulty multiplier based on player level
    /// - Parameter playerLevel: Current player level
    /// - Returns: Difficulty multiplier for challenges
    static func getDifficultyMultiplier(playerLevel: Int) -> Float {
        // Gradually increase difficulty as player levels up
        let baseMultiplier: Float = 1.0
        let levelBonus = Float(playerLevel - 1) * 0.1 // 10% increase per level
        
        return min(3.0, baseMultiplier + levelBonus) // Cap at 3x difficulty
    }
    
    /// Calculate recommended challenge level for player
    /// - Parameters:
    ///   - playerLevel: Current player level
    ///   - recentPerformance: Average score from recent games
    /// - Returns: Recommended challenge difficulty (1-10)
    static func getRecommendedChallengeLevel(
        playerLevel: Int,
        recentPerformance: Int
    ) -> Int {
        // Base challenge level on player level
        var challengeLevel = min(10, max(1, playerLevel / 2))
        
        // Adjust based on recent performance
        if recentPerformance > 5000 {
            challengeLevel = min(10, challengeLevel + 1)
        } else if recentPerformance < 2000 {
            challengeLevel = max(1, challengeLevel - 1)
        }
        
        return challengeLevel
    }
}

