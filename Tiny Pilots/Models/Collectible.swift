//
//  Collectible.swift
//  Tiny Pilots
//
//  Created on 2025-03-01.
//

import SpriteKit

/// Represents a collectible item in the game environment
class Collectible {
    
    // MARK: - Properties
    
    /// The node representing this collectible in the scene
    let node: SKSpriteNode
    
    /// The type of collectible
    let type: CollectibleType
    
    /// Whether the collectible has been collected
    var isCollected: Bool = false
    
    // MARK: - Initialization
    
    /// Initialize a new collectible with the specified type
    init(type: CollectibleType) {
        self.type = type
        
        // Create the sprite node for this collectible
        if let texture = SKTexture(imageNamed: type.textureName) {
            node = SKSpriteNode(texture: texture, size: type.size)
        } else {
            // Fallback to a colored shape if texture is not available
            switch type {
            case .star:
                node = SKSpriteNode(color: .yellow, size: type.size)
            case .coin:
                node = SKSpriteNode(color: .orange, size: type.size)
            case .gem:
                node = SKSpriteNode(color: .purple, size: type.size)
            case .shell:
                node = SKSpriteNode(color: .cyan, size: type.size)
            }
        }
        
        // Set up physics body
        setupPhysicsBody()
        
        // Set the name for identification
        node.name = "collectible_\(type)"
        
        // Apply visual effects
        applyVisualEffects()
    }
    
    // MARK: - Setup
    
    /// Set up the physics body for this collectible
    private func setupPhysicsBody() {
        // Create a physics body based on the collectible type
        let physicsBody: SKPhysicsBody
        
        switch type {
        case .star:
            // Stars use a circle shape
            physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        case .coin:
            // Coins use a circle shape
            physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        case .gem:
            // Gems use a rectangle shape
            physicsBody = SKPhysicsBody(rectangleOf: node.size)
        case .shell:
            // Shells use a rectangle shape
            physicsBody = SKPhysicsBody(rectangleOf: node.size)
        }
        
        // Configure physics body properties
        physicsBody.isDynamic = false
        physicsBody.categoryBitMask = 0x1 << 2 // Collectible category
        physicsBody.collisionBitMask = 0 // Don't collide with anything
        physicsBody.contactTestBitMask = 0x1 << 0 // Test contact with airplane
        
        // Assign physics body to node
        node.physicsBody = physicsBody
    }
    
    // MARK: - Methods
    
    /// Apply visual effects to the collectible based on its type
    private func applyVisualEffects() {
        switch type {
        case .star:
            // Stars pulse and rotate
            let pulseAction = SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 0.5),
                SKAction.scale(to: 1.0, duration: 0.5)
            ])
            let rotateAction = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 3.0)
            
            node.run(SKAction.group([
                SKAction.repeatForever(pulseAction),
                SKAction.repeatForever(rotateAction)
            ]))
            
        case .coin:
            // Coins spin
            let spinAction = SKAction.sequence([
                SKAction.scaleX(to: 0.1, duration: 0.5),
                SKAction.scaleX(to: 1.0, duration: 0.5)
            ])
            
            node.run(SKAction.repeatForever(spinAction))
            
        case .gem:
            // Gems sparkle
            let sparkleAction = SKAction.run {
                if let sparkleParticle = SKEmitterNode(fileNamed: "SparkleParticle") {
                    sparkleParticle.position = CGPoint.zero
                    sparkleParticle.numParticlesToEmit = 5
                    self.node.addChild(sparkleParticle)
                    
                    // Remove particle emitter after it's done
                    let waitAction = SKAction.wait(forDuration: 1.0)
                    let removeAction = SKAction.removeFromParent()
                    sparkleParticle.run(SKAction.sequence([waitAction, removeAction]))
                }
            }
            
            let waitAction = SKAction.wait(forDuration: 2.0)
            node.run(SKAction.repeatForever(SKAction.sequence([waitAction, sparkleAction])))
            
            // Also add a subtle pulse
            let pulseAction = SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 1.0),
                SKAction.scale(to: 0.9, duration: 1.0)
            ])
            node.run(SKAction.repeatForever(pulseAction))
            
        case .shell:
            // Shells gently bob up and down
            let bobAction = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 5, duration: 1.0),
                SKAction.moveBy(x: 0, y: -5, duration: 1.0)
            ])
            
            node.run(SKAction.repeatForever(bobAction))
        }
    }
    
    /// Handle collection by the player's airplane
    func collect() {
        guard !isCollected else { return }
        
        isCollected = true
        
        // Play collection animation
        let collectAction = SKAction.group([
            SKAction.scale(to: 1.5, duration: 0.2),
            SKAction.fadeOut(withDuration: 0.2)
        ])
        
        let removeAction = SKAction.removeFromParent()
        node.run(SKAction.sequence([collectAction, removeAction]))
        
        // Create collection particles
        if let collectParticle = SKEmitterNode(fileNamed: "CollectParticle") {
            collectParticle.position = node.position
            collectParticle.numParticlesToEmit = 20
            node.parent?.addChild(collectParticle)
            
            // Remove particle emitter after it's done
            let waitAction = SKAction.wait(forDuration: 1.0)
            let removeParticleAction = SKAction.removeFromParent()
            collectParticle.run(SKAction.sequence([waitAction, removeParticleAction]))
        }
        
        // Update score
        GameManager.shared.sessionData.score += type.pointValue
        
        // Post notification for collection
        NotificationCenter.default.post(
            name: NSNotification.Name("CollectibleCollected"),
            object: self
        )
    }
    
    /// Position the collectible at the specified position in the scene
    func position(at point: CGPoint) {
        node.position = point
    }
} 