import SwiftUI

/// SwiftUI view for entering challenge codes
struct ChallengeInputView: View {
    // MARK: - Properties
    
    // Environment object to access game state
    @EnvironmentObject var gameState: GameStateManager
    
    // Environment to dismiss the view
    @SwiftUI.Environment(\.dismiss) private var dismiss: DismissAction
    
    // State variables
    @State private var challengeCode = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var challengeInfo: (courseID: String, distance: Int, time: Int)?
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(UIColor.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 25) {
                    // Challenge code input
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Enter Challenge Code")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        TextField("XXXX-XXXX-XXXX", text: $challengeCode)
                            .font(.system(size: 20, weight: .medium, design: .monospaced))
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 2)
                                    .opacity(challengeCode.isEmpty ? 0 : 1)
                            )
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                            .onChange(of: challengeCode) { oldValue, newValue in
                                // Format the challenge code as the user types
                                let filtered = newValue.uppercased().filter { $0.isLetter || $0.isNumber || $0 == "-" }
                                
                                if filtered != newValue {
                                    challengeCode = filtered
                                }
                                
                                // Clear error when typing
                                if !filtered.isEmpty {
                                    errorMessage = nil
                                    showError = false
                                }
                            }
                    }
                    
                    // Challenge info (if available)
                    if let info = challengeInfo {
                        VStack(spacing: 15) {
                            Text("Challenge Details")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 20) {
                                // Distance info
                                VStack {
                                    Image(systemName: "ruler")
                                        .font(.system(size: 24))
                                        .foregroundColor(.blue)
                                    
                                    Text("\(info.distance)m")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    Text("Distance")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                
                                // Time info
                                VStack {
                                    Image(systemName: "clock")
                                        .font(.system(size: 24))
                                        .foregroundColor(.orange)
                                    
                                    Text("\(info.time)s")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    Text("Time Limit")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                        }
                        .padding(.horizontal)
                        .transition(.opacity)
                    }
                    
                    // Error message
                    if showError, let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.red.opacity(0.1))
                            )
                            .transition(.opacity)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 15) {
                        // Submit button
                        Button(action: {
                            submitChallengeCode()
                        }) {
                            HStack {
                                Text("Start Challenge")
                                    .font(.system(size: 18, weight: .bold))
                                
                                if isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .padding(.leading, 5)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(challengeCode.isEmpty ? Color.gray : Color.blue)
                            )
                            .foregroundColor(.white)
                        }
                        .disabled(challengeCode.isEmpty || isProcessing)
                        .accessibilityHint("Submit the challenge code to start playing")
                        
                        // Generate button
                        Button(action: {
                            generateChallengeCode()
                        }) {
                            Text("Generate My Challenge")
                                .font(.system(size: 16, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue, lineWidth: 1)
                                )
                                .foregroundColor(.blue)
                        }
                        .accessibilityHint("Generate a new challenge code to share with friends")
                    }
                }
                .padding()
                .disabled(isProcessing)
            }
            .navigationTitle("Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    // MARK: - Methods
    
    /// Submit the challenge code
    private func submitChallengeCode() {
        // Validate input
        guard !challengeCode.isEmpty else {
            showError(message: "Please enter a challenge code")
            return
        }
        
        // Start processing
        isProcessing = true
        
        // Simulate network request
        let validateWork = DispatchWorkItem { [challengeCode] in
            // Process the challenge code
            let result = GameCenterManager.shared.processChallengeCode(challengeCode)
            
            if let courseID = result.0 {
                // Valid challenge code
                challengeInfo = (courseID: courseID, distance: 1000, time: 120)
                
                // Start the challenge after a brief delay
                let startWork = DispatchWorkItem {
                    // Dismiss the sheet
                    dismiss()
                    
                    // Start the challenge
                    gameState.startGame(mode: .challenge, environmentType: "challenge")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: startWork)
            } else {
                // Invalid challenge code
                showError(message: "Invalid challenge code. Please check and try again.")
                isProcessing = false
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: validateWork)
    }
    
    /// Generate a new challenge code
    private func generateChallengeCode() {
        // Generate a random course ID
        let courseID = "CustomCourse\(Int.random(in: 1...10))"
        
        // Generate the challenge code
        let code = GameCenterManager.shared.generateChallengeCode(for: courseID)
        
        // Set the code in the text field
        challengeCode = code
        
        // Copy to clipboard
        UIPasteboard.general.string = code
        
        // Show confirmation
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Show challenge info
        challengeInfo = (courseID: courseID, distance: Int.random(in: 800...1500), time: Int.random(in: 90...180))
    }
    
    /// Show an error message
    private func showError(message: String) {
        errorMessage = message
        
        withAnimation {
            showError = true
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
} 