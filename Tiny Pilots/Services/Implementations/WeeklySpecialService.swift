import Foundation
import GameKit

/// Implementation of WeeklySpecialServiceProtocol
class WeeklySpecialService: WeeklySpecialServiceProtocol {
    
    // MARK: - Properties
    
    private let gameCenterService: GameCenterServiceProtocol
    private let networkService: NetworkServiceProtocol
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "CachedWeeklySpecials"
    private let participationKey = "WeeklySpecialParticipation"
    private let bestScoresKey = "WeeklySpecialBestScores"
    
    // Cache for loaded weekly specials
    private var cachedWeeklySpecials: [WeeklySpecial] = []
    private var lastCacheUpdate: Date?
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
    // MARK: - Initialization
    
    init(gameCenterService: GameCenterServiceProtocol, networkService: NetworkServiceProtocol) {
        self.gameCenterService = gameCenterService
        self.networkService = networkService
        loadCachedData()
    }
    
    // MARK: - WeeklySpecialServiceProtocol Implementation
    
    func loadWeeklySpecials(forceRefresh: Bool = false) async throws -> [WeeklySpecial] {
        Logger.shared.info("Loading weekly specials (forceRefresh: \(forceRefresh))", category: .network)
        
        // Check cache validity
        if !forceRefresh && isCacheValid() && !cachedWeeklySpecials.isEmpty {
            Logger.shared.info("Returning cached weekly specials", category: .network)
            return cachedWeeklySpecials.filter { $0.isActive }
        }
        
        do {
            // Load from server
            let weeklySpecials = try await loadFromServer()
            
            // Cache the results
            cachedWeeklySpecials = weeklySpecials
            lastCacheUpdate = Date()
            cacheWeeklySpecials(weeklySpecials)
            
            Logger.shared.info("Successfully loaded \(weeklySpecials.count) weekly specials", category: .network)
            
            // Track analytics
            AnalyticsManager.shared.trackEvent(.settingsChanged(setting: "weekly_specials_loaded", value: String(weeklySpecials.count)))
            
            return weeklySpecials.filter { $0.isActive }
            
        } catch {
            Logger.shared.error("Failed to load weekly specials from server", error: error, category: .network)
            
            // Fallback to cached data if available
            if !cachedWeeklySpecials.isEmpty {
                Logger.shared.info("Falling back to cached weekly specials", category: .network)
                return cachedWeeklySpecials.filter { $0.isActive }
            }
            
            // If no cache available, return sample data in debug mode
            #if DEBUG
            Logger.shared.warning("No cached data available, returning sample weekly special", category: .network)
            let sampleSpecial = WeeklySpecial.sample()
            return [sampleSpecial]
            #else
            throw error
            #endif
        }
    }
    
    func getWeeklySpecial(id: String) async throws -> WeeklySpecial {
        Logger.shared.info("Getting weekly special with ID: \(id)", category: .network)
        
        // First check cache
        if let cached = cachedWeeklySpecials.first(where: { $0.id == id }) {
            Logger.shared.info("Found weekly special in cache", category: .network)
            return cached
        }
        
        // Load from server
        do {
            let weeklySpecial = try await loadWeeklySpecialFromServer(id: id)
            Logger.shared.info("Successfully loaded weekly special from server", category: .network)
            return weeklySpecial
        } catch {
            Logger.shared.error("Failed to load weekly special from server", error: error, category: .network)
            throw WeeklySpecialError.notFound
        }
    }
    
    func submitScore(score: Int, weeklySpecialId: String, gameData: [String: Any]) async throws {
        Logger.shared.info("Submitting score \(score) for weekly special \(weeklySpecialId)", category: .game)
        
        // Validate input
        guard score > 0 else {
            throw WeeklySpecialError.validationError("Invalid score")
        }
        
        // Check if weekly special exists and is active
        let weeklySpecial = try await getWeeklySpecial(id: weeklySpecialId)
        guard weeklySpecial.isActive else {
            throw WeeklySpecialError.expired
        }
        
        do {
            // Submit to server
            try await submitScoreToServer(score: score, weeklySpecialId: weeklySpecialId, gameData: gameData)
            
            // Submit to Game Center leaderboard
            if let leaderboardId = ConfigurationManager.shared.gameCenterLeaderboardID(for: "weekly") {
                await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    gameCenterService.submitScore(score, to: leaderboardId) { submitError in
                        if submitError != nil {
                            Logger.shared.warning("Failed to submit score to Game Center", category: .game)
                        } else {
                            Logger.shared.info("Successfully submitted score to Game Center", category: .game)
                        }
                        continuation.resume()
                    }
                }
            }
            
            // Update local records
            updateParticipationRecord(weeklySpecialId: weeklySpecialId)
            updateBestScore(score: score, weeklySpecialId: weeklySpecialId)
            
            // Track analytics
            AnalyticsManager.shared.trackEvent(.gameCompleted(mode: .weeklySpecial, score: score, duration: 0, environment: weeklySpecial.environment))
            
            Logger.shared.info("Successfully submitted score for weekly special", category: .game)
            
        } catch {
            Logger.shared.error("Failed to submit score", error: error, category: .network)
            throw WeeklySpecialError.submissionFailed
        }
    }
    
    func loadLeaderboard(weeklySpecialId: String) async throws -> [WeeklySpecialLeaderboardEntry] {
        Logger.shared.info("Loading leaderboard for weekly special \(weeklySpecialId)", category: .network)
        
        do {
            let entries = try await loadLeaderboardFromServer(weeklySpecialId: weeklySpecialId)
            Logger.shared.info("Successfully loaded \(entries.count) leaderboard entries", category: .network)
            return entries
        } catch {
            Logger.shared.error("Failed to load leaderboard from server", error: error, category: .network)
            
            // Fallback to Game Center leaderboard if available
            if let leaderboardId = ConfigurationManager.shared.gameCenterLeaderboardID(for: "weekly") {
                return try await loadGameCenterLeaderboard(leaderboardId: leaderboardId, weeklySpecialId: weeklySpecialId)
            }
            
            throw WeeklySpecialError.leaderboardUnavailable
        }
    }
    
    func generateShareCode(for weeklySpecial: WeeklySpecial) -> String {
        Logger.shared.info("Generating share code for weekly special: \(weeklySpecial.title)", category: .game)
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let randomSeed = Int.random(in: 1000...9999)
        
        // Base components: weeklySpecialId_timestamp_randomSeed
        let baseString = "\(weeklySpecial.id)_\(timestamp)_\(randomSeed)"
        
        // Generate checksum
        let checksum = generateChecksum(for: baseString)
        
        // Final format: WS_weeklySpecialId_timestamp_randomSeed_checksum
        let shareCode = "WS_\(baseString)_\(checksum)"
        
        Logger.shared.info("Generated share code successfully", category: .game)
        
        // Track analytics
        AnalyticsManager.shared.trackEvent(.challengeShared(challengeId: weeklySpecial.id))
        
        return shareCode
    }
    
    func loadFromShareCode(_ shareCode: String) async throws -> WeeklySpecial {
        Logger.shared.info("Loading weekly special from share code", category: .network)
        
        // Validate share code format
        let components = shareCode.split(separator: "_")
        guard components.count == 5,
              components[0] == "WS",
              let timestamp = Int(components[2]),
              let randomSeed = Int(components[3]),
              let checksum = Int(components[4]) else {
            throw WeeklySpecialError.invalidShareCode
        }
        
        // Validate checksum
        let weeklySpecialId = String(components[1])
        let baseString = "\(weeklySpecialId)_\(timestamp)_\(randomSeed)"
        let expectedChecksum = generateChecksum(for: baseString)
        
        guard checksum == expectedChecksum else {
            throw WeeklySpecialError.invalidShareCode
        }
        
        // Check if share code is expired (older than 7 days)
        let shareDate = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let expirationInterval: TimeInterval = 7 * 24 * 60 * 60 // 7 days
        
        guard Date().timeIntervalSince(shareDate) < expirationInterval else {
            throw WeeklySpecialError.expired
        }
        
        // Load the weekly special
        do {
            let weeklySpecial = try await getWeeklySpecial(id: weeklySpecialId)
            Logger.shared.info("Successfully loaded weekly special from share code", category: .network)
            return weeklySpecial
        } catch {
            Logger.shared.error("Failed to load weekly special from share code", error: error, category: .network)
            throw WeeklySpecialError.notFound
        }
    }
    
    func hasParticipated(in weeklySpecialId: String) -> Bool {
        let participationData = userDefaults.dictionary(forKey: participationKey) as? [String: Bool] ?? [:]
        return participationData[weeklySpecialId] ?? false
    }
    
    func getPlayerBestScore(for weeklySpecialId: String) -> Int? {
        let bestScores = userDefaults.dictionary(forKey: bestScoresKey) as? [String: Int] ?? [:]
        return bestScores[weeklySpecialId]
    }
    
    func cacheWeeklySpecials(_ weeklySpecials: [WeeklySpecial]) {
        do {
            let data = try JSONEncoder().encode(weeklySpecials)
            userDefaults.set(data, forKey: cacheKey)
            Logger.shared.info("Successfully cached \(weeklySpecials.count) weekly specials", category: .app)
        } catch {
            Logger.shared.error("Failed to cache weekly specials", error: error, category: .app)
        }
    }
    
    func loadCachedWeeklySpecials() -> [WeeklySpecial] {
        guard let data = userDefaults.data(forKey: cacheKey) else {
            Logger.shared.info("No cached weekly specials found", category: .app)
            return []
        }
        
        do {
            let weeklySpecials = try JSONDecoder().decode([WeeklySpecial].self, from: data)
            
            // Filter out expired weekly specials
            let validSpecials = weeklySpecials.filter { !$0.isExpired }
            
            // If we filtered out expired specials, update the cache
            if validSpecials.count != weeklySpecials.count {
                cacheWeeklySpecials(validSpecials)
                Logger.shared.info("Cleaned up \(weeklySpecials.count - validSpecials.count) expired weekly specials from cache", category: .app)
            }
            
            Logger.shared.info("Loaded \(validSpecials.count) cached weekly specials", category: .app)
            return validSpecials
        } catch {
            Logger.shared.error("Failed to decode cached weekly specials", error: error, category: .app)
            return []
        }
    }
    
    // MARK: - Private Methods
    
    private func loadCachedData() {
        cachedWeeklySpecials = loadCachedWeeklySpecials()
        if !cachedWeeklySpecials.isEmpty {
            lastCacheUpdate = Date()
        }
    }
    
    private func isCacheValid() -> Bool {
        guard let lastUpdate = lastCacheUpdate else { return false }
        return Date().timeIntervalSince(lastUpdate) < cacheValidityDuration
    }
    
    private func loadFromServer() async throws -> [WeeklySpecial] {
        // In a real implementation, this would make an HTTP request to the server
        // For now, we'll simulate server response with sample data
        
        #if DEBUG
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Return sample weekly specials
        return [WeeklySpecial.sample()]
        #else
        // In production, make actual network request
        let endpoint = "\(ConfigurationManager.shared.apiBaseURL)/weekly-specials"
        let weeklySpecials = try await networkService.get(endpoint: endpoint, responseType: [WeeklySpecial].self)
        return weeklySpecials
        #endif
    }
    
    private func loadWeeklySpecialFromServer(id: String) async throws -> WeeklySpecial {
        #if DEBUG
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Return sample if ID matches
        let sample = WeeklySpecial.sample()
        if sample.id == id {
            return sample
        } else {
            throw WeeklySpecialError.notFound
        }
        #else
        // In production, make actual network request
        let endpoint = "\(ConfigurationManager.shared.apiBaseURL)/weekly-specials/\(id)"
        let weeklySpecial = try await networkService.get(endpoint: endpoint, responseType: WeeklySpecial.self)
        return weeklySpecial
        #endif
    }
    
    private func submitScoreToServer(score: Int, weeklySpecialId: String, gameData: [String: Any]) async throws {
        #if DEBUG
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        Logger.shared.info("Simulated score submission to server", category: .network)
        #else
        // In production, make actual network request
        let endpoint = "\(ConfigurationManager.shared.apiBaseURL)/weekly-specials/\(weeklySpecialId)/scores"
        let payload = [
            "score": score,
            "gameData": gameData
        ]
        try await networkService.post(endpoint: endpoint, payload: payload)
        #endif
    }
    
    private func loadLeaderboardFromServer(weeklySpecialId: String) async throws -> [WeeklySpecialLeaderboardEntry] {
        #if DEBUG
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Return sample leaderboard data
        return [
            WeeklySpecialLeaderboardEntry(
                playerID: "player1",
                displayName: "SkyMaster",
                score: 1850,
                rank: 1,
                completionTime: 142.5,
                weeklySpecialId: weeklySpecialId
            ),
            WeeklySpecialLeaderboardEntry(
                playerID: "player2",
                displayName: "WindRider",
                score: 1720,
                rank: 2,
                completionTime: 156.8,
                weeklySpecialId: weeklySpecialId
            ),
            WeeklySpecialLeaderboardEntry(
                playerID: "player3",
                displayName: "CloudHopper",
                score: 1650,
                rank: 3,
                completionTime: 163.2,
                weeklySpecialId: weeklySpecialId
            )
        ]
        #else
        // In production, make actual network request
        let endpoint = "\(ConfigurationManager.shared.apiBaseURL)/weekly-specials/\(weeklySpecialId)/leaderboard"
        let entries = try await networkService.get(endpoint: endpoint, responseType: [WeeklySpecialLeaderboardEntry].self)
        return entries
        #endif
    }
    
    private func loadGameCenterLeaderboard(leaderboardId: String, weeklySpecialId: String) async throws -> [WeeklySpecialLeaderboardEntry] {
        return try await withCheckedThrowingContinuation { continuation in
            gameCenterService.loadLeaderboard(for: leaderboardId) { entries, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let weeklyEntries = (entries ?? []).map { entry in
                    WeeklySpecialLeaderboardEntry(
                        playerID: entry.playerID,
                        displayName: entry.displayName,
                        score: entry.score,
                        rank: entry.rank,
                        completionTime: 0, // Game Center doesn't track completion time
                        submissionDate: entry.date,
                        weeklySpecialId: weeklySpecialId
                    )
                }
                
                continuation.resume(returning: weeklyEntries)
            }
        }
    }
    
    private func updateParticipationRecord(weeklySpecialId: String) {
        var participationData = userDefaults.dictionary(forKey: participationKey) as? [String: Bool] ?? [:]
        participationData[weeklySpecialId] = true
        userDefaults.set(participationData, forKey: participationKey)
        
        Logger.shared.info("Updated participation record for weekly special \(weeklySpecialId)", category: .app)
    }
    
    private func updateBestScore(score: Int, weeklySpecialId: String) {
        var bestScores = userDefaults.dictionary(forKey: bestScoresKey) as? [String: Int] ?? [:]
        let currentBest = bestScores[weeklySpecialId] ?? 0
        
        if score > currentBest {
            bestScores[weeklySpecialId] = score
            userDefaults.set(bestScores, forKey: bestScoresKey)
            Logger.shared.info("Updated best score for weekly special \(weeklySpecialId): \(score)", category: .app)
        }
    }
    
    private func generateChecksum(for string: String) -> Int {
        var checksum = 0
        for char in string {
            checksum = ((checksum << 5) &+ checksum) &+ Int(char.asciiValue ?? 0)
        }
        return abs(checksum % 10000) // Keep it 4 digits
    }
}

// MARK: - NetworkServiceProtocol

// NetworkServiceProtocol is defined in Services/Protocols/NetworkServiceProtocol.swift

