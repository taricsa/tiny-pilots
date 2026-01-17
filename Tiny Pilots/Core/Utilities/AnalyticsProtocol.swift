//
//  AnalyticsProtocol.swift
//  Tiny Pilots
//
//  Created by Kiro on 7/15/25.
//

import Foundation

/// Protocol defining analytics tracking capabilities
protocol AnalyticsProtocol {
    /// Track a specific analytics event
    func trackEvent(_ event: AnalyticsEvent)
    
    /// Track an error with context information
    func trackError(message: String, category: String, error: Error?)
    
    /// Track performance metrics
    func trackPerformance(_ metric: PerformanceMetric)
    
    /// Set user properties for analytics
    func setUserProperty(_ property: String, value: Any)
    
    /// Track screen views
    func trackScreenView(_ screenName: String, parameters: [String: Any]?)
    
    /// Enable or disable analytics tracking
    func setAnalyticsEnabled(_ enabled: Bool)
    
    /// Check if user has consented to analytics
    var hasUserConsent: Bool { get }
    
    /// Request user consent for analytics
    func requestUserConsent() async -> Bool
}

/// Analytics events specific to Tiny Pilots game
enum AnalyticsEvent: Codable {
    // Game Events
    case gameStarted(mode: GameMode, environment: String)
    case gameCompleted(mode: GameMode, score: Int, duration: TimeInterval, environment: String)
    case gamePaused(duration: TimeInterval)
    case gameResumed
    case gameAbandoned(reason: String, duration: TimeInterval)
    
    // User Interactions
    case airplaneCustomized(foldType: String, colorScheme: String)
    case challengeShared(challengeId: String)
    case achievementUnlocked(achievementId: String)
    case leaderboardViewed(category: String)
    case settingsChanged(setting: String, value: String)
    
    // Game Center Events
    case gameCenterAuthenticated
    case gameCenterAuthenticationFailed(error: String)
    case leaderboardScoreSubmitted(category: String, score: Int)
    case achievementProgressUpdated(achievementId: String, progress: Double)
    
    // Performance Events
    case lowFrameRateDetected(fps: Double, scene: String)
    case highMemoryUsageDetected(memoryMB: Double)
    case slowSceneTransition(fromScene: String, toScene: String, duration: TimeInterval)
    case appLaunchCompleted(duration: TimeInterval)
    
    // Error Events
    case errorOccurred(category: String, message: String, isFatal: Bool)
    case crashRecovered(context: String)
    
    // Network Events
    case networkConnectivityChanged(isConnected: Bool)
    case networkRequestFailed(endpoint: String, error: String)
    case offlineModeActivated
    
    // Feature Usage
    case tutorialStarted
    case tutorialCompleted(duration: TimeInterval)
    case tutorialSkipped(step: String)
    case dailyRunStarted
    case weeklySpecialViewed
    case challengeCodeEntered(isValid: Bool)
    case dailyRunGenerated(difficulty: String)
    case dailyRunCompleted(score: Int)
    
    // Privacy & Compliance Events
    case privacyPolicyAccepted
    case complianceValidation(isCompliant: Bool)
}

/// Performance metrics for tracking
struct PerformanceMetric: Codable {
    let name: String
    let value: Double
    let unit: String
    let category: String
    let timestamp: Date
    let additionalInfo: [String: String]?
    
    init(name: String, value: Double, unit: String, category: String, additionalInfo: [String: String]? = nil) {
        self.name = name
        self.value = value
        self.unit = unit
        self.category = category
        self.timestamp = Date()
        self.additionalInfo = additionalInfo
    }
}

/// User consent status for analytics
enum AnalyticsConsentStatus: String, Codable {
    case notRequested = "not_requested"
    case granted = "granted"
    case denied = "denied"
    case expired = "expired"
}