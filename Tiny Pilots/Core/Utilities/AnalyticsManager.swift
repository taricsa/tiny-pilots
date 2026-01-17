//
//  AnalyticsManager.swift
//  Tiny Pilots
//
//  Created by Kiro on 7/15/25.
//

import Foundation
import UIKit

/// Main analytics manager implementing privacy-compliant analytics tracking
class AnalyticsManager: AnalyticsProtocol {
    static let shared = AnalyticsManager()
    
    // MARK: - Properties
    
    private let userDefaults = UserDefaults.standard
    private let consentKey = "analytics_consent_status"
    private let consentDateKey = "analytics_consent_date"
    private let userPropertiesKey = "analytics_user_properties"
    
    private var isEnabled: Bool = false
    private var eventQueue: [AnalyticsEventData] = []
    private let queueLock = NSLock()
    private let maxQueueSize = 100
    private let batchUploadSize = 10
    
    // MARK: - Initialization
    
    private init() {
        setupAnalytics()
        loadUserConsent()
    }
    
    // MARK: - Public Interface
    
    func initialize() {
        Logger.shared.info("Initializing AnalyticsManager", category: .app)
        setupAnalytics()
        loadUserConsent()
    }
    
    var hasUserConsent: Bool {
        let status = getConsentStatus()
        return status == .granted && !isConsentExpired()
    }
    
    func trackEvent(_ event: AnalyticsEvent) {
        guard hasUserConsent && isEnabled else {
            Logger.shared.debug("Analytics event skipped - no consent or disabled", category: .app)
            return
        }
        
        let eventData = convertEventToData(event)
        queueEvent(eventData)
        
        Logger.shared.debug("Analytics event tracked: \(eventData.name)", category: .app)
    }
    
    func trackError(message: String, category: String, error: Error? = nil) {
        guard hasUserConsent && isEnabled else { return }
        
        let eventData = AnalyticsEventData(
            name: "error_occurred",
            parameters: [
                "message": message,
                "category": category,
                "error_description": error?.localizedDescription ?? "Unknown",
                "timestamp": Date().timeIntervalSince1970
            ],
            timestamp: Date()
        )
        
        queueEvent(eventData)
        Logger.shared.debug("Analytics error tracked: \(message)", category: .app)
    }
    
    func trackPerformance(_ metric: PerformanceMetric) {
        guard hasUserConsent && isEnabled else { return }
        
        var parameters: [String: Any] = [
            "metric_name": metric.name,
            "value": metric.value,
            "unit": metric.unit,
            "category": metric.category,
            "timestamp": metric.timestamp.timeIntervalSince1970
        ]
        
        if let additionalInfo = metric.additionalInfo {
            parameters.merge(additionalInfo) { _, new in new }
        }
        
        let eventData = AnalyticsEventData(
            name: "performance_metric",
            parameters: parameters,
            timestamp: metric.timestamp
        )
        
        queueEvent(eventData)
        Logger.shared.debug("Performance metric tracked: \(metric.name) = \(metric.value) \(metric.unit)", category: .performance)
    }
    
    func setUserProperty(_ property: String, value: Any) {
        guard hasUserConsent else { return }
        
        var userProperties = getUserProperties()
        userProperties[property] = value
        
        userDefaults.set(userProperties, forKey: userPropertiesKey)
        Logger.shared.debug("User property set: \(property)", category: .app)
    }
    
    func trackScreenView(_ screenName: String, parameters: [String: Any]? = nil) {
        guard hasUserConsent && isEnabled else { return }
        
        var eventParameters: [String: Any] = [
            "screen_name": screenName,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let additionalParams = parameters {
            eventParameters.merge(additionalParams) { _, new in new }
        }
        
        let eventData = AnalyticsEventData(
            name: "screen_view",
            parameters: eventParameters,
            timestamp: Date()
        )
        
        queueEvent(eventData)
        Logger.shared.debug("Screen view tracked: \(screenName)", category: .app)
    }
    
    func setAnalyticsEnabled(_ enabled: Bool) {
        self.isEnabled = enabled
        Logger.shared.info("Analytics enabled: \(enabled)", category: .app)
        
        if enabled && hasUserConsent {
            processQueuedEvents()
        }
    }
    
    func requestUserConsent() async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { continuation.resume(returning: false); return }
                strongSelf.showConsentDialog { granted in
                    strongSelf.setConsentStatus(granted ? .granted : .denied)
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAnalytics() {
        // Configure analytics based on environment
        let config = AppConfiguration.current
        self.isEnabled = config.featureFlags.isAnalyticsEnabled
        
        Logger.shared.info("Analytics manager initialized - enabled: \(isEnabled)", category: .app)
    }
    
    private func loadUserConsent() {
        let status = getConsentStatus()
        Logger.shared.info("Analytics consent status: \(status)", category: .app)
        
        // Check if consent has expired (1 year)
        if status == .granted && isConsentExpired() {
            setConsentStatus(.expired)
            Logger.shared.info("Analytics consent expired, requesting new consent", category: .app)
        }
    }
    
    private func getConsentStatus() -> AnalyticsConsentStatus {
        let rawValue = userDefaults.integer(forKey: consentKey)
        switch rawValue {
        case 1: return .granted
        case 2: return .denied
        case 3: return .expired
        default: return .notRequested
        }
    }
    
    private func setConsentStatus(_ status: AnalyticsConsentStatus) {
        let rawValue: Int
        switch status {
        case .notRequested: rawValue = 0
        case .granted: rawValue = 1
        case .denied: rawValue = 2
        case .expired: rawValue = 3
        }
        
        userDefaults.set(rawValue, forKey: consentKey)
        userDefaults.set(Date(), forKey: consentDateKey)
        
        Logger.shared.info("Analytics consent status updated: \(status)", category: .app)
    }
    
    private func isConsentExpired() -> Bool {
        guard let consentDate = userDefaults.object(forKey: consentDateKey) as? Date else {
            return true
        }
        
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        return consentDate < oneYearAgo
    }
    
    private func getUserProperties() -> [String: Any] {
        return userDefaults.dictionary(forKey: userPropertiesKey) ?? [:]
    }
    
    private func convertEventToData(_ event: AnalyticsEvent) -> AnalyticsEventData {
        let (name, parameters) = eventToNameAndParameters(event)
        return AnalyticsEventData(name: name, parameters: parameters, timestamp: Date())
    }
    
    private func eventToNameAndParameters(_ event: AnalyticsEvent) -> (String, [String: Any]) {
        switch event {
        case .gameStarted(let mode, let environment):
            return ("game_started", ["mode": mode.rawValue, "environment": environment])
            
        case .gameCompleted(let mode, let score, let duration, let environment):
            return ("game_completed", [
                "mode": mode.rawValue,
                "score": score,
                "duration": duration,
                "environment": environment
            ])
            
        case .gamePaused(let duration):
            return ("game_paused", ["duration": duration])
            
        case .gameResumed:
            return ("game_resumed", [:])
            
        case .gameAbandoned(let reason, let duration):
            return ("game_abandoned", ["reason": reason, "duration": duration])
            
        case .airplaneCustomized(let foldType, let colorScheme):
            return ("airplane_customized", ["fold_type": foldType, "color_scheme": colorScheme])
            
        case .challengeShared(let challengeId):
            return ("challenge_shared", ["challenge_id": challengeId])
            
        case .achievementUnlocked(let achievementId):
            return ("achievement_unlocked", ["achievement_id": achievementId])
            
        case .leaderboardViewed(let category):
            return ("leaderboard_viewed", ["category": category])
            
        case .settingsChanged(let setting, let value):
            return ("settings_changed", ["setting": setting, "value": value])
            
        case .gameCenterAuthenticated:
            return ("game_center_authenticated", [:])
            
        case .gameCenterAuthenticationFailed(let error):
            return ("game_center_auth_failed", ["error": error])
            
        case .leaderboardScoreSubmitted(let category, let score):
            return ("leaderboard_score_submitted", ["category": category, "score": score])
            
        case .achievementProgressUpdated(let achievementId, let progress):
            return ("achievement_progress_updated", ["achievement_id": achievementId, "progress": progress])
            
        case .lowFrameRateDetected(let fps, let scene):
            return ("low_frame_rate_detected", ["fps": fps, "scene": scene])
            
        case .highMemoryUsageDetected(let memoryMB):
            return ("high_memory_usage_detected", ["memory_mb": memoryMB])
            
        case .slowSceneTransition(let fromScene, let toScene, let duration):
            return ("slow_scene_transition", [
                "from_scene": fromScene,
                "to_scene": toScene,
                "duration": duration
            ])
            
        case .appLaunchCompleted(let duration):
            return ("app_launch_completed", ["duration": duration])
            
        case .errorOccurred(let category, let message, let isFatal):
            return ("error_occurred", [
                "category": category,
                "message": message,
                "is_fatal": isFatal
            ])
            
        case .crashRecovered(let context):
            return ("crash_recovered", ["context": context])
            
        case .networkConnectivityChanged(let isConnected):
            return ("network_connectivity_changed", ["is_connected": isConnected])
            
        case .networkRequestFailed(let endpoint, let error):
            return ("network_request_failed", ["endpoint": endpoint, "error": error])
            
        case .offlineModeActivated:
            return ("offline_mode_activated", [:])
            
        case .tutorialStarted:
            return ("tutorial_started", [:])
            
        case .tutorialCompleted(let duration):
            return ("tutorial_completed", ["duration": duration])
            
        case .tutorialSkipped(let step):
            return ("tutorial_skipped", ["step": step])
            
        case .dailyRunStarted:
            return ("daily_run_started", [:])
            
        case .weeklySpecialViewed:
            return ("weekly_special_viewed", [:])
            
        case .challengeCodeEntered(let isValid):
            return ("challenge_code_entered", ["is_valid": isValid])
            
        case .dailyRunGenerated(let difficulty):
            return ("daily_run_generated", ["difficulty": difficulty])
            
        case .dailyRunCompleted(let score):
            return ("daily_run_completed", ["score": score])
            
        case .privacyPolicyAccepted:
            return ("privacy_policy_accepted", [:])
            
        case .complianceValidation(let isCompliant):
            return ("compliance_validation", ["is_compliant": isCompliant])
        }
    }
    
    private func queueEvent(_ eventData: AnalyticsEventData) {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        eventQueue.append(eventData)
        
        // Remove old events if queue is too large
        if eventQueue.count > maxQueueSize {
            eventQueue.removeFirst(eventQueue.count - maxQueueSize)
            Logger.shared.warning("Analytics queue overflow, removed old events", category: .app)
        }
        
        // Process events if we have enough for a batch
        if eventQueue.count >= batchUploadSize {
            processQueuedEvents()
        }
    }
    
    private func processQueuedEvents() {
        let eventsToProcess: [AnalyticsEventData] = {
            queueLock.lock()
            defer { queueLock.unlock() }
            let batch = Array(eventQueue.prefix(batchUploadSize))
            eventQueue.removeFirst(min(batchUploadSize, eventQueue.count))
            return batch
        }()
        
        guard !eventsToProcess.isEmpty else { return }
        
        // In a real implementation, this would send events to an analytics service
        // For now, we'll just log them
        Logger.shared.info("Processing \(eventsToProcess.count) analytics events", category: .app)
        
        for event in eventsToProcess {
            Logger.shared.debug("Analytics event: \(event.name) - \(event.parameters)", category: .app)
        }
        
        // Simulate network call
        Task {
            await sendEventsToService(eventsToProcess)
        }
    }
    
    private func sendEventsToService(_ events: [AnalyticsEventData]) async {
        // This would integrate with a real analytics service like Firebase Analytics
        // For now, we'll simulate the network call
        do {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
            Logger.shared.info("Successfully sent \(events.count) analytics events", category: .app)
        } catch {
            Logger.shared.error("Failed to send analytics events", error: error, category: .app)
            
            // Re-queue failed events synchronously on main thread
            DispatchQueue.main.sync {
                self.queueLock.lock()
                self.eventQueue.insert(contentsOf: events, at: 0)
                self.queueLock.unlock()
            }
        }
    }
    
    private func showConsentDialog(completion: @escaping (Bool) -> Void) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            completion(false)
            return
        }
        
        let alert = UIAlertController(
            title: "Analytics & Crash Reporting",
            message: "Help us improve Tiny Pilots by sharing anonymous usage data and crash reports. This data helps us fix bugs and enhance your gaming experience. You can change this setting anytime in the app settings.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Allow", style: .default) { _ in
            completion(true)
        })
        
        alert.addAction(UIAlertAction(title: "Don't Allow", style: .cancel) { _ in
            completion(false)
        })
        
        window.rootViewController?.present(alert, animated: true)
    }
}

// MARK: - Supporting Types

private struct AnalyticsEventData {
    let name: String
    let parameters: [String: Any]
    let timestamp: Date
}