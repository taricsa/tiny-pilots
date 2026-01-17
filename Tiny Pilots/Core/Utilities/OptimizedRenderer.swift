import SpriteKit
import MetalKit

/// Optimized renderer for SpriteKit scenes with performance monitoring and adaptive quality
class OptimizedRenderer {
    
    // MARK: - Properties
    
    /// The scene being rendered
    weak var scene: SKScene?
    
    /// Current quality settings
    private var qualitySettings: QualitySettings
    

    
    /// Memory usage tracker
    private var memoryTracker = MemoryTracker()
    
    /// Render statistics
    private(set) var renderStats = RenderStatistics()
    
    /// Object pools for reusing nodes
    private var nodePool = NodePool()
    
    /// Texture cache for optimized texture loading
    private var textureCache = TextureCache()
    
    /// Whether adaptive quality is enabled
    var isAdaptiveQualityEnabled = true
    
    /// Performance monitoring delegate
    weak var performanceDelegate: OptimizedRendererDelegate?
    
    /// Simple frame counter for periodic tasks
    private var frameCounter = 0
    
    // MARK: - Initialization
    
    init(scene: SKScene) {
        self.scene = scene
        self.qualitySettings = DeviceCapabilityManager.shared.qualitySettings
        
        setupQualityObserver()
        configureScene()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupQualityObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(qualitySettingsChanged),
            name: .qualitySettingsDidChange,
            object: nil
        )
    }
    
    @objc private func qualitySettingsChanged(_ notification: Notification) {
        guard let newSettings = notification.userInfo?["newSettings"] as? QualitySettings else { return }
        updateQualitySettings(newSettings)
    }
    
    private func configureScene() {
        guard let scene = scene else { return }
        
        // Configure scene properties based on quality settings
        scene.scaleMode = .aspectFill
        
        // Set up physics world optimization
        configurePhysicsWorld(scene.physicsWorld)
        
        // Configure view properties if available
        if let view = scene.view {
            configureView(view)
        }
    }
    
    private func configurePhysicsWorld(_ physicsWorld: SKPhysicsWorld) {
        // Optimize physics world based on quality settings
        physicsWorld.speed = qualitySettings.physicsUpdateRate >= 60 ? 1.0 : 0.5
        
        // Reduce physics accuracy for better performance on lower-end devices
        if qualitySettings.targetFrameRate <= 30 {
            // Lower physics accuracy for better performance
            physicsWorld.speed = 0.8
        }
    }
    
    private func configureView(_ view: SKView) {
        // Configure view properties based on quality settings
        view.preferredFramesPerSecond = qualitySettings.targetFrameRate
        view.ignoresSiblingOrder = true // Performance optimization
        
        // Configure Metal rendering options
        if qualitySettings.enableAntialiasing {
            view.isMultipleTouchEnabled = true
        }
        
        // Debug options (only in debug builds)
        #if DEBUG
        if AppConfiguration.current.featureFlags.isDebugMenuEnabled {
            view.showsFPS = true
            view.showsNodeCount = true
            view.showsDrawCount = true
        }
        #endif
    }
    
    // MARK: - Quality Management
    
    private func updateQualitySettings(_ newSettings: QualitySettings) {
        let oldSettings = qualitySettings
        qualitySettings = newSettings
        
        Logger.shared.info("Renderer updating quality settings", category: .performance)
        
        // Update scene configuration
        configureScene()
        
        // Update texture quality
        if oldSettings.textureQuality != newSettings.textureQuality {
            textureCache.updateTextureQuality(newSettings.textureQuality)
        }
        
        // Update particle systems
        updateParticleSystemsQuality()
        
        // Notify delegate
        performanceDelegate?.rendererDidUpdateQuality(self, from: oldSettings, to: newSettings)
    }
    
    private func updateParticleSystemsQuality() {
        guard let scene = scene else { return }
        
        scene.enumerateChildNodes(withName: "//particle") { node, _ in
            if let particleNode = node as? SKEmitterNode {
                self.configureParticleNode(particleNode)
            }
        }
    }
    
    private func configureParticleNode(_ particleNode: SKEmitterNode) {
        // Adjust particle count based on quality settings
        let baseParticleCount = particleNode.numParticlesToEmit
        let adjustedCount = Int(Double(baseParticleCount) * (Double(qualitySettings.particleCount) / 100.0))
        
        particleNode.numParticlesToEmit = max(1, adjustedCount)
        
        // Adjust particle lifetime for performance
        if qualitySettings.targetFrameRate <= 30 {
            particleNode.particleLifetime *= 0.8
        }
    }
    
    // MARK: - Frame Rate Optimization
    
    func updateFrame(currentTime: TimeInterval) {
        memoryTracker.updateMemoryUsage()
        
        // Update render statistics
        updateRenderStatistics()
        
        // Check if adaptive quality adjustment is needed
        if isAdaptiveQualityEnabled {
            checkAdaptiveQualityAdjustment()
        }
        
        // Clean up unused resources periodically - use a simple frame counter
        frameCounter += 1
        if frameCounter % 300 == 0 { // Every 5 seconds at 60fps
            performResourceCleanup()
        }
    }
    
    private func updateRenderStatistics() {
        // Get FPS from PerformanceMonitor instead
        let performanceReport = PerformanceMonitor.shared.getPerformanceReport()
        renderStats.currentFPS = performanceReport.currentFrameRate
        renderStats.averageFPS = performanceReport.averageFrameRate
        renderStats.memoryUsage = memoryTracker.currentMemoryUsage
        renderStats.nodeCount = scene?.children.count ?? 0
        renderStats.lastUpdateTime = CACurrentMediaTime()
    }
    
    private func checkAdaptiveQualityAdjustment() {
        let performanceReport = PerformanceMonitor.shared.getPerformanceReport()
        let currentFPS = performanceReport.currentFrameRate
        let targetFPS = Double(qualitySettings.targetFrameRate)
        
        // If FPS is consistently below target, reduce quality
        if currentFPS < targetFPS * 0.8 && currentFPS > 0 {
            reduceQuality()
        }
        // If FPS is consistently above target and we're not at max quality, increase quality
        else if currentFPS > targetFPS * 1.1 {
            increaseQuality()
        }
    }
    
    private func reduceQuality() {
        var newSettings = qualitySettings
        
        // Reduce particle count first
        if newSettings.particleCount > 10 {
            newSettings.particleCount = max(10, newSettings.particleCount - 10)
        }
        // Then disable effects
        else if newSettings.enableBloom {
            newSettings.enableBloom = false
        }
        // Then reduce shadow quality
        else if newSettings.shadowQuality.rawValue > 0 {
            newSettings.shadowQuality = ShadowQuality(rawValue: newSettings.shadowQuality.rawValue - 1) ?? .off
        }
        // Finally reduce frame rate target
        else if newSettings.targetFrameRate > 30 {
            newSettings.targetFrameRate = 30
        }
        
        if !areEqual(newSettings, qualitySettings) {
            let performanceReport = PerformanceMonitor.shared.getPerformanceReport()
            Logger.shared.warning("Reducing quality due to low FPS: \(performanceReport.currentFrameRate)", category: .performance)
            DeviceCapabilityManager.shared.updateQualitySettings(newSettings)
        }
    }
    
    private func increaseQuality() {
        let recommendedSettings = DeviceCapabilityManager.shared.getRecommendedSettings()
        var newSettings = qualitySettings
        
        // Only increase if we're below recommended settings
        if newSettings.particleCount < recommendedSettings.particleCount {
            newSettings.particleCount = min(recommendedSettings.particleCount, newSettings.particleCount + 10)
        }
        else if !newSettings.enableBloom && recommendedSettings.enableBloom {
            newSettings.enableBloom = true
        }
        else if newSettings.shadowQuality.rawValue < recommendedSettings.shadowQuality.rawValue {
            newSettings.shadowQuality = ShadowQuality(rawValue: newSettings.shadowQuality.rawValue + 1) ?? newSettings.shadowQuality
        }
        
        if !areEqual(newSettings, qualitySettings) {
            let performanceReport = PerformanceMonitor.shared.getPerformanceReport()
            Logger.shared.info("Increasing quality due to good FPS: \(performanceReport.currentFrameRate)", category: .performance)
            DeviceCapabilityManager.shared.updateQualitySettings(newSettings)
        }
    }
    
    // MARK: - Resource Management
    
    private func performResourceCleanup() {
        // Clean up texture cache
        textureCache.cleanup()
        
        // Clean up node pool
        nodePool.cleanup()
        
        // Remove unused nodes from scene
        cleanupUnusedNodes()
        
        Logger.shared.debug("Performed resource cleanup", category: .performance)
    }
    
    private func cleanupUnusedNodes() {
        guard let scene = scene else { return }
        
        var nodesToRemove: [SKNode] = []
        
        scene.enumerateChildNodes(withName: "//*") { node, _ in
            // Remove nodes that are far off-screen
            if node.parent != nil,
               abs(node.position.x - scene.frame.midX) > scene.frame.width * 2 {
                nodesToRemove.append(node)
            }
        }
        
        for node in nodesToRemove {
            node.removeFromParent()
        }
        
        if !nodesToRemove.isEmpty {
            Logger.shared.debug("Cleaned up \(nodesToRemove.count) off-screen nodes", category: .performance)
        }
    }
    
    // MARK: - Node Creation Optimization
    
    func createOptimizedNode<T: SKNode>(type: T.Type, configure: (T) -> Void) -> T {
        // Try to get from pool first
        if let pooledNode = nodePool.getNode(type: type) {
            configure(pooledNode)
            return pooledNode
        }
        
        // Create new node if pool is empty
        let newNode = type.init()
        configure(newNode)
        return newNode
    }
    
    func recycleNode<T: SKNode>(_ node: T) {
        // Reset node state
        node.removeAllActions()
        node.removeAllChildren()
        node.position = .zero
        node.zRotation = 0
        node.alpha = 1.0
        node.isHidden = false
        
        // Return to pool
        nodePool.returnNode(node)
    }
    
    // MARK: - Texture Management
    
    func getOptimizedTexture(named name: String) -> SKTexture {
        return textureCache.getTexture(named: name, quality: qualitySettings.textureQuality)
    }
    
    func preloadTextures(_ textureNames: [String]) {
        textureCache.preloadTextures(textureNames, quality: qualitySettings.textureQuality)
    }
}

// MARK: - Supporting Classes

private func areEqual(_ lhs: QualitySettings, _ rhs: QualitySettings) -> Bool {
    return lhs.targetFrameRate == rhs.targetFrameRate &&
    lhs.particleCount == rhs.particleCount &&
    lhs.shadowQuality == rhs.shadowQuality &&
    lhs.enableBloom == rhs.enableBloom &&
    lhs.enableAntialiasing == rhs.enableAntialiasing &&
    lhs.textureQuality == rhs.textureQuality &&
    lhs.physicsUpdateRate == rhs.physicsUpdateRate &&
    lhs.maxConcurrentSounds == rhs.maxConcurrentSounds
}



class MemoryTracker {
    private(set) var currentMemoryUsage: UInt64 = 0
    
    func updateMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            currentMemoryUsage = info.resident_size
        }
    }
}

class NodePool {
    private var pools: [String: [SKNode]] = [:]
    private let maxPoolSize = 50
    
    func getNode<T: SKNode>(type: T.Type) -> T? {
        let typeName = String(describing: type)
        
        if var pool = pools[typeName], !pool.isEmpty {
            let node = pool.removeLast()
            pools[typeName] = pool
            return node as? T
        }
        
        return nil
    }
    
    func returnNode<T: SKNode>(_ node: T) {
        let typeName = String(describing: type(of: node))
        
        if pools[typeName] == nil {
            pools[typeName] = []
        }
        
        if pools[typeName]!.count < maxPoolSize {
            pools[typeName]!.append(node)
        }
    }
    
    func cleanup() {
        // Remove excess nodes from pools
        for (typeName, pool) in pools {
            if pool.count > maxPoolSize / 2 {
                pools[typeName] = Array(pool.suffix(maxPoolSize / 2))
            }
        }
    }
}

class TextureCache {
    private var cache: [String: SKTexture] = [:]
    private var lastCleanupTime: TimeInterval = 0
    
    func getTexture(named name: String, quality: QualityLevel) -> SKTexture {
        let cacheKey = "\(name)_\(quality.rawValue)"
        
        if let cachedTexture = cache[cacheKey] {
            return cachedTexture
        }
        
        let texture = loadTexture(named: name, quality: quality)
        cache[cacheKey] = texture
        return texture
    }
    
    private func loadTexture(named name: String, quality: QualityLevel) -> SKTexture {
        // Load texture with appropriate quality
        let texture = SKTexture(imageNamed: name)
        
        // Adjust filtering based on quality
        switch quality {
        case .low:
            texture.filteringMode = .nearest
        case .medium, .high, .ultra:
            texture.filteringMode = .linear
        }
        
        return texture
    }
    
    func preloadTextures(_ names: [String], quality: QualityLevel) {
        for name in names {
            _ = getTexture(named: name, quality: quality)
        }
    }
    
    func updateTextureQuality(_ newQuality: QualityLevel) {
        // Clear cache to force reload with new quality
        cache.removeAll()
    }
    
    func cleanup() {
        let currentTime = CACurrentMediaTime()
        
        // Clean up cache every 30 seconds
        if currentTime - lastCleanupTime > 30 {
            // Remove unused textures (this is a simplified approach)
            if cache.count > 100 {
                let keysToRemove = Array(cache.keys.prefix(cache.count - 50))
                for key in keysToRemove {
                    cache.removeValue(forKey: key)
                }
            }
            
            lastCleanupTime = currentTime
        }
    }
}

struct RenderStatistics {
    var currentFPS: Double = 0
    var averageFPS: Double = 0
    var memoryUsage: UInt64 = 0
    var nodeCount: Int = 0
    var lastUpdateTime: TimeInterval = 0
}

// MARK: - Delegate Protocol

protocol OptimizedRendererDelegate: AnyObject {
    func rendererDidUpdateQuality(_ renderer: OptimizedRenderer, from oldSettings: QualitySettings, to newSettings: QualitySettings)
    func rendererDetectedPerformanceIssue(_ renderer: OptimizedRenderer, issue: PerformanceIssue)
}

enum PerformanceIssue {
    case lowFrameRate(fps: Double)
    case highMemoryUsage(bytes: UInt64)
    case thermalThrottling
}