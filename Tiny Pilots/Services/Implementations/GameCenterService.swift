import Foundation
import GameKit
import UIKit

/// Implementation of GameCenterServiceProtocol with enhanced offline support and retry logic
class GameCenterService: NSObject, GameCenterServiceProtocol {
    
    // MARK: - Properties
    
    /// The local player
    private var localPlayer = GKLocalPlayer.local
    
    /// Whether Game Center is available and authenticated
    var isAuthenticated: Bool {
        return localPlayer.isAuthenticated
    }
    
    /// The local player's display name
    var playerDisplayName: String? {
        return isAuthenticated ? localPlayer.displayName : nil
    }
    
    /// Flag to track if authentication is in progress
    private var isAuthenticating = false
    
    /// Completion handlers waiting for authentication
    private var pendingAuthCompletions: [(Bool, Error?) -> Void] = []
    
    /// Cached leaderboards
    private var leaderboards: [GKLeaderboard] = []
    
    /// Cached achievements
    private var achievements: [GKAchievement] = []
    
    /// Offline data storage for sync when online
    private var offlineScores: [OfflineScoreEntry] = []
    private var offlineAchievements: [OfflineAchievementEntry] = []
    
    /// Network monitoring
    private var isOnline: Bool = true
    
    /// Retry configuration
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 2.0
    
    /// Configuration
    private let appConfiguration = ConfigurationManager.shared.currentConfiguration
    
    /// Queue for background operations
    private let operationQueue = DispatchQueue(label: "com.tinypilots.gamecenter", qos: .utility)
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupNetworkMonitoring()
        loadOfflineData()
    }
    
    // MARK: - Offline Data Models
    
    private struct OfflineScoreEntry: Codable {
        let score: Int
        let leaderboardID: String
        let timestamp: Date
        let playerID: String
    }
    
    private struct OfflineAchievementEntry: Codable {
        let identifier: String
        let percentComplete: Double
        let timestamp: Date
        let playerID: String
    }
    
    // MARK: - Network Monitoring & Offline Support
    
    private func setupNetworkMonitoring() {
        // Monitor network connectivity changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(networkStatusChanged),
            name: .networkConnectivityChanged,
            object: nil
        )
        
        // Check initial network status
        updateNetworkStatus()
    }
    
    @objc private func networkStatusChanged() {
        updateNetworkStatus()
        
        // If we're back online, sync offline data
        if isOnline {
            syncOfflineData()
        }
    }
    
    private func updateNetworkStatus() {
        // Use NetworkMonitor if available, otherwise assume online
        if let networkMonitor = try? DIContainer.shared.resolve(NetworkMonitor.self) {
            isOnline = networkMonitor.isConnected
        } else {
            isOnline = true // Default to online if no network monitor
        }
        
        Logger.shared.info("Network status updated: \(isOnline ? "Online" : "Offline")", category: .gameCenter)
    }
    
    private func loadOfflineData() {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Load offline scores
            if let scoresData = UserDefaults.standard.data(forKey: "OfflineScores"),
               let scores = try? JSONDecoder().decode([OfflineScoreEntry].self, from: scoresData) {
                self.offlineScores = scores
                Logger.shared.info("Loaded \(scores.count) offline scores", category: .gameCenter)
            }
            
            // Load offline achievements
            if let achievementsData = UserDefaults.standard.data(forKey: "OfflineAchievements"),
               let achievements = try? JSONDecoder().decode([OfflineAchievementEntry].self, from: achievementsData) {
                self.offlineAchievements = achievements
                Logger.shared.info("Loaded \(achievements.count) offline achievements", category: .gameCenter)
            }
        }
    }
    
    private func saveOfflineData() {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Save offline scores
            if let scoresData = try? JSONEncoder().encode(self.offlineScores) {
                UserDefaults.standard.set(scoresData, forKey: "OfflineScores")
            }
            
            // Save offline achievements
            if let achievementsData = try? JSONEncoder().encode(self.offlineAchievements) {
                UserDefaults.standard.set(achievementsData, forKey: "OfflineAchievements")
            }
            
            UserDefaults.standard.synchronize()
        }
    }
    
    private func syncOfflineData() {
        guard isAuthenticated && isOnline else {
            Logger.shared.info("Skipping offline data sync - not authenticated or offline", category: .gameCenter)
            return
        }
        
        Logger.shared.info("Starting offline data sync", category: .gameCenter)
        
        operationQueue.async { [weak self] in
            self?.syncOfflineScores()
            self?.syncOfflineAchievements()
        }
    }
    
    private func syncOfflineScores() {
        let scoresToSync = offlineScores
        guard !scoresToSync.isEmpty else { return }
        
        Logger.shared.info("Syncing \(scoresToSync.count) offline scores", category: .gameCenter)
        
        let group = DispatchGroup()
        var syncedCount = 0
        
        for scoreEntry in scoresToSync {
            group.enter()
            
            submitScoreWithRetry(scoreEntry.score, to: scoreEntry.leaderboardID, retryCount: 0) { [weak self] error in
                if error == nil {
                    syncedCount += 1
                    // Remove synced score from offline storage
                    self?.offlineScores.removeAll { $0.timestamp == scoreEntry.timestamp }
                } else {
                    Logger.shared.error("Failed to sync offline score", error: error, category: .gameCenter)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            Logger.shared.info("Synced \(syncedCount) of \(scoresToSync.count) offline scores", category: .gameCenter)
            self?.saveOfflineData()
        }
    }
    
    private func syncOfflineAchievements() {
        let achievementsToSync = offlineAchievements
        guard !achievementsToSync.isEmpty else { return }
        
        Logger.shared.info("Syncing \(achievementsToSync.count) offline achievements", category: .gameCenter)
        
        let group = DispatchGroup()
        var syncedCount = 0
        
        for achievementEntry in achievementsToSync {
            group.enter()
            
            reportAchievementWithRetry(
                identifier: achievementEntry.identifier,
                percentComplete: achievementEntry.percentComplete,
                retryCount: 0
            ) { [weak self] error in
                if error == nil {
                    syncedCount += 1
                    // Remove synced achievement from offline storage
                    self?.offlineAchievements.removeAll { $0.timestamp == achievementEntry.timestamp }
                } else {
                    Logger.shared.error("Failed to sync offline achievement", error: error, category: .gameCenter)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            Logger.shared.info("Synced \(syncedCount) of \(achievementsToSync.count) offline achievements", category: .gameCenter)
            self?.saveOfflineData()
        }
    }
    
    // MARK: - Authentication
    
    func authenticate(completion: @escaping (Bool, Error?) -> Void) {
        authenticateWithRetry(retryCount: 0, completion: completion)
    }
    
    private func authenticateWithRetry(retryCount: Int, completion: @escaping (Bool, Error?) -> Void) {
        // If already authenticated, return immediately
        if localPlayer.isAuthenticated {
            Logger.shared.info("Player already authenticated as: \(localPlayer.displayName)", category: .gameCenter)
            AnalyticsManager.shared.trackEvent(.gameCenterAuthenticated)
            completion(true, nil)
            return
        }
        
        // If authentication is in progress, queue this completion handler
        if isAuthenticating {
            pendingAuthCompletions.append(completion)
            Logger.shared.info("Authentication already in progress, queuing completion handler", category: .gameCenter)
            return
        }
        
        // Set authenticating flag
        isAuthenticating = true
        pendingAuthCompletions.append(completion)
        
        // Log authentication attempt
        Logger.shared.info("Attempting to authenticate with Game Center (attempt \(retryCount + 1))", category: .gameCenter)
        
        localPlayer.authenticateHandler = { [weak self] viewController, error in
            guard let self = self else { return }
            
            if let viewController = viewController {
                // Present the view controller for authentication
                Logger.shared.info("Game Center authentication requires user interaction", category: .gameCenter)
                
                DispatchQueue.main.async {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let topVC = windowScene.windows.first?.rootViewController {
                        self.presentViewController(viewController, from: topVC)
                    } else {
                        Logger.shared.error("Could not find a view controller to present Game Center authentication", category: .gameCenter)
                        let error = GameCenterServiceError.notAuthenticated
                        self.handleAuthenticationFailure(error: error, retryCount: retryCount, completion: completion)
                    }
                }
            } else if let error = error {
                // Authentication failed with error
                Logger.shared.error("Game Center authentication failed (attempt \(retryCount + 1))", error: error, category: .gameCenter)
                self.handleAuthenticationFailure(error: error, retryCount: retryCount, completion: completion)
            } else {
                // Authentication succeeded or was already authenticated
                let success = self.localPlayer.isAuthenticated
                
                if success {
                    Logger.shared.info("Game Center authentication successful for player: \(self.localPlayer.displayName)", category: .gameCenter)
                    AnalyticsManager.shared.trackEvent(.gameCenterAuthenticated)
                    
                    // Load achievements and leaderboards
                    self.loadLeaderboards()
                    self.loadAchievements { _, _ in }
                    
                    // Sync any offline data
                    self.syncOfflineData()
                    
                    self.completeAuthentication(success: true, error: nil)
                } else {
                    Logger.shared.warning("Game Center is not available despite no error", category: .gameCenter)
                    let error = GameCenterServiceError.notAuthenticated
                    self.handleAuthenticationFailure(error: error, retryCount: retryCount, completion: completion)
                }
            }
        }
    }
    
    private func handleAuthenticationFailure(error: Error, retryCount: Int, completion: @escaping (Bool, Error?) -> Void) {
        // Check if we should retry
        if retryCount < maxRetryAttempts {
            Logger.shared.info("Retrying Game Center authentication in \(retryDelay) seconds", category: .gameCenter)
            
            // Reset authentication state for retry
            isAuthenticating = false
            pendingAuthCompletions.removeAll()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
                self?.authenticateWithRetry(retryCount: retryCount + 1, completion: completion)
            }
        } else {
            Logger.shared.error("Game Center authentication failed after \(maxRetryAttempts) attempts", category: .gameCenter)
            AnalyticsManager.shared.trackEvent(.gameCenterAuthenticationFailed(error: error.localizedDescription))
            completeAuthentication(success: false, error: error)
        }
    }
    
    /// Present a view controller with proper error handling
    private func presentViewController(_ viewController: UIViewController, from presentingVC: UIViewController) {
        if presentingVC.presentedViewController != nil {
            print("Warning: A view controller is already being presented. Waiting to present Game Center authentication.")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if presentingVC.presentedViewController == nil {
                    presentingVC.present(viewController, animated: true)
                } else {
                    print("Error: Could not present Game Center authentication due to an existing presentation")
                    let error = GameCenterServiceError.notAuthenticated
                    self.completeAuthentication(success: false, error: error)
                }
            }
        } else {
            presentingVC.present(viewController, animated: true)
        }
    }
    
    /// Complete authentication and notify all pending completion handlers
    private func completeAuthentication(success: Bool, error: Error?) {
        DispatchQueue.main.async {
            // Call all pending completion handlers
            for completion in self.pendingAuthCompletions {
                completion(success, error)
            }
            
            // Clear the pending completions
            self.pendingAuthCompletions.removeAll()
            
            // Reset authenticating flag
            self.isAuthenticating = false
        }
    }
    
    // MARK: - Leaderboards
    
    func submitScore(_ score: Int, to leaderboardID: String, completion: @escaping (Error?) -> Void) {
        // If not authenticated or offline, store for later sync
        if !isAuthenticated || !isOnline {
            storeScoreOffline(score: score, leaderboardID: leaderboardID)
            
            if !isAuthenticated {
                Logger.shared.warning("Score stored offline - not authenticated", category: .gameCenter)
                completion(GameCenterServiceError.notAuthenticated)
            } else {
                Logger.shared.info("Score stored offline - no network connection", category: .gameCenter)
                completion(nil) // Success - stored offline
            }
            return
        }
        
        submitScoreWithRetry(score, to: leaderboardID, retryCount: 0, completion: completion)
    }
    
    private func submitScoreWithRetry(_ score: Int, to leaderboardID: String, retryCount: Int, completion: @escaping (Error?) -> Void) {
        Logger.shared.info("Submitting score \(score) to leaderboard \(leaderboardID) (attempt \(retryCount + 1))", category: .gameCenter)
        
        // Use configured leaderboard ID if available
        let configuredLeaderboardID = appConfiguration.gameCenterConfiguration.leaderboardIDs[leaderboardID] ?? leaderboardID
        
        GKLeaderboard.submitScore(score, context: 0, player: localPlayer,
                                 leaderboardIDs: [configuredLeaderboardID]) { [weak self] error in
            if let error = error {
                Logger.shared.error("Error submitting score (attempt \(retryCount + 1))", error: error, category: .gameCenter)
                
                // Check if we should retry
                if retryCount < self?.maxRetryAttempts ?? 0 {
                    let delay = self?.retryDelay ?? 2.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self?.submitScoreWithRetry(score, to: leaderboardID, retryCount: retryCount + 1, completion: completion)
                    }
                } else {
                    // Max retries reached, store offline
                    self?.storeScoreOffline(score: score, leaderboardID: leaderboardID)
                    completion(GameCenterServiceError.submissionFailed)
                }
            } else {
                Logger.shared.info("Score submitted successfully", category: .gameCenter)
                AnalyticsManager.shared.trackEvent(.leaderboardScoreSubmitted(category: leaderboardID, score: score))
                completion(nil)
            }
        }
    }
    
    private func storeScoreOffline(score: Int, leaderboardID: String) {
        let offlineEntry = OfflineScoreEntry(
            score: score,
            leaderboardID: leaderboardID,
            timestamp: Date(),
            playerID: localPlayer.gamePlayerID
        )
        
        operationQueue.async { [weak self] in
            self?.offlineScores.append(offlineEntry)
            self?.saveOfflineData()
            Logger.shared.info("Score stored offline for later sync", category: .gameCenter)
        }
    }
    
    func loadLeaderboard(for leaderboardID: String, completion: @escaping ([GameCenterLeaderboardEntry]?, Error?) -> Void) {
        guard isAuthenticated else {
            completion(nil, GameCenterServiceError.notAuthenticated)
            return
        }
        
        // If offline, return cached data if available
        if !isOnline {
            Logger.shared.info("Loading cached leaderboard data - offline mode", category: .gameCenter)
            completion(getCachedLeaderboardEntries(for: leaderboardID), nil)
            return
        }
        
        loadLeaderboardWithRetry(leaderboardID: leaderboardID, retryCount: 0, completion: completion)
    }
    
    private func loadLeaderboardWithRetry(leaderboardID: String, retryCount: Int, completion: @escaping ([GameCenterLeaderboardEntry]?, Error?) -> Void) {
        Logger.shared.info("Loading leaderboard for ID: \(leaderboardID) (attempt \(retryCount + 1))", category: .gameCenter)
        
        // Use configured leaderboard ID if available
        let configuredLeaderboardID = appConfiguration.gameCenterConfiguration.leaderboardIDs[leaderboardID] ?? leaderboardID
        
        // Use the new iOS 14+ API
        GKLeaderboard.loadLeaderboards(IDs: [configuredLeaderboardID]) { [weak self] leaderboards, error in
            if let error = error {
                Logger.shared.error("Error loading leaderboard (attempt \(retryCount + 1))", error: error, category: .gameCenter)
                
                // Check if we should retry
                if retryCount < self?.maxRetryAttempts ?? 0 {
                    let delay = self?.retryDelay ?? 2.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self?.loadLeaderboardWithRetry(leaderboardID: leaderboardID, retryCount: retryCount + 1, completion: completion)
                    }
                } else {
                    // Max retries reached, return cached data if available
                    let cachedEntries = self?.getCachedLeaderboardEntries(for: leaderboardID)
                    if let entries = cachedEntries, !entries.isEmpty {
                        Logger.shared.info("Returning cached leaderboard data after retry failure", category: .gameCenter)
                        completion(entries, nil)
                    } else {
                        completion(nil, GameCenterServiceError.networkError)
                    }
                }
                return
            }
            
            guard let leaderboard = leaderboards?.first else {
                Logger.shared.warning("Leaderboard not found: \(configuredLeaderboardID)", category: .gameCenter)
                completion(nil, GameCenterServiceError.leaderboardNotFound)
                return
            }
            
            // Load entries using the new API
            leaderboard.loadEntries(
                for: .global,
                timeScope: .allTime,
                range: NSRange(location: 1, length: 25)
            ) { [weak self] localEntry, entries, totalPlayerCount, error in
                if let error = error {
                    Logger.shared.error("Error loading leaderboard entries", error: error, category: .gameCenter)
                    
                    // Return cached data if available
                    let cachedEntries = self?.getCachedLeaderboardEntries(for: leaderboardID)
                    if let entries = cachedEntries, !entries.isEmpty {
                        completion(entries, nil)
                    } else {
                        completion(nil, GameCenterServiceError.networkError)
                    }
                    return
                }
                
                guard let entries = entries else {
                    completion([], nil)
                    return
                }
                
                let leaderboardEntries = entries.map { entry in
                    GameCenterLeaderboardEntry(
                        playerID: entry.player.gamePlayerID,
                        displayName: entry.player.displayName,
                        score: entry.score,
                        rank: entry.rank,
                        date: entry.date
                    )
                }
                
                // Cache the entries for offline use
                self?.cacheLeaderboardEntries(leaderboardEntries, for: leaderboardID)
                
                Logger.shared.info("Successfully loaded \(leaderboardEntries.count) leaderboard entries", category: .gameCenter)
                completion(leaderboardEntries, nil)
            }
        }
    }
    
    private func getCachedLeaderboardEntries(for leaderboardID: String) -> [GameCenterLeaderboardEntry]? {
        let key = "CachedLeaderboard_\(leaderboardID)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let entries = try? JSONDecoder().decode([CachedLeaderboardEntry].self, from: data) else {
            return nil
        }
        
        // Convert cached entries back to GameCenterLeaderboardEntry
        return entries.map { cached in
            GameCenterLeaderboardEntry(
                playerID: cached.playerID,
                displayName: cached.displayName,
                score: cached.score,
                rank: cached.rank,
                date: cached.date
            )
        }
    }
    
    private func cacheLeaderboardEntries(_ entries: [GameCenterLeaderboardEntry], for leaderboardID: String) {
        let cachedEntries = entries.map { entry in
            CachedLeaderboardEntry(
                playerID: entry.playerID,
                displayName: entry.displayName,
                score: entry.score,
                rank: entry.rank,
                date: entry.date
            )
        }
        
        let key = "CachedLeaderboard_\(leaderboardID)"
        if let data = try? JSONEncoder().encode(cachedEntries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private struct CachedLeaderboardEntry: Codable {
        let playerID: String
        let displayName: String
        let score: Int
        let rank: Int
        let date: Date
    }
    
    /// Load all leaderboards
    private func loadLeaderboards() {
        guard isAuthenticated else {
            print("Skipping leaderboard loading - not authenticated")
            return
        }
        
        print("Loading Game Center leaderboards...")
        
        GKLeaderboard.loadLeaderboards(IDs: nil) { [weak self] leaderboards, error in
            if let error = error {
                print("Error loading leaderboards: \(error.localizedDescription)")
                return
            }
            
            self?.leaderboards = leaderboards ?? []
            print("Successfully loaded \(leaderboards?.count ?? 0) leaderboards")
        }
    }
    
    func showLeaderboards(from presentingViewController: UIViewController) {
        guard isAuthenticated else {
            let error = GameCenterServiceError.notAuthenticated
            showError(error, from: presentingViewController)
            return
        }
        
        let viewController = GKGameCenterViewController(state: .leaderboards)
        viewController.gameCenterDelegate = self
        presentingViewController.present(viewController, animated: true)
    }
    
    // MARK: - Achievements
    
    func reportAchievement(identifier: String, percentComplete: Double, completion: @escaping (Error?) -> Void) {
        // If not authenticated or offline, store for later sync
        if !isAuthenticated || !isOnline {
            storeAchievementOffline(identifier: identifier, percentComplete: percentComplete)
            
            if !isAuthenticated {
                Logger.shared.warning("Achievement stored offline - not authenticated", category: .gameCenter)
                completion(GameCenterServiceError.notAuthenticated)
            } else {
                Logger.shared.info("Achievement stored offline - no network connection", category: .gameCenter)
                completion(nil) // Success - stored offline
            }
            return
        }
        
        reportAchievementWithRetry(identifier: identifier, percentComplete: percentComplete, retryCount: 0, completion: completion)
    }
    
    private func reportAchievementWithRetry(identifier: String, percentComplete: Double, retryCount: Int, completion: @escaping (Error?) -> Void) {
        Logger.shared.info("Reporting achievement \(identifier) with \(percentComplete)% completion (attempt \(retryCount + 1))", category: .gameCenter)
        
        // Use configured achievement ID if available
        let configuredAchievementID = appConfiguration.gameCenterConfiguration.achievementIDs[identifier] ?? identifier
        
        let achievement = GKAchievement(identifier: configuredAchievementID)
        achievement.percentComplete = percentComplete
        achievement.showsCompletionBanner = true
        
        GKAchievement.report([achievement]) { [weak self] error in
            if let error = error {
                Logger.shared.error("Error reporting achievement (attempt \(retryCount + 1))", error: error, category: .gameCenter)
                
                // Check if we should retry
                if retryCount < self?.maxRetryAttempts ?? 0 {
                    let delay = self?.retryDelay ?? 2.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self?.reportAchievementWithRetry(identifier: identifier, percentComplete: percentComplete, retryCount: retryCount + 1, completion: completion)
                    }
                } else {
                    // Max retries reached, store offline
                    self?.storeAchievementOffline(identifier: identifier, percentComplete: percentComplete)
                    completion(GameCenterServiceError.submissionFailed)
                }
            } else {
                Logger.shared.info("Achievement reported successfully", category: .gameCenter)
                AnalyticsManager.shared.trackEvent(.achievementUnlocked(achievementId: identifier))
                completion(nil)
            }
        }
    }
    
    private func storeAchievementOffline(identifier: String, percentComplete: Double) {
        let offlineEntry = OfflineAchievementEntry(
            identifier: identifier,
            percentComplete: percentComplete,
            timestamp: Date(),
            playerID: localPlayer.gamePlayerID
        )
        
        operationQueue.async { [weak self] in
            self?.offlineAchievements.append(offlineEntry)
            self?.saveOfflineData()
            Logger.shared.info("Achievement stored offline for later sync", category: .gameCenter)
        }
    }
    
    func loadAchievements(completion: @escaping ([GKAchievement]?, Error?) -> Void) {
        guard isAuthenticated else {
            completion(nil, GameCenterServiceError.notAuthenticated)
            return
        }
        
        // If offline, return cached achievements if available
        if !isOnline {
            Logger.shared.info("Loading cached achievement data - offline mode", category: .gameCenter)
            completion(getCachedAchievements(), nil)
            return
        }
        
        loadAchievementsWithRetry(retryCount: 0, completion: completion)
    }
    
    private func loadAchievementsWithRetry(retryCount: Int, completion: @escaping ([GKAchievement]?, Error?) -> Void) {
        Logger.shared.info("Loading Game Center achievements (attempt \(retryCount + 1))", category: .gameCenter)
        
        GKAchievement.loadAchievements { [weak self] achievements, error in
            if let error = error {
                Logger.shared.error("Error loading achievements (attempt \(retryCount + 1))", error: error, category: .gameCenter)
                
                // Check if we should retry
                if retryCount < self?.maxRetryAttempts ?? 0 {
                    let delay = self?.retryDelay ?? 2.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self?.loadAchievementsWithRetry(retryCount: retryCount + 1, completion: completion)
                    }
                } else {
                    // Max retries reached, return cached data if available
                    let cachedAchievements = self?.getCachedAchievements()
                    if let achievements = cachedAchievements, !achievements.isEmpty {
                        Logger.shared.info("Returning cached achievement data after retry failure", category: .gameCenter)
                        completion(achievements, nil)
                    } else {
                        completion(nil, GameCenterServiceError.networkError)
                    }
                }
                return
            }
            
            self?.achievements = achievements ?? []
            
            // Cache achievements for offline use
            self?.cacheAchievements(achievements ?? [])
            
            Logger.shared.info("Successfully loaded \(achievements?.count ?? 0) achievements", category: .gameCenter)
            completion(achievements, nil)
        }
    }
    
    private func getCachedAchievements() -> [GKAchievement]? {
        guard let data = UserDefaults.standard.data(forKey: "CachedAchievements"),
              let cachedData = try? JSONDecoder().decode([CachedAchievementData].self, from: data) else {
            return nil
        }
        
        // Convert cached data back to GKAchievement objects
        return cachedData.compactMap { cached in
            let achievement = GKAchievement(identifier: cached.identifier)
            achievement.percentComplete = cached.percentComplete
            // isCompleted is read-only; infer from percentComplete
            if cached.isCompleted {
                achievement.percentComplete = 100.0
            }
            return achievement
        }
    }
    
    private func cacheAchievements(_ achievements: [GKAchievement]) {
        let cachedData = achievements.map { achievement in
            CachedAchievementData(
                identifier: achievement.identifier,
                percentComplete: achievement.percentComplete,
                isCompleted: achievement.isCompleted
            )
        }
        
        if let data = try? JSONEncoder().encode(cachedData) {
            UserDefaults.standard.set(data, forKey: "CachedAchievements")
        }
    }
    
    private struct CachedAchievementData: Codable {
        let identifier: String
        let percentComplete: Double
        let isCompleted: Bool
    }
    
    func showAchievements(from presentingViewController: UIViewController) {
        guard isAuthenticated else {
            let error = GameCenterServiceError.notAuthenticated
            showError(error, from: presentingViewController)
            return
        }
        
        let viewController = GKGameCenterViewController(state: .achievements)
        viewController.gameCenterDelegate = self
        presentingViewController.present(viewController, animated: true)
    }
    
    // MARK: - Challenge System
    
    func generateChallengeCode(for courseData: String) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let randomSeed = Int.random(in: 1000...9999)
        
        // Base components
        let baseString = "\(courseData)_\(timestamp)_\(randomSeed)"
        
        // Generate a simple checksum
        let checksum = generateChecksum(for: baseString)
        
        // Final code format: course_timestamp_randomSeed_checksum
        return "\(baseString)_\(checksum)"
    }
    
    func validateChallengeCode(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Split the code into components
        let components = code.split(separator: "_")
        
        // Validate format
        guard components.count == 4,
              let timestamp = Int(components[1]),
              let randomSeed = Int(components[2]),
              let checksum = Int(components[3]) else {
            completion(.failure(GameCenterServiceError.invalidChallengeCode))
            return
        }
        
        // Recreate the base string for checksum validation
        let courseID = String(components[0])
        let baseString = "\(courseID)_\(timestamp)_\(randomSeed)"
        
        // Validate checksum
        let expectedChecksum = generateChecksum(for: baseString)
        guard checksum == expectedChecksum else {
            completion(.failure(GameCenterServiceError.invalidChallengeCode))
            return
        }
        
        // Check if the challenge is expired (older than 7 days)
        let challengeDate = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let expirationInterval: TimeInterval = 7 * 24 * 60 * 60 // 7 days
        
        guard Date().timeIntervalSince(challengeDate) < expirationInterval else {
            completion(.failure(GameCenterServiceError.challengeExpired))
            return
        }
        
        completion(.success(courseID))
    }
    
    /// Generate a simple checksum for validation
    private func generateChecksum(for string: String) -> Int {
        var checksum = 0
        for char in string {
            checksum = ((checksum << 5) &+ checksum) &+ Int(char.asciiValue ?? 0)
        }
        return abs(checksum % 10000) // Keep it 4 digits
    }
    
    // MARK: - Enhanced Game Center Integration Methods
    
    /// Get offline data status for debugging and monitoring
    func getOfflineDataStatus() -> (scores: Int, achievements: Int) {
        return (offlineScores.count, offlineAchievements.count)
    }
    
    /// Force sync offline data (useful for testing or manual sync)
    func forceSyncOfflineData() {
        guard isAuthenticated && isOnline else {
            Logger.shared.warning("Cannot force sync - not authenticated or offline", category: .gameCenter)
            return
        }
        
        Logger.shared.info("Force syncing offline data", category: .gameCenter)
        syncOfflineData()
    }
    
    /// Clear all cached data (useful for testing or troubleshooting)
    func clearCachedData() {
        operationQueue.async {
            // Clear offline data
            self.offlineScores.removeAll()
            self.offlineAchievements.removeAll()
            
            // Clear cached leaderboards and achievements
            let userDefaults = UserDefaults.standard
            let keys = userDefaults.dictionaryRepresentation().keys
            
            for key in keys {
                if key.hasPrefix("CachedLeaderboard_") || key == "CachedAchievements" || key == "OfflineScores" || key == "OfflineAchievements" {
                    userDefaults.removeObject(forKey: key)
                }
            }
            
            userDefaults.synchronize()
            Logger.shared.info("Cleared all cached Game Center data", category: .gameCenter)
        }
    }
    
    /// Check if Game Center is available on the device
    var isGameCenterAvailable: Bool {
        return GKLocalPlayer.local.isAuthenticated || !GKLocalPlayer.local.isUnderage
    }
    
    /// Get current network and authentication status
    func getStatus() -> (isOnline: Bool, isAuthenticated: Bool, hasOfflineData: Bool) {
        let offlineStatus = getOfflineDataStatus()
        return (
            isOnline: isOnline,
            isAuthenticated: isAuthenticated,
            hasOfflineData: offlineStatus.scores > 0 || offlineStatus.achievements > 0
        )
    }
    
    // MARK: - Cleanup
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Error Handling
    
    /// Show an error alert
    private func showError(_ error: Error, from viewController: UIViewController) {
        DispatchQueue.main.async {
            // Check if the view controller is already presenting something
            if viewController.presentedViewController != nil {
                print("Warning: Cannot show error alert - view controller is already presenting something")
                return
            }
            
            let alert = UIAlertController(
                title: "Game Center Error",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            viewController.present(alert, animated: true)
        }
    }
}

// MARK: - GKGameCenterControllerDelegate

extension GameCenterService: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}