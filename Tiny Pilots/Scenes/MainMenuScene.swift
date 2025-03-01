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
    // This would be implemented in a real game
    // For now it's just a placeholder for the scene flow
} 