//
//  AccessibilityExtensions.swift
//  Tiny Pilots
//
//  Created by Kiro on Production Readiness Implementation
//

import UIKit
import SpriteKit
import SwiftUI

// MARK: - SKNode Accessibility Extensions

extension SKNode {
    /// Configure accessibility properties for SpriteKit nodes
    /// - Parameters:
    ///   - label: Accessibility label describing the element
    ///   - hint: Accessibility hint providing usage instructions
    ///   - traits: Accessibility traits defining the element's behavior
    ///   - value: Current value for adjustable elements
    func configureAccessibility(
        label: String?,
        hint: String? = nil,
        traits: UIAccessibilityTraits = .none,
        value: String? = nil
    ) {
        self.isAccessibilityElement = true
        
        if let label = label {
            self.accessibilityLabel = label
        }
        
        if let hint = hint {
            self.accessibilityHint = hint
        }
        
        if traits != .none {
            self.accessibilityTraits = traits
        }
        
        if let value = value {
            self.accessibilityValue = value
        }
    }
    
    /// Make node accessible as a button
    /// - Parameters:
    ///   - label: Button label
    ///   - hint: Usage hint
    func makeAccessibleButton(label: String, hint: String? = nil) {
        configureAccessibility(
            label: label,
            hint: hint,
            traits: .button
        )
    }
    
    /// Make node accessible as a static text
    /// - Parameter text: Text content
    func makeAccessibleText(_ text: String) {
        configureAccessibility(
            label: text,
            traits: .staticText
        )
    }
    
    /// Make node accessible as an adjustable element
    /// - Parameters:
    ///   - label: Element label
    ///   - value: Current value
    ///   - hint: Usage instructions
    func makeAccessibleAdjustable(label: String, value: String, hint: String? = nil) {
        configureAccessibility(
            label: label,
            hint: hint,
            traits: .adjustable,
            value: value
        )
    }
    
    /// Remove accessibility from node
    func removeAccessibility() {
        self.isAccessibilityElement = false
        self.accessibilityLabel = nil
        self.accessibilityHint = nil
        self.accessibilityValue = nil
        self.accessibilityTraits = .none
    }
}

// MARK: - SwiftUI View Accessibility Extensions

extension View {
    /// Configure comprehensive accessibility for SwiftUI views
    /// - Parameters:
    ///   - label: Accessibility label
    ///   - hint: Usage hint
    ///   - value: Current value
    ///   - traits: Accessibility traits
    ///   - sortPriority: Navigation order priority
    func accessibilityConfiguration(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits? = nil,
        sortPriority: Double? = nil
    ) -> some View {
        var view = self.accessibilityLabel(label)
        
        if let hint = hint {
            view = view.accessibilityHint(hint)
        }
        
        if let value = value {
            view = view.accessibilityValue(value)
        }
        
        if let traits = traits {
            view = view.accessibilityAddTraits(traits)
        }
        
        if let sortPriority = sortPriority {
            view = view.accessibilitySortPriority(sortPriority)
        }
        
        return view
    }
    
    /// Make view accessible as a game element
    /// - Parameters:
    ///   - label: Element description
    ///   - hint: Usage instructions
    ///   - value: Current state or value
    func accessibilityGameElement(
        label: String,
        hint: String? = nil,
        value: String? = nil
    ) -> some View {
        accessibilityConfiguration(
            label: label,
            hint: hint,
            value: value,
            traits: .isStaticText
        )
    }
    
    /// Make view accessible as a navigation button
    /// - Parameters:
    ///   - label: Button label
    ///   - destination: Where the button leads
    func accessibilityNavigationButton(
        label: String,
        destination: String
    ) -> some View {
        accessibilityConfiguration(
            label: label,
            hint: "Navigates to \(destination)",
            traits: .isButton
        )
    }
    
    /// Make view accessible as a progress indicator
    /// - Parameters:
    ///   - label: Progress description
    ///   - value: Current progress value
    ///   - maximum: Maximum value
    func accessibilityProgress(
        label: String,
        value: Double,
        maximum: Double = 100
    ) -> some View {
        let percentage = Int((value / maximum) * 100)
        return accessibilityConfiguration(
            label: label,
            value: "\(percentage) percent",
            traits: .updatesFrequently
        )
    }
}

// MARK: - Accessibility Announcement Helpers

extension AccessibilityManager {
    /// Announce game state changes
    /// - Parameter gameState: Current game state
    func announceGameStateChange(_ gameState: String) {
        announceMessage("Game state: \(gameState)", priority: .medium)
    }
    
    /// Announce score updates
    /// - Parameters:
    ///   - score: Current score
    ///   - isNewHighScore: Whether this is a new high score
    func announceScoreUpdate(_ score: Int, isNewHighScore: Bool = false) {
        let message = isNewHighScore ? "New high score: \(score)" : "Score: \(score)"
        let priority: AccessibilityAnnouncementPriority = isNewHighScore ? .high : .low
        announceMessage(message, priority: priority)
    }
    
    /// Announce collectible collection
    /// - Parameters:
    ///   - type: Type of collectible
    ///   - count: Total count after collection
    func announceCollectibleCollection(_ type: String, count: Int) {
        announceMessage("\(type) collected. Total: \(count)", priority: .low)
    }
    
    /// Announce obstacle collision
    func announceObstacleCollision() {
        announceMessage("Obstacle hit", priority: .high)
    }
    
    /// Announce level completion
    /// - Parameters:
    ///   - level: Completed level
    ///   - score: Final score
    ///   - time: Completion time
    func announceLevelCompletion(level: String, score: Int, time: String) {
        announceMessage("Level \(level) completed. Score: \(score). Time: \(time)", priority: .high)
    }
    
    /// Announce achievement unlock
    /// - Parameter achievement: Achievement name
    func announceAchievementUnlock(_ achievement: String) {
        announceMessage("Achievement unlocked: \(achievement)", priority: .high)
    }
    
    /// Announce menu navigation
    /// - Parameter destination: Destination screen
    func announceMenuNavigation(_ destination: String) {
        announceMessage("Navigating to \(destination)", priority: .medium)
    }
}

// MARK: - VoiceOver Navigation Helpers

/// Helper class for managing VoiceOver navigation order
class VoiceOverNavigationManager {
    static let shared = VoiceOverNavigationManager()
    
    private init() {}
    
    /// Set up navigation order for a collection of elements
    /// - Parameter elements: Array of accessibility elements in desired order
    func setupNavigationOrder(for elements: [Any]) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        
        for (_, element) in elements.enumerated() {
            if let accessibleElement = element as? NSObject {
                // Set navigation order using accessibility container
                accessibleElement.accessibilityNavigationStyle = .combined
            }
        }
    }
    
    /// Focus VoiceOver on a specific element
    /// - Parameter element: Element to focus
    func focusOnElement(_ element: Any) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIAccessibility.post(notification: .layoutChanged, argument: element)
        }
    }
    
    /// Announce screen change
    /// - Parameter screenName: Name of the new screen
    func announceScreenChange(_ screenName: String) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIAccessibility.post(notification: .screenChanged, argument: "\(screenName) screen")
        }
    }
}

// MARK: - Game-Specific Accessibility Helpers

/// Accessibility helpers specific to game elements
struct GameAccessibilityHelper {
    /// Generate accessibility description for airplane position
    /// - Parameters:
    ///   - position: Airplane position
    ///   - screenSize: Screen dimensions
    /// - Returns: Position description
    static func airplanePositionDescription(position: CGPoint, screenSize: CGSize) -> String {
        let horizontalPercent = Int((position.x / screenSize.width) * 100)
        let verticalPercent = Int((position.y / screenSize.height) * 100)
        
        let horizontal = horizontalPercent < 33 ? "left" : horizontalPercent > 66 ? "right" : "center"
        let vertical = verticalPercent < 33 ? "bottom" : verticalPercent > 66 ? "top" : "middle"
        
        return "Airplane at \(horizontal) \(vertical) of screen"
    }
    
    /// Generate accessibility description for obstacle
    /// - Parameters:
    ///   - obstacle: Obstacle node
    ///   - airplanePosition: Current airplane position
    /// - Returns: Obstacle description with relative position
    static func obstacleDescription(obstacle: SKNode, airplanePosition: CGPoint) -> String {
        let distance = sqrt(pow(obstacle.position.x - airplanePosition.x, 2) + 
                           pow(obstacle.position.y - airplanePosition.y, 2))
        
        let direction: String
        if obstacle.position.x > airplanePosition.x {
            direction = obstacle.position.y > airplanePosition.y ? "ahead and above" : "ahead and below"
        } else {
            direction = obstacle.position.y > airplanePosition.y ? "behind and above" : "behind and below"
        }
        
        let proximity = distance < 100 ? "very close" : distance < 200 ? "close" : "distant"
        
        return "Obstacle \(direction), \(proximity)"
    }
    
    /// Generate accessibility description for collectible
    /// - Parameters:
    ///   - collectible: Collectible node
    ///   - type: Type of collectible
    /// - Returns: Collectible description
    static func collectibleDescription(collectible: SKNode, type: String) -> String {
        return "\(type) collectible available"
    }
    
    /// Generate accessibility description for game progress
    /// - Parameters:
    ///   - distance: Distance traveled
    ///   - score: Current score
    ///   - time: Elapsed time
    /// - Returns: Progress description
    static func gameProgressDescription(distance: Float, score: Int, time: String) -> String {
        return "Distance: \(String(format: "%.1f", distance)) meters, Score: \(score), Time: \(time)"
    }
}

// MARK: - Accessibility Testing Helpers

#if DEBUG
/// Helpers for testing accessibility implementation
struct AccessibilityTestHelper {
    /// Validate accessibility setup for a view hierarchy
    /// - Parameter view: Root view to validate
    /// - Returns: Array of accessibility issues found
    static func validateAccessibility(for view: UIView) -> [String] {
        var issues: [String] = []
        
        func checkView(_ view: UIView, depth: Int = 0) {
            if view.isAccessibilityElement {
                // Check for missing labels
                if view.accessibilityLabel?.isEmpty != false {
                    issues.append("Missing accessibility label for \(type(of: view))")
                }
                
                // Check for button without hint
                if view.accessibilityTraits.contains(.button) && 
                   view.accessibilityHint?.isEmpty != false {
                    issues.append("Button missing accessibility hint: \(view.accessibilityLabel ?? "Unknown")")
                }
            }
            
            // Recursively check subviews
            for subview in view.subviews {
                checkView(subview, depth: depth + 1)
            }
        }
        
        checkView(view)
        return issues
    }
    
    /// Log accessibility information for debugging
    /// - Parameter element: Element to log
    static func logAccessibilityInfo(for element: Any) {
        if let accessibleElement = element as? NSObject {
            print("Accessibility Info:")
            print("  Label: \(accessibleElement.accessibilityLabel ?? "None")")
            print("  Hint: \(accessibleElement.accessibilityHint ?? "None")")
            print("  Value: \(accessibleElement.accessibilityValue ?? "None")")
            print("  Traits: \(accessibleElement.accessibilityTraits)")
            print("  Is Element: \(accessibleElement.isAccessibilityElement)")
        }
    }
}
#endif