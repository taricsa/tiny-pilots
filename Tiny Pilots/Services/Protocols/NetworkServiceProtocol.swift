//
//  NetworkServiceProtocol.swift
//  Tiny Pilots
//
//  Created by Kiro on Production Readiness Implementation
//

import Foundation

/// Protocol defining network service functionality
protocol NetworkServiceProtocol {
    /// Load challenge data from server
    /// - Parameters:
    ///   - code: Challenge code to load
    ///   - completion: Completion handler with challenge or error
    func loadChallenge(code: String) async throws -> Challenge
    
    /// Load weekly special data from server
    /// - Parameter completion: Completion handler with weekly special or error
    func loadWeeklySpecial() async throws -> WeeklySpecial
    
    /// Submit daily run result to server
    /// - Parameters:
    ///   - result: Daily run result to submit
    ///   - completion: Completion handler with optional error
    func submitDailyRunResult(_ result: DailyRunResult) async throws
    
    /// Load daily run data from server
    /// - Parameters:
    ///   - date: Date for the daily run
    ///   - completion: Completion handler with daily run or error
    func loadDailyRun(for date: Date) async throws -> DailyRun?
}

/// Network service errors
enum NetworkServiceError: Error, LocalizedError {
    case invalidURL
    case noData
    case invalidResponse
    case serverError(Int)
    case decodingError
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        case .networkUnavailable:
            return "Network unavailable"
        }
    }
}



/// Production network service implementation
class NetworkService: NetworkServiceProtocol {
    
    private let session = URLSession.shared
    private let baseURL: String
    
    init() {
        self.baseURL = ConfigurationManager.shared.apiBaseURL
    }
    
    func loadChallenge(code: String) async throws -> Challenge {
        guard let url = URL(string: "\(baseURL)/challenges/\(code)") else {
            throw NetworkServiceError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkServiceError.serverError(httpResponse.statusCode)
        }
        
        do {
            let challenge = try JSONDecoder().decode(Challenge.self, from: data)
            return challenge
        } catch {
            throw NetworkServiceError.decodingError
        }
    }
    
    func loadWeeklySpecial() async throws -> WeeklySpecial {
        guard let url = URL(string: "\(baseURL)/weekly-special") else {
            throw NetworkServiceError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkServiceError.serverError(httpResponse.statusCode)
        }
        
        do {
            let weeklySpecial = try JSONDecoder().decode(WeeklySpecial.self, from: data)
            return weeklySpecial
        } catch {
            throw NetworkServiceError.decodingError
        }
    }
    
    func submitDailyRunResult(_ result: DailyRunResult) async throws {
        guard let url = URL(string: "\(baseURL)/daily-runs/results") else {
            throw NetworkServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(result)
        } catch {
            throw NetworkServiceError.decodingError
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw NetworkServiceError.serverError(httpResponse.statusCode)
        }
    }
    
    func loadDailyRun(for date: Date) async throws -> DailyRun? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        guard let url = URL(string: "\(baseURL)/daily-runs/\(dateString)") else {
            throw NetworkServiceError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkServiceError.invalidResponse
        }
        
        if httpResponse.statusCode == 404 {
            // No server-side daily run for this date
            return nil
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkServiceError.serverError(httpResponse.statusCode)
        }
        
        do {
            let dailyRun = try JSONDecoder().decode(DailyRun.self, from: data)
            return dailyRun
        } catch {
            throw NetworkServiceError.decodingError
        }
    }
}