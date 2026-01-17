import Foundation
import UIKit

/// Manages staged rollouts and gradual feature releases
class StagedRolloutManager {
    static let shared = StagedRolloutManager()
    
    // MARK: - Properties
    
    private let userDefaults = UserDefaults.standard
    private let rolloutGroupKey = "rollout_group"
    private let rolloutConfigKey = "rollout_config"
    
    // Rollout configurations
    private var rolloutConfigs: [String: RolloutConfig] = [:]
    
    // User's rollout group (0-99)
    private let userRolloutGroup: Int
    
    // MARK: - Initialization
    
    private init() {
        // Assign user to a consistent rollout group (0-99)
        if let savedGroup = userDefaults.object(forKey: rolloutGroupKey) as? Int {
            userRolloutGroup = savedGroup
        } else {
            // Generate deterministic group based on device identifier
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            let hash = abs(deviceId.hash)
            userRolloutGroup = hash % 100
            userDefaults.set(userRolloutGroup, forKey: rolloutGroupKey)
        }
        
        setupDefaultRollouts()
        
        Logger.shared.info("User assigned to rollout group: \(userRolloutGroup)", category: .app)
    }
    
    // MARK: - Public Interface
    
    /// Check if a feature is enabled for the current user based on rollout percentage
    func isFeatureRolledOut(_ featureKey: String) -> Bool {
        guard let config = rolloutConfigs[featureKey] else {
            return false
        }
        
        return isUserInRollout(config)
    }
    
    /// Configure a staged rollout for a feature
    func configureRollout(_ config: RolloutConfig) {
        rolloutConfigs[config.featureKey] = config
        saveRolloutConfigs()
        
        Logger.shared.info("Rollout configured: \(config.featureKey) at \(config.percentage)%", category: .app)
        
        // Track rollout configuration
        AnalyticsManager.shared.trackEvent(.rolloutConfigured(
            feature: config.featureKey,
            percentage: config.percentage,
            userIncluded: isUserInRollout(config)
        ))
    }
    
    /// Update rollout percentage for a feature
    func updateRolloutPercentage(_ featureKey: String, percentage: Int) {
        guard var config = rolloutConfigs[featureKey] else {
            Logger.shared.warning("Attempted to update rollout for unknown feature: \(featureKey)", category: .app)
            return
        }
        
        let oldPercentage = config.percentage
        config.percentage = max(0, min(100, percentage))
        rolloutConfigs[featureKey] = config
        saveRolloutConfigs()
        
        Logger.shared.info("Rollout percentage updated: \(featureKey) from \(oldPercentage)% to \(config.percentage)%", category: .app)
        
        // Track rollout update
        AnalyticsManager.shared.trackEvent(.rolloutUpdated(
            feature: featureKey,
            oldPercentage: oldPercentage,
            newPercentage: config.percentage,
            userIncluded: isUserInRollout(config)
        ))
    }
    
    /// Enable feature for all users (100% rollout)
    func enableFeatureForAll(_ featureKey: String) {
        updateRolloutPercentage(featureKey, percentage: 100)
    }
    
    /// Disable feature for all users (0% rollout)
    func disableFeatureForAll(_ featureKey: String) {
        updateRolloutPercentage(featureKey, percentage: 0)
    }
    
    /// Get rollout status for a feature
    func getRolloutStatus(_ featureKey: String) -> RolloutStatus? {
        guard let config = rolloutConfigs[featureKey] else {
            return nil
        }
        
        return RolloutStatus(
            featureKey: featureKey,
            percentage: config.percentage,
            isUserIncluded: isUserInRollout(config),
            userGroup: userRolloutGroup,
            startDate: config.startDate,
            endDate: config.endDate,
            isActive: config.isActive
        )
    }
    
    /// Get all rollout statuses
    func getAllRolloutStatuses() -> [RolloutStatus] {
        return rolloutConfigs.compactMap { (key, _) in
            getRolloutStatus(key)
        }
    }
    
    /// Remove rollout configuration (feature becomes permanently enabled/disabled)
    func removeRollout(_ featureKey: String) {
        rolloutConfigs.removeValue(forKey: featureKey)
        saveRolloutConfigs()
        
        Logger.shared.info("Rollout configuration removed: \(featureKey)", category: .app)
    }
    
    /// Get user's rollout group for debugging
    var debugRolloutGroup: Int {
        return userRolloutGroup
    }
    
    /// Force user into a specific rollout group (for testing only)
    func setTestRolloutGroup(_ group: Int) {
        #if DEBUG
        let clampedGroup = max(0, min(99, group))
        userDefaults.set(clampedGroup, forKey: rolloutGroupKey)
        Logger.shared.warning("Rollout group forced to \(clampedGroup) for testing", category: .app)
        #else
        Logger.shared.warning("Cannot set test rollout group in non-debug build", category: .app)
        #endif
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultRollouts() {
        // Configure default rollouts for new features
        let defaultRollouts: [RolloutConfig] = [
            RolloutConfig(
                featureKey: "enhanced_graphics_v2",
                percentage: 10,
                startDate: Date(),
                endDate: nil,
                targetGroups: nil
            ),
            RolloutConfig(
                featureKey: "new_physics_engine",
                percentage: 5,
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
                targetGroups: nil
            ),
            RolloutConfig(
                featureKey: "social_features",
                percentage: 25,
                startDate: Date(),
                endDate: nil,
                targetGroups: nil
            )
        ]
        
        for config in defaultRollouts {
            if rolloutConfigs[config.featureKey] == nil {
                rolloutConfigs[config.featureKey] = config
            }
        }
        
        saveRolloutConfigs()
    }
    
    private func isUserInRollout(_ config: RolloutConfig) -> Bool {
        // Check if rollout is active
        guard config.isActive else {
            return false
        }
        
        // Check target groups if specified
        if let targetGroups = config.targetGroups {
            return targetGroups.contains(userRolloutGroup)
        }
        
        // Check percentage-based rollout
        return userRolloutGroup < config.percentage
    }
    
    private func saveRolloutConfigs() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(Array(rolloutConfigs.values))
            userDefaults.set(data, forKey: rolloutConfigKey)
        } catch {
            Logger.shared.error("Failed to save rollout configs", error: error, category: .app)
        }
    }
    
    private func loadRolloutConfigs() {
        guard let data = userDefaults.data(forKey: rolloutConfigKey) else {
            return
        }
        
        let decoder = JSONDecoder()
        do {
            let configs = try decoder.decode([RolloutConfig].self, from: data)
            rolloutConfigs = Dictionary(uniqueKeysWithValues: configs.map { ($0.featureKey, $0) })
        } catch {
            Logger.shared.error("Failed to load rollout configs", error: error, category: .app)
        }
    }
}

// MARK: - Supporting Types

struct RolloutConfig: Codable {
    let featureKey: String
    var percentage: Int // 0-100
    let startDate: Date
    let endDate: Date?
    let targetGroups: Set<Int>? // Specific user groups to target
    
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
    
    init(
        featureKey: String,
        percentage: Int,
        startDate: Date = Date(),
        endDate: Date? = nil,
        targetGroups: Set<Int>? = nil
    ) {
        self.featureKey = featureKey
        self.percentage = max(0, min(100, percentage))
        self.startDate = startDate
        self.endDate = endDate
        self.targetGroups = targetGroups
    }
}

struct RolloutStatus {
    let featureKey: String
    let percentage: Int
    let isUserIncluded: Bool
    let userGroup: Int
    let startDate: Date
    let endDate: Date?
    let isActive: Bool
    
    var statusDescription: String {
        if !isActive {
            return "Inactive"
        } else if percentage == 0 {
            return "Disabled"
        } else if percentage == 100 {
            return "Fully Rolled Out"
        } else {
            return "Rolling Out (\(percentage)%)"
        }
    }
    
    var userStatusDescription: String {
        if !isActive {
            return "Feature inactive"
        } else if isUserIncluded {
            return "Enabled for you"
        } else {
            return "Not enabled for you"
        }
    }
}

// MARK: - Rollout Strategies

extension StagedRolloutManager {
    
    /// Gradually increase rollout percentage over time
    func scheduleGradualRollout(
        featureKey: String,
        startPercentage: Int = 1,
        endPercentage: Int = 100,
        durationDays: Int = 7
    ) {
        let config = RolloutConfig(
            featureKey: featureKey,
            percentage: startPercentage,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: durationDays, to: Date())
        )
        
        configureRollout(config)
        
        // Schedule percentage increases
        let steps = min(durationDays, endPercentage - startPercentage)
        let percentageIncrement = (endPercentage - startPercentage) / steps
        
        for step in 1...steps {
            let delay = TimeInterval(step * 24 * 60 * 60) // Days to seconds
            let targetPercentage = startPercentage + (percentageIncrement * step)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.updateRolloutPercentage(featureKey, percentage: targetPercentage)
            }
        }
        
        Logger.shared.info("Scheduled gradual rollout: \(featureKey) from \(startPercentage)% to \(endPercentage)% over \(durationDays) days", category: .app)
    }
    
    /// Canary rollout - enable for a small percentage first
    func startCanaryRollout(featureKey: String, canaryPercentage: Int = 1) {
        let config = RolloutConfig(
            featureKey: featureKey,
            percentage: canaryPercentage,
            startDate: Date(),
            endDate: nil
        )
        
        configureRollout(config)
        
        Logger.shared.info("Started canary rollout: \(featureKey) at \(canaryPercentage)%", category: .app)
    }
    
    /// Blue-green rollout - enable for specific user groups
    func startBlueGreenRollout(featureKey: String, targetGroups: Set<Int>) {
        let config = RolloutConfig(
            featureKey: featureKey,
            percentage: 100, // 100% for targeted groups
            startDate: Date(),
            endDate: nil,
            targetGroups: targetGroups
        )
        
        configureRollout(config)
        
        Logger.shared.info("Started blue-green rollout: \(featureKey) for groups \(targetGroups)", category: .app)
    }
}

// MARK: - Analytics Extensions

extension AnalyticsEvent {
    static func rolloutConfigured(feature: String, percentage: Int, userIncluded: Bool) -> AnalyticsEvent {
        return .settingsChanged(setting: "rollout_configured", value: "\(feature):\(percentage):\(userIncluded)")
    }
    
    static func rolloutUpdated(feature: String, oldPercentage: Int, newPercentage: Int, userIncluded: Bool) -> AnalyticsEvent {
        return .settingsChanged(setting: "rollout_updated", value: "\(feature):\(oldPercentage)→\(newPercentage):\(userIncluded)")
    }
}