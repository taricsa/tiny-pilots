//
//  MainMenuScene.swift
//  Tiny Pilots
//
//  Created on 2025-03-01.
//

import SpriteKit
import GameplayKit

/// The main menu scene for Tiny Pilots
class MainMenuScene: SKScene {
    
    // MARK: - Node Properties
    
    // Menu buttons
    private var playButton: SKNode?
    private var hangarButton: SKNode?
    private var achievementsButton: SKNode?
    private var settingsButton: SKNode?
    private var friendsButton: SKNode?
    
    // Visual elements
    private var logoNode: SKSpriteNode?
    private var backgroundNode: SKSpriteNode?
    private var paperAirplaneNode: SKSpriteNode?
    
    // MARK: - Scene Lifecycle
    
    override func sceneDidLoad() {
        // Setup scene
        backgroundColor = .systemBlue
        
        // Create UI elements
        createBackground()
        createLogo()
        createButtons()
        createDecorations()
    }
    
    override func didMove(to view: SKView) {
        // Animate elements in
        animateSceneIn()
    }
    
    // MARK: - Setup Methods
    
    /// Create the background for the menu
    private func createBackground() {
        backgroundNode = SKSpriteNode(color: .systemBlue, size: size)
        backgroundNode?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundNode?.zPosition = -10
        
        // Add gradient overlay
        let gradientNode = SKSpriteNode(color: .clear, size: size)
        gradientNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        gradientNode.zPosition = -5
        
        // Add clouds (placeholder - in production would use proper textures)
        for _ in 0..<10 {
            let cloudSize = CGSize(width: CGFloat.random(in: 50...150), height: CGFloat.random(in: 30...80))
            let cloud = SKSpriteNode(color: .white, size: cloudSize)
            cloud.alpha = 0.7
            cloud.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: size.height * 0.5...size.height * 0.9)
            )
            cloud.zPosition = -8
            
            // Add drift animation
            let driftDuration = TimeInterval.random(in: 30...60)
            let driftDistance = size.width + cloudSize.width * 2
            let moveAction = SKAction.moveBy(x: driftDistance, y: 0, duration: driftDuration)
            let resetAction = SKAction.moveTo(x: -cloudSize.width, duration: 0)
            cloud.run(SKAction.repeatForever(SKAction.sequence([moveAction, resetAction])))
            
            addChild(cloud)
        }
        
        if let backgroundNode = backgroundNode {
            addChild(backgroundNode)
        }
        addChild(gradientNode)
    }
    
    /// Create the game logo
    private func createLogo() {
        // In a real implementation, this would use an actual logo image
        logoNode = SKSpriteNode(color: .white, size: CGSize(width: 300, height: 100))
        logoNode?.position = CGPoint(x: size.width / 2, y: size.height * 0.8)
        
        // Add text label (placeholder for actual logo graphic)
        let logoLabel = SKLabelNode(text: "TINY PILOTS")
        logoLabel.fontName = "AvenirNext-Bold"
        logoLabel.fontSize = 36
        logoLabel.fontColor = .systemBlue
        logoLabel.position = CGPoint(x: 0, y: -12) // Center in the white box
        
        logoNode?.addChild(logoLabel)
        
        if let logoNode = logoNode {
            addChild(logoNode)
        }
    }
    
    /// Create the menu buttons
    private func createButtons() {
        // Define button size and spacing
        let buttonSize = CGSize(width: 250, height: 60)
        let buttonSpacing: CGFloat = 70
        let startY = size.height * 0.45
        
        // Create button nodes
        let buttonData = [
            (title: "Play", name: "playButton"),
            (title: "Airplane Hangar", name: "hangarButton"),
            (title: "Achievements", name: "achievementsButton"),
            (title: "Settings", name: "settingsButton"),
            (title: "Friends", name: "friendsButton")
        ]
        
        for (index, data) in buttonData.enumerated() {
            let button = createButton(title: data.title, size: buttonSize)
            button.position = CGPoint(x: size.width / 2, y: startY - CGFloat(index) * buttonSpacing)
            button.name = data.name
            
            addChild(button)
            
            // Store reference to specific buttons
            switch data.name {
            case "playButton": playButton = button
            case "hangarButton": hangarButton = button
            case "achievementsButton": achievementsButton = button
            case "settingsButton": settingsButton = button
            case "friendsButton": friendsButton = button
            default: break
            }
        }
    }
    
    /// Create an individual button
    private func createButton(title: String, size: CGSize) -> SKNode {
        let button = SKNode()
        
        // Create button background
        let background = SKShapeNode(rectOf: size, cornerRadius: 10)
        background.fillColor = .white
        background.strokeColor = .darkGray
        background.lineWidth = 2
        
        // Create button label
        let label = SKLabelNode(text: title)
        label.fontName = "AvenirNext-DemiBold"
        label.fontSize = 24
        label.fontColor = .systemBlue
        label.verticalAlignmentMode = .center
        
        button.addChild(background)
        button.addChild(label)
        
        return button
    }
    
    /// Create decorative elements for the menu
    private func createDecorations() {
        // Add a paper airplane decoration that flies across the screen
        paperAirplaneNode = SKSpriteNode(color: .white, size: CGSize(width: 60, height: 40))
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
    
    // MARK: - Animation Methods
    
    /// Animate the scene elements when the scene appears
    private func animateSceneIn() {
        // Set initial states
        logoNode?.alpha = 0
        logoNode?.setScale(0.7)
        
        // Animate logo
        logoNode?.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ]))
        
        // Animate buttons
        let buttons = [playButton, hangarButton, achievementsButton, settingsButton, friendsButton]
        
        for (index, button) in buttons.enumerated() {
            button?.alpha = 0
            button?.setScale(0.8)
            
            let delay = 0.2 + 0.1 * Double(index)
            button?.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.fadeIn(withDuration: 0.3),
                    SKAction.scale(to: 1.0, duration: 0.3)
                ])
            ]))
        }
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            // Find the button node if we touched a child of it
            var buttonNode = node
            while buttonNode.name == nil && buttonNode.parent != nil {
                buttonNode = buttonNode.parent!
            }
            
            // Handle button tap
            switch buttonNode.name {
            case "playButton":
                handlePlayButtonTap()
            case "hangarButton":
                handleHangarButtonTap()
            case "achievementsButton":
                handleAchievementsButtonTap()
            case "settingsButton":
                handleSettingsButtonTap()
            case "friendsButton":
                handleFriendsButtonTap()
            default:
                break
            }
        }
    }
    
    // MARK: - Button Handlers
    
    private func handlePlayButtonTap() {
        // Animate button press
        animateButtonPress(playButton)
        
        // Present game mode selection scene
        let gameModeScene = GameModeSelectionScene(size: size)
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(gameModeScene, transition: transition)
    }
    
    private func handleHangarButtonTap() {
        // Animate button press
        animateButtonPress(hangarButton)
        
        // Present airplane customization scene
        // This would be implemented in a real game
        print("Opening airplane hangar")
    }
    
    private func handleAchievementsButtonTap() {
        // Animate button press
        animateButtonPress(achievementsButton)
        
        // Open achievements
        // This would integrate with Game Center in a real game
        print("Opening achievements")
    }
    
    private func handleSettingsButtonTap() {
        // Animate button press
        animateButtonPress(settingsButton)
        
        // Present settings scene
        // This would be implemented in a real game
        print("Opening settings")
    }
    
    private func handleFriendsButtonTap() {
        // Animate button press
        animateButtonPress(friendsButton)
        
        // Open friends list
        // This would integrate with Game Center in a real game
        print("Opening friends")
    }
    
    /// Animate a button press
    private func animateButtonPress(_ button: SKNode?) {
        guard let button = button else { return }
        
        // Scale down and back up
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        button.run(SKAction.sequence([scaleDown, scaleUp]))
    }
}

/// Game mode selection scene
class GameModeSelectionScene: SKScene {
    // MARK: - Properties
    
    // UI elements
    private var titleLabel: SKLabelNode?
    private var freeFlightButton: SKNode?
    private var challengeButton: SKNode?
    private var dailyRunButton: SKNode?
    private var backButton: SKNode?
    
    // MARK: - Scene Lifecycle
    
    override func didMove(to view: SKView) {
        // Setup scene
        backgroundColor = .systemBlue
        
        // Create UI elements
        createBackground()
        createTitle()
        createButtons()
        
        // Animate elements in
        animateSceneIn()
    }
    
    // MARK: - Setup Methods
    
    /// Create the background for the scene
    private func createBackground() {
        let backgroundNode = SKSpriteNode(color: .systemBlue, size: size)
        backgroundNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundNode.zPosition = -10
        addChild(backgroundNode)
        
        // Add gradient overlay (would use a proper gradient in production)
        let gradientNode = SKSpriteNode(color: .clear, size: size)
        gradientNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        gradientNode.zPosition = -5
        addChild(gradientNode)
    }
    
    /// Create the title label
    private func createTitle() {
        titleLabel = SKLabelNode(text: "SELECT GAME MODE")
        titleLabel?.fontName = "AvenirNext-Bold"
        titleLabel?.fontSize = 36
        titleLabel?.fontColor = .white
        titleLabel?.position = CGPoint(x: size.width / 2, y: size.height * 0.8)
        
        if let titleLabel = titleLabel {
            addChild(titleLabel)
        }
    }
    
    /// Create the mode selection buttons
    private func createButtons() {
        // Define button size and spacing
        let buttonSize = CGSize(width: 250, height: 60)
        let buttonSpacing: CGFloat = 80
        let startY = size.height * 0.55
        
        // Create button nodes
        let buttonData = [
            (title: "Free Flight", name: "freeFlightButton"),
            (title: "Challenge Mode", name: "challengeButton"),
            (title: "Daily Run", name: "dailyRunButton")
        ]
        
        for (index, data) in buttonData.enumerated() {
            let button = createButton(title: data.title, size: buttonSize)
            button.position = CGPoint(x: size.width / 2, y: startY - CGFloat(index) * buttonSpacing)
            button.name = data.name
            
            addChild(button)
            
            // Store reference to specific buttons
            switch data.name {
            case "freeFlightButton": freeFlightButton = button
            case "challengeButton": challengeButton = button
            case "dailyRunButton": dailyRunButton = button
            default: break
            }
        }
        
        // Create back button
        backButton = createButton(title: "Back", size: CGSize(width: 120, height: 50))
        backButton?.position = CGPoint(x: 80, y: 50)
        backButton?.name = "backButton"
        
        if let backButton = backButton {
            addChild(backButton)
        }
    }
    
    /// Create an individual button
    private func createButton(title: String, size: CGSize) -> SKNode {
        let button = SKNode()
        
        // Create button background
        let background = SKShapeNode(rectOf: size, cornerRadius: 10)
        background.fillColor = .white
        background.strokeColor = .darkGray
        background.lineWidth = 2
        
        // Create button label
        let label = SKLabelNode(text: title)
        label.fontName = "AvenirNext-DemiBold"
        label.fontSize = 24
        label.fontColor = .systemBlue
        label.verticalAlignmentMode = .center
        
        button.addChild(background)
        button.addChild(label)
        
        return button
    }
    
    // MARK: - Animation Methods
    
    /// Animate the scene elements when the scene appears
    private func animateSceneIn() {
        // Set initial states
        titleLabel?.alpha = 0
        titleLabel?.setScale(0.7)
        
        // Animate title
        titleLabel?.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ]))
        
        // Animate buttons
        let buttons = [freeFlightButton, challengeButton, dailyRunButton, backButton]
        
        for (index, button) in buttons.enumerated() {
            button?.alpha = 0
            button?.setScale(0.8)
            
            let delay = 0.2 + 0.1 * Double(index)
            button?.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.fadeIn(withDuration: 0.3),
                    SKAction.scale(to: 1.0, duration: 0.3)
                ])
            ]))
        }
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            // Find the button node if we touched a child of it
            var buttonNode = node
            while buttonNode.name == nil && buttonNode.parent != nil {
                buttonNode = buttonNode.parent!
            }
            
            // Handle button tap
            switch buttonNode.name {
            case "freeFlightButton":
                handleFreeFlightButtonTap()
            case "challengeButton":
                handleChallengeButtonTap()
            case "dailyRunButton":
                handleDailyRunButtonTap()
            case "backButton":
                handleBackButtonTap()
            default:
                break
            }
        }
    }
    
    // MARK: - Button Handlers
    
    private func handleFreeFlightButtonTap() {
        // Animate button press
        animateButtonPress(freeFlightButton)
        
        // Set game mode to free flight
        GameManager.shared.currentMode = .freeFlight
        
        // Present flight scene
        let flightScene = FlightScene(size: size)
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(flightScene, transition: transition)
    }
    
    private func handleChallengeButtonTap() {
        // Animate button press
        animateButtonPress(challengeButton)
        
        // Set game mode to challenge
        GameManager.shared.currentMode = .challenge
        
        // Present flight scene with challenge mode
        let flightScene = FlightScene(size: size)
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(flightScene, transition: transition)
    }
    
    private func handleDailyRunButtonTap() {
        // Animate button press
        animateButtonPress(dailyRunButton)
        
        // Check if player can participate in daily run
        if GameManager.shared.canParticipateDailyRun() {
            // Set game mode to daily run
            GameManager.shared.currentMode = .dailyRun
            
            // Record participation
            GameManager.shared.recordDailyRunParticipation()
            
            // Present flight scene with daily run mode
            let flightScene = FlightScene(size: size)
            let transition = SKTransition.fade(withDuration: 0.5)
            view?.presentScene(flightScene, transition: transition)
        } else {
            // Show message that daily run is already completed
            showDailyRunCompletedMessage()
        }
    }
    
    private func handleBackButtonTap() {
        // Animate button press
        animateButtonPress(backButton)
        
        // Return to main menu
        let mainMenuScene = MainMenuScene(size: size)
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(mainMenuScene, transition: transition)
    }
    
    /// Animate a button press
    private func animateButtonPress(_ button: SKNode?) {
        guard let button = button else { return }
        
        // Scale down and back up
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        button.run(SKAction.sequence([scaleDown, scaleUp]))
    }
    
    /// Show a message that the daily run is already completed
    private func showDailyRunCompletedMessage() {
        // Create message background
        let messageBackground = SKShapeNode(rectOf: CGSize(width: 400, height: 200), cornerRadius: 20)
        messageBackground.fillColor = .white
        messageBackground.strokeColor = .darkGray
        messageBackground.lineWidth = 2
        messageBackground.position = CGPoint(x: size.width / 2, y: size.height / 2)
        messageBackground.zPosition = 100
        messageBackground.name = "messageBackground"
        
        // Create message text
        let messageText = SKLabelNode(text: "Daily Run Already Completed")
        messageText.fontName = "AvenirNext-Bold"
        messageText.fontSize = 24
        messageText.fontColor = .systemBlue
        messageText.position = CGPoint(x: 0, y: 30)
        
        // Create subtext
        let subText = SKLabelNode(text: "Come back tomorrow for a new run!")
        subText.fontName = "AvenirNext-Regular"
        subText.fontSize = 18
        subText.fontColor = .darkGray
        subText.position = CGPoint(x: 0, y: -10)
        
        // Create OK button
        let okButton = SKShapeNode(rectOf: CGSize(width: 100, height: 40), cornerRadius: 10)
        okButton.fillColor = .systemBlue
        okButton.strokeColor = .darkGray
        okButton.lineWidth = 1
        okButton.position = CGPoint(x: 0, y: -60)
        okButton.name = "okButton"
        
        let okText = SKLabelNode(text: "OK")
        okText.fontName = "AvenirNext-Bold"
        okText.fontSize = 20
        okText.fontColor = .white
        okText.verticalAlignmentMode = .center
        okButton.addChild(okText)
        
        // Add to scene
        messageBackground.addChild(messageText)
        messageBackground.addChild(subText)
        messageBackground.addChild(okButton)
        addChild(messageBackground)
        
        // Add tap handler for OK button
        let tapHandler = SKAction.run { [weak self] in
            self?.childNode(withName: "messageBackground")?.removeFromParent()
        }
        
        okButton.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.1), // Small delay to prevent accidental taps
            tapHandler
        ]))
    }
} 