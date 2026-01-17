//
//  NetworkMonitor.swift
//  Tiny Pilots
//
//  Created by Kiro on 7/15/25.
//

import Foundation
import Network
import SystemConfiguration

/// Network monitoring system for tracking connectivity and handling offline scenarios
class NetworkMonitor: ObservableObject, @unchecked Sendable {
    static let shared = NetworkMonitor()
    
    // MARK: - Properties
    
    @Published private(set) var isConnected = false
    @Published private(set) var connectionType: ConnectionType = .unknown
    @Published private(set) var isExpensive = false
    @Published private(set) var isConstrained = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.tinypilots.networkmonitor", qos: .utility)
    
    private var isMonitoring = false
    private var connectionHistory: [ConnectionEvent] = []
    private let maxConnectionHistory = 100
    
    // Retry configuration
    private var retryConfiguration: RetryConfiguration = .default
    private var activeRetryOperations: [String: RetryOperation] = [:]
    
    // Offline mode
    private var offlineModeEnabled = false
    private var offlineQueue: [OfflineOperation] = []
    private let maxOfflineOperations = 50
    
    // MARK: - Initialization
    
    private init() {
        setupNetworkMonitoring()
    }
    
    // MARK: - Public Interface
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        monitor.start(queue: queue)
        isMonitoring = true
        
        Logger.shared.info("Network monitoring started", category: .network)
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        monitor.cancel()
        isMonitoring = false
        
        Logger.shared.info("Network monitoring stopped", category: .network)
    }
    
    func setRetryConfiguration(_ configuration: RetryConfiguration) {
        self.retryConfiguration = configuration
        Logger.shared.info("Network retry configuration updated", category: .network)
    }
    
    func performRequest<T>(
        _ request: NetworkRequest<T>,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        guard isConnected else {
            handleOfflineRequest(request, completion: completion)
            return
        }
        
        executeRequest(request, attempt: 1, completion: completion)
    }
    
    func enableOfflineMode(_ enabled: Bool) {
        offlineModeEnabled = enabled
        
        if enabled {
            Logger.shared.info("Offline mode enabled", category: .network)
            AnalyticsManager.shared.trackEvent(.offlineModeActivated)
        } else {
            Logger.shared.info("Offline mode disabled", category: .network)
            processOfflineQueue()
        }
    }
    
    func getConnectionStatus() -> ConnectionStatus {
        return ConnectionStatus(
            isConnected: isConnected,
            connectionType: connectionType,
            isExpensive: isExpensive,
            isConstrained: isConstrained,
            lastConnectedTime: getLastConnectedTime(),
            connectionHistory: Array(connectionHistory.suffix(10))
        )
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handlePathUpdate(path)
            }
        }
    }
    
    private func handlePathUpdate(_ path: NWPath) {
        let wasConnected = isConnected
        let previousConnectionType = connectionType
        
        // Update connection status
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
        connectionType = determineConnectionType(from: path)
        
        // Log connection changes
        if wasConnected != isConnected {
            let status = isConnected ? "connected" : "disconnected"
            Logger.shared.info("Network status changed: \(status)", category: .network)
            
            // Track in analytics
            AnalyticsManager.shared.trackEvent(.networkConnectivityChanged(isConnected: isConnected))
            
            // Record connection event
            recordConnectionEvent(
                isConnected: isConnected,
                connectionType: connectionType,
                reason: isConnected ? .connected : .disconnected
            )
            
            // Handle connection state changes
            if isConnected && !wasConnected {
                handleConnectionRestored()
            } else if !isConnected && wasConnected {
                handleConnectionLost()
            }
        }
        
        // Log connection type changes
        if connectionType != previousConnectionType {
            Logger.shared.info("Connection type changed: \(connectionType)", category: .network)
        }
    }
    
    private func determineConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else if path.usesInterfaceType(.other) {
            return .other
        } else {
            return .unknown
        }
    }
    
    private func handleConnectionRestored() {
        Logger.shared.info("Network connection restored", category: .network)
        
        // Process offline queue
        if offlineModeEnabled {
            processOfflineQueue()
        }
        
        // Retry failed operations
        retryFailedOperations()
    }
    
    private func handleConnectionLost() {
        Logger.shared.warning("Network connection lost", category: .network)
        
        // Enable offline mode if configured
        if !offlineModeEnabled {
            enableOfflineMode(true)
        }
    }
    
    private func executeRequest<T>(
        _ request: NetworkRequest<T>,
        attempt: Int,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        // Simulate network request execution
        Task {
            do {
                let result = try await simulateNetworkRequest(request)
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            } catch {
                DispatchQueue.main.async {
                    self.handleRequestError(error, request: request, attempt: attempt, completion: completion)
                }
            }
        }
    }
    
    private func handleRequestError<T>(
        _ error: Error,
        request: NetworkRequest<T>,
        attempt: Int,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        let networkError = error as? NetworkError ?? .unknown(error)
        
        Logger.shared.error("Network request failed (attempt \(attempt))", error: error, category: .network)
        
        // Track failed request in analytics
        AnalyticsManager.shared.trackEvent(.networkRequestFailed(
            endpoint: request.endpoint,
            error: error.localizedDescription
        ))
        
        // Check if we should retry
        if shouldRetry(error: networkError, attempt: attempt) {
            let delay = calculateRetryDelay(attempt: attempt)
            
            Logger.shared.info("Retrying network request in \(delay)s (attempt \(attempt + 1))", category: .network)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.executeRequest(request, attempt: attempt + 1, completion: completion)
            }
        } else {
            completion(.failure(networkError))
        }
    }
    
    private func shouldRetry(error: NetworkError, attempt: Int) -> Bool {
        guard attempt < retryConfiguration.maxAttempts else { return false }
        
        switch error {
        case .timeout, .serverError, .networkUnavailable:
            return true
        case .clientError, .invalidResponse, .decodingError:
            return false
        case .unknown:
            return true
        }
    }
    
    private func calculateRetryDelay(attempt: Int) -> TimeInterval {
        let baseDelay = retryConfiguration.baseDelay
        let maxDelay = retryConfiguration.maxDelay
        
        switch retryConfiguration.strategy {
        case .linear:
            return min(baseDelay * TimeInterval(attempt), maxDelay)
        case .exponential:
            return min(baseDelay * pow(2.0, TimeInterval(attempt - 1)), maxDelay)
        case .fixed:
            return baseDelay
        }
    }
    
    private func handleOfflineRequest<T>(
        _ request: NetworkRequest<T>,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        if offlineModeEnabled {
            // Queue request for later
            let offlineOperation = OfflineOperation(
                id: UUID().uuidString,
                request: AnyNetworkRequest(request),
                timestamp: Date(),
                completion: { result in
                    switch result {
                    case .success(let value):
                        if let typedValue = value as? T {
                            completion(.success(typedValue))
                        } else {
                            completion(.failure(.decodingError(NSError(domain: "TypeMismatch", code: 0))))
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            )
            
            queueOfflineOperation(offlineOperation)
        } else {
            completion(.failure(.networkUnavailable))
        }
    }
    
    private func queueOfflineOperation(_ operation: OfflineOperation) {
        offlineQueue.append(operation)
        
        // Remove old operations if queue is full
        if offlineQueue.count > maxOfflineOperations {
            offlineQueue.removeFirst(offlineQueue.count - maxOfflineOperations)
            Logger.shared.warning("Offline queue overflow, removed old operations", category: .network)
        }
        
        Logger.shared.info("Queued operation for offline processing: \(operation.id)", category: .network)
    }
    
    private func processOfflineQueue() {
        guard isConnected && !offlineQueue.isEmpty else { return }
        
        Logger.shared.info("Processing \(offlineQueue.count) offline operations", category: .network)
        
        let operationsToProcess = Array(offlineQueue)
        offlineQueue.removeAll()
        
        for operation in operationsToProcess {
            executeOfflineOperation(operation)
        }
    }
    
    private func executeOfflineOperation(_ operation: OfflineOperation) {
        // Execute the queued operation
        Task {
            do {
                let result = try await simulateNetworkRequest(operation.request)
                DispatchQueue.main.async {
                    operation.completion(.success(result))
                }
            } catch {
                DispatchQueue.main.async {
                    operation.completion(.failure(error as? NetworkError ?? .unknown(error)))
                }
            }
        }
    }
    
    private func retryFailedOperations() {
        // Retry any operations that were marked for retry
        for (_, retryOperation) in activeRetryOperations {
            Logger.shared.info("Retrying failed operation: \(retryOperation.id)", category: .network)
            // Implementation would retry the specific operation
        }
        
        activeRetryOperations.removeAll()
    }
    
    private func recordConnectionEvent(isConnected: Bool, connectionType: ConnectionType, reason: ConnectionEventReason) {
        let event = ConnectionEvent(
            timestamp: Date(),
            isConnected: isConnected,
            connectionType: connectionType,
            reason: reason
        )
        
        connectionHistory.append(event)
        
        // Keep only recent events
        if connectionHistory.count > maxConnectionHistory {
            connectionHistory.removeFirst(connectionHistory.count - maxConnectionHistory)
        }
    }
    
    private func getLastConnectedTime() -> Date? {
        return connectionHistory.last { $0.isConnected }?.timestamp
    }
    
    private func simulateNetworkRequest<T>(_ request: NetworkRequest<T>) async throws -> T {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000...500_000_000)) // 0.1-0.5 seconds
        
        // Simulate occasional failures
        if Int.random(in: 1...20) == 1 {
            throw NetworkError.timeout
        }
        
        if Int.random(in: 1...30) == 1 {
            throw NetworkError.serverError(500)
        }
        
        // Return mock response
        return request.mockResponse
    }
    
    private func simulateNetworkRequest(_ request: AnyNetworkRequest) async throws -> Any {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000...500_000_000))
        
        // Simulate occasional failures
        if Int.random(in: 1...20) == 1 {
            throw NetworkError.timeout
        }
        
        // Return mock response
        return request.mockResponse
    }
    
    deinit {
        stopMonitoring()
    }
}

// MARK: - Supporting Types

enum ConnectionType: String, CaseIterable {
    case wifi = "wifi"
    case cellular = "cellular"
    case ethernet = "ethernet"
    case other = "other"
    case unknown = "unknown"
}

enum NetworkError: Error, LocalizedError {
    case networkUnavailable
    case timeout
    case serverError(Int)
    case clientError(Int)
    case invalidResponse
    case decodingError(Error)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network is unavailable"
        case .timeout:
            return "Request timed out"
        case .serverError(let code):
            return "Server error (\(code))"
        case .clientError(let code):
            return "Client error (\(code))"
        case .invalidResponse:
            return "Invalid response received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

struct RetryConfiguration {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let strategy: RetryStrategy
    
    static let `default` = RetryConfiguration(
        maxAttempts: 3,
        baseDelay: 1.0,
        maxDelay: 30.0,
        strategy: .exponential
    )
    
    enum RetryStrategy {
        case linear
        case exponential
        case fixed
    }
}

struct NetworkRequest<T> {
    let endpoint: String
    let method: HTTPMethod
    let headers: [String: String]
    let body: Data?
    let timeout: TimeInterval
    let mockResponse: T
    
    enum HTTPMethod: String {
        case GET, POST, PUT, DELETE, PATCH
    }
}

struct AnyNetworkRequest {
    let endpoint: String
    let method: String
    let headers: [String: String]
    let body: Data?
    let timeout: TimeInterval
    let mockResponse: Any
    
    init<T>(_ request: NetworkRequest<T>) {
        self.endpoint = request.endpoint
        self.method = request.method.rawValue
        self.headers = request.headers
        self.body = request.body
        self.timeout = request.timeout
        self.mockResponse = request.mockResponse
    }
}

struct ConnectionEvent {
    let timestamp: Date
    let isConnected: Bool
    let connectionType: ConnectionType
    let reason: ConnectionEventReason
}

enum ConnectionEventReason {
    case connected
    case disconnected
    case typeChanged
}

struct ConnectionStatus {
    let isConnected: Bool
    let connectionType: ConnectionType
    let isExpensive: Bool
    let isConstrained: Bool
    let lastConnectedTime: Date?
    let connectionHistory: [ConnectionEvent]
    
    var description: String {
        return """
        Connection Status:
        - Connected: \(isConnected)
        - Type: \(connectionType.rawValue)
        - Expensive: \(isExpensive)
        - Constrained: \(isConstrained)
        - Last Connected: \(lastConnectedTime?.description ?? "Never")
        """
    }
}

private struct OfflineOperation {
    let id: String
    let request: AnyNetworkRequest
    let timestamp: Date
    let completion: (Result<Any, NetworkError>) -> Void
}

private struct RetryOperation {
    let id: String
    let request: AnyNetworkRequest
    let attempt: Int
    let nextRetryTime: Date
}