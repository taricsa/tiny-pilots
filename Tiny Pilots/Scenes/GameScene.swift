//
//  GameScene.swift
//  Tiny Pilots
//
//  Created on 2025-03-01.
//
//  ARCHITECTURE NOTE:
//  This is a modern MVVM-based implementation with dependency injection,
//  accessibility features, and performance monitoring. However, it is NOT
//  currently used in the app - FlightScene.swift is the active gameplay scene.
//
//  This file represents a potential future architecture direction. To use this:
//  1. Integrate missing features from FlightScene (challenge mode, etc.)
//  2. Update GameViewController to use GameScene instead of FlightScene
//  3. Ensure all game modes are supported
//
//  Current status: Reference implementation / Work in progress

import SpriteKit
import GameplayKit
import CoreMotion
import SwiftData

/// The main game scene for Tiny Pilots (Modern MVVM implementation - not currently in use)
class GameScene: SKScene {
    
    // MARK: - Properties
    
    /// ViewModel for managing game state and logic
    private var viewModel: GameViewModel!
    
    /// Paper airplane node
    private var airplaneNode: SKSpriteNode?
    
    /// Background nodes for parallax effect
    private var backgroundNodes: [SKNode] = []
    
    /// Obstacle nodes
    private var obstacleNodes: [SKNode] = []
    
    /// Collectible nodes
    private var collectibleNodes: [SKNode] = []
    
    /// UI overlay nodes
    private var scoreLabel: SKLabelNode?
    private var distanceLabel: SKLabelNode?
    private var timeLabel: SKLabelNode?
    private var coinsLabel: SKLabelNode?
    private var pauseButton: SKSpriteNode?
    
    /// Physics world reference
    private var gamePhysicsWorld: SKPhysicsWorld { return self.physicsWorld }
    
    /// Scene management properties
    private var lastUpdateTime: TimeInterval = 0
    private var gameStarted: Bool = false
    
    /// Optimized renderer for performance management
    private var optimizedRenderer: OptimizedRenderer?
    
    // MARK: - Scene Lifecycle
    
    override func sceneDidLoad() {
        setupScene()
        setupPhysics()
        setupUI()
        
        // Initialize ViewModel if not already set
        if viewModel == nil {
            setupViewModel()
        }
        
        // Setup optimized renderer
        setupOptimizedRenderer()
        
        // Initialize the ViewModel
        viewModel.initialize()
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        // Setup accessibility for game UI
        setupAccessibility()
        
        // Setup dynamic type observer
        setupDynamicTypeObserver()
        
        // Start observing ViewModel state changes
        startObservingViewModel()
        
        // Announce screen change for VoiceOver
        VoiceOverNavigationManager.shared.announceScreenChange("Game")
    }
    
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        
        // Clean up ViewModel
        viewModel?.cleanup()
    }
    
    // MARK: - Setup Methods
    
    /// Set the ViewModel for this scene
    /// - Parameter viewModel: The GameViewModel to use
    func setViewModel(_ viewModel: GameViewModel) {
        self.viewModel = viewModel
    }
    
    /// Setup the ViewModel using dependency injection
    private func setupViewModel() {
        do {
            let physicsService = try DIContainer.shared.resolve(PhysicsServiceProtocol.self)
            let audioService = try DIContainer.shared.resolve(AudioServiceProtocol.self)
            let gameCenterService = try DIContainer.shared.resolve(GameCenterServiceProtocol.self)
            let modelContext = try DIContainer.shared.resolve(ModelContext.self)
            
            viewModel = GameViewModel(
                physicsService: physicsService,
                audioService: audioService,
                gameCenterService: gameCenterService,
                modelContext: modelContext
            )
        } catch {
            fatalError("Failed to setup GameViewModel: \(error)")
        }
    }
    
    /// Setup the scene properties
    private func setupScene() {
        backgroundColor = SKColor.systemBlue
        
        // Setup camera
        let camera = SKCameraNode()
        self.camera = camera
        addChild(camera)
    }
    
    /// Setup physics world
    private func setupPhysics() {
        gamePhysicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        gamePhysicsWorld.contactDelegate = self
    }
    
    /// Setup UI elements
    private func setupUI() {
        setupScoreLabel()
        setupDistanceLabel()
        setupTimeLabel()
        setupCoinsLabel()
        setupPauseButton()
    }
    
    private func setupScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "Arial-Bold")
        scoreLabel?.configureDynamicType(baseSize: 24, textStyle: .title3)
        scoreLabel?.fontColor = .white
        scoreLabel?.text = "Score: 0"
        scoreLabel?.position = CGPoint(x: -size.width/2 + 100, y: size.height/2 - 50)
        scoreLabel?.zPosition = 100
        camera?.addChild(scoreLabel!)
    }
    
    private func setupDistanceLabel() {
        distanceLabel = SKLabelNode(fontNamed: "Arial-Bold")
        distanceLabel?.configureDynamicType(baseSize: 20, textStyle: .body)
        distanceLabel?.fontColor = .white
        distanceLabel?.text = "Distance: 0.0 m"
        distanceLabel?.position = CGPoint(x: -size.width/2 + 100, y: size.height/2 - 80)
        distanceLabel?.zPosition = 100
        camera?.addChild(distanceLabel!)
    }
    
    private func setupTimeLabel() {
        timeLabel = SKLabelNode(fontNamed: "Arial-Bold")
        timeLabel?.configureDynamicType(baseSize: 20, textStyle: .body)
        timeLabel?.fontColor = .white
        timeLabel?.text = "Time: 00:00"
        timeLabel?.position = CGPoint(x: size.width/2 - 100, y: size.height/2 - 50)
        timeLabel?.zPosition = 100
        camera?.addChild(timeLabel!)
    }
    
    private func setupCoinsLabel() {
        coinsLabel = SKLabelNode(fontNamed: "Arial-Bold")
        coinsLabel?.configureDynamicType(baseSize: 20, textStyle: .body)
        coinsLabel?.fontColor = .yellow
        coinsLabel?.text = "Coins: 0"
        coinsLabel?.position = CGPoint(x: size.width/2 - 100, y: size.height/2 - 80)
        coinsLabel?.zPosition = 100
        camera?.addChild(coinsLabel!)
    }
    
    private func setupPauseButton() {
        pauseButton = SKSpriteNode(color: .gray, size: CGSize(width: 60, height: 60))
        pauseButton?.position = CGPoint(x: size.width/2 - 40, y: size.height/2 - 40)
        pauseButton?.zPosition = 100
        pauseButton?.name = "pauseButton"
        camera?.addChild(pauseButton!)
        
        // Add pause symbol
        let pauseLabel = SKLabelNode(text: "⏸")
        pauseLabel.fontSize = 30
        pauseLabel.fontColor = .white
        pauseLabel.position = CGPoint.zero
        pauseButton?.addChild(pauseLabel)
    }
    
    /// Setup airplane node
    private func setupAirplane() {
        airplaneNode = SKSpriteNode(imageNamed: "paperplane")
        airplaneNode?.size = CGSize(width: 60, height: 40)
        airplaneNode?.position = CGPoint(x: -size.width/3, y: 0)
        airplaneNode?.zPosition = 10
        
        // Setup physics body
        airplaneNode?.physicsBody = SKPhysicsBody(rectangleOf: airplaneNode!.size)
        airplaneNode?.physicsBody?.categoryBitMask = PhysicsCategory.airplane
        airplaneNode?.physicsBody?.contactTestBitMask = PhysicsCategory.obstacle | PhysicsCategory.collectible
        airplaneNode?.physicsBody?.collisionBitMask = PhysicsCategory.obstacle
        airplaneNode?.physicsBody?.isDynamic = true
        airplaneNode?.physicsBody?.allowsRotation = true
        
        addChild(airplaneNode!)
    }
    
    /// Setup background with parallax effect
    private func setupBackground() {
        // Create multiple background layers for parallax effect
        for i in 0..<3 {
            let backgroundNode = SKSpriteNode(color: .clear, size: size)
            backgroundNode.position = CGPoint(x: CGFloat(i) * size.width, y: 0)
            backgroundNode.zPosition = -10 - CGFloat(i)
            backgroundNodes.append(backgroundNode)
            addChild(backgroundNode)
        }
    }
    
    /// Setup optimized renderer for performance management
    private func setupOptimizedRenderer() {
        optimizedRenderer = OptimizedRenderer(scene: self)
        optimizedRenderer?.performanceDelegate = self
        
        // Configure performance monitoring
        let config = PerformanceConfiguration(
            targetFrameRate: DeviceCapabilityManager.shared.qualitySettings.targetFrameRate,
            enableProMotion: DeviceCapabilityManager.shared.supportsProMotion,
            maxMemoryUsage: 200,
            enablePerformanceMetrics: true,
            enableMemoryWarnings: true
        )
        PerformanceMonitor.shared.configure(with: config)
        PerformanceMonitor.shared.setOptimizationDelegate(self)
        
        Logger.shared.info("Optimized renderer configured for GameScene", category: .performance)
    }
    
    // MARK: - Accessibility Methods
    
    /// Setup accessibility for game UI elements
    private func setupAccessibility() {
        // Configure UI labels with accessibility
        scoreLabel?.makeAccessibleText("Score: 0")
        distanceLabel?.makeAccessibleText("Distance: 0 meters")
        timeLabel?.makeAccessibleText("Time: 0 minutes 0 seconds")
        coinsLabel?.makeAccessibleText("Coins: 0")
        
        // Configure pause button
        pauseButton?.makeAccessibleButton(
            label: "Pause",
            hint: "Pause or resume the game"
        )
        
        // Setup navigation order for UI elements
        setupGameUINavigationOrder()
    }
    
    /// Setup accessibility navigation order for game UI
    private func setupGameUINavigationOrder() {
        let uiElements: [SKNode] = [
            scoreLabel,
            distanceLabel,
            timeLabel,
            coinsLabel,
            pauseButton
        ].compactMap { $0 }
        
        VoiceOverNavigationManager.shared.setupNavigationOrder(for: uiElements)
    }
    
    /// Update accessibility information during gameplay
    private func updateAccessibilityInfo() {
        guard let viewModel = viewModel else { return }
        
        // Update UI element accessibility labels with current values
        scoreLabel?.accessibilityLabel = "Score: \(viewModel.formattedScore)"
        distanceLabel?.accessibilityLabel = "Distance: \(viewModel.formattedDistance)"
        timeLabel?.accessibilityLabel = "Time: \(viewModel.formattedTime)"
        coinsLabel?.accessibilityLabel = "Coins: \(viewModel.formattedCoins)"
        
        // Update pause button state
        let pauseButtonLabel = viewModel.canPause ? "Pause" : "Resume"
        pauseButton?.accessibilityLabel = pauseButtonLabel
        
        // Configure airplane accessibility if it exists
        if let airplane = airplaneNode {
            let positionDescription = GameAccessibilityHelper.airplanePositionDescription(
                position: airplane.position,
                screenSize: size
            )
            airplane.configureAccessibility(
                label: "Paper airplane",
                hint: "Your airplane. Tilt device to control flight.",
                traits: .playsSound,
                value: positionDescription
            )
        }
        
        // Configure obstacles with relative position information
        updateObstacleAccessibility()
        
        // Configure collectibles
        updateCollectibleAccessibility()
    }
    
    /// Update accessibility for obstacles
    private func updateObstacleAccessibility() {
        guard let airplane = airplaneNode else { return }
        
        for (index, obstacle) in obstacleNodes.enumerated() {
            let description = GameAccessibilityHelper.obstacleDescription(
                obstacle: obstacle,
                airplanePosition: airplane.position
            )
            obstacle.configureAccessibility(
                label: "Obstacle \(index + 1)",
                hint: "Avoid this obstacle",
                traits: .causesPageTurn,
                value: description
            )
        }
    }
    
    /// Update accessibility for collectibles
    private func updateCollectibleAccessibility() {
        for (index, collectible) in collectibleNodes.enumerated() {
            let description = GameAccessibilityHelper.collectibleDescription(
                collectible: collectible,
                type: "coin"
            )
            collectible.configureAccessibility(
                label: "Coin \(index + 1)",
                hint: "Collect this coin for points",
                traits: .playsSound,
                value: description
            )
        }
    }
    
    /// Announce game events for VoiceOver users
    private func announceGameEvent(_ event: String) {
        AccessibilityManager.shared.announceMessage(event, priority: .medium)
    }
    
    // MARK: - Dynamic Type Support
    
    /// Setup observer for dynamic type changes
    private func setupDynamicTypeObserver() {
        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateDynamicTypeFonts()
        }
    }
    
    /// Update all fonts when dynamic type changes
    private func updateDynamicTypeFonts() {
        // Update UI label fonts
        scoreLabel?.updateDynamicType(baseSize: 24, textStyle: .title3)
        distanceLabel?.updateDynamicType(baseSize: 20, textStyle: .body)
        timeLabel?.updateDynamicType(baseSize: 20, textStyle: .body)
        coinsLabel?.updateDynamicType(baseSize: 20, textStyle: .body)
        
        // Adjust UI layout if needed for accessibility sizes
        if DynamicTypeHelper.shared.shouldUseCompactLayout {
            adjustGameUILayoutForLargeText()
        }
    }
    
    /// Adjust game UI layout for large text sizes
    private func adjustGameUILayoutForLargeText() {
        // Increase spacing between UI elements
        let scaledOffset = DynamicTypeHelper.shared.scaledSpacing(30)
        
        // Adjust positions to prevent overlap
        scoreLabel?.position = CGPoint(x: -size.width/2 + 100, y: size.height/2 - scaledOffset)
        distanceLabel?.position = CGPoint(x: -size.width/2 + 100, y: size.height/2 - scaledOffset - 40)
        timeLabel?.position = CGPoint(x: size.width/2 - 100, y: size.height/2 - scaledOffset)
        coinsLabel?.position = CGPoint(x: size.width/2 - 100, y: size.height/2 - scaledOffset - 40)
        
        // Ensure pause button remains accessible
        let minTouchSize = DynamicTypeHelper.shared.minimumTouchTargetSize
        if let pauseButton = pauseButton {
            let currentSize = pauseButton.size
            if currentSize.width < minTouchSize.width || currentSize.height < minTouchSize.height {
                pauseButton.size = CGSize(
                    width: max(currentSize.width, minTouchSize.width),
                    height: max(currentSize.height, minTouchSize.height)
                )
            }
        }
    }
    
    // MARK: - ViewModel Observation
    
    /// Start observing ViewModel state changes
    private func startObservingViewModel() {
        // Note: With @Observable, the UI will automatically update when ViewModel properties change
        // We can add specific observation logic here if needed
    }
    
    /// Update UI based on ViewModel state
    private func updateUI() {
        guard let viewModel = viewModel else { return }
        
        // Update score
        scoreLabel?.text = "Score: \(viewModel.formattedScore)"
        
        // Update distance
        distanceLabel?.text = "Distance: \(viewModel.formattedDistance)"
        
        // Update time
        timeLabel?.text = "Time: \(viewModel.formattedTime)"
        
        // Update coins
        coinsLabel?.text = "Coins: \(viewModel.formattedCoins)"
        
        // Update pause button visibility
        pauseButton?.isHidden = !viewModel.canPause
        
        // Update accessibility information
        updateAccessibilityInfo()
    }
    
    // MARK: - Game Flow Methods
    
    /// Start the game with specified mode
    /// - Parameter mode: Game mode to start
    func startGame(mode: GameState.Mode) {
        guard let viewModel = viewModel else { return }
        
        // Setup game elements
        setupAirplane()
        setupBackground()
        
        // Setup VoiceOver-specific controls if needed
        setupVoiceOverGameControls()
        
        // Start the game through ViewModel
        viewModel.startGame(mode: mode)
        
        gameStarted = true
        lastUpdateTime = 0
        
        // Announce game start for VoiceOver users
        AccessibilityManager.shared.announceGameStateChange("Game started")
    }
    
    /// Setup VoiceOver-specific game controls
    private func setupVoiceOverGameControls() {
        guard UIAccessibility.isVoiceOverRunning else { return }
        
        // Create invisible control areas for VoiceOver users
        let leftControlArea = SKSpriteNode(color: .clear, size: CGSize(width: size.width/2, height: size.height))
        leftControlArea.position = CGPoint(x: -size.width/4, y: 0)
        leftControlArea.zPosition = 200
        leftControlArea.name = "leftControl"
        leftControlArea.makeAccessibleButton(
            label: "Fly down",
            hint: "Tap to make airplane fly downward"
        )
        addChild(leftControlArea)
        
        let rightControlArea = SKSpriteNode(color: .clear, size: CGSize(width: size.width/2, height: size.height))
        rightControlArea.position = CGPoint(x: size.width/4, y: 0)
        rightControlArea.zPosition = 200
        rightControlArea.name = "rightControl"
        rightControlArea.makeAccessibleButton(
            label: "Fly up",
            hint: "Tap to make airplane fly upward"
        )
        addChild(rightControlArea)
        
        // Add accessibility instructions
        AccessibilityManager.shared.announceMessage(
            "VoiceOver controls: Tap left side of screen to fly down, right side to fly up",
            priority: .high
        )
    }
    
    /// Pause the game
    func pauseGame() {
        viewModel?.pauseGame()
        isPaused = true
    }
    
    /// Resume the game
    func resumeGame() {
        viewModel?.resumeGame()
        isPaused = false
    }
    
    /// End the game
    func endGame() {
        guard let viewModel = viewModel else { return }
        
        // Announce game completion for VoiceOver users
        let finalScore = viewModel.formattedScore
        _ = viewModel.formattedDistance
        let finalTime = viewModel.formattedTime
        
        AccessibilityManager.shared.announceLevelCompletion(
            level: "Free Play",
            score: Int(finalScore) ?? 0,
            time: finalTime
        )
        
        viewModel.endGame()
        gameStarted = false
        
        // Clean up game elements
        airplaneNode?.removeFromParent()
        airplaneNode = nil
        
        backgroundNodes.forEach { $0.removeFromParent() }
        backgroundNodes.removeAll()
        
        obstacleNodes.forEach { $0.removeFromParent() }
        obstacleNodes.removeAll()
        
        collectibleNodes.forEach { $0.removeFromParent() }
        collectibleNodes.removeAll()
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        // Handle pause button tap
        if touchedNode.name == "pauseButton" || touchedNode.parent?.name == "pauseButton" {
            if viewModel?.canPause == true {
                pauseGame()
                AccessibilityManager.shared.announceGameStateChange("Game paused")
            } else if viewModel?.canResume == true {
                resumeGame()
                AccessibilityManager.shared.announceGameStateChange("Game resumed")
            }
            return
        }
        
        // Handle VoiceOver control areas
        if UIAccessibility.isVoiceOverRunning && gameStarted {
            if touchedNode.name == "leftControl" {
                // Apply downward force to airplane
                airplaneNode?.physicsBody?.applyImpulse(CGVector(dx: 0, dy: -50))
                AccessibilityManager.shared.announceMessage("Flying down", priority: .low)
                return
            } else if touchedNode.name == "rightControl" {
                // Apply upward force to airplane
                airplaneNode?.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 50))
                AccessibilityManager.shared.announceMessage("Flying up", priority: .low)
                return
            }
        }
        
        // Handle game start if not started
        if !gameStarted && viewModel?.canStart == true {
            startGame(mode: .freePlay)
        }
    }
    
    // MARK: - Game Loop
    
    override func update(_ currentTime: TimeInterval) {
        guard gameStarted, !isPaused else { return }
        
        // Initialize lastUpdateTime if needed
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        
        // Calculate delta time
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Update performance monitoring
        optimizedRenderer?.updateFrame(currentTime: currentTime)
        PerformanceMonitor.shared.recordFrame(at: currentTime)
        
        // Update game elements
        updateAirplane(deltaTime: deltaTime)
        updateBackground(deltaTime: deltaTime)
        updateObstacles(deltaTime: deltaTime)
        updateCollectibles(deltaTime: deltaTime)
        updateCamera()
        updateUI()
        
        // Update distance in ViewModel
        if let airplane = airplaneNode {
            let distance = Float(airplane.position.x + size.width/3) / 10.0 // Convert to meters
            viewModel?.updateDistance(max(0, distance))
        }
    }
    
    // MARK: - Update Methods
    
    private func updateAirplane(deltaTime: TimeInterval) {
        guard let airplane = airplaneNode else { return }
        
        // Apply physics forces based on device motion
        // This would typically get tilt data from the ViewModel/PhysicsService
        
        // Keep airplane on screen vertically
        let minY = -size.height/2 + airplane.size.height/2
        let maxY = size.height/2 - airplane.size.height/2
        airplane.position.y = max(minY, min(maxY, airplane.position.y))
        
        // Rotate airplane based on velocity
        if let velocity = airplane.physicsBody?.velocity {
            let angle = atan2(velocity.dy, velocity.dx)
            airplane.zRotation = angle
        }
    }
    
    private func updateBackground(deltaTime: TimeInterval) {
        // Move background for parallax effect
        let scrollSpeed: CGFloat = 100
        
        for (index, backgroundNode) in backgroundNodes.enumerated() {
            let speed = scrollSpeed / CGFloat(index + 1)
            backgroundNode.position.x -= speed * CGFloat(deltaTime)
            
            // Reset position when off screen
            if backgroundNode.position.x < -size.width * 1.5 {
                backgroundNode.position.x = size.width * 1.5
            }
        }
    }
    
    private func updateObstacles(deltaTime: TimeInterval) {
        // Update obstacle positions and remove off-screen obstacles
        obstacleNodes.removeAll { obstacle in
            obstacle.position.x -= 200 * CGFloat(deltaTime)
            
            if obstacle.position.x < -size.width/2 - 100 {
                obstacle.removeFromParent()
                return true
            }
            return false
        }
        
        // Spawn new obstacles randomly
        if Int.random(in: 0..<1000) < 5 { // 0.5% chance per frame
            spawnObstacle()
        }
    }
    
    private func updateCollectibles(deltaTime: TimeInterval) {
        // Update collectible positions and remove off-screen collectibles
        collectibleNodes.removeAll { collectible in
            collectible.position.x -= 150 * CGFloat(deltaTime)
            
            if collectible.position.x < -size.width/2 - 100 {
                collectible.removeFromParent()
                return true
            }
            return false
        }
        
        // Spawn new collectibles randomly
        if Int.random(in: 0..<2000) < 3 { // 0.15% chance per frame
            spawnCollectible()
        }
    }
    
    private func updateCamera() {
        guard let airplane = airplaneNode, let camera = camera else { return }
        
        // Follow airplane horizontally with some offset
        let targetX = airplane.position.x + 200
        camera.position.x = targetX
    }
    
    // MARK: - Spawning Methods
    
    private func spawnObstacle() {
        let obstacle = SKSpriteNode(color: .red, size: CGSize(width: 40, height: 80))
        obstacle.position = CGPoint(
            x: size.width/2 + 100,
            y: CGFloat.random(in: -size.height/3...size.height/3)
        )
        obstacle.zPosition = 5
        
        // Setup physics
        obstacle.physicsBody = SKPhysicsBody(rectangleOf: obstacle.size)
        obstacle.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        obstacle.physicsBody?.isDynamic = false
        
        obstacleNodes.append(obstacle)
        addChild(obstacle)
    }
    
    private func spawnCollectible() {
        let collectible = SKSpriteNode(color: .yellow, size: CGSize(width: 20, height: 20))
        collectible.position = CGPoint(
            x: size.width/2 + 100,
            y: CGFloat.random(in: -size.height/3...size.height/3)
        )
        collectible.zPosition = 5
        
        // Setup physics
        collectible.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        collectible.physicsBody?.categoryBitMask = PhysicsCategory.collectible
        collectible.physicsBody?.isDynamic = false
        
        // Add rotation animation
        let rotateAction = SKAction.rotate(byAngle: .pi * 2, duration: 2.0)
        collectible.run(SKAction.repeatForever(rotateAction))
        
        collectibleNodes.append(collectible)
        addChild(collectible)
    }
}

// MARK: - Physics Contact Delegate

extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        switch contactMask {
        case PhysicsCategory.airplane | PhysicsCategory.obstacle:
            handleObstacleCollision(contact)
            
        case PhysicsCategory.airplane | PhysicsCategory.collectible:
            handleCollectibleCollection(contact)
            
        default:
            break
        }
    }
    
    private func handleObstacleCollision(_ contact: SKPhysicsContact) {
        // Verify obstacle collision occurred (node validation)
        _ = contact.bodyA.categoryBitMask == PhysicsCategory.obstacle 
            ? contact.bodyA.node 
            : contact.bodyB.node
        
        // Handle collision through ViewModel
        viewModel?.handleObstacleCollision()
        
        // Announce collision for VoiceOver users
        AccessibilityManager.shared.announceObstacleCollision()
        
        // Visual feedback
        let flashAction = SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.5, duration: 0.1),
            SKAction.colorize(with: .clear, colorBlendFactor: 0.0, duration: 0.1)
        ])
        airplaneNode?.run(flashAction)
    }
    
    private func handleCollectibleCollection(_ contact: SKPhysicsContact) {
        // Determine which node is the collectible
        let collectibleNode: SKNode
        if contact.bodyA.categoryBitMask == PhysicsCategory.collectible {
            collectibleNode = contact.bodyA.node!
        } else {
            collectibleNode = contact.bodyB.node!
        }
        
        // Remove collectible from tracking
        if let index = collectibleNodes.firstIndex(of: collectibleNode) {
            collectibleNodes.remove(at: index)
        }
        
        // Handle collection through ViewModel
        viewModel?.addCoin()
        
        // Announce collection for VoiceOver users
        let totalCoins = viewModel?.formattedCoins ?? "0"
        AccessibilityManager.shared.announceCollectibleCollection("Coin", count: Int(totalCoins) ?? 0)
        
        // Remove collectible with animation
        let scaleAction = SKAction.scale(to: 1.5, duration: 0.2)
        let fadeAction = SKAction.fadeOut(withDuration: 0.2)
        let removeAction = SKAction.removeFromParent()
        let sequence = SKAction.sequence([
            SKAction.group([scaleAction, fadeAction]),
            removeAction
        ])
        collectibleNode.run(sequence)
    }
}

// PhysicsCategory is already defined in Utils/PhysicsCategory.swift 

// MARK: - Performance Optimization Delegates

extension GameScene: OptimizedRendererDelegate {
    func rendererDidUpdateQuality(_ renderer: OptimizedRenderer, from oldSettings: QualitySettings, to newSettings: QualitySettings) {
        Logger.shared.info("GameScene quality updated: \(oldSettings.targetFrameRate)fps -> \(newSettings.targetFrameRate)fps", category: .performance)
        
        // Update scene properties based on new quality settings
        view?.preferredFramesPerSecond = newSettings.targetFrameRate
        
        // Adjust particle systems if any exist
        enumerateChildNodes(withName: "//particle") { node, _ in
            if let particleNode = node as? SKEmitterNode {
                let baseCount = particleNode.numParticlesToEmit
                particleNode.numParticlesToEmit = max(1, Int(Double(baseCount) * (Double(newSettings.particleCount) / 100.0)))
            }
        }
    }
    
    func rendererDetectedPerformanceIssue(_ renderer: OptimizedRenderer, issue: PerformanceIssue) {
        switch issue {
        case .lowFrameRate(let fps):
            Logger.shared.warning("GameScene detected low frame rate: \(fps)", category: .performance)
            // Could pause non-essential animations or reduce quality
            
        case .highMemoryUsage(let bytes):
            Logger.shared.warning("GameScene detected high memory usage: \(bytes / 1024 / 1024)MB", category: .performance)
            // Could clean up off-screen nodes more aggressively
            cleanupOffScreenNodes()
            
        case .thermalThrottling:
            Logger.shared.warning("GameScene detected thermal throttling", category: .performance)
            // Could reduce visual effects or pause background processes
        }
    }
    
    private func cleanupOffScreenNodes() {
        let screenBounds = CGRect(x: -size.width, y: -size.height, width: size.width * 2, height: size.height * 2)
        
        // Clean up obstacles
        obstacleNodes.removeAll { obstacle in
            if !screenBounds.contains(obstacle.position) {
                obstacle.removeFromParent()
                return true
            }
            return false
        }
        
        // Clean up collectibles
        collectibleNodes.removeAll { collectible in
            if !screenBounds.contains(collectible.position) {
                collectible.removeFromParent()
                return true
            }
            return false
        }
    }
}

extension GameScene: PerformanceOptimizationDelegate {
    func performanceMonitorDetectedLowFPS(_ monitor: PerformanceMonitor, fps: Double) {
        Logger.shared.warning("GameScene: Low FPS detected (\(fps)), reducing quality", category: .performance)
        
        // Reduce particle effects
        enumerateChildNodes(withName: "//particle") { node, _ in
            if let particleNode = node as? SKEmitterNode {
                particleNode.numParticlesToEmit = max(1, particleNode.numParticlesToEmit / 2)
            }
        }
        
        // Reduce spawn rates
        // This could be implemented by adjusting spawn probability in update methods
    }
    
    func performanceMonitorDetectedMemoryPressure(_ monitor: PerformanceMonitor, level: MemoryPressureLevel) {
        Logger.shared.warning("GameScene: Memory pressure detected (\(level))", category: .performance)
        
        switch level {
        case .moderate:
            // Clean up off-screen nodes more frequently
            cleanupOffScreenNodes()
            
        case .high:
            // More aggressive cleanup
            cleanupOffScreenNodes()
            // Remove particle trails
            enumerateChildNodes(withName: "//trail") { node, _ in
                node.removeFromParent()
            }
            
        case .critical:
            // Emergency cleanup
            cleanupOffScreenNodes()
            // Remove all non-essential visual effects
            enumerateChildNodes(withName: "//effect") { node, _ in
                node.removeFromParent()
            }
            
        case .normal:
            break
        }
    }
    
    func performanceMonitorDetectedThermalChange(_ monitor: PerformanceMonitor, state: ProcessInfo.ThermalState) {
        Logger.shared.info("GameScene: Thermal state changed to \(state)", category: .performance)
        
        switch state {
        case .serious, .critical:
            // Reduce frame rate and disable non-essential effects
            view?.preferredFramesPerSecond = 30
            
            // Disable particle effects
            enumerateChildNodes(withName: "//particle") { node, _ in
                node.isHidden = true
            }
            
        case .fair:
            // Slightly reduce quality
            view?.preferredFramesPerSecond = 45
            
        case .nominal:
            // Restore normal quality
            let qualitySettings = DeviceCapabilityManager.shared.qualitySettings
            view?.preferredFramesPerSecond = qualitySettings.targetFrameRate
            
            // Re-enable particle effects
            enumerateChildNodes(withName: "//particle") { node, _ in
                node.isHidden = false
            }
            
        @unknown default:
            break
        }
    }
}