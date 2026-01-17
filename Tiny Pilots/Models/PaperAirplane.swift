//
//  PaperAirplane.swift
//  Tiny Pilots
//
//  Created on 2025-03-01.
//

import SpriteKit
import GameplayKit

/// Represents a paper airplane that the player controls
/// This class now focuses only on airplane configuration and visual representation
/// Physics behavior is handled by PhysicsService
class PaperAirplane: SKSpriteNode {
    
    /// Types of paper airplanes
    enum AirplaneType: String, CaseIterable, Codable {
        case basic = "basic"
        case speedy = "speedy"
        case sturdy = "sturdy"
        case glider = "glider"
        
        /// Get the texture name for this airplane type
        var textureName: String {
            return "airplane_\(self.rawValue)"
        }
        
        /// Get the size for this airplane type
        var size: CGSize {
            switch self {
            case .basic:
                return CGSize(width: 60, height: 40)
            case .speedy:
                return CGSize(width: 70, height: 35)
            case .sturdy:
                return CGSize(width: 65, height: 45)
            case .glider:
                return CGSize(width: 75, height: 40)
            }
        }
        
        /// Get the mass for this airplane type
        var mass: CGFloat {
            switch self {
            case .basic:
                return 1.0
            case .speedy:
                return 0.8
            case .sturdy:
                return 1.5
            case .glider:
                return 0.7
            }
        }
        
        /// Get the linear damping for this airplane type
        var linearDamping: CGFloat {
            switch self {
            case .basic:
                return 0.5
            case .speedy:
                return 0.3
            case .sturdy:
                return 0.7
            case .glider:
                return 0.2
            }
        }
        
        /// Get the angular damping for this airplane type
        var angularDamping: CGFloat {
            switch self {
            case .basic:
                return 0.7
            case .speedy:
                return 0.5
            case .sturdy:
                return 0.9
            case .glider:
                return 0.4
            }
        }
    }
    
    /// Types of paper airplane folds
    enum FoldType: String, CaseIterable, Codable {
        case basic = "Basic"
        case dart = "Dart"
        case glider = "Glider"
        case stunt = "Stunt"
        case fighter = "Fighter"
        
        /// Level required to unlock this fold type
        var unlockLevel: Int {
            switch self {
            case .basic: return 1
            case .dart: return 3
            case .glider: return 5
            case .stunt: return 8
            case .fighter: return 12
            }
        }
        
        /// Get the physics properties for this fold type
        var physicsMultiplier: (lift: CGFloat, drag: CGFloat, turnRate: CGFloat, mass: CGFloat) {
            switch self {
            case .basic: return (lift: 1.0, drag: 1.0, turnRate: 1.0, mass: 1.0)
            case .dart: return (lift: 0.8, drag: 0.7, turnRate: 1.2, mass: 0.9)
            case .glider: return (lift: 1.3, drag: 1.1, turnRate: 0.8, mass: 0.8)
            case .stunt: return (lift: 1.1, drag: 0.9, turnRate: 1.5, mass: 1.1)
            case .fighter: return (lift: 1.2, drag: 0.8, turnRate: 1.3, mass: 1.2)
            }
        }
    }
    
    /// Types of paper airplane designs
    enum DesignType: String, CaseIterable, Codable {
        case plain = "Plain"
        case striped = "Striped"
        case dotted = "Dotted"
        case camouflage = "Camo"
        case flames = "Flames"
        case rainbow = "Rainbow"
        
        /// Level required to unlock this design
        var unlockLevel: Int {
            switch self {
            case .plain: return 1
            case .striped: return 2
            case .dotted: return 4
            case .camouflage: return 7
            case .flames: return 10
            case .rainbow: return 15
            }
        }
        
        /// Get the texture name for this design
        var textureName: String {
            return "airplane_design_\(self.rawValue.lowercased())"
        }
    }
    
    // MARK: - Properties
    
    /// The type of this airplane (immutable after creation)
    let type: AirplaneType
    
    /// The fold type of this airplane
    private(set) var fold: FoldType = .basic
    
    /// The design type of this airplane
    private(set) var design: DesignType = .plain
    
    /// Whether the airplane is currently flying (visual state only)
    private(set) var isFlying = false
    
    /// Current tilt angle for visual representation (updated by PhysicsService)
    private(set) var tiltAngle: CGFloat = 0.0
    
    // MARK: - Initialization
    
    /// Initialize with a specific airplane type
    init(type: AirplaneType, fold: FoldType = .basic, design: DesignType = .plain) {
        self.type = type
        self.fold = fold
        self.design = design
        
        // Use the paperplane image with fallback
        if let texture = SKTexture(imageNamed: "paperplane") as SKTexture? {
            super.init(texture: texture, color: .white, size: type.size)
        } else {
            // Fallback to white rectangle if image not found
            super.init(texture: nil, color: .white, size: type.size)
        }
        
        // Set up basic physics body (physics behavior handled by PhysicsService)
        setupPhysicsBody()
        
        // Set name for identification
        self.name = "airplane"
        
        // Set z-position to appear above background
        self.zPosition = 10
        
        // Apply design texture if available
        applyDesign()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Physics Body Setup
    
    /// Set up the basic physics body for this airplane
    /// Physics behavior is handled by PhysicsService
    private func setupPhysicsBody() {
        // Create a physics body based on the texture
        physicsBody = SKPhysicsBody(rectangleOf: size)
        
        // Configure basic physics properties (detailed physics handled by PhysicsService)
        physicsBody?.isDynamic = true
        physicsBody?.allowsRotation = true
        physicsBody?.affectedByGravity = true
        physicsBody?.restitution = 0.2
        physicsBody?.friction = 0.2
        
        // Set initial physics properties based on airplane configuration
        updatePhysicsProperties()
        
        // Set up collision detection
        physicsBody?.categoryBitMask = PhysicsCategory.airplane
        physicsBody?.contactTestBitMask = PhysicsCategory.obstacle | PhysicsCategory.collectible | PhysicsCategory.ground
        physicsBody?.collisionBitMask = PhysicsCategory.obstacle | PhysicsCategory.ground | PhysicsCategory.boundary
    }
    
    // MARK: - Configuration Methods
    
    /// Set the fold type and update physics properties
    func setFold(_ newFold: FoldType) {
        fold = newFold
        updatePhysicsProperties()
    }
    
    /// Set the design type and update visual appearance
    func setDesign(_ newDesign: DesignType) {
        design = newDesign
        applyDesign()
    }
    
    /// Update physics properties based on current airplane configuration
    /// This sets the base physics properties that PhysicsService will use
    private func updatePhysicsProperties() {
        guard let physicsBody = physicsBody else { return }
        
        let multiplier = fold.physicsMultiplier
        physicsBody.mass = type.mass * multiplier.mass
        physicsBody.linearDamping = type.linearDamping * (2.0 - multiplier.lift)
        physicsBody.angularDamping = type.angularDamping * (2.0 - multiplier.turnRate)
    }
    
    // MARK: - Physics Integration (Backward Compatibility)
    
    /// Apply forces to the airplane based on tilt input
    /// Note: This method now delegates to PhysicsService for actual physics calculations
    /// Kept for backward compatibility - PhysicsService should be used directly
    func applyForces(tiltX: CGFloat, tiltY: CGFloat) {
        // Update tilt angle for visual representation
        updateTiltAngle()
        
        // Physics calculations are now handled by PhysicsService
        // This method is kept for backward compatibility but should be called through PhysicsService
    }
    
    /// Update tilt angle based on current velocity (for visual representation)
    private func updateTiltAngle() {
        if let physicsBody = physicsBody {
            tiltAngle = atan2(physicsBody.velocity.dy, physicsBody.velocity.dx)
        }
    }
    
    // MARK: - Visual State Management
    
    /// Update the airplane's visual state based on its physics state
    /// This method handles visual representation only - physics is managed by PhysicsService
    func updateVisualState() {
        guard let physicsBody = physicsBody else { return }
        
        // Calculate speed for visual effects
        let speed = sqrt(physicsBody.velocity.dx * physicsBody.velocity.dx + 
                         physicsBody.velocity.dy * physicsBody.velocity.dy)
        
        // Update flying state for visual effects
        isFlying = speed > 50.0
        
        // Update tilt angle for visual representation
        updateTiltAngle()
        
        // Update rotation based on velocity direction
        let targetRotation = atan2(physicsBody.velocity.dy, physicsBody.velocity.dx)
        let rotationAction = SKAction.rotate(toAngle: targetRotation, duration: 0.1)
        run(rotationAction)
        
        // Add visual effects based on speed
        if isFlying {
            addTrailEffect()
        }
    }
    
    /// Add a trail effect to the airplane for visual feedback
    private func addTrailEffect() {
        // Create a small particle for the trail
        let trail = SKSpriteNode(color: .white, size: CGSize(width: 5, height: 5))
        trail.position = CGPoint(x: -size.width / 2, y: 0) // Position at the back of the airplane
        trail.alpha = 0.7
        trail.zPosition = -1 // Behind the airplane
        
        // Add to parent (not to the airplane itself)
        parent?.addChild(trail)
        
        // Fade and remove
        let fadeAction = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ])
        trail.run(fadeAction)
    }
    
    /// Reset the airplane to its initial state
    func reset() {
        // Reset physics state
        physicsBody?.velocity = CGVector.zero
        physicsBody?.angularVelocity = 0
        
        // Reset visual state
        removeAllActions()
        zRotation = 0
        isFlying = false
        tiltAngle = 0.0
    }
    
    /// Apply the current design to the airplane's visual appearance
    private func applyDesign() {
        // Attempt to load the design texture using safe loading
        // If texture exists, it would be applied here
        if let designTexture = SKTexture.safeTexture(imageNamed: design.textureName) {
            // Design texture found - apply it
            self.texture = designTexture
            self.colorBlendFactor = 0.0
            return
        }
        
        // Fallback: apply color tint based on the design
        // This ensures visual distinction even without texture assets
        colorBlendFactor = 0.3
        switch design {
        case .plain:
            color = .white
        case .striped:
            color = .blue
        case .dotted:
            color = .green
        case .camouflage:
            color = .brown
        case .flames:
            color = .red
        case .rainbow:
            color = .purple
        }
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
