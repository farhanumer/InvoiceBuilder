import SwiftUI
import StoreKit

public struct SubscriptionManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionService.self) private var subscriptionService
    @Environment(\.openURL) private var openURL
    
    @State private var showingPaywall = false
    @State private var showingCancellationAlert = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if subscriptionService.isSubscribed {
                        activeSubscriptionSection
                        subscriptionFeaturesSection
                        subscriptionActionsSection
                    } else {
                        noSubscriptionSection
                    }
                }
                .padding()
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Subscription")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await subscriptionService.updateSubscriptionStatus()
        }
        .sheet(isPresented: $showingPaywall) {
            SubscriptionPaywallView { 
                showingPaywall = false
            }
        }
        .alert("Manage Subscription", isPresented: $showingCancellationAlert) {
            Button("Open Settings") {
                openAppStoreSubscriptionSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To cancel or modify your subscription, you'll need to go to your App Store subscription settings.")
        }
    }
    
    @ViewBuilder
    private var activeSubscriptionSection: some View {
        VStack(spacing: 16) {
            // Status Badge
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.yellow)
                Text("InvoiceBuilder Pro")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text("ACTIVE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            
            // Subscription Details
            if let subscription = subscriptionService.currentSubscription {
                VStack(spacing: 12) {
                    InfoRow(
                        title: "Plan",
                        value: subscription.subscriptionType.displayName,
                        icon: subscription.subscriptionType.icon
                    )
                    
                    if subscription.expirationDate != nil {
                        InfoRow(
                            title: subscription.subscriptionType == .yearly ? "Renews" : "Expires",
                            value: subscription.formattedExpirationDate,
                            icon: "calendar"
                        )
                    } else {
                        InfoRow(
                            title: "Access",
                            value: "Lifetime",
                            icon: "infinity"
                        )
                    }
                    
                    InfoRow(
                        title: "Status",
                        value: subscription.isActive ? "Active" : "Expired",
                        icon: subscription.isActive ? "checkmark.circle.fill" : "xmark.circle.fill"
                    )
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var subscriptionFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Pro Features")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                FeatureBadge(icon: "infinity", title: "Unlimited Invoices", isEnabled: true)
                FeatureBadge(icon: "doc.richtext", title: "Premium Templates", isEnabled: true)
                FeatureBadge(icon: "icloud.and.arrow.up", title: "Cloud Sync", isEnabled: true)
                FeatureBadge(icon: "chart.bar.fill", title: "Advanced Analytics", isEnabled: true)
                FeatureBadge(icon: "square.and.arrow.up", title: "Export Options", isEnabled: true)
                FeatureBadge(icon: "envelope.fill", title: "Email Integration", isEnabled: true)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var subscriptionActionsSection: some View {
        VStack(spacing: 12) {
            Button {
                openAppStoreSubscriptionSettings()
            } label: {
                Label("Manage in App Store", systemImage: "app.badge")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button {
                Task {
                    await subscriptionService.restorePurchases()
                }
            } label: {
                Label("Restore Purchases", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(subscriptionService.isLoading)
            
            if subscriptionService.currentSubscription?.subscriptionType != .lifetime {
                Button {
                    showingCancellationAlert = true
                } label: {
                    Label("Cancel Subscription", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
    }
    
    @ViewBuilder
    private var noSubscriptionSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "crown")
                .font(.system(size: 64))
                .foregroundStyle(.gray)
            
            VStack(spacing: 8) {
                Text("InvoiceBuilder Free")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("You're currently using the free version of InvoiceBuilder")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Limited Features
            VStack(alignment: .leading, spacing: 16) {
                Text("Current Features")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    FeatureBadge(icon: "doc.text", title: "5 Invoices/Month", isEnabled: true)
                    FeatureBadge(icon: "doc.richtext", title: "Basic Templates", isEnabled: true)
                    FeatureBadge(icon: "icloud.and.arrow.up", title: "Cloud Sync", isEnabled: false)
                    FeatureBadge(icon: "chart.bar.fill", title: "Advanced Analytics", isEnabled: false)
                    FeatureBadge(icon: "square.and.arrow.up", title: "Export Options", isEnabled: false)
                    FeatureBadge(icon: "envelope.fill", title: "Email Integration", isEnabled: false)
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            
            Button {
                showingPaywall = true
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                    Text("Upgrade to Pro")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
    
    private func openAppStoreSubscriptionSettings() {
        #if os(iOS)
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            openURL(url)
        }
        #elseif os(macOS)
        if let url = URL(string: "macappstore://showPurchasesPage") {
            openURL(url)
        }
        #endif
    }
}

private struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 20)
            
            Text(title)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
}

private struct FeatureBadge: View {
    let icon: String
    let title: String
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(isEnabled ? .blue : .gray)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(isEnabled ? .primary : .secondary)
            
            Spacer()
            
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(isEnabled ? .green : .gray)
                .font(.caption)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isEnabled ? .green.opacity(0.1) : .gray.opacity(0.1))
        )
    }
}

#Preview {
    SubscriptionManagementView()
        .environment(SubscriptionService.shared)
}