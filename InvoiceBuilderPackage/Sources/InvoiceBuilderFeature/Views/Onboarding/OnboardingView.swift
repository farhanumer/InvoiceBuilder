import SwiftUI

public struct OnboardingView: View {
    @Environment(AuthenticationService.self) private var authService
    @Environment(AppState.self) private var appState
    @State private var currentStep = 0
    @State private var isCompleted = false
    
    private let steps: [OnboardingStep] = [
        .welcome,
        .businessSetup,
        .features,
        .ready
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress indicator
                    HStack {
                        ForEach(0..<steps.count, id: \.self) { index in
                            Circle()
                                .fill(index <= currentStep ? .blue : .gray.opacity(0.3))
                                .frame(width: 10, height: 10)
                            
                            if index < steps.count - 1 {
                                Rectangle()
                                    .fill(index < currentStep ? .blue : .gray.opacity(0.3))
                                    .frame(height: 2)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                    
                    // Current step content
                    TabView(selection: $currentStep) {
                        ForEach(0..<steps.count, id: \.self) { index in
                            stepView(for: steps[index])
                                .tag(index)
                        }
                    }
                    #if os(iOS)
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    #endif
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
                    
                    // Navigation buttons
                    HStack(spacing: 20) {
                        if currentStep > 0 {
                            Button("Back") {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Spacer()
                        
                        Button(currentStep == steps.count - 1 ? "Get Started" : "Continue") {
                            if currentStep == steps.count - 1 {
                                completeOnboarding()
                            } else {
                                withAnimation {
                                    currentStep += 1
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.light)
    }
    
    @ViewBuilder
    private func stepView(for step: OnboardingStep) -> some View {
        VStack(spacing: 30) {
            Spacer()
            
            switch step {
            case .welcome:
                WelcomeStepView()
            case .businessSetup:
                BusinessSetupStepView()
            case .features:
                FeaturesStepView()
            case .ready:
                ReadyStepView()
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    private func completeOnboarding() {
        // Mark onboarding as completed in AppState
        appState.completeOnboarding()
        isCompleted = true
    }
}

// MARK: - Onboarding Steps

private enum OnboardingStep: CaseIterable {
    case welcome
    case businessSetup
    case features
    case ready
}

// MARK: - Step Views

private struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            VStack(spacing: 12) {
                Text("Welcome to Invoice Builder")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Professional invoicing made simple")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                FeatureBadge(
                    icon: "doc.badge.plus",
                    title: "Create Professional Invoices",
                    description: "Beautiful templates and customization"
                )
                
                FeatureBadge(
                    icon: "person.2.fill",
                    title: "Manage Clients",
                    description: "Keep track of all your customers"
                )
                
                FeatureBadge(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Track Your Business",
                    description: "Analytics and reporting dashboard"
                )
            }
        }
    }
}

private struct BusinessSetupStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            VStack(spacing: 12) {
                Text("Set Up Your Business")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("We'll help you configure your business profile in the next step")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                SetupItem(
                    icon: "info.circle.fill",
                    title: "Business Information",
                    description: "Name, address, and contact details"
                )
                
                SetupItem(
                    icon: "photo.fill",
                    title: "Logo & Branding",
                    description: "Upload your logo and signature"
                )
                
                SetupItem(
                    icon: "dollarsign.circle.fill",
                    title: "Payment & Tax Settings",
                    description: "Configure currencies and tax rates"
                )
            }
        }
    }
}

private struct FeaturesStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "star.fill")
                .font(.system(size: 80))
                .foregroundStyle(.yellow)
            
            VStack(spacing: 12) {
                Text("Powerful Features")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Everything you need to run your business")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                FeatureBadge(
                    icon: "icloud.fill",
                    title: "Cloud Sync",
                    description: "Access your data anywhere"
                )
                
                FeatureBadge(
                    icon: "doc.richtext.fill",
                    title: "PDF Export",
                    description: "Professional PDF invoices"
                )
                
                FeatureBadge(
                    icon: "bell.fill",
                    title: "Payment Reminders",
                    description: "Never miss a payment again"
                )
            }
        }
    }
}

private struct ReadyStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            VStack(spacing: 12) {
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Let's create your first invoice and set up your business profile")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                ReadyItem(
                    icon: "1.circle.fill",
                    title: "Complete Business Profile",
                    description: "Add your business details"
                )
                
                ReadyItem(
                    icon: "2.circle.fill",
                    title: "Add Your First Client",
                    description: "Start building your client list"
                )
                
                ReadyItem(
                    icon: "3.circle.fill",
                    title: "Create Your First Invoice",
                    description: "Choose a template and get started"
                )
            }
        }
    }
}

// MARK: - Supporting Views

private struct FeatureBadge: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

private struct SetupItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

private struct ReadyItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.green)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Onboarding State Check

public extension View {
    func showOnboardingIfNeeded() -> some View {
        #if os(iOS)
        self.fullScreenCover(isPresented: .constant(!hasCompletedOnboarding)) {
            OnboardingView()
        }
        #else
        self.sheet(isPresented: .constant(!hasCompletedOnboarding)) {
            OnboardingView()
        }
        #endif
    }
    
    private var hasCompletedOnboarding: Bool {
        UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
}

#Preview {
    OnboardingView()
        .environment(AuthenticationService.shared)
}