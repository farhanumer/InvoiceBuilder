import StoreKit
import SwiftUI
import Observation

@Observable
public final class SubscriptionService: @unchecked Sendable {
    public static let shared = SubscriptionService()
    
    // MARK: - Published Properties
    public private(set) var isSubscribed = false
    public private(set) var currentSubscription: SubscriptionInfo?
    public private(set) var availableProducts: [Product] = []
    public private(set) var isLoading = false
    public private(set) var error: SubscriptionError?
    
    // MARK: - Private Properties
    private var updateListenerTask: Task<Void, Error>?
    
    // Product identifiers - these need to match your App Store Connect configuration
    private let productIdentifiers: Set<String> = [
        "com.invoicebuilder.monthly",
        "com.invoicebuilder.yearly", 
        "com.invoicebuilder.lifetime"
    ]
    
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Load available subscription products from the App Store
    @MainActor
    public func loadProducts() async {
        isLoading = true
        error = nil
        
        do {
            let products = try await Product.products(for: productIdentifiers)
            availableProducts = products.sorted { product1, product2 in
                // Sort by price: monthly, yearly, lifetime
                if product1.type == .autoRenewable && product2.type == .autoRenewable {
                    return product1.price < product2.price
                } else if product1.type == .autoRenewable {
                    return true
                } else if product2.type == .autoRenewable {
                    return false
                } else {
                    return product1.price < product2.price
                }
            }
        } catch {
            self.error = .failedToLoadProducts(error)
        }
        
        isLoading = false
    }
    
    /// Purchase a subscription product
    @MainActor
    public func purchase(_ product: Product) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Handle successful purchase
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updateSubscriptionStatus()
                isLoading = false
                return true
                
            case .userCancelled:
                isLoading = false
                return false
                
            case .pending:
                isLoading = false
                error = .purchasePending
                return false
                
            @unknown default:
                isLoading = false
                error = .unknownPurchaseResult
                return false
            }
        } catch {
            isLoading = false
            self.error = .purchaseFailed(error)
            return false
        }
    }
    
    /// Restore previous purchases
    @MainActor
    public func restorePurchases() async {
        isLoading = true
        error = nil
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            self.error = .restoreFailed(error)
        }
        
        isLoading = false
    }
    
    /// Check current subscription status
    @MainActor
    public func updateSubscriptionStatus() async {
        var activeSubscription: SubscriptionInfo?
        
        // Check for active auto-renewable subscriptions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if let product = availableProducts.first(where: { $0.id == transaction.productID }) {
                    if transaction.productType == .autoRenewable {
                        // For auto-renewable subscriptions, check if it's still valid
                        if let expirationDate = transaction.expirationDate,
                           expirationDate > Date() {
                            activeSubscription = SubscriptionInfo(
                                productId: transaction.productID,
                                productName: product.displayName,
                                expirationDate: expirationDate,
                                isActive: true,
                                subscriptionType: getSubscriptionType(from: transaction.productID)
                            )
                        }
                    } else if transaction.productType == .nonConsumable {
                        // For lifetime subscriptions (non-consumable)
                        activeSubscription = SubscriptionInfo(
                            productId: transaction.productID,
                            productName: product.displayName,
                            expirationDate: nil, // Lifetime doesn't expire
                            isActive: true,
                            subscriptionType: .lifetime
                        )
                    }
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        currentSubscription = activeSubscription
        isSubscribed = activeSubscription?.isActive ?? false
    }
    
    /// Get localized price string for a product
    public func priceString(for product: Product) -> String {
        return product.displayPrice
    }
    
    /// Get subscription period description
    public func subscriptionPeriod(for product: Product) -> String {
        guard let subscription = product.subscription else {
            return "One-time purchase"
        }
        
        let period = subscription.subscriptionPeriod
        let unit = period.unit
        let value = period.value
        
        switch unit {
        case .day:
            return value == 1 ? "Daily" : "\(value) days"
        case .week:
            return value == 1 ? "Weekly" : "\(value) weeks"
        case .month:
            return value == 1 ? "Monthly" : "\(value) months"
        case .year:
            return value == 1 ? "Yearly" : "\(value) years"
        @unknown default:
            return "Unknown period"
        }
    }
    
    // MARK: - Private Methods
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Listen for transaction updates
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                    await self.updateSubscriptionStatus()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.transactionNotVerified
        case .verified(let safe):
            return safe
        }
    }
    
    private func getSubscriptionType(from productId: String) -> SubscriptionType {
        switch productId {
        case "com.invoicebuilder.monthly":
            return .monthly
        case "com.invoicebuilder.yearly":
            return .yearly
        case "com.invoicebuilder.lifetime":
            return .lifetime
        default:
            return .monthly
        }
    }
}

// MARK: - Supporting Types

public struct SubscriptionInfo {
    public let productId: String
    public let productName: String
    public let expirationDate: Date?
    public let isActive: Bool
    public let subscriptionType: SubscriptionType
    
    public var isLifetime: Bool {
        return subscriptionType == .lifetime
    }
    
    public var formattedExpirationDate: String {
        guard let expirationDate = expirationDate else {
            return "Never expires"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: expirationDate)
    }
}

public enum SubscriptionType: String, CaseIterable {
    case monthly = "monthly"
    case yearly = "yearly"
    case lifetime = "lifetime"
    
    public var displayName: String {
        switch self {
        case .monthly:
            return "Monthly"
        case .yearly:
            return "Yearly"
        case .lifetime:
            return "Lifetime"
        }
    }
    
    public var icon: String {
        switch self {
        case .monthly:
            return "calendar"
        case .yearly:
            return "calendar.badge.checkmark"
        case .lifetime:
            return "infinity"
        }
    }
}

public enum SubscriptionError: LocalizedError, Equatable {
    case failedToLoadProducts(String)
    case purchaseFailed(String)
    case purchasePending
    case restoreFailed(String)
    case transactionNotVerified
    case unknownPurchaseResult
    
    // Convert Error to String for Equatable conformance
    public static func failedToLoadProducts(_ error: Error) -> SubscriptionError {
        return .failedToLoadProducts(error.localizedDescription)
    }
    
    public static func purchaseFailed(_ error: Error) -> SubscriptionError {
        return .purchaseFailed(error.localizedDescription)
    }
    
    public static func restoreFailed(_ error: Error) -> SubscriptionError {
        return .restoreFailed(error.localizedDescription)
    }
    
    public var errorDescription: String? {
        switch self {
        case .failedToLoadProducts(let errorMsg):
            return "Failed to load subscription options: \(errorMsg)"
        case .purchaseFailed(let errorMsg):
            return "Purchase failed: \(errorMsg)"
        case .purchasePending:
            return "Purchase is pending approval. Please check back later."
        case .restoreFailed(let errorMsg):
            return "Failed to restore purchases: \(errorMsg)"
        case .transactionNotVerified:
            return "Unable to verify purchase. Please try again."
        case .unknownPurchaseResult:
            return "Unknown purchase result. Please try again."
        }
    }
}