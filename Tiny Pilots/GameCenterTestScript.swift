import Foundation
import GameKit

/// Test script for Game Center integration
/// This is a utility class to help with testing Game Center features
class GameCenterTester {
    
    /// Shared instance
    static let shared = GameCenterTester()
    
    /// Private initializer
    private init() {}
    
    /// Test authentication
    func testAuthentication() {
        print("Testing Game Center Authentication...")
        
        if GKLocalPlayer.local.isAuthenticated {
            print("✅ User is authenticated as: \(GKLocalPlayer.local.displayName)")
        } else {
            print("❌ User is not authenticated")
            
            // Attempt to authenticate
            GameCenterManager.shared.authenticatePlayer { success, error in
                if success {
                    print("✅ Authentication successful")
                } else if let error = error {
                    print("❌ Authentication failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Test leaderboard submission
    func testLeaderboardSubmission() {
        print("Testing Leaderboard Submission...")
        
        // Ensure we're authenticated before proceeding
        guard GKLocalPlayer.local.isAuthenticated else {
            print("❌ Cannot test leaderboard submission - not authenticated with Game Center")
            return
        }
        
        // Test global distance leaderboard
        let testScore = Int.random(in: 100...5000)
        print("Submitting test score: \(testScore) to total distance leaderboard")
        
        GameCenterManager.shared.submitScore(testScore, to: GameCenterConfig.Leaderboards.distanceFreePlay) { error in
            if let error = error {
                print("❌ Failed to submit score: \(error.localizedDescription)")
            } else {
                print("✅ Score submitted successfully")
            }
        }
    }
    
    /// Test achievement reporting
    func testAchievementReporting() {
        print("Testing Achievement Reporting...")
        
        // Ensure we're authenticated before proceeding
        guard GKLocalPlayer.local.isAuthenticated else {
            print("❌ Cannot test achievement reporting - not authenticated with Game Center")
            return
        }
        
        // Test distance achievement
        print("Reporting 100% completion for distance achievement")
        
        GameCenterManager.shared.reportAchievement(
            GameCenterConfig.Achievements.distance10000,
            percentComplete: 100
        ) { error in
            if let error = error {
                print("❌ Failed to report achievement: \(error.localizedDescription)")
            } else {
                print("✅ Achievement reported successfully")
            }
        }
    }
    
    /// Test challenge code generation and processing
    func testChallengeCode() {
        print("Testing Challenge Code Generation and Processing...")
        
        // Generate a test code
        let courseID = "mountain"
        let code = GameCenterManager.shared.generateChallengeCode(for: courseID)
        print("Generated challenge code: \(code) for course: \(courseID)")
        
        // Process the code
        let result = GameCenterManager.shared.processChallengeCode(code)
        
        if let extractedCourseID = result.0 {
            print("✅ Code processed successfully, extracted course ID: \(extractedCourseID)")
            
            if extractedCourseID == courseID {
                print("✅ Extracted course ID matches original")
            } else {
                print("❌ Extracted course ID does not match original")
            }
        } else if let error = result.1 {
            print("❌ Failed to process code: \(error)")
        }
    }
    
    /// Test invalid challenge code
    func testInvalidChallengeCode() {
        print("Testing Invalid Challenge Code Processing...")
        
        let invalidCode = "invalid_code_format"
        let result = GameCenterManager.shared.processChallengeCode(invalidCode)
        
        if result.0 == nil && result.1 != nil {
            print("✅ Invalid code correctly rejected with error: \(result.1!)")
        } else {
            print("❌ Invalid code not properly rejected")
        }
    }
    
    /// Run all tests
    func runAllTests() {
        print("🚀 Starting Game Center Integration Tests")
        print("----------------------------------------")
        
        // First ensure we're authenticated
        if !GKLocalPlayer.local.isAuthenticated {
            print("⚠️ Not authenticated with Game Center. Attempting to authenticate first...")
            GameCenterManager.shared.authenticatePlayer { success, error in
                if success {
                    print("✅ Authentication successful, proceeding with tests")
                    self.runTestsSequentially()
                } else {
                    print("❌ Authentication failed, cannot run tests")
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            runTestsSequentially()
        }
    }
    
    /// Run tests one after another with delays
    private func runTestsSequentially() {
        // Run tests with delays to avoid overwhelming Game Center
        testAuthentication()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.testLeaderboardSubmission()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.testAchievementReporting()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.testChallengeCode()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.testInvalidChallengeCode()
                        
                        print("----------------------------------------")
                        print("🏁 Game Center Integration Tests Complete")
                    }
                }
            }
        }
    }
    
    /// Reset all achievements (for testing)
    func resetAllAchievements() {
        print("Resetting all achievements...")
        
        // Ensure we're authenticated before proceeding
        guard GKLocalPlayer.local.isAuthenticated else {
            print("❌ Cannot reset achievements - not authenticated with Game Center")
            return
        }
        
        GKAchievement.resetAchievements { error in
            if let error = error {
                print("❌ Failed to reset achievements: \(error.localizedDescription)")
            } else {
                print("✅ All achievements reset successfully")
            }
        }
    }
} 