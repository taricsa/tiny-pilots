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
    func applicationWillResignActive(_ application: UIApplication) {
        // Pause the game if it's running
        if GameManager.shared.currentState == .playing {
            GameManager.shared.pauseGame()
        }
        
        // Stop physics simulation
        PhysicsManager.shared.stopPhysicsSimulation()
    }
    
    /// Called when the app has become active
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Resume the game if it was paused
        if GameManager.shared.currentState == .paused {
            GameManager.shared.resumeGame()
        }
    }
}
