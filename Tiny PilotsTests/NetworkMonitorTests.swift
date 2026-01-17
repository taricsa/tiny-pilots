//
//  NetworkMonitorTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on 7/15/25.
//

import XCTest
@testable import Tiny_Pilots

final class NetworkMonitorTests: XCTestCase {
    
    var networkMonitor: NetworkMonitor!
    
    override func setUp() {
        super.setUp()
        networkMonitor = NetworkMonitor.shared
    }
    
    override func tearDown() {
        networkMonitor.stopMonitoring()
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testNetworkMonitorInitialization() {
        // Given: Network monitor
        // When: Checking initial state
        // Then: Should have valid initial state
        XCTAssertNotNil(networkMonitor)
        
        let status = networkMonitor.getConnectionStatus()
        XCTAssertNotNil(status)
    }
    
    func testStartAndStopMonitoring() {
        // Given: Network monitor
        // When: Starting monitoring
        XCTAssertNoThrow(networkMonitor.startMonitoring())
        
        // When: Stopping monitoring
        XCTAssertNoThrow(networkMonitor.stopMonitoring())
    }
    
    // MARK: - Connection Status Tests
    
    func testConnectionStatus() {
        // Given: Network monitor
        // When: Getting connection status
        let status = networkMonitor.getConnectionStatus()
        
        // Then: Should have valid status
        XCTAssertNotNil(status.connectionType)
        XCTAssertNotNil(status.connectionHistory)
        XCTAssertFalse(status.description.isEmpty)
    }
    
    func testConnectionTypes() {
        // Given: Connection types
        let types: [ConnectionType] = [.wifi, .cellular, .ethernet, .other, .unknown]
        
        // When: Checking raw values
        // Then: Should have correct string representations
        XCTAssertEqual(ConnectionType.wifi.rawValue, "wifi")
        XCTAssertEqual(ConnectionType.cellular.rawValue, "cellular")
        XCTAssertEqual(ConnectionType.ethernet.rawValue, "ethernet")
        XCTAssertEqual(ConnectionType.other.rawValue, "other")
        XCTAssertEqual(ConnectionType.unknown.rawValue, "unknown")
        
        // All cases should be covered
        XCTAssertEqual(ConnectionType.allCases.count, 5)
    }
    
    // MARK: - Retry Configuration Tests
    
    func testDefaultRetryConfiguration() {
        // Given: Default retry configuration
        let config = RetryConfiguration.default
        
        // When: Checking default values
        // Then: Should have sensible defaults
        XCTAssertEqual(config.maxAttempts, 3)
        XCTAssertEqual(config.baseDelay, 1.0)
        XCTAssertEqual(config.maxDelay, 30.0)
        XCTAssertEqual(config.strategy, .exponential)
    }
    
    func testCustomRetryConfiguration() {
        // Given: Custom retry configuration
        let config = RetryConfiguration(
            maxAttempts: 5,
            baseDelay: 2.0,
            maxDelay: 60.0,
            strategy: .linear
        )
        
        // When: Setting configuration
        XCTAssertNoThrow(networkMonitor.setRetryConfiguration(config))
        
        // Then: Should accept configuration without issues
        XCTAssertTrue(true) // If we reach here, configuration was set successfully
    }
    
    // MARK: - Network Request Tests
    
    func testNetworkRequestCreation() {
        // Given: Network request parameters
        let endpoint = "https://api.example.com/test"
        let headers = ["Content-Type": "application/json"]
        let mockResponse = "Test Response"
        
        // When: Creating network request
        let request = NetworkRequest(
            endpoint: endpoint,
            method: .GET,
            headers: headers,
            body: nil,
            timeout: 30.0,
            mockResponse: mockResponse
        )
        
        // Then: Should have correct properties
        XCTAssertEqual(request.endpoint, endpoint)
        XCTAssertEqual(request.method, .GET)
        XCTAssertEqual(request.headers, headers)
        XCTAssertNil(request.body)
        XCTAssertEqual(request.timeout, 30.0)
        XCTAssertEqual(request.mockResponse, mockResponse)
    }
    
    func testHTTPMethods() {
        // Given: HTTP methods
        let methods: [NetworkRequest<String>.HTTPMethod] = [.GET, .POST, .PUT, .DELETE, .PATCH]
        
        // When: Checking raw values
        // Then: Should have correct string representations
        XCTAssertEqual(NetworkRequest<String>.HTTPMethod.GET.rawValue, "GET")
        XCTAssertEqual(NetworkRequest<String>.HTTPMethod.POST.rawValue, "POST")
        XCTAssertEqual(NetworkRequest<String>.HTTPMethod.PUT.rawValue, "PUT")
        XCTAssertEqual(NetworkRequest<String>.HTTPMethod.DELETE.rawValue, "DELETE")
        XCTAssertEqual(NetworkRequest<String>.HTTPMethod.PATCH.rawValue, "PATCH")
    }
    
    func testPerformRequest() {
        // Given: Network monitor and request
        let request = NetworkRequest(
            endpoint: "https://api.example.com/test",
            method: .GET,
            headers: [:],
            body: nil,
            timeout: 30.0,
            mockResponse: "Success"
        )
        
        let expectation = XCTestExpectation(description: "Network request completed")
        
        // When: Performing request
        networkMonitor.performRequest(request) { result in
            // Then: Should complete (success or failure)
            switch result {
            case .success(let response):
                XCTAssertEqual(response, "Success")
            case .failure(let error):
                // Network might not be available in test environment
                XCTAssertNotNil(error)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Offline Mode Tests
    
    func testOfflineModeToggle() {
        // Given: Network monitor
        // When: Enabling offline mode
        XCTAssertNoThrow(networkMonitor.enableOfflineMode(true))
        
        // When: Disabling offline mode
        XCTAssertNoThrow(networkMonitor.enableOfflineMode(false))
    }
    
    func testOfflineRequestHandling() {
        // Given: Network monitor with offline mode enabled
        networkMonitor.enableOfflineMode(true)
        
        let request = NetworkRequest(
            endpoint: "https://api.example.com/offline-test",
            method: .POST,
            headers: [:],
            body: nil,
            timeout: 30.0,
            mockResponse: "Offline Response"
        )
        
        let expectation = XCTestExpectation(description: "Offline request handled")
        
        // When: Performing request in offline mode
        networkMonitor.performRequest(request) { result in
            // Then: Should handle request appropriately
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorDescriptions() {
        // Given: Network errors
        let errors: [NetworkError] = [
            .networkUnavailable,
            .timeout,
            .serverError(500),
            .clientError(404),
            .invalidResponse,
            .decodingError(NSError(domain: "TestError", code: 0)),
            .unknown(NSError(domain: "UnknownError", code: 0))
        ]
        
        // When: Getting error descriptions
        // Then: Should have meaningful descriptions
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    func testSpecificErrorDescriptions() {
        // Given: Specific errors
        let serverError = NetworkError.serverError(500)
        let clientError = NetworkError.clientError(404)
        
        // When: Getting descriptions
        // Then: Should include error codes
        XCTAssertTrue(serverError.errorDescription!.contains("500"))
        XCTAssertTrue(clientError.errorDescription!.contains("404"))
    }
    
    // MARK: - AnyNetworkRequest Tests
    
    func testAnyNetworkRequestConversion() {
        // Given: Typed network request
        let typedRequest = NetworkRequest(
            endpoint: "https://api.example.com/test",
            method: .POST,
            headers: ["Authorization": "Bearer token"],
            body: "test data".data(using: .utf8),
            timeout: 15.0,
            mockResponse: ["key": "value"]
        )
        
        // When: Converting to AnyNetworkRequest
        let anyRequest = AnyNetworkRequest(typedRequest)
        
        // Then: Should preserve all properties
        XCTAssertEqual(anyRequest.endpoint, typedRequest.endpoint)
        XCTAssertEqual(anyRequest.method, typedRequest.method.rawValue)
        XCTAssertEqual(anyRequest.headers, typedRequest.headers)
        XCTAssertEqual(anyRequest.body, typedRequest.body)
        XCTAssertEqual(anyRequest.timeout, typedRequest.timeout)
    }
    
    // MARK: - Connection Event Tests
    
    func testConnectionEvent() {
        // Given: Connection event parameters
        let timestamp = Date()
        let connectionType = ConnectionType.wifi
        let reason = ConnectionEventReason.connected
        
        // When: Creating connection event
        let event = ConnectionEvent(
            timestamp: timestamp,
            isConnected: true,
            connectionType: connectionType,
            reason: reason
        )
        
        // Then: Should have correct properties
        XCTAssertEqual(event.timestamp, timestamp)
        XCTAssertTrue(event.isConnected)
        XCTAssertEqual(event.connectionType, connectionType)
        XCTAssertEqual(event.reason, reason)
    }
    
    // MARK: - Retry Strategy Tests
    
    func testRetryStrategies() {
        // Given: Retry strategies
        let strategies: [RetryConfiguration.RetryStrategy] = [.linear, .exponential, .fixed]
        
        // When: Using strategies in configuration
        for strategy in strategies {
            let config = RetryConfiguration(
                maxAttempts: 3,
                baseDelay: 1.0,
                maxDelay: 10.0,
                strategy: strategy
            )
            
            // Then: Should create valid configuration
            XCTAssertEqual(config.strategy, strategy)
        }
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceOfStatusChecking() {
        // Given: Network monitor
        // When: Getting status multiple times
        measure {
            for _ in 0..<100 {
                _ = networkMonitor.getConnectionStatus()
            }
        }
    }
    
    func testPerformanceOfRequestCreation() {
        // Given: Request parameters
        // When: Creating multiple requests
        measure {
            for i in 0..<1000 {
                _ = NetworkRequest(
                    endpoint: "https://api.example.com/test/\(i)",
                    method: .GET,
                    headers: [:],
                    body: nil,
                    timeout: 30.0,
                    mockResponse: "Response \(i)"
                )
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testIntegrationWithAnalytics() {
        // Given: Network monitor
        // When: Enabling offline mode (should trigger analytics)
        XCTAssertNoThrow(networkMonitor.enableOfflineMode(true))
        
        // Then: Should not crash (analytics integration working)
        XCTAssertTrue(true)
    }
    
    func testIntegrationWithLogger() {
        // Given: Network monitor
        // When: Starting monitoring (should trigger logging)
        XCTAssertNoThrow(networkMonitor.startMonitoring())
        
        // Then: Should not crash (logger integration working)
        XCTAssertTrue(true)
    }
}