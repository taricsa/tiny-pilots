//
//  ViewAction.swift
//  Tiny Pilots
//
//  Created by Kiro on 7/15/25.
//

import Foundation

/// Protocol for defining user actions that can be handled by ViewModels
protocol ViewAction {
    /// Unique identifier for the action type
    var actionType: String { get }
}

// MARK: - Common View Actions

/// Action for starting a game
struct StartGameAction: ViewAction {
    let actionType = "startGame"
    let gameMode: String
    
    init(gameMode: String) {
        self.gameMode = gameMode
    }
}

/// Action for pausing a game
struct PauseGameAction: ViewAction {
    let actionType = "pauseGame"
}

/// Action for resuming a game
struct ResumeGameAction: ViewAction {
    let actionType = "resumeGame"
}

/// Action for ending a game
struct EndGameAction: ViewAction {
    let actionType = "endGame"
}

/// Action for navigating to a different screen
struct NavigateAction: ViewAction {
    let actionType = "navigate"
    let destination: String
    
    init(to destination: String) {
        self.destination = destination
    }
}

/// Action for updating settings
struct UpdateSettingAction: ViewAction {
    let actionType = "updateSetting"
    let key: String
    let value: Any
    
    init(key: String, value: Any) {
        self.key = key
        self.value = value
    }
}

/// Action for handling tilt input
struct TiltInputAction: ViewAction {
    let actionType = "tiltInput"
    let x: Double
    let y: Double
    
    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}