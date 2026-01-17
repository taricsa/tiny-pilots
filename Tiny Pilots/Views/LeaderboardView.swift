import SwiftUI

/// SwiftUI view for displaying leaderboards
struct LeaderboardView: View {
    // MARK: - Properties
    
    // Environment to dismiss the view
    @SwiftUI.Environment(\.dismiss) private var dismiss: DismissAction
    
    // State variables
    @State private var isLoading = true
    @State private var leaderboardEntries: [LeaderboardEntry] = []
    @State private var selectedLeaderboardType: LeaderboardType = .weeklySpecial
    @State private var selectedTimeFrame: TimeFrame = .thisWeek
    @State private var playerRank: Int?
    @State private var errorMessage: String?
    @State private var animateElements = false
    @State private var showingFriendsList = false
    
    // Optional ID for specific weekly special
    var weeklySpecialID: String?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            if isLoading {
                // Loading state
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                    
                    Text("Loading Leaderboard...")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                }
            } else if let error = errorMessage {
                // Error state
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text(error)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        loadLeaderboard()
                    }) {
                        Text("Try Again")
                            .font(.system(size: 16, weight: .medium))
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue)
                            )
                            .foregroundColor(.white)
                    }
                    .padding(.top, 10)
                }
            } else {
                // Leaderboard content
                VStack(spacing: 0) {
                    // Leaderboard type selector
                    if weeklySpecialID == nil {
                        Picker("Leaderboard Type", selection: $selectedLeaderboardType) {
                            ForEach(LeaderboardType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .onChange(of: selectedLeaderboardType) { oldValue, newValue in
                            loadLeaderboard()
                        }
                    }
                    
                    // Time frame selector (only for certain leaderboard types)
                    if shouldShowTimeFrameSelector() {
                        Picker("Time Frame", selection: $selectedTimeFrame) {
                            ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                                Text(timeFrame.displayName).tag(timeFrame)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .onChange(of: selectedTimeFrame) { oldValue, newValue in
                            loadLeaderboard()
                        }
                    }
                    
                    // Player rank card
                    if let rank = playerRank {
                        PlayerRankCard(rank: rank, entries: leaderboardEntries)
                            .padding(.horizontal)
                            .padding(.top, 15)
                            .opacity(animateElements ? 1 : 0)
                    }
                    
                    // Leaderboard entries
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // Header
                            LeaderboardHeader()
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .background(Color(UIColor.secondarySystemBackground))
                                .opacity(animateElements ? 1 : 0)
                            
                            // Entries
                            ForEach(Array(leaderboardEntries.enumerated()), id: \.element.id) { index, entry in
                                LeaderboardRow(
                                    rank: index + 1,
                                    entry: entry,
                                    isCurrentPlayer: entry.isCurrentPlayer
                                )
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                .background(
                                    entry.isCurrentPlayer ?
                                    Color.blue.opacity(0.1) :
                                    (index % 2 == 0 ? Color(UIColor.systemBackground) : Color(UIColor.secondarySystemBackground))
                                )
                                .opacity(animateElements ? 1 : 0)
                            }
                            
                            // Empty state
                            if leaderboardEntries.isEmpty {
                                VStack(spacing: 20) {
                                    Image(systemName: "trophy")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    
                                    Text("No entries yet")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    Text("Be the first to set a score!")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 50)
                                .opacity(animateElements ? 1 : 0)
                            }
                        }
                    }
                    
                    // Action buttons
                    HStack(spacing: 15) {
                        // Friends button
                        Button(action: {
                            showingFriendsList = true
                        }) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 16))
                                
                                Text("Friends")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                            .foregroundColor(.blue)
                        }
                        
                        // Challenge button
                        Button(action: {
                            shareChallenge()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16))
                                
                                Text("Challenge")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue)
                            )
                            .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .opacity(animateElements ? 1 : 0)
                }
                .sheet(isPresented: $showingFriendsList) {
                    FriendsListView()
                }
            }
        }
        .navigationTitle(getNavigationTitle())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.blue)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    loadLeaderboard(forceRefresh: true)
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
                .disabled(isLoading)
                .accessibilityLabel("Refresh leaderboard")
            }
        }
        .onAppear {
            loadLeaderboard()
        }
    }
    
    // MARK: - Methods
    
    /// Load the leaderboard data
    /// - Parameter forceRefresh: Whether to force a refresh
    private func loadLeaderboard(forceRefresh: Bool = false) {
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // In a real app, this would fetch from Game Center or a server
            // For now, we'll generate mock data
            
            do {
                // Generate entries based on leaderboard type
                let entries = try self.generateMockLeaderboardEntries()
                self.leaderboardEntries = entries
                
                // Find player rank
                if let playerIndex = entries.firstIndex(where: { $0.isCurrentPlayer }) {
                    self.playerRank = playerIndex + 1
                } else {
                    self.playerRank = nil
                }
                
                // Animate elements
                withAnimation(.easeOut(duration: 0.5)) {
                    self.animateElements = true
                }
            } catch {
                self.errorMessage = "Failed to load leaderboard. Please check your connection and try again."
            }
            
            self.isLoading = false
        }
    }
    
    /// Generate mock leaderboard entries for testing
    /// - Returns: Array of leaderboard entries
    private func generateMockLeaderboardEntries() throws -> [LeaderboardEntry] {
        // In a real app, this would fetch from Game Center or a server
        
        var entries: [LeaderboardEntry] = []
        
        // Number of entries to generate
        let count = 20
        
        // Generate random entries
        for i in 0..<count {
            let isCurrentPlayer = i == 3 // Make the 4th entry the current player
            
            let entry = LeaderboardEntry(
                id: UUID().uuidString,
                playerName: isCurrentPlayer ? "You" : "Player\(i + 1)",
                score: Int.random(in: 500...2000),
                date: Date().addingTimeInterval(-Double(Int.random(in: 0...86400))),
                isCurrentPlayer: isCurrentPlayer
            )
            
            entries.append(entry)
        }
        
        // Sort by score (descending)
        entries.sort { $0.score > $1.score }
        
        return entries
    }
    
    /// Share a challenge with friends
    private func shareChallenge() {
        // In a real app, this would use UIActivityViewController
        // For now, just copy to clipboard
        
        let shareMessage: String
        
        if let weeklyID = weeklySpecialID {
            shareMessage = "Can you beat my score in this week's special challenge in Tiny Pilots? Use code: \(weeklyID)"
        } else {
            shareMessage = "Can you beat my score in Tiny Pilots? Check out the leaderboard!"
        }
        
        UIPasteboard.general.string = shareMessage
        
        // Show confirmation
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Announce for VoiceOver users
        AccessibilityManager.shared.announceMessage("Challenge copied to clipboard")
    }
    
    /// Get the navigation title based on the selected leaderboard type
    private func getNavigationTitle() -> String {
        if let _ = weeklySpecialID {
            return "Weekly Special Leaderboard"
        }
        
        return "Leaderboard"
    }
    
    /// Determine if the time frame selector should be shown
    private func shouldShowTimeFrameSelector() -> Bool {
        // Only show for certain leaderboard types
        switch selectedLeaderboardType {
        case .weeklySpecial, .dailyRun:
            return false
        case .distance, .airTime, .tricks:
            return true
        }
    }
}

// MARK: - Supporting Types

/// Types of leaderboards
enum LeaderboardType: String, CaseIterable {
    case weeklySpecial
    case dailyRun
    case distance
    case airTime
    case tricks
    
    var displayName: String {
        switch self {
        case .weeklySpecial: return "Weekly Special"
        case .dailyRun: return "Daily Run"
        case .distance: return "Distance"
        case .airTime: return "Air Time"
        case .tricks: return "Tricks"
        }
    }
}

/// Time frames for leaderboards
enum TimeFrame: String, CaseIterable {
    case today
    case thisWeek
    case allTime
    
    var displayName: String {
        switch self {
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .allTime: return "All Time"
        }
    }
}

/// Leaderboard entry model
struct LeaderboardEntry: Identifiable {
    let id: String
    let playerName: String
    let score: Int
    let date: Date
    let isCurrentPlayer: Bool
    
    var formattedScore: String {
        return "\(score)"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

/// Header for the leaderboard
struct LeaderboardHeader: View {
    var body: some View {
        HStack {
            Text("Rank")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)
            
            Text("Player")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Score")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .trailing)
        }
    }
}

/// Row for a leaderboard entry
struct LeaderboardRow: View {
    let rank: Int
    let entry: LeaderboardEntry
    let isCurrentPlayer: Bool
    
    var body: some View {
        HStack {
            // Rank
            HStack(spacing: 5) {
                if rank <= 3 {
                    Image(systemName: "medal.fill")
                        .foregroundColor(
                            rank == 1 ? .yellow :
                                rank == 2 ? .gray : .brown
                        )
                } else {
                    Text("\(rank)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isCurrentPlayer ? .blue : .primary)
                }
            }
            .frame(width: 50, alignment: .leading)
            
            // Player name
            Text(entry.playerName)
                .font(.system(size: 16, weight: isCurrentPlayer ? .bold : .regular))
                .foregroundColor(isCurrentPlayer ? .blue : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Score
            Text(entry.formattedScore)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isCurrentPlayer ? .blue : .primary)
                .frame(width: 80, alignment: .trailing)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rank \(rank), \(entry.playerName), Score \(entry.formattedScore)")
    }
}

/// Card showing the player's rank
struct PlayerRankCard: View {
    let rank: Int
    let entries: [LeaderboardEntry]
    
    var playerEntry: LeaderboardEntry? {
        entries.first { $0.isCurrentPlayer }
    }
    
    var body: some View {
        if let entry = playerEntry {
            HStack(spacing: 20) {
                // Rank
                VStack(spacing: 5) {
                    Text("Your Rank")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 5) {
                        if rank <= 3 {
                            Image(systemName: "medal.fill")
                                .font(.system(size: 24))
                                .foregroundColor(
                                    rank == 1 ? .yellow :
                                        rank == 2 ? .gray : .brown
                                )
                        } else {
                            Text("#\(rank)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    }
                }
                .frame(width: 80)
                
                Divider()
                    .frame(height: 40)
                
                // Score
                VStack(spacing: 5) {
                    Text("Your Score")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text(entry.formattedScore)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 40)
                
                // Top player difference
                if rank > 1, let topEntry = entries.first {
                    let difference = topEntry.score - entry.score
                    
                    VStack(spacing: 5) {
                        Text("To #1")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text("+\(difference)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    .frame(width: 80)
                } else {
                    VStack(spacing: 5) {
                        Text("Status")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text("Top Player!")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.green)
                    }
                    .frame(width: 80)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
    }
}

/// View for displaying friends list
struct FriendsListView: View {
    @SwiftUI.Environment(\.dismiss) private var dismiss: DismissAction
    
    // Mock friends data
    let friends = [
        (name: "Friend1", status: "Online", lastPlayed: "2 hours ago"),
        (name: "Friend2", status: "Offline", lastPlayed: "Yesterday"),
        (name: "Friend3", status: "Playing", lastPlayed: "Now")
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(0..<friends.count, id: \.self) { index in
                    HStack {
                        // Avatar
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(String(friends[index].name.prefix(1)))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.blue)
                            )
                        
                        // Info
                        VStack(alignment: .leading, spacing: 5) {
                            Text(friends[index].name)
                                .font(.system(size: 16, weight: .medium))
                            
                            HStack {
                                Circle()
                                    .fill(friends[index].status == "Offline" ? Color.gray : (friends[index].status == "Playing" ? Color.green : Color.blue))
                                    .frame(width: 8, height: 8)
                                
                                Text("\(friends[index].status) • \(friends[index].lastPlayed)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Challenge button
                        Button(action: {}) {
                            Text("Challenge")
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.blue)
                                )
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Close")
                            .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

// MARK: - LeaderboardDetailView

/// Detail view for a specific leaderboard
struct LeaderboardDetailView: View {
    // MARK: - Properties
    
    // Environment object to access game state
    @EnvironmentObject var gameState: GameStateManager
    
    // Environment to dismiss the view
    @SwiftUI.Environment(\.dismiss) private var dismiss: DismissAction
    
    // Leaderboard ID
    var leaderboardID: String
    
    // MARK: - Body
    
    var body: some View {
        Text("Leaderboard Detail: \(leaderboardID)")
            .padding()
    }
} 