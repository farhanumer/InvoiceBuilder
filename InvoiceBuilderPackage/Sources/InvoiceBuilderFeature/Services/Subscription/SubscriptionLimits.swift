import Foundation

/// Helper class to manage subscription limits and feature availability
public final class SubscriptionLimits: @unchecked Sendable {
    public static let shared = SubscriptionLimits()
    
    private init() {}
    
    // MARK: - Free Tier Limits
    
    /// Maximum number of invoices allowed per month for free users
    public static let freeInvoicesPerMonth = 5
    
    /// Maximum number of clients allowed for free users
    public static let freeClientsLimit = 10
    
    /// Maximum number of service items allowed for free users
    public static let freeServiceItemsLimit = 5
    
    // MARK: - Feature Availability
    
    /// Check if user can create a new invoice
    public func canCreateInvoice(currentInvoiceCount: Int) -> Bool {
        let subscriptionService = SubscriptionService.shared
        
        if subscriptionService.isSubscribed {
            return true // Unlimited for premium users
        }
        
        // For free users, check monthly limit
        let _ = Calendar.current.component(.month, from: Date())
        let _ = Calendar.current.component(.year, from: Date())
        
        // In a real implementation, you would track invoices per month
        // For demo purposes, we'll use the total count as an approximation
        return currentInvoiceCount < Self.freeInvoicesPerMonth
    }
    
    /// Check if user can create a new client
    public func canCreateClient(currentClientCount: Int) -> Bool {
        let subscriptionService = SubscriptionService.shared
        
        if subscriptionService.isSubscribed {
            return true // Unlimited for premium users
        }
        
        return currentClientCount < Self.freeClientsLimit
    }
    
    /// Check if user can create a new service item
    public func canCreateServiceItem(currentServiceItemCount: Int) -> Bool {
        let subscriptionService = SubscriptionService.shared
        
        if subscriptionService.isSubscribed {
            return true // Unlimited for premium users
        }
        
        return currentServiceItemCount < Self.freeServiceItemsLimit
    }
    
    /// Check if a specific template is available
    public func isTemplateAvailable(_ template: InvoiceTemplate) -> Bool {
        let subscriptionService = SubscriptionService.shared
        
        if subscriptionService.isSubscribed {
            return true // All templates available for premium users
        }
        
        // For free users, only basic templates are available
        // Using template name to determine if it's basic
        let freeTemplateNames = ["classic", "modern", "minimal", "clean", "simple"]
        return freeTemplateNames.contains(template.name)
    }
    
    /// Get available templates based on subscription status
    public func getAvailableTemplates() -> [InvoiceTemplate] {
        let subscriptionService = SubscriptionService.shared
        
        if subscriptionService.isSubscribed {
            // All templates for premium users - we'll return the predefined ones
            return [
                .classic, .modern, .executive, .corporate, .creative, .colorful, .artistic,
                .minimal, .clean, .simple, .consulting, .freelancer, .agency, .retail,
                .ecommerce, .wholesale, .professional, .watercolor, .geometric, .pure,
                .neat, .techBlue, .forestGreen, .crimson, .midnight, .sunrise
            ]
        }
        
        // For free users, only basic templates
        return [.classic, .modern, .minimal, .clean, .simple]
    }
    
    // MARK: - Usage Information
    
    /// Get usage information for display in UI
    public func getUsageInfo(
        invoiceCount: Int,
        clientCount: Int,
        serviceItemCount: Int
    ) -> UsageInfo {
        let subscriptionService = SubscriptionService.shared
        
        if subscriptionService.isSubscribed {
            return UsageInfo(
                invoicesUsed: invoiceCount,
                invoicesLimit: nil, // Unlimited
                clientsUsed: clientCount,
                clientsLimit: nil, // Unlimited
                serviceItemsUsed: serviceItemCount,
                serviceItemsLimit: nil, // Unlimited
                isPremium: true
            )
        } else {
            return UsageInfo(
                invoicesUsed: invoiceCount,
                invoicesLimit: Self.freeInvoicesPerMonth,
                clientsUsed: clientCount,
                clientsLimit: Self.freeClientsLimit,
                serviceItemsUsed: serviceItemCount,
                serviceItemsLimit: Self.freeServiceItemsLimit,
                isPremium: false
            )
        }
    }
}

// MARK: - Supporting Types

public struct UsageInfo {
    public let invoicesUsed: Int
    public let invoicesLimit: Int? // nil means unlimited
    public let clientsUsed: Int
    public let clientsLimit: Int? // nil means unlimited
    public let serviceItemsUsed: Int
    public let serviceItemsLimit: Int? // nil means unlimited
    public let isPremium: Bool
    
    public var invoicesRemainingText: String {
        guard let limit = invoicesLimit else { return "Unlimited" }
        let remaining = max(0, limit - invoicesUsed)
        return "\(remaining) remaining this month"
    }
    
    public var clientsRemainingText: String {
        guard let limit = clientsLimit else { return "Unlimited" }
        let remaining = max(0, limit - clientsUsed)
        return "\(remaining) remaining"
    }
    
    public var serviceItemsRemainingText: String {
        guard let limit = serviceItemsLimit else { return "Unlimited" }
        let remaining = max(0, limit - serviceItemsUsed)
        return "\(remaining) remaining"
    }
    
    public var isInvoiceLimitReached: Bool {
        guard let limit = invoicesLimit else { return false }
        return invoicesUsed >= limit
    }
    
    public var isClientLimitReached: Bool {
        guard let limit = clientsLimit else { return false }
        return clientsUsed >= limit
    }
    
    public var isServiceItemLimitReached: Bool {
        guard let limit = serviceItemsLimit else { return false }
        return serviceItemsUsed >= limit
    }
}