//
//  Collectible.swift
//  Tiny Pilots
//
//  Created on 2025-03-01.
//

import SpriteKit

/// A class representing a collectible item in the game
class Collectible {
    
    // MARK: - Properties
    
    /// The collectible's node in the scene
    let node: SKSpriteNode
    
    /// The type of collectible
    let type: CollectibleType
    
    /// Whether the collectible has been collected
    var isCollected: Bool = false
    
    // MARK: - Initialization
    
    /// Initialize with a collectible type
    init(type: CollectibleType) {
        self.type = type
        
        // Create sprite node with texture, fallback to colored circle if texture missing
        let fallbackColor: UIColor = {
            switch type {
            case .star: return .yellow
            case .coin: return .systemYellow
            case .gem: return .systemBlue
            case .shell: return .systemOrange
            }
        }()
        
        self.node = SKSpriteNode.safeSprite(
            imageNamed: type.textureName,
            fallbackColor: fallbackColor,
            size: type.size
        )
        self.node.name = "collectible_\(type)"
        
        // Set up physics body
        let physicsBody = SKPhysicsBody(circleOfRadius: min(type.size.width, type.size.height) / 2)
        physicsBody.isDynamic = false
        physicsBody.categoryBitMask = PhysicsCategory.collectible
        physicsBody.collisionBitMask = 0
        physicsBody.contactTestBitMask = PhysicsCategory.airplane
        
        self.node.physicsBody = physicsBody
        
        // Apply initial visual effects
        applyVisualEffects()
    }
    
    // MARK: - Methods
    
    /// Position the collectible at a specific point
    func position(at point: CGPoint) {
        node.position = point
    }
    
    /// Apply visual effects based on collectible type
    private func applyVisualEffects() {
        // Add floating animation
        let float = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 5, duration: 1.0),
            SKAction.moveBy(x: 0, y: -5, duration: 1.0)
        ])
        node.run(SKAction.repeatForever(float))
        
        // Add rotation based on type
        switch type {
        case .star:
            // Stars spin slowly
            let spin = SKAction.rotate(byAngle: .pi * 2, duration: 3.0)
            node.run(SKAction.repeatForever(spin))
            
            // Add sparkle effect
            let sparkle = SKEmitterNode()
            sparkle.particleTexture = SKTexture(imageNamed: "sparkle")
            sparkle.particleBirthRate = 2.0
            sparkle.particleLifetime = 1.0
            sparkle.particleScale = 0.2
            sparkle.particleScaleRange = 0.1
            sparkle.particleAlpha = 0.8
            sparkle.particleAlphaRange = 0.2
            sparkle.particleSpeed = 10.0
            sparkle.particleSpeedRange = 5.0
            sparkle.emissionAngle = 0
            sparkle.emissionAngleRange = .pi * 2
            node.addChild(sparkle)
            
        case .coin:
            // Coins spin quickly
            let spin = SKAction.rotate(byAngle: .pi * 2, duration: 1.5)
            node.run(SKAction.repeatForever(spin))
            
            // Add shine effect
            let shine = SKAction.sequence([
                SKAction.fadeAlpha(to: 1.0, duration: 0.1),
                SKAction.wait(forDuration: 1.0),
                SKAction.fadeAlpha(to: 0.7, duration: 0.1),
                SKAction.wait(forDuration: 0.5)
            ])
            node.run(SKAction.repeatForever(shine))
            
        case .gem:
            // Gems pulse and rotate
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.5),
                SKAction.scale(to: 0.9, duration: 0.5)
            ])
            let spin = SKAction.rotate(byAngle: .pi, duration: 2.0)
            
            node.run(SKAction.group([
                SKAction.repeatForever(pulse),
                SKAction.repeatForever(spin)
            ]))
            
        case .shell:
            // Shells bob gently
            let bob = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 3, duration: 1.5),
                SKAction.moveBy(x: 0, y: -3, duration: 1.5)
            ])
            node.run(SKAction.repeatForever(bob))
            
            // Add subtle glow
            let glow = SKAction.sequence([
                SKAction.colorize(with: .white, colorBlendFactor: 0.3, duration: 1.0),
                SKAction.colorize(with: .white, colorBlendFactor: 0.0, duration: 1.0)
            ])
            node.run(SKAction.repeatForever(glow))
        }
    }
    
    /// Handle collection by the player
    func collect() {
        guard !isCollected else { return }
        
        isCollected = true
        
        // Create collection effect
        let collectEffect = SKEmitterNode()
        collectEffect.particleTexture = SKTexture(imageNamed: "sparkle")
        collectEffect.particleBirthRate = 20
        collectEffect.particleLifetime = 0.5
        collectEffect.particleScale = 0.3
        collectEffect.particleScaleRange = 0.2
        collectEffect.particleAlpha = 0.8
        collectEffect.particleSpeed = 50.0
        collectEffect.particleSpeedRange = 20.0
        collectEffect.emissionAngle = 0
        collectEffect.emissionAngleRange = .pi * 2
        collectEffect.numParticlesToEmit = 20
        
        // Position effect at collectible's position
        collectEffect.position = node.position
        node.parent?.addChild(collectEffect)
        
        // Remove collectible with scale and fade animation
        let collect = SKAction.group([
            SKAction.scale(to: 1.5, duration: 0.2),
            SKAction.fadeOut(withDuration: 0.2)
        ])
        
        node.run(SKAction.sequence([
            collect,
            SKAction.removeFromParent()
        ]))
        
        // Remove effect node after animation
        collectEffect.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.removeFromParent()
        ]))
        
        // Post notification for collection with score value
        NotificationCenter.default.post(
            name: NSNotification.Name("CollectibleCollected"),
            object: self,
            userInfo: ["pointValue": type.pointValue]
        )
    }
} 