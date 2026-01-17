//
//  AppConfigurationTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on Production Readiness Implementation
//

import XCTest
@testable import Tiny_Pilots

class AppConfigurationTests: XCTestCase {
    
    var configurationManager: ConfigurationManager!
    var notificationObserver: NSObjectProtocol?
    
    override func setUp() {
        super.setUp()
        configurationManager = ConfigurationManager.shared
    }
    
    override func tearDown() {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
            notificationObserver = nil
        }
        configurationManager = nil
        super.tearDown()
    }
    
    // MARK: - Environment Tests
    
    func testEnvironmentProperties() {
        XCTAssertTrue(Environment.debug.isDevelopment)
        XCTAssertFalse(Environment.debug.isTesting)
        XCTAssertFalse(Environment.debug.isProduction)
        
        XCTAssertFalse(Environment.testFlight.isDevelopment)
        XCTAssertTrue(Environment.testFlight.isTesting)
        XCTAssertFalse(Environment.testFlight.isProduction)
        
        XCTAssertFalse(Environment.production.isDevelopment)
        XCTAssertFalse(Environment.production.isTesting)
        XCTAssertTrue(Environment.production.isProduction)
    }
    
    func testEnvironmentRawValues() {
        XCTAssertEqual(Environment.debug.rawValue, "Debug")
        XCTAssertEqual(Environment.testFlight.rawValue, "TestFlight")
        XCTAssertEqual(Environment.production.rawValue, "Production")
    }
    
    func testCurrentEnvironment() {
        let currentEnv = Environment.current
        
        // In test environment, this should be debug
        #if DEBUG
        XCTAssertEqual(currentEnv, .debug)
        #elseif TESTFLIGHT
        XCTAssertEqual(currentEnv, .testFlight)
        #else
        XCTAssertEqual(currentEnv, .production)
        #endif
    }
    
    // MARK: - Feature Flags Tests
    
    func testDebugFeatureFlags() {
        let flags = FeatureFlags.forEnvironment(.debug)
        
        XCTAssertTrue(flags.isDebugMenuEnabled)
        XCTAssertFalse(flags.isAnalyticsEnabled)
        XCTAssertFalse(flags.isCrashReportingEnabled)
        XCTAssertTrue(flags.isPerformanceMonitoringEnabled)
        XCTAssertTrue(flags.isAdvancedLoggingEnabled)
        XCTAssertTrue(flags.isExperimentalFeaturesEnabled)
    }
    
    func testTestFlightFeatureFlags() {
        let flags = FeatureFlags.forEnvironment(.testFlight)
        
        XCTAssertTrue(flags.isDebugMenuEnabled)
        XCTAssertTrue(flags.isAnalyticsEnabled)
        XCTAssertTrue(flags.isCrashReportingEnabled)
        XCTAssertTrue(flags.isPerformanceMonitoringEnabled)
        XCTAssertTrue(flags.isAdvancedLoggingEnabled)
        XCTAssertFalse(flags.isExperimentalFeaturesEnabled)
    }
    
    func testProductionFeatureFlags() {
        let flags = FeatureFlags.forEnvironment(.production)
        
        XCTAssertFalse(flags.isDebugMenuEnabled)
        XCTAssertTrue(flags.isAnalyticsEnabled)
        XCTAssertTrue(flags.isCrashReportingEnabled)
        XCTAssertFalse(flags.isPerformanceMonitoringEnabled)
        XCTAssertFalse(flags.isAdvancedLoggingEnabled)
        XCTAssertFalse(flags.isExperimentalFeaturesEnabled)
    }
    
    // MARK: - API Configuration Tests
    
    func testDebugAPIConfiguration() {
        let config = APIConfiguration.forEnvironment(.debug)
        
        XCTAssertEqual(config.baseURL, "https://api-dev.tinypilots.com")
        XCTAssertEqual(config.timeout, 30.0)
        XCTAssertEqual(config.retryAttempts, 3)
        XCTAssertFalse(config.enableSSLPinning)
    }
    
    func testTestFlightAPIConfiguration() {
        let config = APIConfiguration.forEnvironment(.testFlight)
        
        XCTAssertEqual(config.baseURL, "https://api-staging.tinypilots.com")
        XCTAssertEqual(config.timeout, 15.0)
        XCTAssertEqual(config.retryAttempts, 3)
        XCTAssertTrue(config.enableSSLPinning)
    }
    
    func testProductionAPIConfiguration() {
        let config = APIConfiguration.forEnvironment(.production)
        
        XCTAssertEqual(config.baseURL, "https://api.tinypilots.com")
        XCTAssertEqual(config.timeout, 10.0)
        XCTAssertEqual(config.retryAttempts, 2)
        XCTAssertTrue(config.enableSSLPinning)
    }
    
    // MARK: - Game Center Configuration Tests
    
    func testDebugGameCenterConfiguration() {
        let config = GameCenterConfiguration.forEnvironment(.debug)
        
        XCTAssertEqual(config.leaderboardIDs["distance"], "com.tinypilots.leaderboard.distance.debug")
        XCTAssertEqual(config.leaderboardIDs["weekly"], "com.tinypilots.leaderboard.weekly.debug")
        XCTAssertEqual(config.achievementIDs["first_flight"], "com.tinypilots.achievement.first_flight.debug")
        XCTAssertTrue(config.enableSandbox)
    }
    
    func testProductionGameCenterConfiguration() {
        let config = GameCenterConfiguration.forEnvironment(.production)
        
        XCTAssertEqual(config.leaderboardIDs["distance"], "com.tinypilots.leaderboard.distance")
        XCTAssertEqual(config.leaderboardIDs["weekly"], "com.tinypilots.leaderboard.weekly")
        XCTAssertEqual(config.achievementIDs["first_flight"], "com.tinypilots.achievement.first_flight")
        XCTAssertFalse(config.enableSandbox)
    }
    
    // MARK: - Logging Configuration Tests
    
    func testDebugLoggingConfiguration() {
        let config = LoggingConfiguration.forEnvironment(.debug)
        
        XCTAssertEqual(config.minimumLevel, .debug)
        XCTAssertTrue(config.enableFileLogging)
        XCTAssertFalse(config.enableRemoteLogging)
        XCTAssertEqual(config.maxLogFileSize, 50)
        XCTAssertEqual(config.logRetentionDays, 7)
    }
    
    func testProductionLoggingConfiguration() {
        let config = LoggingConfiguration.forEnvironment(.production)
        
        XCTAssertEqual(config.minimumLevel, .warning)
        XCTAssertFalse(config.enableFileLogging)
        XCTAssertTrue(config.enableRemoteLogging)
        XCTAssertEqual(config.maxLogFileSize, 10)
        XCTAssertEqual(config.logRetentionDays, 1)
    }
    
    // MARK: - Performance Configuration Tests
    
    func testPerformanceConfiguration() {
        let debugConfig = PerformanceConfiguration.forEnvironment(.debug)
        let productionConfig = PerformanceConfiguration.forEnvironment(.production)
        
        XCTAssertEqual(debugConfig.targetFrameRate, 60)
        XCTAssertTrue(debugConfig.enableProMotion)
        XCTAssertEqual(debugConfig.maxMemoryUsage, 500)
        XCTAssertTrue(debugConfig.enablePerformanceMetrics)
        XCTAssertTrue(debugConfig.enableMemoryWarnings)
        
        XCTAssertEqual(productionConfig.targetFrameRate, 60)
        XCTAssertTrue(productionConfig.enableProMotion)
        XCTAssertEqual(productionConfig.maxMemoryUsage, 200)
        XCTAssertFalse(productionConfig.enablePerformanceMetrics)
        XCTAssertFalse(productionConfig.enableMemoryWarnings)
    }
    
    // MARK: - App Configuration Tests
    
    func testCurrentAppConfiguration() {
        let config = AppConfiguration.current
        
        XCTAssertEqual(config.environment, Environment.current)
        XCTAssertNotNil(config.featureFlags)
        XCTAssertNotNil(config.apiConfiguration)
        XCTAssertNotNil(config.gameCenterConfiguration)
        XCTAssertNotNil(config.loggingConfiguration)
        XCTAssertNotNil(config.performanceConfiguration)
        XCTAssertFalse(config.buildVersion.isEmpty)
        XCTAssertFalse(config.buildNumber.isEmpty)
    }
    
    func testCustomAppConfiguration() {
        let customFlags = FeatureFlags(
            isDebugMenuEnabled: true,
            isAnalyticsEnabled: false,
            isCrashReportingEnabled: false,
            isPerformanceMonitoringEnabled: true,
            isAdvancedLoggingEnabled: true,
            isExperimentalFeaturesEnabled: true
        )
        
        let config = AppConfiguration.custom(
            environment: .debug,
            featureFlags: customFlags
        )
        
        XCTAssertEqual(config.environment, .debug)
        XCTAssertTrue(config.featureFlags.isDebugMenuEnabled)
        XCTAssertFalse(config.featureFlags.isAnalyticsEnabled)
    }
    
    func testAppConfigurationConvenienceProperties() {
        let debugConfig = AppConfiguration.custom(environment: .debug)
        let productionConfig = AppConfiguration.custom(environment: .production)
        
        XCTAssertTrue(debugConfig.isDebugMode)
        XCTAssertFalse(debugConfig.shouldCollectAnalytics)
        XCTAssertFalse(debugConfig.shouldSendCrashReports)
        
        XCTAssertFalse(productionConfig.isDebugMode)
        XCTAssertTrue(productionConfig.shouldCollectAnalytics)
        XCTAssertTrue(productionConfig.shouldSendCrashReports)
        
        XCTAssertEqual(debugConfig.environmentDisplayName, "Debug")
        XCTAssertEqual(productionConfig.environmentDisplayName, "Production")
    }
    
    // MARK: - Configuration Manager Tests
    
    func testConfigurationManagerSingleton() {
        let instance1 = ConfigurationManager.shared
        let instance2 = ConfigurationManager.shared
        
        XCTAssertTrue(instance1 === instance2, "ConfigurationManager should be a singleton")
    }
    
    func testConfigurationManagerCurrentConfiguration() {
        let config = configurationManager.currentConfiguration
        
        XCTAssertNotNil(config)
        XCTAssertEqual(config.environment, Environment.current)
    }
    
    func testConfigurationManagerFeatureCheck() {
        let isDebugEnabled = configurationManager.isFeatureEnabled(\.isDebugMenuEnabled)
        let isAnalyticsEnabled = configurationManager.isFeatureEnabled(\.isAnalyticsEnabled)
        
        // These should match the current environment's feature flags
        let expectedFlags = FeatureFlags.forEnvironment(Environment.current)
        XCTAssertEqual(isDebugEnabled, expectedFlags.isDebugMenuEnabled)
        XCTAssertEqual(isAnalyticsEnabled, expectedFlags.isAnalyticsEnabled)
    }
    
    func testConfigurationManagerAPIAccess() {
        let apiURL = configurationManager.apiBaseURL
        let expectedURL = APIConfiguration.forEnvironment(Environment.current).baseURL
        
        XCTAssertEqual(apiURL, expectedURL)
    }
    
    func testConfigurationManagerGameCenterAccess() {
        let leaderboardID = configurationManager.gameCenterLeaderboardID(for: "distance")
        let achievementID = configurationManager.gameCenterAchievementID(for: "first_flight")
        
        XCTAssertNotNil(leaderboardID)
        XCTAssertNotNil(achievementID)
        XCTAssertTrue(leaderboardID!.contains("distance"))
        XCTAssertTrue(achievementID!.contains("first_flight"))
    }
    
    func testConfigurationManagerUpdate() {
        let customConfig = AppConfiguration.custom(environment: .debug)
        let expectation = XCTestExpectation(description: "Configuration change notification")
        
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .configurationDidChange,
            object: nil,
            queue: .main
        ) { notification in
            XCTAssertNotNil(notification.userInfo?["configuration"])
            expectation.fulfill()
        }
        
        configurationManager.updateConfiguration(customConfig)
        
        wait(for: [expectation], timeout: 1.0)
        
        // Verify the configuration was updated
        let updatedConfig = configurationManager.currentConfiguration
        XCTAssertEqual(updatedConfig.environment, .debug)
    }
    
    // MARK: - Performance Tests
    
    func testConfigurationAccessPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = configurationManager.currentConfiguration
                _ = configurationManager.isFeatureEnabled(\.isAnalyticsEnabled)
                _ = configurationManager.apiBaseURL
            }
        }
    }
    
    func testConfigurationCreationPerformance() {
        measure {
            for _ in 0..<100 {
                _ = AppConfiguration.current
                _ = FeatureFlags.forEnvironment(.debug)
                _ = APIConfiguration.forEnvironment(.production)
            }
        }
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentConfigurationAccess() {
        let expectation = XCTestExpectation(description: "Concurrent configuration access")
        expectation.expectedFulfillmentCount = 10
        
        for i in 0..<10 {
            DispatchQueue.global(qos: .background).async {
                _ = self.configurationManager.currentConfiguration
                _ = self.configurationManager.isFeatureEnabled(\.isDebugMenuEnabled)
                _ = self.configurationManager.apiBaseURL
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Edge Case Tests
    
    func testInvalidGameCenterKeys() {
        let invalidLeaderboard = configurationManager.gameCenterLeaderboardID(for: "invalid_key")
        let invalidAchievement = configurationManager.gameCenterAchievementID(for: "invalid_key")
        
        XCTAssertNil(invalidLeaderboard)
        XCTAssertNil(invalidAchievement)
    }
    
    func testEmptyGameCenterKeys() {
        let emptyLeaderboard = configurationManager.gameCenterLeaderboardID(for: "")
        let emptyAchievement = configurationManager.gameCenterAchievementID(for: "")
        
        XCTAssertNil(emptyLeaderboard)
        XCTAssertNil(emptyAchievement)
    }
}