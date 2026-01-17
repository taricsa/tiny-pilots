import Foundation
import UIKit

/// Manages release notes and version update notifications
class ReleaseNotesManager {
    static let shared = ReleaseNotesManager()
    
    // MARK: - Properties
    
    private let userDefaults = UserDefaults.standard
    private let lastShownVersionKey = "last_shown_release_notes_version"
    private let releaseNotesShownKey = "release_notes_shown_versions"
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Interface
    
    /// Check if release notes should be shown for current version
    func shouldShowReleaseNotes() -> Bool {
        let currentVersion = getCurrentVersion()
        let lastShownVersion = getLastShownVersion()
        
        // Show if this is a new version
        if currentVersion != lastShownVersion {
            return true
        }
        
        return false
    }
    
    /// Show release notes for current version
    func showReleaseNotes() {
        let currentVersion = getCurrentVersion()
        let releaseNotes = getReleaseNotes(for: currentVersion)
        
        guard !releaseNotes.isEmpty else {
            Logger.shared.warning("No release notes found for version \(currentVersion)", category: .app)
            return
        }
        
        showReleaseNotesModal(releaseNotes)
        markReleaseNotesAsShown(for: currentVersion)
    }
    
    /// Manually show release notes (from settings)
    func showReleaseNotesManually() {
        let currentVersion = getCurrentVersion()
        let releaseNotes = getReleaseNotes(for: currentVersion)
        
        if releaseNotes.isEmpty {
            showNoReleaseNotesAlert()
        } else {
            showReleaseNotesModal(releaseNotes)
        }
    }
    
    /// Get release notes for a specific version
    func getReleaseNotes(for version: String) -> ReleaseNotes {
        // In a real app, this might fetch from a server or local JSON file
        // For now, we'll return hardcoded release notes based on version
        return getHardcodedReleaseNotes(for: version)
    }
    
    /// Get all available release notes
    func getAllReleaseNotes() -> [ReleaseNotes] {
        let versions = ["1.0.0", "1.0.1", "1.1.0", "1.2.0"] // Example versions
        return versions.compactMap { version in
            let notes = getReleaseNotes(for: version)
            return notes.isEmpty ? nil : notes
        }
    }
    
    /// Mark release notes as shown for a version
    func markReleaseNotesAsShown(for version: String) {
        userDefaults.set(version, forKey: lastShownVersionKey)
        
        var shownVersions = getShownVersions()
        shownVersions.insert(version)
        userDefaults.set(Array(shownVersions), forKey: releaseNotesShownKey)
        
        Logger.shared.info("Release notes marked as shown for version \(version)", category: .app)
        
        // Track in analytics
        AnalyticsManager.shared.trackEvent(.releaseNotesShown(version: version))
    }
    
    /// Check if release notes have been shown for a version
    func hasShownReleaseNotes(for version: String) -> Bool {
        let shownVersions = getShownVersions()
        return shownVersions.contains(version)
    }
    
    /// Get current app version
    func getCurrentVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    /// Get current build number
    func getCurrentBuildNumber() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// Get full version string
    func getFullVersionString() -> String {
        return "\(getCurrentVersion()) (\(getCurrentBuildNumber()))"
    }
    
    // MARK: - Private Methods
    
    private func getLastShownVersion() -> String? {
        return userDefaults.string(forKey: lastShownVersionKey)
    }
    
    private func getShownVersions() -> Set<String> {
        let array = userDefaults.stringArray(forKey: releaseNotesShownKey) ?? []
        return Set(array)
    }
    
    private func showReleaseNotesModal(_ releaseNotes: ReleaseNotes) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let alert = UIAlertController(
            title: "What's New in \(releaseNotes.version)",
            message: formatReleaseNotesForAlert(releaseNotes),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Got it!", style: .default) { _ in
            // Track user acknowledgment
            AnalyticsManager.shared.trackEvent(.releaseNotesAcknowledged(version: releaseNotes.version))
        })
        
        // Add "View Full Notes" button if there are detailed notes
        if !releaseNotes.detailedNotes.isEmpty {
            alert.addAction(UIAlertAction(title: "View Full Notes", style: .default) { _ in
                self.showDetailedReleaseNotes(releaseNotes)
            })
        }
        
        window.rootViewController?.present(alert, animated: true)
        
        Logger.shared.info("Release notes modal shown for version \(releaseNotes.version)", category: .app)
    }
    
    private func showDetailedReleaseNotes(_ releaseNotes: ReleaseNotes) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let detailedMessage = formatDetailedReleaseNotes(releaseNotes)
        
        let alert = UIAlertController(
            title: "Release Notes \(releaseNotes.version)",
            message: detailedMessage,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Close", style: .default))
        
        window.rootViewController?.present(alert, animated: true)
        
        // Track detailed view
        AnalyticsManager.shared.trackEvent(.releaseNotesDetailViewed(version: releaseNotes.version))
    }
    
    private func showNoReleaseNotesAlert() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let alert = UIAlertController(
            title: "Release Notes",
            message: "No release notes available for the current version.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        window.rootViewController?.present(alert, animated: true)
    }
    
    private func formatReleaseNotesForAlert(_ releaseNotes: ReleaseNotes) -> String {
        var message = ""
        
        if !releaseNotes.highlights.isEmpty {
            message += releaseNotes.highlights.map { "• \($0)" }.joined(separator: "\n")
        }
        
        if !releaseNotes.bugFixes.isEmpty {
            if !message.isEmpty { message += "\n\n" }
            message += "Bug Fixes:\n"
            message += releaseNotes.bugFixes.map { "• \($0)" }.joined(separator: "\n")
        }
        
        return message
    }
    
    private func formatDetailedReleaseNotes(_ releaseNotes: ReleaseNotes) -> String {
        var message = ""
        
        // Version and date
        message += "Version: \(releaseNotes.version)\n"
        if let releaseDate = releaseNotes.releaseDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            message += "Released: \(formatter.string(from: releaseDate))\n\n"
        }
        
        // New features
        if !releaseNotes.newFeatures.isEmpty {
            message += "🎉 New Features:\n"
            message += releaseNotes.newFeatures.map { "• \($0)" }.joined(separator: "\n")
            message += "\n\n"
        }
        
        // Improvements
        if !releaseNotes.improvements.isEmpty {
            message += "✨ Improvements:\n"
            message += releaseNotes.improvements.map { "• \($0)" }.joined(separator: "\n")
            message += "\n\n"
        }
        
        // Bug fixes
        if !releaseNotes.bugFixes.isEmpty {
            message += "🐛 Bug Fixes:\n"
            message += releaseNotes.bugFixes.map { "• \($0)" }.joined(separator: "\n")
            message += "\n\n"
        }
        
        // Known issues
        if !releaseNotes.knownIssues.isEmpty {
            message += "⚠️ Known Issues:\n"
            message += releaseNotes.knownIssues.map { "• \($0)" }.joined(separator: "\n")
        }
        
        return message.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func getHardcodedReleaseNotes(for version: String) -> ReleaseNotes {
        switch version {
        case "1.0.0":
            return ReleaseNotes(
                version: "1.0.0",
                releaseDate: Date(),
                highlights: [
                    "Welcome to Tiny Pilots!",
                    "Realistic paper airplane physics",
                    "5 beautiful environments to explore",
                    "Game Center integration"
                ],
                newFeatures: [
                    "Paper airplane flight simulation with realistic physics",
                    "Five stunning environments: Sunny Meadows, Alpine Heights, Coastal Breeze, Urban Skyline, and Desert Canyon",
                    "Multiple game modes: Free Play, Challenge, Daily Run, Weekly Special, and Tutorial",
                    "Game Center leaderboards and achievements",
                    "Customizable paper airplane designs",
                    "Full accessibility support with VoiceOver",
                    "Tilt-based intuitive controls"
                ],
                improvements: [
                    "Optimized performance for all supported devices",
                    "Beautiful particle effects and visual polish",
                    "Smooth 60 FPS gameplay (120 FPS on ProMotion displays)"
                ],
                bugFixes: [],
                knownIssues: [],
                detailedNotes: "This is the initial release of Tiny Pilots, bringing you the joy of paper airplane flight with stunning realism and beautiful environments."
            )
            
        case "1.0.1":
            return ReleaseNotes(
                version: "1.0.1",
                releaseDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
                highlights: [
                    "Bug fixes and performance improvements",
                    "Enhanced accessibility features"
                ],
                newFeatures: [],
                improvements: [
                    "Improved VoiceOver announcements",
                    "Better performance on older devices",
                    "Enhanced tilt control sensitivity"
                ],
                bugFixes: [
                    "Fixed crash when switching between game modes",
                    "Resolved Game Center authentication issues",
                    "Fixed audio not resuming after phone calls"
                ],
                knownIssues: [],
                detailedNotes: "This update focuses on stability and accessibility improvements based on user feedback."
            )
            
        case "1.1.0":
            return ReleaseNotes(
                version: "1.1.0",
                releaseDate: Calendar.current.date(byAdding: .day, value: -30, to: Date()),
                highlights: [
                    "New challenge sharing feature",
                    "Enhanced graphics options",
                    "Improved daily runs"
                ],
                newFeatures: [
                    "Share custom challenges with friends",
                    "New graphics quality settings",
                    "Enhanced daily run variety",
                    "Achievement progress tracking"
                ],
                improvements: [
                    "Better wind physics simulation",
                    "Improved collision detection",
                    "Enhanced particle effects",
                    "Faster app launch times"
                ],
                bugFixes: [
                    "Fixed weekly special loading issues",
                    "Resolved score submission delays",
                    "Fixed rare physics calculation errors"
                ],
                knownIssues: [
                    "Some users may experience longer loading times on iOS 16.0"
                ],
                detailedNotes: "This major update introduces challenge sharing and enhanced graphics options, making Tiny Pilots more social and visually stunning."
            )
            
        default:
            return ReleaseNotes.empty
        }
    }
}

// MARK: - Supporting Types

struct ReleaseNotes {
    let version: String
    let releaseDate: Date?
    let highlights: [String]
    let newFeatures: [String]
    let improvements: [String]
    let bugFixes: [String]
    let knownIssues: [String]
    let detailedNotes: String
    
    var isEmpty: Bool {
        return highlights.isEmpty && 
               newFeatures.isEmpty && 
               improvements.isEmpty && 
               bugFixes.isEmpty && 
               knownIssues.isEmpty &&
               detailedNotes.isEmpty
    }
    
    static let empty = ReleaseNotes(
        version: "",
        releaseDate: nil,
        highlights: [],
        newFeatures: [],
        improvements: [],
        bugFixes: [],
        knownIssues: [],
        detailedNotes: ""
    )
    
    init(
        version: String,
        releaseDate: Date? = nil,
        highlights: [String] = [],
        newFeatures: [String] = [],
        improvements: [String] = [],
        bugFixes: [String] = [],
        knownIssues: [String] = [],
        detailedNotes: String = ""
    ) {
        self.version = version
        self.releaseDate = releaseDate
        self.highlights = highlights
        self.newFeatures = newFeatures
        self.improvements = improvements
        self.bugFixes = bugFixes
        self.knownIssues = knownIssues
        self.detailedNotes = detailedNotes
    }
}

// MARK: - Analytics Extensions

extension AnalyticsEvent {
    static func releaseNotesShown(version: String) -> AnalyticsEvent {
        return .settingsChanged(setting: "release_notes_shown", value: version)
    }
    
    static func releaseNotesAcknowledged(version: String) -> AnalyticsEvent {
        return .settingsChanged(setting: "release_notes_acknowledged", value: version)
    }
    
    static func releaseNotesDetailViewed(version: String) -> AnalyticsEvent {
        return .settingsChanged(setting: "release_notes_detail_viewed", value: version)
    }
}