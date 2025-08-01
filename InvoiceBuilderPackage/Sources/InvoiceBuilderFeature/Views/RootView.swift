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

// Main navigation views using actual implementations

struct InvoicesView: View {
    var body: some View {
        InvoiceListView()
    }
}

struct ClientsView: View {
    var body: some View {
        ClientListView()
    }
}

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(SubscriptionService.self) private var subscriptionService
    @State private var showingBusinessProfile = false
    @State private var showingServiceItems = false
    @State private var showingTemplateSelection = false
    @State private var showingSubscriptionManagement = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Business") {
                    Button {
                        showingBusinessProfile = true
                    } label: {
                        HStack {
                            Image(systemName: "building.2.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Business Profile")
                                    .foregroundStyle(.primary)
                                Text("Manage your business information")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    
                    Button {
                        showingServiceItems = true
                    } label: {
                        HStack {
                            Image(systemName: "list.clipboard.fill")
                                .foregroundStyle(.green)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Service Items")
                                    .foregroundStyle(.primary)
                                Text("Manage your reusable service items")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    
                    Button {
                        showingTemplateSelection = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(.purple)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Invoice Templates")
                                    .foregroundStyle(.primary)
                                Text("Browse and customize invoice templates")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                
                Section("Subscription") {
                    Button {
                        showingSubscriptionManagement = true
                    } label: {
                        HStack {
                            Image(systemName: subscriptionService.isSubscribed ? "crown.fill" : "crown")
                                .foregroundStyle(subscriptionService.isSubscribed ? .yellow : .orange)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(subscriptionService.isSubscribed ? "InvoiceBuilder Pro" : "Upgrade to Pro")
                                    .foregroundStyle(.primary)
                                if subscriptionService.isSubscribed {
                                    if let subscription = subscriptionService.currentSubscription {
                                        Text(subscription.subscriptionType == .lifetime ? "Lifetime Access" : "Active until \(subscription.formattedExpirationDate)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("Premium features active")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                } else {
                                    Text("Unlock unlimited invoices and premium features")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if subscriptionService.isSubscribed {
                                Text("ACTIVE")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.green)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                
                Section("Account") {
                    if let user = appState.currentUser {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Signed in as:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(user.name)
                                .fontWeight(.semibold)
                            Text(user.email)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button("Sign Out", role: .destructive) {
                        appState.signOut()
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingBusinessProfile) {
                BusinessProfileView()
            }
            .sheet(isPresented: $showingServiceItems) {
                ItemsListView()
            }
            .sheet(isPresented: $showingTemplateSelection) {
                TemplateSelectionView { template in
                    print("Selected template: \(template.displayName)")
                }
            }
            .sheet(isPresented: $showingSubscriptionManagement) {
                SubscriptionManagementView()
            }
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

// OnboardingView moved to Views/Onboarding/OnboardingView.swift

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