//
//  Obstacle.swift
//  Tiny Pilots
//
//  Created on 2025-03-01.
//

import SpriteKit

/// A class representing an obstacle in the game
class Obstacle {
    
    // MARK: - Properties
    
    /// The obstacle's node in the scene
    let node: SKSpriteNode
    
    /// The type of obstacle
    let type: ObstacleType
    
    /// Whether the obstacle has been passed by the player
    var isPassed: Bool = false
    
    // MARK: - Initialization
    
    /// Initialize with an obstacle type
    init(type: ObstacleType) {
        self.type = type
        
        // Create sprite node with texture, fallback to colored rectangle if texture missing
        self.node = SKSpriteNode.safeSprite(
            imageNamed: type.textureName,
            fallbackColor: .red,
            size: type.size
        )
        self.node.name = "obstacle_\(type)"
        
        // Set up physics body
        let physicsBody = SKPhysicsBody(rectangleOf: type.size)
        physicsBody.isDynamic = false
        physicsBody.categoryBitMask = PhysicsCategory.obstacle
        physicsBody.collisionBitMask = PhysicsCategory.airplane
        physicsBody.contactTestBitMask = PhysicsCategory.airplane
        
        self.node.physicsBody = physicsBody
    }
    
    // MARK: - Methods
    
    /// Position the obstacle at a specific point
    func position(at point: CGPoint) {
        node.position = point
    }
    
    /// Apply visual effects based on obstacle type
    func applyVisualEffects() {
        switch type {
        case .tree, .palmTree:
            // Add gentle swaying animation
            let sway = SKAction.sequence([
                SKAction.rotate(byAngle: 0.05, duration: 1.0),
                SKAction.rotate(byAngle: -0.1, duration: 2.0),
                SKAction.rotate(byAngle: 0.05, duration: 1.0)
            ])
            node.run(SKAction.repeatForever(sway))
            
        case .umbrella:
            // Add slight bobbing animation
            let bob = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 5, duration: 1.0),
                SKAction.moveBy(x: 0, y: -5, duration: 1.0)
            ])
            node.run(SKAction.repeatForever(bob))
            
        case .billboard:
            // Add flickering effect for neon signs
            let flicker = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.7, duration: 0.1),
                SKAction.fadeAlpha(to: 1.0, duration: 0.1)
            ])
            node.run(SKAction.repeatForever(SKAction.sequence([
                flicker,
                SKAction.wait(forDuration: Double.random(in: 2...5))
            ])))
            
        case .antenna:
            // Add blinking light at the top
            let light = SKShapeNode(circleOfRadius: 3)
            light.fillColor = .red
            light.position = CGPoint(x: 0, y: type.size.height / 2)
            
            let blink = SKAction.sequence([
                SKAction.fadeOut(withDuration: 1.0),
                SKAction.fadeIn(withDuration: 1.0)
            ])
            light.run(SKAction.repeatForever(blink))
            node.addChild(light)
            
        default:
            // No special effects for other obstacles
            break
        }
    }
    
    /// Handle collision with the player
    func handleCollision() {
        // Flash the obstacle
        let flash = SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.5, duration: 0.1),
            SKAction.colorize(with: .white, colorBlendFactor: 0.0, duration: 0.1)
        ])
        node.run(flash)
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