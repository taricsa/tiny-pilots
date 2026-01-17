//
//  GameCenterManager.swift
//  Tiny Pilots
//
//  Compatibility façade over GameCenterService to satisfy legacy references.
//

import Foundation
import GameKit
import UIKit

final class GameCenterManager {
    static let shared = GameCenterManager()

    // The presenting VC for Game Center UI
    weak var presentingViewController: UIViewController?

    private let service: GameCenterServiceProtocol

    private init() {
        if let resolved: GameCenterServiceProtocol = DIContainer.shared.tryResolve(GameCenterServiceProtocol.self) {
            service = resolved
        } else {
            service = GameCenterService()
        }
    }

    var isGameCenterAvailable: Bool {
        return GKLocalPlayer.local.isAuthenticated || !GKLocalPlayer.local.isUnderage
    }

    func authenticatePlayer(completion: @escaping (Bool, Error?) -> Void) {
        service.authenticate { success, error in
            completion(success, error)
        }
    }

    func submitScore(_ score: Int, to leaderboardId: String, completion: @escaping (Error?) -> Void) {
        service.submitScore(score, to: leaderboardId, completion: completion)
    }

    func reportAchievement(_ identifier: String, percentComplete: Double, showsCompletionBanner: Bool = true, completion: @escaping (Error?) -> Void) {
        service.reportAchievement(identifier: identifier, percentComplete: percentComplete, completion: completion)
    }

    func trackAchievementProgress() {
        service.loadAchievements { _ , _ in }
    }

    // Legacy challenge code helpers
    func generateChallengeCode(for courseID: String) -> String {
        let code = UUID().uuidString.replacingOccurrences(of: "-", with: "").uppercased()
        let start = code.startIndex
        let mid = code.index(start, offsetBy: GameCenterConfig.ChallengeCode.hyphenPosition)
        let end = code.index(start, offsetBy: GameCenterConfig.ChallengeCode.codeLength)
        return String(code[start..<mid]) + "-" + String(code[mid..<end])
    }

    func processChallengeCode(_ code: String) -> (courseID: String?, error: String?) {
        let sanitized = code.replacingOccurrences(of: " ", with: "").uppercased()
        let parts = sanitized.split(separator: "-")
        guard parts.count == 2 else { return (nil, "invalid_format") }
        // For now, map by prefix deterministically to a course
        let prefix = parts[0]
        let coursePool = GameCenterConfig.Courses.allCourses
        if let hash = prefix.unicodeScalars.map({ UInt32($0.value) }).reduce(0, +) as UInt32?, !coursePool.isEmpty {
            let idx = Int(hash) % coursePool.count
            return (coursePool[idx], nil)
        }
        return (nil, "unknown_code")
    }
}


