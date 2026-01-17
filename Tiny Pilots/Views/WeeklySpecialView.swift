import SwiftUI

/// SwiftUI view for the Weekly Special feature
struct WeeklySpecialView: View {
    // MARK: - Properties
    
    // Environment to dismiss the view
    @SwiftUI.Environment(\.dismiss) private var dismiss: DismissAction
    
    // Weekly Special Service
    private let weeklySpecialService: WeeklySpecialServiceProtocol
    
    // Game ViewModel for starting games
    private let gameViewModel: GameViewModel
    
    // State variables
    @State private var isLoading = true
    @State private var weeklySpecials: [WeeklySpecial] = []
    @State private var selectedSpecialIndex = 0
    @State private var showLeaderboard = false
    @State private var errorMessage: String?
    @State private var animateElements = false
    
    // MARK: - Initialization
    
    init() {
        do {
            self.weeklySpecialService = try DIContainer.shared.resolve(WeeklySpecialServiceProtocol.self)
            self.gameViewModel = try ViewModelFactory.shared.createGameViewModel()
        } catch {
            fatalError("Failed to resolve dependencies: \(error)")
        }
    }
    
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
                    
                    Text("Loading Weekly Specials...")
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
                        loadWeeklySpecials()
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
            } else if !weeklySpecials.isEmpty {
                // Weekly special content
                VStack(spacing: 0) {
                    // Header with special selector
                    VStack(spacing: 10) {
                        Text("Weekly Special")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                            .opacity(animateElements ? 1 : 0)
                        
                        // Special selector
                        if weeklySpecials.count > 1 {
                            Picker("Select Special", selection: $selectedSpecialIndex) {
                                ForEach(0..<weeklySpecials.count, id: \.self) { index in
                                    Text(weeklySpecials[index].title)
                                        .tag(index)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                            .opacity(animateElements ? 1 : 0)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    // Course details
                    ScrollView {
                        VStack(spacing: 25) {
                            // Time remaining
                            VStack(spacing: 8) {
                                Text("Available Until")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Text(formatDate(weeklySpecials[selectedSpecialIndex].endDate))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                            .padding(.horizontal)
                            .opacity(animateElements ? 1 : 0)
                            
                            // Special details card
                            WeeklySpecialDetailsCard(weeklySpecial: weeklySpecials[selectedSpecialIndex])
                                .padding(.horizontal)
                                .opacity(animateElements ? 1 : 0)
                            
                            // Rewards card
                            WeeklySpecialRewardsCard(weeklySpecial: weeklySpecials[selectedSpecialIndex])
                                .padding(.horizontal)
                                .opacity(animateElements ? 1 : 0)
                            
                            // Leaderboard preview
                            LeaderboardPreviewCard()
                                .padding(.horizontal)
                                .opacity(animateElements ? 1 : 0)
                                .onTapGesture {
                                    showLeaderboard = true
                                }
                            
                            Spacer(minLength: 20)
                        }
                        .padding(.vertical, 10)
                    }
                    
                    // Action buttons
                    VStack(spacing: 15) {
                        // Play button
                        Button(action: {
                            startWeeklySpecial()
                        }) {
                            Text("Start Weekly Special")
                                .font(.system(size: 18, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.blue)
                                )
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        .opacity(animateElements ? 1 : 0)
                        .accessibilityHint("Start playing the selected weekly special course")
                        
                        // Share button
                        Button(action: {
                            shareWeeklySpecial()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16))
                                
                                Text("Share with Friends")
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
                        .padding(.horizontal)
                        .opacity(animateElements ? 1 : 0)
                        .accessibilityHint("Share this weekly special with friends")
                    }
                    .padding(.vertical, 20)
                }
                .sheet(isPresented: $showLeaderboard) {
                    // Leaderboard view would go here
                    Text("Weekly Special Leaderboard")
                        .font(.title)
                        .padding()
                }
            }
        }
        .navigationTitle("Weekly Special")
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
                    loadWeeklySpecials(forceRefresh: true)
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
                .disabled(isLoading)
                .accessibilityLabel("Refresh weekly specials")
            }
        }
        .onAppear {
            loadWeeklySpecials()
        }
    }
    
    // MARK: - Methods
    
    /// Load the weekly specials
    /// - Parameter forceRefresh: Whether to force a refresh
    private func loadWeeklySpecials(forceRefresh: Bool = false) {
        isLoading = true
        errorMessage = nil
        animateElements = false
        
        Task {
            do {
                let specials = try await weeklySpecialService.loadWeeklySpecials(forceRefresh: forceRefresh)
                
                await MainActor.run {
                    if !specials.isEmpty {
                        self.weeklySpecials = specials
                        self.selectedSpecialIndex = 0
                        
                        // Animate elements
                        withAnimation(.easeOut(duration: 0.5)) {
                            self.animateElements = true
                        }
                    } else {
                        self.errorMessage = "No weekly specials available at this time. Please check back later."
                    }
                    
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
                
                Logger.shared.error("Failed to load weekly specials", error: error, category: .network)
            }
        }
    }
    
    /// Start the selected weekly special
    private func startWeeklySpecial() {
        guard selectedSpecialIndex < weeklySpecials.count else { return }
        
        let selectedSpecial = weeklySpecials[selectedSpecialIndex]
        
        // Dismiss the view
        dismiss()
        
        // Start the game with the weekly special
        gameViewModel.startGame(mode: .weeklySpecial, challengeCode: nil, weeklySpecialID: selectedSpecial.id)
    }
    
    /// Share the weekly special with friends
    private func shareWeeklySpecial() {
        guard selectedSpecialIndex < weeklySpecials.count else { return }
        
        let selectedSpecial = weeklySpecials[selectedSpecialIndex]
        
        // Generate share code
        let shareCode = weeklySpecialService.generateShareCode(for: selectedSpecial)
        
        // Generate a share message
        let shareMessage = "Join me in this week's special challenge in Tiny Pilots: \(selectedSpecial.title)! Use code: \(shareCode)"
        
        // In a real app, this would use UIActivityViewController
        // For now, just copy to clipboard
        UIPasteboard.general.string = shareMessage
        
        // Show confirmation
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Announce for VoiceOver users
        AccessibilityManager.shared.announceMessage("Share message copied to clipboard")
    }
    
    /// Format a date for display
    /// - Parameter date: The date to format
    /// - Returns: Formatted date string
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

/// Card displaying weekly special details
struct WeeklySpecialDetailsCard: View {
    let weeklySpecial: WeeklySpecial
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Special Details")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Difficulty badge
                Text(weeklySpecial.difficulty.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(weeklySpecial.difficulty.color))
                    )
                    .foregroundColor(.white)
            }
            
            // Description
            Text(weeklySpecial.description)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Special info grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                // Environment
                InfoItem(
                    title: "Environment",
                    value: weeklySpecial.environment,
                    icon: "leaf.fill",
                    color: .green
                )
                
                // Wind
                InfoItem(
                    title: "Wind",
                    value: weeklySpecial.windCondition,
                    icon: "wind",
                    color: .blue
                )
                
                // Distance
                InfoItem(
                    title: "Target Distance",
                    value: "\(weeklySpecial.targetDistance)m",
                    icon: "ruler.fill",
                    color: .orange
                )
                
                // XP Reward
                InfoItem(
                    title: "XP Reward",
                    value: "\(weeklySpecial.xpReward) XP",
                    icon: "star.fill",
                    color: .yellow
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

/// Card displaying weekly special rewards information
struct WeeklySpecialRewardsCard: View {
    let weeklySpecial: WeeklySpecial
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Rewards")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                // XP reward
                VStack(spacing: 10) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.yellow)
                    
                    Text("\(weeklySpecial.xpReward)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("XP")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(UIColor.tertiarySystemBackground))
                )
                
                // Bonus items
                VStack(spacing: 10) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.purple)
                    
                    Text("\(weeklySpecial.rewards.bonusItems.count)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Bonus Items")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(UIColor.tertiarySystemBackground))
                )
            }
            
            // Show bonus items if available
            if !weeklySpecial.rewards.bonusItems.isEmpty {
                VStack(spacing: 10) {
                    Text("Featured Bonus Items")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ForEach(weeklySpecial.rewards.bonusItems.prefix(3), id: \.name) { item in
                        HStack {
                            Image(systemName: item.iconName)
                                .foregroundColor(Color(item.rarity.color))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Text(item.rarity.displayName)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.top, 10)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

/// Card displaying leaderboard preview
struct LeaderboardPreviewCard: View {
    @State private var leaderboardEntries: [WeeklySpecialLeaderboardEntry] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Leaderboard")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            
            if isLoading {
                // Loading placeholder
                ForEach(0..<3, id: \.self) { _ in
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 30, height: 20)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 100, height: 16)
                        
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 16)
                    }
                    .padding(.vertical, 5)
                }
            } else if leaderboardEntries.isEmpty {
                // Empty state
                VStack(spacing: 10) {
                    Image(systemName: "person.3")
                        .font(.system(size: 30))
                        .foregroundColor(.secondary)
                    
                    Text("No scores yet")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    
                    Text("Be the first to play!")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else {
                // Top players
                ForEach(Array(leaderboardEntries.prefix(3).enumerated()), id: \.element.id) { index, entry in
                    HStack {
                        // Rank
                        Text("\(entry.rank)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 30)
                        
                        // Medal for top 3
                        if index < 3 {
                            Image(systemName: "medal.fill")
                                .foregroundColor(index == 0 ? .yellow : index == 1 ? .gray : .brown)
                        }
                        
                        // Player name
                        Text(entry.displayName)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Score
                        Text("\(entry.score)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 5)
                    
                    if index < min(leaderboardEntries.count, 3) - 1 {
                        Divider()
                    }
                }
                
                // View more button
                Button(action: {}) {
                    Text("View Full Leaderboard")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.top, 5)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .onAppear {
            loadLeaderboard()
        }
    }
    
    private func loadLeaderboard() {
        // Simulate loading sample leaderboard data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.leaderboardEntries = [
                WeeklySpecialLeaderboardEntry(
                    playerID: "player1",
                    displayName: "SkyMaster",
                    score: 1850,
                    rank: 1,
                    completionTime: 142.5,
                    weeklySpecialId: "sample"
                ),
                WeeklySpecialLeaderboardEntry(
                    playerID: "player2",
                    displayName: "WindRider",
                    score: 1720,
                    rank: 2,
                    completionTime: 156.8,
                    weeklySpecialId: "sample"
                ),
                WeeklySpecialLeaderboardEntry(
                    playerID: "player3",
                    displayName: "CloudHopper",
                    score: 1650,
                    rank: 3,
                    completionTime: 163.2,
                    weeklySpecialId: "sample"
                )
            ]
            self.isLoading = false
        }
    }
}

/// Info item for course details
struct InfoItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
} 