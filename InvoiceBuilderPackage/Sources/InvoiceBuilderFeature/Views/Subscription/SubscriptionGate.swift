import SwiftUI

/// A view that conditionally shows content based on subscription status
public struct SubscriptionGate<Content: View, FallbackContent: View>: View {
    @Environment(SubscriptionService.self) private var subscriptionService
    
    private let requiredFeature: PremiumFeature
    private let content: () -> Content
    private let fallbackContent: () -> FallbackContent
    
    public init(
        requiredFeature: PremiumFeature,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder fallbackContent: @escaping () -> FallbackContent
    ) {
        self.requiredFeature = requiredFeature
        self.content = content
        self.fallbackContent = fallbackContent
    }
    
    public var body: some View {
        if subscriptionService.isSubscribed || requiredFeature.isAvailableInFree {
            content()
        } else {
            fallbackContent()
        }
    }
}

/// A simpler subscription gate that shows a premium prompt when not subscribed
public struct PremiumFeatureGate<Content: View>: View {
    @Environment(SubscriptionService.self) private var subscriptionService
    
    private let feature: PremiumFeature
    private let content: () -> Content
    @State private var showingPaywall = false
    
    public init(
        feature: PremiumFeature,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.feature = feature
        self.content = content
    }
    
    public var body: some View {
        if subscriptionService.isSubscribed || feature.isAvailableInFree {
            content()
        } else {
            PremiumPromptCard(feature: feature) {
                showingPaywall = true
            }
            .sheet(isPresented: $showingPaywall) {
                SubscriptionPaywallView {
                    showingPaywall = false
                }
            }
        }
    }
}

/// A view that shows a premium upgrade prompt
private struct PremiumPromptCard: View {
    let feature: PremiumFeature
    let onUpgrade: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 32))
                .foregroundStyle(.yellow)
            
            VStack(spacing: 8) {
                Text(feature.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                onUpgrade()
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
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

/// Enum defining all premium features in the app
public enum PremiumFeature: String, CaseIterable {
    case unlimitedInvoices = "unlimited_invoices"
    case premiumTemplates = "premium_templates"
    case cloudSync = "cloud_sync"
    case advancedAnalytics = "advanced_analytics"
    case exportOptions = "export_options"
    case emailIntegration = "email_integration"
    case customBranding = "custom_branding"
    case recurringInvoices = "recurring_invoices"
    
    public var displayName: String {
        switch self {
        case .unlimitedInvoices:
            return "Unlimited Invoices"
        case .premiumTemplates:
            return "Premium Templates"
        case .cloudSync:
            return "Cloud Sync"
        case .advancedAnalytics:
            return "Advanced Analytics"
        case .exportOptions:
            return "Export Options"
        case .emailIntegration:
            return "Email Integration"
        case .customBranding:
            return "Custom Branding"
        case .recurringInvoices:
            return "Recurring Invoices"
        }
    }
    
    public var description: String {
        switch self {
        case .unlimitedInvoices:
            return "Create unlimited invoices without restrictions"
        case .premiumTemplates:
            return "Access all professional invoice templates"
        case .cloudSync:
            return "Sync your data across all devices"
        case .advancedAnalytics:
            return "Detailed business insights and reports"
        case .exportOptions:
            return "Export to PDF, Excel, and other formats"
        case .emailIntegration:
            return "Send invoices directly from the app"
        case .customBranding:
            return "Add your logo and custom branding"
        case .recurringInvoices:
            return "Set up automatic recurring invoices"
        }
    }
    
    public var icon: String {
        switch self {
        case .unlimitedInvoices:
            return "infinity"
        case .premiumTemplates:
            return "doc.richtext"
        case .cloudSync:
            return "icloud.and.arrow.up"
        case .advancedAnalytics:
            return "chart.bar.fill"
        case .exportOptions:
            return "square.and.arrow.up"
        case .emailIntegration:
            return "envelope.fill"
        case .customBranding:
            return "paintbrush.fill"
        case .recurringInvoices:
            return "arrow.clockwise"
        }
    }
    
    /// Whether this feature is available in the free tier
    public var isAvailableInFree: Bool {
        switch self {
        case .unlimitedInvoices, .premiumTemplates, .cloudSync, 
             .advancedAnalytics, .exportOptions, .emailIntegration,
             .customBranding, .recurringInvoices:
            return false
        }
    }
}

/// Helper function to check if a premium feature is available
public func isPremiumFeatureAvailable(_ feature: PremiumFeature) -> Bool {
    return SubscriptionService.shared.isSubscribed || feature.isAvailableInFree
}

/// Helper view modifier to conditionally disable features based on subscription
public struct PremiumFeatureModifier: ViewModifier {
    @Environment(SubscriptionService.self) private var subscriptionService
    let feature: PremiumFeature
    let onPremiumRequired: () -> Void
    
    public func body(content: Content) -> some View {
        content
            .disabled(!subscriptionService.isSubscribed && !feature.isAvailableInFree)
            .onTapGesture {
                if !subscriptionService.isSubscribed && !feature.isAvailableInFree {
                    onPremiumRequired()
                }
            }
    }
}

extension View {
    /// Apply premium feature gating to any view
    public func premiumFeature(
        _ feature: PremiumFeature,
        onPremiumRequired: @escaping () -> Void = {}
    ) -> some View {
        self.modifier(PremiumFeatureModifier(feature: feature, onPremiumRequired: onPremiumRequired))
    }
}

#Preview {
    VStack(spacing: 20) {
        // Example of a premium feature gate
        PremiumFeatureGate(feature: .premiumTemplates) {
            Text("This is premium content")
                .padding()
                .background(.blue.opacity(0.1))
                .cornerRadius(8)
        }
        
        // Example of conditional content
        SubscriptionGate(requiredFeature: .unlimitedInvoices) {
            Text("Unlimited invoices available!")
                .foregroundStyle(.green)
        } fallbackContent: {
            Text("Upgrade to get unlimited invoices")
                .foregroundStyle(.secondary)
        }
    }
    .padding()
    .environment(SubscriptionService.shared)
}