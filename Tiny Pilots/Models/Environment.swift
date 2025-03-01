//
//  Environment.swift
//  Tiny Pilots
//
//  Created on 2025-03-01.
//

import SpriteKit

/// Represents a game environment with its unique properties and visual elements
class Environment {
    
    // MARK: - Types
    
    /// Defines the different types of environments available in the game
    enum EnvironmentType: Int, CaseIterable {
        case meadow = 0
        case mountains = 1
        case beach = 2
        case city = 3
        case canyon = 4
        
        /// The name of the environment for display
        var displayName: String {
            switch self {
            case .meadow: return "Sunny Meadows"
            case .mountains: return "Alpine Heights"
            case .beach: return "Coastal Breeze"
            case .city: return "Urban Skyline"
            case .canyon: return "Desert Canyon"
            }
        }
        
        /// The level required to unlock this environment
        var unlockLevel: Int {
            return GameConfig.Environments.environmentUnlockLevels[self.rawValue]
        }
        
        /// Whether this environment is unlocked for the current player
        var isUnlocked: Bool {
            return GameManager.shared.playerData.level >= unlockLevel
        }
    }
    
    /// Defines the weather conditions for an environment
    enum WeatherCondition {
        case clear
        case lightWind
        case strongWind
        case variable
        
        /// Get a random wind strength based on the weather condition
        var windStrengthRange: ClosedRange<CGFloat> {
            switch self {
            case .clear: return 0.0...10.0
            case .lightWind: return 10.0...25.0
            case .strongWind: return 25.0...50.0
            case .variable: return 0.0...50.0
            }
        }
    }
    
    // MARK: - Properties
    
    /// The type of environment
    let type: EnvironmentType
    
    /// The current weather condition in this environment
    var weatherCondition: WeatherCondition
    
    /// The background color for the sky
    var skyColor: SKColor
    
    /// The color of the ground
    var groundColor: SKColor
    
    /// The texture to use for the ground
    var groundTexture: SKTexture?
    
    /// The texture to use for the background
    var backgroundTexture: SKTexture?
    
    /// The parallax layers for this environment
    var parallaxLayers: [ParallaxLayer] = []
    
    /// The obstacle types available in this environment
    var obstacleTypes: [ObstacleType] = []
    
    /// The collectible types available in this environment
    var collectibleTypes: [CollectibleType] = []
    
    /// The ambient sound for this environment
    var ambientSound: String?
    
    // MARK: - Initialization
    
    /// Initialize a new environment with the specified type
    init(type: EnvironmentType) {
        self.type = type
        
        // Set default weather condition
        self.weatherCondition = .clear
        
        // Set default colors
        self.skyColor = .blue
        self.groundColor = .green
        
        // Configure environment based on type
        configureEnvironment()
    }
    
    // MARK: - Configuration
    
    /// Configure the environment based on its type
    private func configureEnvironment() {
        switch type {
        case .meadow:
            configureMeadowEnvironment()
        case .mountains:
            configureMountainEnvironment()
        case .beach:
            configureBeachEnvironment()
        case .city:
            configureCityEnvironment()
        case .canyon:
            configureCanyonEnvironment()
        }
    }
    
    /// Configure the meadow environment
    private func configureMeadowEnvironment() {
        // Set weather condition
        weatherCondition = .lightWind
        
        // Set colors
        skyColor = SKColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 1.0)
        groundColor = SKColor(red: 0.3, green: 0.8, blue: 0.2, alpha: 1.0)
        
        // Set textures
        groundTexture = SKTexture(imageNamed: "grass_texture")
        backgroundTexture = SKTexture(imageNamed: "meadow_background")
        
        // Set parallax layers
        parallaxLayers = [
            ParallaxLayer(textureName: "clouds", scrollSpeed: 0.1, zPosition: -9),
            ParallaxLayer(textureName: "distant_hills", scrollSpeed: 0.3, zPosition: -8),
            ParallaxLayer(textureName: "trees", scrollSpeed: 0.5, zPosition: -7)
        ]
        
        // Set obstacle types
        obstacleTypes = [
            ObstacleType.tree,
            ObstacleType.rock,
            ObstacleType.fence
        ]
        
        // Set collectible types
        collectibleTypes = [
            CollectibleType.star,
            CollectibleType.coin
        ]
        
        // Set ambient sound
        ambientSound = "meadow_ambient"
    }
    
    /// Configure the mountain environment
    private func configureMountainEnvironment() {
        // Set weather condition
        weatherCondition = .strongWind
        
        // Set colors
        skyColor = SKColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1.0)
        groundColor = SKColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        
        // Set textures
        groundTexture = SKTexture(imageNamed: "mountain_texture")
        backgroundTexture = SKTexture(imageNamed: "mountain_background")
        
        // Set parallax layers
        parallaxLayers = [
            ParallaxLayer(textureName: "clouds", scrollSpeed: 0.1, zPosition: -9),
            ParallaxLayer(textureName: "distant_mountains", scrollSpeed: 0.2, zPosition: -8),
            ParallaxLayer(textureName: "mountain_ridge", scrollSpeed: 0.4, zPosition: -7)
        ]
        
        // Set obstacle types
        obstacleTypes = [
            ObstacleType.mountain,
            ObstacleType.rock,
            ObstacleType.snowdrift
        ]
        
        // Set collectible types
        collectibleTypes = [
            CollectibleType.star,
            CollectibleType.gem
        ]
        
        // Set ambient sound
        ambientSound = "mountain_ambient"
    }
    
    /// Configure the beach environment
    private func configureBeachEnvironment() {
        // Set weather condition
        weatherCondition = .variable
        
        // Set colors
        skyColor = SKColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
        groundColor = SKColor(red: 0.9, green: 0.8, blue: 0.6, alpha: 1.0)
        
        // Set textures
        groundTexture = SKTexture(imageNamed: "sand_texture")
        backgroundTexture = SKTexture(imageNamed: "beach_background")
        
        // Set parallax layers
        parallaxLayers = [
            ParallaxLayer(textureName: "clouds", scrollSpeed: 0.1, zPosition: -9),
            ParallaxLayer(textureName: "ocean", scrollSpeed: 0.2, zPosition: -8),
            ParallaxLayer(textureName: "palm_trees", scrollSpeed: 0.5, zPosition: -7)
        ]
        
        // Set obstacle types
        obstacleTypes = [
            ObstacleType.palmTree,
            ObstacleType.umbrella,
            ObstacleType.sandcastle
        ]
        
        // Set collectible types
        collectibleTypes = [
            CollectibleType.star,
            CollectibleType.shell
        ]
        
        // Set ambient sound
        ambientSound = "beach_ambient"
    }
    
    /// Configure the city environment
    private func configureCityEnvironment() {
        // Set weather condition
        weatherCondition = .variable
        
        // Set colors
        skyColor = SKColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1.0)
        groundColor = SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        
        // Set textures
        groundTexture = SKTexture(imageNamed: "concrete_texture")
        backgroundTexture = SKTexture(imageNamed: "city_background")
        
        // Set parallax layers
        parallaxLayers = [
            ParallaxLayer(textureName: "clouds", scrollSpeed: 0.1, zPosition: -9),
            ParallaxLayer(textureName: "distant_buildings", scrollSpeed: 0.3, zPosition: -8),
            ParallaxLayer(textureName: "skyscrapers", scrollSpeed: 0.5, zPosition: -7)
        ]
        
        // Set obstacle types
        obstacleTypes = [
            ObstacleType.building,
            ObstacleType.antenna,
            ObstacleType.billboard
        ]
        
        // Set collectible types
        collectibleTypes = [
            CollectibleType.star,
            CollectibleType.coin
        ]
        
        // Set ambient sound
        ambientSound = "city_ambient"
    }
    
    /// Configure the canyon environment
    private func configureCanyonEnvironment() {
        // Set weather condition
        weatherCondition = .strongWind
        
        // Set colors
        skyColor = SKColor(red: 0.8, green: 0.7, blue: 0.5, alpha: 1.0)
        groundColor = SKColor(red: 0.8, green: 0.5, blue: 0.3, alpha: 1.0)
        
        // Set textures
        groundTexture = SKTexture(imageNamed: "canyon_texture")
        backgroundTexture = SKTexture(imageNamed: "canyon_background")
        
        // Set parallax layers
        parallaxLayers = [
            ParallaxLayer(textureName: "clouds", scrollSpeed: 0.1, zPosition: -9),
            ParallaxLayer(textureName: "distant_mesas", scrollSpeed: 0.2, zPosition: -8),
            ParallaxLayer(textureName: "canyon_walls", scrollSpeed: 0.4, zPosition: -7)
        ]
        
        // Set obstacle types
        obstacleTypes = [
            ObstacleType.mesa,
            ObstacleType.cactus,
            ObstacleType.rock
        ]
        
        // Set collectible types
        collectibleTypes = [
            CollectibleType.star,
            CollectibleType.gem
        ]
        
        // Set ambient sound
        ambientSound = "canyon_ambient"
    }
    
    // MARK: - Helper Methods
    
    /// Get a random wind direction and strength based on the environment's weather condition
    func getRandomWind() -> (direction: CGFloat, strength: CGFloat) {
        let direction = CGFloat.random(in: 0...360)
        let strength = CGFloat.random(in: weatherCondition.windStrengthRange)
        return (direction, strength)
    }
    
    /// Get a random obstacle type for this environment
    func getRandomObstacleType() -> ObstacleType {
        return obstacleTypes.randomElement() ?? .rock
    }
    
    /// Get a random collectible type for this environment
    func getRandomCollectibleType() -> CollectibleType {
        return collectibleTypes.randomElement() ?? .star
    }
}

// MARK: - Supporting Types

/// Represents a parallax scrolling layer in the environment
struct ParallaxLayer {
    let textureName: String
    let scrollSpeed: CGFloat
    let zPosition: CGFloat
    
    func createNode(size: CGSize) -> SKNode {
        let texture = SKTexture(imageNamed: textureName)
        let node = SKSpriteNode(texture: texture, size: size)
        node.zPosition = zPosition
        return node
    }
}

/// Defines the different types of obstacles in the game
enum ObstacleType {
    case tree
    case rock
    case fence
    case mountain
    case snowdrift
    case palmTree
    case umbrella
    case sandcastle
    case building
    case antenna
    case billboard
    case mesa
    case cactus
    
    /// Get the texture name for this obstacle type
    var textureName: String {
        switch self {
        case .tree: return "obstacle_tree"
        case .rock: return "obstacle_rock"
        case .fence: return "obstacle_fence"
        case .mountain: return "obstacle_mountain"
        case .snowdrift: return "obstacle_snowdrift"
        case .palmTree: return "obstacle_palm_tree"
        case .umbrella: return "obstacle_umbrella"
        case .sandcastle: return "obstacle_sandcastle"
        case .building: return "obstacle_building"
        case .antenna: return "obstacle_antenna"
        case .billboard: return "obstacle_billboard"
        case .mesa: return "obstacle_mesa"
        case .cactus: return "obstacle_cactus"
        }
    }
    
    /// Get the size for this obstacle type
    var size: CGSize {
        switch self {
        case .tree: return CGSize(width: 80, height: 150)
        case .rock: return CGSize(width: 100, height: 80)
        case .fence: return CGSize(width: 150, height: 60)
        case .mountain: return CGSize(width: 200, height: 300)
        case .snowdrift: return CGSize(width: 150, height: 50)
        case .palmTree: return CGSize(width: 100, height: 200)
        case .umbrella: return CGSize(width: 120, height: 120)
        case .sandcastle: return CGSize(width: 80, height: 60)
        case .building: return CGSize(width: 150, height: 400)
        case .antenna: return CGSize(width: 30, height: 200)
        case .billboard: return CGSize(width: 150, height: 100)
        case .mesa: return CGSize(width: 300, height: 200)
        case .cactus: return CGSize(width: 60, height: 120)
        }
    }
}

/// Defines the different types of collectibles in the game
enum CollectibleType {
    case star
    case coin
    case gem
    case shell
    
    /// Get the texture name for this collectible type
    var textureName: String {
        switch self {
        case .star: return "collectible_star"
        case .coin: return "collectible_coin"
        case .gem: return "collectible_gem"
        case .shell: return "collectible_shell"
        }
    }
    
    /// Get the size for this collectible type
    var size: CGSize {
        switch self {
        case .star: return CGSize(width: 40, height: 40)
        case .coin: return CGSize(width: 30, height: 30)
        case .gem: return CGSize(width: 35, height: 35)
        case .shell: return CGSize(width: 40, height: 35)
        }
    }
    
    /// Get the point value for this collectible type
    var pointValue: Int {
        switch self {
        case .star: return 10
        case .coin: return 5
        case .gem: return 20
        case .shell: return 15
        }
    }
} 