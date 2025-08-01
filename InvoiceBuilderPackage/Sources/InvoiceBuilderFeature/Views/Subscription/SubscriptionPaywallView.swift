import SwiftUI
import StoreKit

public struct SubscriptionPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionService.self) private var subscriptionService
    
    @State private var selectedProduct: Product?
    @State private var showingError = false
    @State private var showingPurchaseSuccess = false
    
    private var isPresented: Bool
    private let onSubscriptionComplete: (() -> Void)?
    
    public init(isPresented: Bool = true, onSubscriptionComplete: (() -> Void)? = nil) {
        self.isPresented = isPresented
        self.onSubscriptionComplete = onSubscriptionComplete
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    featuresSection
                    subscriptionOptionsSection
                    footerSection
                }
                .padding()
                .frame(maxWidth: 600) // Reasonable width on larger screens
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("InvoiceBuilder Pro")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                if isPresented {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Not Now") {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Restore") {
                        Task {
                            await subscriptionService.restorePurchases()
                            if subscriptionService.isSubscribed {
                                showingPurchaseSuccess = true
                            }
                        }
                    }
                    .disabled(subscriptionService.isLoading)
                }
            }
        }
        .task {
            if subscriptionService.availableProducts.isEmpty {
                await subscriptionService.loadProducts()
            }
        }
        .alert("Subscription Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(subscriptionService.error?.errorDescription ?? "An unknown error occurred")
        }
        .alert("Welcome to Pro!", isPresented: $showingPurchaseSuccess) {
            Button("Continue") {
                onSubscriptionComplete?()
                dismiss()
            }
        } message: {
            Text("Your subscription is now active. Enjoy unlimited access to all premium features!")
        }
        .onChange(of: subscriptionService.error) { _, error in
            showingError = error != nil
        }
        .onChange(of: subscriptionService.isSubscribed) { _, isSubscribed in
            if isSubscribed {
                showingPurchaseSuccess = true
            }
        }
        .overlay {
            if subscriptionService.isLoading {
                LoadingOverlay()
            }
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow)
                .shadow(color: .yellow.opacity(0.3), radius: 10)
            
            Text("Unlock InvoiceBuilder Pro")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Get unlimited invoices, advanced templates, and premium features")
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Premium Features")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                FeatureCard(
                    icon: "infinity",
                    title: "Unlimited Invoices",
                    description: "Create as many invoices as you need"
                )
                
                FeatureCard(
                    icon: "doc.richtext",
                    title: "Premium Templates",
                    description: "Access to all professional templates"
                )
                
                FeatureCard(
                    icon: "icloud.and.arrow.up",
                    title: "Cloud Sync",
                    description: "Sync data across all your devices"
                )
                
                FeatureCard(
                    icon: "chart.bar.fill",
                    title: "Advanced Analytics",
                    description: "Detailed business insights and reports"
                )
                
                FeatureCard(
                    icon: "square.and.arrow.up",
                    title: "Export Options",
                    description: "PDF, Excel, and other export formats"
                )
                
                FeatureCard(
                    icon: "envelope.fill",
                    title: "Email Integration",
                    description: "Send invoices directly from the app"
                )
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var subscriptionOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Your Plan")
                .font(.headline)
                .fontWeight(.semibold)
            
            if subscriptionService.availableProducts.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading subscription options...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(subscriptionService.availableProducts, id: \.id) { product in
                        SubscriptionOptionCard(
                            product: product,
                            isSelected: selectedProduct?.id == product.id,
                            subscriptionService: subscriptionService
                        ) {
                            selectedProduct = product
                            Task {
                                let success = await subscriptionService.purchase(product)
                                if success {
                                    showingPurchaseSuccess = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("✓ Cancel anytime")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("Subscriptions automatically renew unless cancelled 24 hours before the end of the current period.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

private struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(height: 30)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct SubscriptionOptionCard: View {
    let product: Product
    let isSelected: Bool
    let subscriptionService: SubscriptionService
    let onPurchase: () -> Void
    
    var body: some View {
        Button(action: onPurchase) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if isPopularPlan {
                            Text("POPULAR")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.orange)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(subscriptionService.subscriptionPeriod(for: product))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if let subscription = product.subscription {
                        Text(product.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    if let subscription = product.subscription,
                       subscription.subscriptionPeriod.unit == .year {
                        if let monthlyEquivalent = calculateMonthlyEquivalent() {
                            Text("\(monthlyEquivalent)/month")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var isPopularPlan: Bool {
        // Mark yearly plan as popular
        return product.id.contains("yearly")
    }
    
    private func calculateMonthlyEquivalent() -> String? {
        guard let subscription = product.subscription,
              subscription.subscriptionPeriod.unit == .year else {
            return nil
        }
        
        let yearlyPrice = product.price
        let monthlyPrice = yearlyPrice / 12
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD" // Default to USD for now
        
        return formatter.string(from: monthlyPrice as NSDecimalNumber)
    }
}

#Preview {
    SubscriptionPaywallView()
        .environment(SubscriptionService.shared)
}