//
//  AppConfiguration.swift
//  Tiny Pilots
//
//  Created by Kiro on Production Readiness Implementation
//

import Foundation

/// Environment types for different build configurations
enum BuildEnvironment: String, CaseIterable {
    case debug = "Debug"
    case testFlight = "TestFlight"
    case production = "Production"
    
    /// Get the current environment based on build configuration
    static var current: BuildEnvironment {
        #if DEBUG
        return .debug
        #elseif TESTFLIGHT
        return .testFlight
        #else
        return .production
        #endif
    }
    
    /// Whether this is a development environment
    var isDevelopment: Bool {
        return self == .debug
    }
    
    /// Whether this is a testing environment
    var isTesting: Bool {
        return self == .testFlight
    }
    
    /// Whether this is a production environment
    var isProduction: Bool {
        return self == .production
    }
}

/// Feature flags for controlling app behavior
struct FeatureFlags {
    let isDebugMenuEnabled: Bool
    let isAnalyticsEnabled: Bool
    let isCrashReportingEnabled: Bool
    let isPerformanceMonitoringEnabled: Bool
    let isAdvancedLoggingEnabled: Bool
    let isExperimentalFeaturesEnabled: Bool
    
    static func forEnvironment(_ environment: BuildEnvironment) -> FeatureFlags {
        switch environment {
        case .debug:
            return FeatureFlags(
                isDebugMenuEnabled: true,
                isAnalyticsEnabled: false,
                isCrashReportingEnabled: false,
                isPerformanceMonitoringEnabled: true,
                isAdvancedLoggingEnabled: true,
                isExperimentalFeaturesEnabled: true
            )
        case .testFlight:
            return FeatureFlags(
                isDebugMenuEnabled: true,
                isAnalyticsEnabled: true,
                isCrashReportingEnabled: true,
                isPerformanceMonitoringEnabled: true,
                isAdvancedLoggingEnabled: true,
                isExperimentalFeaturesEnabled: false
            )
        case .production:
            return FeatureFlags(
                isDebugMenuEnabled: false,
                isAnalyticsEnabled: true,
                isCrashReportingEnabled: true,
                isPerformanceMonitoringEnabled: false,
                isAdvancedLoggingEnabled: false,
                isExperimentalFeaturesEnabled: false
            )
        }
    }
}

/// API configuration for different environments
struct APIConfiguration {
    let baseURL: String
    let timeout: TimeInterval
    let retryAttempts: Int
    let enableSSLPinning: Bool
    
    static func forEnvironment(_ environment: BuildEnvironment) -> APIConfiguration {
        switch environment {
        case .debug:
            return APIConfiguration(
                baseURL: "https://api-dev.tinypilots.com",
                timeout: 30.0,
                retryAttempts: 3,
                enableSSLPinning: false
            )
        case .testFlight:
            return APIConfiguration(
                baseURL: "https://api-staging.tinypilots.com",
                timeout: 15.0,
                retryAttempts: 3,
                enableSSLPinning: true
            )
        case .production:
            return APIConfiguration(
                baseURL: "https://api.tinypilots.com",
                timeout: 10.0,
                retryAttempts: 2,
                enableSSLPinning: true
            )
        }
    }
}

/// Game Center configuration for different environments
struct GameCenterConfiguration {
    let leaderboardIDs: [String: String]
    let achievementIDs: [String: String]
    let enableSandbox: Bool
    
    static func forEnvironment(_ environment: BuildEnvironment) -> GameCenterConfiguration {
        let suffix = environment.isProduction ? "" : ".\(environment.rawValue.lowercased())"
        
        return GameCenterConfiguration(
            leaderboardIDs: [
                "distance": "com.tinypilots.leaderboard.distance\(suffix)",
                "weekly": "com.tinypilots.leaderboard.weekly\(suffix)",
                "daily": "com.tinypilots.leaderboard.daily\(suffix)",
                "challenges": "com.tinypilots.leaderboard.challenges\(suffix)"
            ],
            achievementIDs: [
                "first_flight": "com.tinypilots.achievement.first_flight\(suffix)",
                "distance_100": "com.tinypilots.achievement.distance_100\(suffix)",
                "distance_500": "com.tinypilots.achievement.distance_500\(suffix)",
                "distance_1000": "com.tinypilots.achievement.distance_1000\(suffix)",
                "perfect_landing": "com.tinypilots.achievement.perfect_landing\(suffix)",
                "challenge_master": "com.tinypilots.achievement.challenge_master\(suffix)"
            ],
            enableSandbox: !environment.isProduction
        )
    }
}

/// Logging configuration for different environments
struct LoggingConfiguration {
    let minimumLevel: LogLevel
    let enableFileLogging: Bool
    let enableRemoteLogging: Bool
    let maxLogFileSize: Int // in MB
    let logRetentionDays: Int
    
    static func forEnvironment(_ environment: BuildEnvironment) -> LoggingConfiguration {
        switch environment {
        case .debug:
            return LoggingConfiguration(
                minimumLevel: .debug,
                enableFileLogging: true,
                enableRemoteLogging: false,
                maxLogFileSize: 50,
                logRetentionDays: 7
            )
        case .testFlight:
            return LoggingConfiguration(
                minimumLevel: .info,
                enableFileLogging: true,
                enableRemoteLogging: true,
                maxLogFileSize: 25,
                logRetentionDays: 3
            )
        case .production:
            return LoggingConfiguration(
                minimumLevel: .warning,
                enableFileLogging: false,
                enableRemoteLogging: true,
                maxLogFileSize: 10,
                logRetentionDays: 1
            )
        }
    }
}

/// Performance configuration for different environments
struct PerformanceConfiguration {
    let targetFrameRate: Int
    let enableProMotion: Bool
    let maxMemoryUsage: Int // in MB
    let enablePerformanceMetrics: Bool
    let enableMemoryWarnings: Bool
    
    static func forEnvironment(_ environment: BuildEnvironment) -> PerformanceConfiguration {
        switch environment {
        case .debug:
            return PerformanceConfiguration(
                targetFrameRate: 60,
                enableProMotion: true,
                maxMemoryUsage: 500,
                enablePerformanceMetrics: true,
                enableMemoryWarnings: true
            )
        case .testFlight:
            return PerformanceConfiguration(
                targetFrameRate: 60,
                enableProMotion: true,
                maxMemoryUsage: 300,
                enablePerformanceMetrics: true,
                enableMemoryWarnings: false
            )
        case .production:
            return PerformanceConfiguration(
                targetFrameRate: 60,
                enableProMotion: true,
                maxMemoryUsage: 200,
                enablePerformanceMetrics: false,
                enableMemoryWarnings: false
            )
        }
    }
}

/// Main application configuration
struct AppConfiguration {
    let environment: BuildEnvironment
    let featureFlags: FeatureFlags
    let apiConfiguration: APIConfiguration
    let gameCenterConfiguration: GameCenterConfiguration
    let loggingConfiguration: LoggingConfiguration
    let performanceConfiguration: PerformanceConfiguration
    let buildVersion: String
    let buildNumber: String
    
    /// Get the current app configuration based on the environment
    static var current: AppConfiguration {
        let environment = BuildEnvironment.current
        
        return AppConfiguration(
            environment: environment,
            featureFlags: FeatureFlags.forEnvironment(environment),
            apiConfiguration: APIConfiguration.forEnvironment(environment),
            gameCenterConfiguration: GameCenterConfiguration.forEnvironment(environment),
            loggingConfiguration: LoggingConfiguration.forEnvironment(environment),
            performanceConfiguration: PerformanceConfiguration.forEnvironment(environment),
            buildVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        )
    }
    
    /// Create a custom configuration (useful for testing)
    static func custom(
        environment: BuildEnvironment,
        featureFlags: FeatureFlags? = nil,
        apiConfiguration: APIConfiguration? = nil,
        gameCenterConfiguration: GameCenterConfiguration? = nil,
        loggingConfiguration: LoggingConfiguration? = nil,
        performanceConfiguration: PerformanceConfiguration? = nil
    ) -> AppConfiguration {
        return AppConfiguration(
            environment: environment,
            featureFlags: featureFlags ?? FeatureFlags.forEnvironment(environment),
            apiConfiguration: apiConfiguration ?? APIConfiguration.forEnvironment(environment),
            gameCenterConfiguration: gameCenterConfiguration ?? GameCenterConfiguration.forEnvironment(environment),
            loggingConfiguration: loggingConfiguration ?? LoggingConfiguration.forEnvironment(environment),
            performanceConfiguration: performanceConfiguration ?? PerformanceConfiguration.forEnvironment(environment),
            buildVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        )
    }
}

/// Configuration manager for runtime configuration changes
class ConfigurationManager {
    static let shared = ConfigurationManager()
    
    private var _currentConfiguration: AppConfiguration
    private let configurationQueue = DispatchQueue(label: "com.tinypilots.configuration", qos: .utility)
    
    private init() {
        self._currentConfiguration = AppConfiguration.current
        setupLoggingConfiguration()
    }
    
    /// Get the current configuration
    var currentConfiguration: AppConfiguration {
        return configurationQueue.sync {
            return _currentConfiguration
        }
    }
    
    /// Update the configuration (useful for testing or runtime changes)
    func updateConfiguration(_ configuration: AppConfiguration) {
        configurationQueue.async { [weak self] in
            self?._currentConfiguration = configuration
            self?.setupLoggingConfiguration()
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .configurationDidChange,
                    object: nil,
                    userInfo: ["configuration": configuration]
                )
            }
        }
    }
    
    /// Check if a feature is enabled
    func isFeatureEnabled(_ feature: KeyPath<FeatureFlags, Bool>) -> Bool {
        return currentConfiguration.featureFlags[keyPath: feature]
    }
    
    /// Get API base URL
    var apiBaseURL: String {
        return currentConfiguration.apiConfiguration.baseURL
    }
    
    /// Get Game Center leaderboard ID
    func gameCenterLeaderboardID(for key: String) -> String? {
        return currentConfiguration.gameCenterConfiguration.leaderboardIDs[key]
    }
    
    /// Get Game Center achievement ID
    func gameCenterAchievementID(for key: String) -> String? {
        return currentConfiguration.gameCenterConfiguration.achievementIDs[key]
    }
    
    private func setupLoggingConfiguration() {
        let loggingConfig = _currentConfiguration.loggingConfiguration
        Logger.shared.setMinimumLogLevel(loggingConfig.minimumLevel)
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let configurationDidChange = Notification.Name("ConfigurationDidChange")
    static let networkConnectivityChanged = Notification.Name("NetworkConnectivityChanged")
}

// MARK: - Convenience Extensions
extension AppConfiguration {
    /// Whether debug features should be enabled
    var isDebugMode: Bool {
        return environment.isDevelopment || featureFlags.isDebugMenuEnabled
    }
    
    /// Whether analytics should be collected
    var shouldCollectAnalytics: Bool {
        return featureFlags.isAnalyticsEnabled
    }
    
    /// Whether crash reports should be sent
    var shouldSendCrashReports: Bool {
        return featureFlags.isCrashReportingEnabled
    }
    
    /// Full version string
    var fullVersionString: String {
        return "\(buildVersion) (\(buildNumber))"
    }
    
    /// Environment display name
    var environmentDisplayName: String {
        return environment.rawValue
    }
}