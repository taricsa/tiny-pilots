//
//  MainMenuScene.swift
//  Tiny Pilots
//
//  Created on 2025-03-01.
//

import SpriteKit
import GameplayKit
import SwiftUI
import GameKit
import SwiftData

/// The main menu scene for Tiny Pilots
class MainMenuScene: SKScene {
    
    // MARK: - Properties
    
    /// ViewModel for managing menu state and navigation
    private var viewModel: MainMenuViewModel!
    
    // MARK: - Node Properties
    
    // Visual elements
    private var backgroundNode: SKSpriteNode?
    private var paperAirplaneNode: SKSpriteNode?
    
    // UI elements
    private var titleLabel: SKLabelNode?
    private var playButton: SKSpriteNode?
    private var hangarButton: SKSpriteNode?
    private var settingsButton: SKSpriteNode?
    private var achievementsButton: SKSpriteNode?
    private var leaderboardsButton: SKSpriteNode?
    
    // Player info display
    private var playerLevelLabel: SKLabelNode?
    private var playerExperienceLabel: SKLabelNode?
    private var experienceProgressBar: SKShapeNode?
    
    // MARK: - Scene Lifecycle
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        // Setup scene
        backgroundColor = .systemBlue
        
        // Initialize ViewModel if not already set
        if viewModel == nil {
            setupViewModel()
        }
        
        // Initialize the ViewModel
        viewModel.initialize()
    }
    
    override func didMove(to view: SKView) {
        // Setup scene elements
        createBackground()
        createDecorations()
        createUI()
        
        // Setup accessibility
        setupAccessibility()
        
        // Setup dynamic type observer
        setupDynamicTypeObserver()
        
        // Start observing ViewModel state changes
        startObservingViewModel()
        
        // Hide debug info in release builds
        #if DEBUG
        view.showsFPS = GameConfig.Debug.showsFPS
        view.showsNodeCount = GameConfig.Debug.showsNodeCount
        #else
        view.showsFPS = false
        view.showsNodeCount = false
        #endif
        
        // Announce screen change for VoiceOver
        VoiceOverNavigationManager.shared.announceScreenChange("Main Menu")
    }
    
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        
        // Clean up ViewModel
        viewModel?.cleanup()
    }
    
    // MARK: - Background Methods
    
    /// Create the background for the menu
    private func createBackground() {
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
    
    /// Create decorative elements for the menu
    private func createDecorations() {
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
        createMenuButtons()
        createPlayerInfo()
    }
    
    /// Create the title label
    private func createTitle() {
        titleLabel = SKLabelNode(fontNamed: "Arial-Bold")
        titleLabel?.text = "Tiny Pilots"
        titleLabel?.configureDynamicType(baseSize: 48, textStyle: .largeTitle)
        titleLabel?.fontColor = .white
        titleLabel?.position = CGPoint(x: size.width / 2, y: size.height * 0.8)
        titleLabel?.zPosition = 10
        
        // Add shadow effect
        let shadowLabel = SKLabelNode(fontNamed: "Arial-Bold")
        shadowLabel.text = "Tiny Pilots"
        shadowLabel.configureDynamicType(baseSize: 48, textStyle: .largeTitle)
        shadowLabel.fontColor = .black
        shadowLabel.alpha = 0.3
        shadowLabel.position = CGPoint(x: 2, y: -2)
        titleLabel?.addChild(shadowLabel)
        
        if let titleLabel = titleLabel {
            addChild(titleLabel)
        }
    }
    
    /// Create menu buttons
    private func createMenuButtons() {
        let buttonWidth: CGFloat = 200
        let buttonHeight: CGFloat = 50
        let buttonSpacing: CGFloat = 60
        let startY = size.height * 0.6
        
        // Play button
        playButton = createButton(
            text: "Play",
            size: CGSize(width: buttonWidth, height: buttonHeight),
            position: CGPoint(x: size.width / 2, y: startY),
            name: "playButton"
        )
        
        // Hangar button
        hangarButton = createButton(
            text: "Hangar",
            size: CGSize(width: buttonWidth, height: buttonHeight),
            position: CGPoint(x: size.width / 2, y: startY - buttonSpacing),
            name: "hangarButton"
        )
        
        // Settings button
        settingsButton = createButton(
            text: "Settings",
            size: CGSize(width: buttonWidth, height: buttonHeight),
            position: CGPoint(x: size.width / 2, y: startY - buttonSpacing * 2),
            name: "settingsButton"
        )
        
        // Achievements button
        achievementsButton = createButton(
            text: "Achievements",
            size: CGSize(width: buttonWidth, height: buttonHeight),
            position: CGPoint(x: size.width / 2, y: startY - buttonSpacing * 3),
            name: "achievementsButton"
        )
        
        // Leaderboards button
        leaderboardsButton = createButton(
            text: "Leaderboards",
            size: CGSize(width: buttonWidth, height: buttonHeight),
            position: CGPoint(x: size.width / 2, y: startY - buttonSpacing * 4),
            name: "leaderboardsButton"
        )
    }
    
    /// Create a menu button
    private func createButton(text: String, size: CGSize, position: CGPoint, name: String) -> SKSpriteNode {
        let button = SKSpriteNode(color: .systemBlue, size: size)
        button.position = position
        button.zPosition = 10
        button.name = name
        
        // Add border
        let border = SKShapeNode(rectOf: size, cornerRadius: 8)
        border.strokeColor = .white
        border.lineWidth = 2
        border.fillColor = .clear
        button.addChild(border)
        
        // Add label
        let label = SKLabelNode(fontNamed: "Arial-Bold")
        label.text = text
        label.configureDynamicType(baseSize: 20, textStyle: .body)
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        button.addChild(label)
        
        addChild(button)
        return button
    }
    
    /// Create player info display
    private func createPlayerInfo() {
        // Player level
        playerLevelLabel = SKLabelNode(fontNamed: "Arial-Bold")
        playerLevelLabel?.configureDynamicType(baseSize: 18, textStyle: .headline)
        playerLevelLabel?.fontColor = .white
        playerLevelLabel?.position = CGPoint(x: 100, y: size.height - 50)
        playerLevelLabel?.zPosition = 10
        
        if let playerLevelLabel = playerLevelLabel {
            addChild(playerLevelLabel)
        }
        
        // Player experience
        playerExperienceLabel = SKLabelNode(fontNamed: "Arial")
        playerExperienceLabel?.configureDynamicType(baseSize: 14, textStyle: .body)
        playerExperienceLabel?.fontColor = .lightGray
        playerExperienceLabel?.position = CGPoint(x: 100, y: size.height - 75)
        playerExperienceLabel?.zPosition = 10
        
        if let playerExperienceLabel = playerExperienceLabel {
            addChild(playerExperienceLabel)
        }
        
        // Experience progress bar
        let progressBarWidth: CGFloat = 150
        let progressBarHeight: CGFloat = 8
        
        // Background bar
        let progressBackground = SKShapeNode(rectOf: CGSize(width: progressBarWidth, height: progressBarHeight), cornerRadius: 4)
        progressBackground.fillColor = .darkGray
        progressBackground.strokeColor = .clear
        progressBackground.position = CGPoint(x: 100, y: size.height - 95)
        progressBackground.zPosition = 10
        addChild(progressBackground)
        
        // Progress bar
        experienceProgressBar = SKShapeNode(rectOf: CGSize(width: progressBarWidth, height: progressBarHeight), cornerRadius: 4)
        experienceProgressBar?.fillColor = .systemYellow
        experienceProgressBar?.strokeColor = .clear
        experienceProgressBar?.position = CGPoint(x: 100, y: size.height - 95)
        experienceProgressBar?.zPosition = 11
        
        if let experienceProgressBar = experienceProgressBar {
            addChild(experienceProgressBar)
        }
    }
    
    // MARK: - ViewModel Observation
    
    /// Start observing ViewModel state changes
    private func startObservingViewModel() {
        // Note: With @Observable, the UI will automatically update when ViewModel properties change
        // We can add specific observation logic here if needed
        updateUI()
    }
    
    /// Update UI based on ViewModel state
    private func updateUI() {
        guard let viewModel = viewModel else { return }
        
        // Update player level
        playerLevelLabel?.text = "Level \(viewModel.playerLevel)"
        
        // Update experience
        playerExperienceLabel?.text = "XP: \(viewModel.playerExperience) / \(viewModel.experienceToNextLevel)"
        
        // Update progress bar
        let progress = CGFloat(viewModel.levelProgress)
        let progressBarWidth: CGFloat = 150
        let newWidth = progressBarWidth * progress
        experienceProgressBar?.path = CGPath(
            roundedRect: CGRect(x: -newWidth/2, y: -4, width: newWidth, height: 8),
            cornerWidth: 4,
            cornerHeight: 4,
            transform: nil
        )
        
        // Update button availability based on Game Center status
        achievementsButton?.alpha = viewModel.isGameCenterAvailable ? 1.0 : 0.5
        leaderboardsButton?.alpha = viewModel.isGameCenterAvailable ? 1.0 : 0.5
        
        // Update accessibility information
        updateAccessibility()
        
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
        let buttons = [playButton, hangarButton, settingsButton, achievementsButton, leaderboardsButton]
        
        for (index, button) in buttons.enumerated() {
            guard let button = button else { continue }
            
            button.alpha = 0
            button.position.x = -200
            
            let delay = Double(index) * 0.1
            let moveIn = SKAction.moveTo(x: size.width / 2, duration: 0.3)
            let fadeIn = SKAction.fadeIn(withDuration: 0.3)
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
        switch nodeName {
        case "playButton":
            viewModel.navigateTo(.gameMode)
        case "hangarButton":
            viewModel.navigateTo(.hangar)
        case "settingsButton":
            viewModel.navigateTo(.settings)
        case "achievementsButton":
            viewModel.showAchievements()
        case "leaderboardsButton":
            viewModel.showLeaderboards()
        default:
            break
        }
    }
    
    /// Animate button press
    private func animateButtonPress(_ button: SKSpriteNode) {
        let scaleDown = SKAction.scale(to: 0.95, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        let sequence = SKAction.sequence([scaleDown, scaleUp])
        button.run(sequence)
    }
    
    // MARK: - Accessibility Methods
    
    /// Setup accessibility for all UI elements
    private func setupAccessibility() {
        // Configure title accessibility
        titleLabel?.makeAccessibleText("Tiny Pilots")
        
        // Configure button accessibility with proper hints
        playButton?.makeAccessibleButton(
            label: "Play",
            hint: "Start playing the game. Opens game mode selection."
        )
        
        hangarButton?.makeAccessibleButton(
            label: "Hangar",
            hint: "Customize your paper airplane. Opens airplane hangar."
        )
        
        settingsButton?.makeAccessibleButton(
            label: "Settings",
            hint: "Adjust game settings. Opens settings menu."
        )
        
        achievementsButton?.makeAccessibleButton(
            label: "Achievements",
            hint: "View your game achievements. Opens Game Center achievements."
        )
        
        leaderboardsButton?.makeAccessibleButton(
            label: "Leaderboards",
            hint: "View global leaderboards. Opens Game Center leaderboards."
        )
        
        // Configure player info accessibility
        setupPlayerInfoAccessibility()
        
        // Configure decorative elements
        paperAirplaneNode?.removeAccessibility() // Decorative only
        
        // Setup navigation order
        setupAccessibilityNavigationOrder()
    }
    
    /// Setup accessibility for player info elements
    private func setupPlayerInfoAccessibility() {
        guard let viewModel = viewModel else { return }
        
        // Player level label
        playerLevelLabel?.makeAccessibleText("Level \(viewModel.playerLevel)")
        
        // Experience label with progress information
        let experienceText = "Experience: \(viewModel.playerExperience) out of \(viewModel.experienceToNextLevel)"
        playerExperienceLabel?.makeAccessibleText(experienceText)
        
        // Progress bar as adjustable element
        let progressPercent = Int(viewModel.levelProgress * 100)
        experienceProgressBar?.makeAccessibleAdjustable(
            label: "Experience progress",
            value: "\(progressPercent) percent",
            hint: "Shows progress to next level"
        )
    }
    
    /// Setup accessibility navigation order
    private func setupAccessibilityNavigationOrder() {
        let navigationOrder: [SKNode] = [
            titleLabel,
            playerLevelLabel,
            playerExperienceLabel,
            experienceProgressBar,
            playButton,
            hangarButton,
            settingsButton,
            achievementsButton,
            leaderboardsButton
        ].compactMap { $0 }
        
        VoiceOverNavigationManager.shared.setupNavigationOrder(for: navigationOrder)
    }
    
    /// Update accessibility when UI changes
    private func updateAccessibility() {
        guard let viewModel = viewModel else { return }
        
        // Update player info accessibility
        playerLevelLabel?.accessibilityLabel = "Level \(viewModel.playerLevel)"
        
        let experienceText = "Experience: \(viewModel.playerExperience) out of \(viewModel.experienceToNextLevel)"
        playerExperienceLabel?.accessibilityLabel = experienceText
        
        let progressPercent = Int(viewModel.levelProgress * 100)
        experienceProgressBar?.accessibilityValue = "\(progressPercent) percent"
        
        // Update button availability announcements
        let gameCenterStatus = viewModel.isGameCenterAvailable ? "available" : "unavailable"
        achievementsButton?.accessibilityHint = "View your game achievements. Game Center is \(gameCenterStatus)."
        leaderboardsButton?.accessibilityHint = "View global leaderboards. Game Center is \(gameCenterStatus)."
        
        // Announce significant changes
        if viewModel.levelProgress == 1.0 {
            AccessibilityManager.shared.announceMessage("Level up! You are now level \(viewModel.playerLevel)", priority: .high)
        }
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
        // Update title font
        if let titleLabel = titleLabel {
            titleLabel.fontSize = DynamicTypeHelper.shared.scaledFontSize(baseSize: 48)
        }
        if let childLabel = titleLabel?.children.first as? SKLabelNode {
            childLabel.fontSize = DynamicTypeHelper.shared.scaledFontSize(baseSize: 48)
        }
        
        // Update button fonts
        updateButtonFonts()
        
        // Update player info fonts
        playerLevelLabel?.updateDynamicType(baseSize: 18, textStyle: .headline)
        playerExperienceLabel?.updateDynamicType(baseSize: 14, textStyle: .body)
        
        // Adjust layout if needed for accessibility sizes
        if DynamicTypeHelper.shared.shouldUseCompactLayout {
            adjustLayoutForLargeText()
        }
    }
    
    /// Update fonts for all buttons
    private func updateButtonFonts() {
        let buttons = [playButton, hangarButton, settingsButton, achievementsButton, leaderboardsButton]
        
        for button in buttons {
            // Find the label child and update its font
            for child in button?.children ?? [] {
                if let label = child as? SKLabelNode {
                    label.updateDynamicType(baseSize: 20, textStyle: .body)
                }
            }
        }
    }
    
    /// Adjust layout for large text sizes
    private func adjustLayoutForLargeText() {
        // Increase button spacing for accessibility
        let buttonSpacing: CGFloat = DynamicTypeHelper.shared.scaledSpacing(80)
        let startY = size.height * 0.55 // Move buttons down slightly
        
        let buttons = [playButton, hangarButton, settingsButton, achievementsButton, leaderboardsButton]
        
        for (index, button) in buttons.enumerated() {
            button?.position.y = startY - CGFloat(index) * buttonSpacing
        }
        
        // Adjust player info position if needed
        let scaledOffset = DynamicTypeHelper.shared.scaledSpacing(50)
        playerLevelLabel?.position.y = size.height - scaledOffset
        playerExperienceLabel?.position.y = size.height - scaledOffset - 25
    }
    
    // MARK: - Navigation Methods
    
    /// Handle navigation to different screens
    func handleNavigation(to destination: NavigationDestination) {
        // Announce navigation for VoiceOver users
        AccessibilityManager.shared.announceMenuNavigation(destination.displayName)
        
        // This would typically trigger a scene transition
        // For now, we'll just log the navigation
        print("Navigating to: \(destination.displayName)")
        
        // In a real implementation, this would:
        // 1. Create the appropriate scene
        // 2. Set up the scene with necessary ViewModels
        // 3. Transition to the new scene
    }
}

// End of MainMenuScene 
