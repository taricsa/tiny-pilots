//
//  DynamicTypeHelper.swift
//  Tiny Pilots
//
//  Created by Kiro on Production Readiness Implementation
//

import UIKit
import SwiftUI
import SpriteKit

/// Helper class for managing Dynamic Type support throughout the app
class DynamicTypeHelper {
    static let shared = DynamicTypeHelper()
    
    private init() {}
    
    // MARK: - Font Scaling
    
    /// Get scaled font size based on current content size category
    /// - Parameters:
    ///   - baseSize: Base font size for standard content size
    ///   - textStyle: Text style to use for scaling reference
    /// - Returns: Scaled font size
    func scaledFontSize(baseSize: CGFloat, for textStyle: UIFont.TextStyle = .body) -> CGFloat {
        let fontMetrics = UIFontMetrics(forTextStyle: textStyle)
        return fontMetrics.scaledValue(for: baseSize)
    }
    
    /// Get scaled font for SpriteKit labels
    /// - Parameters:
    ///   - fontName: Font name
    ///   - baseSize: Base font size
    ///   - textStyle: Text style for scaling
    /// - Returns: Scaled font size
    func scaledSKFont(fontName: String, baseSize: CGFloat, for textStyle: UIFont.TextStyle = .body) -> CGFloat {
        return scaledFontSize(baseSize: baseSize, for: textStyle)
    }
    
    /// Get scaled SwiftUI font
    /// - Parameters:
    ///   - baseSize: Base font size
    ///   - weight: Font weight
    ///   - design: Font design
    ///   - textStyle: Text style for scaling
    /// - Returns: Scaled SwiftUI font
    func scaledFont(
        baseSize: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        for textStyle: UIFont.TextStyle = .body
    ) -> Font {
        let scaledSize = scaledFontSize(baseSize: baseSize, for: textStyle)
        return .system(size: scaledSize, weight: weight, design: design)
    }
    
    // MARK: - Layout Scaling
    
    /// Get scaled spacing value based on content size category
    /// - Parameter baseSpacing: Base spacing value
    /// - Returns: Scaled spacing value
    func scaledSpacing(_ baseSpacing: CGFloat) -> CGFloat {
        let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        let scaleFactor = getScaleFactor(for: contentSizeCategory)
        return baseSpacing * scaleFactor
    }
    
    /// Get scaled padding value based on content size category
    /// - Parameter basePadding: Base padding value
    /// - Returns: Scaled padding value
    func scaledPadding(_ basePadding: CGFloat) -> CGFloat {
        return scaledSpacing(basePadding)
    }
    
    /// Get scaled corner radius based on content size category
    /// - Parameter baseRadius: Base corner radius
    /// - Returns: Scaled corner radius
    func scaledCornerRadius(_ baseRadius: CGFloat) -> CGFloat {
        let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        let scaleFactor = getScaleFactor(for: contentSizeCategory)
        return baseRadius * min(scaleFactor, 1.5) // Cap corner radius scaling
    }
    
    // MARK: - Content Size Category Helpers
    
    /// Check if current content size category is an accessibility size
    var isAccessibilitySize: Bool {
        return UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
    }
    
    /// Get current content size category
    var currentContentSizeCategory: UIContentSizeCategory {
        return UIApplication.shared.preferredContentSizeCategory
    }
    
    /// Get scale factor for a given content size category
    /// - Parameter category: Content size category
    /// - Returns: Scale factor (1.0 = normal size)
    private func getScaleFactor(for category: UIContentSizeCategory) -> CGFloat {
        switch category {
        case .extraSmall:
            return 0.8
        case .small:
            return 0.9
        case .medium:
            return 1.0
        case .large:
            return 1.0 // Default size
        case .extraLarge:
            return 1.1
        case .extraExtraLarge:
            return 1.2
        case .extraExtraExtraLarge:
            return 1.3
        case .accessibilityMedium:
            return 1.4
        case .accessibilityLarge:
            return 1.6
        case .accessibilityExtraLarge:
            return 1.8
        case .accessibilityExtraExtraLarge:
            return 2.0
        case .accessibilityExtraExtraExtraLarge:
            return 2.2
        default:
            return 1.0
        }
    }
    
    // MARK: - Layout Adjustment Helpers
    
    /// Determine if layout should be adjusted for large text
    var shouldUseCompactLayout: Bool {
        let category = currentContentSizeCategory
        return category.rawValue.contains("accessibility") || 
               category == .extraExtraExtraLarge
    }
    
    /// Get recommended minimum touch target size for current accessibility settings
    var minimumTouchTargetSize: CGSize {
        let baseSize: CGFloat = 44.0 // Apple's recommended minimum
        let scaleFactor = getScaleFactor(for: currentContentSizeCategory)
        let scaledSize = baseSize * scaleFactor
        return CGSize(width: scaledSize, height: scaledSize)
    }
    
    /// Get recommended button height for current text size
    /// - Parameter baseHeight: Base button height
    /// - Returns: Scaled button height
    func scaledButtonHeight(_ baseHeight: CGFloat) -> CGFloat {
        let scaleFactor = getScaleFactor(for: currentContentSizeCategory)
        let scaledHeight = baseHeight * scaleFactor
        return max(scaledHeight, minimumTouchTargetSize.height)
    }
    
    // MARK: - Text Layout Helpers
    
    /// Calculate number of lines needed for text at current size
    /// - Parameters:
    ///   - text: Text to measure
    ///   - font: Font to use
    ///   - width: Available width
    /// - Returns: Number of lines needed
    func numberOfLines(for text: String, font: UIFont, width: CGFloat) -> Int {
        let textSize = text.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        
        let lineHeight = font.lineHeight
        return max(1, Int(ceil(textSize.height / lineHeight)))
    }
    
    /// Check if text will fit in given bounds at current size
    /// - Parameters:
    ///   - text: Text to check
    ///   - font: Font to use
    ///   - bounds: Available bounds
    /// - Returns: True if text fits
    func textFits(_ text: String, font: UIFont, in bounds: CGSize) -> Bool {
        let textSize = text.boundingRect(
            with: bounds,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        
        return textSize.width <= bounds.width && textSize.height <= bounds.height
    }
}

// MARK: - SwiftUI Extensions

extension View {
    /// Apply dynamic type scaling to a view
    /// - Parameter baseSize: Base size for scaling reference
    /// - Returns: View with dynamic type scaling applied
    func dynamicTypeSize(baseSize: CGFloat = 16) -> some View {
        let scaledSize = DynamicTypeHelper.shared.scaledFontSize(baseSize: baseSize)
        return self.font(.system(size: scaledSize))
    }
    
    /// Apply scaled padding based on dynamic type
    /// - Parameter basePadding: Base padding value
    /// - Returns: View with scaled padding
    func scaledPadding(_ basePadding: CGFloat) -> some View {
        let scaledPadding = DynamicTypeHelper.shared.scaledPadding(basePadding)
        return self.padding(scaledPadding)
    }
    
    /// Apply scaled spacing based on dynamic type
    /// - Parameter baseSpacing: Base spacing value
    /// - Returns: View with scaled spacing
    func scaledSpacing(_ baseSpacing: CGFloat) -> some View {
        let scaledSpacing = DynamicTypeHelper.shared.scaledSpacing(baseSpacing)
        return self.padding(.vertical, scaledSpacing / 2)
    }
    
    /// Apply minimum touch target size for accessibility
    /// - Returns: View with minimum touch target size
    func minimumTouchTarget() -> some View {
        let minSize = DynamicTypeHelper.shared.minimumTouchTargetSize
        return self.frame(minWidth: minSize.width, minHeight: minSize.height)
    }
    
    /// Apply dynamic type responsive layout
    /// - Parameters:
    ///   - compact: View to show for large text sizes
    ///   - regular: View to show for normal text sizes
    /// - Returns: Appropriate view based on text size
    func dynamicTypeLayout<Compact: View, Regular: View>(
        compact: () -> Compact,
        regular: () -> Regular
    ) -> some View {
        Group {
            if DynamicTypeHelper.shared.shouldUseCompactLayout {
                compact()
            } else {
                regular()
            }
        }
    }
}

// MARK: - UIKit Extensions

extension UILabel {
    /// Configure label for dynamic type support
    /// - Parameters:
    ///   - textStyle: Text style to use
    ///   - baseSize: Base font size (optional, uses text style default if nil)
    func configureDynamicType(textStyle: UIFont.TextStyle, baseSize: CGFloat? = nil) {
        adjustsFontForContentSizeCategory = true
        
        if let baseSize = baseSize {
            let scaledSize = DynamicTypeHelper.shared.scaledFontSize(baseSize: baseSize, for: textStyle)
            font = UIFont.systemFont(ofSize: scaledSize)
        } else {
            font = UIFont.preferredFont(forTextStyle: textStyle)
        }
        
        numberOfLines = 0 // Allow multiple lines for accessibility
    }
}

extension UIButton {
    /// Configure button for dynamic type support
    /// - Parameters:
    ///   - textStyle: Text style to use
    ///   - baseSize: Base font size (optional)
    func configureDynamicType(textStyle: UIFont.TextStyle, baseSize: CGFloat? = nil) {
        titleLabel?.configureDynamicType(textStyle: textStyle, baseSize: baseSize)
        
        // Ensure minimum touch target size
        let minSize = DynamicTypeHelper.shared.minimumTouchTargetSize
        if bounds.width < minSize.width || bounds.height < minSize.height {
            frame = CGRect(
                origin: frame.origin,
                size: CGSize(
                    width: max(frame.width, minSize.width),
                    height: max(frame.height, minSize.height)
                )
            )
        }
    }
}

// MARK: - SpriteKit Extensions

extension SKLabelNode {
    /// Configure SpriteKit label for dynamic type support
    /// - Parameters:
    ///   - baseSize: Base font size
    ///   - textStyle: Text style for scaling reference
    func configureDynamicType(baseSize: CGFloat, textStyle: UIFont.TextStyle = .body) {
        let scaledSize = DynamicTypeHelper.shared.scaledSKFont(
            fontName: fontName ?? "Helvetica",
            baseSize: baseSize,
            for: textStyle
        )
        fontSize = scaledSize
        
        // Adjust line break mode for accessibility
        if DynamicTypeHelper.shared.isAccessibilitySize {
            lineBreakMode = .byWordWrapping
            numberOfLines = 0
        }
    }
    
    /// Update font size when content size category changes
    /// - Parameters:
    ///   - baseSize: Base font size
    ///   - textStyle: Text style for scaling reference
    func updateDynamicType(baseSize: CGFloat, textStyle: UIFont.TextStyle = .body) {
        configureDynamicType(baseSize: baseSize, textStyle: textStyle)
    }
}

// MARK: - Dynamic Type Notification Observer

/// Observer for dynamic type changes
class DynamicTypeObserver: ObservableObject {
    @Published var contentSizeCategory: UIContentSizeCategory
    
    init() {
        self.contentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        
        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.contentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Preview Helpers

#if DEBUG
/// Helper for previewing different content size categories in SwiftUI
struct DynamicTypePreview<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(ContentSizeCategory.allCases, id: \.self) { category in
                    VStack {
                        Text(category.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        content
                            .environment(\.sizeCategory, category)
                            .border(Color.gray.opacity(0.3))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Dynamic Type Preview")
    }
}

extension ContentSizeCategory {
    var displayName: String {
        switch self {
        case .extraSmall: return "Extra Small"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large (Default)"
        case .extraLarge: return "Extra Large"
        case .extraExtraLarge: return "Extra Extra Large"
        case .extraExtraExtraLarge: return "Extra Extra Extra Large"
        case .accessibilityMedium: return "Accessibility Medium"
        case .accessibilityLarge: return "Accessibility Large"
        case .accessibilityExtraLarge: return "Accessibility Extra Large"
        case .accessibilityExtraExtraLarge: return "Accessibility Extra Extra Large"
        case .accessibilityExtraExtraExtraLarge: return "Accessibility Extra Extra Extra Large"
        @unknown default: return "Unknown"
        }
    }
    
    static var allCases: [ContentSizeCategory] {
        return [
            .extraSmall, .small, .medium, .large, .extraLarge,
            .extraExtraLarge, .extraExtraExtraLarge,
            .accessibilityMedium, .accessibilityLarge, .accessibilityExtraLarge,
            .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge
        ]
    }
}
#endif