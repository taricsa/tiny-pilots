//
//  AppDelegate.swift
//  Tiny Pilots
//
//  Created by Taric Santos de Andrade on 2025-03-01.
//

import UIKit
import SwiftData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Logger.shared.info("🚀 Starting Tiny Pilots application...", category: .app)
        
        // Step 1: Initialize core infrastructure
        initializeCoreInfrastructure()
        
        // Step 2: Check App Store compliance
        performComplianceValidation()
        
        // Step 3: Configure dependency injection
        var dependencyInjectionConfigured = false
        do {
            try configureDependencyInjection()
            dependencyInjectionConfigured = true
            Logger.shared.info("✅ Dependency injection configured successfully", category: .app)
        } catch {
            handleConfigurationError(error)
            dependencyInjectionConfigured = false
        }
        
        // Step 4: Initialize Game Center authentication
        initializeGameCenter(dependencyInjectionConfigured: dependencyInjectionConfigured)
        
        // Step 5: Perform additional startup tasks
        performAdditionalStartupTasks()
        
        // Step 6: Check if privacy disclosure is needed
        checkPrivacyDisclosureRequirement()
        
        // Step 7: Check for release notes and feature rollouts
        checkReleaseNotesAndRollouts()
        
        // Step 8: Set up the window and root view controller programmatically (no main storyboard)
        window = UIWindow(frame: UIScreen.main.bounds)
        let rootViewController = GameViewController()
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()

        Logger.shared.info("🎉 Tiny Pilots application startup completed", category: .app)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        // Track achievement progress
        if GameCenterManager.shared.isGameCenterAvailable {
            GameCenterManager.shared.trackAchievementProgress()
        }
    }
    
    // MARK: - Dependency Injection Configuration
    
    /// Configure the dependency injection container with all required services
    /// - Throws: DIError if configuration fails
    private func configureDependencyInjection() throws {
        print("🔧 Configuring dependency injection...")
        
        // Step 1: Configure service registration
        let serviceRegistration = ServiceRegistration()
        serviceRegistration.configureServices()
        
        // Step 2: Validate service registration
        let missingServices = serviceRegistration.validateConfiguration()
        if !missingServices.isEmpty {
            let errorMessage = "Missing required services: \(missingServices.joined(separator: ", "))"
            print("❌ Service registration validation failed: \(errorMessage)")
            throw DIError.serviceNotRegistered(errorMessage)
        }
        
        print("✅ Service registration validation passed")
        
        // Step 3: Configure ViewModel factory
        try configureViewModelFactory()
        
        // Step 4: Validate complete configuration
        try validateCompleteConfiguration()
        
        print("🎉 Dependency injection configuration completed successfully")
    }
    
    /// Configure the ViewModel factory and validate it
    /// - Throws: ViewModelFactoryError if configuration fails
    private func configureViewModelFactory() throws {
        print("🏭 Configuring ViewModel factory...")
        
        let factory = ViewModelFactory.shared
        
        // Validate that the factory can create all required ViewModels
        let missingViewModels = factory.validateViewModelRegistration()
        if !missingViewModels.isEmpty {
            let errorMessage = "ViewModel factory missing registrations: \(missingViewModels.joined(separator: ", "))"
            print("❌ ViewModel factory validation failed: \(errorMessage)")
            throw ViewModelFactoryError.configurationInvalid(errorMessage)
        }
        
        // Test creation of each ViewModel to ensure dependencies are properly configured
        do {
            _ = try factory.createGameViewModel()
            print("✅ GameViewModel creation test passed")
            
            _ = try factory.createMainMenuViewModel()
            print("✅ MainMenuViewModel creation test passed")
            
            _ = try factory.createHangarViewModel()
            print("✅ HangarViewModel creation test passed")
            
            _ = try factory.createSettingsViewModel()
            print("✅ SettingsViewModel creation test passed")
            
        } catch {
            print("❌ ViewModel creation test failed: \(error)")
            throw ViewModelFactoryError.creationFailed("Test ViewModels", underlying: error)
        }
        
        print("✅ ViewModel factory configuration completed")
    }
    
    /// Validate the complete dependency injection configuration
    /// - Throws: DIError if validation fails
    private func validateCompleteConfiguration() throws {
        print("🔍 Validating complete configuration...")
        
        // Validate core services
        let coreServicesProtocols: [Any.Type] = [
            AudioServiceProtocol.self,
            PhysicsServiceProtocol.self,
            GameCenterServiceProtocol.self
        ]
        
        for serviceType in coreServicesProtocols {
            if !DIContainer.shared.isRegisteredByAny(serviceType) {
                let errorMessage = "Core service not registered: \(serviceType)"
                print("❌ \(errorMessage)")
                throw DIError.serviceNotRegistered(errorMessage)
            }
        }
        
        // Validate ViewModels
        let viewModelTypes: [Any.Type] = [
            GameViewModel.self,
            MainMenuViewModel.self,
            HangarViewModel.self,
            SettingsViewModel.self
        ]
        
        for viewModelType in viewModelTypes {
            if !DIContainer.shared.isRegisteredByAny(viewModelType) {
                let errorMessage = "ViewModel not registered: \(viewModelType)"
                print("❌ \(errorMessage)")
                throw DIError.serviceNotRegistered(errorMessage)
            }
        }
        
        // Print configuration summary
        printConfigurationSummary()
        
        print("✅ Complete configuration validation passed")
    }
    
    /// Print a summary of the dependency injection configuration
    private func printConfigurationSummary() {
        print("📋 Dependency Injection Configuration Summary:")
        print("   Core Services:")
        print("     • AudioService: \(DIContainer.shared.isRegistered(AudioServiceProtocol.self) ? "✅" : "❌")")
        print("     • PhysicsService: \(DIContainer.shared.isRegistered(PhysicsServiceProtocol.self) ? "✅" : "❌")")
        print("     • GameCenterService: \(DIContainer.shared.isRegistered(GameCenterServiceProtocol.self) ? "✅" : "❌")")
        print("     • ModelContext: \(DIContainer.shared.isRegistered(ModelContext.self) ? "✅" : "❌")")
        print("   ViewModels:")
        print("     • GameViewModel: \(DIContainer.shared.isRegistered(GameViewModel.self) ? "✅" : "❌")")
        print("     • MainMenuViewModel: \(DIContainer.shared.isRegistered(MainMenuViewModel.self) ? "✅" : "❌")")
        print("     • HangarViewModel: \(DIContainer.shared.isRegistered(HangarViewModel.self) ? "✅" : "❌")")
        print("     • SettingsViewModel: \(DIContainer.shared.isRegistered(SettingsViewModel.self) ? "✅" : "❌")")
        
        let factoryStatus = ViewModelFactory.shared.getFactoryStatus()
        print("   ViewModel Factory: \(factoryStatus.isConfigured ? "✅ Configured" : "❌ Not Configured")")
    }
    
    /// Handle dependency injection configuration errors
    /// - Parameter error: The configuration error that occurred
    private func handleConfigurationError(_ error: Error) {
        print("💥 Dependency injection configuration failed: \(error)")
        
        // Log detailed error information
        if let diError = error as? DIError {
            print("   DI Error: \(diError.localizedDescription)")
        } else if let factoryError = error as? ViewModelFactoryError {
            print("   Factory Error: \(factoryError.localizedDescription)")
        } else {
            print("   Unknown Error: \(error.localizedDescription)")
        }
        
        // In a production app, you might want to:
        // 1. Show an alert to the user
        // 2. Send crash reports
        // 3. Fall back to a minimal configuration
        // 4. Attempt recovery
        
        // For now, we'll continue with a warning
        print("⚠️  Continuing with potentially incomplete configuration")
    }
    
    // MARK: - Game Center Initialization
    
    /// Initialize Game Center authentication
    /// - Parameter dependencyInjectionConfigured: Whether DI was successfully configured
    private func initializeGameCenter(dependencyInjectionConfigured: Bool) {
        print("🎮 Initializing Game Center...")
        
        if dependencyInjectionConfigured {
            // Use the new service-based approach
            if let gameCenterService = DIContainer.shared.tryResolve(GameCenterServiceProtocol.self) {
                print("✅ Using GameCenterService from DI container")
                gameCenterService.authenticate { success, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("❌ Game Center authentication failed: \(error.localizedDescription)")
                        } else if success {
                            print("✅ Game Center authentication successful")
                        } else {
                            print("⚠️  Game Center authentication completed without success")
                        }
                    }
                }
            } else {
                print("⚠️  GameCenterService not available from DI container, falling back to manager")
                fallbackToGameCenterManager()
            }
        } else {
            print("⚠️  Dependency injection not configured, using fallback Game Center manager")
            fallbackToGameCenterManager()
        }
    }
    
    /// Fallback to the old GameCenterManager when DI is not available
    private func fallbackToGameCenterManager() {
        GameCenterManager.shared.authenticatePlayer { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Game Center authentication failed (fallback): \(error.localizedDescription)")
                } else if success {
                    print("✅ Game Center authentication successful (fallback)")
                } else {
                    print("⚠️  Game Center authentication completed without success (fallback)")
                }
            }
        }
    }
    
    // MARK: - Additional Startup Tasks
    
    /// Perform additional startup tasks after core initialization
    private func performAdditionalStartupTasks() {
        print("⚙️  Performing additional startup tasks...")
        
        // Initialize SwiftData if not already done through DI
        initializeSwiftDataIfNeeded()
        
        // Set up app-wide configurations
        configureAppearance()
        
        // Register for notifications if needed
        registerForNotifications()
        
        // Perform any cleanup from previous sessions
        performSessionCleanup()
        
        print("✅ Additional startup tasks completed")
    }
    
    /// Initialize SwiftData if it wasn't properly set up through DI
    private func initializeSwiftDataIfNeeded() {
        // Check if ModelContext is available through DI
        if DIContainer.shared.tryResolve(ModelContext.self) != nil {
            print("✅ SwiftData ModelContext available through DI")
        } else {
            print("⚠️  SwiftData ModelContext not available through DI, ensuring SwiftDataManager is initialized")
            // Ensure SwiftDataManager is initialized
            _ = SwiftDataManager.shared
        }
    }
    
    /// Configure app-wide appearance settings
    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        print("✅ App appearance configured")
    }
    
    /// Register for push notifications if needed
    private func registerForNotifications() {
        // This would be where you'd register for push notifications
        // For now, we'll just log that this step was considered
        print("✅ Notification registration considered (not implemented)")
    }
    
    /// Perform cleanup from previous app sessions
    private func performSessionCleanup() {
        // Clear any temporary files or caches if needed
        // Reset any session-specific state
        Logger.shared.info("✅ Session cleanup completed", category: .app)
    }
    
    // MARK: - Core Infrastructure Initialization
    
    /// Initialize core infrastructure components
    private func initializeCoreInfrastructure() {
        Logger.shared.info("🔧 Initializing core infrastructure...", category: .app)
        
        // Initialize performance monitoring
        PerformanceMonitor.shared.trackAppLaunchTime()
        
        // Initialize analytics (respects user privacy settings)
        AnalyticsManager.shared.initialize()
        
        // Initialize crash reporting
        CrashReportingManager.shared.initialize()
        
        // Initialize accessibility manager
        AccessibilityManager.shared.initialize()
        
        Logger.shared.info("✅ Core infrastructure initialized", category: .app)
    }
    
    /// Perform App Store compliance validation
    private func performComplianceValidation() {
        Logger.shared.info("🔍 Performing compliance validation...", category: .app)
        
        let complianceResult = AppStoreComplianceManager.shared.performCompleteComplianceCheck()
        
        if complianceResult.isCompliant {
            Logger.shared.info("✅ App Store compliance validation passed", category: .app)
        } else {
            Logger.shared.warning("⚠️ App Store compliance issues found:", category: .app)
            for issue in complianceResult.allIssues {
                Logger.shared.warning("  - \(issue)", category: .app)
            }
        }
        
        // Track compliance status in analytics
        AnalyticsManager.shared.trackEvent(.complianceValidation(isCompliant: complianceResult.isCompliant))
    }
    
    /// Check if privacy disclosure needs to be shown
    private func checkPrivacyDisclosureRequirement() {
        if AppStoreComplianceManager.shared.shouldShowPrivacyPolicy() {
            Logger.shared.info("Privacy disclosure required for user", category: .app)
            // Privacy disclosure will be handled by the main view controller
            NotificationCenter.default.post(name: .privacyDisclosureRequired, object: nil)
        } else {
            Logger.shared.info("Privacy disclosure not required", category: .app)
        }
    }
    
    /// Check for release notes and initialize feature rollouts
    private func checkReleaseNotesAndRollouts() {
        Logger.shared.info("🚀 Checking release notes and feature rollouts...", category: .app)
        
        // Initialize feature flag manager
        _ = FeatureFlagManager.shared
        
        // Initialize staged rollout manager
        _ = StagedRolloutManager.shared
        
        // Check if release notes should be shown
        if ReleaseNotesManager.shared.shouldShowReleaseNotes() {
            Logger.shared.info("Release notes should be shown for current version", category: .app)
            // Delay showing release notes to allow UI to be ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                ReleaseNotesManager.shared.showReleaseNotes()
            }
        } else {
            Logger.shared.info("No release notes to show", category: .app)
        }
        
        // Log feature flag status
        let activeFlags = FeatureFlagManager.shared.getAllActiveFlags()
        Logger.shared.info("Active feature flags: \(activeFlags.keys.joined(separator: ", "))", category: .app)
        
        // Log rollout status
        let rolloutStatuses = StagedRolloutManager.shared.getAllRolloutStatuses()
        for status in rolloutStatuses {
            Logger.shared.info("Rollout status: \(status.featureKey) - \(status.statusDescription) - \(status.userStatusDescription)", category: .app)
        }
        
        Logger.shared.info("✅ Release notes and feature rollouts initialized", category: .app)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let privacyDisclosureRequired = Notification.Name("privacyDisclosureRequired")
}

