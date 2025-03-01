//
//  FlightScene.swift
//  Tiny Pilots
//
//  Created on 2025-03-01.
//

import SpriteKit
import GameplayKit
import CoreMotion

/// The main flight scene for Tiny Pilots where the player controls a paper airplane
class FlightScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - Properties
    
    // Game elements
    private var paperAirplane: PaperAirplane?
    private var cameraNode: SKCameraNode?
    private var environment: Environment?
    private var parallaxBackground: ParallaxBackground?
    
    // HUD elements
    private var speedLabel: SKLabelNode?
    private var altitudeLabel: SKLabelNode?
    private var scoreLabel: SKLabelNode?
    private var pauseButton: SKSpriteNode?
    
    // Scene management
    private var lastUpdateTime: TimeInterval = 0
    private var isPaused: Bool = false
    private var distanceTraveled: CGFloat = 0
    private var gameMode: GameManager.GameMode = .freeFlight
    
    // Collision categories
    struct PhysicsCategory {
        static let none: UInt32 = 0
        static let airplane: UInt32 = 0x1 << 0
        static let obstacle: UInt32 = 0x1 << 1
        static let collectible: UInt32 = 0x1 << 2
        static let ground: UInt32 = 0x1 << 3
        static let boundary: UInt32 = 0x1 << 4
    }
    
    // MARK: - Initialization
    
    /// Initialize with a specific game mode
    init(size: CGSize, mode: GameManager.GameMode) {
        self.gameMode = mode
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Scene Lifecycle
    
    override func didMove(to view: SKView) {
        // Set up physics world
        setupPhysicsWorld()
        
        // Set up scene elements
        setupCamera()
        setupEnvironment()
        setupAirplane()
        setupHUD()
        
        // Start physics simulation
        PhysicsManager.shared.startPhysicsSimulation()
        
        // Set initial wind for the environment
        setupWind()
        
        // Start the game
        GameManager.shared.startNewGame(mode: gameMode)
    }
    
    override func willMove(from view: SKView) {
        // Stop physics simulation when leaving the scene
        PhysicsManager.shared.stopPhysicsSimulation()
    }
    
    // MARK: - Setup Methods
    
    /// Set up the physics world for the scene
    private func setupPhysicsWorld() {
        // Configure physics world through the PhysicsManager
        PhysicsManager.shared.configurePhysicsWorld(for: self)
        
        // Set this scene as the physics contact delegate
        physicsWorld.contactDelegate = self
    }
    
    /// Set up the camera that follows the airplane
    private func setupCamera() {
        cameraNode = SKCameraNode()
        if let cameraNode = cameraNode {
            addChild(cameraNode)
            camera = cameraNode
            
            // Set initial camera position
            cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        }
    }
    
    /// Set up the player's paper airplane
    private func setupAirplane() {
        // Create the paper airplane using the active airplane from GameManager or create a new one
        if let activeAirplane = GameManager.shared.activeAirplane {
            paperAirplane = activeAirplane
        } else {
            paperAirplane = PaperAirplane()
            GameManager.shared.activeAirplane = paperAirplane
        }
        
        // Position the airplane
        if let paperAirplane = paperAirplane {
            // Set initial position
            paperAirplane.node.position = CGPoint(x: size.width * 0.3, y: size.height * 0.7)
            
            // Set initial rotation (facing slightly upward)
            paperAirplane.node.zRotation = -CGFloat.pi * 0.05
            
            // Add to scene
            addChild(paperAirplane.node)
            
            // Apply initial thrust to get the airplane moving
            paperAirplane.applyThrust(amount: 50.0)
        }
    }
    
    /// Set up the environment elements (ground, obstacles, etc.)
    private func setupEnvironment() {
        // Get the active environment from GameManager or create a new one
        if let activeEnvironment = GameManager.shared.activeEnvironment {
            environment = activeEnvironment
        } else {
            environment = Environment(type: GameManager.shared.currentEnvironmentType)
            GameManager.shared.activeEnvironment = environment
        }
        
        guard let environment = environment else { return }
        
        // Set the background color based on environment
        backgroundColor = environment.skyColor
        
        // Create ground with environment texture
        let groundHeight: CGFloat = 100.0
        let groundNode = SKSpriteNode(color: environment.groundColor, size: CGSize(width: size.width * 3, height: groundHeight))
        
        // Apply ground texture if available
        if let groundTexture = environment.groundTexture {
            groundTexture.filteringMode = .nearest
            groundNode.texture = groundTexture
            groundNode.texture?.filteringMode = .nearest
        }
        
        groundNode.position = CGPoint(x: size.width / 2, y: groundHeight / 2)
        groundNode.zPosition = -5
        
        // Set up ground physics
        let groundPhysicsBody = SKPhysicsBody(rectangleOf: groundNode.size)
        groundPhysicsBody.isDynamic = false
        groundPhysicsBody.categoryBitMask = PhysicsCategory.ground
        groundPhysicsBody.collisionBitMask = PhysicsCategory.airplane
        groundPhysicsBody.contactTestBitMask = PhysicsCategory.airplane
        groundNode.physicsBody = groundPhysicsBody
        
        addChild(groundNode)
        
        // Create sky background with environment texture
        let skyNode = SKSpriteNode(color: environment.skyColor, size: size)
        if let backgroundTexture = environment.backgroundTexture {
            backgroundTexture.filteringMode = .nearest
            skyNode.texture = backgroundTexture
        }
        skyNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        skyNode.zPosition = -10
        addChild(skyNode)
        
        // Set up parallax background
        setupParallaxBackground()
        
        // Add clouds based on environment
        addClouds()
        
        // Add obstacles based on the current environment
        addObstacles()
        
        // Add collectibles
        addCollectibles()
        
        // Add world boundaries to keep the airplane within playable area
        addWorldBoundaries()
        
        // Play ambient sound if available
        if let ambientSound = environment.ambientSound {
            let soundAction = SKAction.playSoundFileNamed(ambientSound, waitForCompletion: false)
            let loopAction = SKAction.repeatForever(soundAction)
            run(loopAction, withKey: "ambientSound")
        }
    }
    
    /// Set up the parallax background with environment layers
    private func setupParallaxBackground() {
        guard let environment = environment else { return }
        
        // Create parallax background manager
        parallaxBackground = ParallaxBackground(parent: self, size: size)
        parallaxBackground?.setup(with: environment.parallaxLayers)
    }
    
    /// Add cloud decorations to the scene
    private func addClouds() {
        guard let environment = environment else { return }
        
        // Add several clouds at random positions
        for _ in 0..<15 {
            let cloudWidth = CGFloat.random(in: 100...300)
            let cloudHeight = CGFloat.random(in: 50...150)
            
            // Create cloud sprite
            let cloud = SKSpriteNode(color: .white, size: CGSize(width: cloudWidth, height: cloudHeight))
            cloud.alpha = 0.8
            cloud.position = CGPoint(
                x: CGFloat.random(in: 0...(size.width * 3)),
                y: CGFloat.random(in: (size.height * 0.3)...(size.height * 0.9))
            )
            cloud.zPosition = -8
            
            // Add some visual interest with a subtle animation
            let scaleAction = SKAction.sequence([
                SKAction.scale(by: 1.05, duration: 2.0),
                SKAction.scale(by: 0.95, duration: 2.0)
            ])
            cloud.run(SKAction.repeatForever(scaleAction))
            
            // Add to parallax background with appropriate scroll speed
            parallaxBackground?.addCloud(at: cloud.position, size: cloud.size, speed: 0.1)
        }
    }
    
    /// Add obstacles to the scene based on the current environment
    private func addObstacles() {
        guard let environment = environment else { return }
        
        // Add obstacles based on the environment type
        for i in 1...10 {
            // Get a random obstacle type for this environment
            let obstacleType = environment.getRandomObstacleType()
            let obstacle = Obstacle(type: obstacleType)
            
            // Position the obstacle
            let xPos = size.width * 0.5 + CGFloat(i) * 300
            let yPos = size.height * CGFloat.random(in: 0.2...0.6)
            obstacle.position(at: CGPoint(x: xPos, y: yPos))
            
            // Apply visual effects
            obstacle.applyVisualEffects()
            
            // Add to scene
            addChild(obstacle.node)
        }
    }
    
    /// Add collectible items to the scene
    private func addCollectibles() {
        guard let environment = environment else { return }
        
        // Add collectibles based on the environment type
        for i in 1...15 {
            // Get a random collectible type for this environment
            let collectibleType = environment.getRandomCollectibleType()
            let collectible = Collectible(type: collectibleType)
            
            // Position the collectible
            let xPos = size.width * 0.5 + CGFloat(i) * 200
            let yPos = size.height * CGFloat.random(in: 0.3...0.8)
            collectible.position(at: CGPoint(x: xPos, y: yPos))
            
            // Add to scene
            addChild(collectible.node)
        }
    }
    
    /// Add world boundaries to keep the airplane within the playable area
    private func addWorldBoundaries() {
        // Create invisible boundaries at the top and bottom of the screen
        let topBoundary = SKNode()
        topBoundary.position = CGPoint(x: size.width / 2, y: size.height + 50)
        topBoundary.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width * 3, height: 100))
        topBoundary.physicsBody?.isDynamic = false
        topBoundary.physicsBody?.categoryBitMask = PhysicsCategory.boundary
        topBoundary.physicsBody?.collisionBitMask = PhysicsCategory.airplane
        topBoundary.physicsBody?.contactTestBitMask = PhysicsCategory.airplane
        addChild(topBoundary)
        
        // Bottom boundary is handled by the ground
    }
    
    /// Set up the heads-up display (HUD)
    private func setupHUD() {
        // Create speed label
        speedLabel = SKLabelNode(text: "Speed: 0")
        speedLabel?.fontName = "AvenirNext-Bold"
        speedLabel?.fontSize = 18
        speedLabel?.fontColor = .white
        speedLabel?.horizontalAlignmentMode = .left
        speedLabel?.position = CGPoint(x: 20, y: size.height - 30)
        cameraNode?.addChild(speedLabel!)
        
        // Create altitude label
        altitudeLabel = SKLabelNode(text: "Altitude: 0")
        altitudeLabel?.fontName = "AvenirNext-Bold"
        altitudeLabel?.fontSize = 18
        altitudeLabel?.fontColor = .white
        altitudeLabel?.horizontalAlignmentMode = .left
        altitudeLabel?.position = CGPoint(x: 20, y: size.height - 60)
        cameraNode?.addChild(altitudeLabel!)
        
        // Create score label
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel?.fontName = "AvenirNext-Bold"
        scoreLabel?.fontSize = 18
        scoreLabel?.fontColor = .white
        scoreLabel?.horizontalAlignmentMode = .left
        scoreLabel?.position = CGPoint(x: 20, y: size.height - 90)
        cameraNode?.addChild(scoreLabel!)
        
        // Create pause button
        pauseButton = SKSpriteNode(color: .white, size: CGSize(width: 40, height: 40))
        pauseButton?.position = CGPoint(x: size.width - 40, y: size.height - 40)
        pauseButton?.name = "pauseButton"
        cameraNode?.addChild(pauseButton!)
    }
    
    /// Set up wind effects for the current environment
    private func setupWind() {
        guard let environment = environment else { return }
        
        // Get random wind direction and strength based on environment
        let (windDirection, windStrength) = environment.getRandomWind()
        
        // Set wind vector in physics manager
        PhysicsManager.shared.setWindVector(direction: windDirection, strength: windStrength)
        
        // Add wind particle effects
        addWindParticles()
    }
    
    /// Add wind particle effects to visualize wind direction
    private func addWindParticles() {
        guard let environment = environment else { return }
        
        // Create wind particles at different positions based on environment
        for _ in 0..<5 {
            if let windParticle = SKEmitterNode(fileNamed: "WindParticle") {
                // Position randomly within the scene
                windParticle.position = CGPoint(
                    x: CGFloat.random(in: 0...(size.width * 3)),
                    y: CGFloat.random(in: (size.height * 0.2)...(size.height * 0.8))
                )
                
                // Adjust particle direction based on wind vector
                let windVector = PhysicsManager.shared.windVector
                if let windAngle = atan2(windVector.dy, windVector.dx) as CGFloat? {
                    // Convert to degrees and adjust emitter angle
                    let angleDegrees = windAngle * 180 / .pi
                    windParticle.emissionAngle = angleDegrees
                    
                    // Adjust particle speed based on wind strength
                    if let windStrength = windVector.length {
                        windParticle.particleSpeed = windStrength * 2
                    }
                }
                
                // Adjust particle properties based on environment
                switch environment.weatherCondition {
                case .clear:
                    windParticle.particleBirthRate *= 0.5
                case .lightWind:
                    // Default settings
                    break
                case .strongWind:
                    windParticle.particleBirthRate *= 2.0
                    windParticle.particleLifetime *= 1.5
                case .variable:
                    // Random variation
                    windParticle.particleBirthRate *= CGFloat.random(in: 0.5...2.0)
                }
                
                // Add to scene
                windParticle.zPosition = -6
                addChild(windParticle)
            }
        }
    }
    
    // MARK: - Update Methods
    
    override func update(_ currentTime: TimeInterval) {
        // Skip update if game is paused
        if isPaused || GameManager.shared.currentState != .playing {
            return
        }
        
        // Calculate time since last update
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Update game elements
        updateAirplane(deltaTime: dt)
        updateCamera()
        updateHUD()
        updateGameState(deltaTime: dt)
        updateParallaxBackground()
        
        // Occasionally update wind to create variation
        if Int.random(in: 0...100) < 2 { // 2% chance per frame
            updateRandomWind()
        }
    }
    
    /// Update the paper airplane's state
    private func updateAirplane(deltaTime: TimeInterval) {
        guard let paperAirplane = paperAirplane, let physicsBody = paperAirplane.node.physicsBody else { return }
        
        // Calculate current speed
        let velocity = physicsBody.velocity
        let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        paperAirplane.speed = speed
        
        // Update distance traveled
        if speed > 0 {
            distanceTraveled += speed * CGFloat(deltaTime)
            GameManager.shared.sessionData.distance = Float(distanceTraveled / 100.0) // Convert to meters for game purposes
        }
        
        // Apply lift force based on current speed and airplane properties
        paperAirplane.applyLift()
        
        // Check if airplane is below minimum speed (stalling)
        if speed < paperAirplane.minSpeed {
            // Apply a small downward force to simulate stalling
            let stallForce = CGVector(dx: 0, dy: -10.0)
            physicsBody.applyForce(stallForce)
        }
        
        // Apply air resistance based on speed
        let airResistance = GameConfig.Physics.airResistance
        let resistanceForce = CGVector(
            dx: -velocity.dx * airResistance,
            dy: -velocity.dy * airResistance
        )
        physicsBody.applyForce(resistanceForce)
        
        // Update airplane rotation to match velocity direction for more realistic flight
        if speed > paperAirplane.minSpeed {
            let targetAngle = atan2(velocity.dy, velocity.dx)
            let currentAngle = paperAirplane.node.zRotation
            
            // Smoothly rotate to target angle
            let rotationSpeed: CGFloat = 2.0
            let angleDifference = targetAngle - currentAngle
            
            // Normalize angle difference to [-π, π]
            var normalizedDifference = angleDifference
            while normalizedDifference > .pi {
                normalizedDifference -= 2 * .pi
            }
            while normalizedDifference < -.pi {
                normalizedDifference += 2 * .pi
            }
            
            // Apply rotation based on difference
            paperAirplane.node.zRotation += normalizedDifference * rotationSpeed * CGFloat(deltaTime)
        }
    }
    
    /// Update the camera to follow the airplane
    private func updateCamera() {
        guard let paperAirplane = paperAirplane, let cameraNode = cameraNode else { return }
        
        // Calculate target position (slightly ahead of the airplane in the direction of travel)
        let airplanePosition = paperAirplane.node.position
        let velocity = paperAirplane.node.physicsBody?.velocity ?? CGVector(dx: 0, dy: 0)
        let lookAheadDistance: CGFloat = 200.0
        
        // Normalize velocity vector
        let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        let normalizedVelocity = speed > 0 ? CGVector(dx: velocity.dx / speed, dy: velocity.dy / speed) : CGVector(dx: 1, dy: 0)
        
        // Calculate target position
        let targetX = airplanePosition.x + normalizedVelocity.dx * lookAheadDistance
        let targetY = airplanePosition.y + normalizedVelocity.dy * lookAheadDistance
        
        // Smoothly move camera to target position
        let smoothingFactor: CGFloat = 0.1
        let newX = cameraNode.position.x + (targetX - cameraNode.position.x) * smoothingFactor
        let newY = cameraNode.position.y + (targetY - cameraNode.position.y) * smoothingFactor
        
        cameraNode.position = CGPoint(x: newX, y: newY)
    }
    
    /// Update the HUD elements
    private func updateHUD() {
        guard let paperAirplane = paperAirplane else { return }
        
        // Update speed label
        let speedKmh = Int(paperAirplane.speed * 0.1) // Convert to km/h for display
        speedLabel?.text = "Speed: \(speedKmh) km/h"
        
        // Update altitude label
        let altitude = Int(paperAirplane.node.position.y)
        altitudeLabel?.text = "Altitude: \(altitude) m"
        
        // Update score label
        let score = GameManager.shared.sessionData.score
        scoreLabel?.text = "Score: \(score)"
    }
    
    /// Update the overall game state
    private func updateGameState(deltaTime: TimeInterval) {
        // Update session time
        GameManager.shared.sessionData.timeElapsed += deltaTime
        
        // Check for game over conditions
        checkGameOverConditions()
    }
    
    /// Check if any game over conditions are met
    private func checkGameOverConditions() {
        guard let paperAirplane = paperAirplane else { return }
        
        // Check if airplane is too low (crashed)
        if paperAirplane.node.position.y < 50 {
            gameOver(reason: "Crashed")
        }
        
        // Check if airplane is out of bounds
        if paperAirplane.node.position.x < -500 || paperAirplane.node.position.x > size.width * 3 + 500 {
            gameOver(reason: "Out of bounds")
        }
    }
    
    /// Handle game over
    private func gameOver(reason: String) {
        // End the game
        GameManager.shared.endGame()
        
        // Show game over message
        let gameOverLabel = SKLabelNode(text: "Game Over: \(reason)")
        gameOverLabel.fontName = "AvenirNext-Bold"
        gameOverLabel.fontSize = 36
        gameOverLabel.fontColor = .white
        gameOverLabel.position = CGPoint(x: 0, y: 0)
        cameraNode?.addChild(gameOverLabel)
        
        // Add restart button
        let restartButton = SKSpriteNode(color: .white, size: CGSize(width: 200, height: 60))
        restartButton.position = CGPoint(x: 0, y: -100)
        restartButton.name = "restartButton"
        
        let restartLabel = SKLabelNode(text: "Restart")
        restartLabel.fontName = "AvenirNext-Bold"
        restartLabel.fontSize = 24
        restartLabel.fontColor = .blue
        restartLabel.verticalAlignmentMode = .center
        restartButton.addChild(restartLabel)
        
        cameraNode?.addChild(restartButton)
        
        // Add menu button
        let menuButton = SKSpriteNode(color: .white, size: CGSize(width: 200, height: 60))
        menuButton.position = CGPoint(x: 0, y: -180)
        menuButton.name = "menuButton"
        
        let menuLabel = SKLabelNode(text: "Main Menu")
        menuLabel.fontName = "AvenirNext-Bold"
        menuLabel.fontSize = 24
        menuLabel.fontColor = .blue
        menuLabel.verticalAlignmentMode = .center
        menuButton.addChild(menuLabel)
        
        cameraNode?.addChild(menuButton)
    }
    
    /// Update the parallax background based on camera position
    private func updateParallaxBackground() {
        guard let cameraNode = cameraNode else { return }
        parallaxBackground?.update(withCameraPosition: cameraNode.position)
    }
    
    /// Update wind with random variations based on environment
    private func updateRandomWind() {
        guard let environment = environment else { return }
        
        // Get new random wind based on environment
        let (windDirection, windStrength) = environment.getRandomWind()
        
        // Gradually transition to new wind
        PhysicsManager.shared.transitionWindVector(
            toDirection: windDirection,
            strength: windStrength,
            duration: 3.0
        )
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Convert touch location to camera's coordinate space for HUD elements
        let locationInCamera = convertPoint(fromScene: location)
        
        // Check if pause button was tapped
        if let pauseButton = pauseButton, pauseButton.contains(locationInCamera) {
            togglePause()
            return
        }
        
        // Check if restart button was tapped
        if GameManager.shared.currentState == .gameOver {
            let nodes = self.nodes(at: locationInCamera)
            for node in nodes {
                if node.name == "restartButton" {
                    restartGame()
                    return
                } else if node.name == "menuButton" {
                    returnToMainMenu()
                    return
                }
            }
        }
        
        // If game is playing, apply a small upward thrust on tap (optional touch control)
        if GameManager.shared.currentState == .playing && !isPaused {
            paperAirplane?.applyThrust(amount: 30.0)
        }
    }
    
    /// Toggle pause state
    private func togglePause() {
        isPaused = !isPaused
        
        if isPaused {
            // Pause the game
            GameManager.shared.pauseGame()
            PhysicsManager.shared.stopPhysicsSimulation()
            
            // Show pause menu
            showPauseMenu()
        } else {
            // Resume the game
            GameManager.shared.resumeGame()
            PhysicsManager.shared.startPhysicsSimulation()
            
            // Hide pause menu
            hidePauseMenu()
        }
    }
    
    /// Show the pause menu
    private func showPauseMenu() {
        // Create pause menu background
        let pauseBackground = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.5), size: size)
        pauseBackground.position = CGPoint.zero
        pauseBackground.name = "pauseBackground"
        
        // Create resume button
        let resumeButton = SKSpriteNode(color: .white, size: CGSize(width: 200, height: 60))
        resumeButton.position = CGPoint(x: 0, y: 50)
        resumeButton.name = "resumeButton"
        
        let resumeLabel = SKLabelNode(text: "Resume")
        resumeLabel.fontName = "AvenirNext-Bold"
        resumeLabel.fontSize = 24
        resumeLabel.fontColor = .blue
        resumeLabel.verticalAlignmentMode = .center
        resumeButton.addChild(resumeLabel)
        
        // Create main menu button
        let menuButton = SKSpriteNode(color: .white, size: CGSize(width: 200, height: 60))
        menuButton.position = CGPoint(x: 0, y: -50)
        menuButton.name = "menuButton"
        
        let menuLabel = SKLabelNode(text: "Main Menu")
        menuLabel.fontName = "AvenirNext-Bold"
        menuLabel.fontSize = 24
        menuLabel.fontColor = .blue
        menuLabel.verticalAlignmentMode = .center
        menuButton.addChild(menuLabel)
        
        // Add to camera
        pauseBackground.addChild(resumeButton)
        pauseBackground.addChild(menuButton)
        cameraNode?.addChild(pauseBackground)
    }
    
    /// Hide the pause menu
    private func hidePauseMenu() {
        cameraNode?.childNode(withName: "pauseBackground")?.removeFromParent()
    }
    
    /// Restart the game
    private func restartGame() {
        // Create a new flight scene with the same game mode
        if let view = view {
            let newScene = FlightScene(size: size, mode: gameMode)
            newScene.scaleMode = scaleMode
            view.presentScene(newScene, transition: SKTransition.fade(withDuration: 0.5))
        }
    }
    
    /// Return to the main menu
    private func returnToMainMenu() {
        // Create a new main menu scene
        if let view = view {
            let menuScene = MainMenuScene(size: size)
            menuScene.scaleMode = scaleMode
            view.presentScene(menuScene, transition: SKTransition.fade(withDuration: 0.5))
        }
    }
    
    // MARK: - Physics Contact Delegate
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Sort the bodies by category
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // Handle different collision types
        
        // Airplane collided with obstacle
        if (firstBody.categoryBitMask & PhysicsCategory.airplane != 0) &&
           (secondBody.categoryBitMask & PhysicsCategory.obstacle != 0) {
            handleObstacleCollision(airplane: firstBody.node!, obstacle: secondBody.node!)
        }
        
        // Airplane collided with collectible
        if (firstBody.categoryBitMask & PhysicsCategory.airplane != 0) &&
           (secondBody.categoryBitMask & PhysicsCategory.collectible != 0) {
            handleCollectibleCollection(airplane: firstBody.node!, collectible: secondBody.node!)
        }
        
        // Airplane collided with ground
        if (firstBody.categoryBitMask & PhysicsCategory.airplane != 0) &&
           (secondBody.categoryBitMask & PhysicsCategory.ground != 0) {
            handleGroundCollision(airplane: firstBody.node!, ground: secondBody.node!)
        }
    }
    
    /// Handle collision between airplane and obstacle
    private func handleObstacleCollision(airplane: SKNode, obstacle: SKNode) {
        // Apply impact effect to the airplane
        paperAirplane?.handleImpact()
        
        // Increment obstacles avoided counter (for scoring)
        GameManager.shared.sessionData.obstaclesAvoided += 1
        
        // Visual feedback
        let flashAction = SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.5, duration: 0.1),
            SKAction.colorize(with: .white, colorBlendFactor: 0.0, duration: 0.1)
        ])
        obstacle.run(flashAction)
    }
    
    /// Handle collection of a collectible item
    private func handleCollectibleCollection(airplane: SKNode, collectible: SKNode) {
        // Find the collectible object
        if let collectibleNode = collectible as? SKSpriteNode,
           let collectibleName = collectibleNode.name,
           collectibleName.hasPrefix("collectible_") {
            
            // Call the collect method on the Collectible object
            for child in children {
                if child === collectibleNode {
                    // Find the collectible type from the node name
                    let typeName = collectibleName.replacingOccurrences(of: "collectible_", with: "")
                    
                    // Determine point value based on type
                    var pointValue = 10 // Default value
                    
                    if typeName == "star" {
                        pointValue = 10
                    } else if typeName == "coin" {
                        pointValue = 5
                    } else if typeName == "gem" {
                        pointValue = 20
                    } else if typeName == "shell" {
                        pointValue = 15
                    }
                    
                    // Update game data
                    GameManager.shared.sessionData.collectiblesGathered += 1
                    GameManager.shared.sessionData.score += pointValue
                    
                    // Visual and audio feedback
                    let collectAction = SKAction.group([
                        SKAction.scale(to: 1.5, duration: 0.2),
                        SKAction.fadeOut(withDuration: 0.2)
                    ])
                    
                    collectible.run(SKAction.sequence([
                        collectAction,
                        SKAction.removeFromParent()
                    ]))
                    
                    break
                }
            }
        }
    }
    
    /// Handle collision between airplane and ground
    private func handleGroundCollision(airplane: SKNode, ground: SKNode) {
        // End the game if the airplane hits the ground
        gameOver(reason: "Crashed")
    }
} 