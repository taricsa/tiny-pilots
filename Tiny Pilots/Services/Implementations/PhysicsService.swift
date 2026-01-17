import Foundation
import SpriteKit
import CoreMotion

/// Implementation of PhysicsServiceProtocol
class PhysicsService: PhysicsServiceProtocol {
    
    // MARK: - Properties
    
    /// The motion manager for device tilt detection
    private let motionManager = CMMotionManager()
    
    /// Current wind vector in the environment
    private(set) var windVector = CGVector(dx: 0, dy: 0)
    
    /// Sensitivity of tilt controls (adjustable by player)
    var sensitivity: CGFloat {
        get { _sensitivity }
        set { _sensitivity = max(0.1, min(2.0, newValue)) }
    }
    private var _sensitivity: CGFloat = 1.0
    
    /// Flag indicating if physics simulation is active
    private(set) var isActive = false
    
    /// Weak reference to the current airplane for physics updates
    private weak var currentAirplane: PaperAirplane?
    
    // MARK: - Initialization
    
    init() {
        // Set up motion manager
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 Hz update rate
    }
    
    deinit {
        stopPhysicsSimulation()
    }
    
    // MARK: - Physics World Configuration
    
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
    
    func stopDeviceMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    /// Process tilt control from device motion
    private func processTiltControl(motion: CMDeviceMotion) {
        guard let airplane = currentAirplane else { return }
        
        // Get roll (tilting left/right)
        let roll = motion.attitude.roll
        
        // Get pitch (tilting forward/backward)
        let pitch = motion.attitude.pitch
        
        // Normalize values to range [-1, 1]
        let maxTiltAngle: CGFloat = CGFloat.pi / 4 // 45 degrees
        let normalizedRoll = CGFloat(max(-1.0, min(1.0, Double(roll) / Double(maxTiltAngle))))
        let normalizedPitch = CGFloat(max(-1.0, min(1.0, Double(pitch) / Double(maxTiltAngle))))
        
        // Apply forces based on tilt
        applyForces(to: airplane, tiltX: normalizedRoll, tiltY: normalizedPitch)
        
        // Apply advanced flight controls
        applyAdvancedFlightControls(to: airplane, motion: motion)
    }
    
    // MARK: - Physics Simulation
    
    func startPhysicsSimulation() {
        guard !isActive else { return }
        
        isActive = true
        
        // Start device motion for tilt control
        startDeviceMotionUpdates()
    }
    
    func stopPhysicsSimulation() {
        guard isActive else { return }
        
        isActive = false
        
        // Stop device motion updates
        stopDeviceMotionUpdates()
        
        // Clear airplane reference
        currentAirplane = nil
    }
    
    /// Update physics simulation with frame-synced delta time
    /// This method should be called from the scene's update(_:) method
    /// - Parameter deltaTime: Time elapsed since last frame
    func update(deltaTime: TimeInterval) {
        guard isActive, let airplane = currentAirplane else { return }
        
        // Update the airplane's visual state
        airplane.updateVisualState()
        
        // Apply wind effects
        applyWind(to: airplane)
    }
    
    // MARK: - Force Application
    
    func applyForces(to airplane: PaperAirplane, tiltX: CGFloat, tiltY: CGFloat) {
        guard let physicsBody = airplane.physicsBody else { return }
        
        // Store reference to current airplane
        currentAirplane = airplane
        
        // Calculate force based on tilt with sensitivity
        let forceMultiplier: CGFloat = 50.0 * sensitivity
        let xForce = tiltX * forceMultiplier
        let yForce = tiltY * forceMultiplier
        
        // Apply main force
        physicsBody.applyForce(CGVector(dx: xForce, dy: yForce))
        
        // Apply constant forward thrust
        let baseThrust: CGFloat = 20.0 * sensitivity
        physicsBody.applyForce(CGVector(dx: baseThrust, dy: 0))
        
        // Apply lift based on velocity
        let liftForce = calculateLift(for: airplane)
        physicsBody.applyForce(CGVector(dx: 0, dy: liftForce))
    }
    
    func calculateLift(for airplane: PaperAirplane) -> CGFloat {
        guard let physicsBody = airplane.physicsBody else { return 0 }
        
        let velocity = physicsBody.velocity
        let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        
        // Get fold type multiplier for lift calculation
        let foldMultiplier = airplane.fold.physicsMultiplier.lift
        
        // Calculate lift force based on speed and airplane characteristics
        let baseLiftForce = speed * 0.2 * foldMultiplier * sensitivity
        
        // Apply additional lift based on airplane orientation
        // More lift when airplane is angled upward
        let orientationLift = sin(airplane.zRotation) * 10.0
        
        return baseLiftForce + orientationLift
    }
    
    func handleCollision(between nodeA: SKNode, and nodeB: SKNode) {
        // Determine collision types
        guard let bodyA = nodeA.physicsBody,
              let bodyB = nodeB.physicsBody else { return }
        
        let categoryA = bodyA.categoryBitMask
        let categoryB = bodyB.categoryBitMask
        
        // Handle airplane collisions
        if categoryA == PhysicsCategory.airplane || categoryB == PhysicsCategory.airplane {
            let airplane = (categoryA == PhysicsCategory.airplane) ? nodeA : nodeB
            let other = (categoryA == PhysicsCategory.airplane) ? nodeB : nodeA
            let otherCategory = (categoryA == PhysicsCategory.airplane) ? categoryB : categoryA
            
            handleAirplaneCollision(airplane: airplane, with: other, category: otherCategory)
        }
    }
    
    /// Handle specific airplane collision scenarios
    private func handleAirplaneCollision(airplane: SKNode, with other: SKNode, category: UInt32) {
        guard let airplaneBody = airplane.physicsBody else { return }
        
        switch category {
        case PhysicsCategory.obstacle:
            // Reduce velocity on obstacle collision
            let dampingFactor: CGFloat = 0.5
            airplaneBody.velocity = CGVector(
                dx: airplaneBody.velocity.dx * dampingFactor,
                dy: airplaneBody.velocity.dy * dampingFactor
            )
            
            // Apply bounce effect
            let bounceForce = CGVector(dx: -airplaneBody.velocity.dx * 0.3, dy: 50)
            airplaneBody.applyImpulse(bounceForce)
            
        case PhysicsCategory.ground:
            // Handle ground collision
            if airplaneBody.velocity.dy < -100 { // Hard landing
                // Significant velocity reduction
                airplaneBody.velocity = CGVector(
                    dx: airplaneBody.velocity.dx * 0.2,
                    dy: max(airplaneBody.velocity.dy * 0.1, -50)
                )
            } else { // Soft landing
                // Gentle bounce
                airplaneBody.velocity = CGVector(
                    dx: airplaneBody.velocity.dx * 0.8,
                    dy: abs(airplaneBody.velocity.dy) * 0.3
                )
            }
            
        case PhysicsCategory.collectible:
            // Collectibles don't affect airplane physics
            break
            
        default:
            break
        }
    }
    
    // MARK: - Wind Effects
    
    func setWindVector(direction: CGFloat, strength: CGFloat) {
        // Convert direction (in degrees) to radians
        let radians = direction * CGFloat.pi / 180.0
        
        // Create wind vector using direction and strength
        windVector = CGVector(
            dx: cos(radians) * strength,
            dy: sin(radians) * strength
        )
    }
    
    func applyWind(to airplane: PaperAirplane) {
        guard let physicsBody = airplane.physicsBody else { return }
        
        // Apply wind force
        // Wind effect depends on the airplane's drag coefficient
        let foldMultiplier = airplane.fold.physicsMultiplier.drag
        let windEffect = CGVector(
            dx: windVector.dx * 0.5 * foldMultiplier,
            dy: windVector.dy * 0.5 * foldMultiplier
        )
        
        physicsBody.applyForce(windEffect)
        
        // Apply turbulence effect for more realistic wind
        applyTurbulence(to: airplane)
    }
    
    func applyTurbulence(to airplane: PaperAirplane) {
        guard let physicsBody = airplane.physicsBody else { return }
        
        // Only apply turbulence occasionally (5% chance per update)
        if Int.random(in: 0...100) < 5 {
            // Calculate turbulence strength based on wind strength
            let windStrength = sqrt(windVector.dx * windVector.dx + windVector.dy * windVector.dy)
            let turbulenceStrength = windStrength * CGFloat.random(in: 0.5...1.5)
            
            // Apply random turbulence force
            let turbulenceForce = CGVector(
                dx: CGFloat.random(in: -1.0...1.0) * turbulenceStrength,
                dy: CGFloat.random(in: -1.0...1.0) * turbulenceStrength
            )
            
            physicsBody.applyForce(turbulenceForce)
        }
    }
    
    func updateRandomWind() {
        // Calculate current wind strength
        let currentStrength = sqrt(windVector.dx * windVector.dx + windVector.dy * windVector.dy)
        
        // If there's no wind, don't update
        guard currentStrength > 0 else { return }
        
        // Get current direction in radians
        let currentDirection = atan2(windVector.dy, windVector.dx)
        
        // Create variation in direction (convert to degrees for clarity)
        let directionVariation = CGFloat.random(in: -15...15) * CGFloat.pi / 180.0 // ±15 degrees
        let newDirection = currentDirection + directionVariation
        
        // Create variation in strength
        let strengthVariation = CGFloat.random(in: 0.8...1.2)
        let newStrength = max(0, min(currentStrength * strengthVariation, 100)) // Cap at 100
        
        // Set new wind vector
        windVector = CGVector(
            dx: cos(newDirection) * newStrength,
            dy: sin(newDirection) * newStrength
        )
    }
    
    func transitionWindVector(toDirection direction: CGFloat, strength: CGFloat, duration: TimeInterval) {
        // Convert target direction to radians
        let targetRadians = direction * CGFloat.pi / 180.0
        
        // Create target wind vector
        let targetVector = CGVector(
            dx: cos(targetRadians) * strength,
            dy: sin(targetRadians) * strength
        )
        
        // Store initial wind vector
        let initialVector = windVector
        
        // Create a timer to update the wind vector gradually
        let updateInterval: TimeInterval = 0.05 // 50ms updates
        let steps = Int(duration / updateInterval)
        var currentStep = 0
        
        // Create and start the transition timer
        let transitionTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            currentStep += 1
            let progress = CGFloat(currentStep) / CGFloat(steps)
            
            // Use easing function for smoother transition
            let easedProgress = self.easeInOutQuad(progress)
            
            // Interpolate between initial and target vectors
            let newDx = initialVector.dx + (targetVector.dx - initialVector.dx) * easedProgress
            let newDy = initialVector.dy + (targetVector.dy - initialVector.dy) * easedProgress
            
            // Update wind vector
            self.windVector = CGVector(dx: newDx, dy: newDy)
            
            // Stop timer when transition is complete
            if currentStep >= steps {
                timer.invalidate()
            }
        }
        
        // Add the timer to the run loop
        RunLoop.current.add(transitionTimer, forMode: .common)
    }
    
    func applyAdvancedFlightControls(to airplane: PaperAirplane, motion: CMDeviceMotion) {
        // Get the airplane's physics body
        guard let physicsBody = airplane.physicsBody else { return }
        
        // Get current velocity
        let velocity = physicsBody.velocity
        let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        
        // Apply drag based on airplane orientation
        // More drag when perpendicular to direction of travel
        let currentRotation = airplane.zRotation
        let velocityAngle = atan2(velocity.dy, velocity.dx)
        let angleDifference = abs(currentRotation - velocityAngle)
        
        // Calculate drag factor (maximum when perpendicular)
        let dragFactor = sin(angleDifference) * 0.1 * airplane.fold.physicsMultiplier.drag
        
        // Apply drag force opposite to velocity
        let dragForce = CGVector(
            dx: -velocity.dx * dragFactor,
            dy: -velocity.dy * dragFactor
        )
        physicsBody.applyForce(dragForce)
        
        // Apply stabilization at higher speeds
        // This makes the airplane more stable as it gains speed
        if speed > 100 { // Minimum speed for stabilization
            // Get current rotation
            let currentRotation = airplane.zRotation
            
            // Calculate ideal rotation based on velocity direction
            let idealRotation = atan2(velocity.dy, velocity.dx)
            
            // Calculate difference
            var rotationDiff = idealRotation - currentRotation
            
            // Normalize to [-π, π]
            while rotationDiff > CGFloat.pi { rotationDiff -= 2 * CGFloat.pi }
            while rotationDiff < -CGFloat.pi { rotationDiff += 2 * CGFloat.pi }
            
            // Apply stabilizing torque proportional to speed and turn rate
            let stabilizationFactor = min(1.0, (speed - 100) / 100) * 0.1 * airplane.fold.physicsMultiplier.turnRate
            physicsBody.applyTorque(rotationDiff * stabilizationFactor)
        }
    }
    
    /// Easing function for smoother transitions
    private func easeInOutQuad(_ x: CGFloat) -> CGFloat {
        return x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2
    }
}