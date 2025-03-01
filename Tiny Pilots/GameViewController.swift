//
//  GameViewController.swift
//  Tiny Pilots
//
//  Created by Taric Santos de Andrade on 2025-03-01.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view
        if let view = self.view as! SKView? {
            // Set up debug options based on configuration
            view.showsFPS = GameConfig.Debug.showsFPS
            view.showsNodeCount = GameConfig.Debug.showsNodeCount
            view.showsPhysics = GameConfig.Debug.showsPhysics
            
            // Ignore sibling order for faster rendering
            view.ignoresSiblingOrder = true
            
            // Create and present the main menu scene
            presentMainMenu(in: view)
        }
        
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
    }
    
    deinit {
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Present the main menu scene in the given view
    private func presentMainMenu(in view: SKView) {
        // Create the main menu scene with the view size
        let scene = MainMenuScene(size: view.bounds.size)
        
        // Set scale mode to fill the view
        scene.scaleMode = .aspectFill
        
        // Present the scene
        view.presentScene(scene)
    }
    
    /// Present the flight scene in the given view
    func presentFlightScene(in view: SKView, mode: GameManager.GameMode) {
        // Create the flight scene with the view size and game mode
        let scene = FlightScene(size: view.bounds.size, mode: mode)
        
        // Set scale mode to fill the view
        scene.scaleMode = .aspectFill
        
        // Present the scene with a transition
        let transition = SKTransition.fade(withDuration: 0.5)
        view.presentScene(scene, transition: transition)
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
        if GameManager.shared.currentState == .playing {
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
        }
        
        // Resume the game if it was paused
        if GameManager.shared.currentState == .paused {
            // Don't automatically resume gameplay, just unpause the view
            // The user will need to tap the resume button to continue playing
            
            // However, restart physics simulation for visual effects
            if let scene = view?.scene as? FlightScene {
                PhysicsManager.shared.startPhysicsSimulation()
            }
        }
    }
}
