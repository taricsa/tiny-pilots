//
//  DailyRunView.swift
//  Tiny Pilots
//
//  Created by Kiro on Production Readiness Implementation
//

import SwiftUI

struct DailyRunView: View {
    @State private var currentDailyRun: DailyRun?
    @State private var streakInfo: DailyRunStreak?
    @State private var leaderboard: [DailyRunLeaderboardEntry] = []
    @State private var isLoading = false
    @State private var hasCompleted = false
    @State private var showingLeaderboard = false
    @State private var showingHistory = false
    @State private var errorMessage: String?
    @State private var showingAlert = false
    
    // Services
    private let dailyRunService: DailyRunServiceProtocol
    private let gameCenterService: GameCenterServiceProtocol
    
    // Initialize with dependency injection
    init() {
        do {
            self.dailyRunService = try DIContainer.shared.resolve(DailyRunServiceProtocol.self)
            self.gameCenterService = try DIContainer.shared.resolve(GameCenterServiceProtocol.self)
        } catch {
            print("Failed to resolve services for DailyRunView: \(error)")
            // Fallback - this should not happen in production
            fatalError("Failed to initialize DailyRunView: \(error)")
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Streak Information
                    if let streak = streakInfo {
                        streakSection(streak)
                    }
                    
                    // Daily Run Challenge
                    if let dailyRun = currentDailyRun {
                        dailyRunSection(dailyRun)
                    }
                    
                    // Action Buttons
                    actionButtonsSection
                    
                    // Leaderboard Preview
                    if !leaderboard.isEmpty {
                        leaderboardPreviewSection
                    }
                }
                .padding()
            }
            .navigationTitle("Daily Run")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await loadDailyRunData()
            }
            .onAppear {
                Task {
                    await loadDailyRunData()
                }
            }
            .alert("Daily Run", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showingLeaderboard) {
                DailyRunLeaderboardView(leaderboard: leaderboard)
            }
            .sheet(isPresented: $showingHistory) {
                DailyRunHistoryView()
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Daily Run")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Complete today's unique challenge!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private func streakSection(_ streak: DailyRunStreak) -> some View {
        VStack(spacing: 15) {
            HStack {
                VStack {
                    Text("\(streak.currentStreak)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Current Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Text("\(streak.longestStreak)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    Text("Best Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Text("\(streak.nextRewardAt)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Next Reward")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar to next reward
            let progress = Double(streak.currentStreak) / Double(streak.nextRewardAt)
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
            
            Text("Keep your streak alive! \(streak.nextRewardAt - streak.currentStreak) more days to next reward")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    private func dailyRunSection(_ dailyRun: DailyRun) -> some View {
        VStack(spacing: 15) {
            HStack {
                Text("Today's Challenge")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                difficultyBadge(dailyRun.difficulty)
            }
            
            // Challenge details
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "location")
                    Text("Environment: \(dailyRun.challengeData.environmentType.capitalized)")
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "target")
                    Text("Obstacles: \(dailyRun.challengeData.obstacles.count)")
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "star")
                    Text("Collectibles: \(dailyRun.challengeData.collectibles.count)")
                        .font(.subheadline)
                }
                
                if let targetDistance = dailyRun.challengeData.targetDistance {
                    HStack {
                        Image(systemName: "ruler")
                        Text("Target: \(targetDistance)m")
                            .font(.subheadline)
                    }
                }
                
                if let timeLimit = dailyRun.challengeData.timeLimit {
                    HStack {
                        Image(systemName: "timer")
                        Text("Time Limit: \(Int(timeLimit))s")
                            .font(.subheadline)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Special modifiers
            if !dailyRun.challengeData.specialModifiers.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Special Modifiers:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(dailyRun.challengeData.specialModifiers, id: \.rawValue) { modifier in
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                            Text(modifier.displayName)
                                .font(.caption)
                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Rewards
            rewardsSection(dailyRun.rewards)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(15)
    }
    
    private func difficultyBadge(_ difficulty: DailyRunDifficulty) -> some View {
        Text(difficulty.displayName)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(difficultyColor(difficulty))
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    private func difficultyColor(_ difficulty: DailyRunDifficulty) -> Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        case .extreme: return .purple
        }
    }
    
    private func rewardsSection(_ rewards: DailyRunRewards) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Rewards:")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Image(systemName: "dollarsign.circle")
                    .foregroundColor(.yellow)
                Text("\(rewards.baseCoins + rewards.streakBonus + rewards.difficultyBonus) coins")
                    .font(.caption)
            }
            
            if rewards.streakBonus > 0 {
                HStack {
                    Image(systemName: "flame")
                        .foregroundColor(.orange)
                    Text("+\(rewards.streakBonus) streak bonus")
                        .font(.caption)
                }
            }
            
            if !rewards.achievements.isEmpty {
                HStack {
                    Image(systemName: "trophy")
                        .foregroundColor(.gold)
                    Text("Achievement unlock possible")
                        .font(.caption)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 15) {
            // Play Daily Run Button
            Button(action: {
                playDailyRun()
            }) {
                HStack {
                    Image(systemName: hasCompleted ? "checkmark.circle" : "play.circle")
                    Text(hasCompleted ? "Completed Today" : "Play Daily Run")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(hasCompleted ? Color.green : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(hasCompleted || !gameCenterService.isAuthenticated)
            
            // Secondary buttons
            HStack(spacing: 15) {
                Button("Leaderboard") {
                    showingLeaderboard = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("History") {
                    showingHistory = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            if !gameCenterService.isAuthenticated {
                Text("Sign in to Game Center to participate in Daily Runs")
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var leaderboardPreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today's Leaderboard")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    showingLeaderboard = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            ForEach(Array(leaderboard.prefix(3).enumerated()), id: \.offset) { index, entry in
                HStack {
                    Text("#\(entry.rank)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 30, alignment: .leading)
                    
                    Text(entry.displayName)
                        .font(.subheadline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("\(entry.score)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if entry.isCurrentPlayer {
                        Image(systemName: "person.circle")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    // MARK: - Actions
    
    private func playDailyRun() {
        guard currentDailyRun != nil else { return }
        
        // This would navigate to the game scene with the daily run configuration
        // For now, we'll just track the event
        AnalyticsManager.shared.trackEvent(.dailyRunStarted)
        
        // In a real implementation, this would:
        // 1. Configure the game scene with the daily run parameters
        // 2. Navigate to the game scene
        // 3. Track completion and submit score when finished
        
        showAlert("Daily Run started! (This would launch the game with today's challenge)")
    }
    
    @MainActor
    private func loadDailyRunData() async {
        isLoading = true
        
        // Load current daily run
        dailyRunService.getCurrentDailyRun { result in
            switch result {
            case .success(let dailyRun):
                self.currentDailyRun = dailyRun
            case .failure(let error):
                self.showAlert("Failed to load daily run: \(error.localizedDescription)")
            }
        }
        
        // Load streak info
        dailyRunService.getStreakInfo { result in
            switch result {
            case .success(let streak):
                self.streakInfo = streak
            case .failure(let error):
                Logger.shared.error("Failed to load streak info", error: error, category: .game)
            }
        }
        
        // Check if completed today
        hasCompleted = dailyRunService.hasCompletedTodaysDailyRun()
        
        // Load leaderboard
        dailyRunService.getDailyRunLeaderboard { result in
            switch result {
            case .success(let entries):
                self.leaderboard = entries
            case .failure(let error):
                Logger.shared.error("Failed to load daily run leaderboard", error: error, category: .game)
            }
        }
        
        isLoading = false
    }
    
    private func showAlert(_ message: String) {
        errorMessage = message
        showingAlert = true
    }
}

// MARK: - Supporting Views

struct DailyRunLeaderboardView: View {
    let leaderboard: [DailyRunLeaderboardEntry]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(leaderboard, id: \.playerID) { entry in
                HStack {
                    Text("#\(entry.rank)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(width: 40, alignment: .leading)
                    
                    VStack(alignment: .leading) {
                        Text(entry.displayName)
                            .font(.subheadline)
                            .fontWeight(entry.isCurrentPlayer ? .bold : .regular)
                        
                        Text("Completed: \(entry.completionTime, style: .time)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(entry.score)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if entry.isCurrentPlayer {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 2)
                .background(entry.isCurrentPlayer ? Color.blue.opacity(0.1) : Color.clear)
                .cornerRadius(8)
            }
            .navigationTitle("Daily Run Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DailyRunHistoryView: View {
    @State private var history: [DailyRunResult] = []
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    
    private let dailyRunService: DailyRunServiceProtocol
    
    init() {
        do {
            self.dailyRunService = try DIContainer.shared.resolve(DailyRunServiceProtocol.self)
        } catch {
            fatalError("Failed to resolve DailyRunService: \(error)")
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading history...")
                } else if history.isEmpty {
                    VStack {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No daily runs completed yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Complete your first daily run to see your history here!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List(history, id: \.id) { result in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("Score: \(result.score)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                if let rank = result.rank {
                                    Text("#\(rank)")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Text("Distance: \(Int(result.distance))m • Coins: \(result.coinsCollected)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(result.completionTime, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("Daily Run History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadHistory()
            }
        }
    }
    
    private func loadHistory() {
        dailyRunService.getDailyRunHistory { result in
            switch result {
            case .success(let historyData):
                self.history = historyData
            case .failure(let error):
                Logger.shared.error("Failed to load daily run history", error: error, category: .game)
            }
            self.isLoading = false
        }
    }
}

// MARK: - Color Extensions

extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}