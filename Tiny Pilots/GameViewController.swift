//
//  GameViewController.swift
//  Tiny Pilots
//
//  Created by Taric Santos de Andrade on 2025-03-01.
//

import UIKit
import SpriteKit
import GameplayKit
import SwiftUI
import Combine

class GameViewController: UIViewController {
    // Helpers to convert between GameManager.GameMode and GameState.Mode
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
    override func loadView() {
        // Create an SKView programmatically since we are not using a storyboard
        self.view = SKView(frame: UIScreen.main.bounds)
    }

    // Add a cancellable property to store our subscription
    private var screenChangeSubscription: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view
        if let view = self.view as! SKView? {
            // Set up debug options based on configuration
            view.showsFPS = GameConfig.Debug.showsFPS
            view.showsNodeCount = GameConfig.Debug.showsNodeCount
            view.showsPhysics = GameConfig.Debug.showsPhysics
            
            // Ensure transparency and hit testing work correctly
            view.allowsTransparency = true
            view.ignoresSiblingOrder = true
            
            // Create and present the main menu scene
            presentMainMenu(in: view)
        }
        
        // Set up Game Center
        setupGameCenter()
        
        // Add observer for screen changes
        observeScreenChanges()
        
        // Register for application lifecycle notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Register for challenge notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleChallengeNotification(_:)),
            name: NSNotification.Name("LaunchChallengeNotification"),
            object: nil
        )
    }
    
    deinit {
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Present the main menu scene in the given view
    private func presentMainMenu(in view: SKView) {
        print("Presenting MainMenuScene")
        
        // Ensure the view is ready for a new scene
        view.isPaused = false
        
        // Create the main menu scene with the view size
        let scene = MainMenuScene(size: view.bounds.size)
        
        // Set scale mode to fill the view
        scene.scaleMode = .aspectFill
        
        // Present the scene with a transition
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(scene, transition: transition)
        
        // Add SwiftUI menu overlay after a short delay to ensure the SpriteKit scene is properly set up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Create the SwiftUI overlay
            let menuView = MainMenuView()
                .environmentObject(GameStateManager.shared)
            
            // Create and configure the hosting controller
            let hostingController = UIHostingController(rootView: menuView)
            hostingController.view.backgroundColor = .clear
            
            // Add the SwiftUI view as an overlay directly to the main view controller
            self.addChild(hostingController)
            self.view.addSubview(hostingController.view)
            hostingController.view.frame = self.view.bounds
            hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            hostingController.didMove(toParent: self)
            
            // For debug purposes
            print("Added MainMenuView overlay")
        }
    }
    
    /// Present the flight scene in the given view
    func presentFlightScene(in view: SKView, mode: GameManager.GameMode) {
        print("Presenting flight scene with mode: \(mode)")
        
        // Ensure the view is ready for a new scene
        view.isPaused = false
        
        // Create the flight scene with the view size and game mode
        let scene = FlightScene(size: view.bounds.size, mode: mode)
        
        // Set scale mode to fill the view
        scene.scaleMode = .aspectFill
        
        // Present the scene with a transition
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(scene, transition: transition)
        
        // Delay starting the game until the scene is fully loaded and transition complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            print("Flight scene loaded, now starting game")
            
            // Make sure the scene is still active before starting the game
            if view.scene is FlightScene {
                // Start the game
                // Convert GameManager.GameMode to GameState.Mode
                let gameStateMode = convertToGameStateMode(mode)
                GameManager.shared.setGameMode(gameStateMode)
                GameManager.shared.startGame()
            } else {
                print("Flight scene is no longer active, not starting game")
            }
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .landscape
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // Handle application lifecycle events
    
    /// Called when the app is about to move from active to inactive state
    @objc func applicationWillResignActive(_ notification: Notification) {
        // Pause the game if it's running
        if GameManager.shared.currentState.status == .playing {
            GameManager.shared.pauseGame()
        }
        
        // Stop physics simulation
        PhysicsManager.shared.stopPhysicsSimulation()
        
        // Pause the view
        if let view = self.view as? SKView {
            view.isPaused = true
        }
    }
    
    /// Called when the app has become active
    @objc func applicationDidBecomeActive(_ notification: Notification) {
        // Resume the view
        if let view = self.view as? SKView {
            view.isPaused = false
            
            // Resume the game if it was paused
            if GameManager.shared.currentState.status == .paused {
                // Don't automatically resume gameplay, just unpause the view
                // The user will need to tap the resume button to continue playing
                
                // However, restart physics simulation for visual effects
                if view.scene is FlightScene {
                    PhysicsManager.shared.startPhysicsSimulation()
                }
            }
        }
    }
    
    // MARK: - Challenge Handling
    
    @objc func handleChallengeNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let challengeCode = userInfo["challengeCode"] as? String,
              let view = self.view as? SKView else {
            return
        }
        
        // Launch the flight scene with the challenge code
        presentChallengeScene(in: view, challengeCode: challengeCode)
    }
    
    /// Present a challenge scene with the given challenge code
    func presentChallengeScene(in view: SKView, challengeCode: String) {
        print("Presenting challenge scene with code: \(challengeCode)")
        
        // Create the flight scene with the challenge code
        let scene = FlightScene(size: view.bounds.size, challengeCode: challengeCode)
        
        // Configure the scene
        scene.scaleMode = .aspectFill
        
        // Present the scene
        view.presentScene(scene, transition: SKTransition.fade(withDuration: 1.0))
        
        // Delay starting the game until the scene is fully loaded and transition complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            print("Challenge scene loaded, now starting game")
            
            // Start the game without checking scene type since it might have changed
            GameManager.shared.setGameMode(.challenge)
            GameManager.shared.startGame()
        }
    }
    
    /// Set up Game Center integration
    private func setupGameCenter() {
        // Set the presenting view controller
        GameCenterManager.shared.presentingViewController = self
        
        // Authenticate with Game Center after a short delay to ensure the view is fully loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            GameCenterManager.shared.authenticatePlayer { success, error in
                if let error = error {
                    print("Game Center authentication failed: \(error.localizedDescription)")
                } else if success {
                    print("Game Center authentication successful")
                }
            }
        }
    }

    // Add method to observe screen changes
    private func observeScreenChanges() {
        // Observe screen changes via Notification as fallback (since $currentScreen may not be exposed)
        screenChangeSubscription = NotificationCenter.default.publisher(for: Notification.Name("NavigateToMainMenu"))
            .sink { [weak self] _ in
                guard let self = self, let view = self.view as? SKView else { return }
                self.cleanupCurrentScene()
                self.presentMainMenu(in: view)
            }
        
        // If Combine publisher is available in GameStateManager, also attach here
        // screenChangeSubscription = GameStateManager.shared.$currentScreen
            .sink { [weak self] screen in
                guard let self = self, let view = self.view as? SKView else { return }
                
                print("Screen changed to: \(screen)")
                
                // First, clean up the current state
                self.cleanupCurrentScene()
                
                // Handle different screen types
                switch screen {
                case .mainMenu:
                    self.presentMainMenu(in: view)
                case .gameModeSelection:
                    self.presentGameModeSelection(in: view)
                case .flight:
                    let gmMode = convertFromGameStateMode(GameStateManager.shared.currentGameMode)
                    self.presentFlightScene(in: view, mode: gmMode)
                case .hangar:
                    self.presentHangarScene(in: view)
                case .challenge(let code):
                    self.presentChallengeScene(in: view, challengeCode: code)
                case .dailyRun:
                    self.presentFlightScene(in: view, mode: .dailyRun)
                case .weeklySpecial:
                    self.presentFlightScene(in: view, mode: .weeklySpecial)
                default:
                    break
                }
            }
    }
    
    /// Clean up the current scene before transitioning to a new one
    private func cleanupCurrentScene() {
        // Stop any ongoing game
        if GameManager.shared.currentState == .playing || GameManager.shared.currentState == .paused {
            print("Stopping current game before scene transition")
            GameManager.shared.stopGame()
        }
        
        // Stop physics simulation
        PhysicsManager.shared.stopPhysicsSimulation()
        
        // Clear view's children to ensure clean transition
        if let view = self.view as? SKView {
            // Pause the view during transition
            view.isPaused = true
            
            // Log what scene we're cleaning up
            if let currentScene = view.scene {
                print("Cleaning up scene of type: \(type(of: currentScene))")
            }
        }
        
        // Remove all SwiftUI overlays
        removeSwiftUIOverlays()
    }
    
    // Add method to present game mode selection screen
    private func presentGameModeSelection(in view: SKView) {
        print("Presenting GameModeSelectionScene")
        
        // Ensure the view is ready for a new scene
        view.isPaused = false
        view.allowsTransparency = true
        
        // Create a completely fresh scene
        let scene = GameModeSelectionScene(size: view.bounds.size)
        scene.scaleMode = .aspectFill
        scene.backgroundColor = .systemBlue
        
        // Present the scene with a transition
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(scene, transition: transition)
        print("GameModeSelectionScene presented with transition")
        
        // Wait a moment before adding the SwiftUI overlay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Create GameModeSelectionView with environment object
            let modeSelectionView = GameModeSelectionEnvironmentView()
                .environmentObject(GameStateManager.shared)
            
            // Create hosting controller with transparent background
            let hostingController = UIHostingController(rootView: modeSelectionView)
            hostingController.view.backgroundColor = .clear
            hostingController.view.isOpaque = false
            
            // Add the SwiftUI overlay directly to the view controller
            self.addChild(hostingController)
            self.view.addSubview(hostingController.view)
            hostingController.view.frame = self.view.bounds
            hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            hostingController.didMove(toParent: self)
            
            // Debug log
            print("GameModeSelectionView overlay added to main view")
        }
    }
    
    @objc func testButtonTapped() {
        print("TEST BUTTON TAPPED - Touch events are working")
    }
    
    // Add method to present hangar scene
    private func presentHangarScene(in view: SKView) {
        let scene = HangarScene(size: view.bounds.size)
        scene.scaleMode = .aspectFill
        view.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
        
        // Add SwiftUI overlay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Remove any existing SwiftUI overlays
            self.removeSwiftUIOverlays()
            
            // Create HangarView
            let hangarView = HangarView()
                .environmentObject(GameStateManager.shared)
            
            let hostingController = UIHostingController(rootView: hangarView)
            hostingController.view.backgroundColor = .clear
            
            self.addChild(hostingController)
            view.addSubview(hostingController.view)
            hostingController.view.frame = view.bounds
            hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            hostingController.didMove(toParent: self)
        }
    }
    
    // Helper method to remove SwiftUI overlays
    private func removeSwiftUIOverlays() {
        print("Removing SwiftUI overlays. Current child count: \(children.count)")
        
        for child in children {
            // Check if the child is a UIHostingController by comparing its type name
            if String(describing: type(of: child)).contains("UIHostingController") {
                print("Found UIHostingController: \(child)")
                child.willMove(toParent: nil)
                child.view.removeFromSuperview()
                child.removeFromParent()
            }
        }
        
        // Verify all hosting controllers are removed
        print("After removal, child count: \(children.count)")
    }
}
