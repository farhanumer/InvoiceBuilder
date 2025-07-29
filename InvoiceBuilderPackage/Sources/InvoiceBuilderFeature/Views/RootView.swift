import SwiftUI

public struct RootView: View {
    @Environment(AppState.self) private var appState
    
    public var body: some View {
        Group {
            if appState.isAuthenticated {
                if appState.hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: appState.hasCompletedOnboarding)
    }
    
    public init() {}
}

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
            
            InvoicesView()
                .tabItem {
                    Label("Invoices", systemImage: "doc.text.fill")
                }
            
            ClientsView()
                .tabItem {
                    Label("Clients", systemImage: "person.2.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

// Placeholder views for the main navigation
struct DashboardView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Welcome to Invoice Builder")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct InvoicesView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Invoices")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Manage your invoices")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Invoices")
        }
    }
}

struct ClientsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Clients")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Manage your clients")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Clients")
        }
    }
}

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if let user = appState.currentUser {
                    VStack {
                        Text("Signed in as:")
                        Text(user.name)
                            .fontWeight(.semibold)
                        Text(user.email)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Button("Sign Out") {
                    appState.signOut()
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Settings")
        }
    }
}

struct AuthenticationView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                VStack(spacing: 10) {
                    Text("Invoice Builder")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Professional invoicing made simple")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 15) {
                    Button("Sign In with Apple") {
                        // Simulate sign in
                        let user = User(id: "1", name: "Demo User", email: "demo@example.com")
                        appState.signIn(user: user)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    
                    Button("Sign In with Google") {
                        // Simulate sign in
                        let user = User(id: "2", name: "Google User", email: "google@example.com")
                        appState.signIn(user: user)
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    
                    Button("Continue with Email") {
                        // Simulate sign in
                        let user = User(id: "3", name: "Email User", email: "email@example.com")
                        appState.signIn(user: user)
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .padding()
        }
    }
}

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Welcome to Invoice Builder!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 20) {
                    FeatureRow(icon: "doc.text.fill", title: "Create Invoices", description: "Professional templates in minutes")
                    FeatureRow(icon: "person.2.fill", title: "Manage Clients", description: "Keep track of all your customers")
                    FeatureRow(icon: "chart.bar.fill", title: "Track Revenue", description: "Monitor your business growth")
                }
                
                Button("Complete Setup") {
                    appState.completeOnboarding()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding()
            .navigationTitle("Getting Started")
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}