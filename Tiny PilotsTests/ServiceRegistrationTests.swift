//
//  ServiceRegistrationTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on 7/15/25.
//

import XCTest
@testable import Tiny_Pilots

class ServiceRegistrationTests: XCTestCase {
    
    var container: DIContainer!
    var sut: ServiceRegistration!
    
    override func setUp() {
        super.setUp()
        container = DIContainer()
        sut = ServiceRegistration(container: container)
    }
    
    override func tearDown() {
        container.clear()
        container = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Configuration Tests
    
    func testConfigureServices_ShouldCompleteWithoutError() {
        // Given
        // Fresh service registration instance
        
        // When & Then
        XCTAssertNoThrow(sut.configureServices())
    }
    
    func testValidateConfiguration_InitialState_ShouldReturnEmptyArray() {
        // Given
        // Fresh service registration instance
        
        // When
        let missingServices = sut.validateConfiguration()
        
        // Then
        XCTAssertTrue(missingServices.isEmpty)
    }
    
    func testIsConfigurationValid_InitialState_ShouldReturnTrue() {
        // Given
        // Fresh service registration instance
        
        // When
        let isValid = sut.isConfigurationValid()
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    // MARK: - Registration Extension Tests
    
    func testRegisterProtocolWithImplementation_ShouldRegisterSuccessfully() throws {
        // Given
        // Service registration instance
        
        // When
        sut.register(TestProtocol.self, implementation: TestImplementation.self)
        
        // Then
        XCTAssertTrue(container.isRegistered(TestProtocol.self))
        let resolved = try container.resolve(TestProtocol.self)
        XCTAssertNotNil(resolved)
        XCTAssertEqual(resolved.protocolValue, "Protocol Implementation")
    }
    
    func testRegisterWithCustomFactory_ShouldRegisterSuccessfully() throws {
        // Given
        let expectedValue = "Custom Factory"
        
        // When
        sut.register(TestProtocol.self) {
            return TestImplementation(protocolValue: expectedValue)
        }
        
        // Then
        XCTAssertTrue(container.isRegistered(TestProtocol.self))
        let resolved = try container.resolve(TestProtocol.self)
        XCTAssertEqual(resolved.protocolValue, expectedValue)
    }
    
    func testRegisterWithDependencyInjectionFactory_ShouldRegisterSuccessfully() throws {
        // Given
        let expectedValue = "DI Factory"
        
        // When
        sut.register(TestProtocol.self) { container in
            return TestImplementation(protocolValue: expectedValue)
        }
        
        // Then
        XCTAssertTrue(container.isRegistered(TestProtocol.self))
        let resolved = try container.resolve(TestProtocol.self)
        XCTAssertEqual(resolved.protocolValue, expectedValue)
    }
    
    func testRegisterWithSingletonLifetime_ShouldReturnSameInstance() throws {
        // Given
        sut.register(TestProtocol.self, implementation: TestImplementation.self, lifetime: .singleton)
        
        // When
        let instance1 = try container.resolve(TestProtocol.self)
        let instance2 = try container.resolve(TestProtocol.self)
        
        // Then
        XCTAssertTrue(instance1 as AnyObject === instance2 as AnyObject)
    }
    
    func testRegisterWithTransientLifetime_ShouldReturnDifferentInstances() throws {
        // Given
        sut.register(TestProtocol.self, implementation: TestImplementation.self, lifetime: .transient)
        
        // When
        let instance1 = try container.resolve(TestProtocol.self)
        let instance2 = try container.resolve(TestProtocol.self)
        
        // Then
        XCTAssertFalse(instance1 as AnyObject === instance2 as AnyObject)
    }
}

// MARK: - Test Helpers

private protocol TestProtocol {
    var protocolValue: String { get }
}

private class TestImplementation: TestProtocol {
    let protocolValue: String
    
    required init() {
        self.protocolValue = "Protocol Implementation"
    }
    
    init(protocolValue: String) {
        self.protocolValue = protocolValue
    }
}