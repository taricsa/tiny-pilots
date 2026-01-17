import Foundation
import UIKit
import MessageUI

/// Manages user feedback collection and customer support integration
class UserFeedbackManager: NSObject {
    static let shared = UserFeedbackManager()
    
    // MARK: - Properties
    
    private let userDefaults = UserDefaults.standard
    private let feedbackEmailKey = "user_feedback_email"
    private let feedbackCountKey = "feedback_count"
    private let lastFeedbackDateKey = "last_feedback_date"
    
    // Configuration
    private let supportEmail = "support@tinypilots.com"
    private let feedbackEmail = "feedback@tinypilots.com"
    private let maxFeedbacksPerDay = 3
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Interface
    
    /// Show feedback options to user
    func showFeedbackOptions() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let alert = UIAlertController(
            title: "Send Feedback",
            message: "We'd love to hear from you! How can we help?",
            preferredStyle: .alert
        )
        
        // Report a Bug
        alert.addAction(UIAlertAction(title: "Report a Bug", style: .default) { [weak self] _ in
            self?.showBugReportForm()
        })
        
        // Feature Request
        alert.addAction(UIAlertAction(title: "Request a Feature", style: .default) { [weak self] _ in
            self?.showFeatureRequestForm()
        })
        
        // General Feedback
        alert.addAction(UIAlertAction(title: "General Feedback", style: .default) { [weak self] _ in
            self?.showGeneralFeedbackForm()
        })
        
        // Contact Support
        alert.addAction(UIAlertAction(title: "Contact Support", style: .default) { [weak self] _ in
            self?.showSupportContactForm()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        window.rootViewController?.present(alert, animated: true)
        
        // Track analytics
        AnalyticsManager.shared.trackEvent(.feedbackOptionsShown())
    }
    
    /// Show bug report form
    func showBugReportForm() {
        let feedbackData = FeedbackData(
            type: .bugReport,
            title: "Bug Report",
            promptMessage: "Please describe the bug you encountered:",
            placeholderText: "Describe what happened, what you expected to happen, and steps to reproduce the issue..."
        )
        
        showFeedbackForm(feedbackData)
    }
    
    /// Show feature request form
    func showFeatureRequestForm() {
        let feedbackData = FeedbackData(
            type: .featureRequest,
            title: "Feature Request",
            promptMessage: "What feature would you like to see in Tiny Pilots?",
            placeholderText: "Describe the feature you'd like to see and how it would improve your experience..."
        )
        
        showFeedbackForm(feedbackData)
    }
    
    /// Show general feedback form
    func showGeneralFeedbackForm() {
        let feedbackData = FeedbackData(
            type: .generalFeedback,
            title: "General Feedback",
            promptMessage: "We'd love to hear your thoughts about Tiny Pilots:",
            placeholderText: "Share your thoughts, suggestions, or any other feedback..."
        )
        
        showFeedbackForm(feedbackData)
    }
    
    /// Show support contact form
    func showSupportContactForm() {
        let feedbackData = FeedbackData(
            type: .support,
            title: "Contact Support",
            promptMessage: "How can we help you?",
            placeholderText: "Describe your issue or question, and we'll get back to you as soon as possible..."
        )
        
        showFeedbackForm(feedbackData)
    }
    
    /// Check if user can send feedback (rate limiting)
    func canSendFeedback() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastFeedbackDate = userDefaults.object(forKey: lastFeedbackDateKey) as? Date {
            let lastFeedbackDay = Calendar.current.startOfDay(for: lastFeedbackDate)
            
            if Calendar.current.isDate(today, inSameDayAs: lastFeedbackDay) {
                let todayCount = userDefaults.integer(forKey: feedbackCountKey)
                return todayCount < maxFeedbacksPerDay
            }
        }
        
        return true
    }
    
    /// Get feedback statistics
    func getFeedbackStatistics() -> FeedbackStatistics {
        return FeedbackStatistics(
            totalFeedbackCount: userDefaults.integer(forKey: feedbackCountKey),
            lastFeedbackDate: userDefaults.object(forKey: lastFeedbackDateKey) as? Date,
            canSendFeedback: canSendFeedback()
        )
    }
    
    // MARK: - Private Methods
    
    private func showFeedbackForm(_ feedbackData: FeedbackData) {
        guard canSendFeedback() else {
            showRateLimitAlert()
            return
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let alert = UIAlertController(
            title: feedbackData.title,
            message: feedbackData.promptMessage,
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = feedbackData.placeholderText
            textField.autocapitalizationType = .sentences
            textField.autocorrectionType = .yes
        }
        
        // Send Feedback
        alert.addAction(UIAlertAction(title: "Send", style: .default) { [weak self] _ in
            if let feedbackText = alert.textFields?.first?.text, !feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self?.sendFeedback(feedbackData.type, text: feedbackText)
            } else {
                self?.showEmptyFeedbackAlert()
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        window.rootViewController?.present(alert, animated: true)
        
        // Track analytics
        AnalyticsManager.shared.trackEvent(.feedbackFormShown(type: feedbackData.type.rawValue))
    }
    
    private func sendFeedback(_ type: FeedbackType, text: String) {
        // Try to send via email first
        if MFMailComposeViewController.canSendMail() {
            sendFeedbackViaEmail(type, text: text)
        } else {
            // Fallback to copying to clipboard and opening mail app
            sendFeedbackViaFallback(type, text: text)
        }
        
        // Update feedback tracking
        updateFeedbackTracking()
        
        // Track analytics
        AnalyticsManager.shared.trackEvent(.feedbackSent(type: type.rawValue))
        
        Logger.shared.info("Feedback sent: \(type.rawValue)", category: .app)
    }
    
    private func sendFeedbackViaEmail(_ type: FeedbackType, text: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else { return }
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        
        // Set recipient based on feedback type
        let recipient = type == .support ? supportEmail : feedbackEmail
        mailComposer.setToRecipients([recipient])
        
        // Set subject
        let subject = "\(type.emailSubject) - Tiny Pilots"
        mailComposer.setSubject(subject)
        
        // Set body with system information
        let systemInfo = getSystemInformation()
        let body = """
        \(text)
        
        ---
        System Information:
        \(systemInfo)
        """
        
        mailComposer.setMessageBody(body, isHTML: false)
        
        rootViewController.present(mailComposer, animated: true)
    }
    
    private func sendFeedbackViaFallback(_ type: FeedbackType, text: String) {
        let recipient = type == .support ? supportEmail : feedbackEmail
        let subject = "\(type.emailSubject) - Tiny Pilots"
        let systemInfo = getSystemInformation()
        
        let emailBody = """
        \(text)
        
        ---
        System Information:
        \(systemInfo)
        """
        
        // Copy to clipboard
        UIPasteboard.general.string = emailBody
        
        // Show alert with instructions
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let alert = UIAlertController(
            title: "Email Not Available",
            message: "Your feedback has been copied to the clipboard. Please email it to \(recipient) or tap 'Open Mail' to try opening your mail app.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Open Mail", style: .default) { _ in
            if let mailURL = URL(string: "mailto:\(recipient)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                UIApplication.shared.open(mailURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        window.rootViewController?.present(alert, animated: true)
    }
    
    private func getSystemInformation() -> String {
        let device = UIDevice.current
        _ = Bundle.main // Referenced for potential future use
        let config = AppConfiguration.current
        
        return """
        App Version: \(config.buildVersion) (\(config.buildNumber))
        iOS Version: \(device.systemVersion)
        Device Model: \(device.model)
        Device Name: \(device.name)
        Environment: \(config.environment.rawValue)
        Timestamp: \(Date())
        """
    }
    
    private func updateFeedbackTracking() {
        let today = Date()
        let todayStart = Calendar.current.startOfDay(for: today)
        
        if let lastFeedbackDate = userDefaults.object(forKey: lastFeedbackDateKey) as? Date {
            let lastFeedbackDay = Calendar.current.startOfDay(for: lastFeedbackDate)
            
            if Calendar.current.isDate(todayStart, inSameDayAs: lastFeedbackDay) {
                // Same day, increment count
                let currentCount = userDefaults.integer(forKey: feedbackCountKey)
                userDefaults.set(currentCount + 1, forKey: feedbackCountKey)
            } else {
                // New day, reset count
                userDefaults.set(1, forKey: feedbackCountKey)
            }
        } else {
            // First feedback
            userDefaults.set(1, forKey: feedbackCountKey)
        }
        
        userDefaults.set(today, forKey: lastFeedbackDateKey)
    }
    
    private func showRateLimitAlert() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let alert = UIAlertController(
            title: "Feedback Limit Reached",
            message: "You've reached the daily limit for feedback submissions. Please try again tomorrow or contact us directly at \(supportEmail).",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        window.rootViewController?.present(alert, animated: true)
    }
    
    private func showEmptyFeedbackAlert() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let alert = UIAlertController(
            title: "Empty Feedback",
            message: "Please enter your feedback before sending.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        window.rootViewController?.present(alert, animated: true)
    }
    
    private func showFeedbackSentConfirmation() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let alert = UIAlertController(
            title: "Feedback Sent",
            message: "Thank you for your feedback! We'll review it and get back to you if needed.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        window.rootViewController?.present(alert, animated: true)
    }
}

// MARK: - MFMailComposeViewControllerDelegate

extension UserFeedbackManager: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) { [weak self] in
            switch result {
            case .sent:
                self?.showFeedbackSentConfirmation()
                Logger.shared.info("Feedback email sent successfully", category: .app)
            case .cancelled:
                Logger.shared.info("Feedback email cancelled", category: .app)
            case .failed:
                Logger.shared.error("Feedback email failed to send", error: error, category: .app)
            case .saved:
                Logger.shared.info("Feedback email saved as draft", category: .app)
            @unknown default:
                Logger.shared.warning("Unknown mail compose result", category: .app)
            }
        }
    }
}

// MARK: - Supporting Types

enum FeedbackType: String, CaseIterable {
    case bugReport = "bug_report"
    case featureRequest = "feature_request"
    case generalFeedback = "general_feedback"
    case support = "support"
    
    var emailSubject: String {
        switch self {
        case .bugReport:
            return "Bug Report"
        case .featureRequest:
            return "Feature Request"
        case .generalFeedback:
            return "General Feedback"
        case .support:
            return "Support Request"
        }
    }
}

struct FeedbackData {
    let type: FeedbackType
    let title: String
    let promptMessage: String
    let placeholderText: String
}

struct FeedbackStatistics {
    let totalFeedbackCount: Int
    let lastFeedbackDate: Date?
    let canSendFeedback: Bool
    
    var debugDescription: String {
        return """
        Feedback Statistics:
        - Total Feedback Count: \(totalFeedbackCount)
        - Last Feedback Date: \(lastFeedbackDate?.description ?? "Never")
        - Can Send Feedback: \(canSendFeedback)
        """
    }
}

// MARK: - Analytics Extensions

extension AnalyticsEvent {
    static func feedbackOptionsShown() -> AnalyticsEvent {
        return .settingsChanged(setting: "feedback_options", value: "shown")
    }
    
    static func feedbackFormShown(type: String) -> AnalyticsEvent {
        return .settingsChanged(setting: "feedback_form_shown", value: type)
    }
    
    static func feedbackSent(type: String) -> AnalyticsEvent {
        return .settingsChanged(setting: "feedback_sent", value: type)
    }
}