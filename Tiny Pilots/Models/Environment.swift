//
//  Environment.swift
//  Tiny Pilots
//
//  Created on 2025-03-01.
//

import SpriteKit

/// Represents a game environment with its specific characteristics and visual elements
final class GameEnvironment: SKNode {
    // MARK: - Types
    enum EnvironmentType: String, CaseIterable, Codable {
        case meadow = "Sunny Meadows"
        case alpine = "Alpine Heights"
        case coastal = "Coastal Breeze"
        case urban = "Urban Skyline"
        case desert = "Desert Canyon"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    // MARK: - Properties
    let type: EnvironmentType
    let size: CGSize
    
    // MARK: - Static Environment Configurations
    static func meadow(size: CGSize) -> GameEnvironment {
        return GameEnvironment(type: .meadow, size: size)
    }
    
    static func alpine(size: CGSize) -> GameEnvironment {
        return GameEnvironment(type: .alpine, size: size)
    }
    
    static func coastal(size: CGSize) -> GameEnvironment {
        return GameEnvironment(type: .coastal, size: size)
    }
    
    static func urban(size: CGSize) -> GameEnvironment {
        return GameEnvironment(type: .urban, size: size)
    }
    
    static func desert(size: CGSize) -> GameEnvironment {
        return GameEnvironment(type: .desert, size: size)
    }
    
    // MARK: - Initialization
    init(type: EnvironmentType, size: CGSize) {
        self.type = type
        self.size = size
        super.init()
        setupEnvironment()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupEnvironment() {
        // Setup environment based on type
        switch type {
        case .meadow:
            setupMeadowEnvironment()
        case .alpine:
            setupAlpineEnvironment()
        case .coastal:
            setupCoastalEnvironment()
        case .urban:
            setupUrbanEnvironment()
        case .desert:
            setupDesertEnvironment()
        }
    }
    
    private func setupMeadowEnvironment() {
        // Implementation for meadow environment
    }
    
    private func setupAlpineEnvironment() {
        // Implementation for alpine environment
    }
    
    private func setupCoastalEnvironment() {
        // Implementation for coastal environment
    }
    
    private func setupUrbanEnvironment() {
        // Implementation for urban environment
    }
    
    private func setupDesertEnvironment() {
        // Implementation for desert environment
    }
}

// MARK: - Supporting Types

/// Represents a parallax scrolling layer in the environment
struct ParallaxLayer: Codable {
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
enum ObstacleType: String, CaseIterable, Codable {
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
enum CollectibleType: String, CaseIterable, Codable {
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