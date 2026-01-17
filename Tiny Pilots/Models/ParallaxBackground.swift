//
//  ParallaxBackground.swift
//  Tiny Pilots
//
//  Created on 2025-03-01.
//

import SpriteKit

/// A background that creates a parallax scrolling effect
final class ParallaxBackground: SKNode {
    // MARK: - Properties
    private let size: CGSize
    private var layers: [SKNode] = []
    private let parallaxFactors: [CGFloat] = [0.2, 0.4, 0.6, 0.8]
    
    // MARK: - Initialization
    init(size: CGSize) {
        self.size = size
        super.init()
        setupBackground()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupBackground() {
        // Create multiple background layers for parallax effect
        for (index, factor) in parallaxFactors.enumerated() {
            let layer = createBackgroundLayer(depth: index, factor: factor)
            layers.append(layer)
            addChild(layer)
        }
    }
    
    private func createBackgroundLayer(depth: Int, factor: CGFloat) -> SKNode {
        let layer = SKNode()
        layer.zPosition = CGFloat(-100 + depth)
        
        // Add visual elements to the layer based on depth
        let elements = createLayerElements(depth: depth)
        for element in elements {
            layer.addChild(element)
        }
        
        return layer
    }
    
    private func createLayerElements(depth: Int) -> [SKNode] {
        var elements: [SKNode] = []
        
        // Create different elements based on depth
        switch depth {
        case 0: // Farthest layer (clouds)
            elements = createClouds()
        case 1: // Mountains or city skyline
            elements = createMountains()
        case 2: // Mid-ground elements
            elements = createMidgroundElements()
        case 3: // Foreground elements
            elements = createForegroundElements()
        default:
            break
        }
        
        return elements
    }
    
    private func createClouds() -> [SKNode] {
        // Implementation for cloud layer
        return []
    }
    
    private func createMountains() -> [SKNode] {
        // Implementation for mountain layer
        return []
    }
    
    private func createMidgroundElements() -> [SKNode] {
        // Implementation for mid-ground elements
        return []
    }
    
    private func createForegroundElements() -> [SKNode] {
        // Implementation for foreground elements
        return []
    }
    
    // MARK: - Update
    func update(withCameraPosition position: CGPoint) {
        for (index, layer) in layers.enumerated() {
            let factor = parallaxFactors[index]
            layer.position = CGPoint(
                x: -position.x * factor,
                y: -position.y * factor
            )
        }
    }
} 