//
//  GameConfig.swift
//  Tiny Pilots
//
//  Created on 2025-03-01.
//

import UIKit
import SpriteKit

/// A struct containing all the game configuration parameters and constants
struct GameConfig {
    
    // MARK: - Debug Settings
    struct Debug {
        static let showsFPS = true
        static let showsNodeCount = true
        static let showsPhysics = false
    }
    
    // MARK: - Game Physics Settings
    struct Physics {
        static let gravity: CGVector = CGVector(dx: 0, dy: -9.8)
        static let airResistance: CGFloat = 0.02
        static let maxSpeed: CGFloat = 1000.0
        static let minSpeed: CGFloat = 50.0
        
        // Default airplane physics properties
        static let defaultMass: CGFloat = 0.2
        static let defaultDrag: CGFloat = 0.15
        static let defaultAngularDamping: CGFloat = 0.8
        static let defaultLinearDamping: CGFloat = 0.1
    }
    
    // MARK: - Game Control Settings
    struct Controls {
        static let tiltSensitivity: CGFloat = 1.0
        static let touchSensitivity: CGFloat = 1.0
        static let maxTiltAngle: CGFloat = 45.0 // In degrees
    }
    
    // MARK: - Game UI Settings
    struct UI {
        static let fadeInDuration: TimeInterval = 0.3
        static let fadeOutDuration: TimeInterval = 0.3
        static let minimumHUDOpacity: CGFloat = 0.7
        
        // HUD element sizes
        static let pauseButtonSize: CGSize = CGSize(width: 40, height: 40)
        static let hudElementPadding: CGFloat = 20.0
    }
    
    // MARK: - Game Progression Settings
    struct Progression {
        static let baseXpPerSecond: CGFloat = 1.0
        static let baseXpPerMeter: CGFloat = 0.5
        static let bonusXpPerCollectible: CGFloat = 50.0
        static let xpPerLevelMultiplier: CGFloat = 1.5
        
        // Level thresholds
        static func xpRequiredForLevel(_ level: Int) -> Int {
            // Base XP + exponential scaling with level
            return Int(100.0 * pow(Double(xpPerLevelMultiplier), Double(level - 1)))
        }
    }
    
    // MARK: - Environment Settings
    struct Environments {
        static let environmentCount: Int = 5
        static let windStrengthRange: ClosedRange<CGFloat> = 0.0...50.0
        static let windDirectionVariability: CGFloat = 30.0 // In degrees
        
        // Environment unlock levels
        static let environmentUnlockLevels: [Int] = [1, 5, 10, 15, 20]
    }
    
    // MARK: - Airplane Designs
    struct AirplaneDesigns {
        static let designCount: Int = 15
        
        // Design unlock levels (players unlock designs as they progress)
        static let designUnlockLevels: [Int] = [
            1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 30
        ]
    }
    
    // MARK: - Performance Settings
    struct Performance {
        static let targetFrameRate: Int = 60
        static let maxParticleCount: Int = 500
        static let cullingDistance: CGFloat = 2000.0
        static let maxVisibleObstacles: Int = 50
    }
    
    // MARK: - Challenges
    struct Challenges {
        static let challengeRefreshHours: Int = 24
        static let maxActiveChallenges: Int = 3
        static let maxDailyChallengeAttempts: Int = 1
    }
} 