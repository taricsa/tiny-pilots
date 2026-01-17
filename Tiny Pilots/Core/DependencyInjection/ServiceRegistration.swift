//
//  ServiceRegistration.swift
//  Tiny Pilots
//
//  Created by Kiro on 7/15/25.
//

import Foundation
import SwiftData

/// Service registration configuration class for setting up dependency injection
class ServiceRegistration {
    
    // MARK: - Properties
    
    private let container: DIContainer
    
    // MARK: - Initialization
    
    init(container: DIContainer = DIContainer.shared) {
        self.container = container
    }
    
    // MARK: - Registration Methods
    
    /// Configure all services for the application
    func configureServices() {
        registerCoreServices()
        registerGameServices()
        registerUIServices()
    }
    
    // MARK: - Private Registration Methods
    
    private func registerCoreServices() {
        // Register SwiftData ModelContext as singleton
        container.register(ModelContext.self, lifetime: .singleton) { _ in
            // Access mainContext on main actor
            var context: ModelContext!
            let semaphore = DispatchSemaphore(value: 0)
            Task { @MainActor in
                context = SwiftDataManager.shared.mainContext
                semaphore.signal()
            }
            semaphore.wait()
            return context
        }
        
        // Register core services as singletons
        container.register(AudioServiceProtocol.self, lifetime: .singleton) { _ in
            return AudioService()
        }
        
        container.register(PhysicsServiceProtocol.self, lifetime: .singleton) { _ in
            return PhysicsService()
        }
        
        container.register(GameCenterServiceProtocol.self, lifetime: .singleton) { _ in
            return GameCenterService()
        }
        
        container.register(NetworkServiceProtocol.self, lifetime: .singleton) { _ in
            return NetworkService()
        }
        
        container.register(ChallengeServiceProtocol.self, lifetime: .singleton) { container in
            do {
                let gameCenterService = try container.resolve(GameCenterServiceProtocol.self)
                return ChallengeService(gameCenterService: gameCenterService)
            } catch {
                fatalError("Failed to resolve dependencies for ChallengeService: \(error)")
            }
        }
        
        container.register(WeeklySpecialServiceProtocol.self, lifetime: .singleton) { container in
            do {
                let gameCenterService = try container.resolve(GameCenterServiceProtocol.self)
                let networkService = try container.resolve(NetworkServiceProtocol.self)
                return WeeklySpecialService(gameCenterService: gameCenterService, networkService: networkService)
            } catch {
                fatalError("Failed to resolve dependencies for WeeklySpecialService: \(error)")
            }
        }
        
        container.register(DailyRunServiceProtocol.self, lifetime: .singleton) { container in
            do {
                let gameCenterService = try container.resolve(GameCenterServiceProtocol.self)
                let networkService = try container.resolve(NetworkServiceProtocol.self)
                return DailyRunService(gameCenterService: gameCenterService, networkService: networkService)
            } catch {
                fatalError("Failed to resolve dependencies for DailyRunService: \(error)")
            }
        }
    }
    
    private func registerGameServices() {
        // Register ViewModels as transient (new instance each time)
        container.register(GameViewModel.self, lifetime: .transient) { container in
            do {
                let physicsService = try container.resolve(PhysicsServiceProtocol.self)
                let audioService = try container.resolve(AudioServiceProtocol.self)
                let gameCenterService = try container.resolve(GameCenterServiceProtocol.self)
                let modelContext = try container.resolve(ModelContext.self)
                
                return GameViewModel(
                    physicsService: physicsService,
                    audioService: audioService,
                    gameCenterService: gameCenterService,
                    modelContext: modelContext
                )
            } catch {
                fatalError("Failed to resolve dependencies for GameViewModel: \(error)")
            }
        }
        
        container.register(MainMenuViewModel.self, lifetime: .transient) { container in
            do {
                let gameCenterService = try container.resolve(GameCenterServiceProtocol.self)
                let audioService = try container.resolve(AudioServiceProtocol.self)
                let modelContext = try container.resolve(ModelContext.self)
                
                return MainMenuViewModel(
                    gameCenterService: gameCenterService,
                    audioService: audioService,
                    modelContext: modelContext
                )
            } catch {
                fatalError("Failed to resolve dependencies for MainMenuViewModel: \(error)")
            }
        }
        
        container.register(HangarViewModel.self, lifetime: .transient) { container in
            do {
                let audioService = try container.resolve(AudioServiceProtocol.self)
                let modelContext = try container.resolve(ModelContext.self)
                
                return HangarViewModel(
                    audioService: audioService,
                    modelContext: modelContext
                )
            } catch {
                fatalError("Failed to resolve dependencies for HangarViewModel: \(error)")
            }
        }
        
        container.register(SettingsViewModel.self, lifetime: .transient) { container in
            do {
                let audioService = try container.resolve(AudioServiceProtocol.self)
                let physicsService = try container.resolve(PhysicsServiceProtocol.self)
                let gameCenterService = try container.resolve(GameCenterServiceProtocol.self)
                let modelContext = try container.resolve(ModelContext.self)
                
                return SettingsViewModel(
                    audioService: audioService,
                    physicsService: physicsService,
                    gameCenterService: gameCenterService,
                    modelContext: modelContext
                )
            } catch {
                fatalError("Failed to resolve dependencies for SettingsViewModel: \(error)")
            }
        }
    }
    
    private func registerUIServices() {
        // Register UI-related services if needed in the future
        // Currently all UI services are handled through ViewModels
    }
}

// MARK: - Service Registration Extensions

extension ServiceRegistration {
    
    /// Register a service with custom factory
    /// - Parameters:
    ///   - protocolType: The protocol type to register
    ///   - lifetime: The service lifetime
    ///   - factory: Custom factory closure
    func register<Protocol>(
        _ protocolType: Protocol.Type,
        lifetime: ServiceLifetime = .transient,
        factory: @escaping () -> Protocol
    ) {
        container.register(protocolType, lifetime: lifetime, factory: factory)
    }
    
    /// Register a service with dependency injection factory
    /// - Parameters:
    ///   - protocolType: The protocol type to register
    ///   - lifetime: The service lifetime
    ///   - factory: Factory closure with container parameter for dependency injection
    func register<Protocol>(
        _ protocolType: Protocol.Type,
        lifetime: ServiceLifetime = .transient,
        factory: @escaping (DIContainer) -> Protocol
    ) {
        container.register(protocolType, lifetime: lifetime, factory: factory)
    }
}

// MARK: - Configuration Validation

extension ServiceRegistration {
    
    /// Validate that all required services are registered
    /// - Returns: Array of missing service names
    func validateConfiguration() -> [String] {
        var missingServices: [String] = []
        
        // Check core services
        if !container.isRegistered(ModelContext.self) {
            missingServices.append("ModelContext")
        }
        if !container.isRegistered(AudioServiceProtocol.self) {
            missingServices.append("AudioServiceProtocol")
        }
        if !container.isRegistered(PhysicsServiceProtocol.self) {
            missingServices.append("PhysicsServiceProtocol")
        }
        if !container.isRegistered(GameCenterServiceProtocol.self) {
            missingServices.append("GameCenterServiceProtocol")
        }
        if !container.isRegistered(NetworkServiceProtocol.self) {
            missingServices.append("NetworkServiceProtocol")
        }
        if !container.isRegistered(ChallengeServiceProtocol.self) {
            missingServices.append("ChallengeServiceProtocol")
        }
        if !container.isRegistered(WeeklySpecialServiceProtocol.self) {
            missingServices.append("WeeklySpecialServiceProtocol")
        }
        if !container.isRegistered(DailyRunServiceProtocol.self) {
            missingServices.append("DailyRunServiceProtocol")
        }
        
        // Check ViewModels
        if !container.isRegistered(GameViewModel.self) {
            missingServices.append("GameViewModel")
        }
        if !container.isRegistered(MainMenuViewModel.self) {
            missingServices.append("MainMenuViewModel")
        }
        if !container.isRegistered(HangarViewModel.self) {
            missingServices.append("HangarViewModel")
        }
        if !container.isRegistered(SettingsViewModel.self) {
            missingServices.append("SettingsViewModel")
        }
        
        return missingServices
    }
    
    /// Check if the dependency injection configuration is valid
    /// - Returns: True if configuration is valid, false otherwise
    func isConfigurationValid() -> Bool {
        return validateConfiguration().isEmpty
    }
}