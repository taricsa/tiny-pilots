//
//  ParallaxBackground.swift
//  Tiny Pilots
//
//  Created on 2025-03-01.
//

import SpriteKit

/// Manages parallax scrolling backgrounds for a scene
class ParallaxBackground {
    
    // MARK: - Properties
    
    /// The parent node to which all background layers are added
    private let parentNode: SKNode
    
    /// The size of the scene
    private let sceneSize: CGSize
    
    /// The layers that make up the parallax background
    private var layers: [ParallaxLayer] = []
    
    /// The nodes for each layer
    private var layerNodes: [SKNode] = []
    
    // MARK: - Initialization
    
    /// Initialize a new parallax background for the given scene
    init(parent: SKNode, size: CGSize) {
        self.parentNode = parent
        self.sceneSize = size
    }
    
    // MARK: - Setup
    
    /// Set up the parallax background with the given layers
    func setup(with layers: [ParallaxLayer]) {
        // Clear any existing layers
        for node in layerNodes {
            node.removeFromParent()
        }
        
        self.layers = layers
        self.layerNodes = []
        
        // Create nodes for each layer
        for layer in layers {
            let layerNode = createLayerNode(for: layer)
            parentNode.addChild(layerNode)
            layerNodes.append(layerNode)
        }
    }
    
    /// Create a node for the given layer
    private func createLayerNode(for layer: ParallaxLayer) -> SKNode {
        // Create a container node for this layer
        let containerNode = SKNode()
        containerNode.zPosition = layer.zPosition
        
        // Create the layer sprite
        let layerSize = CGSize(width: sceneSize.width * 1.5, height: sceneSize.height)
        let spriteNode = layer.createNode(size: layerSize) as! SKSpriteNode
        
        // Position the first sprite
        spriteNode.position = CGPoint(x: 0, y: sceneSize.height / 2)
        spriteNode.anchorPoint = CGPoint(x: 0, y: 0.5)
        containerNode.addChild(spriteNode)
        
        // Create a duplicate sprite for seamless scrolling
        let duplicateSpriteNode = layer.createNode(size: layerSize) as! SKSpriteNode
        duplicateSpriteNode.position = CGPoint(x: layerSize.width, y: sceneSize.height / 2)
        duplicateSpriteNode.anchorPoint = CGPoint(x: 0, y: 0.5)
        containerNode.addChild(duplicateSpriteNode)
        
        return containerNode
    }
    
    // MARK: - Update
    
    /// Update the parallax background based on the camera position
    func update(withCameraPosition cameraPosition: CGPoint) {
        for (index, layerNode) in layerNodes.enumerated() {
            let layer = layers[index]
            
            // Calculate the parallax offset based on camera position and layer speed
            let parallaxOffset = cameraPosition.x * layer.scrollSpeed
            
            // Apply the offset to the layer
            layerNode.position.x = -parallaxOffset
            
            // Check if we need to reset the position for seamless scrolling
            let layerWidth = sceneSize.width * 1.5
            if abs(layerNode.position.x) > layerWidth {
                // Reset position to create the illusion of infinite scrolling
                layerNode.position.x = layerNode.position.x.truncatingRemainder(dividingBy: layerWidth)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Add a cloud to the scene with parallax effect
    func addCloud(at position: CGPoint, size: CGSize, speed: CGFloat) {
        // Create a cloud sprite
        let cloud = SKSpriteNode(color: .white, size: size)
        cloud.alpha = 0.8
        cloud.position = position
        cloud.zPosition = -8
        
        // Add to the parent node
        parentNode.addChild(cloud)
        
        // Store the cloud's initial x position relative to the camera
        let initialRelativeX = position.x
        
        // Add a custom action to move the cloud with parallax effect
        let moveAction = SKAction.customAction(withDuration: 1.0) { node, elapsedTime in
            if let cameraNode = self.parentNode.scene?.camera {
                // Calculate the parallax offset based on camera position and cloud speed
                let parallaxOffset = cameraNode.position.x * speed
                
                // Apply the offset to the cloud
                node.position.x = initialRelativeX - parallaxOffset
            }
        }
        
        // Run the action continuously
        cloud.run(SKAction.repeatForever(moveAction))
    }
} 