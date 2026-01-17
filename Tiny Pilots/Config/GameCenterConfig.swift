import Foundation

/// Configuration constants for Game Center integration
struct GameCenterConfig {
    
    /// Leaderboard identifiers
    struct Leaderboards {
        /// Leaderboard for distance in free play mode
        static let distanceFreePlay = "com.tinypilots.leaderboard.distance.freeplay"
        
        /// Leaderboard for distance in challenge mode
        static let distanceChallenge = "com.tinypilots.leaderboard.distance.challenge"
        
        /// Leaderboard for distance in daily run mode
        static let distanceDailyRun = "com.tinypilots.leaderboard.distance.dailyrun"
        
        /// Leaderboard for distance in weekly special mode
        static let distanceWeeklySpecial = "com.tinypilots.leaderboard.distance.weeklyspecial"
        
        /// Leaderboard for total flight time
        static let flightTime = "com.tinypilots.leaderboard.flighttime"
        
        /// Leaderboard for highest score
        static let highScore = "com.tinypilots.leaderboard.highscore"
    }
    
    /// Achievement identifiers
    struct Achievements {
        /// Achievement for completing the first flight
        static let firstFlight = "com.tinypilots.achievement.firstflight"
        
        /// Achievement for flying 1000 meters in a single flight
        static let distance1000 = "com.tinypilots.achievement.distance1000"
        
        /// Achievement for flying 5000 meters in a single flight
        static let distance5000 = "com.tinypilots.achievement.distance5000"
        
        /// Achievement for flying 10000 meters in a single flight
        static let distance10000 = "com.tinypilots.achievement.distance10000"
        
        /// Achievement for completing a daily run for 3 consecutive days
        static let dailyStreak3 = "com.tinypilots.achievement.dailystreak3"
        
        /// Achievement for completing a daily run for 7 consecutive days
        static let dailyStreak7 = "com.tinypilots.achievement.dailystreak7"
        
        /// Achievement for completing a daily run for 30 consecutive days
        static let dailyStreak30 = "com.tinypilots.achievement.dailystreak30"
        
        /// Achievement for flying for a total of 1 hour
        static let flightTime1Hour = "com.tinypilots.achievement.flighttime1hour"
        
        /// Achievement for unlocking all airplanes
        static let allAirplanes = "com.tinypilots.achievement.allairplanes"
        
        /// Achievement for unlocking all environments
        static let allEnvironments = "com.tinypilots.achievement.allenvironments"
        
        /// Achievement for completing the first challenge
        static let firstChallenge = "com.tinypilots.achievement.firstchallenge"
        
        /// Achievement for completing 10 challenges
        static let challenges10 = "com.tinypilots.achievement.challenges10"
    }
    
    /// Course identifiers for challenges
    struct Courses {
        /// Mountain course
        static let mountain = "mountain"
        
        /// Desert course
        static let desert = "desert"
        
        /// Ocean course
        static let ocean = "ocean"
        
        /// City course
        static let city = "city"
        
        /// Forest course
        static let forest = "forest"
        
        /// Get display name for a course ID
        static func displayName(for courseID: String) -> String {
            switch courseID {
            case mountain:
                return "Mountain Range"
            case desert:
                return "Desert Canyon"
            case ocean:
                return "Ocean Breeze"
            case city:
                return "City Skyline"
            case forest:
                return "Forest Canopy"
            default:
                return courseID.capitalized
            }
        }
        
        /// Get all available course IDs
        static var allCourses: [String] {
            return [mountain, desert, ocean, city, forest]
        }
    }
    
    /// Challenge code configuration
    struct ChallengeCode {
        /// Length of the challenge code (excluding hyphen)
        static let codeLength = 8
        
        /// Position of the hyphen in the challenge code
        static let hyphenPosition = 4
        
        /// Challenge code expiration time in hours
        static let expirationHours = 24
    }
} 