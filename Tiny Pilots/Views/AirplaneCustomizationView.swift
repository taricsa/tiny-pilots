import SwiftUI

/// SwiftUI view for customizing paper airplanes
struct AirplaneCustomizationView: View {
    // MARK: - Properties
    
    // Environment object to access game state
    @EnvironmentObject var gameState: GameStateManager
    
    // Environment to dismiss the view
    @SwiftUI.Environment(\.dismiss) private var dismiss: DismissAction
    
    // State variables
    @State private var selectedDesign: AirplaneDesign
    @State private var selectedColor: AirplaneColor
    @State private var selectedFold: FoldType
    @State private var selectedPattern: PatternType
    @State private var isPreviewMode = false
    @State private var previewRotation: Double = 0
    @State private var showUnlockAlert = false
    @State private var itemToUnlock: String = ""
    @State private var unlockCost: Int = 0
    @State private var showConfetti = false
    
    // Animation states
    @State private var animateDesigns = false
    @State private var animateColors = false
    @State private var animateFolds = false
    @State private var animatePatterns = false
    
    // Available customization options
    private let availableDesigns: [AirplaneDesign]
    private let availableColors: [AirplaneColor]
    private let availableFolds: [FoldType]
    private let availablePatterns: [PatternType]
    
    // MARK: - Initialization
    
    init() {
        // Load the player's current airplane configuration
        let playerData = UserDefaults.standard
        
        // Get saved values or use defaults
        let designString = playerData.string(forKey: "selectedAirplaneDesign") ?? "classic"
        let colorString = playerData.string(forKey: "selectedAirplaneColor") ?? "white"
        let foldString = playerData.string(forKey: "selectedFoldType") ?? "standard"
        let patternString = playerData.string(forKey: "selectedPatternType") ?? "none"
        
        // Initialize state variables
        _selectedDesign = State(initialValue: AirplaneDesign(rawValue: designString) ?? .classic)
        _selectedColor = State(initialValue: AirplaneColor(rawValue: colorString) ?? .white)
        _selectedFold = State(initialValue: FoldType(rawValue: foldString) ?? .standard)
        _selectedPattern = State(initialValue: PatternType(rawValue: patternString) ?? .none)
        
        // Set available options (in a real app, these would be filtered based on player progression)
        availableDesigns = AirplaneDesign.allCases
        availableColors = AirplaneColor.allCases
        availableFolds = FoldType.allCases
        availablePatterns = PatternType.allCases
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Preview area
                ZStack {
                    // Background for preview area
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .padding(.horizontal)
                    
                    // Airplane preview
                    VStack {
                        if isPreviewMode {
                            // 3D preview mode
                            Text("3D Preview")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.top, 10)
                            
                            // 3D airplane image would go here
                            Image(airplanePreviewImageName)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .rotation3DEffect(
                                    .degrees(previewRotation),
                                    axis: (x: 0, y: 1, z: 0)
                                )
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            let dragAmount = value.translation.width
                                            previewRotation = Double(dragAmount) / 2
                                        }
                                        .onEnded { _ in
                                            withAnimation(.spring()) {
                                                previewRotation = 0
                                            }
                                        }
                                )
                                .accessibilityHint("Drag horizontally to rotate the airplane preview")
                        } else {
                            // Standard preview
                            Image(airplanePreviewImageName)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                        }
                        
                        // Preview mode toggle
                        Button(action: {
                            withAnimation {
                                isPreviewMode.toggle()
                            }
                        }) {
                            Text(isPreviewMode ? "Standard View" : "3D Preview")
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.opacity(0.2))
                                )
                                .foregroundColor(.blue)
                        }
                        .padding(.bottom, 10)
                        .accessibilityHint("Toggle between standard and 3D preview modes")
                    }
                    .padding()
                    
                    // Confetti overlay
                    if showConfetti {
                        ConfettiView()
                            .allowsHitTesting(false)
                    }
                }
                .frame(height: 220)
                .padding(.bottom, 10)
                
                // Customization options
                ScrollView {
                    VStack(spacing: 20) {
                        // Airplane design section
                        CustomizationSection(
                            title: "Airplane Design",
                            isAnimated: $animateDesigns,
                            content: {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(availableDesigns, id: \.rawValue) { design in
                                            CustomizationOption(
                                                isSelected: design == selectedDesign,
                                                isLocked: !isDesignUnlocked(design),
                                                image: "airplane_design_\(design.rawValue)",
                                                title: design.displayName,
                                                onSelect: {
                                                    if isDesignUnlocked(design) {
                                                        withAnimation {
                                                            selectedDesign = design
                                                        }
                                                    } else {
                                                        showUnlockPrompt(for: design.displayName, cost: design.unlockCost)
                                                    }
                                                }
                                            )
                                            .accessibilityHint("Select the \(design.displayName) airplane design")
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        )
                        
                        // Color section
                        CustomizationSection(
                            title: "Paper Color",
                            isAnimated: $animateColors,
                            content: {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(availableColors, id: \.rawValue) { color in
                                            ColorOption(
                                                color: color.uiColor,
                                                isSelected: color == selectedColor,
                                                isLocked: !isColorUnlocked(color),
                                                onSelect: {
                                                    if isColorUnlocked(color) {
                                                        withAnimation {
                                                            selectedColor = color
                                                        }
                                                    } else {
                                                        showUnlockPrompt(for: color.displayName, cost: color.unlockCost)
                                                    }
                                                }
                                            )
                                            .accessibilityLabel("\(color.displayName) paper color")
                                            .accessibilityHint("Select the \(color.displayName) paper color")
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        )
                        
                        // Fold type section
                        CustomizationSection(
                            title: "Fold Type",
                            isAnimated: $animateFolds,
                            content: {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(availableFolds, id: \.rawValue) { fold in
                                            CustomizationOption(
                                                isSelected: fold == selectedFold,
                                                isLocked: !isFoldUnlocked(fold),
                                                image: "fold_\(fold.rawValue)",
                                                title: fold.displayName,
                                                onSelect: {
                                                    if isFoldUnlocked(fold) {
                                                        withAnimation {
                                                            selectedFold = fold
                                                        }
                                                    } else {
                                                        showUnlockPrompt(for: fold.displayName, cost: fold.unlockCost)
                                                    }
                                                }
                                            )
                                            .accessibilityHint("Select the \(fold.displayName) fold type")
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        )
                        
                        // Pattern section
                        CustomizationSection(
                            title: "Pattern",
                            isAnimated: $animatePatterns,
                            content: {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(availablePatterns, id: \.rawValue) { pattern in
                                            CustomizationOption(
                                                isSelected: pattern == selectedPattern,
                                                isLocked: !isPatternUnlocked(pattern),
                                                image: "pattern_\(pattern.rawValue)",
                                                title: pattern.displayName,
                                                onSelect: {
                                                    if isPatternUnlocked(pattern) {
                                                        withAnimation {
                                                            selectedPattern = pattern
                                                        }
                                                    } else {
                                                        showUnlockPrompt(for: pattern.displayName, cost: pattern.unlockCost)
                                                    }
                                                }
                                            )
                                            .accessibilityHint("Select the \(pattern.displayName) pattern")
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        )
                    }
                    .padding(.bottom, 20)
                }
                
                // Save button
                Button(action: {
                    saveCustomization()
                }) {
                    Text("Save Changes")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                        )
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                .accessibilityHint("Save your airplane customization changes")
            }
            .padding(.top, 10)
            
            // Unlock alert
            if showUnlockAlert {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            showUnlockAlert = false
                        }
                    }
                
                VStack(spacing: 20) {
                    Text("Unlock \(itemToUnlock)?")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("This will cost \(unlockCost) XP")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            withAnimation {
                                showUnlockAlert = false
                            }
                        }) {
                            Text("Cancel")
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 100)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                                .foregroundColor(.primary)
                        }
                        
                        Button(action: {
                            unlockItem()
                        }) {
                            Text("Unlock")
                                .font(.system(size: 16, weight: .bold))
                                .frame(width: 100)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.blue)
                                )
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(radius: 10)
                )
                .padding(.horizontal, 40)
                .transition(.scale)
            }
        }
        .navigationTitle("Customize Airplane")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Computed Properties
    
    /// Get the image name for the airplane preview
    private var airplanePreviewImageName: String {
        "airplane_\(selectedDesign.rawValue)_\(selectedColor.rawValue)_\(selectedPattern.rawValue)"
    }
    
    // MARK: - Methods
    
    /// Start the entrance animations
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
            animateDesigns = true
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            animateColors = true
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            animateFolds = true
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
            animatePatterns = true
        }
    }
    
    /// Save the customization changes
    private func saveCustomization() {
        // Save to UserDefaults
        let playerData = UserDefaults.standard
        playerData.set(selectedDesign.rawValue, forKey: "selectedAirplaneDesign")
        playerData.set(selectedColor.rawValue, forKey: "selectedAirplaneColor")
        playerData.set(selectedFold.rawValue, forKey: "selectedFoldType")
        playerData.set(selectedPattern.rawValue, forKey: "selectedPatternType")
        
        // Show success feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Dismiss the view
        dismiss()
    }
    
    /// Show the unlock prompt for an item
    /// - Parameters:
    ///   - item: The item name
    ///   - cost: The XP cost to unlock
    private func showUnlockPrompt(for item: String, cost: Int) {
        itemToUnlock = item
        unlockCost = cost
        
        withAnimation {
            showUnlockAlert = true
        }
    }
    
    /// Unlock the selected item
    private func unlockItem() {
        // In a real app, this would check if the player has enough XP
        // and then unlock the item in the player's progression
        
        // For now, we'll just simulate success
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Show confetti
        withAnimation {
            showConfetti = true
            showUnlockAlert = false
        }
        
        // Hide confetti after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showConfetti = false
            }
        }
        
        // Announce for VoiceOver users
        AccessibilityManager.shared.announceMessage("\(itemToUnlock) unlocked!")
    }
    
    /// Check if a design is unlocked
    /// - Parameter design: The design to check
    /// - Returns: Whether the design is unlocked
    private func isDesignUnlocked(_ design: AirplaneDesign) -> Bool {
        // In a real app, this would check the player's progression
        // For now, we'll just make some designs locked
        switch design {
        case .classic, .dart:
            return true
        case .glider:
            return UserDefaults.standard.bool(forKey: "unlocked_design_glider")
        case .stunt:
            return UserDefaults.standard.bool(forKey: "unlocked_design_stunt")
        case .origami:
            return UserDefaults.standard.bool(forKey: "unlocked_design_origami")
        }
    }
    
    /// Check if a color is unlocked
    /// - Parameter color: The color to check
    /// - Returns: Whether the color is unlocked
    private func isColorUnlocked(_ color: AirplaneColor) -> Bool {
        // In a real app, this would check the player's progression
        // For now, we'll just make some colors locked
        switch color {
        case .white, .blue:
            return true
        case .red:
            return UserDefaults.standard.bool(forKey: "unlocked_color_red")
        case .green:
            return UserDefaults.standard.bool(forKey: "unlocked_color_green")
        case .yellow:
            return UserDefaults.standard.bool(forKey: "unlocked_color_yellow")
        case .purple:
            return UserDefaults.standard.bool(forKey: "unlocked_color_purple")
        }
    }
    
    /// Check if a fold type is unlocked
    /// - Parameter fold: The fold type to check
    /// - Returns: Whether the fold type is unlocked
    private func isFoldUnlocked(_ fold: FoldType) -> Bool {
        // In a real app, this would check the player's progression
        // For now, we'll just make some fold types locked
        switch fold {
        case .standard, .sharp:
            return true
        case .curved:
            return UserDefaults.standard.bool(forKey: "unlocked_fold_curved")
        case .precision:
            return UserDefaults.standard.bool(forKey: "unlocked_fold_precision")
        }
    }
    
    /// Check if a pattern is unlocked
    /// - Parameter pattern: The pattern to check
    /// - Returns: Whether the pattern is unlocked
    private func isPatternUnlocked(_ pattern: PatternType) -> Bool {
        // In a real app, this would check the player's progression
        // For now, we'll just make some patterns locked
        switch pattern {
        case .none, .dots:
            return true
        case .stripes:
            return UserDefaults.standard.bool(forKey: "unlocked_pattern_stripes")
        case .stars:
            return UserDefaults.standard.bool(forKey: "unlocked_pattern_stars")
        case .custom:
            return UserDefaults.standard.bool(forKey: "unlocked_pattern_custom")
        }
    }
}

// MARK: - Supporting Views

/// Section for customization options
struct CustomizationSection<Content: View>: View {
    let title: String
    @Binding var isAnimated: Bool
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal)
                .opacity(isAnimated ? 1 : 0)
                .offset(x: isAnimated ? 0 : -20)
            
            content()
                .opacity(isAnimated ? 1 : 0)
                .offset(y: isAnimated ? 0 : 20)
        }
    }
}

/// Option for customization
struct CustomizationOption: View {
    let isSelected: Bool
    let isLocked: Bool
    let image: String
    let title: String
    let onSelect: () -> Void
    
    var body: some View {
        VStack {
            ZStack {
                // Option image
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .opacity(isLocked ? 0.5 : 1)
                
                // Selection indicator
                if isSelected && !isLocked {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: 80, height: 80)
                }
                
                // Lock overlay
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.7))
                        )
                }
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.tertiarySystemBackground))
            )
            .onTapGesture {
                onSelect()
            }
            
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .primary : .secondary)
                .lineLimit(1)
                .frame(width: 80)
        }
    }
}

/// Color option for customization
struct ColorOption: View {
    let color: UIColor
    let isSelected: Bool
    let isLocked: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack {
            ZStack {
                // Color circle
                Circle()
                    .fill(Color(color))
                    .frame(width: 60, height: 60)
                    .opacity(isLocked ? 0.5 : 1)
                
                // Selection indicator
                if isSelected && !isLocked {
                    Circle()
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: 70, height: 70)
                }
                
                // Lock overlay
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.7))
                        )
                }
            }
            .frame(width: 70, height: 70)
            .onTapGesture {
                onSelect()
            }
        }
    }
}

/// Confetti view for celebrations
struct ConfettiView: View {
    @State private var confetti: [ConfettiPiece] = []
    
    var body: some View {
        ZStack {
            ForEach(confetti) { piece in
                ConfettiPiece(color: piece.color, rotation: piece.rotation, position: piece.position)
            }
        }
        .onAppear {
            generateConfetti()
        }
    }
    
    private func generateConfetti() {
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange]
        
        for _ in 0..<50 {
            let piece = ConfettiPiece(
                id: UUID(),
                color: colors.randomElement()!,
                rotation: Double.random(in: 0...360),
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: -50...0)
                )
            )
            confetti.append(piece)
        }
    }
}

struct ConfettiPiece: View, Identifiable {
    let id: UUID
    let color: Color
    let rotation: Double
    let position: CGPoint
    
    init(id: UUID = UUID(), color: Color, rotation: Double, position: CGPoint) {
        self.id = id
        self.color = color
        self.rotation = rotation
        self.position = position
    }
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 8, height: 8)
            .rotationEffect(.degrees(rotation))
            .position(x: position.x, y: position.y)
            .offset(y: 300) // Start below the screen
            .animation(
                .linear(duration: 3)
                    .delay(Double.random(in: 0...1)),
                value: position
            )
    }
}

// MARK: - Models

/// Airplane design options
enum AirplaneDesign: String, CaseIterable {
    case classic
    case dart
    case glider
    case stunt
    case origami
    
    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .dart: return "Dart"
        case .glider: return "Glider"
        case .stunt: return "Stunt"
        case .origami: return "Origami"
        }
    }
    
    var unlockCost: Int {
        switch self {
        case .classic, .dart: return 0
        case .glider: return 100
        case .stunt: return 250
        case .origami: return 500
        }
    }
}

/// Airplane color options
enum AirplaneColor: String, CaseIterable {
    case white
    case blue
    case red
    case green
    case yellow
    case purple
    
    var displayName: String {
        switch self {
        case .white: return "White"
        case .blue: return "Blue"
        case .red: return "Red"
        case .green: return "Green"
        case .yellow: return "Yellow"
        case .purple: return "Purple"
        }
    }
    
    var uiColor: UIColor {
        switch self {
        case .white: return .white
        case .blue: return .systemBlue
        case .red: return .systemRed
        case .green: return .systemGreen
        case .yellow: return .systemYellow
        case .purple: return .systemPurple
        }
    }
    
    var unlockCost: Int {
        switch self {
        case .white, .blue: return 0
        case .red, .green: return 50
        case .yellow: return 100
        case .purple: return 150
        }
    }
}

/// Fold type options
enum FoldType: String, CaseIterable {
    case standard
    case sharp
    case curved
    case precision
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .sharp: return "Sharp"
        case .curved: return "Curved"
        case .precision: return "Precision"
        }
    }
    
    var unlockCost: Int {
        switch self {
        case .standard, .sharp: return 0
        case .curved: return 150
        case .precision: return 300
        }
    }
}

/// Pattern type options
enum PatternType: String, CaseIterable {
    case none
    case dots
    case stripes
    case stars
    case custom
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .dots: return "Dots"
        case .stripes: return "Stripes"
        case .stars: return "Stars"
        case .custom: return "Custom"
        }
    }
    
    var unlockCost: Int {
        switch self {
        case .none, .dots: return 0
        case .stripes: return 75
        case .stars: return 200
        case .custom: return 350
        }
    }
} 
