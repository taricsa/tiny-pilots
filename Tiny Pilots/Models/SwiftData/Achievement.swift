import Foundation
import SwiftData

/// SwiftData model representing a player achievement
@Model
class Achievement {
    @Attribute(.unique) var id: String
    var title: String
    var achievementDescription: String
    var isUnlocked: Bool
    var unlockedAt: Date?
    var progress: Double
    var targetValue: Double
    var category: String
    var iconName: String
    var rewardXP: Int
    
    // Relationship
    var player: PlayerData?
    
    init(
        id: String,
        title: String,
        description: String,
        targetValue: Double,
        category: String = "general",
        iconName: String = "trophy",
        rewardXP: Int = 50
    ) {
        self.id = id
        self.title = title
        self.achievementDescription = description
        self.isUnlocked = false
        self.progress = 0.0
        self.targetValue = targetValue
        self.category = category
        self.iconName = iconName
        self.rewardXP = rewardXP
    }
    
    /// Update progress towards this achievement
    /// - Parameter newProgress: The new progress value
    /// - Returns: True if the achievement was unlocked by this update
    @discardableResult
    func updateProgress(_ newProgress: Double) -> Bool {
        guard !isUnlocked else { return false }
        
        progress = min(newProgress, targetValue)
        
        if progress >= targetValue {
            unlock()
            return true
        }
        
        return false
    }
    
    /// Unlock this achievement
    private func unlock() {
        guard !isUnlocked else { return }
        
        isUnlocked = true
        unlockedAt = Date()
        progress = targetValue
        
        // Award XP to player
        player?.addExperience(rewardXP)
    }
    
    /// Get progress as a percentage (0.0 to 1.0)
    var progressPercentage: Double {
        guard targetValue > 0 else { return 0.0 }
        return min(1.0, progress / targetValue)
    }
    
    /// Get progress as a percentage string
    var progressString: String {
        let percentage = Int(progressPercentage * 100)
        return "\(percentage)%"
    }
    
    /// Check if achievement is close to completion (>= 80%)
    var isNearCompletion: Bool {
        return progressPercentage >= 0.8
    }
}

/// Achievement categories for organization
enum AchievementCategory: String, CaseIterable {
    case distance = "distance"
    case score = "score"
    case time = "time"
    case collection = "collection"
    case streak = "streak"
    case challenge = "challenge"
    case general = "general"
    
    var displayName: String {
        switch self {
        case .distance: return "Distance"
        case .score: return "Score"
        case .time: return "Time"
        case .collection: return "Collection"
        case .streak: return "Streak"
        case .challenge: return "Challenge"
        case .general: return "General"
        }
    }
}

// MARK: - Codable Support for Backup/Restore

/// Codable representation of Achievement for backup purposes
struct AchievementCodable: Codable {
    let id: String
    let title: String
    let achievementDescription: String
    let isUnlocked: Bool
    let unlockedAt: Date?
    let progress: Double
    let targetValue: Double
    let category: String
    let iconName: String
    let rewardXP: Int
    
    init(from achievement: Achievement) {
        self.id = achievement.id
        self.title = achievement.title
        self.achievementDescription = achievement.achievementDescription
        self.isUnlocked = achievement.isUnlocked
        self.unlockedAt = achievement.unlockedAt
        self.progress = achievement.progress
        self.targetValue = achievement.targetValue
        self.category = achievement.category
        self.iconName = achievement.iconName
        self.rewardXP = achievement.rewardXP
    }
    
    // Convert codable backup to SwiftData model
    @MainActor
    func toModel(in context: ModelContext, player: PlayerData) -> Achievement {
        let achievement = Achievement(
            id: id,
            title: title,
            description: achievementDescription,
            targetValue: targetValue,
            category: category,
            iconName: iconName,
            rewardXP: rewardXP
        )
        achievement.player = player
        achievement.progress = progress
        achievement.isUnlocked = isUnlocked
        achievement.unlockedAt = unlockedAt
        return achievement
    }
}