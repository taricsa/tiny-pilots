//
//  DIContainerTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on 7/15/25.
//

import XCTest
@testable import Tiny_Pilots

class DIContainerTests: XCTestCase {
    
    var sut: DIContainer!
    
    override func setUp() {
        super.setUp()
        sut = DIContainer()
    }
    
    override func tearDown() {
        sut.clear()
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Registration Tests
    
    func testRegisterService_WithSimpleFactory_ShouldRegisterSuccessfully() {
        // Given
        let expectedValue = "Test Service"
        
        // When
        sut.register(TestService.self) {
            return TestService(value: expectedValue)
        }
        
        // Then
        XCTAssertTrue(sut.isRegistered(TestService.self))
    }
    
    func testRegisterService_WithContainerFactory_ShouldRegisterSuccessfully() {
        // Given
        let expectedValue = "Container Service"
        
        // When
        sut.register(TestService.self) { container in
            return TestService(value: expectedValue)
        }
        
        // Then
        XCTAssertTrue(sut.isRegistered(TestService.self))
    }
    
    func testRegisterSingleton_WithInstance_ShouldRegisterSuccessfully() {
        // Given
        let instance = TestService(value: "Singleton")
        
        // When
        sut.registerSingleton(TestService.self, instance: instance)
        
        // Then
        XCTAssertTrue(sut.isRegistered(TestService.self))
    }
    
    // MARK: - Resolution Tests
    
    func testResolve_RegisteredService_ShouldReturnInstance() throws {
        // Given
        let expectedValue = "Test Value"
        sut.register(TestService.self) {
            return TestService(value: expectedValue)
        }
        
        // When
        let resolved = try sut.resolve(TestService.self)
        
        // Then
        XCTAssertEqual(resolved.value, expectedValue)
    }
    
    func testResolve_UnregisteredService_ShouldThrowError() {
        // Given
        // No service registered
        
        // When & Then
        XCTAssertThrowsError(try sut.resolve(TestService.self)) { error in
            guard case DIError.serviceNotRegistered = error else {
                XCTFail("Expected serviceNotRegistered error")
                return
            }
        }
    }
    
    func testTryResolve_RegisteredService_ShouldReturnInstance() {
        // Given
        let expectedValue = "Test Value"
        sut.register(TestService.self) {
            return TestService(value: expectedValue)
        }
        
        // When
        let resolved = sut.tryResolve(TestService.self)
        
        // Then
        XCTAssertNotNil(resolved)
        XCTAssertEqual(resolved?.value, expectedValue)
    }
    
    func testTryResolve_UnregisteredService_ShouldReturnNil() {
        // Given
        // No service registered
        
        // When
        let resolved = sut.tryResolve(TestService.self)
        
        // Then
        XCTAssertNil(resolved)
    }
    
    // MARK: - Singleton Tests
    
    func testResolve_SingletonService_ShouldReturnSameInstance() throws {
        // Given
        sut.register(TestService.self, lifetime: .singleton) {
            return TestService(value: "Singleton")
        }
        
        // When
        let instance1 = try sut.resolve(TestService.self)
        let instance2 = try sut.resolve(TestService.self)
        
        // Then
        XCTAssertTrue(instance1 === instance2)
    }
    
    func testResolve_TransientService_ShouldReturnDifferentInstances() throws {
        // Given
        sut.register(TestService.self, lifetime: .transient) {
            return TestService(value: "Transient")
        }
        
        // When
        let instance1 = try sut.resolve(TestService.self)
        let instance2 = try sut.resolve(TestService.self)
        
        // Then
        XCTAssertFalse(instance1 === instance2)
    }
    
    func testRegisterSingleton_WithInstance_ShouldReturnSameInstance() throws {
        // Given
        let originalInstance = TestService(value: "Original")
        sut.registerSingleton(TestService.self, instance: originalInstance)
        
        // When
        let resolved = try sut.resolve(TestService.self)
        
        // Then
        XCTAssertTrue(originalInstance === resolved)
    }
    
    // MARK: - Utility Tests
    
    func testIsRegistered_RegisteredService_ShouldReturnTrue() {
        // Given
        sut.register(TestService.self) {
            return TestService(value: "Test")
        }
        
        // When
        let isRegistered = sut.isRegistered(TestService.self)
        
        // Then
        XCTAssertTrue(isRegistered)
    }
    
    func testIsRegistered_UnregisteredService_ShouldReturnFalse() {
        // Given
        // No service registered
        
        // When
        let isRegistered = sut.isRegistered(TestService.self)
        
        // Then
        XCTAssertFalse(isRegistered)
    }
    
    func testClear_ShouldRemoveAllServices() {
        // Given
        sut.register(TestService.self) {
            return TestService(value: "Test")
        }
        XCTAssertTrue(sut.isRegistered(TestService.self))
        
        // When
        sut.clear()
        
        // Then
        XCTAssertFalse(sut.isRegistered(TestService.self))
    }
}

// MARK: - Test Helpers

private class TestService {
    let value: String
    
    init(value: String) {
        self.value = value
    }
}

private protocol TestProtocol {
    var protocolValue: String { get }
}

private class TestImplementation: TestProtocol {
    let protocolValue: String
    
    init(protocolValue: String = "Protocol Implementation") {
        self.protocolValue = protocolValue
    }
}