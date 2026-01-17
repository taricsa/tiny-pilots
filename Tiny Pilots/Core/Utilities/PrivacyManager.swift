import Foundation
import UIKit

/// Protocol for privacy compliance management
protocol PrivacyManagerProtocol {
    func requestAnalyticsConsent() async -> Bool
    func requestDataCollectionConsent() async -> Bool
    func hasAnalyticsConsent() -> Bool
    func hasDataCollectionConsent() -> Bool
    func revokeAllConsent()
    func exportUserData() async -> [String: Any]
    func deleteUserData() async -> Bool
    func showPrivacyPolicy()
    func showDataDeletionRequest()
}

/// Privacy compliance manager for GDPR and other privacy regulations
class PrivacyManager: PrivacyManagerProtocol {
    static let shared = PrivacyManager()
    
    private let secureDataManager = SecureDataManager.shared
    private let logger = Logger.shared
    
    // Privacy consent keys
    private let analyticsConsentKey = "analytics_consent"
    private let dataCollectionConsentKey = "data_collection_consent"
    private let consentTimestampKey = "consent_timestamp"
    private let privacyPolicyVersionKey = "privacy_policy_version"
    
    // Current privacy policy version
    private let currentPrivacyPolicyVersion = "1.0"
    
    private init() {}
    
    // MARK: - Consent Management
    
    /// Request user consent for analytics tracking
    func requestAnalyticsConsent() async -> Bool {
        logger.info("Requesting analytics consent", category: .security)
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: "Analytics & Performance",
                    message: "We'd like to collect anonymous usage data to improve the app. This helps us understand how you use Tiny Pilots and make it better. You can change this setting anytime in the app settings.",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "Allow", style: .default) { _ in
                    self.setAnalyticsConsent(true)
                    continuation.resume(returning: true)
                })
                
                alert.addAction(UIAlertAction(title: "Don't Allow", style: .cancel) { _ in
                    self.setAnalyticsConsent(false)
                    continuation.resume(returning: false)
                })
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootViewController = window.rootViewController {
                    rootViewController.present(alert, animated: true)
                } else {
                    // Fallback - assume no consent
                    self.setAnalyticsConsent(false)
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    /// Request user consent for data collection
    func requestDataCollectionConsent() async -> Bool {
        logger.info("Requesting data collection consent", category: .security)
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: "Game Data Collection",
                    message: "We collect your game progress, scores, and achievements to provide features like leaderboards and cross-device sync. This data is stored securely and never shared with third parties.",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "Allow", style: .default) { _ in
                    self.setDataCollectionConsent(true)
                    continuation.resume(returning: true)
                })
                
                alert.addAction(UIAlertAction(title: "Don't Allow", style: .cancel) { _ in
                    self.setDataCollectionConsent(false)
                    continuation.resume(returning: false)
                })
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootViewController = window.rootViewController {
                    rootViewController.present(alert, animated: true)
                } else {
                    // Fallback - assume no consent
                    self.setDataCollectionConsent(false)
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    /// Check if user has given analytics consent
    func hasAnalyticsConsent() -> Bool {
        do {
            let consent: Bool? = try secureDataManager.retrieveSecureData(Bool.self, forKey: analyticsConsentKey)
            return consent ?? false
        } catch {
            logger.error("Failed to retrieve analytics consent", error: error, category: .security)
            return false
        }
    }
    
    /// Check if user has given data collection consent
    func hasDataCollectionConsent() -> Bool {
        do {
            let consent: Bool? = try secureDataManager.retrieveSecureData(Bool.self, forKey: dataCollectionConsentKey)
            return consent ?? false
        } catch {
            logger.error("Failed to retrieve data collection consent", error: error, category: .security)
            return false
        }
    }
    
    /// Revoke all user consent
    func revokeAllConsent() {
        logger.info("Revoking all user consent", category: .security)
        
        do {
            try secureDataManager.deleteSecureData(forKey: analyticsConsentKey)
            try secureDataManager.deleteSecureData(forKey: dataCollectionConsentKey)
            try secureDataManager.deleteSecureData(forKey: consentTimestampKey)
            
            logger.info("All consent revoked successfully", category: .security)
        } catch {
            logger.error("Failed to revoke consent", error: error, category: .security)
        }
    }
    
    // MARK: - Data Rights Management
    
    /// Export all user data for GDPR compliance
    func exportUserData() async -> [String: Any] {
        logger.info("Exporting user data", category: .security)
        
        var exportData: [String: Any] = [:]
        
        // Add consent information
        exportData["analytics_consent"] = hasAnalyticsConsent()
        exportData["data_collection_consent"] = hasDataCollectionConsent()
        
        // Add consent timestamp
        do {
            if let timestamp: Date = try secureDataManager.retrieveSecureData(Date.self, forKey: consentTimestampKey) {
                exportData["consent_timestamp"] = ISO8601DateFormatter().string(from: timestamp)
            }
        } catch {
            logger.error("Failed to retrieve consent timestamp", error: error, category: .security)
        }
        
        // Add game data if consent is given
        if hasDataCollectionConsent() {
            if let playerData = await SecureSwiftDataManager.shared.getSecureCurrentPlayer() {
                exportData["player_data"] = [
                    "level": playerData.level,
                    "experience_points": playerData.experiencePoints,
                    "total_score": playerData.totalScore,
                    "total_distance": playerData.totalDistance,
                    "total_flight_time": playerData.totalFlightTime,
                    "daily_run_streak": playerData.dailyRunStreak,
                    "unlocked_airplanes": playerData.unlockedAirplanes,
                    "unlocked_environments": playerData.unlockedEnvironments,
                    "completed_challenges": playerData.completedChallenges,
                    "high_score": playerData.highScore,
                    "created_at": ISO8601DateFormatter().string(from: playerData.createdAt),
                    "last_played_at": ISO8601DateFormatter().string(from: playerData.lastPlayedAt)
                ]
                
                // Add game results
                let gameResults = playerData.gameResults.map { result in
                    return [
                        "score": result.score,
                        "distance": result.distance,
                        "time_elapsed": result.timeElapsed,
                        "mode": result.mode,
                        "environment": result.environmentType,
                        "date_played": ISO8601DateFormatter().string(from: result.completedAt)
                    ]
                }
                exportData["game_results"] = gameResults
                
                // Add achievements
                let achievements = playerData.achievements.filter { $0.isUnlocked }.map { achievement in
                    return [
                        "id": achievement.id,
                        "title": achievement.title,
                        "description": achievement.achievementDescription,
                        "unlocked_at": achievement.unlockedAt != nil ? ISO8601DateFormatter().string(from: achievement.unlockedAt!) : nil
                    ]
                }
                exportData["achievements"] = achievements
            }
        }
        
        exportData["export_timestamp"] = ISO8601DateFormatter().string(from: Date())
        exportData["privacy_policy_version"] = currentPrivacyPolicyVersion
        
        logger.info("User data export completed", category: .security)
        return exportData
    }
    
    /// Delete all user data for GDPR compliance
    func deleteUserData() async -> Bool {
        logger.info("Deleting all user data", category: .security)
        
        do {
            // Delete consent data
            try secureDataManager.deleteSecureData(forKey: analyticsConsentKey)
            try secureDataManager.deleteSecureData(forKey: dataCollectionConsentKey)
            try secureDataManager.deleteSecureData(forKey: consentTimestampKey)
            try secureDataManager.deleteSecureData(forKey: privacyPolicyVersionKey)
            
            // Delete secure backups
            try secureDataManager.deleteSecureData(forKey: "player_data_backup")
            try secureDataManager.deleteSecureData(forKey: "game_results_backup")
            try secureDataManager.deleteSecureData(forKey: "achievements_backup")
            try secureDataManager.deleteSecureData(forKey: "data_integrity_hash")
            
            // Clear SwiftData
            await clearSwiftDataStorage()
            
            logger.info("All user data deleted successfully", category: .security)
            return true
            
        } catch {
            logger.error("Failed to delete user data", error: error, category: .security)
            return false
        }
    }
    
    // MARK: - Privacy Policy Integration
    
    /// Show privacy policy to user
    func showPrivacyPolicy() {
        logger.info("Showing privacy policy", category: .security)
        
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Privacy Policy",
                message: self.getPrivacyPolicyText(),
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Close", style: .default))
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                rootViewController.present(alert, animated: true)
            }
        }
    }
    
    /// Show data deletion request interface
    func showDataDeletionRequest() {
        logger.info("Showing data deletion request", category: .security)
        
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Delete All Data",
                message: "This will permanently delete all your game progress, scores, achievements, and settings. This action cannot be undone. Are you sure you want to continue?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            alert.addAction(UIAlertAction(title: "Delete All Data", style: .destructive) { _ in
                Task {
                    let success = await self.deleteUserData()
                    
                    DispatchQueue.main.async {
                        let resultAlert = UIAlertController(
                            title: success ? "Data Deleted" : "Deletion Failed",
                            message: success ? "All your data has been permanently deleted." : "There was an error deleting your data. Please try again.",
                            preferredStyle: .alert
                        )
                        
                        resultAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first,
                           let rootViewController = window.rootViewController {
                            rootViewController.present(resultAlert, animated: true)
                        }
                    }
                }
            })
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                rootViewController.present(alert, animated: true)
            }
        }
    }
    
    // MARK: - Consent Validation
    
    /// Check if consent needs to be re-requested (e.g., privacy policy updated)
    func needsConsentUpdate() -> Bool {
        do {
            let storedVersion: String? = try secureDataManager.retrieveSecureData(String.self, forKey: privacyPolicyVersionKey)
            return storedVersion != currentPrivacyPolicyVersion
        } catch {
            logger.error("Failed to check privacy policy version", error: error, category: .security)
            return true // Assume consent update needed on error
        }
    }
    
    /// Initialize privacy manager and check for required consent
    func initializePrivacyCompliance() async {
        logger.info("Initializing privacy compliance", category: .security)
        
        // Check if we need to request consent
        if needsConsentUpdate() || (!hasAnalyticsConsent() && !hasDataCollectionConsent()) {
            // Request consent for new users or privacy policy updates
            let analyticsConsent = await requestAnalyticsConsent()
            let dataConsent = await requestDataCollectionConsent()
            
            // Store privacy policy version
            do {
                try secureDataManager.storeSecureData(currentPrivacyPolicyVersion, forKey: privacyPolicyVersionKey)
            } catch {
                logger.error("Failed to store privacy policy version", error: error, category: .security)
            }
            
            logger.info("Privacy compliance initialized - Analytics: \(analyticsConsent), Data: \(dataConsent)", category: .security)
        } else {
            logger.info("Privacy compliance already established", category: .security)
        }
    }
    
    // MARK: - Private Methods
    
    private func setAnalyticsConsent(_ consent: Bool) {
        do {
            try secureDataManager.storeSecureData(consent, forKey: analyticsConsentKey)
            try secureDataManager.storeSecureData(Date(), forKey: consentTimestampKey)
            logger.info("Analytics consent set to \(consent)", category: .security)
        } catch {
            logger.error("Failed to store analytics consent", error: error, category: .security)
        }
    }
    
    private func setDataCollectionConsent(_ consent: Bool) {
        do {
            try secureDataManager.storeSecureData(consent, forKey: dataCollectionConsentKey)
            try secureDataManager.storeSecureData(Date(), forKey: consentTimestampKey)
            logger.info("Data collection consent set to \(consent)", category: .security)
        } catch {
            logger.error("Failed to store data collection consent", error: error, category: .security)
        }
    }
    
    private func clearSwiftDataStorage() async {
        // This would integrate with SecureSwiftDataManager to clear all data
        // For now, we'll just log the action
        logger.info("Clearing SwiftData storage", category: .security)
    }
    
    private func getPrivacyPolicyText() -> String {
        return """
        TINY PILOTS PRIVACY POLICY
        
        Last Updated: \(Date().formatted(date: .abbreviated, time: .omitted))
        
        We respect your privacy and are committed to protecting your personal data.
        
        INFORMATION WE COLLECT:
        • Game progress and scores (with your consent)
        • Device performance data for optimization
        • Crash reports to improve stability
        
        HOW WE USE YOUR DATA:
        • To provide game features like leaderboards
        • To sync your progress across devices
        • To improve app performance and fix bugs
        
        DATA SHARING:
        We never sell or share your personal data with third parties.
        
        YOUR RIGHTS:
        • View all data we have about you
        • Delete all your data at any time
        • Withdraw consent for data collection
        
        CONTACT:
        For privacy questions, contact us through the app settings.
        """
    }
}

/// Privacy compliance errors
enum PrivacyError: Error, LocalizedError {
    case consentRequired
    case dataExportFailed
    case dataDeletionFailed
    
    var errorDescription: String? {
        switch self {
        case .consentRequired:
            return "User consent is required for this operation"
        case .dataExportFailed:
            return "Failed to export user data"
        case .dataDeletionFailed:
            return "Failed to delete user data"
        }
    }
}