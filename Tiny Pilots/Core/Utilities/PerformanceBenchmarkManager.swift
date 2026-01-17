import Foundation
import SpriteKit

/// Manages performance benchmarking and regression detection
class PerformanceBenchmarkManager {
    static let shared = PerformanceBenchmarkManager()
    
    // MARK: - Properties
    
    /// Benchmark results storage
    private var benchmarkResults: [BenchmarkResult] = []
    
    /// Historical performance data for regression detection
    private var historicalData: PerformanceHistory?
    
    /// Current benchmark session
    private var currentSession: BenchmarkSession?
    
    /// Benchmark configuration
    private var configuration: BenchmarkConfiguration
    
    /// Performance thresholds for regression detection
    private let regressionThresholds = RegressionThresholds()
    
    // MARK: - Initialization
    
    private init() {
        self.configuration = BenchmarkConfiguration.default
        loadHistoricalData()
    }
    
    // MARK: - Public Interface
    
    /// Configure benchmarking system
    func configure(with configuration: BenchmarkConfiguration) {
        self.configuration = configuration
        Logger.shared.info("Performance benchmarking configured", category: .performance)
    }
    
    /// Start a new benchmark session
    func startBenchmarkSession(name: String, category: BenchmarkCategory) -> BenchmarkSession {
        let session = BenchmarkSession(name: name, category: category)
        currentSession = session
        
        Logger.shared.info("Started benchmark session: \(name)", category: .performance)
        return session
    }
    
    /// Complete the current benchmark session
    func completeBenchmarkSession() -> BenchmarkResult? {
        guard let session = currentSession else {
            Logger.shared.warning("No active benchmark session to complete", category: .performance)
            return nil
        }
        
        let result = session.complete()
        benchmarkResults.append(result)
        currentSession = nil
        
        // Check for performance regression
        checkForRegression(result)
        
        Logger.shared.info("Completed benchmark: \(result.name) - \(result.summary)", category: .performance)
        return result
    }
    
    /// Run a complete performance benchmark suite
    func runBenchmarkSuite() -> BenchmarkSuiteResult {
        Logger.shared.info("Starting performance benchmark suite", category: .performance)
        
        let suiteStartTime = CFAbsoluteTimeGetCurrent()
        var results: [BenchmarkResult] = []
        
        // Frame rate benchmarks
        results.append(runFrameRateBenchmark())
        results.append(runFrameRateWithLoadBenchmark())
        
        // Memory benchmarks
        results.append(runMemoryUsageBenchmark())
        results.append(runMemoryLeakBenchmark())
        
        // Scene transition benchmarks
        results.append(runSceneTransitionBenchmark())
        
        // Physics benchmarks
        results.append(runPhysicsBenchmark())
        
        // Rendering benchmarks
        results.append(runRenderingBenchmark())
        
        let suiteDuration = CFAbsoluteTimeGetCurrent() - suiteStartTime
        let suiteResult = BenchmarkSuiteResult(
            results: results,
            duration: suiteDuration,
            timestamp: Date(),
            deviceInfo: getDeviceInfo(),
            regressionDetected: results.contains { $0.regressionDetected }
        )
        
        // Save results
        saveBenchmarkResults(suiteResult)
        
        Logger.shared.info("Benchmark suite completed in \(String(format: "%.2f", suiteDuration))s", category: .performance)
        return suiteResult
    }
    
    // MARK: - Individual Benchmarks
    
    private func runFrameRateBenchmark() -> BenchmarkResult {
        let session = startBenchmarkSession(name: "Frame Rate Baseline", category: .frameRate)
        
        // Simulate 60 frames at target FPS
        let targetFPS = Double(DeviceCapabilityManager.shared.qualitySettings.targetFrameRate)
        let frameInterval = 1.0 / targetFPS
        var currentTime: TimeInterval = 0
        
        let frameRateTracker = FrameRateTracker()
        
        for _ in 0..<Int(targetFPS * 2) { // 2 seconds of frames
            currentTime += frameInterval
            frameRateTracker.recordFrame(currentTime)
        }
        
        session.recordMetric("average_fps", value: frameRateTracker.averageFPS)
        session.recordMetric("current_fps", value: frameRateTracker.currentFPS)
        session.recordMetric("frame_stability", value: frameRateTracker.isStable ? 1.0 : 0.0)
        
        return session.complete()
    }
    
    private func runFrameRateWithLoadBenchmark() -> BenchmarkResult {
        let session = startBenchmarkSession(name: "Frame Rate Under Load", category: .frameRate)
        
        // Create a test scene with load
        let testScene = createTestScene()
        addLoadToScene(testScene, nodeCount: 1000, particleCount: 10)
        
        // Simulate frame updates
        let frameRateTracker = FrameRateTracker()
        let targetFPS = Double(DeviceCapabilityManager.shared.qualitySettings.targetFrameRate)
        let frameInterval = 1.0 / targetFPS
        var currentTime: TimeInterval = 0
        
        for _ in 0..<Int(targetFPS * 3) { // 3 seconds under load
            currentTime += frameInterval
            frameRateTracker.recordFrame(currentTime)
            testScene.update(currentTime)
        }
        
        session.recordMetric("average_fps_under_load", value: frameRateTracker.averageFPS)
        session.recordMetric("fps_drop_percentage", value: max(0, (targetFPS - frameRateTracker.averageFPS) / targetFPS * 100))
        
        return session.complete()
    }
    
    private func runMemoryUsageBenchmark() -> BenchmarkResult {
        let session = startBenchmarkSession(name: "Memory Usage", category: .memory)
        
        let initialMemory = getMemoryUsage()
        session.recordMetric("initial_memory_mb", value: Double(initialMemory) / 1024.0 / 1024.0)
        
        // Create memory load
        var nodes: [SKNode] = []
        for i in 0..<5000 {
            let node = SKSpriteNode(color: .red, size: CGSize(width: 10, height: 10))
            node.position = CGPoint(x: i % 100 * 10, y: i / 100 * 10)
            nodes.append(node)
        }
        
        let peakMemory = getMemoryUsage()
        session.recordMetric("peak_memory_mb", value: Double(peakMemory) / 1024.0 / 1024.0)
        
        // Clean up
        nodes.removeAll()
        
        let finalMemory = getMemoryUsage()
        session.recordMetric("final_memory_mb", value: Double(finalMemory) / 1024.0 / 1024.0)
        session.recordMetric("memory_cleanup_efficiency", value: Double(peakMemory - finalMemory) / Double(peakMemory - initialMemory))
        
        return session.complete()
    }
    
    private func runMemoryLeakBenchmark() -> BenchmarkResult {
        let session = startBenchmarkSession(name: "Memory Leak Detection", category: .memory)
        
        let initialMemory = getMemoryUsage()
        
        // Perform multiple allocation/deallocation cycles
        for cycle in 0..<20 {
            var tempNodes: [SKNode] = []
            
            for i in 0..<100 {
                let node = SKSpriteNode(color: .blue, size: CGSize(width: 5, height: 5))
                node.position = CGPoint(x: i * 5, y: cycle * 5)
                tempNodes.append(node)
            }
            
            // Clean up
            tempNodes.removeAll()
        }
        
        let finalMemory = getMemoryUsage()
        let memoryGrowth = Double(finalMemory - initialMemory) / 1024.0 / 1024.0
        
        session.recordMetric("memory_growth_mb", value: memoryGrowth)
        session.recordMetric("leak_detected", value: memoryGrowth > 5.0 ? 1.0 : 0.0)
        
        return session.complete()
    }
    
    private func runSceneTransitionBenchmark() -> BenchmarkResult {
        let session = startBenchmarkSession(name: "Scene Transition", category: .sceneTransition)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Simulate scene transition work
        let testScene = createTestScene()
        addLoadToScene(testScene, nodeCount: 500, particleCount: 5)
        
        let transitionDuration = CFAbsoluteTimeGetCurrent() - startTime
        
        session.recordMetric("transition_duration_ms", value: transitionDuration * 1000)
        session.recordMetric("meets_target", value: transitionDuration < 2.0 ? 1.0 : 0.0)
        
        return session.complete()
    }
    
    private func runPhysicsBenchmark() -> BenchmarkResult {
        let session = startBenchmarkSession(name: "Physics Performance", category: .physics)
        
        let testScene = createTestScene()
        
        // Add physics bodies
        for i in 0..<100 {
            let node = SKSpriteNode(color: .yellow, size: CGSize(width: 20, height: 20))
            node.position = CGPoint(x: CGFloat(i * 20), y: 400)
            node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
            node.physicsBody?.isDynamic = true
            testScene.addChild(node)
        }
        
        // Simulate physics updates
        let frameRateTracker = FrameRateTracker()
        let targetFPS = Double(DeviceCapabilityManager.shared.qualitySettings.targetFrameRate)
        let frameInterval = 1.0 / targetFPS
        var currentTime: TimeInterval = 0
        
        for _ in 0..<Int(targetFPS * 2) { // 2 seconds of physics
            currentTime += frameInterval
            frameRateTracker.recordFrame(currentTime)
            testScene.update(currentTime)
        }
        
        session.recordMetric("physics_fps", value: frameRateTracker.averageFPS)
        session.recordMetric("physics_performance_ratio", value: frameRateTracker.averageFPS / targetFPS)
        
        return session.complete()
    }
    
    private func runRenderingBenchmark() -> BenchmarkResult {
        let session = startBenchmarkSession(name: "Rendering Performance", category: .rendering)
        
        let testScene = createTestScene()
        
        // Add many visual elements
        for i in 0..<2000 {
            let node = SKSpriteNode(color: .green, size: CGSize(width: 8, height: 8))
            node.position = CGPoint(x: CGFloat(i % 200 * 8), y: CGFloat(i / 200 * 8))
            testScene.addChild(node)
        }
        
        // Add particle systems
        for i in 0..<5 {
            let particles = SKEmitterNode()
            particles.particleTexture = SKTexture(imageNamed: "spark")
            particles.numParticlesToEmit = 50
            particles.particleLifetime = 1.0
            particles.position = CGPoint(x: i * 200, y: 300)
            testScene.addChild(particles)
        }
        
        // Measure rendering performance
        let frameRateTracker = FrameRateTracker()
        let targetFPS = Double(DeviceCapabilityManager.shared.qualitySettings.targetFrameRate)
        let frameInterval = 1.0 / targetFPS
        var currentTime: TimeInterval = 0
        
        for _ in 0..<Int(targetFPS * 2) { // 2 seconds of rendering
            currentTime += frameInterval
            frameRateTracker.recordFrame(currentTime)
            testScene.update(currentTime)
        }
        
        session.recordMetric("rendering_fps", value: frameRateTracker.averageFPS)
        session.recordMetric("node_count", value: Double(testScene.children.count))
        session.recordMetric("fps_per_node", value: frameRateTracker.averageFPS / Double(testScene.children.count) * 1000)
        
        return session.complete()
    }
    
    // MARK: - Regression Detection
    
    private func checkForRegression(_ result: BenchmarkResult) {
        guard let historical = historicalData else {
            Logger.shared.info("No historical data for regression comparison", category: .performance)
            return
        }
        
        guard let baseline = historical.getBaseline(for: result.name, category: result.category) else {
            Logger.shared.info("No baseline found for \(result.name)", category: .performance)
            return
        }
        
        var regressionDetected = false
        var regressionDetails: [String] = []
        
        // Check each metric against thresholds
        for (metricName, currentValue) in result.metrics {
            if let baselineValue = baseline.metrics[metricName] {
                let changePercentage = abs(currentValue - baselineValue) / baselineValue * 100
                
                let threshold = regressionThresholds.getThreshold(for: metricName, category: result.category)
                
                if changePercentage > threshold {
                    regressionDetected = true
                    regressionDetails.append("\(metricName): \(String(format: "%.1f", changePercentage))% change")
                }
            }
        }
        
        if regressionDetected {
            var updated = result
            updated.regressionDetected = true
            updated.regressionDetails = regressionDetails
            
            Logger.shared.warning("Performance regression detected in \(result.name): \(regressionDetails.joined(separator: ", "))", category: .performance)
            
            // Track in analytics
            AnalyticsManager.shared.trackEvent(.errorOccurred(category: "performance", message: "regression_\(result.name): \(regressionDetails.joined(separator: ", "))", isFatal: false))
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestScene() -> SKScene {
        let scene = SKScene(size: CGSize(width: 1024, height: 768))
        scene.scaleMode = .aspectFill
        return scene
    }
    
    private func addLoadToScene(_ scene: SKScene, nodeCount: Int, particleCount: Int) {
        // Add nodes
        for i in 0..<nodeCount {
            let node = SKSpriteNode(color: .red, size: CGSize(width: 10, height: 10))
            node.position = CGPoint(x: i % 100 * 10, y: i / 100 * 10)
            scene.addChild(node)
        }
        
        // Add particle systems
        for i in 0..<particleCount {
            let particles = SKEmitterNode()
            particles.particleTexture = SKTexture(imageNamed: "spark")
            particles.numParticlesToEmit = 20
            particles.particleLifetime = 1.0
            particles.position = CGPoint(x: i * 100, y: 300)
            scene.addChild(particles)
        }
    }
    
    private func getMemoryUsage() -> UInt64 {
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
        
        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }
    
    private func getDeviceInfo() -> DeviceInfo {
        return DeviceInfo.current
    }
    
    // MARK: - Data Persistence
    
    private func loadHistoricalData() {
        // In a real implementation, this would load from persistent storage
        // For now, we'll create empty historical data
        historicalData = PerformanceHistory()
    }
    
    private func saveBenchmarkResults(_ suiteResult: BenchmarkSuiteResult) {
        // Update historical data
        historicalData?.addResults(suiteResult)
        
        // In a real implementation, this would save to persistent storage
        Logger.shared.info("Benchmark results saved", category: .performance)
    }
}

// MARK: - Supporting Types

enum BenchmarkCategory: String, CaseIterable {
    case frameRate = "frame_rate"
    case memory = "memory"
    case sceneTransition = "scene_transition"
    case physics = "physics"
    case rendering = "rendering"
}

class BenchmarkSession {
    let name: String
    let category: BenchmarkCategory
    let startTime: CFAbsoluteTime
    private var metrics: [String: Double] = [:]
    
    init(name: String, category: BenchmarkCategory) {
        self.name = name
        self.category = category
        self.startTime = CFAbsoluteTimeGetCurrent()
    }
    
    func recordMetric(_ name: String, value: Double) {
        metrics[name] = value
    }
    
    func complete() -> BenchmarkResult {
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        return BenchmarkResult(
            name: name,
            category: category,
            duration: duration,
            metrics: metrics,
            timestamp: Date(),
            deviceInfo: DeviceCapabilityManager.shared.deviceModel.rawValue
        )
    }
}

struct BenchmarkResult {
    let name: String
    let category: BenchmarkCategory
    let duration: TimeInterval
    let metrics: [String: Double]
    let timestamp: Date
    let deviceInfo: String
    var regressionDetected: Bool = false
    var regressionDetails: [String] = []
    
    var summary: String {
        let metricsString = metrics.map { "\($0.key): \(String(format: "%.2f", $0.value))" }.joined(separator: ", ")
        return "Duration: \(String(format: "%.3f", duration))s, Metrics: \(metricsString)"
    }
}

struct BenchmarkSuiteResult {
    let results: [BenchmarkResult]
    let duration: TimeInterval
    let timestamp: Date
    let deviceInfo: DeviceInfo
    let regressionDetected: Bool
    
    var summary: String {
        let passedCount = results.filter { !$0.regressionDetected }.count
        let totalCount = results.count
        return "Benchmarks: \(passedCount)/\(totalCount) passed, Duration: \(String(format: "%.2f", duration))s"
    }
}

struct BenchmarkConfiguration {
    let enableRegressionDetection: Bool
    let saveResults: Bool
    let detailedLogging: Bool
    
    static let `default` = BenchmarkConfiguration(
        enableRegressionDetection: true,
        saveResults: true,
        detailedLogging: false
    )
}

class PerformanceHistory {
    private var baselines: [String: BenchmarkResult] = [:]
    
    func addResults(_ suiteResult: BenchmarkSuiteResult) {
        for result in suiteResult.results {
            let key = "\(result.category.rawValue)_\(result.name)"
            
            // Update baseline if this is better performance or first result
            if let existing = baselines[key] {
                // Simple heuristic: if average of key metrics is better, update baseline
                if isPerformanceBetter(result, than: existing) {
                    baselines[key] = result
                }
            } else {
                baselines[key] = result
            }
        }
    }
    
    func getBaseline(for name: String, category: BenchmarkCategory) -> BenchmarkResult? {
        let key = "\(category.rawValue)_\(name)"
        return baselines[key]
    }
    
    private func isPerformanceBetter(_ new: BenchmarkResult, than existing: BenchmarkResult) -> Bool {
        // Simple comparison - in a real implementation this would be more sophisticated
        return new.duration < existing.duration
    }
}

struct RegressionThresholds {
    private let thresholds: [String: Double] = [
        "average_fps": 10.0,           // 10% FPS drop is significant
        "memory_growth_mb": 20.0,      // 20% memory growth is concerning
        "transition_duration_ms": 15.0, // 15% slower transitions
        "physics_fps": 10.0,           // 10% physics performance drop
        "rendering_fps": 10.0          // 10% rendering performance drop
    ]
    
    func getThreshold(for metric: String, category: BenchmarkCategory) -> Double {
        return thresholds[metric] ?? 25.0 // Default 25% threshold
    }
}

// MARK: - Analytics Extension

extension AnalyticsEvent {
    static func performanceRegression(benchmark: String, details: String) -> AnalyticsEvent {
        return .errorOccurred(category: "performance", message: "regression_\(benchmark): \(details)", isFatal: false)
    }
}