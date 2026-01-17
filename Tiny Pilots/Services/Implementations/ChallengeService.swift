import Foundation
import CoreGraphics

/// Implementation of ChallengeServiceProtocol
class ChallengeService: ChallengeServiceProtocol {
    
    // MARK: - Properties
    
    private let gameCenterService: GameCenterServiceProtocol
    private let userDefaults = UserDefaults.standard
    private let savedChallengesKey = "SavedChallenges"
    
    // MARK: - Initialization
    
    init(gameCenterService: GameCenterServiceProtocol) {
        self.gameCenterService = gameCenterService
    }
    
    // MARK: - Challenge Loading
    
    func loadChallenge(code: String) async throws -> Challenge {
        print("Loading challenge with code: \(code)")
        
        // First validate the code format and expiration
        guard try await validateChallengeCode(code) else {
            throw ChallengeError.invalidCode
        }
        
        // Extract course data from the code using Game Center service
        let result = await withCheckedContinuation { continuation in
            gameCenterService.validateChallengeCode(code) { result in
                continuation.resume(returning: result)
            }
        }
        
        switch result {
        case .success(let courseDataString):
            // Decode the course data
            guard let courseData = ChallengeData.decode(from: courseDataString) else {
                print("Failed to decode challenge course data")
                throw ChallengeError.decodingError
            }
            
            // Create challenge from decoded data
            let challenge = Challenge(
                title: "Friend Challenge",
                description: "A challenge shared by a friend",
                courseData: courseData,
                createdBy: "Friend"
            )
            
            print("Successfully loaded challenge: \(challenge.title)")
            
            return challenge
            
        case .failure(let error):
            print("Challenge code validation failed: \(error)")
            
            // Map Game Center errors to Challenge errors
            if let gcError = error as? GameCenterServiceError {
                switch gcError {
                case .invalidChallengeCode:
                    throw ChallengeError.invalidCode
                case .challengeExpired:
                    throw ChallengeError.expired
                case .networkError:
                    throw ChallengeError.networkError
                default:
                    throw ChallengeError.validationError(gcError.localizedDescription)
                }
            } else {
                throw ChallengeError.validationError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Challenge Code Generation
    
    func generateChallengeCode(for challenge: Challenge) -> String {
        print("Generating challenge code for: \(challenge.title)")
        
        let encodedCourseData = challenge.courseData.encoded
        let challengeCode = gameCenterService.generateChallengeCode(for: encodedCourseData)
        
        print("Generated challenge code successfully")
        
        return challengeCode
    }
    
    // MARK: - Challenge Validation
    
    func validateChallengeCode(_ code: String) async throws -> Bool {
        print("Validating challenge code format")
        
        // Basic format validation
        guard !code.isEmpty, code.contains("_") else {
            throw ChallengeError.invalidCode
        }
        
        // Use Game Center service for detailed validation
        let result = await withCheckedContinuation { continuation in
            gameCenterService.validateChallengeCode(code) { result in
                continuation.resume(returning: result)
            }
        }
        
        switch result {
        case .success:
            print("Challenge code validation successful")
            return true
        case .failure(let error):
            print("Challenge code validation failed: \(error.localizedDescription)")
            
            // Map specific errors
            if let gcError = error as? GameCenterServiceError {
                switch gcError {
                case .invalidChallengeCode:
                    throw ChallengeError.invalidCode
                case .challengeExpired:
                    throw ChallengeError.expired
                case .networkError:
                    throw ChallengeError.networkError
                default:
                    throw ChallengeError.validationError(gcError.localizedDescription)
                }
            } else {
                throw ChallengeError.validationError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Challenge Creation
    
    func createChallenge(
        title: String,
        description: String,
        courseData: ChallengeData,
        createdBy: String,
        targetScore: Int? = nil
    ) -> Challenge {
        print("Creating new challenge: \(title)")
        
        let challenge = Challenge(
            title: title,
            description: description,
            courseData: courseData,
            createdBy: createdBy,
            targetScore: targetScore
        )
        
        print("Challenge created successfully with ID: \(challenge.id)")
        
        return challenge
    }
    
    // MARK: - Local Storage
    
    func saveChallenge(_ challenge: Challenge) throws {
        print("Saving challenge locally: \(challenge.title)")
        
        var savedChallenges = loadSavedChallenges()
        
        // Remove existing challenge with same ID if it exists
        savedChallenges.removeAll { $0.id == challenge.id }
        
        // Add the new/updated challenge
        savedChallenges.append(challenge)
        
        // Limit to 50 saved challenges to prevent storage bloat
        if savedChallenges.count > 50 {
            savedChallenges = Array(savedChallenges.suffix(50))
        }
        
        do {
            let data = try JSONEncoder().encode(savedChallenges)
            userDefaults.set(data, forKey: savedChallengesKey)
            print("Challenge saved successfully")
        } catch {
            print("Failed to save challenge: \(error)")
            throw ChallengeError.validationError("Failed to save challenge: \(error.localizedDescription)")
        }
    }
    
    func loadSavedChallenges() -> [Challenge] {
        print("Loading saved challenges from local storage")
        
        guard let data = userDefaults.data(forKey: savedChallengesKey) else {
            print("No saved challenges found")
            return []
        }
        
        do {
            let challenges = try JSONDecoder().decode([Challenge].self, from: data)
            
            // Filter out expired challenges
            let validChallenges = challenges.filter { $0.isValid }
            
            // If we filtered out expired challenges, save the cleaned list
            if validChallenges.count != challenges.count {
                let cleanedData = try JSONEncoder().encode(validChallenges)
                userDefaults.set(cleanedData, forKey: savedChallengesKey)
                print("Cleaned up \(challenges.count - validChallenges.count) expired challenges")
            }
            
            print("Loaded \(validChallenges.count) valid saved challenges")
            return validChallenges
        } catch {
            print("Failed to load saved challenges: \(error)")
            return []
        }
    }
    
    func deleteSavedChallenge(challengeID: String) throws {
        print("Deleting saved challenge: \(challengeID)")
        
        var savedChallenges = loadSavedChallenges()
        let originalCount = savedChallenges.count
        
        savedChallenges.removeAll { $0.id == challengeID }
        
        guard savedChallenges.count < originalCount else {
            print("Challenge not found for deletion: \(challengeID)")
            throw ChallengeError.notFound
        }
        
        do {
            let data = try JSONEncoder().encode(savedChallenges)
            userDefaults.set(data, forKey: savedChallengesKey)
            print("Challenge deleted successfully")
        } catch {
            print("Failed to delete challenge: \(error)")
            throw ChallengeError.validationError("Failed to delete challenge: \(error.localizedDescription)")
        }
    }
}

// MARK: - Analytics Events Extension

extension AnalyticsEvent {
    static func challengeLoaded(code: String) -> AnalyticsEvent {
        return .challengeShared(challengeId: code)
    }
    
    static func challengeCreated(title: String, difficulty: String) -> AnalyticsEvent {
        return .settingsChanged(setting: "challenge_created", value: difficulty)
    }
}