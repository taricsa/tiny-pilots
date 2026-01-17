import SpriteKit
import SwiftData

/// A class that manages progression-related UI overlays and animations
class ProgressionOverlay {
    
    // MARK: - Properties
    
    /// The scene to add overlays to
    private weak var scene: SKScene?
    
    /// The ViewModel providing player data
    private weak var viewModel: BaseViewModel?
    
    /// The current level-up animation (if any)
    private var currentLevelUpNode: SKNode?
    
    /// The current unlock animation (if any)
    private var currentUnlockNode: SKNode?
    
    /// The XP bar node
    private var xpBarNode: SKNode?
    
    /// Player data for progression display
    private var playerData: PlayerData?
    
    // MARK: - Initialization
    
    /// Initialize with a scene and ViewModel
    init(scene: SKScene, viewModel: BaseViewModel? = nil) {
        self.scene = scene
        self.viewModel = viewModel
        loadPlayerData()
        setupXPBar()
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    /// Load player data from SwiftData
    private func loadPlayerData() {
        // Try to get player data from ViewModel first
        if let gameViewModel = viewModel as? GameViewModel {
            // GameViewModel has playerData property
            // This would need to be exposed or we need a different approach
        } else if let mainMenuViewModel = viewModel as? MainMenuViewModel {
            // MainMenuViewModel has playerData property
            // This would need to be exposed or we need a different approach
        }
        
        // For now, load directly from SwiftData
        // In a real implementation, this should be provided by the ViewModel
        do {
            let modelContext = try DIContainer.shared.resolve(ModelContext.self)
            let fetchDescriptor = FetchDescriptor<PlayerData>()
            let players = try modelContext.fetch(fetchDescriptor)
            playerData = players.first
        } catch {
            print("Failed to load player data: \(error)")
        }
    }
    
    /// Set up the XP bar
    private func setupXPBar() {
        guard let scene = scene else { return }
        
        // Create XP bar container
        let container = SKNode()
        container.position = CGPoint(x: scene.size.width - 200, y: scene.size.height - 40)
        container.zPosition = 100
        
        // Create background bar
        let barBackground = SKShapeNode(rectOf: CGSize(width: 150, height: 10), cornerRadius: 5)
        barBackground.fillColor = .darkGray
        barBackground.strokeColor = .white
        barBackground.alpha = 0.8
        container.addChild(barBackground)
        
        // Create fill bar
        let fillBar = SKShapeNode(rectOf: CGSize(width: 0, height: 10), cornerRadius: 5)
        fillBar.fillColor = .systemBlue
        fillBar.strokeColor = .clear
        fillBar.name = "fillBar"
        fillBar.position = CGPoint(x: -75, y: 0) // Left-aligned
        container.addChild(fillBar)
        
        // Create level label
        let currentLevel = playerData?.level ?? 1
        let levelLabel = SKLabelNode(text: "Level \(currentLevel)")
        levelLabel.fontName = "AvenirNext-Bold"
        levelLabel.fontSize = 16
        levelLabel.fontColor = .white
        levelLabel.position = CGPoint(x: -75, y: 15)
        levelLabel.name = "levelLabel"
        container.addChild(levelLabel)
        
        // Create XP label
        let xpLabel = SKLabelNode(text: "0/100 XP")
        xpLabel.fontName = "AvenirNext-Medium"
        xpLabel.fontSize = 12
        xpLabel.fontColor = .white
        xpLabel.position = CGPoint(x: 0, y: -20)
        xpLabel.name = "xpLabel"
        container.addChild(xpLabel)
        
        xpBarNode = container
        scene.addChild(container)
        
        updateXPBar(animated: false)
    }
    
    /// Set up notification observers
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLevelUp),
            name: Notification.Name("playerDidLevelUp"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleContentUnlock),
            name: Notification.Name("contentDidUnlock"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleXPGain),
            name: Notification.Name("gameDidEnd"),
            object: nil
        )
    }
    
    // MARK: - Update Methods
    
    /// Update the XP bar display
    private func updateXPBar(animated: Bool = true) {
        guard let fillBar = xpBarNode?.childNode(withName: "fillBar") as? SKShapeNode,
              let levelLabel = xpBarNode?.childNode(withName: "levelLabel") as? SKLabelNode,
              let xpLabel = xpBarNode?.childNode(withName: "xpLabel") as? SKLabelNode,
              let playerData = playerData else {
            return
        }
        
        let currentXP = playerData.experiencePoints
        let currentLevel = playerData.level
        let nextLevelXP = playerData.experienceToNextLevel + currentXP
        let previousLevelXP = currentXP - (currentXP % 100) // Simplified calculation
        let levelProgress = Float(currentXP - previousLevelXP) / Float(nextLevelXP - previousLevelXP)
        
        // Update labels
        levelLabel.text = "Level \(currentLevel)"
        xpLabel.text = "\(currentXP - previousLevelXP)/\(nextLevelXP - previousLevelXP) XP"
        
        // Update fill bar
        let targetWidth = CGFloat(levelProgress) * 150
        if animated {
            let fillAction = SKAction.resize(toWidth: targetWidth, duration: 0.3)
            fillBar.run(fillAction)
        } else {
            fillBar.xScale = targetWidth / 150
        }
    }
    
    /// Update player data and refresh UI
    func updatePlayerData(_ newPlayerData: PlayerData) {
        playerData = newPlayerData
        updateXPBar(animated: true)
    }
    
    // MARK: - Notification Handlers
    
    @objc private func handleLevelUp(_ notification: Notification) {
        guard let level = notification.userInfo?["level"] as? Int else { return }
        showLevelUpAnimation(level: level)
        updateXPBar()
    }
    
    @objc private func handleContentUnlock(_ notification: Notification) {
        guard let type = notification.userInfo?["type"] as? String,
              let id = notification.userInfo?["id"] else { return }
        showUnlockAnimation(type: type, id: id)
    }
    
    @objc private func handleXPGain(_ notification: Notification) {
        guard let earnedXP = notification.userInfo?["earnedXP"] as? Int else { return }
        showXPGainAnimation(xp: earnedXP)
        updateXPBar()
    }
    
    // MARK: - Animations
    
    /// Show level up animation
    private func showLevelUpAnimation(level: Int) {
        guard let scene = scene else { return }
        
        // Remove any existing animation
        currentLevelUpNode?.removeFromParent()
        
        // Create level up container
        let container = SKNode()
        container.position = CGPoint(x: scene.size.width/2, y: scene.size.height/2)
        container.zPosition = 1000
        
        // Create background
        let background = SKShapeNode(rectOf: CGSize(width: 300, height: 200), cornerRadius: 20)
        background.fillColor = .black
        background.strokeColor = .white
        background.alpha = 0.9
        container.addChild(background)
        
        // Create level up text
        let levelText = SKLabelNode(text: "LEVEL UP!")
        levelText.fontName = "AvenirNext-Bold"
        levelText.fontSize = 36
        levelText.fontColor = .white
        levelText.position = CGPoint(x: 0, y: 40)
        container.addChild(levelText)
        
        // Create level number
        let levelNumber = SKLabelNode(text: "\(level)")
        levelNumber.fontName = "AvenirNext-Bold"
        levelNumber.fontSize = 48
        levelNumber.fontColor = .systemBlue
        levelNumber.position = CGPoint(x: 0, y: -20)
        container.addChild(levelNumber)
        
        // Add shine effect
        let shine = SKSpriteNode(color: .white, size: CGSize(width: 400, height: 10))
        shine.alpha = 0.5
        shine.position = CGPoint(x: -200, y: 0)
        container.addChild(shine)
        
        // Animate shine across the text
        let shineAction = SKAction.sequence([
            SKAction.moveBy(x: 400, y: 0, duration: 1.0),
            SKAction.removeFromParent()
        ])
        shine.run(shineAction)
        
        // Scale in animation
        container.setScale(0)
        let scaleAction = SKAction.scale(to: 1.0, duration: 0.3)
        container.run(scaleAction)
        
        // Dismiss after delay
        let dismissAction = SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])
        container.run(dismissAction)
        
        scene.addChild(container)
        currentLevelUpNode = container
    }
    
    /// Show unlock animation
    private func showUnlockAnimation(type: String, id: Any) {
        guard let scene = scene else { return }
        
        // Remove any existing animation
        currentUnlockNode?.removeFromParent()
        
        // Create unlock container
        let container = SKNode()
        container.position = CGPoint(x: scene.size.width/2, y: scene.size.height * 0.7)
        container.zPosition = 1000
        
        // Create background
        let background = SKShapeNode(rectOf: CGSize(width: 300, height: 100), cornerRadius: 15)
        background.fillColor = .black
        background.strokeColor = .white
        background.alpha = 0.9
        container.addChild(background)
        
        // Create unlock text
        let unlockText = SKLabelNode(text: "New Unlock!")
        unlockText.fontName = "AvenirNext-Bold"
        unlockText.fontSize = 24
        unlockText.fontColor = .white
        unlockText.position = CGPoint(x: 0, y: 20)
        container.addChild(unlockText)
        
        // Create item text
        let itemName: String
        switch type {
        case "environment":
            if let index = id as? Int,
               let envTypeString = String(index) as String?,
               let envType = GameEnvironment.EnvironmentType(rawValue: envTypeString) {
                itemName = envType.displayName
            } else {
                itemName = "New Environment"
            }
        case "airplaneDesign":
            itemName = (id as? String) ?? "New Design"
        case "foldType":
            itemName = (id as? String) ?? "New Fold Type"
        default:
            itemName = "New Item"
        }
        
        let itemText = SKLabelNode(text: itemName)
        itemText.fontName = "AvenirNext-Medium"
        itemText.fontSize = 20
        itemText.fontColor = .systemBlue
        itemText.position = CGPoint(x: 0, y: -15)
        container.addChild(itemText)
        
        // Slide in from top
        container.position.y += 100
        let slideAction = SKAction.moveBy(x: 0, y: -100, duration: 0.3)
        container.run(slideAction)
        
        // Dismiss after delay
        let dismissAction = SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.moveBy(x: 0, y: -50, duration: 0.3)
            ]),
            SKAction.removeFromParent()
        ])
        container.run(dismissAction)
        
        scene.addChild(container)
        currentUnlockNode = container
    }
    
    /// Show XP gain animation
    private func showXPGainAnimation(xp: Int) {
        guard let scene = scene, let xpBarNode = xpBarNode else { return }
        
        // Create XP text
        let xpText = SKLabelNode(text: "+\(xp) XP")
        xpText.fontName = "AvenirNext-Bold"
        xpText.fontSize = 24
        xpText.fontColor = .systemBlue
        xpText.position = CGPoint(x: scene.size.width/2, y: scene.size.height/2)
        
        // Add animation to move towards XP bar
        let moveAction = SKAction.move(to: xpBarNode.position, duration: 1.0)
        let fadeAction = SKAction.fadeOut(withDuration: 0.3)
        let sequence = SKAction.sequence([moveAction, fadeAction, SKAction.removeFromParent()])
        
        xpText.run(sequence)
        scene.addChild(xpText)
    }
} 