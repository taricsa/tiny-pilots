//
//  BackgroundLayer.swift
//  Tiny Pilots
//
//  Created by Kiro on 7/17/25.
//

import Foundation
import CoreGraphics

/// Represents a background layer for parallax scrolling effects
struct BackgroundLayer: Codable, Equatable {
    /// Texture name for the layer
    let textureName: String
    
    /// Parallax scroll speed factor (0.0 to 1.0)
    let scrollSpeed: CGFloat
    
    /// Z-position for layer ordering
    let zPosition: CGFloat
    
    /// Layer opacity (0.0 to 1.0)
    let opacity: CGFloat
    
    /// Layer tint color (optional)
    let tintColor: String?
    
    /// Whether the layer should repeat horizontally
    let repeatsHorizontally: Bool
    
    /// Whether the layer should repeat vertically
    let repeatsVertically: Bool
    
    /// Initialize a background layer
    /// - Parameters:
    ///   - textureName: Name of the texture asset
    ///   - scrollSpeed: Parallax scroll speed factor
    ///   - zPosition: Z-position for layer ordering
    ///   - opacity: Layer opacity
    ///   - tintColor: Optional tint color name
    ///   - repeatsHorizontally: Whether to repeat horizontally
    ///   - repeatsVertically: Whether to repeat vertically
    init(
        textureName: String,
        scrollSpeed: CGFloat,
        zPosition: CGFloat,
        opacity: CGFloat = 1.0,
        tintColor: String? = nil,
        repeatsHorizontally: Bool = true,
        repeatsVertically: Bool = false
    ) {
        self.textureName = textureName
        self.scrollSpeed = max(0.0, min(1.0, scrollSpeed)) // Clamp to valid range
        self.zPosition = zPosition
        self.opacity = max(0.0, min(1.0, opacity)) // Clamp to valid range
        self.tintColor = tintColor
        self.repeatsHorizontally = repeatsHorizontally
        self.repeatsVertically = repeatsVertically
    }
    
    /// Predefined background layers for different environments
    static let cloudLayer = BackgroundLayer(
        textureName: "clouds_background",
        scrollSpeed: 0.2,
        zPosition: -100,
        opacity: 0.8
    )
    
    static let mountainLayer = BackgroundLayer(
        textureName: "mountains_background",
        scrollSpeed: 0.4,
        zPosition: -80,
        opacity: 0.9
    )
    
    static let hillLayer = BackgroundLayer(
        textureName: "hills_background",
        scrollSpeed: 0.6,
        zPosition: -60,
        opacity: 1.0
    )
    
    static let treeLayer = BackgroundLayer(
        textureName: "trees_background",
        scrollSpeed: 0.8,
        zPosition: -40,
        opacity: 1.0
    )
    
    /// Get layers for a specific environment type
    /// - Parameter environmentType: The environment type
    /// - Returns: Array of background layers for the environment
    static func layers(for environmentType: String) -> [BackgroundLayer] {
        switch environmentType.lowercased() {
        case "meadow", "sunny meadows":
            return [cloudLayer, hillLayer, treeLayer]
        case "alpine", "alpine heights":
            return [cloudLayer, mountainLayer, hillLayer]
        case "coastal", "coastal breeze":
            return [
                BackgroundLayer(textureName: "ocean_background", scrollSpeed: 0.3, zPosition: -90),
                BackgroundLayer(textureName: "beach_background", scrollSpeed: 0.7, zPosition: -50)
            ]
        case "urban", "urban skyline":
            return [
                BackgroundLayer(textureName: "city_background", scrollSpeed: 0.5, zPosition: -70),
                BackgroundLayer(textureName: "buildings_background", scrollSpeed: 0.8, zPosition: -30)
            ]
        case "desert", "desert canyon":
            return [
                BackgroundLayer(textureName: "desert_sky_background", scrollSpeed: 0.2, zPosition: -100),
                BackgroundLayer(textureName: "canyon_background", scrollSpeed: 0.6, zPosition: -60)
            ]
        default:
            return [cloudLayer, hillLayer]
        }
    }
}

// MARK: - CustomStringConvertible

extension BackgroundLayer: CustomStringConvertible {
    var description: String {
        return "BackgroundLayer(texture: \(textureName), speed: \(scrollSpeed), z: \(zPosition))"
    }
}