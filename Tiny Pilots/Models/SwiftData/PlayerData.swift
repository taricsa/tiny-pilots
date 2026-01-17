import Foundation
import SwiftData

/// SwiftData model representing player data and progress
@Model
class PlayerData {
    @Attribute(.unique) var id: UUID
    var level: Int
    var experiencePoints: Int
    var totalScore: Int
    var totalDistance: Float
    var totalFlightTime: TimeInterval
    var dailyRunStreak: Int
    var lastDailyRunDate: Date?
    var unlockedAirplanes: [String]
    var unlockedEnvironments: [String]
    var completedChallenges: Int
    var selectedFoldType: String
    var selectedDesignType: String
    var highScore: Int
    var createdAt: Date
    var lastPlayedAt: Date
    
    // Relationships
    @Relationship(deleteRule: .cascade) var gameResults: [GameResult]
    @Relationship(deleteRule: .cascade) var achievements: [Achievement]
    
    init(
        id: UUID = UUID(),
        level: Int = 1,
        experiencePoints: Int = 0,
        totalScore: Int = 0,
        totalDistance: Float = 0,
        totalFlightTime: TimeInterval = 0,
        dailyRunStreak: Int = 0,
        lastDailyRunDate: Date? = nil,
        unlockedAirplanes: [String] = ["basic"],
        unlockedEnvironments: [String] = ["standard"],
        completedChallenges: Int = 0,
        selectedFoldType: String = "basic",
        selectedDesignType: String = "plain",
        highScore: Int = 0
    ) {
        self.id = id
        self.level = level
        self.experiencePoints = experiencePoints
        self.totalScore = totalScore
        self.totalDistance = totalDistance
        self.totalFlightTime = totalFlightTime
        self.dailyRunStreak = dailyRunStreak
        self.lastDailyRunDate = lastDailyRunDate
        self.unlockedAirplanes = unlockedAirplanes
        self.unlockedEnvironments = unlockedEnvironments
        self.completedChallenges = completedChallenges
        self.selectedFoldType = selectedFoldType
        self.selectedDesignType = selectedDesignType
        self.highScore = highScore
        self.createdAt = Date()
        self.lastPlayedAt = Date()
        self.gameResults = []
        self.achievements = []
    }
    
    /// Add experience points and handle level progression with validation
    func addExperience(_ points: Int) {
        guard points >= 0 else { return } // Validate non-negative points
        
        experiencePoints += points
        
        // Check for level up (100 XP per level)
        let newLevel = (experiencePoints / 100) + 1
        if newLevel > level && newLevel <= 999 { // Validate level cap
            level = newLevel
        }
        
        lastPlayedAt = Date()
    }
    
    /// Set level with validation
    func setLevel(_ newLevel: Int) -> Bool {
        guard newLevel >= 1 && newLevel <= 999 else { return false }
        level = newLevel
        lastPlayedAt = Date()
        return true
    }
    
    /// Set experience points with validation
    func setExperiencePoints(_ points: Int) -> Bool {
        guard points >= 0 else { return false }
        experiencePoints = points
        lastPlayedAt = Date()
        return true
    }
    
    /// Add to total score with validation
    func addToTotalScore(_ points: Int) -> Bool {
        guard points >= 0 else { return false }
        totalScore += points
        lastPlayedAt = Date()
        return true
    }
    
    /// Add to total distance with validation
    func addToTotalDistance(_ distance: Float) -> Bool {
        guard distance >= 0 else { return false }
        totalDistance += distance
        lastPlayedAt = Date()
        return true
    }
    
    /// Add to total flight time with validation
    func addToTotalFlightTime(_ time: TimeInterval) -> Bool {
        guard time >= 0 else { return false }
        totalFlightTime += time
        lastPlayedAt = Date()
        return true
    }
    
    /// Set high score with validation
    func setHighScore(_ score: Int) -> Bool {
        guard score >= 0 else { return false }
        highScore = max(highScore, score) // Only update if higher
        lastPlayedAt = Date()
        return true
    }
    
    /// Unlock new content
    func unlockContent(_ contentId: String, type: ContentType) {
        switch type {
        case .airplane:
            if !unlockedAirplanes.contains(contentId) {
                unlockedAirplanes.append(contentId)
            }
        case .environment:
            if !unlockedEnvironments.contains(contentId) {
                unlockedEnvironments.append(contentId)
            }
        }
        lastPlayedAt = Date()
    }
    
    /// Update daily run streak
    func updateDailyRunStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastDate = lastDailyRunDate {
            let lastRunDay = Calendar.current.startOfDay(for: lastDate)
            let daysBetween = Calendar.current.dateComponents([.day], from: lastRunDay, to: today).day ?? 0
            
            if daysBetween == 1 {
                // Consecutive day
                dailyRunStreak += 1
            } else if daysBetween > 1 {
                // Streak broken
                dailyRunStreak = 1
            }
            // If daysBetween == 0, already played today, don't update
        } else {
            // First daily run
            dailyRunStreak = 1
        }
        
        lastDailyRunDate = today
        lastPlayedAt = Date()
    }
    
    /// Check if content is unlocked
    func isContentUnlocked(_ contentId: String, type: ContentType) -> Bool {
        switch type {
        case .airplane:
            return unlockedAirplanes.contains(contentId)
        case .environment:
            return unlockedEnvironments.contains(contentId)
        }
    }
    
    // MARK: - Business Rule Validation
    
    /// Validate that selected airplane type is unlocked
    func validateSelectedAirplane(_ airplaneType: String) -> Bool {
        return unlockedAirplanes.contains(airplaneType)
    }
    
    /// Validate that selected environment is unlocked
    func validateSelectedEnvironment(_ environmentType: String) -> Bool {
        return unlockedEnvironments.contains(environmentType)
    }
    
    /// Validate fold type selection
    func validateFoldType(_ foldType: String) -> Bool {
        let validFoldTypes = ["basic", "dart", "glider", "stunt", "heavy"]
        return validFoldTypes.contains(foldType)
    }
    
    /// Validate design type selection
    func validateDesignType(_ designType: String) -> Bool {
        let validDesignTypes = ["plain", "striped", "dotted", "rainbow", "metallic"]
        return validDesignTypes.contains(designType)
    }
    
    /// Update selected airplane configuration with validation
    func updateSelectedAirplane(foldType: String, designType: String) -> Bool {
        guard validateFoldType(foldType) && validateDesignType(designType) else {
            return false
        }
        
        selectedFoldType = foldType
        selectedDesignType = designType
        lastPlayedAt = Date()
        return true
    }
    
    /// Add game result and update statistics
    func addGameResult(_ result: GameResult) {
        // Validate the result belongs to this player
        result.player = self
        gameResults.append(result)
        
        // Update statistics
        totalScore += result.score
        totalDistance += result.distance
        totalFlightTime += result.timeElapsed
        
        // Update high score if needed
        if result.score > highScore {
            highScore = result.score
        }
        
        // Add experience points
        addExperience(result.experienceEarned)
        
        lastPlayedAt = Date()
    }
    
    /// Calculate experience needed for next level
    var experienceToNextLevel: Int {
        let nextLevelXP = level * 100
        return max(0, nextLevelXP - experiencePoints)
    }
    
    /// Calculate current level progress (0.0 to 1.0)
    var levelProgress: Double {
        let currentLevelXP = (level - 1) * 100
        let nextLevelXP = level * 100
        let progressInLevel = experiencePoints - currentLevelXP
        let levelRange = nextLevelXP - currentLevelXP
        
        guard levelRange > 0 else { return 1.0 }
        return Double(progressInLevel) / Double(levelRange)
    }
    
    /// Check if player can unlock content based on level requirements
    func canUnlockContent(_ contentId: String, type: ContentType, requiredLevel: Int) -> Bool {
        return level >= requiredLevel && !isContentUnlocked(contentId, type: type)
    }
    
    /// Get player statistics summary
    var statisticsSummary: PlayerStatistics {
        return PlayerStatistics(
            level: level,
            experiencePoints: experiencePoints,
            totalScore: totalScore,
            totalDistance: totalDistance,
            totalFlightTime: totalFlightTime,
            highScore: highScore,
            gamesPlayed: gameResults.count,
            averageScore: gameResults.isEmpty ? 0 : totalScore / gameResults.count,
            averageDistance: gameResults.isEmpty ? 0 : totalDistance / Float(gameResults.count),
            dailyRunStreak: dailyRunStreak,
            completedChallenges: completedChallenges,
            unlockedContentCount: unlockedAirplanes.count + unlockedEnvironments.count,
            achievementsUnlocked: achievements.filter { $0.isUnlocked }.count
        )
    }
    
    /// Validate player data integrity
    func validateDataIntegrity() -> [String] {
        var errors: [String] = []
        
        // Check basic constraints
        if level < 1 || level > 999 {
            errors.append("Invalid level: \(level)")
        }
        
        if experiencePoints < 0 {
            errors.append("Negative experience points: \(experiencePoints)")
        }
        
        if totalScore < 0 {
            errors.append("Negative total score: \(totalScore)")
        }
        
        if totalDistance < 0 {
            errors.append("Negative total distance: \(totalDistance)")
        }
        
        if totalFlightTime < 0 {
            errors.append("Negative total flight time: \(totalFlightTime)")
        }
        
        // Check consistency between level and experience
        let expectedLevel = (experiencePoints / 100) + 1
        if level != expectedLevel {
            errors.append("Level \(level) inconsistent with experience \(experiencePoints)")
        }
        
        // Check that selected content is unlocked
        if !validateSelectedAirplane(selectedFoldType) {
            errors.append("Selected fold type '\(selectedFoldType)' is not valid")
        }
        
        if !validateDesignType(selectedDesignType) {
            errors.append("Selected design type '\(selectedDesignType)' is not valid")
        }
        
        // Check unlocked content arrays
        if unlockedAirplanes.isEmpty {
            errors.append("No unlocked airplanes - should have at least 'basic'")
        }
        
        if unlockedEnvironments.isEmpty {
            errors.append("No unlocked environments - should have at least 'standard'")
        }
        
        return errors
    }
}

/// Player statistics summary structure
struct PlayerStatistics {
    let level: Int
    let experiencePoints: Int
    let totalScore: Int
    let totalDistance: Float
    let totalFlightTime: TimeInterval
    let highScore: Int
    let gamesPlayed: Int
    let averageScore: Int
    let averageDistance: Float
    let dailyRunStreak: Int
    let completedChallenges: Int
    let unlockedContentCount: Int
    let achievementsUnlocked: Int
}

/// Types of unlockable content
enum ContentType {
    case airplane
    case environment
}

// MARK: - Codable Support for Backup/Restore

/// Codable representation of PlayerData for backup purposes
struct PlayerDataCodable: Codable {
    let id: UUID
    let level: Int
    let experiencePoints: Int
    let totalScore: Int
    let totalDistance: Float
    let totalFlightTime: TimeInterval
    let dailyRunStreak: Int
    let lastDailyRunDate: Date?
    let unlockedAirplanes: [String]
    let unlockedEnvironments: [String]
    let completedChallenges: Int
    let selectedFoldType: String
    let selectedDesignType: String
    let highScore: Int
    let createdAt: Date
    let lastPlayedAt: Date
    
    init(from playerData: PlayerData) {
        self.id = playerData.id
        self.level = playerData.level
        self.experiencePoints = playerData.experiencePoints
        self.totalScore = playerData.totalScore
        self.totalDistance = playerData.totalDistance
        self.totalFlightTime = playerData.totalFlightTime
        self.dailyRunStreak = playerData.dailyRunStreak
        self.lastDailyRunDate = playerData.lastDailyRunDate
        self.unlockedAirplanes = playerData.unlockedAirplanes
        self.unlockedEnvironments = playerData.unlockedEnvironments
        self.completedChallenges = playerData.completedChallenges
        self.selectedFoldType = playerData.selectedFoldType
        self.selectedDesignType = playerData.selectedDesignType
        self.highScore = playerData.highScore
        self.createdAt = playerData.createdAt
        self.lastPlayedAt = playerData.lastPlayedAt
    }
    
    // Convert codable backup back into SwiftData model
    @MainActor
    func toModel(in context: ModelContext) -> PlayerData {
        let player = PlayerData(
            id: id,
            level: level,
            experiencePoints: experiencePoints,
            totalScore: totalScore,
            totalDistance: totalDistance,
            totalFlightTime: totalFlightTime,
            dailyRunStreak: dailyRunStreak,
            lastDailyRunDate: lastDailyRunDate,
            unlockedAirplanes: unlockedAirplanes,
            unlockedEnvironments: unlockedEnvironments,
            completedChallenges: completedChallenges,
            selectedFoldType: selectedFoldType,
            selectedDesignType: selectedDesignType,
            highScore: highScore
        )
        player.createdAt = createdAt
        player.lastPlayedAt = lastPlayedAt
        context.insert(player)
        return player
    }
}