import Foundation

/// Manages feature flags for gradual rollouts and A/B testing
class FeatureFlagManager {
    static let shared = FeatureFlagManager()
    
    // MARK: - Properties
    
    private let userDefaults = UserDefaults.standard
    private let featureFlagsKey = "feature_flags"
    private let userGroupKey = "user_group"
    private let abTestGroupsKey = "ab_test_groups"
    
    // Local feature flags (can be overridden by remote config)
    private var localFlags: [String: Any] = [:]
    
    // Remote feature flags (from server)
    private var remoteFlags: [String: Any] = [:]
    
    // A/B test configurations
    private var abTestConfigs: [String: ABTestConfig] = [:]
    
    // User's assigned groups
    private var userGroups: [String: String] = [:]
    
    // MARK: - Initialization
    
    private init() {
        loadLocalFlags()
        loadUserGroups()
        setupDefaultFlags()
    }
    
    // MARK: - Public Interface
    
    /// Check if a feature is enabled
    func isFeatureEnabled(_ feature: FeatureFlag) -> Bool {
        return isFeatureEnabled(feature.rawValue)
    }
    
    /// Check if a feature is enabled by string key
    func isFeatureEnabled(_ featureKey: String) -> Bool {
        // Check remote flags first (they override local)
        if let remoteValue = remoteFlags[featureKey] as? Bool {
            return remoteValue
        }
        
        // Check local flags
        if let localValue = localFlags[featureKey] as? Bool {
            return localValue
        }
        
        // Check if this is an A/B test
        if let abTestConfig = abTestConfigs[featureKey] {
            return evaluateABTest(abTestConfig)
        }
        
        // Default to false for unknown features
        return false
    }
    
    /// Get feature flag value with type safety
    func getFeatureValue<T>(_ feature: FeatureFlag, defaultValue: T) -> T {
        return getFeatureValue(feature.rawValue, defaultValue: defaultValue)
    }
    
    /// Get feature flag value by string key with type safety
    func getFeatureValue<T>(_ featureKey: String, defaultValue: T) -> T {
        // Check remote flags first
        if let remoteValue = remoteFlags[featureKey] as? T {
            return remoteValue
        }
        
        // Check local flags
        if let localValue = localFlags[featureKey] as? T {
            return localValue
        }
        
        return defaultValue
    }
    
    /// Set a local feature flag (for testing/debugging)
    func setLocalFeatureFlag(_ feature: FeatureFlag, enabled: Bool) {
        setLocalFeatureFlag(feature.rawValue, enabled: enabled)
    }
    
    /// Set a local feature flag by string key
    func setLocalFeatureFlag(_ featureKey: String, enabled: Bool) {
        localFlags[featureKey] = enabled
        saveLocalFlags()
        
        Logger.shared.info("Local feature flag set: \(featureKey) = \(enabled)", category: .app)
        
        // Notify observers
        NotificationCenter.default.post(
            name: .featureFlagChanged,
            object: nil,
            userInfo: ["feature": featureKey, "enabled": enabled]
        )
    }
    
    /// Update remote feature flags (typically called from network service)
    func updateRemoteFlags(_ flags: [String: Any]) {
        remoteFlags = flags
        
        Logger.shared.info("Remote feature flags updated: \(flags.keys.joined(separator: ", "))", category: .app)
        
        // Notify observers
        NotificationCenter.default.post(
            name: .remoteFeatureFlagsUpdated,
            object: nil,
            userInfo: ["flags": flags]
        )
    }
    
    /// Configure A/B test
    func configureABTest(_ config: ABTestConfig) {
        abTestConfigs[config.featureKey] = config
        
        // Assign user to group if not already assigned
        if userGroups[config.featureKey] == nil {
            let group = assignUserToABTestGroup(config)
            userGroups[config.featureKey] = group
            saveUserGroups()
            
            Logger.shared.info("User assigned to A/B test group: \(config.featureKey) = \(group)", category: .app)
            
            // Track in analytics
            AnalyticsManager.shared.trackEvent(.abTestAssigned(test: config.featureKey, group: group))
        }
    }
    
    /// Get user's A/B test group for a feature
    func getABTestGroup(_ featureKey: String) -> String? {
        return userGroups[featureKey]
    }
    
    /// Get all active feature flags for debugging
    func getAllActiveFlags() -> [String: Any] {
        var allFlags: [String: Any] = [:]
        
        // Start with local flags
        allFlags.merge(localFlags) { _, new in new }
        
        // Override with remote flags
        allFlags.merge(remoteFlags) { _, new in new }
        
        // Add A/B test results
        for (key, config) in abTestConfigs {
            allFlags[key] = evaluateABTest(config)
        }
        
        return allFlags
    }
    
    /// Reset all local overrides (for testing)
    func resetLocalOverrides() {
        localFlags.removeAll()
        saveLocalFlags()
        
        Logger.shared.info("All local feature flag overrides reset", category: .app)
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultFlags() {
        // Set default values for all feature flags
        let defaults: [String: Any] = [
            FeatureFlag.newGameModes.rawValue: false,
            FeatureFlag.enhancedGraphics.rawValue: false,
            FeatureFlag.socialSharing.rawValue: true,
            FeatureFlag.advancedAnalytics.rawValue: false,
            FeatureFlag.premiumFeatures.rawValue: false,
            FeatureFlag.betaFeatures.rawValue: false,
            FeatureFlag.experimentalPhysics.rawValue: false,
            FeatureFlag.newUI.rawValue: false,
            FeatureFlag.cloudSync.rawValue: false,
            FeatureFlag.multiplayerMode.rawValue: false
        ]
        
        // Only set defaults for flags that don't already have values
        for (key, value) in defaults {
            if localFlags[key] == nil && remoteFlags[key] == nil {
                localFlags[key] = value
            }
        }
        
        saveLocalFlags()
    }
    
    private func loadLocalFlags() {
        if let flags = userDefaults.dictionary(forKey: featureFlagsKey) {
            localFlags = flags
        }
    }
    
    private func saveLocalFlags() {
        userDefaults.set(localFlags, forKey: featureFlagsKey)
    }
    
    private func loadUserGroups() {
        if let groups = userDefaults.dictionary(forKey: abTestGroupsKey) as? [String: String] {
            userGroups = groups
        }
    }
    
    private func saveUserGroups() {
        userDefaults.set(userGroups, forKey: abTestGroupsKey)
    }
    
    private func evaluateABTest(_ config: ABTestConfig) -> Bool {
        guard let userGroup = userGroups[config.featureKey] else {
            return false
        }
        
        return config.enabledGroups.contains(userGroup)
    }
    
    private func assignUserToABTestGroup(_ config: ABTestConfig) -> String {
        // Use a deterministic hash based on user identifier and test name
        let userIdentifier = getUserIdentifier()
        let hashInput = "\(userIdentifier)_\(config.featureKey)"
        let hash = hashInput.hash
        
        // Convert hash to a percentage (0-99)
        let percentage = abs(hash) % 100
        
        // Assign to group based on traffic allocation
        var cumulativePercentage = 0
        for (group, allocation) in config.trafficAllocation {
            cumulativePercentage += allocation
            if percentage < cumulativePercentage {
                return group
            }
        }
        
        // Fallback to control group
        return "control"
    }
    
    private func getUserIdentifier() -> String {
        // Try to get a stable user identifier
        if let identifier = userDefaults.string(forKey: userGroupKey) {
            return identifier
        }
        
        // Generate a new identifier
        let identifier = UUID().uuidString
        userDefaults.set(identifier, forKey: userGroupKey)
        return identifier
    }
}

// MARK: - Supporting Types

/// Feature flags enum for type safety
enum FeatureFlag: String, CaseIterable {
    case newGameModes = "new_game_modes"
    case enhancedGraphics = "enhanced_graphics"
    case socialSharing = "social_sharing"
    case advancedAnalytics = "advanced_analytics"
    case premiumFeatures = "premium_features"
    case betaFeatures = "beta_features"
    case experimentalPhysics = "experimental_physics"
    case newUI = "new_ui"
    case cloudSync = "cloud_sync"
    case multiplayerMode = "multiplayer_mode"
    
    var displayName: String {
        switch self {
        case .newGameModes:
            return "New Game Modes"
        case .enhancedGraphics:
            return "Enhanced Graphics"
        case .socialSharing:
            return "Social Sharing"
        case .advancedAnalytics:
            return "Advanced Analytics"
        case .premiumFeatures:
            return "Premium Features"
        case .betaFeatures:
            return "Beta Features"
        case .experimentalPhysics:
            return "Experimental Physics"
        case .newUI:
            return "New UI"
        case .cloudSync:
            return "Cloud Sync"
        case .multiplayerMode:
            return "Multiplayer Mode"
        }
    }
    
    var description: String {
        switch self {
        case .newGameModes:
            return "Access to new game modes and challenges"
        case .enhancedGraphics:
            return "Improved visual effects and rendering"
        case .socialSharing:
            return "Share achievements and scores on social media"
        case .advancedAnalytics:
            return "Detailed gameplay analytics and insights"
        case .premiumFeatures:
            return "Premium content and features"
        case .betaFeatures:
            return "Early access to beta features"
        case .experimentalPhysics:
            return "Experimental physics engine improvements"
        case .newUI:
            return "Updated user interface design"
        case .cloudSync:
            return "Synchronize progress across devices"
        case .multiplayerMode:
            return "Play with friends in multiplayer mode"
        }
    }
}

/// A/B test configuration
struct ABTestConfig {
    let featureKey: String
    let testName: String
    let enabledGroups: Set<String>
    let trafficAllocation: [String: Int] // Group name to percentage
    let startDate: Date
    let endDate: Date?
    
    var isActive: Bool {
        let now = Date()
        if now < startDate {
            return false
        }
        if let endDate = endDate, now > endDate {
            return false
        }
        return true
    }
    
    static func createSimpleABTest(
        featureKey: String,
        testName: String,
        controlPercentage: Int = 50,
        treatmentPercentage: Int = 50,
        startDate: Date = Date(),
        endDate: Date? = nil
    ) -> ABTestConfig {
        return ABTestConfig(
            featureKey: featureKey,
            testName: testName,
            enabledGroups: ["treatment"],
            trafficAllocation: [
                "control": controlPercentage,
                "treatment": treatmentPercentage
            ],
            startDate: startDate,
            endDate: endDate
        )
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let featureFlagChanged = Notification.Name("FeatureFlagChanged")
    static let remoteFeatureFlagsUpdated = Notification.Name("RemoteFeatureFlagsUpdated")
}

// MARK: - Analytics Extensions

extension AnalyticsEvent {
    static func abTestAssigned(test: String, group: String) -> AnalyticsEvent {
        return .settingsChanged(setting: "ab_test_assigned", value: "\(test):\(group)")
    }
}