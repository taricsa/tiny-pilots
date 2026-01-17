import Foundation
import CoreGraphics

/// Represents a weekly special challenge with unique content and rewards
struct WeeklySpecial: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let startDate: Date
    let endDate: Date
    let courseData: WeeklySpecialCourseData
    let rewards: WeeklySpecialRewards
    let difficulty: ChallengeDifficulty
    let targetDistance: Int
    let environment: String
    let windCondition: String
    let createdAt: Date
    let version: Int
    
    /// Initialize a new weekly special
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        startDate: Date,
        endDate: Date,
        courseData: WeeklySpecialCourseData,
        rewards: WeeklySpecialRewards,
        difficulty: ChallengeDifficulty = .medium,
        targetDistance: Int = 1000,
        environment: String = "Sunny Meadows",
        windCondition: String = "Light Breeze",
        version: Int = 1
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.courseData = courseData
        self.rewards = rewards
        self.difficulty = difficulty
        self.targetDistance = targetDistance
        self.environment = environment
        self.windCondition = windCondition
        self.createdAt = Date()
        self.version = version
    }
    
    /// Check if the weekly special is currently active
    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }
    
    /// Check if the weekly special has expired
    var isExpired: Bool {
        return Date() > endDate
    }
    
    /// Get the remaining time until expiration
    var timeUntilExpiration: TimeInterval {
        return endDate.timeIntervalSinceNow
    }
    
    /// Get the time until the weekly special starts
    var timeUntilStart: TimeInterval {
        return startDate.timeIntervalSinceNow
    }
    
    /// Get a formatted date range string
    var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        let startString = formatter.string(from: startDate)
        let endString = formatter.string(from: endDate)
        
        return "\(startString) - \(endString)"
    }
    
    /// Get XP reward amount
    var xpReward: Int {
        return rewards.xpReward
    }
    
    /// Convert to Challenge for gameplay
    func toChallenge() -> Challenge {
        let challengeData = ChallengeData(
            environmentType: environment,
            obstacles: courseData.obstacles,
            collectibles: courseData.collectibles,
            weatherConditions: courseData.weatherConditions,
            difficulty: difficulty,
            estimatedDuration: courseData.estimatedDuration
        )
        
        return Challenge(
            id: id,
            title: title,
            description: description,
            courseData: challengeData,
            expirationDate: endDate,
            createdBy: "Tiny Pilots Team",
            targetScore: targetDistance
        )
    }
}

/// Course data specific to weekly specials
struct WeeklySpecialCourseData: Codable {
    let obstacles: [ObstacleConfiguration]
    let collectibles: [CollectibleConfiguration]
    let weatherConditions: WeatherConfiguration
    let specialFeatures: [WeeklySpecialFeature]
    let estimatedDuration: TimeInterval
    let courseLayout: WeeklySpecialLayout
    
    init(
        obstacles: [ObstacleConfiguration] = [],
        collectibles: [CollectibleConfiguration] = [],
        weatherConditions: WeatherConfiguration = WeatherConfiguration(),
        specialFeatures: [WeeklySpecialFeature] = [],
        estimatedDuration: TimeInterval = 180, // 3 minutes default
        courseLayout: WeeklySpecialLayout = WeeklySpecialLayout()
    ) {
        self.obstacles = obstacles
        self.collectibles = collectibles
        self.weatherConditions = weatherConditions
        self.specialFeatures = specialFeatures
        self.estimatedDuration = estimatedDuration
        self.courseLayout = courseLayout
    }
}

/// Special features unique to weekly specials
struct WeeklySpecialFeature: Codable {
    let type: WeeklySpecialFeatureType
    let position: CGPoint
    let properties: [String: String]
    let isActive: Bool
    
    init(
        type: WeeklySpecialFeatureType,
        position: CGPoint,
        properties: [String: String] = [:],
        isActive: Bool = true
    ) {
        self.type = type
        self.position = position
        self.properties = properties
        self.isActive = isActive
    }
}

/// Types of special features in weekly specials
enum WeeklySpecialFeatureType: String, Codable, CaseIterable {
    case boostRing = "boost_ring"
    case windTunnel = "wind_tunnel"
    case scoreMultiplier = "score_multiplier"
    case timeBonus = "time_bonus"
    case secretPath = "secret_path"
    case movingPlatform = "moving_platform"
    
    var displayName: String {
        switch self {
        case .boostRing: return "Boost Ring"
        case .windTunnel: return "Wind Tunnel"
        case .scoreMultiplier: return "Score Multiplier"
        case .timeBonus: return "Time Bonus"
        case .secretPath: return "Secret Path"
        case .movingPlatform: return "Moving Platform"
        }
    }
}

/// Layout configuration for weekly special courses
struct WeeklySpecialLayout: Codable {
    let theme: String
    let backgroundElements: [String]
    let musicTrack: String
    let ambientSounds: [String]
    let visualEffects: [String]
    
    init(
        theme: String = "default",
        backgroundElements: [String] = [],
        musicTrack: String = "default_theme",
        ambientSounds: [String] = [],
        visualEffects: [String] = []
    ) {
        self.theme = theme
        self.backgroundElements = backgroundElements
        self.musicTrack = musicTrack
        self.ambientSounds = ambientSounds
        self.visualEffects = visualEffects
    }
}

/// Rewards for completing weekly specials
struct WeeklySpecialRewards: Codable {
    let xpReward: Int
    let bonusItems: [WeeklySpecialBonusItem]
    let achievements: [String]
    let unlockables: [String]
    
    init(
        xpReward: Int = 500,
        bonusItems: [WeeklySpecialBonusItem] = [],
        achievements: [String] = [],
        unlockables: [String] = []
    ) {
        self.xpReward = xpReward
        self.bonusItems = bonusItems
        self.achievements = achievements
        self.unlockables = unlockables
    }
}

/// Bonus items that can be earned from weekly specials
struct WeeklySpecialBonusItem: Codable {
    let type: BonusItemType
    let name: String
    let description: String
    let rarity: BonusItemRarity
    let iconName: String
    
    init(
        type: BonusItemType,
        name: String,
        description: String,
        rarity: BonusItemRarity = .common,
        iconName: String = "gift.fill"
    ) {
        self.type = type
        self.name = name
        self.description = description
        self.rarity = rarity
        self.iconName = iconName
    }
}

/// Types of bonus items
enum BonusItemType: String, Codable, CaseIterable {
    case paperDesign = "paper_design"
    case trailEffect = "trail_effect"
    case soundPack = "sound_pack"
    case environment = "environment"
    case customization = "customization"
    
    var displayName: String {
        switch self {
        case .paperDesign: return "Paper Design"
        case .trailEffect: return "Trail Effect"
        case .soundPack: return "Sound Pack"
        case .environment: return "Environment"
        case .customization: return "Customization"
        }
    }
}

/// Rarity levels for bonus items
enum BonusItemRarity: String, Codable, CaseIterable {
    case common = "common"
    case uncommon = "uncommon"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var displayName: String {
        switch self {
        case .common: return "Common"
        case .uncommon: return "Uncommon"
        case .rare: return "Rare"
        case .epic: return "Epic"
        case .legendary: return "Legendary"
        }
    }
    
    var color: String {
        switch self {
        case .common: return "gray"
        case .uncommon: return "green"
        case .rare: return "blue"
        case .epic: return "purple"
        case .legendary: return "orange"
        }
    }
}

/// Leaderboard entry for weekly specials
struct WeeklySpecialLeaderboardEntry: Codable, Identifiable {
    let id: String
    let playerID: String
    let displayName: String
    let score: Int
    let rank: Int
    let completionTime: TimeInterval
    let submissionDate: Date
    let weeklySpecialId: String
    
    init(
        id: String = UUID().uuidString,
        playerID: String,
        displayName: String,
        score: Int,
        rank: Int,
        completionTime: TimeInterval,
        submissionDate: Date = Date(),
        weeklySpecialId: String
    ) {
        self.id = id
        self.playerID = playerID
        self.displayName = displayName
        self.score = score
        self.rank = rank
        self.completionTime = completionTime
        self.submissionDate = submissionDate
        self.weeklySpecialId = weeklySpecialId
    }
    
    /// Formatted completion time string
    var formattedCompletionTime: String {
        let minutes = Int(completionTime) / 60
        let seconds = Int(completionTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Formatted submission date string
    var formattedSubmissionDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: submissionDate)
    }
}

/// Errors related to weekly special operations
enum WeeklySpecialError: Error, LocalizedError {
    case notFound
    case expired
    case notStarted
    case invalidShareCode
    case networkError
    case serverError(String)
    case submissionFailed
    case leaderboardUnavailable
    case cacheError
    case validationError(String)
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Weekly special not found."
        case .expired:
            return "This weekly special has expired."
        case .notStarted:
            return "This weekly special hasn't started yet."
        case .invalidShareCode:
            return "Invalid share code. Please check and try again."
        case .networkError:
            return "Network error. Please check your connection."
        case .serverError(let message):
            return "Server error: \(message)"
        case .submissionFailed:
            return "Failed to submit score. Please try again."
        case .leaderboardUnavailable:
            return "Leaderboard is currently unavailable."
        case .cacheError:
            return "Failed to cache weekly specials."
        case .validationError(let message):
            return "Validation error: \(message)"
        }
    }
}

// MARK: - Convenience Extensions

extension WeeklySpecial {
    /// Create a sample weekly special for testing
    static func sample() -> WeeklySpecial {
        let obstacles = [
            ObstacleConfiguration(
                type: "tree",
                position: CGPoint(x: 200, y: 300),
                size: CGSize(width: 60, height: 120)
            ),
            ObstacleConfiguration(
                type: "building",
                position: CGPoint(x: 500, y: 200),
                size: CGSize(width: 100, height: 200)
            )
        ]
        
        let collectibles = [
            CollectibleConfiguration(
                type: "star",
                position: CGPoint(x: 150, y: 250),
                value: 50
            ),
            CollectibleConfiguration(
                type: "coin",
                position: CGPoint(x: 350, y: 180),
                value: 25
            )
        ]
        
        let specialFeatures = [
            WeeklySpecialFeature(
                type: .boostRing,
                position: CGPoint(x: 300, y: 400)
            ),
            WeeklySpecialFeature(
                type: .scoreMultiplier,
                position: CGPoint(x: 600, y: 300),
                properties: ["multiplier": "2.0"]
            )
        ]
        
        let courseData = WeeklySpecialCourseData(
            obstacles: obstacles,
            collectibles: collectibles,
            weatherConditions: WeatherConfiguration(
                windSpeed: 0.7,
                windDirection: 45,
                turbulence: 0.3
            ),
            specialFeatures: specialFeatures,
            estimatedDuration: 150
        )
        
        let bonusItems = [
            WeeklySpecialBonusItem(
                type: .paperDesign,
                name: "Golden Glider",
                description: "A special golden paper airplane design",
                rarity: .rare,
                iconName: "airplane"
            )
        ]
        
        let rewards = WeeklySpecialRewards(
            xpReward: 750,
            bonusItems: bonusItems,
            achievements: ["weekly_champion"],
            unlockables: ["golden_trail"]
        )
        
        return WeeklySpecial(
            title: "Sky High Challenge",
            description: "Navigate through the clouds and reach new heights in this week's special challenge!",
            startDate: Date().addingTimeInterval(-24 * 60 * 60), // Started yesterday
            endDate: Date().addingTimeInterval(6 * 24 * 60 * 60), // Ends in 6 days
            courseData: courseData,
            rewards: rewards,
            difficulty: .hard,
            targetDistance: 1500,
            environment: "Alpine Heights",
            windCondition: "Strong Winds"
        )
    }
}