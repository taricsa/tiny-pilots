import Foundation
import SwiftData

/// Manager class for SwiftData configuration and operations
class SwiftDataManager {
    /// Shared instance for singleton access
    static let shared = SwiftDataManager()
    
    /// The SwiftData model container
    private(set) var container: ModelContainer
    
    /// The main model context
    @MainActor
    var mainContext: ModelContext {
        return container.mainContext
    }
    
    /// Private initializer to enforce singleton pattern
    private init() {
        do {
            // Configure the model container with all SwiftData models
            let schema = Schema([
                PlayerData.self,
                GameResult.self,
                Achievement.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            // Set up initial data if needed - defer to main actor
            Task { @MainActor in
                setupInitialData()
            }
            
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }
    
    /// Set up initial data for new installations
    @MainActor
    private func setupInitialData() {
        let context = mainContext
        
        // Check if we already have a player
        let playerFetch = FetchDescriptor<PlayerData>()
        
        do {
            let existingPlayers = try context.fetch(playerFetch)
            
            if existingPlayers.isEmpty {
                // Create initial player data
                let newPlayer = PlayerData()
                context.insert(newPlayer)
                
                // Create initial achievements
                createInitialAchievements(for: newPlayer, in: context)
                
                try context.save()
                print("Created initial player data and achievements")
            }
        } catch {
            print("Error setting up initial data: \(error)")
        }
    }
    
    /// Create initial achievements for a new player
    private func createInitialAchievements(for player: PlayerData, in context: ModelContext) {
        let initialAchievements = [
            Achievement(
                id: "first_flight",
                title: "First Flight",
                description: "Complete your first flight",
                targetValue: 1,
                category: "general",
                iconName: "airplane",
                rewardXP: 25
            ),
            Achievement(
                id: "distance_1000",
                title: "Sky Explorer",
                description: "Travel 1000 units in a single flight",
                targetValue: 1000,
                category: "distance",
                iconName: "map",
                rewardXP: 50
            ),
            Achievement(
                id: "distance_5000",
                title: "Long Distance Pilot",
                description: "Travel 5000 units in a single flight",
                targetValue: 5000,
                category: "distance",
                iconName: "globe",
                rewardXP: 100
            ),
            Achievement(
                id: "distance_10000",
                title: "Master Navigator",
                description: "Travel 10000 units in a single flight",
                targetValue: 10000,
                category: "distance",
                iconName: "star",
                rewardXP: 200
            ),
            Achievement(
                id: "daily_streak_3",
                title: "Consistent Flyer",
                description: "Complete daily runs for 3 consecutive days",
                targetValue: 3,
                category: "streak",
                iconName: "calendar",
                rewardXP: 75
            ),
            Achievement(
                id: "daily_streak_7",
                title: "Weekly Warrior",
                description: "Complete daily runs for 7 consecutive days",
                targetValue: 7,
                category: "streak",
                iconName: "flame",
                rewardXP: 150
            ),
            Achievement(
                id: "daily_streak_30",
                title: "Monthly Master",
                description: "Complete daily runs for 30 consecutive days",
                targetValue: 30,
                category: "streak",
                iconName: "crown",
                rewardXP: 500
            ),
            Achievement(
                id: "flight_time_1_hour",
                title: "Time in the Sky",
                description: "Accumulate 1 hour of total flight time",
                targetValue: 3600, // 1 hour in seconds
                category: "time",
                iconName: "clock",
                rewardXP: 100
            ),
            Achievement(
                id: "all_airplanes",
                title: "Collector",
                description: "Unlock all airplane types",
                targetValue: 5, // Assuming 5 airplane types
                category: "collection",
                iconName: "collection",
                rewardXP: 200
            ),
            Achievement(
                id: "all_environments",
                title: "World Explorer",
                description: "Unlock all environments",
                targetValue: 5, // Assuming 5 environments
                category: "collection",
                iconName: "mountain",
                rewardXP: 150
            ),
            Achievement(
                id: "first_challenge",
                title: "Challenge Accepted",
                description: "Complete your first challenge",
                targetValue: 1,
                category: "challenge",
                iconName: "target",
                rewardXP: 50
            ),
            Achievement(
                id: "challenges_10",
                title: "Challenge Master",
                description: "Complete 10 challenges",
                targetValue: 10,
                category: "challenge",
                iconName: "medal",
                rewardXP: 200
            )
        ]
        
        for achievement in initialAchievements {
            achievement.player = player
            context.insert(achievement)
        }
    }
    
    /// Get the current player data
    @MainActor
    func getCurrentPlayer() -> PlayerData? {
        let context = mainContext
        let fetchDescriptor = FetchDescriptor<PlayerData>()
        
        do {
            let players = try context.fetch(fetchDescriptor)
            return players.first
        } catch {
            print("Error fetching player data: \(error)")
            return nil
        }
    }
    
    /// Save the current context
    @MainActor
    func save() {
        do {
            try mainContext.save()
        } catch {
            print("Error saving SwiftData context: \(error)")
        }
    }
    
    /// Create a new background context for background operations
    func newBackgroundContext() -> ModelContext {
        return ModelContext(container)
    }
    
    /// Perform a background task with a separate context
    func performBackgroundTask(_ task: @escaping (ModelContext) -> Void) {
        let backgroundContext = newBackgroundContext()
        
        Task {
            await Task.detached {
                task(backgroundContext)
                
                do {
                    try backgroundContext.save()
                } catch {
                    print("Error saving background context: \(error)")
                }
            }.value
        }
    }
}