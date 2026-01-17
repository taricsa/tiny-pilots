import SwiftUI
import GameKit

/// SwiftUI view for the main menu overlay
struct MainMenuView: View {
    // MARK: - Properties
    
    // Environment object to access game state
    @EnvironmentObject var gameState: GameStateManager
    
    // State variables
    @State private var showingSettings = false
    @State private var showingAchievements = false
    @State private var showingLeaderboards = false
    @State private var showingChallengeInput = false
    
    // Animation states
    @State private var animateTitle = true
    @State private var animateButtons = true
    
    // Player stats (should be fetched from your game state in real implementation)
    @State private var playerLevel = 1
    @State private var playerXP = 50
    @State private var playerMaxXP = 100
    @State private var showingUnlocks = false
    
    // Game mode selection
    @State private var isShowingGameModeSelection = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background is handled by SpriteKit scene
            // Add a clear background to ensure transparency
            Color.clear
                .ignoresSafeArea()
            
            // Debug overlay to check if the view is rendering
            Color.red.opacity(VisualAccessibilityHelper.shared.isReduceTransparencyEnabled ? 0.5 : 0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Title area
                titleArea
                    .opacity(animateTitle ? 1 : 0)
                    .offset(y: animateTitle ? 0 : -50)
                
                // Player level info
                playerLevelInfo
                    .opacity(animateTitle ? 1 : 0)
                    .offset(y: animateTitle ? 0 : -30)
                
                // Better vertical spacing with flexible spacers
                Spacer()
                    .frame(height: 10)
                    .layoutPriority(1)
                
                // Main buttons
                buttonArea
                    .opacity(animateButtons ? 1 : 0)
                    .offset(y: animateButtons ? 0 : 50)
                
                Spacer()
                    .frame(height: 20)
                    .layoutPriority(0.5)
                
                // Debug text to confirm view hierarchy
                Text("Debug: MainMenuView is rendering")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
            }
            .padding(.top, 50)
            .padding(.bottom, 40)
            .padding(.horizontal, 24)
            
            // Modals
            if showingSettings {
                SettingsView(isPresented: $showingSettings)
                    .transition(.opacity)
            }
        }
        // Let's verify our animation is working properly
        .onAppear {
            print("MainMenuView appeared")
            startAnimations()
        }
        .sheet(isPresented: $showingAchievements) {
            GameCenterView()
        }
        .sheet(isPresented: $showingLeaderboards) {
            GameCenterView()
        }
        .sheet(isPresented: $showingChallengeInput) {
            ChallengeInputView()
        }
        .sheet(isPresented: $showingUnlocks) {
            UnlocksView(
                level: playerLevel,
                onDismiss: { showingUnlocks = false }
            )
        }
    }
    
    // MARK: - UI Components
    
    /// Title area with game logo
    private var titleArea: some View {
        VStack(spacing: DynamicTypeHelper.shared.scaledSpacing(10)) {
            Text("TINY PILOTS")
                .font(DynamicTypeHelper.shared.scaledFont(baseSize: 48, weight: .bold, design: .rounded, for: .largeTitle))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
                .minimumScaleFactor(0.5)
                .lineLimit(nil)
            
            Text("Take Flight, Make History")
                .font(DynamicTypeHelper.shared.scaledFont(baseSize: 18, weight: .medium, design: .rounded, for: .headline))
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                .minimumScaleFactor(0.7)
                .lineLimit(nil)
        }
        .padding(.vertical, DynamicTypeHelper.shared.scaledPadding(24))
        .padding(.horizontal, DynamicTypeHelper.shared.scaledPadding(30))
        .background(
            ZStack {
                // Blurred background with accessibility considerations
                RoundedRectangle(cornerRadius: DynamicTypeHelper.shared.scaledCornerRadius(24))
                    .fill(Color.blue.opacity(VisualAccessibilityHelper.shared.isReduceTransparencyEnabled ? 0.8 : 0.3))
                    .background(
                        RoundedRectangle(cornerRadius: DynamicTypeHelper.shared.scaledCornerRadius(24))
                            .fill(.ultraThinMaterial)
                            .opacity(VisualAccessibilityHelper.shared.isReduceTransparencyEnabled ? 0.0 : 1.0)
                    )
                
                // Top highlight with high contrast support
                RoundedRectangle(cornerRadius: DynamicTypeHelper.shared.scaledCornerRadius(24))
                    .stroke(
                        VisualAccessibilityHelper.shared.isHighContrastEnabled ?
                        Color.white :
                        LinearGradient(
                            colors: [.white.opacity(0.7), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: VisualAccessibilityHelper.shared.isHighContrastEnabled ? 2.0 : 1.5
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tiny Pilots, Take Flight, Make History")
        .accessibilitySortPriority(100)
    }
    
    /// Player level information display
    private var playerLevelInfo: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showingUnlocks = true
            }
        }) {
            VStack(spacing: 10) {
                HStack {
                    HStack(spacing: DynamicTypeHelper.shared.scaledSpacing(8)) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(DynamicTypeHelper.shared.scaledFont(baseSize: 16, weight: .bold, for: .body))
                        
                        Text("Level \(playerLevel)")
                            .font(DynamicTypeHelper.shared.scaledFont(baseSize: 18, weight: .bold, design: .rounded, for: .headline))
                    }
                    
                    Spacer()
                    
                    Text("\(playerXP)/\(playerMaxXP) XP")
                        .font(DynamicTypeHelper.shared.scaledFont(baseSize: 16, weight: .medium, design: .rounded, for: .body))
                }
                
                // XP Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 12)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, Color(red: 0.3, green: 0.8, blue: 1.0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(12, geometry.size.width * CGFloat(playerXP) / CGFloat(playerMaxXP)), height: 12)
                    }
                }
                .frame(height: 12)
                
                HStack {
                    Spacer()
                    HStack(spacing: DynamicTypeHelper.shared.scaledSpacing(6)) {
                        Text("Tap to see unlocks")
                            .font(DynamicTypeHelper.shared.scaledFont(baseSize: 14, weight: .medium, design: .rounded, for: .caption1))
                        Image(systemName: "chevron.right.circle.fill")
                            .font(DynamicTypeHelper.shared.scaledFont(baseSize: 12, for: .caption1))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.blue.opacity(0.2))
                        .background(
                            .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 18)
                        )
                    
                    // Top highlight
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.5), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 3)
            .foregroundColor(.white)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Level \(playerLevel), \(playerXP) out of \(playerMaxXP) XP. Tap to see unlocks")
        .accessibilityHint("Shows upcoming unlocks and rewards")
        .accessibilitySortPriority(90)
    }
    
    /// Main button area
    private var buttonArea: some View {
        VStack(spacing: 20) {
            // Play button (larger, more prominent)
            selectGameModeButton
                .padding(.bottom, 10)
            
            // Secondary buttons section
            VStack(spacing: 16) {
                // Hangar button
                MenuButton(
                    title: "Airplane Hangar",
                    icon: "airplane",
                    color: .orange
                ) {
                    // Navigate to hangar - handled by parent view
                }
                .accessibilityHint("Customize your paper airplane")
                .accessibilitySortPriority(70)
                
                // Game Center buttons section
                VStack(spacing: 16) {
                    // Achievements button
                    MenuButton(
                        title: "Achievements",
                        icon: "trophy.fill",
                        color: .orange
                    ) {
                        showingAchievements = true
                    }
                    .accessibilityHint("View your game achievements")
                    .accessibilitySortPriority(60)
                    
                    // Leaderboards button
                    MenuButton(
                        title: "Leaderboards",
                        icon: "list.number",
                        color: .orange
                    ) {
                        showingLeaderboards = true
                    }
                    .accessibilityHint("View global leaderboards")
                    .accessibilitySortPriority(50)
                }
                
                // Challenge button
                MenuButton(
                    title: "Friend Challenge",
                    icon: "person.2.fill",
                    color: .orange
                ) {
                    showingChallengeInput = true
                }
                .accessibilityHint("Play a challenge from a friend")
                .accessibilitySortPriority(40)
                
                // Settings button
                MenuButton(
                    title: "Settings",
                    icon: "gearshape.fill",
                    color: .gray
                ) {
                    showingSettings = true
                }
                .accessibilityHint("Adjust game settings")
                .accessibilitySortPriority(30)
            }
        }
    }
    
    /// Game mode selection button
    private var selectGameModeButton: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // Update isShowingGameModeSelection
            withAnimation(.easeOut(duration: 0.3)) {
                isShowingGameModeSelection = true
            }
        }) {
            HStack {
                Spacer()
                
                Image(systemName: "play.fill")
                    .font(DynamicTypeHelper.shared.scaledFont(baseSize: 30, weight: .bold, for: .title2))
                    .padding(.trailing, DynamicTypeHelper.shared.scaledSpacing(6))
                
                Text("PLAY")
                    .font(DynamicTypeHelper.shared.scaledFont(baseSize: 30, weight: .heavy, design: .rounded, for: .title2))
                
                Spacer()
            }
            .padding(.vertical, 24)
            .foregroundColor(.white)
            .background(
                ZStack {
                    // Main fill with solid color for primary button
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // Top highlight
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.8), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            )
            .shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 5)
            .overlay(
                // Pulsing glow effect
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.blue.opacity(0.7), lineWidth: 3)
                    .blur(radius: 5)
                    .opacity(0.7)
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.95))
        .accessibilityLabel("Play")
        .accessibilityHint("Start playing the game")
        .accessibilitySortPriority(80)
        .sheet(isPresented: $isShowingGameModeSelection) {
            GameModeSelectionView(gameState: gameState)
                .onDisappear {
                    // Reset flag when the sheet is dismissed
                    isShowingGameModeSelection = false
                }
        }
    }
    
    // MARK: - Animation Methods
    
    /// Start entrance animations
    private func startAnimations() {
        print("Starting animations")
        
        // Reset animation states to ensure they trigger
        animateTitle = false
        animateButtons = false
        
        // Respect reduce motion settings
        let animationDuration = VisualAccessibilityHelper.shared.adjustedAnimationDuration(0.8)
        let shouldAnimate = !VisualAccessibilityHelper.shared.shouldDisableAnimation(.decorative)
        
        // Use DispatchQueue to ensure animations happen in the main thread
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("Animating title")
            if shouldAnimate {
                withAnimation(.easeOut(duration: animationDuration)) {
                    self.animateTitle = true
                }
            } else {
                self.animateTitle = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + (shouldAnimate ? 0.4 : 0.1)) {
                print("Animating buttons")
                if shouldAnimate {
                    withAnimation(.easeOut(duration: animationDuration)) {
                        self.animateButtons = true
                    }
                } else {
                    self.animateButtons = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

/// Custom button for menu items
struct MenuButton: View {
    let title: String
    let icon: String
    let color: Color
    var isPrimary: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            action()
        }) {
            HStack {
                Image(systemName: icon)
                    .font(DynamicTypeHelper.shared.scaledFont(
                        baseSize: isPrimary ? 24 : 20, 
                        weight: .semibold, 
                        for: isPrimary ? .title3 : .body
                    ))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(DynamicTypeHelper.shared.scaledFont(
                        baseSize: isPrimary ? 24 : 20, 
                        weight: .semibold, 
                        design: .rounded, 
                        for: isPrimary ? .title3 : .body
                    ))
                    .lineLimit(nil)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(DynamicTypeHelper.shared.scaledFont(
                        baseSize: isPrimary ? 16 : 14, 
                        weight: .semibold, 
                        for: .caption1
                    ))
                    .opacity(0.7)
            }
            .padding(.vertical, DynamicTypeHelper.shared.scaledPadding(isPrimary ? 20 : 16))
            .padding(.horizontal, DynamicTypeHelper.shared.scaledPadding(20))
            .foregroundColor(.white)
            .background(
                ZStack {
                    // Main fill with accessibility considerations
                    RoundedRectangle(cornerRadius: DynamicTypeHelper.shared.scaledCornerRadius(16))
                        .fill(color.opacity(VisualAccessibilityHelper.shared.isReduceTransparencyEnabled ? 0.8 : 0.2))
                        .background(
                            RoundedRectangle(cornerRadius: DynamicTypeHelper.shared.scaledCornerRadius(16))
                                .fill(.ultraThinMaterial)
                                .opacity(VisualAccessibilityHelper.shared.isReduceTransparencyEnabled ? 0.0 : 1.0)
                        )
                    
                    // Border for high contrast and button shapes
                    RoundedRectangle(cornerRadius: DynamicTypeHelper.shared.scaledCornerRadius(16))
                        .stroke(
                            VisualAccessibilityHelper.shared.isHighContrastEnabled || VisualAccessibilityHelper.shared.isButtonShapesEnabled ?
                            Color.white :
                            LinearGradient(
                                colors: [.white.opacity(0.5), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: VisualAccessibilityHelper.shared.isHighContrastEnabled ? 2.0 : 1.0
                        )
                }
            )
            .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .frame(height: isPrimary ? 70 : 60)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}

/// Unlocks view presented as a sheet
struct UnlocksView: View {
    let level: Int
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Content
            VStack(spacing: 24) {
                // Header
                Text("Level Unlocks")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                Text("Reach Level \(level + 1) to unlock:")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                
                // Unlock items in a grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    unlockItem(icon: "paperplane", title: "Dart Plane")
                    unlockItem(icon: "map", title: "Sky Valley")
                    unlockItem(icon: "wind", title: "Air Boost")
                    unlockItem(icon: "sparkles", title: "Trail Effect")
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Close button
                Button("Close") {
                    onDismiss()
                }
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                )
                .padding(.bottom, 30)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.black.opacity(0.1))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30))
                    .ignoresSafeArea()
            )
        }
    }
    
    /// Helper function to create unlock item
    private func unlockItem(icon: String, title: String) -> some View {
        VStack(spacing: 16) {
            // Icon with glow effect
            ZStack {
                // Glow
                Circle()
                    .fill(Color.blue.opacity(0.5))
                    .frame(width: 80, height: 80)
                    .blur(radius: 8)
                
                // Icon circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.8), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
            
            // Title
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .frame(height: 44)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.1))
        )
    }
}

/// Scale animation for buttons
struct ScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
} 