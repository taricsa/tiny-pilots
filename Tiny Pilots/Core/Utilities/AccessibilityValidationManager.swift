//
//  AccessibilityValidationManager.swift
//  Tiny Pilots
//
//  Created by Kiro on Production Readiness Implementation
//

import UIKit
import SwiftUI

/// Manager for validating accessibility implementation and generating reports
class AccessibilityValidationManager {
    static let shared = AccessibilityValidationManager()
    
    private init() {}
    
    // MARK: - Validation Methods
    
    /// Validate accessibility implementation for a view controller
    /// - Parameter viewController: View controller to validate
    /// - Returns: Validation report
    func validateAccessibility(for viewController: UIViewController) -> AccessibilityValidationReport {
        let startTime = Date()
        
        // Load view if needed
        viewController.loadViewIfNeeded()
        
        var issues: [AccessibilityIssue] = []
        
        // Run all validation checks
        issues.append(contentsOf: validateAccessibilityLabels(in: viewController.view))
        issues.append(contentsOf: validateTouchTargets(in: viewController.view))
        issues.append(contentsOf: validateColorContrast(in: viewController.view))
        issues.append(contentsOf: validateDynamicType(in: viewController.view))
        issues.append(contentsOf: validateNavigationOrder(in: viewController.view))
        issues.append(contentsOf: validateFocusManagement(in: viewController.view))
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        return AccessibilityValidationReport(
            viewControllerName: String(describing: type(of: viewController)),
            validationDate: startTime,
            validationDuration: duration,
            totalIssues: issues.count,
            issues: issues,
            score: calculateAccessibilityScore(from: issues),
            recommendations: generateRecommendations(from: issues)
        )
    }
    
    /// Validate accessibility for multiple view controllers
    /// - Parameter viewControllers: Array of view controllers to validate
    /// - Returns: Comprehensive validation report
    func validateAccessibility(for viewControllers: [UIViewController]) -> ComprehensiveAccessibilityReport {
        let startTime = Date()
        var reports: [AccessibilityValidationReport] = []
        
        for viewController in viewControllers {
            let report = validateAccessibility(for: viewController)
            reports.append(report)
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        return ComprehensiveAccessibilityReport(
            reports: reports,
            validationDate: startTime,
            validationDuration: duration,
            overallScore: calculateOverallScore(from: reports),
            summary: generateSummary(from: reports)
        )
    }
    
    // MARK: - Individual Validation Methods
    
    private func validateAccessibilityLabels(in view: UIView) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        func checkView(_ view: UIView, path: String = "") {
            let currentPath = path.isEmpty ? String(describing: type(of: view)) : "\(path) > \(type(of: view))"
            
            // Check if interactive elements have accessibility labels
            if view.isUserInteractionEnabled && (view is UIButton || view is UIControl) {
                if !view.isAccessibilityElement {
                    issues.append(AccessibilityIssue(
                        type: .missingAccessibilityElement,
                        severity: .high,
                        description: "Interactive element is not marked as accessibility element",
                        location: currentPath,
                        element: String(describing: type(of: view)),
                        recommendation: "Set isAccessibilityElement = true"
                    ))
                } else if view.accessibilityLabel?.isEmpty != false {
                    issues.append(AccessibilityIssue(
                        type: .missingAccessibilityLabel,
                        severity: .high,
                        description: "Interactive element missing accessibility label",
                        location: currentPath,
                        element: String(describing: type(of: view)),
                        recommendation: "Provide descriptive accessibility label"
                    ))
                }
            }
            
            // Check labels and text elements
            if let label = view as? UILabel {
                if label.isAccessibilityElement && label.accessibilityLabel?.isEmpty != false {
                    issues.append(AccessibilityIssue(
                        type: .missingAccessibilityLabel,
                        severity: .medium,
                        description: "Label missing accessibility label",
                        location: currentPath,
                        element: "UILabel",
                        recommendation: "Set accessibility label or use text content"
                    ))
                }
            }
            
            // Check for buttons without hints
            if let button = view as? UIButton {
                if button.isAccessibilityElement && button.accessibilityHint?.isEmpty != false {
                    issues.append(AccessibilityIssue(
                        type: .missingAccessibilityHint,
                        severity: .low,
                        description: "Button missing accessibility hint",
                        location: currentPath,
                        element: "UIButton",
                        recommendation: "Provide accessibility hint explaining button action"
                    ))
                }
            }
            
            for subview in view.subviews {
                checkView(subview, path: currentPath)
            }
        }
        
        checkView(view)
        return issues
    }
    
    private func validateTouchTargets(in view: UIView) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        let minimumSize = DynamicTypeHelper.shared.minimumTouchTargetSize
        
        func checkView(_ view: UIView, path: String = "") {
            let currentPath = path.isEmpty ? String(describing: type(of: view)) : "\(path) > \(type(of: view))"
            
            if view.isUserInteractionEnabled && (view is UIButton || view is UIControl) {
                let frame = view.frame
                if frame.width < minimumSize.width || frame.height < minimumSize.height {
                    issues.append(AccessibilityIssue(
                        type: .touchTargetTooSmall,
                        severity: .high,
                        description: "Touch target smaller than minimum size (\(minimumSize))",
                        location: currentPath,
                        element: String(describing: type(of: view)),
                        recommendation: "Increase touch target size to at least \(minimumSize.width)x\(minimumSize.height)"
                    ))
                }
            }
            
            for subview in view.subviews {
                checkView(subview, path: currentPath)
            }
        }
        
        checkView(view)
        return issues
    }
    
    private func validateColorContrast(in view: UIView) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        func checkView(_ view: UIView, path: String = "") {
            let currentPath = path.isEmpty ? String(describing: type(of: view)) : "\(path) > \(type(of: view))"
            
            if let label = view as? UILabel,
               let textColor = label.textColor,
               let backgroundColor = getEffectiveBackgroundColor(for: label) {
                
                let contrast = calculateContrast(textColor: textColor, backgroundColor: backgroundColor)
                if contrast < 4.5 {
                    let severity: AccessibilityIssue.Severity = contrast < 3.0 ? .high : .medium
                    issues.append(AccessibilityIssue(
                        type: .lowColorContrast,
                        severity: severity,
                        description: "Color contrast ratio too low: \(String(format: "%.2f", contrast))",
                        location: currentPath,
                        element: "UILabel",
                        recommendation: "Increase contrast ratio to at least 4.5:1 (WCAG AA)"
                    ))
                }
            }
            
            for subview in view.subviews {
                checkView(subview, path: currentPath)
            }
        }
        
        checkView(view)
        return issues
    }
    
    private func validateDynamicType(in view: UIView) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        func checkView(_ view: UIView, path: String = "") {
            let currentPath = path.isEmpty ? String(describing: type(of: view)) : "\(path) > \(type(of: view))"
            
            if let label = view as? UILabel {
                if !label.adjustsFontForContentSizeCategory {
                    issues.append(AccessibilityIssue(
                        type: .noDynamicTypeSupport,
                        severity: .medium,
                        description: "Label does not support Dynamic Type",
                        location: currentPath,
                        element: "UILabel",
                        recommendation: "Set adjustsFontForContentSizeCategory = true"
                    ))
                }
                
                if label.numberOfLines == 1 && DynamicTypeHelper.shared.isAccessibilitySize {
                    issues.append(AccessibilityIssue(
                        type: .textTruncation,
                        severity: .medium,
                        description: "Single-line label may truncate with large text",
                        location: currentPath,
                        element: "UILabel",
                        recommendation: "Set numberOfLines = 0 to allow text wrapping"
                    ))
                }
            }
            
            if let button = view as? UIButton {
                if let titleLabel = button.titleLabel, !titleLabel.adjustsFontForContentSizeCategory {
                    issues.append(AccessibilityIssue(
                        type: .noDynamicTypeSupport,
                        severity: .medium,
                        description: "Button title does not support Dynamic Type",
                        location: currentPath,
                        element: "UIButton",
                        recommendation: "Configure button title for Dynamic Type support"
                    ))
                }
            }
            
            for subview in view.subviews {
                checkView(subview, path: currentPath)
            }
        }
        
        checkView(view)
        return issues
    }
    
    private func validateNavigationOrder(in view: UIView) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        let accessibleElements = getAllAccessibleElements(in: view)
        
        // Check for logical navigation order
        for (index, element) in accessibleElements.enumerated() {
            if index > 0 {
                let previousElement = accessibleElements[index - 1]
                let currentElement = element
                
                // Check if elements are in logical visual order
                if !isLogicalNavigationOrder(from: previousElement, to: currentElement) {
                    issues.append(AccessibilityIssue(
                        type: .illogicalNavigationOrder,
                        severity: .low,
                        description: "Navigation order may not follow visual layout",
                        location: String(describing: type(of: element)),
                        element: String(describing: type(of: element)),
                        recommendation: "Review and adjust accessibility navigation order"
                    ))
                }
            }
        }
        
        return issues
    }
    
    private func validateFocusManagement(in view: UIView) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        // Check for focus traps and proper focus management
        let accessibleElements = getAllAccessibleElements(in: view)
        
        if accessibleElements.isEmpty {
            issues.append(AccessibilityIssue(
                type: .noAccessibleElements,
                severity: .high,
                description: "No accessible elements found in view",
                location: String(describing: type(of: view)),
                element: String(describing: type(of: view)),
                recommendation: "Ensure interactive elements are properly configured for accessibility"
            ))
        }
        
        return issues
    }
    
    // MARK: - Helper Methods
    
    private func getEffectiveBackgroundColor(for view: UIView) -> UIColor? {
        var currentView: UIView? = view
        
        while let view = currentView {
            if let backgroundColor = view.backgroundColor, backgroundColor != .clear {
                return backgroundColor
            }
            currentView = view.superview
        }
        
        return .systemBackground // Default system background
    }
    
    private func calculateContrast(textColor: UIColor, backgroundColor: UIColor) -> Double {
        let textLuminance = getLuminance(of: textColor)
        let backgroundLuminance = getLuminance(of: backgroundColor)
        
        let lighter = max(textLuminance, backgroundLuminance)
        let darker = min(textLuminance, backgroundLuminance)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    private func getLuminance(of color: UIColor) -> Double {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Convert to linear RGB
        let linearRed = red <= 0.03928 ? red / 12.92 : pow((red + 0.055) / 1.055, 2.4)
        let linearGreen = green <= 0.03928 ? green / 12.92 : pow((green + 0.055) / 1.055, 2.4)
        let linearBlue = blue <= 0.03928 ? blue / 12.92 : pow((blue + 0.055) / 1.055, 2.4)
        
        return 0.2126 * Double(linearRed) + 0.7152 * Double(linearGreen) + 0.0722 * Double(linearBlue)
    }
    
    private func getAllAccessibleElements(in view: UIView) -> [UIView] {
        var elements: [UIView] = []
        
        func collectElements(_ view: UIView) {
            if view.isAccessibilityElement {
                elements.append(view)
            }
            
            for subview in view.subviews {
                collectElements(subview)
            }
        }
        
        collectElements(view)
        return elements
    }
    
    private func isLogicalNavigationOrder(from previousElement: UIView, to currentElement: UIView) -> Bool {
        // Simple heuristic: elements should generally be ordered top-to-bottom, left-to-right
        let previousFrame = previousElement.frame
        let currentFrame = currentElement.frame
        
        // If current element is significantly below previous element, order is logical
        if currentFrame.minY > previousFrame.maxY + 10 {
            return true
        }
        
        // If on same row, left-to-right order is logical
        if abs(currentFrame.midY - previousFrame.midY) < 20 {
            return currentFrame.minX >= previousFrame.minX
        }
        
        return true // Default to assuming order is logical
    }
    
    private func calculateAccessibilityScore(from issues: [AccessibilityIssue]) -> AccessibilityScore {
        let totalPossiblePoints = 100
        var deductions = 0
        
        for issue in issues {
            switch issue.severity {
            case .critical:
                deductions += 25
            case .high:
                deductions += 15
            case .medium:
                deductions += 8
            case .low:
                deductions += 3
            }
        }
        
        let score = max(0, totalPossiblePoints - deductions)
        let grade = getGrade(for: score)
        
        return AccessibilityScore(
            score: score,
            maxScore: totalPossiblePoints,
            grade: grade,
            criticalIssues: issues.filter { $0.severity == .critical }.count,
            highIssues: issues.filter { $0.severity == .high }.count,
            mediumIssues: issues.filter { $0.severity == .medium }.count,
            lowIssues: issues.filter { $0.severity == .low }.count
        )
    }
    
    private func getGrade(for score: Int) -> String {
        switch score {
        case 90...100: return "A"
        case 80...89: return "B"
        case 70...79: return "C"
        case 60...69: return "D"
        default: return "F"
        }
    }
    
    private func generateRecommendations(from issues: [AccessibilityIssue]) -> [String] {
        var recommendations: Set<String> = []
        
        for issue in issues {
            recommendations.insert(issue.recommendation)
        }
        
        // Add general recommendations based on issue patterns
        let issueTypes = Set(issues.map { $0.type })
        
        if issueTypes.contains(.missingAccessibilityLabel) {
            recommendations.insert("Review all interactive elements and ensure they have descriptive accessibility labels")
        }
        
        if issueTypes.contains(.touchTargetTooSmall) {
            recommendations.insert("Ensure all touch targets meet minimum size requirements (44x44 points)")
        }
        
        if issueTypes.contains(.lowColorContrast) {
            recommendations.insert("Review color choices to ensure sufficient contrast ratios")
        }
        
        if issueTypes.contains(.noDynamicTypeSupport) {
            recommendations.insert("Enable Dynamic Type support for all text elements")
        }
        
        return Array(recommendations)
    }
    
    private func calculateOverallScore(from reports: [AccessibilityValidationReport]) -> AccessibilityScore {
        guard !reports.isEmpty else {
            return AccessibilityScore(score: 0, maxScore: 100, grade: "F", criticalIssues: 0, highIssues: 0, mediumIssues: 0, lowIssues: 0)
        }
        
        let totalScore = reports.reduce(0) { $0 + $1.score.score }
        let averageScore = totalScore / reports.count
        
        let totalCritical = reports.reduce(0) { $0 + $1.score.criticalIssues }
        let totalHigh = reports.reduce(0) { $0 + $1.score.highIssues }
        let totalMedium = reports.reduce(0) { $0 + $1.score.mediumIssues }
        let totalLow = reports.reduce(0) { $0 + $1.score.lowIssues }
        
        return AccessibilityScore(
            score: averageScore,
            maxScore: 100,
            grade: getGrade(for: averageScore),
            criticalIssues: totalCritical,
            highIssues: totalHigh,
            mediumIssues: totalMedium,
            lowIssues: totalLow
        )
    }
    
    private func generateSummary(from reports: [AccessibilityValidationReport]) -> String {
        let totalIssues = reports.reduce(0) { $0 + $1.totalIssues }
        let averageScore = reports.reduce(0) { $0 + $1.score.score } / max(1, reports.count)
        
        return """
        Accessibility Validation Summary:
        - \(reports.count) view controllers tested
        - \(totalIssues) total issues found
        - Average accessibility score: \(averageScore)/100
        - Overall grade: \(getGrade(for: averageScore))
        """
    }
}

// MARK: - Data Models

/// Represents an accessibility issue found during validation
struct AccessibilityIssue {
    let type: IssueType
    let severity: Severity
    let description: String
    let location: String
    let element: String
    let recommendation: String
    
    enum IssueType {
        case missingAccessibilityLabel
        case missingAccessibilityHint
        case missingAccessibilityElement
        case touchTargetTooSmall
        case lowColorContrast
        case noDynamicTypeSupport
        case textTruncation
        case illogicalNavigationOrder
        case noAccessibleElements
        case focusTrap
        case missingFocusManagement
    }
    
    enum Severity {
        case low
        case medium
        case high
        case critical
    }
}

/// Accessibility score with breakdown
struct AccessibilityScore {
    let score: Int
    let maxScore: Int
    let grade: String
    let criticalIssues: Int
    let highIssues: Int
    let mediumIssues: Int
    let lowIssues: Int
    
    var percentage: Double {
        return Double(score) / Double(maxScore) * 100
    }
}

/// Validation report for a single view controller
struct AccessibilityValidationReport {
    let viewControllerName: String
    let validationDate: Date
    let validationDuration: TimeInterval
    let totalIssues: Int
    let issues: [AccessibilityIssue]
    let score: AccessibilityScore
    let recommendations: [String]
    
    /// Generate formatted report string
    func formattedReport() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        var report = """
        Accessibility Validation Report
        ==============================
        View Controller: \(viewControllerName)
        Validation Date: \(formatter.string(from: validationDate))
        Validation Duration: \(String(format: "%.2f", validationDuration))s
        
        Score: \(score.score)/\(score.maxScore) (\(String(format: "%.1f", score.percentage))%) - Grade: \(score.grade)
        
        Issues Summary:
        - Critical: \(score.criticalIssues)
        - High: \(score.highIssues)
        - Medium: \(score.mediumIssues)
        - Low: \(score.lowIssues)
        Total: \(totalIssues)
        
        """
        
        if !issues.isEmpty {
            report += "Detailed Issues:\n"
            for (index, issue) in issues.enumerated() {
                report += "\n\(index + 1). [\(issue.severity)] \(issue.description)"
                report += "\n   Location: \(issue.location)"
                report += "\n   Element: \(issue.element)"
                report += "\n   Recommendation: \(issue.recommendation)\n"
            }
        }
        
        if !recommendations.isEmpty {
            report += "\nRecommendations:\n"
            for (index, recommendation) in recommendations.enumerated() {
                report += "\(index + 1). \(recommendation)\n"
            }
        }
        
        return report
    }
}

/// Comprehensive validation report for multiple view controllers
struct ComprehensiveAccessibilityReport {
    let reports: [AccessibilityValidationReport]
    let validationDate: Date
    let validationDuration: TimeInterval
    let overallScore: AccessibilityScore
    let summary: String
    
    /// Generate formatted comprehensive report
    func formattedReport() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        var report = """
        Comprehensive Accessibility Validation Report
        ============================================
        Validation Date: \(formatter.string(from: validationDate))
        Total Duration: \(String(format: "%.2f", validationDuration))s
        View Controllers Tested: \(reports.count)
        
        Overall Score: \(overallScore.score)/\(overallScore.maxScore) (\(String(format: "%.1f", overallScore.percentage))%) - Grade: \(overallScore.grade)
        
        Overall Issues Summary:
        - Critical: \(overallScore.criticalIssues)
        - High: \(overallScore.highIssues)
        - Medium: \(overallScore.mediumIssues)
        - Low: \(overallScore.lowIssues)
        
        \(summary)
        
        Individual Reports:
        ==================
        
        """
        
        for (index, individualReport) in reports.enumerated() {
            report += "\n--- Report \(index + 1): \(individualReport.viewControllerName) ---\n"
            report += "Score: \(individualReport.score.score)/\(individualReport.score.maxScore) - Grade: \(individualReport.score.grade)\n"
            report += "Issues: \(individualReport.totalIssues)\n"
            
            if individualReport.totalIssues > 0 {
                report += "Top Issues:\n"
                let topIssues = Array(individualReport.issues.prefix(3))
                for issue in topIssues {
                    report += "  • [\(issue.severity)] \(issue.description)\n"
                }
            }
            report += "\n"
        }
        
        return report
    }
}