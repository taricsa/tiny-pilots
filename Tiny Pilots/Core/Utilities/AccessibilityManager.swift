//
//  AccessibilityManager.swift
//  Tiny Pilots
//
//  Created by Kiro on Production Readiness Implementation
//

import UIKit
import Foundation

/// Concrete implementation of AccessibilityManagerProtocol
class AccessibilityManager: AccessibilityManagerProtocol {
    static let shared = AccessibilityManager()
    
    // MARK: - Private Properties
    private var announcementQueue: [AccessibilityAnnouncement] = []
    private var isProcessingAnnouncements = false
    private let announcementQueue_lock = NSLock()
    private var accessibilityObservers: [NSObjectProtocol] = []
    
    // MARK: - Initialization
    private init() {
        setupAccessibilityNotifications()
    }
    
    deinit {
        cleanupAccessibilityNotifications()
    }
    
    // MARK: - Public Methods
    
    func initialize() {
        Logger.shared.info("Initializing AccessibilityManager", category: .accessibility)
        setupAccessibilityNotifications()
        
        // Log current accessibility status
        Logger.shared.info("VoiceOver enabled: \(isVoiceOverRunning())", category: .accessibility)
        Logger.shared.info("Dynamic Type enabled: \(isDynamicTypeEnabled())", category: .accessibility)
        Logger.shared.info("Content size category: \(preferredContentSizeCategory())", category: .accessibility)
    }
    
    func announceMessage(_ message: String, priority: AccessibilityAnnouncementPriority = .medium) {
        guard !message.isEmpty else { return }
        
        let announcement = AccessibilityAnnouncement(message: message, priority: priority)
        
        if priority == .high {
            // High priority announcements interrupt current ones
            DispatchQueue.main.async {
                UIAccessibility.post(notification: .announcement, argument: message)
            }
        } else {
            // Queue lower priority announcements
            announcementQueue_lock.lock()
            announcementQueue.append(announcement)
            announcementQueue_lock.unlock()
            
            processAnnouncementQueue()
        }
    }
    
    func configureElement(_ element: Any, label: String?, hint: String?, traits: UIAccessibilityTraits?) {
        guard let accessibleElement = element as? NSObject else { return }
        
        DispatchQueue.main.async {
            if let label = label {
                accessibleElement.accessibilityLabel = label
            }
            
            if let hint = hint {
                accessibleElement.accessibilityHint = hint
            }
            
            if let traits = traits {
                accessibleElement.accessibilityTraits = traits
            }
        }
    }
    
    func isVoiceOverRunning() -> Bool {
        return UIAccessibility.isVoiceOverRunning
    }
    
    func isDynamicTypeEnabled() -> Bool {
        return UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
    }
    
    func preferredContentSizeCategory() -> UIContentSizeCategory {
        return UIApplication.shared.preferredContentSizeCategory
    }
    
    func getCurrentConfiguration() -> AccessibilityConfiguration {
        return AccessibilityConfiguration.current
    }
    
    func setupAccessibilityNotifications() {
        cleanupAccessibilityNotifications()
        
        let notificationCenter = NotificationCenter.default
        
        // VoiceOver status change
        let voiceOverObserver = notificationCenter.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleVoiceOverStatusChange()
        }
        accessibilityObservers.append(voiceOverObserver)
        
        // Dynamic Type change
        let dynamicTypeObserver = notificationCenter.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleDynamicTypeChange()
        }
        accessibilityObservers.append(dynamicTypeObserver)
        
        // Reduce Motion change
        let reduceMotionObserver = notificationCenter.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleReduceMotionChange()
        }
        accessibilityObservers.append(reduceMotionObserver)
        
        // High Contrast change
        let highContrastObserver = notificationCenter.addObserver(
            forName: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleHighContrastChange()
        }
        accessibilityObservers.append(highContrastObserver)
    }
    
    func cleanupAccessibilityNotifications() {
        let notificationCenter = NotificationCenter.default
        accessibilityObservers.forEach { observer in
            notificationCenter.removeObserver(observer)
        }
        accessibilityObservers.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func processAnnouncementQueue() {
        guard !isProcessingAnnouncements else { return }
        
        announcementQueue_lock.lock()
        guard !announcementQueue.isEmpty else {
            announcementQueue_lock.unlock()
            return
        }
        
        let announcement = announcementQueue.removeFirst()
        announcementQueue_lock.unlock()
        
        isProcessingAnnouncements = true
        
        DispatchQueue.main.async { [weak self] in
            UIAccessibility.post(notification: .announcement, argument: announcement.message)
            
            // Process next announcement after delay to avoid overwhelming VoiceOver
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.isProcessingAnnouncements = false
                self?.processAnnouncementQueue()
            }
        }
    }
    
    private func handleVoiceOverStatusChange() {
        let isEnabled = UIAccessibility.isVoiceOverRunning
        announceMessage(
            isEnabled ? "VoiceOver enabled" : "VoiceOver disabled",
            priority: .medium
        )
        
        // Post notification for other parts of the app to respond
        NotificationCenter.default.post(
            name: .accessibilityConfigurationChanged,
            object: nil,
            userInfo: ["voiceOverEnabled": isEnabled]
        )
    }
    
    private func handleDynamicTypeChange() {
        let newCategory = UIApplication.shared.preferredContentSizeCategory
        
        // Post notification for other parts of the app to respond
        NotificationCenter.default.post(
            name: .accessibilityConfigurationChanged,
            object: nil,
            userInfo: ["contentSizeCategory": newCategory]
        )
    }
    
    private func handleReduceMotionChange() {
        let isEnabled = UIAccessibility.isReduceMotionEnabled
        
        // Post notification for other parts of the app to respond
        NotificationCenter.default.post(
            name: .accessibilityConfigurationChanged,
            object: nil,
            userInfo: ["reduceMotionEnabled": isEnabled]
        )
    }
    
    private func handleHighContrastChange() {
        let isEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        
        // Post notification for other parts of the app to respond
        NotificationCenter.default.post(
            name: .accessibilityConfigurationChanged,
            object: nil,
            userInfo: ["highContrastEnabled": isEnabled]
        )
    }
    
    // MARK: - Game-Specific Accessibility Methods
    

    
    /// Announce collectible pickup
    func announceCollectiblePickup(_ type: String, count: Int) {
        let message = "\(type) collected. Total: \(count)"
        announceMessage(message, priority: .low)
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let accessibilityConfigurationChanged = Notification.Name("AccessibilityConfigurationChanged")
}