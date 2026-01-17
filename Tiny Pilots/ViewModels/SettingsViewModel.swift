//
//  SettingsViewModel.swift
//  Tiny Pilots
//
//  Created by Kiro on 7/15/25.
//

import Foundation
import Observation
import SwiftData
import UIKit

/// ViewModel for managing game settings
@Observable
class SettingsViewModel: BaseViewModel {
    
    // MARK: - Audio Settings
    
    /// Sound effects volume (0.0 to 1.0)
    var soundVolume: Double = 0.7 {
        didSet {
            audioService.soundVolume = Float(soundVolume)
            saveSettings()
        }
    }
    
    /// Music volume (0.0 to 1.0)
    var musicVolume: Double = 0.5 {
        didSet {
            audioService.musicVolume = Float(musicVolume)
            saveSettings()
        }
    }
    
    /// Whether sound effects are enabled
    var soundEnabled: Bool = true {
        didSet {
            audioService.soundEnabled = soundEnabled
            saveSettings()
        }
    }
    
    /// Whether background music is enabled
    var musicEnabled: Bool = true {
        didSet {
            audioService.musicEnabled = musicEnabled
            saveSettings()
        }
    }
    
    // MARK: - Gameplay Settings
    
    /// Control sensitivity (0.5 to 1.5)
    var controlSensitivity: Double = 1.0 {
        didSet {
            physicsService.sensitivity = CGFloat(controlSensitivity)
            saveSettings()
        }
    }
    
    /// Whether to show tutorial tips
    var showTutorialTips: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    /// Whether to use haptic feedback
    var useHapticFeedback: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    /// Whether to invert tilt controls
    var invertControls: Bool = false {
        didSet {
            saveSettings()
        }
    }
    
    // MARK: - Graphics Settings
    
    /// Whether high performance mode is enabled
    var highPerformanceMode: Bool = false {
        didSet {
            updatePerformanceSettings()
            saveSettings()
        }
    }
    
    /// Whether particle effects are enabled
    var particleEffectsEnabled: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    /// Graphics quality level
    var graphicsQuality: GraphicsQuality = .medium {
        didSet {
            updateGraphicsSettings()
            saveSettings()
        }
    }
    
    // MARK: - Privacy Settings
    
    /// Whether analytics are enabled
    var analyticsEnabled: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    /// Whether crash reporting is enabled
    var crashReportingEnabled: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    // MARK: - Game Center Settings
    
    /// Whether Game Center features are enabled
    var gameCenterEnabled: Bool = true {
        didSet {
            if gameCenterEnabled {
                authenticateGameCenter()
            }
            saveSettings()
        }
    }
    
    /// Whether to show Game Center notifications
    var gameCenterNotifications: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    // MARK: - Computed Properties
    
    /// Whether settings have been modified from defaults
    var hasModifiedSettings: Bool {
        return !isDefaultConfiguration()
    }
    
    /// Current app version
    var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    /// Current build number
    var buildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// Game Center authentication status
    var isGameCenterAuthenticated: Bool {
        return gameCenterService.isAuthenticated
    }
    
    /// Player display name from Game Center
    var gameCenterPlayerName: String? {
        return gameCenterService.playerDisplayName
    }
    
    // MARK: - Dependencies
    
    private var audioService: AudioServiceProtocol
    private var physicsService: PhysicsServiceProtocol
    private let gameCenterService: GameCenterServiceProtocol
    private let modelContext: ModelContext
    
    // MARK: - Private Properties
    
    private let settingsKey = "gameSettings"
    private var isInitializing = false
    
    // MARK: - Initialization
    
    init(
        audioService: AudioServiceProtocol,
        physicsService: PhysicsServiceProtocol,
        gameCenterService: GameCenterServiceProtocol,
        modelContext: ModelContext
    ) {
        self.audioService = audioService
        self.physicsService = physicsService
        self.gameCenterService = gameCenterService
        self.modelContext = modelContext
        
        super.init()
    }
    
    // MARK: - Service Access Methods (for testing)
    
    /// Set the audio service (primarily for testing property mutability)
    func setAudioService(_ service: AudioServiceProtocol) {
        audioService = service
        applyAudioSettings()
    }
    
    /// Get the audio service (primarily for testing property mutability)
    func getAudioService() -> AudioServiceProtocol {
        return audioService
    }
    
    /// Set the physics service (primarily for testing property mutability)
    func setPhysicsService(_ service: PhysicsServiceProtocol) {
        physicsService = service
        applyPhysicsSettings()
    }
    
    /// Get the physics service (primarily for testing property mutability)
    func getPhysicsService() -> PhysicsServiceProtocol {
        return physicsService
    }
    
    // MARK: - BaseViewModel Overrides
    
    override func performInitialization() {
        isInitializing = true
        loadSettings()
        applySettings()
        isInitializing = false
    }
    
    override func handle(_ action: ViewAction) {
        switch action {
        case let settingAction as UpdateSettingAction:
            handleSettingUpdate(key: settingAction.key, value: settingAction.value)
        default:
            super.handle(action)
        }
    }
    
    // MARK: - Settings Management
    
    /// Reset all settings to their default values
    func resetToDefaults() {
        isInitializing = true
        
        // Audio settings
        soundVolume = 0.7
        musicVolume = 0.5
        soundEnabled = true
        musicEnabled = true
        
        // Gameplay settings
        controlSensitivity = 1.0
        showTutorialTips = true
        useHapticFeedback = true
        invertControls = false
        
        // Graphics settings
        highPerformanceMode = false
        particleEffectsEnabled = true
        graphicsQuality = .medium
        
        // Privacy settings
        analyticsEnabled = true
        crashReportingEnabled = true
        
        // Game Center settings
        gameCenterEnabled = true
        gameCenterNotifications = true
        
        isInitializing = false
        
        // Apply and save settings
        applySettings()
        saveSettings()
        
        // Play confirmation sound
        audioService.playSound("settings_reset", volume: nil, pitch: 1.0, completion: nil)
    }
    
    /// Export settings as a dictionary for backup
    func exportSettings() -> [String: Any] {
        return [
            "soundVolume": soundVolume,
            "musicVolume": musicVolume,
            "soundEnabled": soundEnabled,
            "musicEnabled": musicEnabled,
            "controlSensitivity": controlSensitivity,
            "showTutorialTips": showTutorialTips,
            "useHapticFeedback": useHapticFeedback,
            "invertControls": invertControls,
            "highPerformanceMode": highPerformanceMode,
            "particleEffectsEnabled": particleEffectsEnabled,
            "graphicsQuality": graphicsQuality.rawValue,
            "analyticsEnabled": analyticsEnabled,
            "crashReportingEnabled": crashReportingEnabled,
            "gameCenterEnabled": gameCenterEnabled,
            "gameCenterNotifications": gameCenterNotifications
        ]
    }
    
    /// Import settings from a dictionary
    /// - Parameter settings: Dictionary containing settings to import
    /// - Returns: Whether the import was successful
    func importSettings(_ settings: [String: Any]) -> Bool {
        isInitializing = true
        
        // Audio settings
        if let value = settings["soundVolume"] as? Double {
            soundVolume = max(0.0, min(1.0, value))
        }
        if let value = settings["musicVolume"] as? Double {
            musicVolume = max(0.0, min(1.0, value))
        }
        if let value = settings["soundEnabled"] as? Bool {
            soundEnabled = value
        }
        if let value = settings["musicEnabled"] as? Bool {
            musicEnabled = value
        }
        
        // Gameplay settings
        if let value = settings["controlSensitivity"] as? Double {
            controlSensitivity = max(0.5, min(1.5, value))
        }
        if let value = settings["showTutorialTips"] as? Bool {
            showTutorialTips = value
        }
        if let value = settings["useHapticFeedback"] as? Bool {
            useHapticFeedback = value
        }
        if let value = settings["invertControls"] as? Bool {
            invertControls = value
        }
        
        // Graphics settings
        if let value = settings["highPerformanceMode"] as? Bool {
            highPerformanceMode = value
        }
        if let value = settings["particleEffectsEnabled"] as? Bool {
            particleEffectsEnabled = value
        }
        if let value = settings["graphicsQuality"] as? String,
           let quality = GraphicsQuality(rawValue: value) {
            graphicsQuality = quality
        }
        
        // Privacy settings
        if let value = settings["analyticsEnabled"] as? Bool {
            analyticsEnabled = value
        }
        if let value = settings["crashReportingEnabled"] as? Bool {
            crashReportingEnabled = value
        }
        
        // Game Center settings
        if let value = settings["gameCenterEnabled"] as? Bool {
            gameCenterEnabled = value
        }
        if let value = settings["gameCenterNotifications"] as? Bool {
            gameCenterNotifications = value
        }
        
        isInitializing = false
        
        // Apply and save settings
        applySettings()
        saveSettings()
        
        return true
    }
    
    // MARK: - Game Center Methods
    
    /// Authenticate with Game Center
    func authenticateGameCenter() {
        guard gameCenterEnabled else { return }
        
        setLoading(true)
        
        gameCenterService.authenticate { [weak self] success, error in
            DispatchQueue.main.async {
                self?.setLoading(false)
                
                if let error = error {
                    self?.setError(error)
                } else if success {
                    // Play success sound
                    self?.audioService.playSound("game_center_connected", volume: nil, pitch: 1.0, completion: nil)
                }
            }
        }
    }
    
    /// Sign out from Game Center
    func signOutGameCenter() {
        gameCenterEnabled = false
        // Note: Actual Game Center sign out is handled by the system
        audioService.playSound("game_center_disconnected", volume: nil, pitch: 1.0, completion: nil)
    }
    
    // MARK: - Validation Methods
    
    /// Validate a setting value
    /// - Parameters:
    ///   - key: Setting key
    ///   - value: Value to validate
    /// - Returns: Whether the value is valid
    func validateSetting(key: String, value: Any) -> Bool {
        switch key {
        case "soundVolume", "musicVolume":
            guard let doubleValue = value as? Double else { return false }
            return doubleValue >= 0.0 && doubleValue <= 1.0
            
        case "controlSensitivity":
            guard let doubleValue = value as? Double else { return false }
            return doubleValue >= 0.5 && doubleValue <= 1.5
            
        case "graphicsQuality":
            guard let stringValue = value as? String else { return false }
            return GraphicsQuality(rawValue: stringValue) != nil
            
        case "soundEnabled", "musicEnabled", "showTutorialTips", "useHapticFeedback",
             "invertControls", "highPerformanceMode", "particleEffectsEnabled",
             "analyticsEnabled", "crashReportingEnabled", "gameCenterEnabled",
             "gameCenterNotifications":
            return value is Bool
            
        default:
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func handleSettingUpdate(key: String, value: Any) {
        guard validateSetting(key: key, value: value) else {
            setErrorMessage("Invalid value for setting: \(key)")
            return
        }
        
        switch key {
        case "soundVolume":
            soundVolume = value as! Double
        case "musicVolume":
            musicVolume = value as! Double
        case "soundEnabled":
            soundEnabled = value as! Bool
        case "musicEnabled":
            musicEnabled = value as! Bool
        case "controlSensitivity":
            controlSensitivity = value as! Double
        case "showTutorialTips":
            showTutorialTips = value as! Bool
        case "useHapticFeedback":
            useHapticFeedback = value as! Bool
        case "invertControls":
            invertControls = value as! Bool
        case "highPerformanceMode":
            highPerformanceMode = value as! Bool
        case "particleEffectsEnabled":
            particleEffectsEnabled = value as! Bool
        case "graphicsQuality":
            if let stringValue = value as? String,
               let quality = GraphicsQuality(rawValue: stringValue) {
                graphicsQuality = quality
            }
        case "analyticsEnabled":
            analyticsEnabled = value as! Bool
        case "crashReportingEnabled":
            crashReportingEnabled = value as! Bool
        case "gameCenterEnabled":
            gameCenterEnabled = value as! Bool
        case "gameCenterNotifications":
            gameCenterNotifications = value as! Bool
        default:
            setErrorMessage("Unknown setting: \(key)")
        }
    }
    
    private func loadSettings() {
        guard let settings = UserDefaults.standard.dictionary(forKey: settingsKey) else {
            // Use default values if no settings exist
            return
        }
        
        // Load settings without triggering didSet observers
        if let value = settings["soundVolume"] as? Double {
            soundVolume = value
        }
        if let value = settings["musicVolume"] as? Double {
            musicVolume = value
        }
        if let value = settings["soundEnabled"] as? Bool {
            soundEnabled = value
        }
        if let value = settings["musicEnabled"] as? Bool {
            musicEnabled = value
        }
        if let value = settings["controlSensitivity"] as? Double {
            controlSensitivity = value
        }
        if let value = settings["showTutorialTips"] as? Bool {
            showTutorialTips = value
        }
        if let value = settings["useHapticFeedback"] as? Bool {
            useHapticFeedback = value
        }
        if let value = settings["invertControls"] as? Bool {
            invertControls = value
        }
        if let value = settings["highPerformanceMode"] as? Bool {
            highPerformanceMode = value
        }
        if let value = settings["particleEffectsEnabled"] as? Bool {
            particleEffectsEnabled = value
        }
        if let value = settings["graphicsQuality"] as? String,
           let quality = GraphicsQuality(rawValue: value) {
            graphicsQuality = quality
        }
        if let value = settings["analyticsEnabled"] as? Bool {
            analyticsEnabled = value
        }
        if let value = settings["crashReportingEnabled"] as? Bool {
            crashReportingEnabled = value
        }
        if let value = settings["gameCenterEnabled"] as? Bool {
            gameCenterEnabled = value
        }
        if let value = settings["gameCenterNotifications"] as? Bool {
            gameCenterNotifications = value
        }
    }
    
    private func saveSettings() {
        guard !isInitializing else { return }
        
        let settings = exportSettings()
        UserDefaults.standard.set(settings, forKey: settingsKey)
    }
    
    private func applySettings() {
        applyAudioSettings()
        applyPhysicsSettings()
        
        // Apply graphics settings
        updatePerformanceSettings()
        updateGraphicsSettings()
        
        // Apply Game Center settings
        if gameCenterEnabled && !isGameCenterAuthenticated {
            authenticateGameCenter()
        }
    }
    
    private func applyAudioSettings() {
        // Apply audio settings
        audioService.soundVolume = Float(soundVolume)
        audioService.musicVolume = Float(musicVolume)
        audioService.soundEnabled = soundEnabled
        audioService.musicEnabled = musicEnabled
    }
    
    private func applyPhysicsSettings() {
        // Apply physics settings
        physicsService.sensitivity = CGFloat(controlSensitivity)
    }
    
    private func updatePerformanceSettings() {
        // Performance settings would be applied to the game engine
        // This is a placeholder for actual implementation
    }
    
    private func updateGraphicsSettings() {
        // Graphics settings would be applied to the rendering system
        // This is a placeholder for actual implementation
    }
    
    private func isDefaultConfiguration() -> Bool {
        return soundVolume == 0.7 &&
               musicVolume == 0.5 &&
               soundEnabled == true &&
               musicEnabled == true &&
               controlSensitivity == 1.0 &&
               showTutorialTips == true &&
               useHapticFeedback == true &&
               invertControls == false &&
               highPerformanceMode == false &&
               particleEffectsEnabled == true &&
               graphicsQuality == .medium &&
               analyticsEnabled == true &&
               crashReportingEnabled == true &&
               gameCenterEnabled == true &&
               gameCenterNotifications == true
    }
}

// MARK: - Supporting Types

/// Graphics quality levels
enum GraphicsQuality: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case ultra = "ultra"
    
    var displayName: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        case .ultra:
            return "Ultra"
        }
    }
    
    var description: String {
        switch self {
        case .low:
            return "Optimized for battery life"
        case .medium:
            return "Balanced performance and quality"
        case .high:
            return "Enhanced visual effects"
        case .ultra:
            return "Maximum visual quality"
        }
    }
}

// MARK: - Rating and Feedback Extension

extension SettingsViewModel {
    
    // MARK: - Rating Methods
    
    /// Show app rating prompt
    func showRatingPrompt() {
        AppRatingManager.shared.promptForRatingManually()
        
        // Track in analytics
        AnalyticsManager.shared.trackEvent(.settingsChanged(setting: "rating_prompt", value: "manual"))
        
        // Play confirmation sound
        audioService.playSound("button_tap", volume: nil, pitch: 1.0, completion: nil)
    }
    
    /// Get rating statistics for display
    var ratingStatistics: RatingStatistics {
        return AppRatingManager.shared.getRatingStatistics()
    }
    
    /// Whether the user has already rated the app
    var hasUserRatedApp: Bool {
        return AppRatingManager.shared.hasUserRatedApp
    }
    
    // MARK: - Feedback Methods
    
    /// Show feedback options
    func showFeedbackOptions() {
        UserFeedbackManager.shared.showFeedbackOptions()
        
        // Track in analytics
        AnalyticsManager.shared.trackEvent(.settingsChanged(setting: "feedback_options", value: "shown"))
        
        // Play confirmation sound
        audioService.playSound("button_tap", volume: nil, pitch: 1.0, completion: nil)
    }
    
    /// Show bug report form
    func reportBug() {
        UserFeedbackManager.shared.showBugReportForm()
        
        // Track in analytics
        AnalyticsManager.shared.trackEvent(.settingsChanged(setting: "bug_report", value: "shown"))
        
        // Play confirmation sound
        audioService.playSound("button_tap", volume: nil, pitch: 1.0, completion: nil)
    }
    
    /// Show feature request form
    func requestFeature() {
        UserFeedbackManager.shared.showFeatureRequestForm()
        
        // Track in analytics
        AnalyticsManager.shared.trackEvent(.settingsChanged(setting: "feature_request", value: "shown"))
        
        // Play confirmation sound
        audioService.playSound("button_tap", volume: nil, pitch: 1.0, completion: nil)
    }
    
    /// Show general feedback form
    func sendFeedback() {
        UserFeedbackManager.shared.showGeneralFeedbackForm()
        
        // Track in analytics
        AnalyticsManager.shared.trackEvent(.settingsChanged(setting: "general_feedback", value: "shown"))
        
        // Play confirmation sound
        audioService.playSound("button_tap", volume: nil, pitch: 1.0, completion: nil)
    }
    
    /// Show support contact form
    func contactSupport() {
        UserFeedbackManager.shared.showSupportContactForm()
        
        // Track in analytics
        AnalyticsManager.shared.trackEvent(.settingsChanged(setting: "support_contact", value: "shown"))
        
        // Play confirmation sound
        audioService.playSound("button_tap", volume: nil, pitch: 1.0, completion: nil)
    }
    
    /// Get feedback statistics for display
    var feedbackStatistics: FeedbackStatistics {
        return UserFeedbackManager.shared.getFeedbackStatistics()
    }
    
    /// Whether the user can send feedback (not rate limited)
    var canSendFeedback: Bool {
        return UserFeedbackManager.shared.canSendFeedback()
    }
    
    // MARK: - Support Information
    
    /// Get support email address
    var supportEmail: String {
        return "support@tinypilots.com"
    }
    
    /// Get feedback email address
    var feedbackEmail: String {
        return "feedback@tinypilots.com"
    }
    
    /// Get app store URL for rating
    var appStoreURL: String {
        return "https://apps.apple.com/app/tiny-pilots/id[APP_ID]" // Replace with actual App Store ID
    }
    
    /// Get privacy policy URL
    var privacyPolicyURL: String {
        return "https://tinypilots.com/privacy"
    }
    
    /// Get terms of service URL
    var termsOfServiceURL: String {
        return "https://tinypilots.com/terms"
    }
}

// MARK: - Release Management Extension

extension SettingsViewModel {
    
    // MARK: - Release Notes Methods
    
    /// Show release notes for current version
    func showReleaseNotes() {
        ReleaseNotesManager.shared.showReleaseNotesManually()
        
        // Track in analytics
        AnalyticsManager.shared.trackEvent(.settingsChanged(setting: "release_notes", value: "manual_view"))
        
        // Play confirmation sound
        audioService.playSound("button_tap", volume: nil, pitch: 1.0, completion: nil)
    }
    
    /// Get current app version
    var currentVersion: String {
        return ReleaseNotesManager.shared.getCurrentVersion()
    }
    
    /// Get current build number
    var currentBuildNumber: String {
        return ReleaseNotesManager.shared.getCurrentBuildNumber()
    }
    
    /// Get full version string
    var fullVersionString: String {
        return ReleaseNotesManager.shared.getFullVersionString()
    }
    
    /// Whether release notes are available for current version
    var hasReleaseNotes: Bool {
        let releaseNotes = ReleaseNotesManager.shared.getReleaseNotes(for: currentVersion)
        return !releaseNotes.isEmpty
    }
    
    // MARK: - Feature Flag Methods
    
    /// Check if a feature flag is enabled
    func isFeatureEnabled(_ feature: FeatureFlag) -> Bool {
        return FeatureFlagManager.shared.isFeatureEnabled(feature)
    }
    
    /// Get all active feature flags (for debug menu)
    var activeFeatureFlags: [String: Any] {
        return FeatureFlagManager.shared.getAllActiveFlags()
    }
    
    /// Toggle a feature flag (debug only)
    func toggleFeatureFlag(_ feature: FeatureFlag) {
        #if DEBUG
        let currentValue = FeatureFlagManager.shared.isFeatureEnabled(feature)
        FeatureFlagManager.shared.setLocalFeatureFlag(feature, enabled: !currentValue)
        
        // Track in analytics
        AnalyticsManager.shared.trackEvent(.settingsChanged(setting: "feature_flag_toggle", value: "\(feature.rawValue):\(!currentValue)"))
        
        // Play confirmation sound
        audioService.playSound("button_tap", volume: nil, pitch: 1.0, completion: nil)
        
        Logger.shared.info("Feature flag toggled: \(feature.rawValue) = \(!currentValue)", category: .app)
        #else
        Logger.shared.warning("Feature flag toggle not available in non-debug build", category: .app)
        #endif
    }
    
    /// Reset all feature flag overrides (debug only)
    func resetFeatureFlags() {
        #if DEBUG
        FeatureFlagManager.shared.resetLocalOverrides()
        
        // Track in analytics
        AnalyticsManager.shared.trackEvent(.settingsChanged(setting: "feature_flags", value: "reset"))
        
        // Play confirmation sound
        audioService.playSound("settings_reset", volume: nil, pitch: 1.0, completion: nil)
        
        Logger.shared.info("All feature flag overrides reset", category: .app)
        #else
        Logger.shared.warning("Feature flag reset not available in non-debug build", category: .app)
        #endif
    }
    
    // MARK: - Rollout Status Methods
    
    /// Get rollout status for all features
    var rolloutStatuses: [RolloutStatus] {
        return StagedRolloutManager.shared.getAllRolloutStatuses()
    }
    
    /// Get user's rollout group
    var userRolloutGroup: Int {
        return StagedRolloutManager.shared.debugRolloutGroup
    }
    
    /// Check if a feature is rolled out for the current user
    func isFeatureRolledOut(_ featureKey: String) -> Bool {
        return StagedRolloutManager.shared.isFeatureRolledOut(featureKey)
    }
    
    /// Get rollout status for a specific feature
    func getRolloutStatus(_ featureKey: String) -> RolloutStatus? {
        return StagedRolloutManager.shared.getRolloutStatus(featureKey)
    }
    
    // MARK: - Debug Information
    
    /// Whether debug features should be shown
    var shouldShowDebugFeatures: Bool {
        #if DEBUG
        return true
        #else
        return AppConfiguration.current.isDebugMode
        #endif
    }
    
    /// Get debug information summary
    var debugInformation: [String: Any] {
        var info: [String: Any] = [:]
        
        // App information
        info["app_version"] = currentVersion
        info["build_number"] = currentBuildNumber
        info["environment"] = AppConfiguration.current.environment.rawValue
        
        // Feature flags
        info["active_feature_flags"] = activeFeatureFlags
        
        // Rollout information
        info["rollout_group"] = userRolloutGroup
        info["rollout_statuses"] = rolloutStatuses.map { status in
            [
                "feature": status.featureKey,
                "percentage": status.percentage,
                "user_included": status.isUserIncluded,
                "status": status.statusDescription
            ]
        }
        
        // Rating information
        info["rating_statistics"] = [
            "has_rated": ratingStatistics.hasRated,
            "prompt_count": ratingStatistics.promptCount,
            "game_sessions": ratingStatistics.gameSessionCount,
            "significant_events": ratingStatistics.significantEventsCount,
            "days_since_first_launch": ratingStatistics.daysSinceFirstLaunch
        ]
        
        // Feedback information
        info["feedback_statistics"] = [
            "total_feedback": feedbackStatistics.totalFeedbackCount,
            "can_send_feedback": feedbackStatistics.canSendFeedback
        ]
        
        return info
    }
    
    /// Export debug information as string
    func exportDebugInformation() -> String {
        let info = debugInformation
        
        var output = "=== Tiny Pilots Debug Information ===\n\n"
        
        for (key, value) in info.sorted(by: { $0.key < $1.key }) {
            output += "\(key.uppercased()):\n"
            
            if let dict = value as? [String: Any] {
                for (subKey, subValue) in dict.sorted(by: { $0.key < $1.key }) {
                    output += "  \(subKey): \(subValue)\n"
                }
            } else if let array = value as? [[String: Any]] {
                for (index, item) in array.enumerated() {
                    output += "  [\(index)]:\n"
                    for (subKey, subValue) in item.sorted(by: { $0.key < $1.key }) {
                        output += "    \(subKey): \(subValue)\n"
                    }
                }
            } else {
                output += "  \(value)\n"
            }
            
            output += "\n"
        }
        
        output += "Generated: \(Date())\n"
        
        return output
    }
    
    /// Copy debug information to clipboard
    func copyDebugInformation() {
        let debugInfo = exportDebugInformation()
        UIPasteboard.general.string = debugInfo
        
        // Track in analytics
        AnalyticsManager.shared.trackEvent(.settingsChanged(setting: "debug_info", value: "copied"))
        
        // Play confirmation sound
        audioService.playSound("button_tap", volume: nil, pitch: 1.0, completion: nil)
        
        Logger.shared.info("Debug information copied to clipboard", category: .app)
    }
}