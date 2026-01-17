import Foundation
import UIKit

/// Real-time performance monitoring dashboard with alerting capabilities
class PerformanceDashboard {
    static let shared = PerformanceDashboard()
    
    // MARK: - Properties
    
    /// Whether the dashboard is currently active
    private(set) var isActive: Bool = false
    
    /// Current performance metrics
    private(set) var currentMetrics: PerformanceDashboardMetrics
    
    /// Performance alerts
    private var activeAlerts: [PerformanceAlert] = []
    
    /// Alert delegates
    private var alertDelegates: [WeakPerformanceAlertDelegate] = []
    
    /// Metrics history for trending
    private var metricsHistory: [PerformanceDashboardMetrics] = []
    private let maxHistoryCount = 300 // 5 minutes at 1 update per second
    
    /// Update timer
    private var updateTimer: Timer?
    
    /// Alert thresholds
    private let alertThresholds = PerformanceAlertThresholds()
    
    // MARK: - Initialization
    
    private init() {
        self.currentMetrics = PerformanceDashboardMetrics()
        setupPerformanceMonitoring()
    }
    
    // MARK: - Public Interface
    
    /// Start the performance dashboard
    func start() {
        guard !isActive else { return }
        
        isActive = true
        startUpdateTimer()
        
        Logger.shared.info("Performance dashboard started", category: .performance)
        
        // Notify delegates
        notifyDashboardStateChanged(active: true)
    }
    
    /// Stop the performance dashboard
    func stop() {
        guard isActive else { return }
        
        isActive = false
        stopUpdateTimer()
        
        Logger.shared.info("Performance dashboard stopped", category: .performance)
        
        // Notify delegates
        notifyDashboardStateChanged(active: false)
    }
    
    /// Add an alert delegate
    func addAlertDelegate(_ delegate: PerformanceAlertDelegate) {
        alertDelegates.append(WeakPerformanceAlertDelegate(delegate))
        cleanupDelegates()
    }
    
    /// Remove an alert delegate
    func removeAlertDelegate(_ delegate: PerformanceAlertDelegate) {
        alertDelegates.removeAll { $0.delegate === delegate }
    }
    
    /// Get current performance summary
    func getPerformanceSummary() -> PerformanceSummary {
        return PerformanceSummary(
            metrics: currentMetrics,
            alerts: activeAlerts,
            trend: getPerformanceTrend(),
            recommendations: getPerformanceRecommendations()
        )
    }
    
    /// Get performance metrics history
    func getMetricsHistory(duration: TimeInterval = 300) -> [PerformanceDashboardMetrics] {
        let cutoffTime = Date().timeIntervalSince1970 - duration
        return metricsHistory.filter { $0.timestamp >= cutoffTime }
    }
    
    /// Force a performance check
    func performImmediateCheck() {
        updateMetrics()
        checkAlerts()
    }
    
    /// Export performance data
    func exportPerformanceData() -> PerformanceExportData {
        return PerformanceExportData(
            currentMetrics: currentMetrics,
            history: metricsHistory,
            alerts: activeAlerts,
            deviceInfo: getDeviceInfo(),
            exportTimestamp: Date()
        )
    }
    
    // MARK: - Setup
    
    private func setupPerformanceMonitoring() {
        // Set up observers for system notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleThermalStateChange),
            name: ProcessInfo.thermalStateDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFrameRateChange),
            name: .frameRateDidChange,
            object: nil
        )
    }
    
    // MARK: - Update Loop
    
    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMetrics()
            self?.checkAlerts()
        }
    }
    
    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func updateMetrics() {
        let newMetrics = collectCurrentMetrics()
        currentMetrics = newMetrics
        
        // Add to history
        metricsHistory.append(newMetrics)
        
        // Trim history
        if metricsHistory.count > maxHistoryCount {
            metricsHistory.removeFirst(metricsHistory.count - maxHistoryCount)
        }
        
        // Notify delegates of metrics update
        notifyMetricsUpdated(newMetrics)
    }
    
    private func collectCurrentMetrics() -> PerformanceDashboardMetrics {
        let performanceMonitor = PerformanceMonitor.shared
        let deviceManager = DeviceCapabilityManager.shared
        _ = AdaptiveFrameRateManager.shared // Referenced for potential future use
        
        return PerformanceDashboardMetrics(
            timestamp: Date().timeIntervalSince1970,
            frameRate: performanceMonitor.getCurrentFrameRate(),
            memoryUsage: performanceMonitor.getCurrentMemoryUsage().usedMemoryMB,
            thermalState: ProcessInfo.processInfo.thermalState,
            targetFrameRate: deviceManager.qualitySettings.targetFrameRate,
            qualitySettings: deviceManager.qualitySettings,
            devicePerformanceTier: deviceManager.performanceTier,
            batteryLevel: UIDevice.current.batteryLevel,
            isLowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled
        )
    }
    
    // MARK: - Alert System
    
    private func checkAlerts() {
        var newAlerts: [PerformanceAlert] = []
        
        // Check frame rate alerts
        if currentMetrics.frameRate < alertThresholds.lowFrameRateThreshold {
            let alert = PerformanceAlert(
                type: .lowFrameRate,
                severity: getSeverity(for: currentMetrics.frameRate, threshold: alertThresholds.lowFrameRateThreshold),
                message: "Frame rate dropped to \(String(format: "%.1f", currentMetrics.frameRate)) FPS",
                timestamp: Date(),
                metrics: currentMetrics
            )
            newAlerts.append(alert)
        }
        
        // Check memory alerts
        if currentMetrics.memoryUsage > alertThresholds.highMemoryThreshold {
            let alert = PerformanceAlert(
                type: .highMemoryUsage,
                severity: getSeverity(for: currentMetrics.memoryUsage, threshold: alertThresholds.highMemoryThreshold),
                message: "Memory usage at \(String(format: "%.1f", currentMetrics.memoryUsage)) MB",
                timestamp: Date(),
                metrics: currentMetrics
            )
            newAlerts.append(alert)
        }
        
        // Check thermal alerts
        if currentMetrics.thermalState != .nominal {
            let alert = PerformanceAlert(
                type: .thermalThrottling,
                severity: getThermalSeverity(currentMetrics.thermalState),
                message: "Thermal state: \(thermalStateDescription(currentMetrics.thermalState))",
                timestamp: Date(),
                metrics: currentMetrics
            )
            newAlerts.append(alert)
        }
        
        // Check battery alerts
        if currentMetrics.isLowPowerModeEnabled {
            let alert = PerformanceAlert(
                type: .lowPowerMode,
                severity: .low,
                message: "Low Power Mode is enabled",
                timestamp: Date(),
                metrics: currentMetrics
            )
            newAlerts.append(alert)
        }
        
        // Update active alerts
        updateActiveAlerts(newAlerts)
    }
    
    private func updateActiveAlerts(_ newAlerts: [PerformanceAlert]) {
        let previousAlerts = activeAlerts
        activeAlerts = newAlerts
        
        // Find new alerts
        let newAlertTypes = Set(newAlerts.map { $0.type })
        let previousAlertTypes = Set(previousAlerts.map { $0.type })
        let addedAlertTypes = newAlertTypes.subtracting(previousAlertTypes)
        let resolvedAlertTypes = previousAlertTypes.subtracting(newAlertTypes)
        
        // Notify delegates of new alerts
        for alertType in addedAlertTypes {
            if let alert = newAlerts.first(where: { $0.type == alertType }) {
                notifyAlertTriggered(alert)
            }
        }
        
        // Notify delegates of resolved alerts
        for alertType in resolvedAlertTypes {
            notifyAlertResolved(alertType)
        }
    }
    
    // MARK: - Analysis
    
    private func getPerformanceTrend() -> PerformanceTrend {
        guard metricsHistory.count >= 60 else { return .stable } // Need at least 1 minute of data
        
        let recent = Array(metricsHistory.suffix(30)) // Last 30 seconds
        let older = Array(metricsHistory.dropLast(30).suffix(30)) // Previous 30 seconds
        
        let recentAvgFPS = recent.reduce(0) { $0 + $1.frameRate } / Double(recent.count)
        let olderAvgFPS = older.reduce(0) { $0 + $1.frameRate } / Double(older.count)
        
        let change = (recentAvgFPS - olderAvgFPS) / olderAvgFPS
        
        if change > 0.1 {
            return .improving
        } else if change < -0.1 {
            return .degrading
        } else {
            return .stable
        }
    }
    
    private func getPerformanceRecommendations() -> [PerformanceRecommendation] {
        var recommendations: [PerformanceRecommendation] = []
        
        // Frame rate recommendations
        if currentMetrics.frameRate < Double(currentMetrics.targetFrameRate) * 0.8 {
            recommendations.append(.reduceParticleEffects)
            recommendations.append(.lowerRenderQuality)
        }
        
        // Memory recommendations
        if currentMetrics.memoryUsage > 150.0 {
            recommendations.append(.clearTextureCache)
            recommendations.append(.reduceNodeCount)
        }
        
        // Thermal recommendations
        if currentMetrics.thermalState != .nominal {
            recommendations.append(.reduceFrameRate)
            recommendations.append(.disableNonEssentialEffects)
        }
        
        // Battery recommendations
        if currentMetrics.isLowPowerModeEnabled {
            recommendations.append(.enablePowerSavingMode)
        }
        
        return recommendations
    }
    
    // MARK: - Helper Methods
    
    private func getSeverity(for value: Double, threshold: Double) -> AlertSeverity {
        let ratio = value / threshold
        
        if ratio >= 2.0 {
            return .critical
        } else if ratio >= 1.5 {
            return .high
        } else if ratio >= 1.2 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func getThermalSeverity(_ state: ProcessInfo.ThermalState) -> AlertSeverity {
        switch state {
        case .nominal:
            return .low
        case .fair:
            return .medium
        case .serious:
            return .high
        case .critical:
            return .critical
        @unknown default:
            return .medium
        }
    }
    
    private func thermalStateDescription(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "Normal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }
    
    private func getDeviceInfo() -> DeviceInfo {
        return DeviceInfo.current
    }
    
    // MARK: - Delegate Management
    
    private func cleanupDelegates() {
        alertDelegates.removeAll { $0.delegate == nil }
    }
    
    private func notifyDashboardStateChanged(active: Bool) {
        cleanupDelegates()
        alertDelegates.forEach { $0.delegate?.performanceDashboardStateChanged(active: active) }
    }
    
    private func notifyMetricsUpdated(_ metrics: PerformanceDashboardMetrics) {
        cleanupDelegates()
        alertDelegates.forEach { $0.delegate?.performanceMetricsUpdated(metrics) }
    }
    
    private func notifyAlertTriggered(_ alert: PerformanceAlert) {
        Logger.shared.warning("Performance alert: \(alert.message)", category: .performance)
        
        cleanupDelegates()
        alertDelegates.forEach { $0.delegate?.performanceAlertTriggered(alert) }
        
        // Track in analytics
        AnalyticsManager.shared.trackEvent(.performanceAlert(
            type: alert.type.rawValue,
            severity: alert.severity.rawValue,
            message: alert.message
        ))
    }
    
    private func notifyAlertResolved(_ alertType: PerformanceAlertType) {
        Logger.shared.info("Performance alert resolved: \(alertType.rawValue)", category: .performance)
        
        cleanupDelegates()
        alertDelegates.forEach { $0.delegate?.performanceAlertResolved(alertType) }
    }
    
    // MARK: - Notification Handlers
    
    @objc private func handleMemoryWarning() {
        Logger.shared.warning("Memory warning received", category: .performance)
        performImmediateCheck()
    }
    
    @objc private func handleThermalStateChange() {
        Logger.shared.info("Thermal state changed", category: .performance)
        performImmediateCheck()
    }
    
    @objc private func handleFrameRateChange(_ notification: Notification) {
        Logger.shared.info("Frame rate changed", category: .performance)
        performImmediateCheck()
    }
    
    deinit {
        stop()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Supporting Types

struct PerformanceDashboardMetrics {
    let timestamp: TimeInterval
    let frameRate: Double
    let memoryUsage: Double
    let thermalState: ProcessInfo.ThermalState
    let targetFrameRate: Int
    let qualitySettings: QualitySettings
    let devicePerformanceTier: PerformanceTier
    let batteryLevel: Float
    let isLowPowerModeEnabled: Bool
    
    init() {
        self.timestamp = Date().timeIntervalSince1970
        self.frameRate = 0
        self.memoryUsage = 0
        self.thermalState = .nominal
        self.targetFrameRate = 60
        self.qualitySettings = QualitySettings.recommended(for: .medium)
        self.devicePerformanceTier = .medium
        self.batteryLevel = UIDevice.current.batteryLevel
        self.isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    init(
        timestamp: TimeInterval,
        frameRate: Double,
        memoryUsage: Double,
        thermalState: ProcessInfo.ThermalState,
        targetFrameRate: Int,
        qualitySettings: QualitySettings,
        devicePerformanceTier: PerformanceTier,
        batteryLevel: Float,
        isLowPowerModeEnabled: Bool
    ) {
        self.timestamp = timestamp
        self.frameRate = frameRate
        self.memoryUsage = memoryUsage
        self.thermalState = thermalState
        self.targetFrameRate = targetFrameRate
        self.qualitySettings = qualitySettings
        self.devicePerformanceTier = devicePerformanceTier
        self.batteryLevel = batteryLevel
        self.isLowPowerModeEnabled = isLowPowerModeEnabled
    }
}

struct PerformanceAlert {
    let type: PerformanceAlertType
    let severity: AlertSeverity
    let message: String
    let timestamp: Date
    let metrics: PerformanceDashboardMetrics
}

enum PerformanceAlertType: String, CaseIterable, Codable {
    case lowFrameRate = "low_frame_rate"
    case highMemoryUsage = "high_memory_usage"
    case thermalThrottling = "thermal_throttling"
    case lowPowerMode = "low_power_mode"
}

enum AlertSeverity: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

struct PerformanceSummary {
    let metrics: PerformanceDashboardMetrics
    let alerts: [PerformanceAlert]
    let trend: PerformanceTrend
    let recommendations: [PerformanceRecommendation]
}

struct PerformanceExportData: Codable {
    let currentMetrics: PerformanceDashboardMetrics
    let history: [PerformanceDashboardMetrics]
    let alerts: [PerformanceAlert]
    let deviceInfo: DeviceInfo
    let exportTimestamp: Date
}

struct PerformanceAlertThresholds {
    let lowFrameRateThreshold: Double = 45.0
    let highMemoryThreshold: Double = 200.0 // MB
    let criticalMemoryThreshold: Double = 300.0 // MB
}

class WeakPerformanceAlertDelegate {
    weak var delegate: PerformanceAlertDelegate?
    
    init(_ delegate: PerformanceAlertDelegate) {
        self.delegate = delegate
    }
}

// MARK: - Delegate Protocol

protocol PerformanceAlertDelegate: AnyObject {
    func performanceDashboardStateChanged(active: Bool)
    func performanceMetricsUpdated(_ metrics: PerformanceDashboardMetrics)
    func performanceAlertTriggered(_ alert: PerformanceAlert)
    func performanceAlertResolved(_ alertType: PerformanceAlertType)
}

// MARK: - Extensions for Codable Support

extension PerformanceDashboardMetrics: Codable {
    enum CodingKeys: String, CodingKey {
        case timestamp, frameRate, memoryUsage, thermalState, targetFrameRate
        case qualitySettings, devicePerformanceTier, batteryLevel, isLowPowerModeEnabled
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(TimeInterval.self, forKey: .timestamp)
        frameRate = try container.decode(Double.self, forKey: .frameRate)
        memoryUsage = try container.decode(Double.self, forKey: .memoryUsage)
        
        let thermalStateRaw = try container.decode(Int.self, forKey: .thermalState)
        thermalState = ProcessInfo.ThermalState(rawValue: thermalStateRaw) ?? .nominal
        
        targetFrameRate = try container.decode(Int.self, forKey: .targetFrameRate)
        qualitySettings = try container.decode(QualitySettings.self, forKey: .qualitySettings)
        devicePerformanceTier = try container.decode(PerformanceTier.self, forKey: .devicePerformanceTier)
        batteryLevel = try container.decode(Float.self, forKey: .batteryLevel)
        isLowPowerModeEnabled = try container.decode(Bool.self, forKey: .isLowPowerModeEnabled)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(frameRate, forKey: .frameRate)
        try container.encode(memoryUsage, forKey: .memoryUsage)
        try container.encode(thermalState.rawValue, forKey: .thermalState)
        try container.encode(targetFrameRate, forKey: .targetFrameRate)
        try container.encode(qualitySettings, forKey: .qualitySettings)
        try container.encode(devicePerformanceTier, forKey: .devicePerformanceTier)
        try container.encode(batteryLevel, forKey: .batteryLevel)
        try container.encode(isLowPowerModeEnabled, forKey: .isLowPowerModeEnabled)
    }
}

extension PerformanceAlert: Codable {
    enum CodingKeys: String, CodingKey {
        case type, severity, message, timestamp, metrics
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(PerformanceAlertType.self, forKey: .type)
        severity = try container.decode(AlertSeverity.self, forKey: .severity)
        message = try container.decode(String.self, forKey: .message)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        metrics = try container.decode(PerformanceDashboardMetrics.self, forKey: .metrics)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(severity, forKey: .severity)
        try container.encode(message, forKey: .message)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(metrics, forKey: .metrics)
    }
}

// MARK: - Additional Performance Recommendations

extension PerformanceRecommendation {
    static let enablePowerSavingMode = PerformanceRecommendation(rawValue: "Enable power saving mode") ?? .reduceFrameRate
}

// MARK: - Analytics Extension

extension AnalyticsEvent {
    static func performanceAlert(type: String, severity: String, message: String) -> AnalyticsEvent {
        return .errorOccurred(category: "performance", message: "alert_\(type)_\(severity): \(message)", isFatal: false)
    }
}