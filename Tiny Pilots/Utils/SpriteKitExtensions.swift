//
//  SpriteKitExtensions.swift
//  Tiny Pilots
//
//  Created on 2025-01-16.
//

import SpriteKit
import UIKit

extension SKSpriteNode {
    /// Creates a sprite node with safe asset loading and fallback
    /// - Parameters:
    ///   - imageNamed: Name of the image asset to load
    ///   - fallbackColor: Color to use if the image is not found
    ///   - size: Size of the sprite node
    /// - Returns: A sprite node with the image if available, or a colored rectangle as fallback
    static func safeSprite(imageNamed name: String, fallbackColor: UIColor, size: CGSize) -> SKSpriteNode {
        // Check if the image exists
        if UIImage(named: name) != nil {
            return SKSpriteNode(imageNamed: name)
        }
        
        // Fallback to colored rectangle
        let sprite = SKSpriteNode(color: fallbackColor, size: size)
        sprite.alpha = 0.8 // Slightly transparent to indicate it's a fallback
        return sprite
    }
}

extension SKTexture {
    /// Creates a texture with safe asset loading
    /// - Parameter name: Name of the image asset to load
    /// - Returns: A texture if the image exists, nil otherwise
    static func safeTexture(imageNamed name: String) -> SKTexture? {
        if UIImage(named: name) != nil {
            return SKTexture(imageNamed: name)
        }
        // Asset not found - return nil to allow caller to handle gracefully
        print("Warning: Texture asset not found: \(name)")
        return nil
    }
}
