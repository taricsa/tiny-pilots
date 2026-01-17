//
//  PhysicsCalculations.swift
//  Tiny Pilots
//
//  Created on 2025-03-01.
//

import Foundation
import CoreGraphics
import SpriteKit

/// Business logic class for airplane physics calculations
class PhysicsCalculations {
    
    // MARK: - Force Calculations
    
    /// Calculate lift force based on airplane velocity and properties
    /// - Parameters:
    ///   - velocity: Current velocity vector
    ///   - airplaneType: Type of airplane
    ///   - foldType: Fold type affecting aerodynamics
    /// - Returns: Lift force vector
    static func calculateLiftForce(
        velocity: CGVector,
        airplaneType: PaperAirplane.AirplaneType,
        foldType: PaperAirplane.FoldType
    ) -> CGVector {
        let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        
        // Base lift coefficient varies by airplane type
        let baseLiftCoefficient: CGFloat
        switch airplaneType {
        case .basic:
            baseLiftCoefficient = 0.2
        case .speedy:
            baseLiftCoefficient = 0.15
        case .sturdy:
            baseLiftCoefficient = 0.25
        case .glider:
            baseLiftCoefficient = 0.35
        }
        
        // Apply fold type multiplier
        let liftCoefficient = baseLiftCoefficient * foldType.physicsMultiplier.lift
        
        // Calculate lift force (perpendicular to velocity)
        let liftMagnitude = speed * liftCoefficient
        
        // Lift direction is perpendicular to velocity (90 degrees counterclockwise)
        let velocityAngle = atan2(velocity.dy, velocity.dx)
        let liftAngle = velocityAngle + CGFloat.pi / 2
        
        return CGVector(
            dx: cos(liftAngle) * liftMagnitude,
            dy: sin(liftAngle) * liftMagnitude
        )
    }
    
    /// Calculate drag force opposing motion
    /// - Parameters:
    ///   - velocity: Current velocity vector
    ///   - airplaneType: Type of airplane
    ///   - foldType: Fold type affecting drag
    /// - Returns: Drag force vector
    static func calculateDragForce(
        velocity: CGVector,
        airplaneType: PaperAirplane.AirplaneType,
        foldType: PaperAirplane.FoldType
    ) -> CGVector {
        let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        
        // Base drag coefficient varies by airplane type
        let baseDragCoefficient: CGFloat
        switch airplaneType {
        case .basic:
            baseDragCoefficient = 0.1
        case .speedy:
            baseDragCoefficient = 0.08
        case .sturdy:
            baseDragCoefficient = 0.12
        case .glider:
            baseDragCoefficient = 0.06
        }
        
        // Apply fold type multiplier
        let dragCoefficient = baseDragCoefficient * foldType.physicsMultiplier.drag
        
        // Drag force opposes velocity direction
        let dragMagnitude = speed * speed * dragCoefficient * 0.01 // Quadratic drag
        
        if speed > 0 {
            let normalizedVelocity = CGVector(dx: velocity.dx / speed, dy: velocity.dy / speed)
            return CGVector(
                dx: -normalizedVelocity.dx * dragMagnitude,
                dy: -normalizedVelocity.dy * dragMagnitude
            )
        }
        
        return CGVector.zero
    }
    
    /// Calculate thrust force from tilt input
    /// - Parameters:
    ///   - tiltX: Horizontal tilt input (-1 to 1)
    ///   - tiltY: Vertical tilt input (-1 to 1)
    ///   - airplaneType: Type of airplane
    ///   - foldType: Fold type affecting responsiveness
    /// - Returns: Thrust force vector
    static func calculateThrustForce(
        tiltX: CGFloat,
        tiltY: CGFloat,
        airplaneType: PaperAirplane.AirplaneType,
        foldType: PaperAirplane.FoldType
    ) -> CGVector {
        // Base thrust multiplier varies by airplane type
        let baseThrustMultiplier: CGFloat
        switch airplaneType {
        case .basic:
            baseThrustMultiplier = 50.0
        case .speedy:
            baseThrustMultiplier = 70.0
        case .sturdy:
            baseThrustMultiplier = 40.0
        case .glider:
            baseThrustMultiplier = 30.0
        }
        
        // Apply fold type multiplier for turn rate
        let thrustMultiplier = baseThrustMultiplier * foldType.physicsMultiplier.turnRate
        
        // Calculate thrust components
        let xThrust = tiltX * thrustMultiplier
        let yThrust = tiltY * thrustMultiplier
        
        return CGVector(dx: xThrust, dy: yThrust)
    }
    
    /// Calculate constant forward thrust to maintain flight
    /// - Parameters:
    ///   - airplaneType: Type of airplane
    ///   - currentSpeed: Current speed of airplane
    /// - Returns: Forward thrust force
    static func calculateForwardThrust(
        airplaneType: PaperAirplane.AirplaneType,
        currentSpeed: CGFloat
    ) -> CGFloat {
        // Base thrust varies by airplane type
        let baseThrust: CGFloat
        switch airplaneType {
        case .basic:
            baseThrust = 20.0
        case .speedy:
            baseThrust = 30.0
        case .sturdy:
            baseThrust = 15.0
        case .glider:
            baseThrust = 10.0
        }
        
        // Reduce thrust at higher speeds to prevent unlimited acceleration
        let speedFactor = max(0.1, 1.0 - (currentSpeed / 500.0))
        
        return baseThrust * speedFactor
    }
    
    // MARK: - Stability Calculations
    
    /// Calculate stabilization torque to align airplane with velocity
    /// - Parameters:
    ///   - currentRotation: Current airplane rotation in radians
    ///   - velocity: Current velocity vector
    ///   - speed: Current speed
    ///   - airplaneType: Type of airplane
    /// - Returns: Stabilization torque
    static func calculateStabilizationTorque(
        currentRotation: CGFloat,
        velocity: CGVector,
        speed: CGFloat,
        airplaneType: PaperAirplane.AirplaneType
    ) -> CGFloat {
        // Only apply stabilization at higher speeds
        guard speed > 100 else { return 0 }
        
        // Calculate ideal rotation based on velocity direction
        let idealRotation = atan2(velocity.dy, velocity.dx)
        
        // Calculate rotation difference
        var rotationDiff = idealRotation - currentRotation
        
        // Normalize to [-π, π]
        while rotationDiff > CGFloat.pi { rotationDiff -= 2 * CGFloat.pi }
        while rotationDiff < -CGFloat.pi { rotationDiff += 2 * CGFloat.pi }
        
        // Stabilization strength varies by airplane type
        let stabilizationStrength: CGFloat
        switch airplaneType {
        case .basic:
            stabilizationStrength = 0.1
        case .speedy:
            stabilizationStrength = 0.08
        case .sturdy:
            stabilizationStrength = 0.12
        case .glider:
            stabilizationStrength = 0.15
        }
        
        // Apply stabilizing torque proportional to speed
        let speedFactor = min(1.0, (speed - 100) / 100)
        
        return rotationDiff * stabilizationStrength * speedFactor
    }
    
    // MARK: - Wind Effects
    
    /// Calculate wind force effect on airplane
    /// - Parameters:
    ///   - windVector: Current wind vector
    ///   - airplaneType: Type of airplane
    ///   - foldType: Fold type affecting wind resistance
    /// - Returns: Wind force vector
    static func calculateWindForce(
        windVector: CGVector,
        airplaneType: PaperAirplane.AirplaneType,
        foldType: PaperAirplane.FoldType
    ) -> CGVector {
        // Wind resistance varies by airplane type
        let windResistance: CGFloat
        switch airplaneType {
        case .basic:
            windResistance = 0.5
        case .speedy:
            windResistance = 0.4
        case .sturdy:
            windResistance = 0.3
        case .glider:
            windResistance = 0.6
        }
        
        // Apply fold type effect (more aerodynamic folds resist wind better)
        let effectiveResistance = windResistance * (2.0 - foldType.physicsMultiplier.drag)
        
        return CGVector(
            dx: windVector.dx * effectiveResistance,
            dy: windVector.dy * effectiveResistance
        )
    }
    
    /// Generate turbulence force for realistic wind effects
    /// - Parameters:
    ///   - windStrength: Current wind strength
    ///   - turbulenceChance: Probability of turbulence (0.0 to 1.0)
    /// - Returns: Turbulence force vector or zero if no turbulence
    static func calculateTurbulenceForce(
        windStrength: CGFloat,
        turbulenceChance: Float = 0.05
    ) -> CGVector {
        // Check if turbulence occurs
        guard Float.random(in: 0...1) < turbulenceChance else {
            return CGVector.zero
        }
        
        // Calculate turbulence strength based on wind strength
        let turbulenceStrength = windStrength * CGFloat.random(in: 0.5...1.5)
        
        // Apply random turbulence force
        return CGVector(
            dx: CGFloat.random(in: -1.0...1.0) * turbulenceStrength,
            dy: CGFloat.random(in: -1.0...1.0) * turbulenceStrength
        )
    }
    
    // MARK: - Collision Physics
    
    /// Calculate bounce force after collision with obstacle
    /// - Parameters:
    ///   - velocity: Velocity before collision
    ///   - collisionNormal: Normal vector of collision surface
    ///   - restitution: Bounce coefficient (0.0 to 1.0)
    /// - Returns: New velocity after bounce
    static func calculateBounceVelocity(
        velocity: CGVector,
        collisionNormal: CGVector,
        restitution: CGFloat = 0.3
    ) -> CGVector {
        // Calculate dot product of velocity and normal
        let dotProduct = velocity.dx * collisionNormal.dx + velocity.dy * collisionNormal.dy
        
        // Calculate reflection vector
        let reflectionX = velocity.dx - 2 * dotProduct * collisionNormal.dx
        let reflectionY = velocity.dy - 2 * dotProduct * collisionNormal.dy
        
        // Apply restitution (energy loss)
        return CGVector(
            dx: reflectionX * restitution,
            dy: reflectionY * restitution
        )
    }
    
    /// Calculate damage force from collision impact
    /// - Parameters:
    ///   - velocity: Velocity at impact
    ///   - mass: Mass of airplane
    /// - Returns: Impact force magnitude
    static func calculateImpactForce(velocity: CGVector, mass: CGFloat) -> CGFloat {
        let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        return speed * mass * 0.5 // Kinetic energy approximation
    }
    
    // MARK: - Utility Functions
    
    /// Normalize angle to range [-π, π]
    /// - Parameter angle: Angle in radians
    /// - Returns: Normalized angle
    static func normalizeAngle(_ angle: CGFloat) -> CGFloat {
        var normalized = angle
        while normalized > CGFloat.pi { normalized -= 2 * CGFloat.pi }
        while normalized < -CGFloat.pi { normalized += 2 * CGFloat.pi }
        return normalized
    }
    
    /// Calculate distance between two points
    /// - Parameters:
    ///   - point1: First point
    ///   - point2: Second point
    /// - Returns: Distance between points
    static func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// Calculate angle between two points
    /// - Parameters:
    ///   - from: Starting point
    ///   - to: Target point
    /// - Returns: Angle in radians
    static func angle(from: CGPoint, to: CGPoint) -> CGFloat {
        let dx = to.x - from.x
        let dy = to.y - from.y
        return atan2(dy, dx)
    }
}

