import Foundation
import CoreGraphics

/// Represents a challenge that can be shared between players
struct Challenge: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let courseData: ChallengeData
    let expirationDate: Date
    let createdBy: String
    let createdAt: Date
    let targetScore: Int?
    
    /// Initialize a new challenge
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        courseData: ChallengeData,
        expirationDate: Date = Date().addingTimeInterval(7 * 24 * 60 * 60), // 7 days from now
        createdBy: String,
        targetScore: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.courseData = courseData
        self.expirationDate = expirationDate
        self.createdBy = createdBy
        self.createdAt = Date()
        self.targetScore = targetScore
    }
    
    /// Check if the challenge is still valid (not expired)
    var isValid: Bool {
        return Date() < expirationDate
    }
    
    /// Get the remaining time until expiration
    var timeUntilExpiration: TimeInterval {
        return expirationDate.timeIntervalSinceNow
    }
    
    /// Get a formatted expiration date string
    var expirationDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: expirationDate)
    }
}

/// Represents the course configuration for a challenge
struct ChallengeData: Codable {
    let environmentType: String
    let obstacles: [ObstacleConfiguration]
    let collectibles: [CollectibleConfiguration]
    let weatherConditions: WeatherConfiguration
    let difficulty: ChallengeDifficulty
    let estimatedDuration: TimeInterval
    
    /// Initialize challenge data
    init(
        environmentType: String,
        obstacles: [ObstacleConfiguration] = [],
        collectibles: [CollectibleConfiguration] = [],
        weatherConditions: WeatherConfiguration = WeatherConfiguration(),
        difficulty: ChallengeDifficulty = .medium,
        estimatedDuration: TimeInterval = 120 // 2 minutes default
    ) {
        self.environmentType = environmentType
        self.obstacles = obstacles
        self.collectibles = collectibles
        self.weatherConditions = weatherConditions
        self.difficulty = difficulty
        self.estimatedDuration = estimatedDuration
    }
    
    /// Encode the challenge data to a compact string for sharing
    var encoded: String {
        guard let data = try? JSONEncoder().encode(self),
              let base64String = data.base64EncodedString().data(using: .utf8)?.base64EncodedString() else {
            return ""
        }
        return base64String
    }
    
    /// Decode challenge data from an encoded string
    static func decode(from encodedString: String) -> ChallengeData? {
        guard let data = Data(base64Encoded: encodedString),
              let jsonData = Data(base64Encoded: String(data: data, encoding: .utf8) ?? ""),
              let challengeData = try? JSONDecoder().decode(ChallengeData.self, from: jsonData) else {
            return nil
        }
        return challengeData
    }
}

/// Configuration for obstacles in a challenge
struct ObstacleConfiguration: Codable {
    let type: String
    let position: CGPoint
    let size: CGSize
    let rotation: Double
    let properties: [String: String]
    
    init(
        type: String,
        position: CGPoint,
        size: CGSize = CGSize(width: 50, height: 50),
        rotation: Double = 0,
        properties: [String: String] = [:]
    ) {
        self.type = type
        self.position = position
        self.size = size
        self.rotation = rotation
        self.properties = properties
    }
}

/// Configuration for collectibles in a challenge
struct CollectibleConfiguration: Codable {
    let type: String
    let position: CGPoint
    let value: Int
    let properties: [String: String]
    
    init(
        type: String,
        position: CGPoint,
        value: Int = 10,
        properties: [String: String] = [:]
    ) {
        self.type = type
        self.position = position
        self.value = value
        self.properties = properties
    }
}

/// Weather conditions for a challenge
struct WeatherConfiguration: Codable {
    let windSpeed: Double
    let windDirection: Double
    let turbulence: Double
    let visibility: Double
    
    init(
        windSpeed: Double = 0.5,
        windDirection: Double = 0,
        turbulence: Double = 0.2,
        visibility: Double = 1.0
    ) {
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.turbulence = turbulence
        self.visibility = visibility
    }
}

/// Challenge difficulty levels
enum ChallengeDifficulty: String, Codable, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    case expert = "expert"
    
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .expert: return "Expert"
        }
    }
    
    var color: String {
        switch self {
        case .easy: return "green"
        case .medium: return "yellow"
        case .hard: return "orange"
        case .expert: return "red"
        }
    }
}

/// Errors related to challenge operations
enum ChallengeError: Error, LocalizedError {
    case invalidCode
    case expired
    case notFound
    case networkError
    case decodingError
    case validationError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCode:
            return "Invalid challenge code. Please check and try again."
        case .expired:
            return "This challenge has expired."
        case .notFound:
            return "Challenge not found."
        case .networkError:
            return "Network error. Please check your connection."
        case .decodingError:
            return "Failed to decode challenge data."
        case .validationError(let message):
            return "Validation error: \(message)"
        }
    }
}