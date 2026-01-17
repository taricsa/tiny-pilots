import Foundation
import StoreKit
import UIKit

/// Manages app rating prompts and user feedback collection
class AppRatingManager {
    static let shared = AppRatingManager()
    
    // MARK: - Properties
    
    private let userDefaults = UserDefaults.standard
    
    // UserDefaults keys
    private let hasRatedKey = "has_rated_app"
    private let ratingPromptCountKey = "rating_prompt_count"
    private let lastRatingPromptDateKey = "last_rating_prompt_date"
    private let gameSessionCountKey = "game_session_count"
    private let firstLaunchDateKey = "first_launch_date"
    private let lastVersionPromptedKey = "last_version_prompted"
    private let userDeclinedRatingKey = "user_declined_rating"
    private let significantEventsCountKey = "significant_events_count"
    
    // Configuration
    private let minimumDaysSinceFirstLaunch = 3
    private let minimumGameSessions = 5
    private let minimumSignificantEvents = 3
    private let daysBetweenPrompts = 30
    private let maxPromptCount = 3
    
    // MARK: - Initialization
    
    private init() {
        setupFirstLaunchTracking()
    }
    
    // MARK: - Public Interface
    
    /// Check if we should show rating prompt and show it if appropriate
    func checkAndPromptForRating() {
        guard shouldPromptForRating() else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.showRatingPrompt()
        }
    }
    
    /// Manually trigger rating prompt (for settings menu)
    func promptForRatingManually() {
        DispatchQueue.main.async { [weak self] in
            self?.showRatingPrompt()
        }
    }
    
    /// Track significant events that might warrant a rating prompt
    func trackSignificantEvent(_ event: SignificantEvent) {
        let currentCount = userDefaults.integer(forKey: significantEventsCountKey)
        userDefaults.set(currentCount + 1, forKey: significantEventsCountKey)
        
        Logger.shared.debug("Significant event tracked: \(event.rawValue)", category: .app)
        
        // Track in analytics
        AnalyticsManager.shared.trackEvent(.significantEventOccurred(event: event.rawValue))
        
        // Check if we should prompt after this event
        if event.shouldTriggerRatingCheck {
            checkAndPromptForRating()
        }
    }
    
    /// Track game session completion
    func trackGameSessionCompleted() {
        let currentCount = userDefaults.integer(forKey: gameSessionCountKey)
        userDefaults.set(currentCount + 1, forKey: gameSessionCountKey)
        
        Logger.shared.debug("Game session completed, total: \(currentCount + 1)", category: .app)
    }
    
    /// Check if user has already rated the app
    var hasUserRatedApp: Bool {
        return userDefaults.bool(forKey: hasRatedKey)
    }
    
    /// Get rating statistics for analytics
    func getRatingStatistics() -> RatingStatistics {
        return RatingStatistics(
            hasRated: hasUserRatedApp,
            promptCount: userDefaults.integer(forKey: ratingPromptCountKey),
            gameSessionCount: userDefaults.integer(forKey: gameSessionCountKey),
            significantEventsCount: userDefaults.integer(forKey: significantEventsCountKey),
            daysSinceFirstLaunch: daysSinceFirstLaunch(),
            lastPromptDate: userDefaults.object(forKey: lastRatingPromptDateKey) as? Date,
            userDeclinedRating: userDefaults.bool(forKey: userDeclinedRatingKey)
        )
    }
    
    // MARK: - Private Methods
    
    private func setupFirstLaunchTracking() {
        if userDefaults.object(forKey: firstLaunchDateKey) == nil {
            userDefaults.set(Date(), forKey: firstLaunchDateKey)
            Logger.shared.info("First app launch recorded", category: .app)
        }
    }
    
    private func shouldPromptForRating() -> Bool {
        // Don't prompt if user already rated
        if hasUserRatedApp {
            return false
        }
        
        // Don't prompt if user explicitly declined
        if userDefaults.bool(forKey: userDeclinedRatingKey) {
            return false
        }
        
        // Check if we've reached maximum prompt count
        let promptCount = userDefaults.integer(forKey: ratingPromptCountKey)
        if promptCount >= maxPromptCount {
            return false
        }
        
        // Check if enough time has passed since first launch
        if daysSinceFirstLaunch() < minimumDaysSinceFirstLaunch {
            return false
        }
        
        // Check if user has enough game sessions
        let sessionCount = userDefaults.integer(forKey: gameSessionCountKey)
        if sessionCount < minimumGameSessions {
            return false
        }
        
        // Check if user has enough significant events
        let eventsCount = userDefaults.integer(forKey: significantEventsCountKey)
        if eventsCount < minimumSignificantEvents {
            return false
        }
        
        // Check if enough time has passed since last prompt
        if let lastPromptDate = userDefaults.object(forKey: lastRatingPromptDateKey) as? Date {
            let daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastPromptDate, to: Date()).day ?? 0
            if daysSinceLastPrompt < daysBetweenPrompts {
                return false
            }
        }
        
        // Check if we've already prompted for this version
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let lastVersionPrompted = userDefaults.string(forKey: lastVersionPromptedKey)
        if lastVersionPrompted == currentVersion {
            return false
        }
        
        return true
    }
    
    private func showRatingPrompt() {
        // Update prompt tracking
        let promptCount = userDefaults.integer(forKey: ratingPromptCountKey)
        userDefaults.set(promptCount + 1, forKey: ratingPromptCountKey)
        userDefaults.set(Date(), forKey: lastRatingPromptDateKey)
        
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        userDefaults.set(currentVersion, forKey: lastVersionPromptedKey)
        
        Logger.shared.info("Showing rating prompt (attempt \(promptCount + 1))", category: .app)
        
        // Track in analytics
        AnalyticsManager.shared.trackEvent(.ratingPromptShown(attempt: promptCount + 1))
        
        // Use iOS 14+ SKStoreReviewController if available
        if #available(iOS 14.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
                handleRatingPromptShown()
            }
        } else {
            // Fallback for older iOS versions
            SKStoreReviewController.requestReview()
            handleRatingPromptShown()
        }
    }
    
    private func handleRatingPromptShown() {
        // We can't detect the user's response to SKStoreReviewController
        // So we'll assume they engaged with it and mark as rated
        // This prevents over-prompting
        userDefaults.set(true, forKey: hasRatedKey)
        
        Logger.shared.info("Rating prompt shown, marking as rated to prevent over-prompting", category: .app)
        
        // Track in analytics
        AnalyticsManager.shared.trackEvent(.ratingPromptCompleted())
    }
    
    private func daysSinceFirstLaunch() -> Int {
        guard let firstLaunchDate = userDefaults.object(forKey: firstLaunchDateKey) as? Date else {
            return 0
        }
        
        return Calendar.current.dateComponents([.day], from: firstLaunchDate, to: Date()).day ?? 0
    }
    
    // MARK: - Manual Rating Flow (for Settings)
    
    /// Show manual rating options in settings
    func showManualRatingOptions() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let alert = UIAlertController(
            title: "Rate Tiny Pilots",
            message: "If you enjoy playing Tiny Pilots, would you mind taking a moment to rate it? It won't take more than a minute. Thanks for your support!",
            preferredStyle: .alert
        )
        
        // Rate Now
        alert.addAction(UIAlertAction(title: "Rate Now", style: .default) { [weak self] _ in
            self?.openAppStoreForRating()
        })
        
        // Remind Later
        alert.addAction(UIAlertAction(title: "Remind Me Later", style: .default) { [weak self] _ in
            self?.handleRemindLater()
        })
        
        // No Thanks
        alert.addAction(UIAlertAction(title: "No, Thanks", style: .cancel) { [weak self] _ in
            self?.handleDeclineRating()
        })
        
        window.rootViewController?.present(alert, animated: true)
    }
    
    private func openAppStoreForRating() {
        let appID = "YOUR_APP_ID" // Replace with actual App Store ID
        let urlString = "https://apps.apple.com/app/id\(appID)?action=write-review"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
            
            // Mark as rated
            userDefaults.set(true, forKey: hasRatedKey)
            
            Logger.shared.info("Opened App Store for rating", category: .app)
            AnalyticsManager.shared.trackEvent(.appStoreRatingOpened())
        }
    }
    
    private func handleRemindLater() {
        // Reset the last prompt date to allow future prompts
        userDefaults.removeObject(forKey: lastRatingPromptDateKey)
        
        Logger.shared.info("User chose to be reminded later for rating", category: .app)
        AnalyticsManager.shared.trackEvent(.ratingRemindLater())
    }
    
    private func handleDeclineRating() {
        userDefaults.set(true, forKey: userDeclinedRatingKey)
        
        Logger.shared.info("User declined rating", category: .app)
        AnalyticsManager.shared.trackEvent(.ratingDeclined())
    }
}

// MARK: - Supporting Types

enum SignificantEvent: String, CaseIterable {
    case gameCompleted = "game_completed"
    case achievementUnlocked = "achievement_unlocked"
    case highScoreAchieved = "high_score_achieved"
    case challengeShared = "challenge_shared"
    case weeklySpecialCompleted = "weekly_special_completed"
    case perfectLanding = "perfect_landing"
    case longFlightCompleted = "long_flight_completed"
    case multipleGamesInSession = "multiple_games_in_session"
    
    var shouldTriggerRatingCheck: Bool {
        switch self {
        case .gameCompleted, .achievementUnlocked, .highScoreAchieved, .perfectLanding:
            return true
        case .challengeShared, .weeklySpecialCompleted, .longFlightCompleted, .multipleGamesInSession:
            return true
        }
    }
}

struct RatingStatistics {
    let hasRated: Bool
    let promptCount: Int
    let gameSessionCount: Int
    let significantEventsCount: Int
    let daysSinceFirstLaunch: Int
    let lastPromptDate: Date?
    let userDeclinedRating: Bool
    
    var shouldPromptSoon: Bool {
        return !hasRated && !userDeclinedRating && gameSessionCount >= 3 && daysSinceFirstLaunch >= 1
    }
    
    var debugDescription: String {
        return """
        Rating Statistics:
        - Has Rated: \(hasRated)
        - Prompt Count: \(promptCount)
        - Game Sessions: \(gameSessionCount)
        - Significant Events: \(significantEventsCount)
        - Days Since First Launch: \(daysSinceFirstLaunch)
        - User Declined: \(userDeclinedRating)
        - Should Prompt Soon: \(shouldPromptSoon)
        """
    }
}

// MARK: - Analytics Extensions

extension AnalyticsEvent {
    static func significantEventOccurred(event: String) -> AnalyticsEvent {
        return .settingsChanged(setting: "significant_event", value: event)
    }
    
    static func ratingPromptShown(attempt: Int) -> AnalyticsEvent {
        return .settingsChanged(setting: "rating_prompt_shown", value: String(attempt))
    }
    
    static func ratingPromptCompleted() -> AnalyticsEvent {
        return .settingsChanged(setting: "rating_prompt", value: "completed")
    }
    
    static func appStoreRatingOpened() -> AnalyticsEvent {
        return .settingsChanged(setting: "app_store_rating", value: "opened")
    }
    
    static func ratingRemindLater() -> AnalyticsEvent {
        return .settingsChanged(setting: "rating_response", value: "remind_later")
    }
    
    static func ratingDeclined() -> AnalyticsEvent {
        return .settingsChanged(setting: "rating_response", value: "declined")
    }
}