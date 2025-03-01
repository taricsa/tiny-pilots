//
//  Obstacle.swift
//  Tiny Pilots
//
//  Created on 2025-03-01.
//

import SpriteKit

/// Represents an obstacle in the game environment
class Obstacle {
    
    // MARK: - Properties
    
    /// The node representing this obstacle in the scene
    let node: SKSpriteNode
    
    /// The type of obstacle
    let type: ObstacleType
    
    /// Whether the obstacle has been passed by the player
    var isPassed: Bool = false
    
    // MARK: - Initialization
    
    /// Initialize a new obstacle with the specified type
    init(type: ObstacleType) {
        self.type = type
        
        // Create the sprite node for this obstacle
        if let texture = SKTexture(imageNamed: type.textureName) {
            node = SKSpriteNode(texture: texture, size: type.size)
        } else {
            // Fallback to a colored rectangle if texture is not available
            node = SKSpriteNode(color: .brown, size: type.size)
        }
        
        // Set up physics body
        setupPhysicsBody()
        
        // Set the name for identification
        node.name = "obstacle_\(type)"
    }
    
    // MARK: - Setup
    
    /// Set up the physics body for this obstacle
    private func setupPhysicsBody() {
        // Create a physics body based on the obstacle type
        var physicsBody: SKPhysicsBody
        
        switch type {
        case .tree, .palmTree, .building, .antenna, .cactus:
            // Tall, narrow obstacles use a rectangle shape
            physicsBody = SKPhysicsBody(rectangleOf: node.size)
        case .rock, .mountain, .mesa:
            // Large, irregular obstacles use a slightly smaller rectangle to account for irregular shape
            let adjustedSize = CGSize(width: node.size.width * 0.8, height: node.size.height * 0.8)
            physicsBody = SKPhysicsBody(rectangleOf: adjustedSize)
        case .fence, .billboard:
            // Wide, thin obstacles
            physicsBody = SKPhysicsBody(rectangleOf: node.size)
        case .umbrella, .sandcastle, .snowdrift:
            // Smaller obstacles with more regular shapes
            physicsBody = SKPhysicsBody(rectangleOf: node.size)
        }
        
        // Configure physics body properties
        physicsBody.isDynamic = false
        physicsBody.categoryBitMask = 0x1 << 1 // Obstacle category
        physicsBody.collisionBitMask = 0x1 << 0 // Collide with airplane
        physicsBody.contactTestBitMask = 0x1 << 0 // Test contact with airplane
        
        // Assign physics body to node
        node.physicsBody = physicsBody
    }
    
    // MARK: - Methods
    
    /// Apply visual effects to the obstacle based on its type
    func applyVisualEffects() {
        switch type {
        case .tree, .palmTree:
            // Trees sway slightly in the wind
            let swayAction = SKAction.sequence([
                SKAction.rotate(byAngle: 0.05, duration: 1.0),
                SKAction.rotate(byAngle: -0.1, duration: 2.0),
                SKAction.rotate(byAngle: 0.05, duration: 1.0)
            ])
            node.run(SKAction.repeatForever(swayAction))
            
        case .umbrella:
            // Umbrellas might spin in strong wind
            let spinAction = SKAction.sequence([
                SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 5.0)
            ])
            node.run(SKAction.repeatForever(spinAction))
            
        case .sandcastle:
            // Sandcastles might occasionally lose a bit of sand
            let sandParticleAction = SKAction.run {
                if let sandParticle = SKEmitterNode(fileNamed: "SandParticle") {
                    sandParticle.position = CGPoint(x: 0, y: -self.node.size.height / 2)
                    sandParticle.numParticlesToEmit = 5
                    self.node.addChild(sandParticle)
                    
                    // Remove particle emitter after it's done
                    let waitAction = SKAction.wait(forDuration: 2.0)
                    let removeAction = SKAction.removeFromParent()
                    sandParticle.run(SKAction.sequence([waitAction, removeAction]))
                }
            }
            
            let waitAction = SKAction.wait(forDuration: 3.0)
            node.run(SKAction.repeatForever(SKAction.sequence([waitAction, sandParticleAction])))
            
        case .billboard:
            // Billboards might flicker like neon signs
            let flickerAction = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.7, duration: 0.1),
                SKAction.fadeAlpha(to: 1.0, duration: 0.1)
            ])
            
            let waitAction = SKAction.wait(forDuration: CGFloat.random(in: 1.0...5.0))
            node.run(SKAction.repeatForever(SKAction.sequence([waitAction, flickerAction, flickerAction, waitAction])))
            
        default:
            // Other obstacles don't have special visual effects
            break
        }
    }
    
    /// Handle collision with the player's airplane
    func handleCollision(with airplane: PaperAirplane) {
        // Apply visual feedback
        let flashAction = SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.5, duration: 0.1),
            SKAction.colorize(with: .white, colorBlendFactor: 0.0, duration: 0.1)
        ])
        node.run(flashAction)
        
        // Apply physical feedback based on obstacle type
        switch type {
        case .tree, .palmTree, .building, .mountain, .mesa:
            // Hard obstacles cause significant damage
            airplane.handleImpact()
            
            // Create impact particles
            if let impactParticle = SKEmitterNode(fileNamed: "ImpactParticle") {
                impactParticle.position = airplane.node.position
                impactParticle.numParticlesToEmit = 20
                node.parent?.addChild(impactParticle)
                
                // Remove particle emitter after it's done
                let waitAction = SKAction.wait(forDuration: 1.0)
                let removeAction = SKAction.removeFromParent()
                impactParticle.run(SKAction.sequence([waitAction, removeAction]))
            }
            
        case .fence, .umbrella, .billboard, .antenna:
            // Medium obstacles cause moderate damage
            airplane.handleImpact()
            
        case .rock, .snowdrift, .sandcastle, .cactus:
            // Smaller obstacles cause minor damage
            airplane.handleImpact()
        }
    }
    
    /// Position the obstacle at the specified position in the scene
    func position(at point: CGPoint) {
        node.position = point
    }
    
    /// Check if the airplane has passed this obstacle
    func checkIfPassed(by airplanePosition: CGPoint) {
        if !isPassed && airplanePosition.x > node.position.x + node.size.width / 2 {
            isPassed = true
            
            // Notify that obstacle was passed (could be used for scoring)
            NotificationCenter.default.post(
                name: NSNotification.Name("ObstaclePassed"),
                object: self
            )
        }
    }
} 