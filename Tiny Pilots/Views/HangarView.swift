import SwiftUI

/// SwiftUI view for the airplane hangar
struct HangarView: View {
    // Environment object to access game state
    @EnvironmentObject var gameState: GameStateManager
    
    // Animation states
    @State private var animateTitle = true
    @State private var animateContent = true
    
    // Selected airplane
    @State private var selectedPlane = 0
    
    // Sample airplane data
    private let airplanes = [
        Airplane(name: "Classic Dart", description: "The beginner's choice with balanced stats", unlocked: true),
        Airplane(name: "Speed Hawk", description: "Optimized for speed but less stable", unlocked: true),
        Airplane(name: "Stable Glider", description: "Maximum stability for longer flights", unlocked: false),
        Airplane(name: "Stunt Master", description: "Perfect for aerial tricks and maneuvers", unlocked: false)
    ]
    
    var body: some View {
        ZStack {
            // Background is handled by SpriteKit scene
            Color.clear
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                Text("AIRPLANE HANGAR")
                    .font(DynamicTypeHelper.shared.scaledFont(baseSize: 36, weight: .bold, design: .rounded, for: .largeTitle))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
                    .padding(.top, DynamicTypeHelper.shared.scaledPadding(40))
                    .opacity(animateTitle ? 1 : 0)
                    .offset(y: animateTitle ? 0 : -50)
                    .minimumScaleFactor(0.5)
                    .lineLimit(nil)
                
                // Airplane display area
                VStack(spacing: 20) {
                    // Airplane image placeholder
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 180, height: 180)
                        
                        Image(systemName: "paperplane.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(45))
                    }
                    .padding(20)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Preview of \(airplanes[selectedPlane].name)")
                    .accessibilityHint("Visual representation of the selected airplane")
                    .accessibilitySortPriority(90)
                    
                    // Airplane details
                    VStack(spacing: DynamicTypeHelper.shared.scaledSpacing(8)) {
                        Text(airplanes[selectedPlane].name)
                            .font(DynamicTypeHelper.shared.scaledFont(baseSize: 24, weight: .bold, design: .rounded, for: .title2))
                            .lineLimit(nil)
                        
                        Text(airplanes[selectedPlane].description)
                            .font(DynamicTypeHelper.shared.scaledFont(baseSize: 16, for: .body))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DynamicTypeHelper.shared.scaledPadding(20))
                            .lineLimit(nil)
                        
                        // Locked status
                        if !airplanes[selectedPlane].unlocked {
                            Text("Locked - Reach higher level to unlock")
                                .font(DynamicTypeHelper.shared.scaledFont(baseSize: 16, weight: .medium, for: .body))
                                .foregroundColor(.orange)
                                .padding(.top, DynamicTypeHelper.shared.scaledPadding(8))
                                .lineLimit(nil)
                        }
                    }
                    .foregroundColor(.white)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(airplanes[selectedPlane].name). \(airplanes[selectedPlane].description). \(airplanes[selectedPlane].unlocked ? "Available" : "Locked - Reach higher level to unlock")")
                    .accessibilitySortPriority(80)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DynamicTypeHelper.shared.scaledPadding(24))
                .background(
                    RoundedRectangle(cornerRadius: DynamicTypeHelper.shared.scaledCornerRadius(20))
                        .fill(Color.white.opacity(VisualAccessibilityHelper.shared.isReduceTransparencyEnabled ? 0.3 : 0.1))
                        .background(
                            VisualAccessibilityHelper.shared.isReduceTransparencyEnabled ?
                            Color.blue.opacity(0.8) :
                            .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: DynamicTypeHelper.shared.scaledCornerRadius(20))
                        )
                        .overlay(
                            VisualAccessibilityHelper.shared.isHighContrastEnabled ?
                            RoundedRectangle(cornerRadius: DynamicTypeHelper.shared.scaledCornerRadius(20))
                                .stroke(Color.white, lineWidth: 2) : nil
                        )
                )
                .padding(.horizontal, DynamicTypeHelper.shared.scaledPadding(24))
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 50)
                
                // Airplane selection buttons
                HStack(spacing: 16) {
                    ForEach(0..<airplanes.count, id: \.self) { index in
                        Button {
                            selectedPlane = index
                        } label: {
                            Circle()
                                .fill(selectedPlane == index 
                                      ? Color.white 
                                      : Color.white.opacity(0.3))
                                .frame(width: 16, height: 16)
                        }
                        .accessibilityLabel("Select \(airplanes[index].name)")
                        .accessibilityHint(airplanes[index].unlocked ? "Available airplane" : "Locked airplane")
                        .accessibilityValue(selectedPlane == index ? "Selected" : "Not selected")
                        .accessibilitySortPriority(70 - Double(index))
                    }
                }
                .opacity(animateContent ? 1 : 0)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Airplane selection")
                
                Spacer()
                
                // Bottom buttons
                HStack(spacing: 20) {
                    // Back button
                    Button {
                        withAnimation {
                            gameState.currentScreen = .mainMenu
                        }
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                                .font(DynamicTypeHelper.shared.scaledFont(baseSize: 18, weight: .semibold, for: .body))
                            
                            Text("Back")
                                .font(DynamicTypeHelper.shared.scaledFont(baseSize: 18, weight: .semibold, design: .rounded, for: .body))
                        }
                        .padding(.vertical, DynamicTypeHelper.shared.scaledPadding(12))
                        .padding(.horizontal, DynamicTypeHelper.shared.scaledPadding(24))
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                                .background(
                                    .ultraThinMaterial,
                                    in: Capsule()
                                )
                        )
                        .foregroundColor(.white)
                    }
                    .accessibilityLabel("Back")
                    .accessibilityHint("Return to main menu")
                    .accessibilitySortPriority(20)
                    
                    // Select button
                    Button {
                        // In a real implementation, this would save the selected plane
                        withAnimation {
                            gameState.currentScreen = .mainMenu
                        }
                    } label: {
                        Text("Select")
                            .font(DynamicTypeHelper.shared.scaledFont(baseSize: 18, weight: .semibold, design: .rounded, for: .body))
                            .padding(.vertical, DynamicTypeHelper.shared.scaledPadding(12))
                            .padding(.horizontal, DynamicTypeHelper.shared.scaledPadding(36))
                            .background(
                                Capsule()
                                    .fill(airplanes[selectedPlane].unlocked 
                                          ? Color.blue 
                                          : Color.gray)
                                    .background(
                                        .ultraThinMaterial,
                                        in: Capsule()
                                    )
                            )
                            .foregroundColor(.white)
                    }
                    .disabled(!airplanes[selectedPlane].unlocked)
                    .accessibilityLabel("Select \(airplanes[selectedPlane].name)")
                    .accessibilityHint(airplanes[selectedPlane].unlocked ? "Choose this airplane and return to main menu" : "This airplane is locked")
                    .accessibilityValue(airplanes[selectedPlane].unlocked ? "Available" : "Locked")
                    .accessibilitySortPriority(10)
                }
                .padding(.bottom, 40)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 50)
            }
            .padding(.horizontal, 16)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    /// Start entrance animations
    private func startAnimations() {
        // Reset animation states to ensure they trigger
        animateTitle = false
        animateContent = false
        
        // Respect reduce motion settings
        let animationDuration = VisualAccessibilityHelper.shared.adjustedAnimationDuration(0.8)
        let shouldAnimate = !VisualAccessibilityHelper.shared.shouldDisableAnimation(.decorative)
        
        // Use DispatchQueue to ensure animations happen in the main thread
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if shouldAnimate {
                withAnimation(.easeOut(duration: animationDuration)) {
                    self.animateTitle = true
                }
            } else {
                self.animateTitle = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + (shouldAnimate ? 0.3 : 0.1)) {
                if shouldAnimate {
                    withAnimation(.easeOut(duration: animationDuration)) {
                        self.animateContent = true
                    }
                } else {
                    self.animateContent = true
                }
            }
        }
    }
}

/// Model for airplane data
struct Airplane {
    let name: String
    let description: String
    let unlocked: Bool
} 