//
//  DailyRunService.swift
//  Tiny Pilots
//
//  Created by Kiro on Production Readiness Implementation
//

import Foundation
import GameKit

/// Implementation of DailyRunServiceProtocol
class DailyRunService: DailyRunServiceProtocol {
    
    // MARK: - Properties
    
    private let gameCenterService: GameCenterServiceProtocol
    private let networkService: NetworkServiceProtocol?
    private let userDefaults = UserDefaults.standard
    
    /// Current daily run cache
    private var currentDailyRun: DailyRun?
    private var dailyRunCache: [String: DailyRun] = [:]
    
    /// Player data
    private var streakInfo: DailyRunStreak?
    private var completedRuns: Set<String> = []
    
    /// Configuration
    private let appConfiguration = ConfigurationManager.shared.currentConfiguration
    
    /// Queue for background operations
    private let operationQueue = DispatchQueue(label: "com.tinypilots.dailyrun", qos: .utility)
    
    // MARK: - Initialization
    
    init(gameCenterService: GameCenterServiceProtocol, networkService: NetworkServiceProtocol? = nil) {
        self.gameCenterService = gameCenterService
        self.networkService = networkService
        
        loadLocalData()
        setupDailyRunGeneration()
    }
    
    // MARK: - Public Interface
    
    func getCurrentDailyRun(completion: @escaping (Result<DailyRun, Error>) -> Void) {
        let today = Calendar.current.startOfDay(for: Date())
        let todayKey = dailyRunKey(for: today)
        
        // Check if we have today's daily run cached
        if let cachedRun = dailyRunCache[todayKey], 
           Calendar.current.isDate(cachedRun.date, inSameDayAs: today) {
            Logger.shared.info("Returning cached daily run for today", category: .game)
            completion(.success(cachedRun))
            return
        }
        
        // Generate today's daily run
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let dailyRun = try self.generateDailyRun(for: today)
                self.dailyRunCache[todayKey] = dailyRun
                self.currentDailyRun = dailyRun
                self.saveDailyRunCache()
                
                Logger.shared.info("Generated new daily run for today", category: .game)
                AnalyticsManager.shared.trackEvent(.dailyRunGenerated(difficulty: dailyRun.difficulty.rawValue))
                
                DispatchQueue.main.async {
                    completion(.success(dailyRun))
                }
            } catch {
                Logger.shared.error("Failed to generate daily run", error: error, category: .game)
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func submitDailyRunScore(_ score: Int, completion: @escaping (Error?) -> Void) {
        guard gameCenterService.isAuthenticated else {
            completion(DailyRunServiceError.notAuthenticated)
            return
        }
        
        guard score > 0 else {
            completion(DailyRunServiceError.invalidScore)
            return
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let todayKey = dailyRunKey(for: today)
        
        // Check if already completed today
        if completedRuns.contains(todayKey) {
            completion(DailyRunServiceError.alreadyCompleted)
            return
        }
        
        Logger.shared.info("Submitting daily run score: \(score)", category: .game)
        
        // Submit to Game Center leaderboard
        let leaderboardID = appConfiguration.gameCenterConfiguration.leaderboardIDs["daily"] ?? "daily_run"
        
        gameCenterService.submitScore(score, to: leaderboardID) { [weak self] error in
            if let error = error {
                Logger.shared.error("Failed to submit daily run score to Game Center", error: error, category: .game)
                completion(error)
                return
            }
            
            // Mark as completed and update streak
            self?.markDailyRunCompleted(todayKey, score: score)
            self?.updateStreak()
            
            Logger.shared.info("Daily run score submitted successfully", category: .game)
            AnalyticsManager.shared.trackEvent(.dailyRunCompleted(score: score))
            completion(nil)
        }
    }
    
    func getDailyRunLeaderboard(completion: @escaping (Result<[DailyRunLeaderboardEntry], Error>) -> Void) {
        guard gameCenterService.isAuthenticated else {
            completion(.failure(DailyRunServiceError.notAuthenticated))
            return
        }
        
        let leaderboardID = appConfiguration.gameCenterConfiguration.leaderboardIDs["daily"] ?? "daily_run"
        
        gameCenterService.loadLeaderboard(for: leaderboardID) { entries, error in
            if let error = error {
                Logger.shared.error("Failed to load daily run leaderboard", error: error, category: .game)
                completion(.failure(error))
                return
            }
            
            let currentPlayerID = GKLocalPlayer.local.gamePlayerID
            let dailyRunEntries = entries?.enumerated().map { _, entry in
                DailyRunLeaderboardEntry(
                    playerID: entry.playerID,
                    displayName: entry.displayName,
                    score: entry.score,
                    rank: entry.rank,
                    completionTime: entry.date,
                    isCurrentPlayer: entry.playerID == currentPlayerID
                )
            } ?? []
            
            Logger.shared.info("Loaded \(dailyRunEntries.count) daily run leaderboard entries", category: .game)
            completion(.success(dailyRunEntries))
        }
    }
    
    func getStreakInfo(completion: @escaping (Result<DailyRunStreak, Error>) -> Void) {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            if let cachedStreak = self.streakInfo {
                DispatchQueue.main.async {
                    completion(.success(cachedStreak))
                }
                return
            }
            
            // Calculate streak info
            let streak = self.calculateCurrentStreak()
            self.streakInfo = streak
            self.saveStreakInfo()
            
            DispatchQueue.main.async {
                completion(.success(streak))
            }
        }
    }
    
    func hasCompletedTodaysDailyRun() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let todayKey = dailyRunKey(for: today)
        return completedRuns.contains(todayKey)
    }
    
    func getDailyRunHistory(completion: @escaping (Result<[DailyRunResult], Error>) -> Void) {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            let history = self.loadDailyRunHistory()
            
            DispatchQueue.main.async {
                completion(.success(history))
            }
        }
    }
    
    func generateShareableResult(_ result: DailyRunResult, completion: @escaping (Result<DailyRunShareData, Error>) -> Void) {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            let shareData = self.createShareableData(from: result)
            
            DispatchQueue.main.async {
                completion(.success(shareData))
            }
        }
    }
    
    func getFriendsComparison(completion: @escaping (Result<[DailyRunFriendComparison], Error>) -> Void) {
        // This would integrate with Game Center friends API
        // For now, return empty array as friends comparison requires Game Center social features
        Logger.shared.info("Friends comparison requested - feature not yet implemented", category: .game)
        completion(.success([]))
    }
    
    // MARK: - Private Methods
    
    private func setupDailyRunGeneration() {
        // Set up daily run generation based on deterministic seed
        Logger.shared.info("Daily run service initialized", category: .game)
    }
    
    private func generateDailyRun(for date: Date) throws -> DailyRun {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        // Generate deterministic seed based on date
        let seed = generateSeed(for: dateString)
        var random = SeededRandom(seed: seed)
        
        // Determine difficulty based on day of week and date
        let difficulty = determineDifficulty(for: date, random: &random)
        
        // Generate challenge data
        let challengeData = generateChallengeData(difficulty: difficulty, random: &random)
        
        // Calculate rewards
        let rewards = calculateRewards(difficulty: difficulty)
        
        // Set expiration time (end of day)
        let expiresAt = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: date)) ?? date
        
        let dailyRun = DailyRun(
            id: "daily_\(dateString)",
            date: date,
            seed: seed,
            challengeData: challengeData,
            difficulty: difficulty,
            rewards: rewards,
            expiresAt: expiresAt
        )
        
        Logger.shared.info("Generated daily run: \(dailyRun.id), difficulty: \(difficulty.displayName)", category: .game)
        
        return dailyRun
    }
    
    private func generateSeed(for dateString: String) -> Int {
        // Create deterministic seed from date string
        var hash = 0
        for char in dateString {
            hash = ((hash << 5) &- hash) &+ Int(char.asciiValue ?? 0)
        }
        return abs(hash)
    }
    
    private func determineDifficulty(for date: Date, random: inout SeededRandom) -> DailyRunDifficulty {
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: date)
        let dayOfMonth = calendar.component(.day, from: date)
        
        // Weekend runs are generally harder
        if dayOfWeek == 1 || dayOfWeek == 7 { // Sunday or Saturday
            return random.nextDouble() < 0.6 ? .hard : .extreme
        }
        
        // Special difficulty on certain days
        if dayOfMonth % 10 == 0 { // Every 10th day
            return .extreme
        }
        
        // Regular weekday distribution
        let rand = random.nextDouble()
        switch rand {
        case 0.0..<0.3: return .easy
        case 0.3..<0.6: return .medium
        case 0.6..<0.85: return .hard
        default: return .extreme
        }
    }
    
    private func generateChallengeData(difficulty: DailyRunDifficulty, random: inout SeededRandom) -> DailyRunChallengeData {
        // Select environment
        let environments = ["sunny_meadows", "alpine_heights", "coastal_breeze", "urban_skyline", "desert_canyon"]
        let environmentType = environments[random.nextInt(max: environments.count)]
        
        // Generate obstacles based on difficulty
        let obstacleCount = getObstacleCount(for: difficulty)
        var obstacles: [ObstacleConfiguration] = []
        
        for i in 0..<obstacleCount {
            let obstacleType = getRandomObstacleType(random: &random)
            let position = CGPoint(
                x: Double(100 + i * 150 + random.nextInt(max: 100)),
                y: Double(50 + random.nextInt(max: 200))
            )
            obstacles.append(ObstacleConfiguration(type: obstacleType, position: position))
        }
        
        // Generate collectibles
        let collectibleCount = getCollectibleCount(for: difficulty)
        var collectibles: [CollectibleConfiguration] = []
        
        for i in 0..<collectibleCount {
            let collectibleType = getRandomCollectibleType(random: &random)
            let position = CGPoint(
                x: Double(75 + i * 120 + random.nextInt(max: 80)),
                y: Double(30 + random.nextInt(max: 150))
            )
            let value = getCollectibleValue(type: collectibleType, difficulty: difficulty)
            collectibles.append(CollectibleConfiguration(type: collectibleType, position: position, value: value))
        }
        
        // Generate weather conditions
        let weatherConditions = generateWeatherConditions(difficulty: difficulty, random: &random)
        
        // Generate special modifiers
        let modifiers = generateModifiers(difficulty: difficulty, random: &random)
        
        return DailyRunChallengeData(
            environmentType: environmentType,
            obstacles: obstacles,
            collectibles: collectibles,
            weatherConditions: weatherConditions,
            specialModifiers: modifiers,
            targetDistance: getTargetDistance(for: difficulty),
            timeLimit: getTimeLimit(for: difficulty)
        )
    }
    
    private func getObstacleCount(for difficulty: DailyRunDifficulty) -> Int {
        switch difficulty {
        case .easy: return 3
        case .medium: return 5
        case .hard: return 8
        case .extreme: return 12
        }
    }
    
    private func getCollectibleCount(for difficulty: DailyRunDifficulty) -> Int {
        switch difficulty {
        case .easy: return 8
        case .medium: return 6
        case .hard: return 4
        case .extreme: return 3
        }
    }
    
    private func getRandomObstacleType(random: inout SeededRandom) -> String {
        let types = ["tree", "building", "mountain", "cloud", "bird"]
        return types[random.nextInt(max: types.count)]
    }
    
    private func getRandomCollectibleType(random: inout SeededRandom) -> String {
        let types = ["coin", "star", "gem", "powerup"]
        return types[random.nextInt(max: types.count)]
    }
    
    private func getCollectibleValue(type: String, difficulty: DailyRunDifficulty) -> Int {
        let baseValue: Int
        switch type {
        case "coin": baseValue = 10
        case "star": baseValue = 25
        case "gem": baseValue = 50
        case "powerup": baseValue = 100
        default: baseValue = 10
        }
        
        return Int(Double(baseValue) * difficulty.scoreMultiplier)
    }
    
    private func generateWeatherConditions(difficulty: DailyRunDifficulty, random: inout SeededRandom) -> WeatherConfiguration {
        let windSpeed = random.nextDouble() * (difficulty == .extreme ? 1.0 : 0.6)
        let windDirection = random.nextDouble() * 360
        
        return WeatherConfiguration(windSpeed: windSpeed, windDirection: windDirection)
    }
    
    private func generateModifiers(difficulty: DailyRunDifficulty, random: inout SeededRandom) -> [DailyRunModifier] {
        var modifiers: [DailyRunModifier] = []
        
        let modifierCount = difficulty == .extreme ? 2 : (difficulty == .hard ? 1 : 0)
        let availableModifiers = DailyRunModifier.allCases
        
        for _ in 0..<modifierCount {
            if let modifier = availableModifiers.randomElement() {
                if !modifiers.contains(modifier) {
                    modifiers.append(modifier)
                }
            }
        }
        
        return modifiers
    }
    
    private func getTargetDistance(for difficulty: DailyRunDifficulty) -> Int? {
        switch difficulty {
        case .easy: return 500
        case .medium: return 750
        case .hard: return 1000
        case .extreme: return nil // No target, survive as long as possible
        }
    }
    
    private func getTimeLimit(for difficulty: DailyRunDifficulty) -> TimeInterval? {
        switch difficulty {
        case .easy: return nil
        case .medium: return nil
        case .hard: return 120 // 2 minutes
        case .extreme: return 90 // 1.5 minutes
        }
    }
    
    private func calculateRewards(difficulty: DailyRunDifficulty) -> DailyRunRewards {
        let baseCoins: Int
        switch difficulty {
        case .easy: baseCoins = 50
        case .medium: baseCoins = 75
        case .hard: baseCoins = 100
        case .extreme: baseCoins = 150
        }
        
        let currentStreak = streakInfo?.currentStreak ?? 0
        let streakBonus = min(currentStreak * 10, 100) // Max 100 bonus coins
        
        let difficultyBonus = Int(Double(baseCoins) * (difficulty.scoreMultiplier - 1.0))
        
        var achievements: [String] = []
        if difficulty == .extreme {
            achievements.append("daily_run_extreme")
        }
        
        return DailyRunRewards(
            baseCoins: baseCoins,
            streakBonus: streakBonus,
            difficultyBonus: difficultyBonus,
            achievements: achievements
        )
    }
    
    private func markDailyRunCompleted(_ runKey: String, score: Int) {
        completedRuns.insert(runKey)
        saveCompletedRuns()
        
        // Save result to history
        let result = DailyRunResult(
            id: UUID().uuidString,
            dailyRunId: runKey,
            playerID: GKLocalPlayer.local.gamePlayerID,
            score: score,
            distance: Double(score), // Simplified - in real implementation this would be separate
            coinsCollected: score / 10, // Simplified calculation
            completionTime: Date(),
            duration: 0, // Would be tracked during gameplay
            rank: nil, // Would be determined after leaderboard update
            rewards: currentDailyRun?.rewards ?? DailyRunRewards(baseCoins: 0, streakBonus: 0, difficultyBonus: 0, achievements: [])
        )
        
        saveDailyRunResult(result)
    }
    
    private func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
        
        let todayKey = dailyRunKey(for: today)
        let yesterdayKey = dailyRunKey(for: yesterday)
        
        var currentStreak = streakInfo?.currentStreak ?? 0
        let longestStreak = streakInfo?.longestStreak ?? 0
        
        // Check if completed today
        if completedRuns.contains(todayKey) {
            // Check if also completed yesterday to continue streak
            if completedRuns.contains(yesterdayKey) || currentStreak == 0 {
                currentStreak += 1
            } else {
                currentStreak = 1 // Reset streak
            }
        }
        
        let newLongestStreak = max(longestStreak, currentStreak)
        
        streakInfo = DailyRunStreak(
            currentStreak: currentStreak,
            longestStreak: newLongestStreak,
            lastCompletionDate: completedRuns.contains(todayKey) ? Date() : streakInfo?.lastCompletionDate,
            nextRewardAt: getNextRewardStreak(currentStreak),
            streakRewards: getStreakRewards()
        )
        
        saveStreakInfo()
        Logger.shared.info("Updated daily run streak: \(currentStreak)", category: .game)
    }
    
    private func calculateCurrentStreak() -> DailyRunStreak {
        let today = Calendar.current.startOfDay(for: Date())
        var currentStreak = 0
        var checkDate = today
        
        // Count consecutive days backwards
        while true {
            let dateKey = dailyRunKey(for: checkDate)
            if completedRuns.contains(dateKey) {
                currentStreak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        
        // Calculate longest streak
        let longestStreak = calculateLongestStreak()
        
        return DailyRunStreak(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastCompletionDate: currentStreak > 0 ? today : nil,
            nextRewardAt: getNextRewardStreak(currentStreak),
            streakRewards: getStreakRewards()
        )
    }
    
    private func calculateLongestStreak() -> Int {
        // This would analyze all completed runs to find the longest consecutive streak
        // For now, return current streak as a simplified implementation
        return streakInfo?.longestStreak ?? 0
    }
    
    private func getNextRewardStreak(_ currentStreak: Int) -> Int {
        let rewardMilestones = [3, 7, 14, 30, 50, 100]
        return rewardMilestones.first { $0 > currentStreak } ?? (currentStreak + 10)
    }
    
    private func getStreakRewards() -> [DailyRunStreakReward] {
        return [
            DailyRunStreakReward(streakLength: 3, coins: 50, title: "Getting Started", achievement: nil),
            DailyRunStreakReward(streakLength: 7, coins: 100, title: "Week Warrior", achievement: "daily_run_week"),
            DailyRunStreakReward(streakLength: 14, coins: 200, title: "Two Week Champion", achievement: "daily_run_two_weeks"),
            DailyRunStreakReward(streakLength: 30, coins: 500, title: "Monthly Master", achievement: "daily_run_month"),
            DailyRunStreakReward(streakLength: 50, coins: 1000, title: "Dedication Legend", achievement: "daily_run_fifty"),
            DailyRunStreakReward(streakLength: 100, coins: 2500, title: "Century Achiever", achievement: "daily_run_century")
        ]
    }
    
    private func createShareableData(from result: DailyRunResult) -> DailyRunShareData {
        let text = "I just completed today's Daily Run in Tiny Pilots! Score: \(result.score) 🛩️"
        let hashtags = ["#TinyPilots", "#DailyRun", "#MobileGaming"]
        
        return DailyRunShareData(
            text: text,
            image: nil, // Would generate screenshot in real implementation
            url: "https://tinypilots.com/daily-run/\(result.dailyRunId)",
            hashtags: hashtags
        )
    }
    
    // MARK: - Data Persistence
    
    private func dailyRunKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "daily_run_\(formatter.string(from: date))"
    }
    
    private func loadLocalData() {
        loadCompletedRuns()
        loadDailyRunCache()
        loadStreakInfo()
    }
    
    private func loadCompletedRuns() {
        if let data = userDefaults.data(forKey: "CompletedDailyRuns"),
           let runs = try? JSONDecoder().decode(Set<String>.self, from: data) {
            completedRuns = runs
            Logger.shared.info("Loaded \(runs.count) completed daily runs", category: .game)
        }
    }
    
    private func saveCompletedRuns() {
        if let data = try? JSONEncoder().encode(completedRuns) {
            userDefaults.set(data, forKey: "CompletedDailyRuns")
        }
    }
    
    private func loadDailyRunCache() {
        if let data = userDefaults.data(forKey: "DailyRunCache"),
           let cache = try? JSONDecoder().decode([String: DailyRun].self, from: data) {
            dailyRunCache = cache
            Logger.shared.info("Loaded daily run cache with \(cache.count) entries", category: .game)
        }
    }
    
    private func saveDailyRunCache() {
        if let data = try? JSONEncoder().encode(dailyRunCache) {
            userDefaults.set(data, forKey: "DailyRunCache")
        }
    }
    
    private func loadStreakInfo() {
        if let data = userDefaults.data(forKey: "DailyRunStreak"),
           let streak = try? JSONDecoder().decode(DailyRunStreak.self, from: data) {
            streakInfo = streak
            Logger.shared.info("Loaded daily run streak: \(streak.currentStreak)", category: .game)
        }
    }
    
    private func saveStreakInfo() {
        if let streak = streakInfo,
           let data = try? JSONEncoder().encode(streak) {
            userDefaults.set(data, forKey: "DailyRunStreak")
        }
    }
    
    private func loadDailyRunHistory() -> [DailyRunResult] {
        guard let data = userDefaults.data(forKey: "DailyRunHistory"),
              let history = try? JSONDecoder().decode([DailyRunResult].self, from: data) else {
            return []
        }
        return history.sorted { $0.completionTime > $1.completionTime }
    }
    
    private func saveDailyRunResult(_ result: DailyRunResult) {
        var history = loadDailyRunHistory()
        history.append(result)
        
        // Keep only last 30 results
        if history.count > 30 {
            history = Array(history.suffix(30))
        }
        
        if let data = try? JSONEncoder().encode(history) {
            userDefaults.set(data, forKey: "DailyRunHistory")
        }
    }
}

// MARK: - Supporting Types

/// Seeded random number generator for deterministic daily runs
private struct SeededRandom {
    private var seed: UInt64
    
    init(seed: Int) {
        self.seed = UInt64(abs(seed))
    }
    
    mutating func nextInt(max: Int) -> Int {
        guard max > 0 else { return 0 }
        seed = seed &* 1103515245 &+ 12345
        return Int(seed % UInt64(max))
    }
    
    mutating func nextDouble() -> Double {
        seed = seed &* 1103515245 &+ 12345
        return Double(seed % 1000000) / 1000000.0
    }
}

// MARK: - Codable Extensions

// Codable conformance is handled in the protocol file where the structs are defined