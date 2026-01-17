import Foundation
import SpriteKit
import CoreMotion

/// Protocol defining physics service functionality
protocol PhysicsServiceProtocol {
    /// Current wind vector in the environment
    var windVector: CGVector { get }
    
    /// Sensitivity of tilt controls (adjustable by player)
    var sensitivity: CGFloat { get set }
    
    /// Whether physics simulation is active
    var isActive: Bool { get }
    
    /// Configure the physics world for a given scene
    /// - Parameter scene: The SpriteKit scene to configure
    func configurePhysicsWorld(for scene: SKScene)
    
    /// Start device motion updates for tilt control
    func startDeviceMotionUpdates()
    
    /// Stop device motion updates
    func stopDeviceMotionUpdates()
    
    /// Start custom physics simulation
    func startPhysicsSimulation()
    
    /// Stop custom physics simulation
    func stopPhysicsSimulation()
    
    /// Explicitly set the current airplane for physics updates.
    /// Call during scene setup to ensure the airplane is registered before the frame loop.
    /// - Parameter airplane: The paper airplane to apply physics to, or nil to clear
    func setCurrentAirplane(_ airplane: PaperAirplane?)
    
    /// Update physics simulation with frame-synced delta time
    /// - Parameter deltaTime: Time elapsed since last frame
    func update(deltaTime: TimeInterval)
    
    /// Apply forces to an airplane based on tilt input
    /// - Parameters:
    ///   - airplane: The paper airplane to apply forces to
    ///   - tiltX: Horizontal tilt value (-1.0 to 1.0)
    ///   - tiltY: Vertical tilt value (-1.0 to 1.0)
    func applyForces(to airplane: PaperAirplane, tiltX: CGFloat, tiltY: CGFloat)
    
    /// Calculate lift force for an airplane based on its current state
    /// - Parameter airplane: The paper airplane to calculate lift for
    /// - Returns: The lift force value
    func calculateLift(for airplane: PaperAirplane) -> CGFloat
    
    /// Handle collision between two physics bodies
    /// - Parameters:
    ///   - nodeA: First collision node
    ///   - nodeB: Second collision node
    func handleCollision(between nodeA: SKNode, and nodeB: SKNode)
    
    /// Set wind vector for the current environment
    /// - Parameters:
    ///   - direction: Wind direction in degrees
    ///   - strength: Wind strength
    func setWindVector(direction: CGFloat, strength: CGFloat)
    
    /// Apply wind effects to an airplane
    /// - Parameter airplane: The airplane to apply wind effects to
    func applyWind(to airplane: PaperAirplane)
    
    /// Update wind strength and direction randomly for natural variation
    func updateRandomWind()
    
    /// Gradually transition wind vector to new parameters
    /// - Parameters:
    ///   - direction: Target wind direction in degrees
    ///   - strength: Target wind strength
    ///   - duration: Duration of the transition in seconds
    func transitionWindVector(toDirection direction: CGFloat, strength: CGFloat, duration: TimeInterval)
    
    /// Apply advanced flight controls for nuanced airplane handling
    /// - Parameters:
    ///   - airplane: The airplane to apply controls to
    ///   - motion: Device motion data
    func applyAdvancedFlightControls(to airplane: PaperAirplane, motion: CMDeviceMotion)
    
    /// Apply turbulence effects to simulate air pockets and wind gusts
    /// - Parameter airplane: The airplane to apply turbulence to
    func applyTurbulence(to airplane: PaperAirplane)
}

/// Physics service errors
enum PhysicsServiceError: Error, LocalizedError {
    case deviceMotionUnavailable
    case physicsBodyNotFound
    case invalidParameters(String)
    
    var errorDescription: String? {
        switch self {
        case .deviceMotionUnavailable:
            return "Device motion is not available on this device"
        case .physicsBodyNotFound:
            return "Physics body not found for the specified node"
        case .invalidParameters(let details):
            return "Invalid physics parameters: \(details)"
        }
    }
}