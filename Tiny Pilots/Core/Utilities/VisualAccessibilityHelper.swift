//
//  VisualAccessibilityHelper.swift
//  Tiny Pilots
//
//  Created by Kiro on Production Readiness Implementation
//

import UIKit
import SwiftUI

/// Helper class for managing visual accessibility features
class VisualAccessibilityHelper {
    static let shared = VisualAccessibilityHelper()
    
    private init() {}
    
    // MARK: - High Contrast Support
    
    /// Check if high contrast mode is enabled
    var isHighContrastEnabled: Bool {
        return UIAccessibility.isDarkerSystemColorsEnabled
    }
    
    /// Check if reduce motion is enabled
    var isReduceMotionEnabled: Bool {
        return UIAccessibility.isReduceMotionEnabled
    }
    
    /// Check if reduce transparency is enabled
    var isReduceTransparencyEnabled: Bool {
        return UIAccessibility.isReduceTransparencyEnabled
    }
    
    /// Check if button shapes are enabled
    var isButtonShapesEnabled: Bool {
        if #available(iOS 17.0, *) {
            return UIAccessibility.buttonShapesEnabled
        } else {
            // Prior to iOS 17 there is no public API; assume disabled
            return false
        }
    }
    
    /// Check if on/off labels are enabled
    var isOnOffSwitchLabelsEnabled: Bool {
        return UIAccessibility.isOnOffSwitchLabelsEnabled
    }
    
    // MARK: - Color Schemes
    
    /// Get high contrast color scheme
    var highContrastColors: HighContrastColorScheme {
        return HighContrastColorScheme()
    }
    
    /// Get appropriate color for text based on accessibility settings
    /// - Parameters:
    ///   - normalColor: Normal text color
    ///   - backgroundColor: Background color
    /// - Returns: Appropriate text color for accessibility
    func accessibleTextColor(normalColor: UIColor, backgroundColor: UIColor) -> UIColor {
        if isHighContrastEnabled {
            // Use high contrast colors
            let luminance = getLuminance(of: backgroundColor)
            return luminance > 0.5 ? .black : .white
        }
        
        // Check if normal color has sufficient contrast
        let contrast = calculateContrast(textColor: normalColor, backgroundColor: backgroundColor)
        if contrast < 4.5 {
            // Adjust color for better contrast
            return adjustColorForContrast(normalColor, against: backgroundColor)
        }
        
        return normalColor
    }
    
    /// Get appropriate background color based on accessibility settings
    /// - Parameter normalColor: Normal background color
    /// - Returns: Appropriate background color for accessibility
    func accessibleBackgroundColor(_ normalColor: UIColor) -> UIColor {
        if isHighContrastEnabled {
            return highContrastColors.backgroundColor
        }
        
        if isReduceTransparencyEnabled {
            // Remove transparency
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            normalColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        }
        
        return normalColor
    }
    
    /// Get appropriate border color for interactive elements
    /// - Parameter normalColor: Normal border color
    /// - Returns: Appropriate border color for accessibility
    func accessibleBorderColor(_ normalColor: UIColor) -> UIColor {
        if isHighContrastEnabled || isButtonShapesEnabled {
            return highContrastColors.borderColor
        }
        
        return normalColor
    }
    
    // MARK: - Animation Support
    
    /// Get animation duration adjusted for reduce motion
    /// - Parameter normalDuration: Normal animation duration
    /// - Returns: Adjusted duration (0 if reduce motion is enabled)
    func adjustedAnimationDuration(_ normalDuration: TimeInterval) -> TimeInterval {
        return isReduceMotionEnabled ? 0 : normalDuration
    }
    
    /// Get spring animation parameters adjusted for reduce motion
    /// - Parameters:
    ///   - response: Normal response time
    ///   - dampingFraction: Normal damping fraction
    /// - Returns: Adjusted animation parameters
    func adjustedSpringAnimation(response: Double, dampingFraction: Double) -> (response: Double, dampingFraction: Double) {
        if isReduceMotionEnabled {
            return (response: 0.1, dampingFraction: 1.0) // Very quick, no bounce
        }
        return (response: response, dampingFraction: dampingFraction)
    }
    
    /// Check if animation should be disabled
    /// - Parameter animationType: Type of animation
    /// - Returns: True if animation should be disabled
    func shouldDisableAnimation(_ animationType: AnimationType) -> Bool {
        guard isReduceMotionEnabled else { return false }
        
        switch animationType {
        case .essential:
            return false // Keep essential animations even with reduce motion
        case .decorative, .parallax, .autoplay:
            return true // Disable non-essential animations
        }
    }
    
    // MARK: - Visual Indicators
    
    /// Get visual indicator configuration for interactive elements
    /// - Parameter elementType: Type of interactive element
    /// - Returns: Visual indicator configuration
    func visualIndicatorConfig(for elementType: InteractiveElementType) -> VisualIndicatorConfig {
        var config = VisualIndicatorConfig()
        
        if isButtonShapesEnabled {
            config.showBorder = true
            config.borderWidth = 2.0
            config.cornerRadius = 8.0
        }
        
        if isHighContrastEnabled {
            config.borderColor = highContrastColors.borderColor
            config.focusColor = highContrastColors.focusColor
        }
        
        if isOnOffSwitchLabelsEnabled && elementType == .toggle {
            config.showLabels = true
        }
        
        return config
    }
    
    /// Get focus indicator configuration
    /// - Returns: Focus indicator configuration
    func focusIndicatorConfig() -> FocusIndicatorConfig {
        return FocusIndicatorConfig(
            color: isHighContrastEnabled ? highContrastColors.focusColor : .systemBlue,
            width: isHighContrastEnabled ? 3.0 : 2.0,
            style: isHighContrastEnabled ? .solid : .default
        )
    }
    
    // MARK: - Private Helper Methods
    
    func getLuminance(of color: UIColor) -> CGFloat {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Convert to linear RGB
        let linearRed = red <= 0.03928 ? red / 12.92 : pow((red + 0.055) / 1.055, 2.4)
        let linearGreen = green <= 0.03928 ? green / 12.92 : pow((green + 0.055) / 1.055, 2.4)
        let linearBlue = blue <= 0.03928 ? blue / 12.92 : pow((blue + 0.055) / 1.055, 2.4)
        
        // Calculate luminance
        return 0.2126 * linearRed + 0.7152 * linearGreen + 0.0722 * linearBlue
    }
    
    private func calculateContrast(textColor: UIColor, backgroundColor: UIColor) -> CGFloat {
        let textLuminance = getLuminance(of: textColor)
        let backgroundLuminance = getLuminance(of: backgroundColor)
        
        let lighter = max(textLuminance, backgroundLuminance)
        let darker = min(textLuminance, backgroundLuminance)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    private func adjustColorForContrast(_ color: UIColor, against backgroundColor: UIColor) -> UIColor {
        let backgroundLuminance = getLuminance(of: backgroundColor)
        
        // If background is light, make text darker; if background is dark, make text lighter
        if backgroundLuminance > 0.5 {
            return color.darker(by: 0.3)
        } else {
            return color.lighter(by: 0.3)
        }
    }
}

// MARK: - Data Models

/// High contrast color scheme
struct HighContrastColorScheme {
    let backgroundColor: UIColor = .systemBackground
    let textColor: UIColor = .label
    let borderColor: UIColor = .label
    let focusColor: UIColor = .systemBlue
    let buttonColor: UIColor = .systemBlue
    let warningColor: UIColor = .systemRed
    let successColor: UIColor = .systemGreen
    
    /// Get contrasting color for the given background
    /// - Parameter backgroundColor: Background color
    /// - Returns: Contrasting text color
    func contrastingColor(for backgroundColor: UIColor) -> UIColor {
        let luminance = VisualAccessibilityHelper.shared.getLuminance(of: backgroundColor)
        return luminance > 0.5 ? .black : .white
    }
}

/// Configuration for visual indicators
struct VisualIndicatorConfig {
    var showBorder: Bool = false
    var borderWidth: CGFloat = 1.0
    var borderColor: UIColor = .systemGray
    var cornerRadius: CGFloat = 4.0
    var showLabels: Bool = false
    var focusColor: UIColor = .systemBlue
}

/// Configuration for focus indicators
struct FocusIndicatorConfig {
    let color: UIColor
    let width: CGFloat
    let style: Style
    
    enum Style {
        case `default`
        case solid
        case dashed
    }
}

/// Types of animations for reduce motion consideration
enum AnimationType {
    case essential      // Critical for functionality
    case decorative     // Visual enhancement only
    case parallax       // Parallax scrolling effects
    case autoplay       // Auto-playing animations
}

/// Types of interactive elements
enum InteractiveElementType {
    case button
    case toggle
    case slider
    case textField
    case link
}

// MARK: - UIColor Extensions

extension UIColor {
    /// Create a lighter version of the color
    /// - Parameter percentage: Percentage to lighten (0.0 to 1.0)
    /// - Returns: Lighter color
    func lighter(by percentage: CGFloat) -> UIColor {
        return adjustBrightness(by: abs(percentage))
    }
    
    /// Create a darker version of the color
    /// - Parameter percentage: Percentage to darken (0.0 to 1.0)
    /// - Returns: Darker color
    func darker(by percentage: CGFloat) -> UIColor {
        return adjustBrightness(by: -abs(percentage))
    }
    
    private func adjustBrightness(by percentage: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            brightness = max(0, min(1, brightness + percentage))
            return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        }
        
        return self
    }
}

// MARK: - SwiftUI Extensions

extension View {
    /// Apply high contrast styling if enabled
    /// - Returns: View with high contrast styling applied
    func highContrastStyling() -> some View {
        modifier(HighContrastModifier())
    }
    
    /// Apply reduce motion considerations
    /// - Parameter animationType: Type of animation
    /// - Returns: View with motion considerations applied
    func reduceMotionConsidering(_ animationType: AnimationType = .decorative) -> some View {
        modifier(ReduceMotionModifier(animationType: animationType))
    }
    
    /// Apply visual accessibility indicators
    /// - Parameter elementType: Type of interactive element
    /// - Returns: View with accessibility indicators
    func accessibilityVisualIndicators(_ elementType: InteractiveElementType) -> some View {
        modifier(VisualIndicatorModifier(elementType: elementType))
    }
    
    /// Apply accessible focus styling
    /// - Returns: View with focus styling
    func accessibleFocus() -> some View {
        modifier(FocusIndicatorModifier())
    }
}

// MARK: - SwiftUI Modifiers

struct HighContrastModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(VisualAccessibilityHelper.shared.isHighContrastEnabled ? 
                           (colorScheme == .dark ? .white : .black) : nil)
            .background(VisualAccessibilityHelper.shared.isHighContrastEnabled ?
                       (colorScheme == .dark ? Color.black : Color.white) : nil)
    }
}

struct ReduceMotionModifier: ViewModifier {
    let animationType: AnimationType
    
    func body(content: Content) -> some View {
        content
            .animation(
                VisualAccessibilityHelper.shared.shouldDisableAnimation(animationType) ? 
                .none : .default,
                value: UUID() // Placeholder for animation trigger
            )
    }
}

struct VisualIndicatorModifier: ViewModifier {
    let elementType: InteractiveElementType
    
    func body(content: Content) -> some View {
        let config = VisualAccessibilityHelper.shared.visualIndicatorConfig(for: elementType)
        
        return content
            .overlay(
                config.showBorder ?
                RoundedRectangle(cornerRadius: config.cornerRadius)
                    .stroke(Color(config.borderColor), lineWidth: config.borderWidth) :
                nil
            )
    }
}

struct FocusIndicatorModifier: ViewModifier {
    @FocusState private var isFocused: Bool
    
    func body(content: Content) -> some View {
        let config = VisualAccessibilityHelper.shared.focusIndicatorConfig()
        
        return content
            .focused($isFocused)
            .overlay(
                isFocused ?
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color(config.color), lineWidth: config.width) :
                nil
            )
    }
}

// MARK: - Notification Extensions

extension VisualAccessibilityHelper {
    /// Setup observers for accessibility setting changes
    func setupAccessibilityObservers() {
        let notificationCenter = NotificationCenter.default
        
        // High contrast changes
        notificationCenter.addObserver(
            forName: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            NotificationCenter.default.post(name: .visualAccessibilityChanged, object: nil)
        }
        
        // Reduce motion changes
        notificationCenter.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            NotificationCenter.default.post(name: .visualAccessibilityChanged, object: nil)
        }
        
        // Reduce transparency changes
        notificationCenter.addObserver(
            forName: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            NotificationCenter.default.post(name: .visualAccessibilityChanged, object: nil)
        }
        
        // Button shapes changes
        notificationCenter.addObserver(
            forName: UIAccessibility.buttonShapesEnabledStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            NotificationCenter.default.post(name: .visualAccessibilityChanged, object: nil)
        }
        
        // On/off labels changes
        notificationCenter.addObserver(
            forName: UIAccessibility.onOffSwitchLabelsDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            NotificationCenter.default.post(name: .visualAccessibilityChanged, object: nil)
        }
    }
}

extension Notification.Name {
    static let visualAccessibilityChanged = Notification.Name("VisualAccessibilityChanged")
}

// MARK: - Testing Support

#if DEBUG
extension VisualAccessibilityHelper {
    /// Simulate accessibility settings for testing
    /// - Parameters:
    ///   - highContrast: Simulate high contrast mode
    ///   - reduceMotion: Simulate reduce motion
    ///   - reduceTransparency: Simulate reduce transparency
    ///   - buttonShapes: Simulate button shapes
    func simulateAccessibilitySettings(
        highContrast: Bool = false,
        reduceMotion: Bool = false,
        reduceTransparency: Bool = false,
        buttonShapes: Bool = false
    ) {
        // This would be used for testing purposes
        // In a real implementation, you might use method swizzling or dependency injection
        print("Simulating accessibility settings:")
        print("  High Contrast: \(highContrast)")
        print("  Reduce Motion: \(reduceMotion)")
        print("  Reduce Transparency: \(reduceTransparency)")
        print("  Button Shapes: \(buttonShapes)")
    }
}
#endif