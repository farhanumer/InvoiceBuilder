import Foundation

/// Configuration for subscription products
/// These should match the product identifiers configured in App Store Connect
public struct SubscriptionProducts: Sendable {
    
    // MARK: - Product Identifiers
    
    /// Monthly subscription product identifier
    public static let monthlyProductId = "com.invoicebuilder.monthly"
    
    /// Yearly subscription product identifier  
    public static let yearlyProductId = "com.invoicebuilder.yearly"
    
    /// Lifetime subscription product identifier
    public static let lifetimeProductId = "com.invoicebuilder.lifetime"
    
    /// All product identifiers
    public static let allProductIds: Set<String> = [
        monthlyProductId,
        yearlyProductId,
        lifetimeProductId
    ]
    
    // MARK: - Product Configurations
    
    /// Product configuration for App Store Connect setup
    public struct ProductConfiguration: Sendable {
        public let identifier: String
        public let type: ProductType
        public let referenceName: String
        public let displayName: String
        public let description: String
        public let price: Decimal
        public let subscriptionDuration: SubscriptionDuration?
        public let localizations: [String: ProductLocalization]
        
        public init(
            identifier: String,
            type: ProductType,
            referenceName: String,
            displayName: String,
            description: String,
            price: Decimal,
            subscriptionDuration: SubscriptionDuration? = nil,
            localizations: [String: ProductLocalization] = [:]
        ) {
            self.identifier = identifier
            self.type = type
            self.referenceName = referenceName
            self.displayName = displayName
            self.description = description
            self.price = price
            self.subscriptionDuration = subscriptionDuration
            self.localizations = localizations
        }
    }
    
    public enum ProductType: Sendable {
        case autoRenewableSubscription
        case nonConsumable
    }
    
    public enum SubscriptionDuration: Sendable {
        case oneMonth
        case oneYear
    }
    
    public struct ProductLocalization: Sendable {
        public let displayName: String
        public let description: String
        
        public init(displayName: String, description: String) {
            self.displayName = displayName
            self.description = description
        }
    }
    
    // MARK: - Predefined Products
    
    /// Monthly subscription configuration
    public static let monthlyProduct = ProductConfiguration(
        identifier: monthlyProductId,
        type: .autoRenewableSubscription,
        referenceName: "InvoiceBuilder Pro Monthly",
        displayName: "Monthly Pro",
        description: "Get unlimited invoices, premium templates, and all pro features for one month.",
        price: 9.99,
        subscriptionDuration: .oneMonth,
        localizations: [
            "en-US": ProductLocalization(
                displayName: "Monthly Pro",
                description: "Get unlimited invoices, premium templates, and all pro features for one month."
            ),
            "es-ES": ProductLocalization(
                displayName: "Pro Mensual",
                description: "Obtén facturas ilimitadas, plantillas premium y todas las funciones pro por un mes."
            ),
            "fr-FR": ProductLocalization(
                displayName: "Pro Mensuel",
                description: "Obtenez des factures illimitées, des modèles premium et toutes les fonctionnalités pro pour un mois."
            ),
            "de-DE": ProductLocalization(
                displayName: "Pro Monatlich",
                description: "Erhalten Sie unbegrenzte Rechnungen, Premium-Vorlagen und alle Pro-Funktionen für einen Monat."
            )
        ]
    )
    
    /// Yearly subscription configuration
    public static let yearlyProduct = ProductConfiguration(
        identifier: yearlyProductId,
        type: .autoRenewableSubscription,
        referenceName: "InvoiceBuilder Pro Yearly",
        displayName: "Yearly Pro",
        description: "Get unlimited invoices, premium templates, and all pro features for one year. Best value!",
        price: 99.99,
        subscriptionDuration: .oneYear,
        localizations: [
            "en-US": ProductLocalization(
                displayName: "Yearly Pro",
                description: "Get unlimited invoices, premium templates, and all pro features for one year. Best value!"
            ),
            "es-ES": ProductLocalization(
                displayName: "Pro Anual",
                description: "Obtén facturas ilimitadas, plantillas premium y todas las funciones pro por un año. ¡La mejor oferta!"
            ),
            "fr-FR": ProductLocalization(
                displayName: "Pro Annuel",
                description: "Obtenez des factures illimitées, des modèles premium et toutes les fonctionnalités pro pour un an. Meilleure valeur!"
            ),
            "de-DE": ProductLocalization(
                displayName: "Pro Jährlich",
                description: "Erhalten Sie unbegrenzte Rechnungen, Premium-Vorlagen und alle Pro-Funktionen für ein Jahr. Bester Wert!"
            )
        ]
    )
    
    /// Lifetime subscription configuration
    public static let lifetimeProduct = ProductConfiguration(
        identifier: lifetimeProductId,
        type: .nonConsumable,
        referenceName: "InvoiceBuilder Pro Lifetime",
        displayName: "Lifetime Pro",
        description: "Get unlimited invoices, premium templates, and all pro features forever. One-time purchase.",
        price: 299.99,
        localizations: [
            "en-US": ProductLocalization(
                displayName: "Lifetime Pro",
                description: "Get unlimited invoices, premium templates, and all pro features forever. One-time purchase."
            ),
            "es-ES": ProductLocalization(
                displayName: "Pro de por Vida",
                description: "Obtén facturas ilimitadas, plantillas premium y todas las funciones pro para siempre. Compra única."
            ),
            "fr-FR": ProductLocalization(
                displayName: "Pro à Vie",
                description: "Obtenez des factures illimitées, des modèles premium et toutes les fonctionnalités pro pour toujours. Achat unique."
            ),
            "de-DE": ProductLocalization(
                displayName: "Pro Lebenslang",
                description: "Erhalten Sie unbegrenzte Rechnungen, Premium-Vorlagen und alle Pro-Funktionen für immer. Einmaliger Kauf."
            )
        ]
    )
    
    /// All product configurations
    public static let allProducts: [ProductConfiguration] = [
        monthlyProduct,
        yearlyProduct,
        lifetimeProduct
    ]
    
    // MARK: - Subscription Group Configuration
    
    /// Subscription group information for App Store Connect
    public struct SubscriptionGroup: Sendable {
        public let name: String
        public let referenceName: String
        public let products: [ProductConfiguration]
        
        public init(name: String, referenceName: String, products: [ProductConfiguration]) {
            self.name = name
            self.referenceName = referenceName
            self.products = products
        }
    }
    
    /// Main subscription group configuration
    public static let proSubscriptionGroup = SubscriptionGroup(
        name: "InvoiceBuilder Pro",
        referenceName: "invoice_builder_pro_group",
        products: [monthlyProduct, yearlyProduct]
    )
    
    // MARK: - Promotional Offers
    
    /// Promotional offer configuration
    public struct PromotionalOffer: Sendable {
        public let productId: String
        public let offerId: String
        public let referenceName: String
        public let discountType: DiscountType
        public let numberOfPeriods: Int
        public let subscriptionPeriod: SubscriptionPeriod
        public let price: Decimal
        
        public enum DiscountType: Sendable {
            case payAsYouGo
            case payUpFront
            case freeTrial
        }
        
        public enum SubscriptionPeriod: Sendable {
            case oneWeek
            case oneMonth
            case twoMonths
            case threeMonths
            case sixMonths
            case oneYear
        }
    }
    
    /// Free trial offer for monthly subscription
    public static let monthlyFreeTrial = PromotionalOffer(
        productId: monthlyProductId,
        offerId: "monthly_7_day_trial",
        referenceName: "Monthly 7-Day Free Trial",
        discountType: .freeTrial,
        numberOfPeriods: 1,
        subscriptionPeriod: .oneWeek,
        price: 0.00
    )
    
    /// Introductory offer for yearly subscription
    public static let yearlyIntroOffer = PromotionalOffer(
        productId: yearlyProductId,
        offerId: "yearly_first_month_50_off",
        referenceName: "Yearly First Month 50% Off",
        discountType: .payAsYouGo,
        numberOfPeriods: 1,
        subscriptionPeriod: .oneMonth,
        price: 4.99
    )
    
    // MARK: - Helper Functions
    
    /// Get product configuration by identifier
    public static func productConfiguration(for identifier: String) -> ProductConfiguration? {
        return allProducts.first { $0.identifier == identifier }
    }
    
    /// Get localized product information
    public static func localizedProduct(
        for identifier: String, 
        locale: String = "en-US"
    ) -> ProductLocalization? {
        guard let product = productConfiguration(for: identifier) else { return nil }
        return product.localizations[locale] ?? product.localizations["en-US"]
    }
    
    /// Calculate savings for yearly vs monthly
    public static func yearlySavings() -> (amount: Decimal, percentage: Int) {
        let monthlyTotal = monthlyProduct.price * Decimal(12)
        let yearlyPrice = yearlyProduct.price
        let savings = monthlyTotal - yearlyPrice
        let percentage = Int(truncating: ((savings / monthlyTotal) * Decimal(100)) as NSDecimalNumber)
        return (savings, percentage)
    }
    
    /// Format price for display
    public static func formatPrice(_ price: Decimal, currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: price as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - App Store Connect Setup Guide

/*
 APP STORE CONNECT SETUP INSTRUCTIONS:
 
 1. CREATE SUBSCRIPTION GROUP:
    - Name: InvoiceBuilder Pro
    - Reference Name: invoice_builder_pro_group
 
 2. CREATE AUTO-RENEWABLE SUBSCRIPTIONS:
 
    Monthly Subscription:
    - Product ID: com.invoicebuilder.monthly
    - Reference Name: InvoiceBuilder Pro Monthly  
    - Subscription Duration: 1 Month
    - Price: $9.99 USD
    - Add localizations for ES, FR, DE
    
    Yearly Subscription:
    - Product ID: com.invoicebuilder.yearly
    - Reference Name: InvoiceBuilder Pro Yearly
    - Subscription Duration: 1 Year  
    - Price: $99.99 USD
    - Add localizations for ES, FR, DE
 
 3. CREATE NON-CONSUMABLE PRODUCT:
 
    Lifetime Purchase:
    - Product ID: com.invoicebuilder.lifetime
    - Reference Name: InvoiceBuilder Pro Lifetime
    - Type: Non-Consumable
    - Price: $299.99 USD
    - Add localizations for ES, FR, DE
 
 4. SETUP PROMOTIONAL OFFERS (Optional):
    - 7-day free trial for monthly
    - First month 50% off for yearly
 
 5. SETUP TESTING:
    - Create sandbox test users
    - Test purchase flows
    - Test restore purchases
    - Test subscription management
 
 6. PRIVACY & COMPLIANCE:
    - Add privacy policy URL
    - Complete App Store Review questionnaire
    - Ensure compliance with subscription guidelines
 
 7. SUBMISSION:
    - Submit for App Store review
    - Ensure subscription terms are clear in app description
    - Include screenshots showing subscription features
*/