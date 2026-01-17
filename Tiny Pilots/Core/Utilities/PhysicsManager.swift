//
//  PhysicsManager.swift
//  Tiny Pilots
//
//  Minimal façade to satisfy existing references. Delegates to PhysicsService.
//

import Foundation
import CoreMotion
import CoreGraphics

final class PhysicsManager {
    static let shared = PhysicsManager()

    private var physicsService: PhysicsServiceProtocol

    private init() {
        if let resolved: PhysicsServiceProtocol = DIContainer.shared.tryResolve(PhysicsServiceProtocol.self) {
            physicsService = resolved
        } else {
            physicsService = PhysicsService()
        }
    }

    func startPhysicsSimulation() {
        physicsService.startPhysicsSimulation()
    }

    func stopPhysicsSimulation() {
        physicsService.stopPhysicsSimulation()
    }

    func setSensitivity(_ value: CGFloat) {
        physicsService.sensitivity = value
    }
    
    /// Explicitly set the current airplane for physics updates.
    /// Call during scene setup to ensure the airplane is registered before the frame loop.
    /// - Parameter airplane: The paper airplane to apply physics to, or nil to clear
    func setCurrentAirplane(_ airplane: PaperAirplane?) {
        physicsService.setCurrentAirplane(airplane)
    }
    
    /// Update physics simulation with frame-synced delta time
    /// - Parameter deltaTime: Time elapsed since last frame
    func update(deltaTime: TimeInterval) {
        physicsService.update(deltaTime: deltaTime)
    }
}


