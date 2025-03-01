//
//  PaperAirplane.swift
//  Tiny Pilots
//
//  Created on 2025-03-01.
//

import SpriteKit
import GameplayKit

/// A class representing a paper airplane with physical properties and visual appearance
class PaperAirplane {
    
    // MARK: - Enums
    
    /// Different fold types that affect flight characteristics
    enum FoldType: String, CaseIterable {
        case basic = "Basic"
        case dart = "Dart"
        case glider = "Glider"
        case stunt = "Stunt"
        case fastFlyer = "Fast Flyer"
        
        /// Returns physics properties associated with this fold type
        var physicsProperties: PhysicsProperties {
            switch self {
            case .basic:
                return PhysicsProperties(
                    mass: 0.2,
                    drag: 0.15,
                    lift: 0.1,
                    angularDamping: 0.8,
                    linearDamping: 0.1
                )
            case .dart:
                return PhysicsProperties(
                    mass: 0.15,
                    drag: 0.1,
                    lift: 0.05,
                    angularDamping: 0.7,
                    linearDamping: 0.08
                )
            case .glider:
                return PhysicsProperties(
                    mass: 0.25,
                    drag: 0.2,
                    lift: 0.3,
                    angularDamping: 0.9,
                    linearDamping: 0.15
                )
            case .stunt:
                return PhysicsProperties(
                    mass: 0.18,
                    drag: 0.08,
                    lift: 0.15,
                    angularDamping: 0.5,
                    linearDamping: 0.12
                )
            case .fastFlyer:
                return PhysicsProperties(
                    mass: 0.12,
                    drag: 0.05,
                    lift: 0.08,
                    angularDamping: 0.6,
                    linearDamping: 0.06
                )
            }
        }
        
        /// Returns the unlockable level for this fold type
        var unlockLevel: Int {
            switch self {
            case .basic: return 1
            case .dart: return 3
            case .glider: return 7
            case .stunt: return 12
            case .fastFlyer: return 18
            }
        }
    }
    
    /// Different design types that affect visual appearance
    enum DesignType: String, CaseIterable {
        case plain = "Plain"
        case dotted = "Dotted"
        case striped = "Striped"
        case checkered = "Checkered"
        case floral = "Floral"
        case geometric = "Geometric"
        case galaxy = "Galaxy"
        case ocean = "Ocean"
        case forest = "Forest"
        case fire = "Fire"
        case rainbow = "Rainbow"
        case metallic = "Metallic"
        case neon = "Neon"
        case vintage = "Vintage"
        case futuristic = "Futuristic"
        
        /// Returns the texture name for this design
        var textureName: String {
            return "airplane_\(self.rawValue.lowercased())"
        }
        
        /// Returns the unlockable level for this design
        var unlockLevel: Int {
            // Designs are unlocked according to the levels specified in GameConfig
            let index = DesignType.allCases.firstIndex(of: self) ?? 0
            return GameConfig.AirplaneDesigns.designUnlockLevels[min(index, GameConfig.AirplaneDesigns.designUnlockLevels.count - 1)]
        }
    }
    
    // MARK: - Structs
    
    /// Physics properties for the airplane
    struct PhysicsProperties {
        let mass: CGFloat
        let drag: CGFloat
        let lift: CGFloat
        let angularDamping: CGFloat
        let linearDamping: CGFloat
    }
    
    // MARK: - Properties
    
    /// The airplane's sprite node
    var node: SKSpriteNode
    
    /// The airplane's fold type
    var foldType: FoldType
    
    /// The airplane's design type
    var designType: DesignType
    
    /// The current speed of the airplane
    var speed: CGFloat = 0
    
    /// The maximum speed this airplane can achieve
    var maxSpeed: CGFloat {
        return GameConfig.Physics.maxSpeed * (1.0 - foldType.physicsProperties.drag * 2)
    }
    
    /// The minimum speed this airplane needs to stay airborne
    var minSpeed: CGFloat {
        return GameConfig.Physics.minSpeed
    }
    
    // MARK: - Initialization
    
    /// Initialize a paper airplane with the specified fold and design types
    init(foldType: FoldType, designType: DesignType) {
        self.foldType = foldType
        self.designType = designType
        
        // Create sprite node
        self.node = SKSpriteNode(imageNamed: designType.textureName)
        
        // Set default properties
        self.node.name = "paperAirplane"
        self.node.zPosition = 10
        
        // Set up physics body
        setupPhysicsBody()
    }
    
    /// Convenience initializer for a basic airplane
    convenience init() {
        self.init(foldType: .basic, designType: .plain)
    }
    
    // MARK: - Setup
    
    /// Set up the physics body for the airplane
    private func setupPhysicsBody() {
        let physicsProperties = foldType.physicsProperties
        
        // Create physics body from texture
        let body = SKPhysicsBody(texture: node.texture!, size: node.size)
        node.physicsBody = body
        
        // Set physics properties
        body.mass = physicsProperties.mass
        body.linearDamping = physicsProperties.linearDamping
        body.angularDamping = physicsProperties.angularDamping
        body.allowsRotation = true
        body.affectedByGravity = true
        
        // Set collision properties
        body.categoryBitMask = 1
        body.collisionBitMask = 2 // Collide with obstacles
        body.contactTestBitMask = 2 | 4 // Test contact with obstacles and collectibles
    }
    
    // MARK: - Flight Control
    
    /// Apply force to the airplane in the direction it's facing
    func applyThrust(amount: CGFloat) {
        let direction = CGVector(dx: cos(node.zRotation), dy: sin(node.zRotation))
        let thrust = CGVector(dx: direction.dx * amount, dy: direction.dy * amount)
        
        node.physicsBody?.applyForce(thrust)
        
        // Limit speed
        limitSpeed()
    }
    
    /// Apply lift based on current speed and lift coefficient
    func applyLift() {
        let liftCoefficient = foldType.physicsProperties.lift
        let currentVelocity = node.physicsBody!.velocity
        let speedFactor = min(1.0, sqrt(pow(currentVelocity.dx, 2) + pow(currentVelocity.dy, 2)) / 200.0)
        
        // Lift is perpendicular to direction of travel
        let liftDirection = CGVector(dx: -currentVelocity.dy, dy: currentVelocity.dx).normalized()
        let liftForce = CGVector(dx: liftDirection.dx * liftCoefficient * speedFactor * 10,
                                dy: liftDirection.dy * liftCoefficient * speedFactor * 10)
        
        node.physicsBody?.applyForce(liftForce)
    }
    
    /// Limit the airplane's speed to its maximum value
    private func limitSpeed() {
        guard let physicsBody = node.physicsBody else { return }
        
        let velocity = physicsBody.velocity
        let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        
        if speed > maxSpeed {
            let scale = maxSpeed / speed
            physicsBody.velocity = CGVector(dx: velocity.dx * scale, dy: velocity.dy * scale)
        }
    }
    
    /// Apply rotation to bank the airplane
    func bank(amount: CGFloat) {
        node.physicsBody?.applyTorque(amount)
    }
    
    /// Handle impact with obstacle
    func handleImpact() {
        // Slow down the airplane
        if let velocity = node.physicsBody?.velocity {
            node.physicsBody?.velocity = CGVector(
                dx: velocity.dx * 0.7,
                dy: velocity.dy * 0.7
            )
        }
        
        // Visual feedback
        let fadeAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])
        
        node.run(SKAction.repeat(fadeAction, count: 3))
    }
}

// MARK: - Extension for CGVector
extension CGVector {
    /// Returns a normalized version of this vector
    func normalized() -> CGVector {
        let length = sqrt(dx * dx + dy * dy)
        if length == 0 {
            return CGVector(dx: 0, dy: 0)
        }
        return CGVector(dx: dx / length, dy: dy / length)
    }
} 