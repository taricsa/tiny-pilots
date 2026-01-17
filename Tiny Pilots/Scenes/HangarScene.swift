import SpriteKit
import UIKit
import SwiftData

/// Hangar scene for airplane customization and selection
class HangarScene: SKScene {
    
    // MARK: - Properties
    
    /// ViewModel for managing hangar state and airplane customization
    private var viewModel: HangarViewModel!
    
    // MARK: - Visual Properties
    
    // Floor height constant accessible to all methods
    private let floorHeight: CGFloat = 100
    
    // UI elements
    private var titleLabel: SKLabelNode?
    private var backButton: SKSpriteNode?
    private var saveButton: SKSpriteNode?
    private var resetButton: SKSpriteNode?
    
    // Airplane preview
    private var previewAirplane: PaperAirplane?
    private var previewPlatform: SKSpriteNode?
    
    // Customization panels
    private var airplaneTypePanel: SKNode?
    private var foldTypePanel: SKNode?
    private var designTypePanel: SKNode?
    
    // Info display
    private var airplaneNameLabel: SKLabelNode?
    private var airplaneDescriptionLabel: SKLabelNode?
    private var statsDisplay: SKNode?
    
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
        
        // Set a dark blue/gray hangar-like background
        configureBackground()
        createUI()
        
        // Start observing ViewModel state changes
        startObservingViewModel()
    }
    
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        
        // Clean up ViewModel
        viewModel?.cleanup()
    }
    
    private func configureBackground() {
        // Create gradient background
        let backgroundNode = SKSpriteNode(color: UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0), size: size)
        backgroundNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundNode.zPosition = -20
        addChild(backgroundNode)
        
        // Add hangar floor
        let floor = SKSpriteNode(color: UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0), 
                                size: CGSize(width: size.width, height: floorHeight))
        floor.position = CGPoint(x: size.width / 2, y: floorHeight / 2)
        floor.zPosition = -10
        addChild(floor)
        
        // Add some light beams from ceiling
        for i in 0..<4 {
            let beamWidth: CGFloat = 80
            let beamHeight: CGFloat = size.height * 0.7
            
            let beam = SKSpriteNode(color: .white, size: CGSize(width: beamWidth, height: beamHeight))
            beam.position = CGPoint(
                x: size.width * CGFloat(i + 1) / 5,
                y: size.height - beamHeight / 2
            )
            beam.alpha = 0.1
            beam.zPosition = -15
            
            // Pulse animation
            let fadeAction = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.05, duration: 2.0),
                SKAction.fadeAlpha(to: 0.15, duration: 2.0)
            ])
            beam.run(SKAction.repeatForever(fadeAction))
            
            addChild(beam)
        }
        
        // Add wall details
        let wallLinesCount = 5
        for i in 0..<wallLinesCount {
            let y = floorHeight + (size.height - floorHeight) * CGFloat(i) / CGFloat(wallLinesCount)
            let lineNode = SKSpriteNode(color: UIColor(white: 0.3, alpha: 1.0), 
                                      size: CGSize(width: size.width, height: 1))
            lineNode.position = CGPoint(x: size.width / 2, y: y)
            lineNode.zPosition = -12
            lineNode.alpha = 0.3
            addChild(lineNode)
        }
        
        // Add some floating dust particles
        if let dustParticles = SKEmitterNode(fileNamed: "DustParticles") {
            dustParticles.position = CGPoint(x: size.width / 2, y: size.height / 2)
            dustParticles.zPosition = -5
            dustParticles.advanceSimulationTime(10) // Pre-populate particles
            addChild(dustParticles)
        } else {
            // Create simple dust particles as fallback
            createSimpleDustParticles()
        }
    }
    
    private func createSimpleDustParticles() {
        // Add a few dust motes floating in the light beams
        for _ in 0..<15 {
            let dustSize = CGFloat.random(in: 2...5)
            let dust = SKShapeNode(circleOfRadius: dustSize)
            dust.fillColor = .white
            dust.strokeColor = .clear
            dust.alpha = CGFloat.random(in: 0.1...0.3)
            dust.position = CGPoint(
                x: CGFloat.random(in: 0...self.size.width),
                y: CGFloat.random(in: floorHeight...self.size.height)
            )
            dust.zPosition = -5
            
            // Add floating motion
            let moveAction = SKAction.customAction(withDuration: TimeInterval.random(in: 10...20)) { node, time in
                // Slow random drift
                let t = time / 20.0
                node.position.y += sin(t * .pi) * 0.5
                node.position.x += cos(t * .pi * 2) * 0.3
            }
            dust.run(SKAction.repeatForever(moveAction))
            
            addChild(dust)
        }
    }
    
    // MARK: - Setup Methods
    
    /// Set the ViewModel for this scene
    /// - Parameter viewModel: The HangarViewModel to use
    func setViewModel(_ viewModel: HangarViewModel) {
        self.viewModel = viewModel
    }
    
    /// Setup the ViewModel using dependency injection
    private func setupViewModel() {
        do {
            let audioService = try DIContainer.shared.resolve(AudioServiceProtocol.self)
            let modelContext = try DIContainer.shared.resolve(ModelContext.self)
            
            viewModel = HangarViewModel(
                audioService: audioService,
                modelContext: modelContext
            )
        } catch {
            fatalError("Failed to setup HangarViewModel: \(error)")
        }
    }
    
    /// Create UI elements
    private func createUI() {
        createTitle()
        createButtons()
        createAirplanePreview()
        createCustomizationPanels()
        createInfoDisplay()
    }
    
    /// Create the title label
    private func createTitle() {
        titleLabel = SKLabelNode(fontNamed: "Arial-Bold")
        titleLabel?.text = "Airplane Hangar"
        titleLabel?.fontSize = 36
        titleLabel?.fontColor = .white
        titleLabel?.position = CGPoint(x: size.width / 2, y: size.height - 60)
        titleLabel?.zPosition = 10
        
        if let titleLabel = titleLabel {
            addChild(titleLabel)
        }
    }
    
    /// Create control buttons
    private func createButtons() {
        let buttonWidth: CGFloat = 100
        let buttonHeight: CGFloat = 40
        
        // Back button
        backButton = createButton(
            text: "Back",
            size: CGSize(width: buttonWidth, height: buttonHeight),
            position: CGPoint(x: 70, y: size.height - 60),
            name: "backButton",
            color: .systemGray
        )
        
        // Save button
        saveButton = createButton(
            text: "Save",
            size: CGSize(width: buttonWidth, height: buttonHeight),
            position: CGPoint(x: size.width - 70, y: size.height - 60),
            name: "saveButton",
            color: .systemGreen
        )
        
        // Reset button
        resetButton = createButton(
            text: "Reset",
            size: CGSize(width: buttonWidth, height: buttonHeight),
            position: CGPoint(x: size.width - 70, y: size.height - 110),
            name: "resetButton",
            color: .systemOrange
        )
    }
    
    /// Create a button with specified properties
    private func createButton(text: String, size: CGSize, position: CGPoint, name: String, color: UIColor) -> SKSpriteNode {
        let button = SKSpriteNode(color: color, size: size)
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
        label.fontSize = 16
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        button.addChild(label)
        
        addChild(button)
        return button
    }
    
    /// Create airplane preview area
    private func createAirplanePreview() {
        // Create preview platform
        previewPlatform = SKSpriteNode(color: .darkGray, size: CGSize(width: 200, height: 20))
        previewPlatform?.position = CGPoint(x: size.width / 2, y: size.height * 0.6)
        previewPlatform?.zPosition = 5
        
        if let previewPlatform = previewPlatform {
            addChild(previewPlatform)
        }
        
        // Create initial preview airplane
        updateAirplanePreview()
    }
    
    /// Create customization panels
    private func createCustomizationPanels() {
        let panelWidth: CGFloat = 150
        let panelHeight: CGFloat = 200
        let panelY = size.height * 0.3
        
        // Airplane type panel
        airplaneTypePanel = createCustomizationPanel(
            title: "Type",
            size: CGSize(width: panelWidth, height: panelHeight),
            position: CGPoint(x: size.width * 0.2, y: panelY),
            panelType: .airplaneType
        )
        
        // Fold type panel
        foldTypePanel = createCustomizationPanel(
            title: "Fold",
            size: CGSize(width: panelWidth, height: panelHeight),
            position: CGPoint(x: size.width * 0.5, y: panelY),
            panelType: .foldType
        )
        
        // Design type panel
        designTypePanel = createCustomizationPanel(
            title: "Design",
            size: CGSize(width: panelWidth, height: panelHeight),
            position: CGPoint(x: size.width * 0.8, y: panelY),
            panelType: .designType
        )
    }
    
    /// Create a customization panel
    private func createCustomizationPanel(title: String, size: CGSize, position: CGPoint, panelType: CustomizationPanelType) -> SKNode {
        let panel = SKNode()
        panel.position = position
        panel.zPosition = 10
        
        // Panel background
        let background = SKShapeNode(rectOf: size, cornerRadius: 10)
        background.fillColor = UIColor(white: 0.2, alpha: 0.8)
        background.strokeColor = .white
        background.lineWidth = 2
        panel.addChild(background)
        
        // Panel title
        let titleLabel = SKLabelNode(fontNamed: "Arial-Bold")
        titleLabel.text = title
        titleLabel.fontSize = 18
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: size.height / 2 - 30)
        panel.addChild(titleLabel)
        
        // Add options based on panel type
        addPanelOptions(to: panel, type: panelType, size: size)
        
        addChild(panel)
        return panel
    }
    
    /// Add options to a customization panel
    private func addPanelOptions(to panel: SKNode, type: CustomizationPanelType, size: CGSize) {
        let optionHeight: CGFloat = 30
        let optionSpacing: CGFloat = 35
        let startY = size.height / 2 - 70
        
        switch type {
        case .airplaneType:
            for (index, airplaneType) in PaperAirplane.AirplaneType.allCases.enumerated() {
                let option = createOptionButton(
                    text: airplaneType.rawValue.capitalized,
                    position: CGPoint(x: 0, y: startY - CGFloat(index) * optionSpacing),
                    name: "airplaneType_\(airplaneType.rawValue)"
                )
                panel.addChild(option)
            }
            
        case .foldType:
            for (index, foldType) in PaperAirplane.FoldType.allCases.enumerated() {
                let option = createOptionButton(
                    text: foldType.rawValue,
                    position: CGPoint(x: 0, y: startY - CGFloat(index) * optionSpacing),
                    name: "foldType_\(foldType.rawValue)"
                )
                panel.addChild(option)
            }
            
        case .designType:
            for (index, designType) in PaperAirplane.DesignType.allCases.enumerated() {
                let option = createOptionButton(
                    text: designType.rawValue,
                    position: CGPoint(x: 0, y: startY - CGFloat(index) * optionSpacing),
                    name: "designType_\(designType.rawValue)"
                )
                panel.addChild(option)
            }
        }
    }
    
    /// Create an option button
    private func createOptionButton(text: String, position: CGPoint, name: String) -> SKNode {
        let button = SKNode()
        button.position = position
        button.name = name
        
        // Button background
        let background = SKShapeNode(rectOf: CGSize(width: 120, height: 25), cornerRadius: 5)
        background.fillColor = .systemBlue
        background.strokeColor = .white
        background.lineWidth = 1
        button.addChild(background)
        
        // Button label
        let label = SKLabelNode(fontNamed: "Arial")
        label.text = text
        label.fontSize = 14
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        button.addChild(label)
        
        return button
    }
    
    /// Create info display area
    private func createInfoDisplay() {
        let infoY = floorHeight + 50
        
        // Airplane name
        airplaneNameLabel = SKLabelNode(fontNamed: "Arial-Bold")
        airplaneNameLabel?.fontSize = 24
        airplaneNameLabel?.fontColor = .white
        airplaneNameLabel?.position = CGPoint(x: size.width / 2, y: infoY + 60)
        airplaneNameLabel?.zPosition = 10
        
        if let airplaneNameLabel = airplaneNameLabel {
            addChild(airplaneNameLabel)
        }
        
        // Airplane description
        airplaneDescriptionLabel = SKLabelNode(fontNamed: "Arial")
        airplaneDescriptionLabel?.fontSize = 16
        airplaneDescriptionLabel?.fontColor = .lightGray
        airplaneDescriptionLabel?.position = CGPoint(x: size.width / 2, y: infoY + 30)
        airplaneDescriptionLabel?.zPosition = 10
        
        if let airplaneDescriptionLabel = airplaneDescriptionLabel {
            addChild(airplaneDescriptionLabel)
        }
        
        // Stats display
        createStatsDisplay(at: CGPoint(x: size.width / 2, y: infoY))
    }
    
    /// Create stats display
    private func createStatsDisplay(at position: CGPoint) {
        statsDisplay = SKNode()
        statsDisplay?.position = position
        statsDisplay?.zPosition = 10
        
        if let statsDisplay = statsDisplay {
            addChild(statsDisplay)
        }
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
        
        // Update airplane preview
        updateAirplanePreview()
        
        // Update airplane info
        let details = viewModel.currentAirplaneDetails
        airplaneNameLabel?.text = details.name
        airplaneDescriptionLabel?.text = details.description
        
        // Update stats display
        updateStatsDisplay(stats: details.stats)
        
        // Update button states
        saveButton?.alpha = viewModel.canSelectCurrentConfiguration ? 1.0 : 0.5
        resetButton?.alpha = viewModel.hasUnsavedChanges ? 1.0 : 0.5
        
        // Update option button states
        updateOptionButtonStates()
        
        // Handle animations
        if viewModel.animateTitle {
            animateTitle()
        }
        
        if viewModel.animateContent {
            animateContent()
        }
    }
    
    /// Update airplane preview
    private func updateAirplanePreview() {
        guard let viewModel = viewModel else { return }
        
        // Remove existing preview
        previewAirplane?.removeFromParent()
        
        // Create new preview airplane
        let config = viewModel.previewAirplane
        previewAirplane = PaperAirplane(
            type: config.type,
            fold: config.fold,
            design: config.design
        )
        
        if let previewAirplane = previewAirplane,
           let previewPlatform = previewPlatform {
            previewAirplane.position = CGPoint(x: previewPlatform.position.x, y: previewPlatform.position.y + 50)
            previewAirplane.zPosition = 15
            addChild(previewAirplane)
            
            // Add rotation animation
            let rotateAction = SKAction.rotate(byAngle: .pi * 2, duration: 8.0)
            previewAirplane.run(SKAction.repeatForever(rotateAction))
        }
    }
    
    /// Update stats display
    private func updateStatsDisplay(stats: AirplaneStats) {
        guard let statsDisplay = statsDisplay else { return }
        
        // Clear existing stats
        statsDisplay.removeAllChildren()
        
        let statNames = ["Speed", "Stability", "Lift", "Maneuverability"]
        let statValues = [stats.speed, stats.stability, stats.lift, stats.maneuverability]
        
        for (index, (name, value)) in zip(statNames, statValues).enumerated() {
            let statY = CGFloat(index) * -25
            
            // Stat name
            let nameLabel = SKLabelNode(fontNamed: "Arial")
            nameLabel.text = name
            nameLabel.fontSize = 14
            nameLabel.fontColor = .white
            nameLabel.position = CGPoint(x: -80, y: statY)
            nameLabel.horizontalAlignmentMode = .left
            statsDisplay.addChild(nameLabel)
            
            // Stat bar background
            let barBackground = SKShapeNode(rectOf: CGSize(width: 100, height: 8), cornerRadius: 4)
            barBackground.fillColor = .darkGray
            barBackground.strokeColor = .clear
            barBackground.position = CGPoint(x: 30, y: statY)
            statsDisplay.addChild(barBackground)
            
            // Stat bar fill
            let fillWidth = CGFloat(value) * 100
            let barFill = SKShapeNode(rectOf: CGSize(width: fillWidth, height: 8), cornerRadius: 4)
            barFill.fillColor = getStatColor(for: value)
            barFill.strokeColor = .clear
            barFill.position = CGPoint(x: 30 - (100 - fillWidth) / 2, y: statY)
            statsDisplay.addChild(barFill)
        }
    }
    
    /// Get color for stat value
    private func getStatColor(for value: Double) -> UIColor {
        if value >= 0.8 {
            return .systemGreen
        } else if value >= 0.6 {
            return .systemYellow
        } else if value >= 0.4 {
            return .systemOrange
        } else {
            return .systemRed
        }
    }
    
    /// Update option button states
    private func updateOptionButtonStates() {
        guard let viewModel = viewModel else { return }
        
        // Update airplane type buttons
        for airplaneType in PaperAirplane.AirplaneType.allCases {
            if let button = childNode(withName: "//airplaneType_\(airplaneType.rawValue)") {
                let isSelected = viewModel.selectedAirplaneType == airplaneType
                let isUnlocked = viewModel.isAirplaneTypeUnlocked(airplaneType)
                
                updateButtonAppearance(button, isSelected: isSelected, isUnlocked: isUnlocked)
            }
        }
        
        // Update fold type buttons
        for foldType in PaperAirplane.FoldType.allCases {
            if let button = childNode(withName: "//foldType_\(foldType.rawValue)") {
                let isSelected = viewModel.selectedFoldType == foldType
                let isUnlocked = viewModel.isFoldTypeUnlocked(foldType)
                
                updateButtonAppearance(button, isSelected: isSelected, isUnlocked: isUnlocked)
            }
        }
        
        // Update design type buttons
        for designType in PaperAirplane.DesignType.allCases {
            if let button = childNode(withName: "//designType_\(designType.rawValue)") {
                let isSelected = viewModel.selectedDesignType == designType
                let isUnlocked = viewModel.isDesignTypeUnlocked(designType)
                
                updateButtonAppearance(button, isSelected: isSelected, isUnlocked: isUnlocked)
            }
        }
    }
    
    /// Update button appearance based on state
    private func updateButtonAppearance(_ button: SKNode, isSelected: Bool, isUnlocked: Bool) {
        guard let background = button.children.first as? SKShapeNode else { return }
        
        if isSelected {
            background.fillColor = .systemGreen
            background.strokeColor = .white
            background.lineWidth = 3
        } else if isUnlocked {
            background.fillColor = .systemBlue
            background.strokeColor = .white
            background.lineWidth = 1
        } else {
            background.fillColor = .systemGray
            background.strokeColor = .darkGray
            background.lineWidth = 1
        }
        
        button.alpha = isUnlocked ? 1.0 : 0.5
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
    
    /// Animate content entrance
    private func animateContent() {
        let panels = [airplaneTypePanel, foldTypePanel, designTypePanel]
        
        for (index, panel) in panels.enumerated() {
            guard let panel = panel else { continue }
            
            panel.alpha = 0
            panel.position.y -= 100
            
            let delay = Double(index) * 0.2
            let moveUp = SKAction.moveBy(x: 0, y: 100, duration: 0.4)
            let fadeIn = SKAction.fadeIn(withDuration: 0.4)
            let group = SKAction.group([moveUp, fadeIn])
            let sequence = SKAction.sequence([SKAction.wait(forDuration: delay), group])
            
            panel.run(sequence)
        }
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        handleTouch(touchedNode)
    }
    
    /// Handle touch on nodes
    private func handleTouch(_ node: SKNode) {
        guard let nodeName = node.name ?? node.parent?.name else { return }
        
        // Handle button taps
        if nodeName.hasPrefix("airplaneType_") {
            let typeName = String(nodeName.dropFirst("airplaneType_".count))
            if let airplaneType = PaperAirplane.AirplaneType(rawValue: typeName) {
                viewModel.selectAirplaneType(airplaneType)
            }
        } else if nodeName.hasPrefix("foldType_") {
            let foldName = String(nodeName.dropFirst("foldType_".count))
            if let foldType = PaperAirplane.FoldType(rawValue: foldName) {
                viewModel.selectFoldType(foldType)
            }
        } else if nodeName.hasPrefix("designType_") {
            let designName = String(nodeName.dropFirst("designType_".count))
            if let designType = PaperAirplane.DesignType(rawValue: designName) {
                viewModel.selectDesignType(designType)
            }
        } else {
            // Handle control buttons
            switch nodeName {
            case "backButton":
                viewModel.navigateBack()
            case "saveButton":
                if viewModel.canSelectCurrentConfiguration {
                    viewModel.saveConfiguration()
                }
            case "resetButton":
                if viewModel.hasUnsavedChanges {
                    viewModel.resetToSavedConfiguration()
                }
            default:
                break
            }
        }
        
        // Add button press animation
        if let button = node as? SKSpriteNode ?? node.parent as? SKSpriteNode {
            animateButtonPress(button)
        }
    }
    
    /// Animate button press
    private func animateButtonPress(_ button: SKNode) {
        let scaleDown = SKAction.scale(to: 0.95, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        let sequence = SKAction.sequence([scaleDown, scaleUp])
        button.run(sequence)
    }
}

// MARK: - Supporting Types

/// Types of customization panels
private enum CustomizationPanelType {
    case airplaneType
    case foldType
    case designType
} 