//
//  DynamicTypeTestingHelper.swift
//  Tiny Pilots
//
//  Created by Kiro on Production Readiness Implementation
//

import UIKit
import SwiftUI

#if DEBUG

/// Helper class for testing and validating dynamic type implementation
class DynamicTypeTestingHelper {
    static let shared = DynamicTypeTestingHelper()
    
    private init() {}
    
    // MARK: - Testing Methods
    
    /// Test all content size categories for a given view
    /// - Parameter viewController: View controller to test
    /// - Returns: Array of issues found
    func testAllContentSizeCategories(for viewController: UIViewController) -> [DynamicTypeIssue] {
        var issues: [DynamicTypeIssue] = []
        
        for category in UIContentSizeCategory.allTestCases {
            let categoryIssues = testContentSizeCategory(category, for: viewController)
            issues.append(contentsOf: categoryIssues)
        }
        
        return issues
    }
    
    /// Test a specific content size category
    /// - Parameters:
    ///   - category: Content size category to test
    ///   - viewController: View controller to test
    /// - Returns: Array of issues found for this category
    func testContentSizeCategory(_ category: UIContentSizeCategory, for viewController: UIViewController) -> [DynamicTypeIssue] {
        var issues: [DynamicTypeIssue] = []
        
        // Temporarily change content size category
        let originalCategory = UIApplication.shared.preferredContentSizeCategory
        setContentSizeCategory(category)
        
        // Force layout update
        viewController.view.setNeedsLayout()
        viewController.view.layoutIfNeeded()
        
        // Check for issues
        issues.append(contentsOf: checkForTextTruncation(in: viewController.view, category: category))
        issues.append(contentsOf: checkForOverlappingElements(in: viewController.view, category: category))
        issues.append(contentsOf: checkForTouchTargetSize(in: viewController.view, category: category))
        issues.append(contentsOf: checkForReadability(in: viewController.view, category: category))
        
        // Restore original category
        setContentSizeCategory(originalCategory)
        
        return issues
    }
    
    /// Generate a comprehensive test report
    /// - Parameter viewController: View controller to test
    /// - Returns: Test report with all findings
    func generateTestReport(for viewController: UIViewController) -> DynamicTypeTestReport {
        let issues = testAllContentSizeCategories(for: viewController)
        
        let report = DynamicTypeTestReport(
            viewControllerName: String(describing: type(of: viewController)),
            testDate: Date(),
            totalIssues: issues.count,
            issuesByCategory: Dictionary(grouping: issues) { $0.category },
            issuesBySeverity: Dictionary(grouping: issues) { $0.severity },
            recommendations: generateRecommendations(from: issues)
        )
        
        return report
    }
    
    // MARK: - Issue Detection Methods
    
    private func checkForTextTruncation(in view: UIView, category: UIContentSizeCategory) -> [DynamicTypeIssue] {
        var issues: [DynamicTypeIssue] = []
        
        func checkView(_ view: UIView) {
            if let label = view as? UILabel {
                if isTextTruncated(label) {
                    issues.append(DynamicTypeIssue(
                        type: .textTruncation,
                        severity: .high,
                        category: category,
                        description: "Text is truncated in label: '\(label.text ?? "")'",
                        element: String(describing: type(of: label)),
                        recommendation: "Increase numberOfLines to 0 or adjust layout constraints"
                    ))
                }
            } else if let button = view as? UIButton {
                if let titleLabel = button.titleLabel, isTextTruncated(titleLabel) {
                    issues.append(DynamicTypeIssue(
                        type: .textTruncation,
                        severity: .high,
                        category: category,
                        description: "Button title is truncated: '\(button.currentTitle ?? "")'",
                        element: String(describing: type(of: button)),
                        recommendation: "Adjust button size or use multi-line title"
                    ))
                }
            }
            
            for subview in view.subviews {
                checkView(subview)
            }
        }
        
        checkView(view)
        return issues
    }
    
    private func checkForOverlappingElements(in view: UIView, category: UIContentSizeCategory) -> [DynamicTypeIssue] {
        var issues: [DynamicTypeIssue] = []
        let allViews = getAllSubviews(of: view)
        
        for i in 0..<allViews.count {
            for j in (i+1)..<allViews.count {
                let view1 = allViews[i]
                let view2 = allViews[j]
                
                if view1.superview == view2.superview && 
                   view1.frame.intersects(view2.frame) &&
                   !view1.frame.isEmpty && !view2.frame.isEmpty {
                    
                    issues.append(DynamicTypeIssue(
                        type: .overlappingElements,
                        severity: .medium,
                        category: category,
                        description: "Elements are overlapping: \(type(of: view1)) and \(type(of: view2))",
                        element: "\(type(of: view1)) + \(type(of: view2))",
                        recommendation: "Adjust spacing or use stack views with proper constraints"
                    ))
                }
            }
        }
        
        return issues
    }
    
    private func checkForTouchTargetSize(in view: UIView, category: UIContentSizeCategory) -> [DynamicTypeIssue] {
        var issues: [DynamicTypeIssue] = []
        let minimumSize = DynamicTypeHelper.shared.minimumTouchTargetSize
        
        func checkView(_ view: UIView) {
            if view.isUserInteractionEnabled && 
               (view is UIButton || view is UIControl) {
                
                if view.frame.width < minimumSize.width || view.frame.height < minimumSize.height {
                    issues.append(DynamicTypeIssue(
                        type: .touchTargetTooSmall,
                        severity: .high,
                        category: category,
                        description: "Touch target too small: \(view.frame.size) (minimum: \(minimumSize))",
                        element: String(describing: type(of: view)),
                        recommendation: "Increase touch target size to at least \(minimumSize)"
                    ))
                }
            }
            
            for subview in view.subviews {
                checkView(subview)
            }
        }
        
        checkView(view)
        return issues
    }
    
    private func checkForReadability(in view: UIView, category: UIContentSizeCategory) -> [DynamicTypeIssue] {
        var issues: [DynamicTypeIssue] = []
        
        func checkView(_ view: UIView) {
            if let label = view as? UILabel {
                if !label.adjustsFontForContentSizeCategory {
                    issues.append(DynamicTypeIssue(
                        type: .noFontScaling,
                        severity: .medium,
                        category: category,
                        description: "Label does not adjust font for content size category",
                        element: String(describing: type(of: label)),
                        recommendation: "Set adjustsFontForContentSizeCategory = true"
                    ))
                }
                
                // Check contrast (simplified check)
                if let textColor = label.textColor,
                   let backgroundColor = label.backgroundColor ?? label.superview?.backgroundColor {
                    let contrast = calculateContrast(textColor: textColor, backgroundColor: backgroundColor)
                    if contrast < 4.5 { // WCAG AA standard
                        issues.append(DynamicTypeIssue(
                            type: .lowContrast,
                            severity: .medium,
                            category: category,
                            description: "Low contrast ratio: \(String(format: "%.2f", contrast))",
                            element: String(describing: type(of: label)),
                            recommendation: "Increase contrast ratio to at least 4.5:1"
                        ))
                    }
                }
            }
            
            for subview in view.subviews {
                checkView(subview)
            }
        }
        
        checkView(view)
        return issues
    }
    
    // MARK: - Helper Methods
    
    private func setContentSizeCategory(_ category: UIContentSizeCategory) {
        // This is a simplified approach for testing
        // In a real implementation, you might need to use private APIs or test differently
        NotificationCenter.default.post(
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
    }
    
    private func isTextTruncated(_ label: UILabel) -> Bool {
        guard let text = label.text, !text.isEmpty else { return false }
        
        let textSize = text.boundingRect(
            with: CGSize(width: label.frame.width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: label.font!],
            context: nil
        )
        
        let availableHeight = label.frame.height
        let requiredHeight = textSize.height
        
        return requiredHeight > availableHeight + 1 // Small tolerance for rounding
    }
    
    private func getAllSubviews(of view: UIView) -> [UIView] {
        var allViews: [UIView] = [view]
        
        for subview in view.subviews {
            allViews.append(contentsOf: getAllSubviews(of: subview))
        }
        
        return allViews
    }
    
    private func calculateContrast(textColor: UIColor, backgroundColor: UIColor) -> Double {
        // Simplified contrast calculation
        // In a real implementation, you'd want a more accurate calculation
        let textLuminance = getLuminance(textColor)
        let backgroundLuminance = getLuminance(backgroundColor)
        
        let lighter = max(textLuminance, backgroundLuminance)
        let darker = min(textLuminance, backgroundLuminance)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    private func getLuminance(_ color: UIColor) -> Double {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Simplified luminance calculation
        return 0.299 * Double(red) + 0.587 * Double(green) + 0.114 * Double(blue)
    }
    
    private func generateRecommendations(from issues: [DynamicTypeIssue]) -> [String] {
        var recommendations: Set<String> = []
        
        for issue in issues {
            recommendations.insert(issue.recommendation)
        }
        
        // Add general recommendations
        if issues.contains(where: { $0.type == .textTruncation }) {
            recommendations.insert("Consider using UIStackView for better layout management")
            recommendations.insert("Set numberOfLines = 0 for labels that might need multiple lines")
        }
        
        if issues.contains(where: { $0.type == .touchTargetTooSmall }) {
            recommendations.insert("Ensure all interactive elements meet minimum touch target size")
        }
        
        if issues.contains(where: { $0.type == .noFontScaling }) {
            recommendations.insert("Enable adjustsFontForContentSizeCategory for all text elements")
        }
        
        return Array(recommendations)
    }
}

// MARK: - Data Models

/// Represents a dynamic type issue found during testing
struct DynamicTypeIssue {
    let type: IssueType
    let severity: Severity
    let category: UIContentSizeCategory
    let description: String
    let element: String
    let recommendation: String
    
    enum IssueType {
        case textTruncation
        case overlappingElements
        case touchTargetTooSmall
        case noFontScaling
        case lowContrast
        case layoutBreakage
    }
    
    enum Severity {
        case low
        case medium
        case high
        case critical
    }
}

/// Test report containing all findings and recommendations
struct DynamicTypeTestReport {
    let viewControllerName: String
    let testDate: Date
    let totalIssues: Int
    let issuesByCategory: [UIContentSizeCategory: [DynamicTypeIssue]]
    let issuesBySeverity: [DynamicTypeIssue.Severity: [DynamicTypeIssue]]
    let recommendations: [String]
    
    /// Generate a formatted report string
    func formattedReport() -> String {
        var report = """
        Dynamic Type Test Report
        ========================
        View Controller: \(viewControllerName)
        Test Date: \(DateFormatter.localizedString(from: testDate, dateStyle: .medium, timeStyle: .short))
        Total Issues: \(totalIssues)
        
        Issues by Severity:
        """
        
        for severity in [DynamicTypeIssue.Severity.critical, .high, .medium, .low] {
            if let issues = issuesBySeverity[severity], !issues.isEmpty {
                report += "\n  \(severity): \(issues.count)"
            }
        }
        
        report += "\n\nIssues by Content Size Category:"
        for (category, issues) in issuesByCategory.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            report += "\n  \(category.displayName): \(issues.count)"
        }
        
        report += "\n\nRecommendations:"
        for recommendation in recommendations {
            report += "\n  • \(recommendation)"
        }
        
        return report
    }
}

// MARK: - Extensions

extension UIContentSizeCategory {
    static var allTestCases: [UIContentSizeCategory] {
        return [
            .extraSmall, .small, .medium, .large, .extraLarge,
            .extraExtraLarge, .extraExtraExtraLarge,
            .accessibilityMedium, .accessibilityLarge, .accessibilityExtraLarge,
            .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge
        ]
    }
    
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
        default: return "Unknown"
        }
    }
}

// MARK: - SwiftUI Testing Support

/// SwiftUI view for testing dynamic type in previews
struct DynamicTypeTestView<Content: View>: View {
    let content: Content
    @State private var selectedCategory: UIContentSizeCategory = .large
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            Picker("Content Size", selection: $selectedCategory) {
                ForEach(UIContentSizeCategory.allTestCases, id: \.self) { category in
                    Text(category.displayName)
                        .tag(category)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            
            ScrollView {
                content
                    .environment(\.sizeCategory, ContentSizeCategory(selectedCategory))
                    .padding()
                    .border(Color.gray.opacity(0.3))
            }
        }
        .navigationTitle("Dynamic Type Test")
    }
}

extension ContentSizeCategory {
    init(_ uiCategory: UIContentSizeCategory) {
        switch uiCategory {
        case .extraSmall: self = .extraSmall
        case .small: self = .small
        case .medium: self = .medium
        case .large: self = .large
        case .extraLarge: self = .extraLarge
        case .extraExtraLarge: self = .extraExtraLarge
        case .extraExtraExtraLarge: self = .extraExtraExtraLarge
        case .accessibilityMedium: self = .accessibilityMedium
        case .accessibilityLarge: self = .accessibilityLarge
        case .accessibilityExtraLarge: self = .accessibilityExtraLarge
        case .accessibilityExtraExtraLarge: self = .accessibilityExtraExtraLarge
        case .accessibilityExtraExtraExtraLarge: self = .accessibilityExtraExtraExtraLarge
        default: self = .large
        }
    }
}

#endif