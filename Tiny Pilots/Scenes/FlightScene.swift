//
//  FlightScene.swift
//  Tiny Pilots
//
//  Created on 2025-03-01.
//
//  ARCHITECTURE NOTE:
//  This is the primary gameplay scene currently in use. It provides a simpler,
//  more direct implementation compared to GameScene.swift.
//
//  GameScene.swift exists as a more modern MVVM-based implementation with
//  dependency injection, accessibility features, and performance monitoring,
//  but is not currently integrated into the app flow.
//
//  Future migration path: Consider migrating FlightScene features into
//  GameScene for better architecture, or document when to use each.

import SpriteKit
import GameplayKit
import CoreMotion
import UIKit

/// The main flight scene for Tiny Pilots where the player controls a paper airplane
class FlightScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - Properties
    
    // Game elements
    private var airplane: PaperAirplane?
    private var parallaxBackground: ParallaxBackground?
    private var environment: GameEnvironment?
    
    // UI elements
    private var scoreLabel: SKLabelNode?
    private var distanceLabel: SKLabelNode?
    private var timeLabel: SKLabelNode?
    private var pauseButton: SKNode?
    private var challengeInfoLabel: SKLabelNode?
    
    // Game state
    private var lastUpdateTime: TimeInterval = 0
    private var motionManager: CMMotionManager?
    private var cameraNode: SKCameraNode?
    private var dt: TimeInterval = 0
    private var gameMode: GameManager.GameMode = .freePlay
    private var score: Int = 0
    
    // Services
    private var audioService: AudioServiceProtocol?
    
    // Haptic feedback generators
    private let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    // Challenge properties
    private var challengeCode: String?
    private var challengeCourseID: String?
    private var challengeDistance: Int?
    private var challengeTime: Int?
    
    // Chunk-based level generation
    private var lastChunkX: CGFloat = 0
    private let chunkWidth: CGFloat = 1000
    private let generateAheadDistance: CGFloat = 2000
    
    // MARK: - Initialization
    
    convenience init(size: CGSize, challengeCode: String? = nil) {
        self.init(size: size, mode: .challenge)
        self.challengeCode = challengeCode
    }
    
    override func didMove(to view: SKView) {
        // Set up physics world
        physicsWorld.gravity = GameConfig.Physics.gravity
        physicsWorld.contactDelegate = self
        
        // Configure physics service for this scene
        PhysicsManager.shared.startPhysicsSimulation()
        
        // Set up audio service
        setupAudioService()
        
        // Prepare haptic feedback generators
        impactGenerator.prepare()
        notificationGenerator.prepare()
        
        // Set up camera
        setupCamera()
        
        // Set up game elements
        setupGameElements()
        
        // Set up UI
        setupUI()
        
        // Start motion updates
        setupMotionManager()
    }
    
    /// Initialize with a specific game mode
    init(size: CGSize, mode: GameManager.GameMode) {
        super.init(size: size)
        self.gameMode = mode
        GameManager.shared.setGameMode(convertToGameStateMode(mode))
    }
    
    /// Initialize with a challenge code
    init(size: CGSize, challengeCode: String) {
        super.init(size: size)
        self.challengeCode = challengeCode
        GameManager.shared.setGameMode(.challenge)
        
        // Process the challenge code
        processChallengeCode()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Setup Methods
    
    private func setupCamera() {
        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode!)
        
        // Position camera initially
        cameraNode?.position = CGPoint(x: size.width/2, y: size.height/2)
    }
    
    private func setupGameElements() {
        // Create airplane
        airplane = PaperAirplane(type: .basic)
        if let airplane = airplane {
            airplane.position = CGPoint(x: size.width * 0.3, y: size.height * 0.6)
            addChild(airplane)
        }
        
        // Create environment
        if let envType = GameEnvironment.EnvironmentType(rawValue: GameManager.shared.currentEnvironmentType) {
            environment = GameEnvironment(type: envType, size: size)
        } else {
            environment = GameEnvironment(type: .meadow, size: size)
        }
        if let environment = environment {
            addChild(environment)
        }
        
        // Create parallax background
        parallaxBackground = ParallaxBackground(size: size)
        if let parallaxBackground = parallaxBackground {
            parallaxBackground.zPosition = -100
            addChild(parallaxBackground)
        }
        
        // Initialize chunk generation at starting position
        lastChunkX = size.width * 0.3 // Start from airplane's initial X position
    }
    
    private func setupUI() {
        // Create a container for all UI elements
        let uiContainer = SKNode()
        uiContainer.name = "uiContainer"
        uiContainer.zPosition = 999
        cameraNode?.addChild(uiContainer)
        
        // Add score label
        scoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        if let scoreLabel = scoreLabel {
            scoreLabel.text = "Score: 0"
            scoreLabel.fontSize = 24
            scoreLabel.fontColor = .white
            scoreLabel.horizontalAlignmentMode = .left
            scoreLabel.verticalAlignmentMode = .top
            scoreLabel.position = CGPoint(x: -size.width/2 + 20, y: size.height/2 - 30)
            
            // Add shadow for better visibility
            scoreLabel.addShadow(radius: 2, opacity: 0.5)
            uiContainer.addChild(scoreLabel)
        }
        
        // Add pause button
        pauseButton = SKShapeNode(rectOf: CGSize(width: 80, height: 40), cornerRadius: 10)
        if let pauseButton = pauseButton as? SKShapeNode {
            pauseButton.fillColor = UIColor(white: 0.2, alpha: 0.7)
            pauseButton.strokeColor = .white
            pauseButton.lineWidth = 2
            pauseButton.position = CGPoint(x: -size.width/2 + 60, y: -size.height/2 + 50)
            pauseButton.zPosition = 10
            pauseButton.name = "pauseButton"
            
            let pauseLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
            pauseLabel.text = "PAUSE"
            pauseLabel.fontSize = 18
            pauseLabel.fontColor = .white
            pauseLabel.verticalAlignmentMode = .center
            pauseLabel.horizontalAlignmentMode = .center
            pauseLabel.position = CGPoint.zero
            pauseButton.addChild(pauseLabel)
            
            uiContainer.addChild(pauseButton)
        }
        
        // Add distance label with background
        let distanceBackground = SKShapeNode(rectOf: CGSize(width: 160, height: 40), cornerRadius: 10)
        distanceBackground.fillColor = UIColor(white: 0.2, alpha: 0.7)
        distanceBackground.strokeColor = .white
        distanceBackground.lineWidth = 1
        distanceBackground.position = CGPoint(x: 0, y: size.height/2 - 30)
        uiContainer.addChild(distanceBackground)
        
        distanceLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        if let distanceLabel = distanceLabel {
            distanceLabel.text = "Distance: 0m"
            distanceLabel.fontSize = 20
            distanceLabel.fontColor = .white
            distanceLabel.horizontalAlignmentMode = .center
            distanceLabel.verticalAlignmentMode = .center
            distanceLabel.position = CGPoint.zero
            distanceBackground.addChild(distanceLabel)
        }
        
        // Add time label with background
        let timeBackground = SKShapeNode(rectOf: CGSize(width: 140, height: 40), cornerRadius: 10)
        timeBackground.fillColor = UIColor(white: 0.2, alpha: 0.7)
        timeBackground.strokeColor = .white
        timeBackground.lineWidth = 1
        timeBackground.position = CGPoint(x: size.width/2 - 90, y: size.height/2 - 30)
        uiContainer.addChild(timeBackground)
        
        timeLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        if let timeLabel = timeLabel {
            timeLabel.text = "Time: 0s"
            timeLabel.fontSize = 20
            timeLabel.fontColor = .white
            timeLabel.horizontalAlignmentMode = .center
            timeLabel.verticalAlignmentMode = .center
            timeLabel.position = CGPoint.zero
            timeBackground.addChild(timeLabel)
        }
        
        // Add game control buttons on the right side
        addGameControls(to: uiContainer)
    }
    
    private func addGameControls(to container: SKNode) {
        // Create restart button
        let restartButton = createGameButton(name: "restartButton", text: "↻", position: CGPoint(x: size.width/2 - 50, y: -size.height/2 + 170))
        container.addChild(restartButton)
        
        // Create home button
        let homeButton = createGameButton(name: "homeButton", text: "⌂", position: CGPoint(x: size.width/2 - 50, y: -size.height/2 + 110))
        container.addChild(homeButton)
        
        // Create share button
        let shareButton = createGameButton(name: "shareButton", text: "↗", position: CGPoint(x: size.width/2 - 50, y: -size.height/2 + 50))
        container.addChild(shareButton)
    }
    
    private func createGameButton(name: String, text: String, position: CGPoint) -> SKNode {
        let buttonContainer = SKNode()
        buttonContainer.name = name
        buttonContainer.position = position
        
        let background = SKShapeNode(circleOfRadius: 25)
        background.fillColor = UIColor(white: 0.2, alpha: 0.8)
        background.strokeColor = .white
        background.lineWidth = 2
        buttonContainer.addChild(background)
        
        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.text = text
        label.fontSize = 24
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        buttonContainer.addChild(label)
        
        return buttonContainer
    }
    
    private func createModernButton(size: CGSize, cornerRadius: CGFloat, icon: String, text: String, position: CGPoint) -> SKNode {
        let button = SKNode()
        button.position = position
        
        // Button background with improved visibility
        let background = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        background.fillColor = UIColor.black.withAlphaComponent(0.6)
        background.strokeColor = UIColor.white.withAlphaComponent(0.8)
        background.lineWidth = 2
        button.addChild(background)
        
        // Replace SF Symbols with standard text
        let iconNode = SKLabelNode(fontNamed: "Helvetica-Bold")
        iconNode.text = icon
        iconNode.fontSize = 20
        iconNode.fontColor = UIColor.white
        iconNode.verticalAlignmentMode = .center
        iconNode.position = CGPoint(x: -size.width/4, y: 0)
        button.addChild(iconNode)
        
        if !text.isEmpty {
            // Text with proper typography
            let textNode = SKLabelNode(fontNamed: "Helvetica")
            textNode.text = text
            textNode.fontSize = 18
            textNode.fontColor = UIColor.white
            textNode.verticalAlignmentMode = .center
            textNode.position = CGPoint(x: 0, y: 0)
            button.addChild(textNode)
        }
        
        return button
    }
    
    private func setupMotionManager() {
        motionManager = CMMotionManager()
        motionManager?.accelerometerUpdateInterval = 1.0 / 60.0
        motionManager?.startAccelerometerUpdates()
    }
    
    private func setupAudioService() {
        // Try to resolve AudioService from DI container, fallback to direct instantiation
        if let resolved: AudioServiceProtocol = DIContainer.shared.tryResolve(AudioServiceProtocol.self) {
            audioService = resolved
        } else {
            audioService = AudioService()
        }
    }
    
    // MARK: - Game Flow
    
    private func startGame() {
        GameManager.shared.startGame()
    }
    
    private func pauseGame() {
        if GameManager.shared.currentState.status == .playing {
            GameManager.shared.pauseGame()
            // Note: isPaused is managed by SKScene and synced via GameManager
            
            // Show pause menu
            showPauseMenu()
        }
    }
    
    private func resumeGame() {
        if GameManager.shared.currentState.status == .paused {
            GameManager.shared.resumeGame()
            // Note: isPaused is managed by SKScene and synced via GameManager
        }
    }
    
    private func endGame() {
        if GameManager.shared.currentState.status == .playing {
            GameManager.shared.endGame()
            
            // Submit score to Game Center if available
            if GameCenterManager.shared.isGameCenterAvailable {
                // Determine which leaderboard to use based on game mode
                let leaderboardID: String
                
                switch GameManager.shared.currentMode {
                case .freePlay:
                    leaderboardID = GameCenterConfig.Leaderboards.distanceFreePlay
                case .challenge:
                    leaderboardID = GameCenterConfig.Leaderboards.distanceChallenge
                case .dailyRun:
                    leaderboardID = GameCenterConfig.Leaderboards.distanceDailyRun
                case .tutorial:
                    leaderboardID = GameCenterConfig.Leaderboards.distanceFreePlay // Use free play leaderboard for tutorial
                case .weeklySpecial:
                    leaderboardID = GameCenterConfig.Leaderboards.distanceWeeklySpecial
                }
                
                // Submit score
                GameCenterManager.shared.submitScore(
                    Int(GameManager.shared.currentState.distance),
                    to: leaderboardID,
                    completion: { error in
                        if let error = error {
                            print("Error submitting score: \(error.localizedDescription)")
                        }
                    }
                )
                
                // Report achievements based on distance and time
                GameCenterManager.shared.trackAchievementProgress()
            }
            
            // Show game over menu
            showGameOverMenu()
        }
    }
    
    private func showPauseMenu() {
        // Create pause menu with modern design
        let pauseMenu = SKNode()
        pauseMenu.name = "pauseMenu"
        pauseMenu.zPosition = 1000
        
        // Frosted glass background
        let background = SKShapeNode(rectOf: CGSize(width: 320, height: 400), cornerRadius: 24)
        background.fillColor = .black
        background.strokeColor = .white
        background.alpha = 0.85
        pauseMenu.addChild(background)
        
        // Title with Helvetica Bold
        let titleLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        titleLabel.text = "Paused"
        titleLabel.fontSize = 32
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: 120)
        pauseMenu.addChild(titleLabel)
        
        // Stats display
        let statsContainer = SKNode()
        statsContainer.position = CGPoint(x: 0, y: 40)
        
        let scoreDisplay = createStatDisplay(
            title: "Score",
            value: "\(GameManager.shared.currentState.score)",
            position: CGPoint(x: 0, y: 40)
        )
        statsContainer.addChild(scoreDisplay)
        
        let distanceDisplay = createStatDisplay(
            title: "Distance",
            value: "\(Int(GameManager.shared.currentState.distance))m",
            position: CGPoint(x: 0, y: 0)
        )
        statsContainer.addChild(distanceDisplay)
        
        let timeDisplay = createStatDisplay(
            title: "Time",
            value: "\(Int(GameManager.shared.currentState.timeElapsed))s",
            position: CGPoint(x: 0, y: -40)
        )
        statsContainer.addChild(timeDisplay)
        
        pauseMenu.addChild(statsContainer)
        
        // Modern buttons
        let resumeButton = createMenuButton(
            title: "Resume",
            icon: "play.fill",
            color: .systemGreen,
            position: CGPoint(x: 0, y: -60)
        )
        resumeButton.name = "resumeButton"
        pauseMenu.addChild(resumeButton)
        
        let quitButton = createMenuButton(
            title: "Quit",
            icon: "xmark",
            color: .systemRed,
            position: CGPoint(x: 0, y: -120)
        )
        quitButton.name = "quitButton"
        pauseMenu.addChild(quitButton)
        
        // Add to camera with animation
        pauseMenu.alpha = 0
        pauseMenu.position = CGPoint(x: size.width/2, y: size.height/2)
        cameraNode?.addChild(pauseMenu)
        
        pauseMenu.run(SKAction.fadeIn(withDuration: 0.3))
    }
    
    private func createStatDisplay(title: String, value: String, position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        
        let titleLabel = SKLabelNode(fontNamed: "Helvetica")
        titleLabel.text = title
        titleLabel.fontSize = 16
        titleLabel.fontColor = .gray
        titleLabel.position = CGPoint(x: -60, y: 0)
        titleLabel.horizontalAlignmentMode = .left
        container.addChild(titleLabel)
        
        let valueLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        valueLabel.text = value
        valueLabel.fontSize = 18
        valueLabel.fontColor = .white
        valueLabel.position = CGPoint(x: 60, y: 0)
        valueLabel.horizontalAlignmentMode = .right
        container.addChild(valueLabel)
        
        return container
    }
    
    private func createMenuButton(title: String, icon: String, color: UIColor, position: CGPoint) -> SKNode {
        let button = SKNode()
        button.position = position
        
        let background = SKShapeNode(rectOf: CGSize(width: 240, height: 50), cornerRadius: 12)
        background.fillColor = color
        background.strokeColor = .clear
        background.alpha = 0.8
        button.addChild(background)
        
        // Use standard text instead of SF Symbols
        let iconNode = SKLabelNode(fontNamed: "Helvetica-Bold")
        // Map common SF Symbol names to standard text characters
        let iconText: String
        switch icon {
        case "play.fill":
            iconText = "▶️"
        case "xmark":
            iconText = "✖️"
        case "arrow.clockwise":
            iconText = "↻"
        case "house.fill":
            iconText = "⌂"
        case "square.and.arrow.up":
            iconText = "↗️"
        default:
            iconText = "•"
        }
        iconNode.text = iconText
        iconNode.fontSize = 18
        iconNode.fontColor = .white
        iconNode.verticalAlignmentMode = .center
        iconNode.position = CGPoint(x: -80, y: 0)
        button.addChild(iconNode)
        
        let titleLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        titleLabel.text = title
        titleLabel.fontSize = 18
        titleLabel.fontColor = .white
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: 0)
        button.addChild(titleLabel)
        
        return button
    }
    
    private func showGameOverMenu() {
        // Create game over menu with modern design
        let gameOverMenu = SKNode()
        gameOverMenu.name = "gameOverMenu"
        gameOverMenu.zPosition = 1000
        
        // Frosted glass background
        let background = SKShapeNode(rectOf: CGSize(width: 320, height: 480), cornerRadius: 24)
        background.fillColor = .black
        background.strokeColor = .white
        background.alpha = 0.85
        gameOverMenu.addChild(background)
        
        // Title with Helvetica Bold
        let titleLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        titleLabel.text = "Flight Over"
        titleLabel.fontSize = 32
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: 180)
        gameOverMenu.addChild(titleLabel)
        
        // Stats display
        let statsContainer = SKNode()
        statsContainer.position = CGPoint(x: 0, y: 80)
        
        let scoreDisplay = createStatDisplay(
            title: "Final Score",
            value: "\(GameManager.shared.currentState.score)",
            position: CGPoint(x: 0, y: 40)
        )
        statsContainer.addChild(scoreDisplay)
        
        let distanceDisplay = createStatDisplay(
            title: "Distance",
            value: "\(Int(GameManager.shared.currentState.distance))m",
            position: CGPoint(x: 0, y: 0)
        )
        statsContainer.addChild(distanceDisplay)
        
        let timeDisplay = createStatDisplay(
            title: "Flight Time",
            value: "\(Int(GameManager.shared.currentState.timeElapsed))s",
            position: CGPoint(x: 0, y: -40)
        )
        statsContainer.addChild(timeDisplay)
        
        // Add high score indicator if applicable
        if GameManager.shared.currentState.score > GameManager.shared.playerData.highScore {
            let newHighScoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
            newHighScoreLabel.text = "New High Score!"
            newHighScoreLabel.fontSize = 20
            newHighScoreLabel.fontColor = .systemYellow
            newHighScoreLabel.position = CGPoint(x: 0, y: -80)
            statsContainer.addChild(newHighScoreLabel)
        }
        
        gameOverMenu.addChild(statsContainer)
        
        // Modern buttons
        let retryButton = createMenuButton(
            title: "Try Again",
            icon: "arrow.clockwise",
            color: .systemGreen,
            position: CGPoint(x: 0, y: -60)
        )
        retryButton.name = "retryButton"
        gameOverMenu.addChild(retryButton)
        
        let menuButton = createMenuButton(
            title: "Main Menu",
            icon: "house.fill",
            color: .systemBlue,
            position: CGPoint(x: 0, y: -120)
        )
        menuButton.name = "menuButton"
        gameOverMenu.addChild(menuButton)
        
        // Share button
        let shareButton = createMenuButton(
            title: "Share Score",
            icon: "square.and.arrow.up",
            color: .systemIndigo,
            position: CGPoint(x: 0, y: -180)
        )
        shareButton.name = "shareButton"
        gameOverMenu.addChild(shareButton)
        
        // Add to camera with animation
        gameOverMenu.alpha = 0
        gameOverMenu.position = CGPoint(x: size.width/2, y: size.height/2)
        cameraNode?.addChild(gameOverMenu)
        
        // Animate menu in
        gameOverMenu.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.run {
                // Add subtle particle effect for visual interest
                if let emitter = SKEmitterNode(fileNamed: "GameOverParticles") {
                    emitter.position = CGPoint(x: 0, y: 200)
                    gameOverMenu.addChild(emitter)
                }
            }
        ]))
    }
    
    // MARK: - Challenge Handling
    
    private func processChallengeCode() {
        guard let challengeCode = challengeCode else { return }
        
        // Use GameCenterManager to process the challenge code
        let (courseID, error) = GameCenterManager.shared.processChallengeCode(challengeCode)
        
        if let error = error {
            print("Error processing challenge code: \(error)")
            return
        }
        
        if let courseID = courseID {
            // Store challenge details
            self.challengeCourseID = courseID
            // Set default challenge parameters if not specified
            self.challengeDistance = self.challengeDistance ?? 1000
            self.challengeTime = self.challengeTime ?? 180
        }
        
        // Update UI with challenge info
        updateChallengeInfo()
        
        // Set up environment based on challenge course
        if let environmentType = GameEnvironment.EnvironmentType(rawValue: courseID ?? "") {
            self.environment?.removeFromParent()
            self.environment = GameEnvironment(type: environmentType, size: self.size)
            if let environment = self.environment {
                self.insertChild(environment, at: 0)
            }
            
            // Update parallax background
            self.parallaxBackground?.update(withCameraPosition: CGPoint.zero)
        }
    }
    
    private func updateChallengeInfo() {
        guard GameManager.shared.currentMode == .challenge,
              let challengeInfoLabel = challengeInfoLabel else { return }
        
        var infoText = "Challenge: "
        
        if let courseID = challengeCourseID {
            infoText += courseID
        }
        
        if let distance = challengeDistance {
            infoText += " - \(distance)m"
        }
        
        if let time = challengeTime {
            infoText += " - \(time)s"
        }
        
        challengeInfoLabel.text = infoText
    }
    
    // MARK: - Update
    
    override func update(_ currentTime: TimeInterval) {
        // Calculate delta time
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Only update if game is running
        if GameManager.shared.currentState.status == .playing {
            // Update game manager
            GameManager.shared.update(currentTime)
            
            // Update custom physics synced with frame loop
            PhysicsManager.shared.update(deltaTime: dt)
            
            // Update airplane physics based on tilt
            updateAirplanePhysics()
            
            // Update camera position
            updateCameraPosition()
            
            // Generate new chunks ahead of camera for infinite gameplay
            generateChunksIfNeeded()
            
            // Cull offscreen nodes to prevent memory growth
            cullOffscreenNodes()
            
            // Update UI
            updateUI()
            
            // Update parallax background
            if let cameraNode = cameraNode {
                parallaxBackground?.update(withCameraPosition: cameraNode.position)
            }
            
            // Check for game over conditions
            checkGameOver()
        }
    }
    
    private func updateAirplanePhysics() {
        guard let airplane = airplane else { return }
        
        // PhysicsService handles device motion and applies forces automatically
        // We just need to ensure the airplane is set in the physics service
        // This happens when applyForces is called, but we can also set it explicitly
        // The PhysicsService will handle tilt via device motion updates
        
        // Update distance based on airplane movement
        if let physicsBody = airplane.physicsBody {
            let speed = sqrt(physicsBody.velocity.dx * physicsBody.velocity.dx + 
                            physicsBody.velocity.dy * physicsBody.velocity.dy)
            
            // Add distance based on speed
            GameManager.shared.addDistance(Float(speed * CGFloat(dt) * 0.1))
        }
    }
    
    private func updateCameraPosition() {
        guard let airplane = airplane, let cameraNode = cameraNode else { return }
        
        // Camera follows airplane with some lag
        let cameraLag: CGFloat = 0.1
        let targetPosition = airplane.position
        
        let newX = cameraNode.position.x + (targetPosition.x - cameraNode.position.x) * cameraLag
        let newY = cameraNode.position.y + (targetPosition.y - cameraNode.position.y) * cameraLag
        
        cameraNode.position = CGPoint(x: newX, y: newY)
    }
    
    private func updateUI() {
        // Update score label - use currentState for single source of truth
        scoreLabel?.text = "Score: \(GameManager.shared.currentState.score)"
        
        // Update distance label
        distanceLabel?.text = "Distance: \(Int(GameManager.shared.currentState.distance))m"
        
        // Update time label
        timeLabel?.text = "Time: \(Int(GameManager.shared.currentState.timeElapsed))s"
        
        // Check if challenge goals are met
        if GameManager.shared.currentMode == .challenge {
            if let challengeDistance = challengeDistance, 
               Int(GameManager.shared.currentState.distance) >= challengeDistance {
                // Challenge distance goal met
                challengeInfoLabel?.fontColor = .green
                
                // End game if both goals are met
                if let challengeTime = challengeTime, 
                   Int(GameManager.shared.currentState.timeElapsed) <= challengeTime {
                    // Both goals met - challenge completed
                    completeChallenge()
                }
            } else if let challengeTime = challengeTime, 
                      Int(GameManager.shared.currentState.timeElapsed) > challengeTime {
                // Time limit exceeded
                challengeInfoLabel?.fontColor = .red
                
                // End game if time limit is the only goal
                if challengeDistance == nil {
                    endGame()
                }
            }
        }
    }
    
    private func checkGameOver() {
        guard let airplane = airplane else { return }
        
        // Check if airplane is out of bounds
        let margin: CGFloat = 1000 // Allow some margin beyond screen edges
        let minX = -margin
        let maxX = size.width + margin
        let minY = -margin
        let maxY = size.height + margin
        
        if airplane.position.x < minX || airplane.position.x > maxX ||
           airplane.position.y < minY || airplane.position.y > maxY {
            endGame()
        }
    }
    
    /// Generate chunks of level content ahead of the camera for infinite gameplay
    private func generateChunksIfNeeded() {
        guard let cameraX = cameraNode?.position.x else { return }
        let generateThreshold = cameraX + generateAheadDistance
        
        // Generate chunks until we're ahead of the camera
        while lastChunkX < generateThreshold {
            spawnChunk(at: lastChunkX)
            lastChunkX += chunkWidth
        }
    }
    
    /// Spawn a chunk of level content at the specified X position
    /// - Parameter x: The X position where the chunk should be spawned
    private func spawnChunk(at x: CGFloat) {
        // Spawn obstacles in this chunk (2-5 obstacles per chunk)
        let obstacleCount = Int.random(in: 2...5)
        for _ in 0..<obstacleCount {
            let obstacleX = x + CGFloat.random(in: 0...chunkWidth)
            spawnObstacle(at: CGPoint(x: obstacleX, y: CGFloat.random(in: -size.height/3...size.height/3)))
        }
        
        // Spawn collectibles in this chunk (3-8 collectibles per chunk)
        let collectibleCount = Int.random(in: 3...8)
        for _ in 0..<collectibleCount {
            let collectibleX = x + CGFloat.random(in: 0...chunkWidth)
            spawnCollectible(at: CGPoint(x: collectibleX, y: CGFloat.random(in: -size.height/3...size.height/3)))
        }
    }
    
    /// Spawn an obstacle at the specified position
    /// - Parameter position: The position where the obstacle should be spawned
    private func spawnObstacle(at position: CGPoint) {
        // Use Obstacle class if available, otherwise create a simple sprite
        let obstacleType = ObstacleType.allCases.randomElement() ?? .tree
        let obstacle = Obstacle(type: obstacleType)
        obstacle.position(at: position)
        obstacle.applyVisualEffects()
        
        obstacle.node.name = "obstacle_\(obstacleType.rawValue)"
        addChild(obstacle.node)
    }
    
    /// Spawn a collectible at the specified position
    /// - Parameter position: The position where the collectible should be spawned
    private func spawnCollectible(at position: CGPoint) {
        // Use Collectible class if available, otherwise create a simple sprite
        let collectibleType = CollectibleType.allCases.randomElement() ?? .coin
        let collectible = Collectible(type: collectibleType)
        collectible.position(at: position)
        
        collectible.node.name = "collectible_\(collectibleType.rawValue)"
        addChild(collectible.node)
    }
    
    /// Cull offscreen nodes to prevent memory growth
    /// Removes obstacles, collectibles, and other game nodes that are behind the camera
    private func cullOffscreenNodes() {
        let cullingDistance = GameConfig.Performance.cullingDistance
        guard let cameraX = cameraNode?.position.x else { return }
        let cullThreshold = cameraX - cullingDistance
        
        // Cull nodes by category bit mask
        enumerateChildNodes(withName: "//*") { [weak self] node, _ in
            guard let self = self,
                  let physicsBody = node.physicsBody else { return }
            
            // Check if node is an obstacle or collectible
            let isObstacle = (physicsBody.categoryBitMask & PhysicsCategory.obstacle) != 0
            let isCollectible = (physicsBody.categoryBitMask & PhysicsCategory.collectible) != 0
            
            // Remove if behind camera beyond culling distance
            if (isObstacle || isCollectible) && node.position.x < cullThreshold {
                node.removeFromParent()
            }
        }
        
        // Also cull environment nodes that are far behind
        if let environment = environment {
            environment.enumerateChildNodes(withName: "//*") { node, _ in
                if node.position.x < cullThreshold - 500 { // Extra margin for environment
                    node.removeFromParent()
                }
            }
        }
    }
    
    private func completeChallenge() {
        // Mark challenge as completed
        if let courseID = challengeCourseID {
            // Add to completed challenges
            var completedChallenges = GameManager.shared.playerData.completedChallenges
            if completedChallenges < 1 {
                completedChallenges = 1
            } else {
                completedChallenges += 1
            }
            GameManager.shared.playerData.completedChallenges = completedChallenges
            
            // Report achievement for completing challenges
            GameCenterManager.shared.trackAchievementProgress()
            
            // Log completion
            print("Challenge completed: \(courseID)")
        }
        
        // End the game
        endGame()
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Convert touch location to camera's coordinate space for UI elements
        // This commented line was causing a warning because the variable was not used
        // let locationInCamera = convert(location, to: cameraNode!)
        
        // Check if UI container or its children were tapped
        if let uiContainer = cameraNode?.childNode(withName: "uiContainer") {
            
            // Check if pause button was tapped (use optional binding for parent)
            if let pauseButton = pauseButton,
               let parent = pauseButton.parent,
               pauseButton.contains(convert(location, to: parent)) {
                print("Pause button tapped")
                pauseGame()
                return
            }
            
            // Check for game controls (use optional binding for parent to avoid crashes)
            if let restartButton = uiContainer.childNode(withName: "restartButton"),
               let parent = restartButton.parent,
               restartButton.contains(convert(location, to: parent)) {
                print("Restart button tapped")
                restartScene()
                return
            }
            
            if let homeButton = uiContainer.childNode(withName: "homeButton"),
               let parent = homeButton.parent,
               homeButton.contains(convert(location, to: parent)) {
                print("Home button tapped")
                returnToMainMenu()
                return
            }
            
            if let shareButton = uiContainer.childNode(withName: "shareButton"),
               let parent = shareButton.parent,
               shareButton.contains(convert(location, to: parent)) {
                print("Share button tapped")
                shareScore()
                return
            }
        }
        
        // Handle pause menu buttons
        if let pauseMenu = cameraNode?.childNode(withName: "pauseMenu") {
            let locationInMenu = convert(location, to: pauseMenu)
            
            if let resumeButton = pauseMenu.childNode(withName: "resumeButton"),
               resumeButton.contains(locationInMenu) {
                // Resume game
                pauseMenu.removeFromParent()
                resumeGame()
                return
            }
            
            if let quitButton = pauseMenu.childNode(withName: "quitButton"),
               quitButton.contains(locationInMenu) {
                // Quit to main menu
                pauseMenu.removeFromParent()
                returnToMainMenu()
                return
            }
        }
        
        // Handle game over menu buttons
        if let gameOverMenu = cameraNode?.childNode(withName: "gameOverMenu") {
            let locationInMenu = convert(location, to: gameOverMenu)
            
            if let retryButton = gameOverMenu.childNode(withName: "retryButton"),
               retryButton.contains(locationInMenu) {
                // Retry - restart the scene
                restartScene()
                return
            }
            
            if let menuButton = gameOverMenu.childNode(withName: "menuButton"),
               menuButton.contains(locationInMenu) {
                // Return to main menu
                returnToMainMenu()
                return
            }
            
            if let shareButton = gameOverMenu.childNode(withName: "shareButton"),
               shareButton.contains(locationInMenu) {
                // Share score
                shareScore()
                return
            }
        }
    }
    
    // Method to share score
    private func shareScore() {
        print("Sharing score: \(GameManager.shared.currentState.score)")
        
        // Pause the game if playing
        if GameManager.shared.currentState.status == .playing {
            pauseGame()
        }
        
        // Prepare the text to share
        let shareText = "I scored \(GameManager.shared.currentState.score) points and traveled \(Int(GameManager.shared.currentState.distance))m in Tiny Pilots!"
        
        // Create activity view controller for sharing
        let activityViewController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        // Present the view controller
        if let viewController = self.scene?.view?.window?.rootViewController {
            viewController.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Physics Contact
    
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        // Check for airplane collision with obstacle
        if collision == PhysicsCategory.airplane | PhysicsCategory.obstacle {
            // Handle collision with obstacle
            handleObstacleCollision()
        }
        
        // Check for airplane collision with collectible
        if collision == PhysicsCategory.airplane | PhysicsCategory.collectible {
            // Handle collision with collectible
            handleCollectibleCollision(contact)
        }
        
        // Check for airplane collision with ground
        if collision == PhysicsCategory.airplane | PhysicsCategory.ground {
            // Handle collision with ground
            handleGroundCollision()
        }
    }
    
    private func handleObstacleCollision() {
        // Reduce score using GameManager's method
        GameManager.shared.adjustScoreForObstacle()
        
        // Haptic feedback for collision
        impactGenerator.impactOccurred()
        impactGenerator.prepare() // Prepare for next impact
        
        // Visual feedback
        airplane?.run(SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.5, duration: 0.1),
            SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.1)
        ]))
        
        // Play sound effect
        audioService?.playSound("collision")
    }
    
    private func handleCollectibleCollision(_ contact: SKPhysicsContact) {
        // Determine which body is the collectible
        let collectibleBody = (contact.bodyA.categoryBitMask == PhysicsCategory.collectible) ? 
                              contact.bodyA : contact.bodyB
        
        // Remove the collectible
        collectibleBody.node?.removeFromParent()
        
        // Add coin (this will indirectly update the score in GameManager)
        GameManager.shared.addCoin()
        
        // Haptic feedback for collection (success notification)
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare() // Prepare for next notification
        
        // Visual feedback
        audioService?.playSound("coin")
    }
    
    private func handleGroundCollision() {
        // Haptic feedback for ground collision (error notification)
        notificationGenerator.notificationOccurred(.error)
        
        // End the game on ground collision
        endGame()
    }
    
    // MARK: - Scene Management
    
    private func restartScene() {
        // Create a new scene of the same type
        let newScene: FlightScene
        
        if GameManager.shared.currentMode == .challenge, let challengeCode = challengeCode {
            newScene = FlightScene(size: size, challengeCode: challengeCode)
        } else {
            let mode = convertFromGameStateMode(GameManager.shared.currentMode)
            newScene = FlightScene(size: size, mode: mode)
        }
        
        // Transition to the new scene
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(newScene, transition: transition)
    }
    
    private func returnToMainMenu() {
        // Create main menu scene
        let mainMenuScene = MainMenuScene(size: size)
        
        // Transition to main menu
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(mainMenuScene, transition: transition)
    }
    
    // MARK: - Scene Presentation
    
    class func newScene(size: CGSize, mode: GameManager.GameMode, challengeCode: String? = nil) -> FlightScene {
        if let challengeCode = challengeCode {
            return FlightScene(size: size, challengeCode: challengeCode)
        } else {
            return FlightScene(size: size, mode: mode)
        }
    }

    private func convertToGameStateMode(_ mode: GameManager.GameMode) -> GameState.Mode {
        switch mode {
        case .tutorial: return .tutorial
        case .freePlay: return .freePlay
        case .challenge: return .challenge
        case .dailyRun: return .dailyRun
        case .weeklySpecial: return .weeklySpecial
        }
    }

    private func convertFromGameStateMode(_ mode: GameState.Mode) -> GameManager.GameMode {
        switch mode {
        case .tutorial: return .tutorial
        case .freePlay: return .freePlay
        case .challenge: return .challenge
        case .dailyRun: return .dailyRun
        case .weeklySpecial: return .weeklySpecial
        }
    }
    
    // MARK: - Game State Updates
    
    private func updateGameState() {
        guard GameManager.shared.currentState.status == .playing else { return }
        
        // Update score based on game mode
        // Post score update notification instead of calling GameManager directly
        let scoreToAdd: Int
        switch gameMode {
        case .freePlay:
            scoreToAdd = calculateFreePlayScore()
        case .challenge:
            scoreToAdd = calculateChallengeScore()
        case .dailyRun:
            scoreToAdd = calculateDailyRunScore()
        case .tutorial:
            return // No scoring in tutorial mode
        case .weeklySpecial:
            scoreToAdd = calculateWeeklySpecialScore()
        }
        
        NotificationCenter.default.post(
            name: NSNotification.Name("ScoreUpdate"),
            object: self,
            userInfo: ["scoreToAdd": scoreToAdd]
        )
    }
    
    private func calculateFreePlayScore() -> Int {
        // Basic scoring for free play mode
        return Int(airplane?.position.x ?? 0)
    }
    
    private func calculateChallengeScore() -> Int {
        // Challenge mode scoring
        guard let challengeDistance = challengeDistance else { return 0 }
        let currentDistance = Int(airplane?.position.x ?? 0)
        return min(currentDistance, challengeDistance)
    }
    
    private func calculateDailyRunScore() -> Int {
        // Daily run scoring with multipliers
        let baseScore = Int(airplane?.position.x ?? 0)
        let multiplier = 1.5 // Example multiplier for daily run
        return Int(Double(baseScore) * multiplier)
    }
    
    private func calculateWeeklySpecialScore() -> Int {
        // Weekly special mode scoring
        let baseScore = Int(airplane?.position.x ?? 0)
        let multiplier = 2.0 // Example multiplier for weekly special
        return Int(Double(baseScore) * multiplier)
    }
}

// MARK: - GameEnvironment Class references
// Using GameEnvironment class from Models/Environment.swift instead of defining it here

// MARK: - ParallaxBackground Class references
// Using ParallaxBackground class from Models/ParallaxBackground.swift instead of defining it here

// MARK: - Extensions

extension SKLabelNode {
    /// Adds a shadow effect to improve visibility against varying backgrounds
    func addShadow(radius: CGFloat = 1.0, opacity: CGFloat = 0.3) {
        let shadowLabel = SKLabelNode(text: self.text)
        shadowLabel.fontName = self.fontName
        shadowLabel.fontSize = self.fontSize
        shadowLabel.fontColor = UIColor.black.withAlphaComponent(opacity)
        shadowLabel.position = CGPoint(x: radius, y: -radius)
        shadowLabel.zPosition = -1
        self.addChild(shadowLabel)
    }
}
