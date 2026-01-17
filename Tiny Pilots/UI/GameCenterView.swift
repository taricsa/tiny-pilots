import SwiftUI
import GameKit

struct GameCenterView: View {
    @State private var showingLeaderboards = false
    @State private var showingAchievements = false
    @State private var showingChallengeInput = false
    @State private var challengeCode = ""
    @State private var isLoadingChallenge = false
    @State private var challengeError: String?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Services
    private let gameCenterService: GameCenterServiceProtocol
    private let challengeService: ChallengeServiceProtocol
    
    // Initialize with dependency injection
    init() {
        do {
            self.gameCenterService = try DIContainer.shared.resolve(GameCenterServiceProtocol.self)
            self.challengeService = try DIContainer.shared.resolve(ChallengeServiceProtocol.self)
        } catch {
            print("Failed to resolve services for GameCenterView: \(error)")
            // Fallback - this should not happen in production
            fatalError("Failed to initialize GameCenterView: \(error)")
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Game Center")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Authentication status
            if gameCenterService.isAuthenticated {
                if let playerName = gameCenterService.playerDisplayName {
                    Text("Welcome, \(playerName)!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Not signed in to Game Center")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
            
            // Leaderboards Button
            Button(action: {
                showLeaderboards()
            }) {
                HStack {
                    Image(systemName: "list.number")
                    Text("Leaderboards")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!gameCenterService.isAuthenticated)
            
            // Achievements Button
            Button(action: {
                showAchievements()
            }) {
                HStack {
                    Image(systemName: "trophy")
                    Text("Achievements")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!gameCenterService.isAuthenticated)
            
            // Challenge Section
            VStack(spacing: 15) {
                Text("Friend Challenges")
                    .font(.headline)
                
                // Generate Challenge Button
                Button(action: {
                    shareChallenge()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Challenge")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!gameCenterService.isAuthenticated)
                
                // Join Challenge Button
                Button(action: {
                    showingChallengeInput.toggle()
                }) {
                    HStack {
                        Image(systemName: "person.2")
                        Text("Join Challenge")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!gameCenterService.isAuthenticated)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)
        }
        .padding()
        .sheet(isPresented: $showingChallengeInput) {
            NavigationView {
                VStack(spacing: 20) {
                    TextField("Enter Challenge Code", text: $challengeCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    if let error = challengeError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    Button("Join Challenge") {
                        joinChallenge()
                    }
                    .disabled(challengeCode.isEmpty || isLoadingChallenge)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(challengeCode.isEmpty || isLoadingChallenge ? Color.gray : Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    if isLoadingChallenge {
                        ProgressView("Loading challenge...")
                            .padding()
                    }
                    
                    Spacer()
                }
                .navigationTitle("Join Challenge")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            showingChallengeInput = false
                            challengeCode = ""
                            challengeError = nil
                        }
                    }
                }
            }
        }
        .alert("Game Center", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Private Methods
    
    private func showLeaderboards() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            showAlert("Unable to show leaderboards")
            return
        }
        
        gameCenterService.showLeaderboards(from: rootViewController)
    }
    
    private func showAchievements() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            showAlert("Unable to show achievements")
            return
        }
        
        gameCenterService.showAchievements(from: rootViewController)
    }
    
    private func shareChallenge() {
        // Create a sample challenge for sharing
        let sampleCourseData = ChallengeData(
            environmentType: "sunny_meadows",
            obstacles: [
                ObstacleConfiguration(type: "tree", position: CGPoint(x: 100, y: 200)),
                ObstacleConfiguration(type: "building", position: CGPoint(x: 300, y: 150))
            ],
            collectibles: [
                CollectibleConfiguration(type: "star", position: CGPoint(x: 200, y: 100), value: 50)
            ],
            weatherConditions: WeatherConfiguration(windSpeed: 0.3, windDirection: 45),
            difficulty: .medium
        )
        
        let challenge = challengeService.createChallenge(
            title: "Friend Challenge",
            description: "A custom challenge to share with friends",
            courseData: sampleCourseData,
            createdBy: gameCenterService.playerDisplayName ?? "Player",
            targetScore: nil
        )
        
        let challengeCode = challengeService.generateChallengeCode(for: challenge)
        
        // Copy to clipboard
        UIPasteboard.general.string = challengeCode
        
        showAlert("Challenge code copied to clipboard!\nShare it with your friends.")
        
        print("Challenge shared with code: \(challengeCode)")
    }
    
    private func joinChallenge() {
        guard !challengeCode.isEmpty else { return }
        
        isLoadingChallenge = true
        challengeError = nil
        
        Task {
            do {
                let challenge = try await challengeService.loadChallenge(code: challengeCode)
                
                await MainActor.run {
                    isLoadingChallenge = false
                    showingChallengeInput = false
                    challengeCode = ""
                    
                    // Save the challenge locally
                    do {
                        try challengeService.saveChallenge(challenge)
                        showAlert("Challenge loaded successfully!\nTitle: \(challenge.title)\nDifficulty: \(challenge.courseData.difficulty.displayName)")
                        
                        print("Challenge joined successfully: \(challenge.title)")
                    } catch {
                        print("Failed to save challenge: \(error)")
                        showAlert("Challenge loaded but couldn't be saved locally.")
                    }
                }
            } catch {
                await MainActor.run {
                    isLoadingChallenge = false
                    challengeError = error.localizedDescription
                    
                    print("Failed to join challenge: \(error)")
                }
            }
        }
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
} 