import SwiftUI
import SpriteKit

/// SwiftUI view for game settings
struct SettingsView: View {
    // MARK: - Properties
    
    // Binding to control presentation
    @Binding var isPresented: Bool
    
    // State variables for settings
    @State private var soundVolume: Double = UserDefaults.standard.double(forKey: "soundVolume")
    @State private var musicVolume: Double = UserDefaults.standard.double(forKey: "musicVolume")
    @State private var controlSensitivity: Double = UserDefaults.standard.double(forKey: "controlSensitivity")
    @State private var showTutorialTips: Bool = UserDefaults.standard.bool(forKey: "showTutorialTips")
    @State private var useHapticFeedback: Bool = UserDefaults.standard.bool(forKey: "useHapticFeedback")
    @State private var highPerformanceMode: Bool = UserDefaults.standard.bool(forKey: "highPerformanceMode")
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            backgroundView
            settingsPanel
        }
        .onChange(of: soundVolume) { oldValue, newValue in
            UserDefaults.standard.set(newValue, forKey: "soundVolume")
            // Update audio service
            updateAudioServiceVolume(sound: Float(newValue), music: nil)
        }
        .onChange(of: musicVolume) { oldValue, newValue in
            UserDefaults.standard.set(newValue, forKey: "musicVolume")
            // Update audio service
            updateAudioServiceVolume(sound: nil, music: Float(newValue))
        }
        .onChange(of: controlSensitivity) { oldValue, newValue in
            UserDefaults.standard.set(newValue, forKey: "controlSensitivity")
            // Update physics manager
            PhysicsManager.shared.setSensitivity(CGFloat(newValue))
        }
        .onChange(of: showTutorialTips) { oldValue, newValue in
            UserDefaults.standard.set(newValue, forKey: "showTutorialTips")
        }
        .onChange(of: useHapticFeedback) { oldValue, newValue in
            UserDefaults.standard.set(newValue, forKey: "useHapticFeedback")
        }
        .onChange(of: highPerformanceMode) { oldValue, newValue in
            UserDefaults.standard.set(newValue, forKey: "highPerformanceMode")
            // Update performance settings
            updatePerformanceSettings()
        }
    }
    
    // MARK: - UI Components
    
    /// Background view with tap gesture
    private var backgroundView: some View {
        Color.black.opacity(VisualAccessibilityHelper.shared.isReduceTransparencyEnabled ? 0.9 : 0.7)
            .edgesIgnoringSafeArea(.all)
            .onTapGesture {
                // Close when tapping outside
                let animationDuration = VisualAccessibilityHelper.shared.adjustedAnimationDuration(0.3)
                withAnimation(.easeInOut(duration: animationDuration)) {
                    isPresented = false
                }
            }
    }
    
    /// Main settings panel
    private var settingsPanel: some View {
        VStack(spacing: 0) {
            header
            settingsContent
            footer
        }
        .frame(width: min(UIScreen.main.bounds.width - 40, 400), height: min(UIScreen.main.bounds.height - 80, 600))
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: DynamicTypeHelper.shared.scaledCornerRadius(20)))
        .shadow(color: .black.opacity(VisualAccessibilityHelper.shared.isReduceTransparencyEnabled ? 0.8 : 0.5), 
               radius: 20, x: 0, y: 10)
    }
    
    /// Panel background styling
    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: DynamicTypeHelper.shared.scaledCornerRadius(20))
            .fill(VisualAccessibilityHelper.shared.isHighContrastEnabled ? 
                  Color.black : Color(UIColor.systemGray6))
            .overlay(
                VisualAccessibilityHelper.shared.isHighContrastEnabled ?
                RoundedRectangle(cornerRadius: DynamicTypeHelper.shared.scaledCornerRadius(20))
                    .stroke(Color.white, lineWidth: 2) : nil
            )
    }
    
    /// Scrollable settings content
    private var settingsContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                audioSettingsSection
                gameplaySettingsSection
                performanceSettingsSection
                accessibilitySettingsSection
                aboutSettingsSection
            }
            .padding()
        }
    }
    
    /// Audio settings section
    private var audioSettingsSection: some View {
        settingsSection(title: "Audio") {
            sliderSetting(
                title: "Sound Effects",
                value: $soundVolume,
                range: 0...1,
                icon: "speaker.wave.2.fill"
            )
            
            sliderSetting(
                title: "Music",
                value: $musicVolume,
                range: 0...1,
                icon: "music.note"
            )
        }
    }
    
    /// Gameplay settings section
    private var gameplaySettingsSection: some View {
        settingsSection(title: "Gameplay") {
            sliderSetting(
                title: "Control Sensitivity",
                value: $controlSensitivity,
                range: 0.5...1.5,
                icon: "hand.tap.fill"
            )
            
            toggleSetting(
                title: "Show Tutorial Tips",
                isOn: $showTutorialTips,
                icon: "questionmark.circle.fill"
            )
            
            toggleSetting(
                title: "Haptic Feedback",
                isOn: $useHapticFeedback,
                icon: "iphone.radiowaves.left.and.right"
            )
        }
    }
    
    /// Performance settings section
    private var performanceSettingsSection: some View {
        settingsSection(title: "Performance") {
            toggleSetting(
                title: "High Performance Mode",
                isOn: $highPerformanceMode,
                icon: "bolt.fill"
            )
            .accessibilityHint("Enables higher frame rates on supported devices")
        }
    }
    
    /// Accessibility settings section
    private var accessibilitySettingsSection: some View {
        settingsSection(title: "Accessibility") {
            VStack(spacing: 16) {
                accessibilityStatusView()
                
                Button(action: {
                    testAccessibilityFeatures()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                        
                        Text("Test Accessibility Features")
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle")
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                }
                .accessibilityLabel("Test accessibility features")
                .accessibilityHint("Runs a test of all accessibility features")
            }
        }
    }
    
    /// About settings section
    private var aboutSettingsSection: some View {
        settingsSection(title: "About") {
            HStack {
                Text("Version")
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            Button(action: {
                if let url = URL(string: "https://www.example.com/privacy") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Text("Privacy Policy")
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
            }
        }
    }
    
    /// Header with title and close button
    private var header: some View {
        HStack {
            Text("Settings")
                .font(DynamicTypeHelper.shared.scaledFont(baseSize: 24, weight: .bold, design: .rounded, for: .title2))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    isPresented = false
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
            }
            .accessibilityLabel("Close settings")
            .accessibilityHint("Closes the settings menu")
            .accessibilitySortPriority(100)
        }
        .padding()
        .background(Color(UIColor.systemGray5))
    }
    
    /// Footer with reset and save buttons
    private var footer: some View {
        HStack {
            Button(action: {
                resetToDefaults()
            }) {
                Text("Reset to Defaults")
                    .font(DynamicTypeHelper.shared.scaledFont(baseSize: 16, weight: .medium, for: .body))
                    .foregroundColor(.white)
                    .padding(.vertical, DynamicTypeHelper.shared.scaledPadding(12))
                    .padding(.horizontal, DynamicTypeHelper.shared.scaledPadding(20))
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.red.opacity(0.8))
                    )
            }
            .accessibilityHint("Reset all settings to their default values")
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    isPresented = false
                }
            }) {
                Text("Save")
                    .font(DynamicTypeHelper.shared.scaledFont(baseSize: 16, weight: .bold, for: .body))
                    .foregroundColor(.white)
                    .padding(.vertical, DynamicTypeHelper.shared.scaledPadding(12))
                    .padding(.horizontal, DynamicTypeHelper.shared.scaledPadding(30))
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue)
                    )
            }
            .accessibilityHint("Save settings and close")
        }
        .padding()
        .background(Color(UIColor.systemGray5))
    }
    
    // MARK: - Helper Views
    
    /// Creates a settings section with a title and content
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(DynamicTypeHelper.shared.scaledFont(baseSize: 18, weight: .bold, design: .rounded, for: .headline))
                .foregroundColor(.white)
                .padding(.horizontal)
            
            content()
                .padding(.vertical, 5)
            
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.top, 5)
        }
    }
    
    /// Creates a slider setting with title and icon
    private func sliderSetting(title: String, value: Binding<Double>, range: ClosedRange<Double>, icon: String) -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .frame(width: 25)
                
                Text(title)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(value.wrappedValue * 100))%")
                    .foregroundColor(.gray)
            }
            
            Slider(value: value, in: range)
                .accentColor(.blue)
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(Int(value.wrappedValue * 100)) percent")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value.wrappedValue = min(range.upperBound, value.wrappedValue + 0.1)
            case .decrement:
                value.wrappedValue = max(range.lowerBound, value.wrappedValue - 0.1)
            @unknown default:
                break
            }
        }
    }
    
    /// Creates a toggle setting with title and icon
    private func toggleSetting(title: String, isOn: Binding<Bool>, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 25)
            
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            // Show on/off labels if accessibility setting is enabled
            if VisualAccessibilityHelper.shared.isOnOffSwitchLabelsEnabled {
                Text(isOn.wrappedValue ? "On" : "Off")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.trailing, 8)
            }
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .accessibilityVisualIndicators(.toggle)
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(isOn.wrappedValue ? "On" : "Off")")
        .accessibilityHint("Double tap to toggle")
    }
    
    // MARK: - Helper Methods
    
    /// Reset all settings to default values
    private func resetToDefaults() {
        soundVolume = 0.7
        musicVolume = 0.5
        controlSensitivity = 1.0
        showTutorialTips = true
        useHapticFeedback = true
        highPerformanceMode = false
        
        // Apply changes
        UserDefaults.standard.set(soundVolume, forKey: "soundVolume")
        UserDefaults.standard.set(musicVolume, forKey: "musicVolume")
        UserDefaults.standard.set(controlSensitivity, forKey: "controlSensitivity")
        UserDefaults.standard.set(showTutorialTips, forKey: "showTutorialTips")
        UserDefaults.standard.set(useHapticFeedback, forKey: "useHapticFeedback")
        UserDefaults.standard.set(highPerformanceMode, forKey: "highPerformanceMode")
        
        // Update managers
        updateAudioServiceVolume(sound: Float(soundVolume), music: Float(musicVolume))
        PhysicsManager.shared.setSensitivity(CGFloat(controlSensitivity))
        updatePerformanceSettings()
    }
    
    /// Update audio service volume settings
    private func updateAudioServiceVolume(sound: Float?, music: Float?) {
        if let audioService = try? DIContainer.shared.resolve(AudioServiceProtocol.self) {
            if let sound = sound {
                audioService.soundVolume = sound
            }
            if let music = music {
                audioService.musicVolume = music
            }
        }
    }
    
    /// Update performance settings based on high performance mode
    private func updatePerformanceSettings() {
        // Get the active window scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let view = window.rootViewController?.view as? SKView {
            if highPerformanceMode {
                view.preferredFramesPerSecond = 120 // For ProMotion displays
            } else {
                view.preferredFramesPerSecond = 60 // Standard frame rate
            }
        }
    }
    
    // MARK: - Accessibility Methods
    
    /// Display current accessibility status
    private func accessibilityStatusView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Accessibility Settings")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            VStack(spacing: 4) {
                accessibilityStatusRow("VoiceOver", isEnabled: UIAccessibility.isVoiceOverRunning)
                accessibilityStatusRow("High Contrast", isEnabled: VisualAccessibilityHelper.shared.isHighContrastEnabled)
                accessibilityStatusRow("Reduce Motion", isEnabled: VisualAccessibilityHelper.shared.isReduceMotionEnabled)
                accessibilityStatusRow("Reduce Transparency", isEnabled: VisualAccessibilityHelper.shared.isReduceTransparencyEnabled)
                accessibilityStatusRow("Button Shapes", isEnabled: VisualAccessibilityHelper.shared.isButtonShapesEnabled)
                accessibilityStatusRow("On/Off Labels", isEnabled: VisualAccessibilityHelper.shared.isOnOffSwitchLabelsEnabled)
                accessibilityStatusRow("Dynamic Type", isEnabled: DynamicTypeHelper.shared.isAccessibilitySize)
            }
            .padding(.horizontal)
        }
    }
    
    /// Create a row showing accessibility setting status
    private func accessibilityStatusRow(_ title: String, isEnabled: Bool) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isEnabled ? .green : .gray)
                .font(.caption)
        }
    }
    
    /// Test accessibility features
    private func testAccessibilityFeatures() {
        #if DEBUG
        // In debug mode, run accessibility tests
        print("Testing accessibility features...")
        
        // Test dynamic type scaling
        let testSizes = UIContentSizeCategory.allTestCases
        print("Testing \(testSizes.count) content size categories")
        
        // Test high contrast colors
        let highContrastColors = VisualAccessibilityHelper.shared.highContrastColors
        print("High contrast colors available: \(highContrastColors)")
        
        // Test reduce motion settings
        let shouldReduceMotion = VisualAccessibilityHelper.shared.isReduceMotionEnabled
        print("Reduce motion enabled: \(shouldReduceMotion)")
        
        // Announce test completion
        AccessibilityManager.shared.announceMessage("Accessibility test completed", priority: .high)
        #else
        // In release mode, just announce current settings
        let enabledFeatures = [
            UIAccessibility.isVoiceOverRunning ? "VoiceOver" : nil,
            VisualAccessibilityHelper.shared.isHighContrastEnabled ? "High Contrast" : nil,
            VisualAccessibilityHelper.shared.isReduceMotionEnabled ? "Reduce Motion" : nil,
            DynamicTypeHelper.shared.isAccessibilitySize ? "Large Text" : nil
        ].compactMap { $0 }
        
        let message = enabledFeatures.isEmpty ? 
            "No accessibility features currently enabled" :
            "Enabled features: \(enabledFeatures.joined(separator: ", "))"
        
        AccessibilityManager.shared.announceMessage(message, priority: .medium)
        #endif
    }
} 