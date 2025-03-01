//
//  PhysicsManager.swift
//  Tiny Pilots
//
//  Created on 2025-03-01.
//

import Foundation
import SpriteKit
import CoreMotion

/// A manager class that handles physics simulation and device motion for paper airplane control
class PhysicsManager {
    
    // MARK: - Singleton
    
    /// Shared instance for singleton access
    static let shared = PhysicsManager()
    
    // MARK: - Properties
    
    /// The motion manager for device tilt detection
    private let motionManager = CMMotionManager()
    
    /// Current wind vector in the environment
    private(set) var windVector = CGVector(dx: 0, dy: 0)
    
    /// Timer for updating physics effects
    private var physicsTimer: Timer?
    
    /// Flag indicating if physics simulation is active
    private(set) var isActive = false
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton pattern
    private init() {
        // Set up motion manager
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 Hz update rate
    }
    
    // MARK: - Physics World Configuration
    
    /// Configure the physics world for the given scene
    func configurePhysicsWorld(for scene: SKScene) {
        // Set up physics world properties
        scene.physicsWorld.gravity = GameConfig.Physics.gravity
        scene.physicsWorld.speed = 1.0
        
        // Set up contact delegate if the scene supports it
        if let contactDelegate = scene as? SKPhysicsContactDelegate {
            scene.physicsWorld.contactDelegate = contactDelegate
        }
    }
    
    // MARK: - Motion Control
    
    /// Start device motion updates for tilt control
    func startDeviceMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion is not available")
            return
        }
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
            guard let self = self, let motion = motion, error == nil else {
                print("Error getting device motion: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Process device motion for tilt control
            self.processTiltControl(motion: motion)
        }
    }
    
    /// Stop device motion updates
    func stopDeviceMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    /// Process tilt control from device motion
    private func processTiltControl(motion: CMDeviceMotion) {
        guard let airplane = GameManager.shared.activeAirplane,
              GameManager.shared.currentState == .playing else {
            return
        }
        
        // Get roll (tilting left/right)
        let roll = motion.attitude.roll
        
        // Get pitch (tilting forward/backward)
        let pitch = motion.attitude.pitch
        
        // Apply tilt control to airplane
        let sensitivity = GameConfig.Controls.tiltSensitivity
        let maxTiltAngle = GameConfig.Controls.maxTiltAngle * .pi / 180.0
        
        // Normalize tilt values to the range [-1, 1] based on max tilt angle
        let normalizedRoll = CGFloat(max(-1.0, min(1.0, roll / maxTiltAngle)))
        let normalizedPitch = CGFloat(max(-1.0, min(1.0, pitch / maxTiltAngle)))
        
        // Apply banking based on roll (side-to-side tilt)
        let bankForce = normalizedRoll * sensitivity * 5.0
        airplane.bank(amount: bankForce)
        
        // Apply thrust based on pitch (forward-backward tilt)
        // Negative pitch (tilting forward) increases thrust
        let thrustAmount = (1.0 - normalizedPitch) * sensitivity * 10.0
        if thrustAmount > 0 {
            airplane.applyThrust(amount: thrustAmount)
        }
    }
    
    // MARK: - Physics Simulation
    
    /// Start custom physics simulation
    func startPhysicsSimulation() {
        guard !isActive else { return }
        
        isActive = true
        
        // Start device motion for tilt control
        startDeviceMotionUpdates()
        
        // Set up a timer for physics updates not handled by SpriteKit
        physicsTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.updateCustomPhysics()
        }
    }
    
    /// Stop custom physics simulation
    func stopPhysicsSimulation() {
        guard isActive else { return }
        
        isActive = false
        
        // Stop device motion updates
        stopDeviceMotionUpdates()
        
        // Invalidate physics timer
        physicsTimer?.invalidate()
        physicsTimer = nil
    }
    
    /// Update custom physics effects not handled by SpriteKit
    private func updateCustomPhysics() {
        guard let airplane = GameManager.shared.activeAirplane,
              GameManager.shared.currentState == .playing else {
            return
        }
        
        // Apply lift force based on airplane properties and current velocity
        airplane.applyLift()
        
        // Apply wind effects
        applyWind(to: airplane)
    }
    
    // MARK: - Wind Effects
    
    /// Set wind vector for the current environment
    func setWindVector(direction: CGFloat, strength: CGFloat) {
        // Convert direction (in degrees) to radians
        let radians = direction * .pi / 180.0
        
        // Create wind vector using direction and strength
        windVector = CGVector(
            dx: cos(radians) * strength,
            dy: sin(radians) * strength
        )
    }
    
    /// Apply wind effects to the airplane
    private func applyWind(to airplane: PaperAirplane) {
        guard let physicsBody = airplane.node.physicsBody else { return }
        
        // Apply wind force
        // Wind effect depends on the airplane's drag coefficient
        let windEffect = CGVector(
            dx: windVector.dx * airplane.foldType.physicsProperties.drag * 0.5,
            dy: windVector.dy * airplane.foldType.physicsProperties.drag * 0.5
        )
        
        physicsBody.applyForce(windEffect)
    }
    
    /// Update wind strength and direction randomly to create natural variation
    func updateRandomWind() {
        guard let currentStrength = windVector.length, currentStrength > 0 else {
            // If there's no wind, don't update
            return
        }
        
        // Get current direction in radians
        let currentDirection = atan2(windVector.dy, windVector.dx)
        
        // Create variation in direction (convert to degrees for clarity)
        let directionVariation = CGFloat.random(in: -GameConfig.Environments.windDirectionVariability...GameConfig.Environments.windDirectionVariability) * .pi / 180.0
        let newDirection = currentDirection + directionVariation
        
        // Create variation in strength
        let strengthVariation = CGFloat.random(in: 0.8...1.2)
        let newStrength = min(max(currentStrength * strengthVariation, 
                                  GameConfig.Environments.windStrengthRange.lowerBound),
                              GameConfig.Environments.windStrengthRange.upperBound)
        
        // Set new wind vector
        windVector = CGVector(
            dx: cos(newDirection) * newStrength,
            dy: sin(newDirection) * newStrength
        )
    }
}

// MARK: - CGVector Extension

extension CGVector {
    /// Computes the length (magnitude) of the vector
    var length: CGFloat? {
        return sqrt(dx * dx + dy * dy)
    }
} 