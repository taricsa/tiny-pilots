import SwiftUI

/// SwiftUI view for game mode selection - With direct object injection
struct GameModeSelectionView: View {
    // Observed object for direct injection
    @ObservedObject var gameState: GameStateManager
    
    var body: some View {
        GameModeSelectionContent(gameState: gameState)
    }
}

/// SwiftUI view for game mode selection - With environment object injection
struct GameModeSelectionEnvironmentView: View {
    // Environment object for automatic injection
    @EnvironmentObject var gameState: GameStateManager
    
    var body: some View {
        GameModeSelectionContent(gameState: gameState)
    }
}

/// Shared content view for game mode selection - SIMPLIFIED VERSION
struct GameModeSelectionContent: View {
    // Reference to game state
    let gameState: GameStateManager
    
    // Animation states
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            // Completely transparent background to let SpriteKit show through
            Color.clear
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text("SELECT GAME MODE")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 40)
                    .shadow(color: .black, radius: 2)
                
                Spacer()
                
                // Simple button stack
                VStack(spacing: 20) {
                    // FREE PLAY BUTTON
                    Button {
                        print("FREE PLAY BUTTON TAPPED")
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        gameState.startGame(mode: .freePlay)
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Circle().fill(Color.blue.opacity(0.5)))
                            
                            VStack(alignment: .leading) {
                                Text("Free Play")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Practice your flying skills with no time limits")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    }
                    .buttonStyle(PlainButtonStyle()) // Use plain style for reliable touch handling
                    
                    // DAILY RUN BUTTON
                    Button {
                        print("DAILY RUN BUTTON TAPPED")
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        gameState.startGame(mode: .dailyRun)
                    } label: {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Circle().fill(Color.green.opacity(0.5)))
                            
                            VStack(alignment: .leading) {
                                Text("Daily Run")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Take on today's unique challenge")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.green.opacity(0.3))
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    }
                    .buttonStyle(PlainButtonStyle()) // Use plain style for reliable touch handling
                    
                    // WEEKLY SPECIAL BUTTON
                    Button {
                        print("WEEKLY SPECIAL BUTTON TAPPED")
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        gameState.startGame(mode: .weeklySpecial)
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Circle().fill(Color.orange.opacity(0.5)))
                            
                            VStack(alignment: .leading) {
                                Text("Weekly Special")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("This week's special flight competition")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.3))
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    }
                    .buttonStyle(PlainButtonStyle()) // Use plain style for reliable touch handling
                }
                .padding(.horizontal)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 50)
                .animation(.easeOut(duration: 0.5), value: appeared)
                
                Spacer()
                
                // Back button - simplified
                Button {
                    print("BACK BUTTON TAPPED")
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    
                    // Return to main menu via notification (handled by coordinator/root)
                    NotificationCenter.default.post(name: Notification.Name("NavigateToMainMenu"), object: nil)
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back to Menu")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Capsule().fill(Color.white.opacity(0.2)))
                }
                .buttonStyle(PlainButtonStyle()) // Use plain style for reliable touch handling
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            print("GameModeSelectionContent appeared")
            // Delay animation for smooth transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                appeared = true
            }
        }
        .onTapGesture { 
            // Adding an empty tap gesture to the whole view for debugging
            print("Background tap detected")
        }
    }
} 