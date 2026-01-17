import SwiftUI

/// Privacy disclosure view shown on first app launch
struct PrivacyDisclosureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var hasAcceptedPrivacy = false
    @State private var hasAcceptedTerms = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    
    let onAccept: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .center, spacing: 16) {
                        Image("AppIcon")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .cornerRadius(16)
                            .accessibilityHidden(true)
                        
                        Text("Welcome to Tiny Pilots!")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Before you start flying, please review our privacy practices.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 10)
                    
                    // Privacy Summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Privacy Matters")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        PrivacyPointView(
                            icon: "checkmark.shield",
                            title: "No Personal Data Collection",
                            description: "We don't collect your name, email, or personal information."
                        )
                        
                        PrivacyPointView(
                            icon: "gamecontroller",
                            title: "Game Center Integration",
                            description: "Optional Game Center connection for leaderboards and achievements."
                        )
                        
                        PrivacyPointView(
                            icon: "chart.bar",
                            title: "Anonymous Analytics",
                            description: "We collect anonymous usage data to improve the game experience."
                        )
                        
                        PrivacyPointView(
                            icon: "exclamationmark.triangle",
                            title: "Crash Reports",
                            description: "Automatic crash reports help us fix bugs and improve stability."
                        )
                        
                        PrivacyPointView(
                            icon: "hand.raised",
                            title: "Your Control",
                            description: "You can opt out of analytics in Settings at any time."
                        )
                    }
                    
                    // Legal Documents
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Legal Documents")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Button(action: { showingPrivacyPolicy = true }) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Privacy Policy")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .foregroundColor(.primary)
                        .accessibilityLabel("View Privacy Policy")
                        
                        Button(action: { showingTermsOfService = true }) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Terms of Service")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .foregroundColor(.primary)
                        .accessibilityLabel("View Terms of Service")
                    }
                    
                    // Consent Checkboxes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Consent")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ConsentCheckboxView(
                            isChecked: $hasAcceptedPrivacy,
                            text: "I have read and agree to the Privacy Policy"
                        )
                        
                        ConsentCheckboxView(
                            isChecked: $hasAcceptedTerms,
                            text: "I have read and agree to the Terms of Service"
                        )
                    }
                    
                    // Continue Button
                    Button(action: handleAccept) {
                        Text("Start Flying!")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canContinue ? Color.blue : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(!canContinue)
                    .accessibilityLabel(canContinue ? "Accept and start using Tiny Pilots" : "Please accept both privacy policy and terms of service to continue")
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Privacy & Terms")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            SafariView(url: AppStoreComplianceManager.shared.getPrivacyPolicyURL()!)
        }
        .sheet(isPresented: $showingTermsOfService) {
            SafariView(url: AppStoreComplianceManager.shared.getTermsOfServiceURL()!)
        }
    }
    
    private var canContinue: Bool {
        hasAcceptedPrivacy && hasAcceptedTerms
    }
    
    private func handleAccept() {
        guard canContinue else { return }
        
        AppStoreComplianceManager.shared.markPrivacyPolicyShown()
        AnalyticsManager.shared.trackEvent(.privacyPolicyAccepted)
        
        onAccept()
    }
}

struct PrivacyPointView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ConsentCheckboxView: View {
    @Binding var isChecked: Bool
    let text: String
    
    var body: some View {
        Button(action: { isChecked.toggle() }) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .foregroundColor(isChecked ? .blue : .gray)
                    .font(.title3)
                
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isChecked ? "Checked" : "Unchecked")
        .accessibilityLabel(text)
    }
}

import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safari = SFSafariViewController(url: url)
        safari.preferredControlTintColor = UIColor.systemBlue
        return safari
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    PrivacyDisclosureView {
        print("Privacy accepted")
    }
}