import SpriteKit
import UIKit
import SwiftData

/// Game mode selection scene for choosing game modes
class GameModeSelectionScene: SKScene {
    
    // MARK: - Properties
    
    /// ViewModel for managing menu state and game mode selection
    private var viewModel: MainMenuViewModel!
    
    // MARK: - UI Elements
    
    private var titleLabel: SKLabelNode?
    private var backButton: SKSpriteNode?
    private var gameModeButtons: [SKSpriteNode] = []
    
    // Track frame count
    private var frameCount: Int = 0
    
    // MARK: - Scene Lifecycle
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        // Initialize ViewModel if not already set
        if viewModel == nil {
            setupViewModel()
        }
        
        // Initialize the ViewModel
        viewModel.initialize()
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        print("GameModeSelectionScene: didMove called")
        
        // Set background color directly matching MainMenuScene
        backgroundColor = .systemBlue
        
        // Configure the scene using the exact same approach as MainMenuScene
        createBackground()
        createDecorations()
        createUI()
        
        // Start observing ViewModel state changes
        startObservingViewModel()
        
        print("GameModeSelectionScene: background configuration complete")
    }
    
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        
        // Clean up ViewModel
        viewModel?.cleanup()
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        // This will print on the first frame rendered
        if frameCount == 0 {
            print("GameModeSelectionScene: first frame rendered")
        }
        frameCount += 1
    }
    
    // Visual elements - matching MainMenuScene
    private var backgroundNode: SKSpriteNode?
    private var paperAirplaneNode: SKSpriteNode?
    
    /// Create the background - EXACT copy from MainMenuScene
    private func createBackground() {
        print("GameModeSelectionScene: creating background (MainMenuScene style)")
        
        // Create layered background for parallax effect
        let layers = 3
        let baseSpeed: CGFloat = 30.0
        
        // Create gradient background
        backgroundNode = SKSpriteNode(color: .systemBlue, size: size)
        backgroundNode?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundNode?.zPosition = -20
        
        // Add gradient overlay for depth if it exists
        var gradientNode: SKSpriteNode?
        if let _ = UIImage(named: "gradient_overlay") {
            gradientNode = SKSpriteNode(imageNamed: "gradient_overlay")
            gradientNode?.size = size
            gradientNode?.position = CGPoint(x: size.width / 2, y: size.height / 2)
            gradientNode?.zPosition = -15
            gradientNode?.alpha = 0.4
        }
        
        // Create cloud layers with different speeds for parallax effect
        for layer in 0..<layers {
            let layerNode = SKNode()
            layerNode.zPosition = CGFloat(-10 + layer)
            
            let cloudCount = 6 - layer * 2 // Fewer clouds in back layers
            let layerSpeed = baseSpeed * (CGFloat(layer + 1) / CGFloat(layers))
            let scale = 0.6 + CGFloat(layer) * 0.2 // Larger clouds in front
            let alpha = 0.4 + CGFloat(layer) * 0.2 // More opaque in front
            
            for _ in 0..<cloudCount {
                let cloudSize = CGSize(
                    width: CGFloat.random(in: 60...180) * scale,
                    height: CGFloat.random(in: 40...100) * scale
                )
                let cloud = SKShapeNode(rectOf: cloudSize, cornerRadius: cloudSize.height / 2)
                cloud.fillColor = .white
                cloud.strokeColor = .clear
                cloud.alpha = alpha
                cloud.position = CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: size.height * 0.3...size.height * 0.9)
                )
                
                // Add drift animation with parallax effect
                let driftDuration = TimeInterval(size.width / layerSpeed)
                let moveAction = SKAction.moveBy(x: size.width + cloudSize.width * 2, y: 0, duration: driftDuration)
                let resetAction = SKAction.moveTo(x: -cloudSize.width, duration: 0)
                cloud.run(SKAction.repeatForever(SKAction.sequence([moveAction, resetAction])))
                
                layerNode.addChild(cloud)
            }
            
            addChild(layerNode)
        }
        
        if let backgroundNode = backgroundNode {
            addChild(backgroundNode)
        }
        
        if let gradientNode = gradientNode {
            addChild(gradientNode)
        }
        
        // Add subtle color animation to background
        let colorChange = SKAction.customAction(withDuration: 10.0) { node, time in
            let progress = time / 10.0
            let hue = CGFloat(sin(progress * .pi * 2) * 0.05 + 0.6) // Subtle blue variation
            self.backgroundNode?.color = UIColor(hue: hue, saturation: 0.6, brightness: 1.0, alpha: 1.0)
        }
        backgroundNode?.run(SKAction.repeatForever(colorChange))
    }
    
    /// Create decorative elements for the menu - EXACT copy from MainMenuScene
    private func createDecorations() {
        print("GameModeSelectionScene: creating decorations (MainMenuScene style)")
        
        // Add a paper airplane decoration that flies across the screen
        paperAirplaneNode = SKSpriteNode(imageNamed: "paperplane")
        paperAirplaneNode?.size = CGSize(width: 60, height: 40)
        paperAirplaneNode?.position = CGPoint(x: -30, y: size.height * 0.6)
        paperAirplaneNode?.zRotation = CGFloat.pi * 0.1 // Slight angle
        
        if let paperAirplaneNode = paperAirplaneNode {
            addChild(paperAirplaneNode)
            
            // Animate the paper airplane flying across the screen
            let flyPath = CGMutablePath()
            flyPath.move(to: CGPoint(x: -30, y: size.height * 0.6))
            flyPath.addCurve(
                to: CGPoint(x: size.width + 30, y: size.height * 0.5),
                control1: CGPoint(x: size.width * 0.3, y: size.height * 0.7),
                control2: CGPoint(x: size.width * 0.7, y: size.height * 0.6)
            )
            
            let followPath = SKAction.follow(
                flyPath,
                asOffset: false,
                orientToPath: true,
                duration: 10.0
            )
            
            let resetPosition = SKAction.moveTo(x: -30, duration: 0)
            paperAirplaneNode.run(SKAction.repeatForever(SKAction.sequence([followPath, resetPosition])))
        }
    }
    
    private func createSimpleParticles() {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: "spark") // Use a system texture if available
        emitter.position = CGPoint(x: size.width / 2, y: size.height)
        emitter.particleBirthRate = 2.0
        emitter.numParticlesToEmit = 100
        emitter.particleLifetime = 20.0
        emitter.particleSpeed = 10.0
        emitter.particleSpeedRange = 5.0
        emitter.particleAlpha = 0.3
        emitter.particleAlphaRange = 0.2
        emitter.particleScale = 0.1
        emitter.particleScaleRange = 0.05
        emitter.emissionAngle = CGFloat.pi * 1.5 // Downward
        emitter.emissionAngleRange = CGFloat.pi / 4
        emitter.particleColor = .white
        emitter.zPosition = -8
        
        // Fallback if "spark" isn't available - create circular nodes instead
        if emitter.particleTexture == nil {
            print("GameModeSelectionScene: No particle texture, creating simple particles manually")
            // Don't add the emitter, manually create particle-like elements
            for _ in 0..<20 {
                let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...3))
                particle.fillColor = .white
                particle.strokeColor = .clear
                particle.alpha = CGFloat.random(in: 0.1...0.3)
                particle.position = CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                )
                particle.zPosition = -8
                
                // Add gentle floating animation
                let moveAction = SKAction.moveBy(
                    x: CGFloat.random(in: -30...30),
                    y: CGFloat.random(in: -100...0),
                    duration: TimeInterval.random(in: 15...30)
                )
                particle.run(SKAction.repeatForever(moveAction))
                
                addChild(particle)
            }
        } else {
            addChild(emitter)
        }
    }
    
    private func addDecorations() {
        // Add a paper airplane decoration that flies across the screen
        let paperAirplaneNode = SKSpriteNode(imageNamed: "paperplane")
        paperAirplaneNode.size = CGSize(width: 60, height: 40)
        paperAirplaneNode.position = CGPoint(x: -30, y: size.height * 0.6)
        paperAirplaneNode.zRotation = CGFloat.pi * 0.1 // Slight angle
        paperAirplaneNode.zPosition = -5
        addChild(paperAirplaneNode)
        
        // Animate the paper airplane flying across the screen
        let flyPath = CGMutablePath()
        flyPath.move(to: CGPoint(x: -30, y: size.height * 0.6))
        flyPath.addCurve(
            to: CGPoint(x: size.width + 30, y: size.height * 0.5),
            control1: CGPoint(x: size.width * 0.3, y: size.height * 0.7),
            control2: CGPoint(x: size.width * 0.7, y: size.height * 0.6)
        )
        
        let followPath = SKAction.follow(
            flyPath,
            asOffset: false,
            orientToPath: true,
            duration: 10.0
        )
        
        let resetPosition = SKAction.moveTo(x: -30, duration: 0)
        paperAirplaneNode.run(SKAction.repeatForever(SKAction.sequence([followPath, resetPosition])))
        
        // Add a few paper airplane silhouettes floating in the background
        for _ in 0..<3 {
            let planeSize = CGFloat.random(in: 30...50)
            let plane = SKSpriteNode(color: .clear, size: CGSize(width: planeSize, height: planeSize * 0.6))
            
            // Create a paper airplane shape
            let planeShape = SKShapeNode()
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -planeSize/2, y: 0))
            path.addLine(to: CGPoint(x: planeSize/2, y: 0))
            path.addLine(to: CGPoint(x: 0, y: planeSize/2))
            path.close()
            planeShape.path = path.cgPath
            planeShape.fillColor = .white
            planeShape.strokeColor = .clear
            planeShape.alpha = 0.3
            plane.addChild(planeShape)
            
            // Position randomly
            plane.position = CGPoint(
                x: CGFloat.random(in: 0...self.size.width),
                y: CGFloat.random(in: 0...self.size.height)
            )
            plane.zPosition = -5
            plane.zRotation = CGFloat.random(in: 0...CGFloat.pi*2)
            
            // Add floating motion
            let duration = TimeInterval.random(in: 20...40)
            let pathAction = SKAction.follow(
                createRandomPath(from: plane.position, radius: 200),
                asOffset: false,
                orientToPath: true,
                duration: duration
            )
            plane.run(SKAction.repeatForever(pathAction))
            
            addChild(plane)
        }
    }
    
    private func createRandomPath(from startPoint: CGPoint, radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: startPoint)
        
        // Create 3-5 random points to form a path
        let pointCount = Int.random(in: 3...5)
        var lastPoint = startPoint
        
        for _ in 0..<pointCount {
            let angle = CGFloat.random(in: 0...CGFloat.pi*2)
            let distance = CGFloat.random(in: radius/2...radius)
            let x = lastPoint.x + cos(angle) * distance
            let y = lastPoint.y + sin(angle) * distance
            
            // Keep points within the scene bounds
            let boundedX = max(50, min(size.width - 50, x))
            let boundedY = max(50, min(size.height - 50, y))
            
            let newPoint = CGPoint(x: boundedX, y: boundedY)
            path.addLine(to: newPoint)
            lastPoint = newPoint
        }
        
        // Close the loop
        path.addLine(to: startPoint)
        
        return path
    }
    
    // MARK: - Setup Methods
    
    /// Set the ViewModel for this scene
    /// - Parameter viewModel: The MainMenuViewModel to use
    func setViewModel(_ viewModel: MainMenuViewModel) {
        self.viewModel = viewModel
    }
    
    /// Setup the ViewModel using dependency injection
    private func setupViewModel() {
        do {
            let gameCenterService = try DIContainer.shared.resolve(GameCenterServiceProtocol.self)
            let audioService = try DIContainer.shared.resolve(AudioServiceProtocol.self)
            let modelContext = try DIContainer.shared.resolve(ModelContext.self)
            
            viewModel = MainMenuViewModel(
                gameCenterService: gameCenterService,
                audioService: audioService,
                modelContext: modelContext
            )
        } catch {
            fatalError("Failed to setup MainMenuViewModel: \(error)")
        }
    }
    
    /// Create UI elements
    private func createUI() {
        createTitle()
        createBackButton()
        createGameModeButtons()
    }
    
    /// Create the title label
    private func createTitle() {
        titleLabel = SKLabelNode(fontNamed: "Arial-Bold")
        titleLabel?.text = "Select Game Mode"
        titleLabel?.fontSize = 36
        titleLabel?.fontColor = .white
        titleLabel?.position = CGPoint(x: size.width / 2, y: size.height - 80)
        titleLabel?.zPosition = 10
        
        if let titleLabel = titleLabel {
            addChild(titleLabel)
        }
    }
    
    /// Create back button
    private func createBackButton() {
        backButton = SKSpriteNode(color: .systemGray, size: CGSize(width: 100, height: 40))
        backButton?.position = CGPoint(x: 70, y: size.height - 60)
        backButton?.zPosition = 10
        backButton?.name = "backButton"
        
        // Add border
        let border = SKShapeNode(rectOf: CGSize(width: 100, height: 40), cornerRadius: 8)
        border.strokeColor = .white
        border.lineWidth = 2
        border.fillColor = .clear
        backButton?.addChild(border)
        
        // Add label
        let label = SKLabelNode(fontNamed: "Arial-Bold")
        label.text = "Back"
        label.fontSize = 16
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        backButton?.addChild(label)
        
        if let backButton = backButton {
            addChild(backButton)
        }
    }
    
    /// Create game mode buttons
    private func createGameModeButtons() {
        guard let viewModel = viewModel else { return }
        
        let buttonWidth: CGFloat = 300
        let buttonHeight: CGFloat = 80
        let buttonSpacing: CGFloat = 100
        let startY = size.height * 0.7
        
        // Clear existing buttons
        gameModeButtons.forEach { $0.removeFromParent() }
        gameModeButtons.removeAll()
        
        // Create buttons for available game modes
        for (index, gameMode) in viewModel.availableGameModes.enumerated() {
            let button = createGameModeButton(
                gameMode: gameMode,
                size: CGSize(width: buttonWidth, height: buttonHeight),
                position: CGPoint(x: size.width / 2, y: startY - CGFloat(index) * buttonSpacing)
            )
            gameModeButtons.append(button)
        }
    }
    
    /// Create a game mode button
    private func createGameModeButton(gameMode: GameMode, size: CGSize, position: CGPoint) -> SKSpriteNode {
        let button = SKSpriteNode(color: .systemBlue, size: size)
        button.position = position
        button.zPosition = 10
        button.name = "gameMode_\(gameMode.rawValue)"
        
        // Add border
        let border = SKShapeNode(rectOf: size, cornerRadius: 12)
        border.strokeColor = .white
        border.lineWidth = 3
        border.fillColor = .clear
        button.addChild(border)
        
        // Add icon (if available)
        let iconLabel = SKLabelNode(text: gameMode.iconName)
        iconLabel.fontSize = 24
        iconLabel.fontColor = .white
        iconLabel.position = CGPoint(x: -size.width/2 + 40, y: 10)
        button.addChild(iconLabel)
        
        // Add title
        let titleLabel = SKLabelNode(fontNamed: "Arial-Bold")
        titleLabel.text = gameMode.displayName
        titleLabel.fontSize = 24
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: 15)
        titleLabel.horizontalAlignmentMode = .center
        button.addChild(titleLabel)
        
        // Add description
        let descLabel = SKLabelNode(fontNamed: "Arial")
        descLabel.text = gameMode.description
        descLabel.fontSize = 14
        descLabel.fontColor = .lightGray
        descLabel.position = CGPoint(x: 0, y: -15)
        descLabel.horizontalAlignmentMode = .center
        button.addChild(descLabel)
        
        // Add level requirement if needed
        if let playerLevel = viewModel.playerData?.level, playerLevel < gameMode.requiredLevel {
            let lockLabel = SKLabelNode(text: "🔒")
            lockLabel.fontSize = 20
            lockLabel.position = CGPoint(x: size.width/2 - 30, y: 0)
            button.addChild(lockLabel)
            
            let reqLabel = SKLabelNode(fontNamed: "Arial")
            reqLabel.text = "Level \(gameMode.requiredLevel)"
            reqLabel.fontSize = 12
            reqLabel.fontColor = .systemRed
            reqLabel.position = CGPoint(x: size.width/2 - 30, y: -20)
            reqLabel.horizontalAlignmentMode = .center
            button.addChild(reqLabel)
            
            // Dim the button
            button.alpha = 0.6
        }
        
        addChild(button)
        return button
    }
    
    // MARK: - ViewModel Observation
    
    /// Start observing ViewModel state changes
    private func startObservingViewModel() {
        // Note: With @Observable, the UI will automatically update when ViewModel properties change
        updateUI()
    }
    
    /// Update UI based on ViewModel state
    private func updateUI() {
        guard let viewModel = viewModel else { return }
        
        // Update game mode buttons based on available modes
        createGameModeButtons()
        
        // Handle animations
        if viewModel.animateTitle {
            animateTitle()
        }
        
        if viewModel.animateButtons {
            animateButtons()
        }
    }
    
    // MARK: - Animation Methods
    
    /// Animate title entrance
    private func animateTitle() {
        guard let titleLabel = titleLabel else { return }
        
        titleLabel.alpha = 0
        titleLabel.setScale(0.5)
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.5)
        let group = SKAction.group([fadeIn, scaleUp])
        
        titleLabel.run(group)
    }
    
    /// Animate buttons entrance
    private func animateButtons() {
        for (index, button) in gameModeButtons.enumerated() {
            button.alpha = 0
            button.position.x = -200
            
            let delay = Double(index) * 0.15
            let moveIn = SKAction.moveTo(x: size.width / 2, duration: 0.4)
            let fadeIn = SKAction.fadeIn(withDuration: 0.4)
            let group = SKAction.group([moveIn, fadeIn])
            let sequence = SKAction.sequence([SKAction.wait(forDuration: delay), group])
            
            button.run(sequence)
        }
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        handleButtonTap(touchedNode)
    }
    
    /// Handle button tap
    private func handleButtonTap(_ node: SKNode) {
        guard let nodeName = node.name ?? node.parent?.name else { return }
        
        // Add button press animation
        if let button = node as? SKSpriteNode ?? node.parent as? SKSpriteNode {
            animateButtonPress(button)
        }
        
        // Handle navigation through ViewModel
        if nodeName == "backButton" {
            // Navigate back to main menu
            viewModel.dismissAllModals()
        } else if nodeName.hasPrefix("gameMode_") {
            let modeString = String(nodeName.dropFirst("gameMode_".count))
            if let gameMode = GameMode(rawValue: modeString) {
                // Check if player meets level requirement
                if let playerLevel = viewModel.playerData?.level, playerLevel >= gameMode.requiredLevel {
                    viewModel.startGame(mode: gameMode)
                } else {
                    // Show level requirement message
                    showLevelRequirementMessage(for: gameMode)
                }
            }
        }
    }
    
    /// Animate button press
    private func animateButtonPress(_ button: SKSpriteNode) {
        let scaleDown = SKAction.scale(to: 0.95, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        let sequence = SKAction.sequence([scaleDown, scaleUp])
        button.run(sequence)
    }
    
    /// Show level requirement message
    private func showLevelRequirementMessage(for gameMode: GameMode) {
        // Create temporary message label
        let messageLabel = SKLabelNode(fontNamed: "Arial-Bold")
        messageLabel.text = "Reach level \(gameMode.requiredLevel) to unlock \(gameMode.displayName)"
        messageLabel.fontSize = 18
        messageLabel.fontColor = .systemRed
        messageLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        messageLabel.zPosition = 100
        messageLabel.alpha = 0
        
        addChild(messageLabel)
        
        // Animate message
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let wait = SKAction.wait(forDuration: 2.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fadeIn, wait, fadeOut, remove])
        
        messageLabel.run(sequence)
    }
} 