//
//  AccessibilityManagerProtocol.swift
//  Tiny Pilots
//
//  Created by Kiro on Production Readiness Implementation
//

import UIKit

/// Priority levels for accessibility announcements
enum AccessibilityAnnouncementPriority {
    case low
    case medium
    case high
}

/// Accessibility announcement structure
struct AccessibilityAnnouncement {
    let message: String
    let priority: AccessibilityAnnouncementPriority
    let timestamp: Date
    
    init(message: String, priority: AccessibilityAnnouncementPriority) {
        self.message = message
        self.priority = priority
        self.timestamp = Date()
    }
}

/// Configuration structure for accessibility settings
struct AccessibilityConfiguration {
    let isVoiceOverEnabled: Bool
    let isDynamicTypeEnabled: Bool
    let preferredContentSize: UIContentSizeCategory
    let isReduceMotionEnabled: Bool
    let isHighContrastEnabled: Bool
    
    static var current: AccessibilityConfiguration {
        return AccessibilityConfiguration(
            isVoiceOverEnabled: UIAccessibility.isVoiceOverRunning,
            isDynamicTypeEnabled: UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory,
            preferredContentSize: UIApplication.shared.preferredContentSizeCategory,
            isReduceMotionEnabled: UIAccessibility.isReduceMotionEnabled,
            isHighContrastEnabled: UIAccessibility.isDarkerSystemColorsEnabled
        )
    }
}

/// Protocol defining accessibility management functionality
protocol AccessibilityManagerProtocol {
    /// Announce a message to assistive technologies
    /// - Parameters:
    ///   - message: The message to announce
    ///   - priority: Priority level of the announcement
    func announceMessage(_ message: String, priority: AccessibilityAnnouncementPriority)
    
    /// Configure accessibility properties for a UI element
    /// - Parameters:
    ///   - element: The UI element to configure
    ///   - label: Accessibility label
    ///   - hint: Accessibility hint
    ///   - traits: Accessibility traits
    func configureElement(_ element: Any, label: String?, hint: String?, traits: UIAccessibilityTraits?)
    
    /// Check if VoiceOver is currently running
    /// - Returns: True if VoiceOver is active
    func isVoiceOverRunning() -> Bool
    
    /// Check if Dynamic Type is enabled
    /// - Returns: True if Dynamic Type is enabled
    func isDynamicTypeEnabled() -> Bool
    
    /// Get the preferred content size category
    /// - Returns: Current content size category
    func preferredContentSizeCategory() -> UIContentSizeCategory
    
    /// Get current accessibility configuration
    /// - Returns: Current accessibility settings
    func getCurrentConfiguration() -> AccessibilityConfiguration
    
    /// Set up accessibility notifications observer
    func setupAccessibilityNotifications()
    
    /// Clean up accessibility notifications observer
    func cleanupAccessibilityNotifications()
}