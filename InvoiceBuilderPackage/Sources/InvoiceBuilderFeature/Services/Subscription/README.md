# InvoiceBuilder Pro Subscription System

This document outlines the complete StoreKit 2 subscription implementation for InvoiceBuilder.

## Overview

InvoiceBuilder uses a freemium model with the following tiers:

- **Free Tier**: 5 invoices/month, 10 clients, 5 service items, basic templates
- **Pro Tier**: Unlimited invoices, unlimited clients/items, all premium templates, advanced features

## Architecture

### Core Components

1. **SubscriptionService.swift** - Main StoreKit 2 service
2. **SubscriptionProducts.swift** - Product configurations and App Store Connect setup
3. **SubscriptionLimits.swift** - Usage limits and feature gating
4. **SubscriptionPaywallView.swift** - Upgrade interface
5. **SubscriptionManagementView.swift** - Subscription management
6. **SubscriptionGate.swift** - Feature gating components

### Service Layer

```swift
// Main subscription service
@Observable
public final class SubscriptionService: @unchecked Sendable {
    public static let shared = SubscriptionService()
    
    // Key properties
    public private(set) var isSubscribed = false
    public private(set) var currentSubscription: SubscriptionInfo?
    public private(set) var availableProducts: [Product] = []
}
```

## Product Configuration

### Subscription Products

| Product | Type | Duration | Price | Product ID |
|---------|------|----------|-------|------------|
| Monthly Pro | Auto-Renewable | 1 Month | $9.99 | com.invoicebuilder.monthly |
| Yearly Pro | Auto-Renewable | 1 Year | $99.99 | com.invoicebuilder.yearly |
| Lifetime Pro | Non-Consumable | Forever | $299.99 | com.invoicebuilder.lifetime |

### Savings Calculation

- **Monthly**: $9.99/month × 12 = $119.88/year
- **Yearly**: $99.99/year 
- **Savings**: $19.89/year (17% off)

## Feature Gating

### Free Tier Limits

```swift
public static let freeInvoicesPerMonth = 5
public static let freeClientsLimit = 10
public static let freeServiceItemsLimit = 5
```

### Premium Features

- Unlimited invoices, clients, and service items
- Access to all 25+ premium templates
- Cloud sync across devices
- Advanced analytics and reporting
- PDF/Excel export options
- Email integration
- Custom branding options
- Recurring invoice automation

### Usage Implementation

```swift
// Check if user can create invoice
if SubscriptionLimits.shared.canCreateInvoice(currentCount: invoices.count) {
    // Allow creation
} else {
    // Show paywall
}

// Feature gating with SwiftUI
PremiumFeatureGate(feature: .premiumTemplates) {
    AdvancedTemplateView()
}
```

## User Interface

### Paywall Features

- **Feature Showcase**: Visual grid showing premium benefits
- **Pricing Options**: Clear comparison of monthly/yearly/lifetime
- **Popular Badge**: Highlights recommended yearly plan
- **Social Proof**: Benefits-focused messaging
- **Restore Purchases**: For existing subscribers

### Subscription Management

- **Active Status**: Clear display of current subscription
- **Renewal Info**: Next billing date or lifetime access
- **Feature List**: What's included in current plan
- **Upgrade/Manage**: Direct links to App Store
- **Cancel Flow**: Guided cancellation process

## Integration Points

### App-Wide Integration

```swift
// Main app setup
@main
struct InvoiceBuilderApp: App {
    private let subscriptionService = SubscriptionService.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(subscriptionService)
        }
    }
}
```

### Settings Integration

```swift
// Settings menu item
Section("Subscription") {
    Button {
        showingSubscriptionManagement = true
    } label: {
        HStack {
            Image(systemName: subscriptionService.isSubscribed ? "crown.fill" : "crown")
            Text(subscriptionService.isSubscribed ? "InvoiceBuilder Pro" : "Upgrade to Pro")
            Spacer()
            if subscriptionService.isSubscribed {
                Text("ACTIVE").badge()
            }
        }
    }
}
```

### Invoice Creation Gating

```swift
// In InvoiceListView
Button {
    if SubscriptionLimits.shared.canCreateInvoice(currentCount: invoices.count) {
        showingNewInvoice = true
    } else {
        showingSubscriptionPaywall = true
    }
} label: {
    Image(systemName: "plus")
}
```

## Security & Verification

### StoreKit 2 Verification

```swift
private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified:
        throw SubscriptionError.transactionNotVerified
    case .verified(let safe):
        return safe
    }
}
```

### Transaction Monitoring

- Automatic transaction updates listening
- Purchase verification on app launch
- Subscription status synchronization
- Receipt validation with App Store

## Testing Strategy

### Development Testing

1. **Xcode StoreKit Configuration File**
2. **Sandbox Testing with Test Accounts**
3. **Purchase Flow Verification**
4. **Subscription Management Testing**
5. **Feature Gating Validation**

### Test Scenarios

- [ ] Purchase monthly subscription
- [ ] Purchase yearly subscription  
- [ ] Purchase lifetime access
- [ ] Restore previous purchases
- [ ] Cancel subscription
- [ ] Subscription expiration handling
- [ ] Feature access with/without subscription
- [ ] Cross-device synchronization

## Localization

### Supported Languages

- English (en-US) - Primary
- Spanish (es-ES)
- French (fr-FR)
- German (de-DE)

### Localized Content

- Product names and descriptions
- Feature descriptions
- Error messages
- UI text in paywall and management views

## Analytics & Monitoring

### Key Metrics to Track

- **Conversion Rate**: Free to paid conversion
- **Churn Rate**: Monthly/yearly subscription retention
- **Average Revenue Per User (ARPU)**
- **Lifetime Value (LTV)**
- **Feature Usage**: Which premium features drive retention

### Implementation with App Store Connect

- Subscription analytics dashboard
- Revenue tracking
- Customer retention metrics
- Geographic performance data

## App Store Connect Setup

### 1. Subscription Group Setup

- **Group Name**: InvoiceBuilder Pro
- **Reference Name**: invoice_builder_pro_group

### 2. Product Creation

For each subscription product:

1. Navigate to App Store Connect → Your App → Features → In-App Purchases
2. Create new subscription products with IDs matching SubscriptionProducts.swift
3. Configure pricing in all supported territories
4. Add localized metadata for each language
5. Set up promotional offers (optional)

### 3. Testing Setup

1. Create sandbox test user accounts
2. Configure StoreKit testing in Xcode
3. Test all purchase flows thoroughly
4. Verify subscription management works correctly

### 4. Review Submission

- Ensure app description mentions subscription features
- Include screenshots showing premium features
- Complete App Store Review questionnaire
- Provide clear subscription terms and privacy policy

## Error Handling

### Common Scenarios

```swift
public enum SubscriptionError: LocalizedError, Equatable {
    case failedToLoadProducts(String)
    case purchaseFailed(String)
    case purchasePending
    case restoreFailed(String)
    case transactionNotVerified
    case unknownPurchaseResult
}
```

### User-Friendly Messages

- Clear error descriptions for all failure cases
- Retry mechanisms for network issues
- Graceful degradation when Store services unavailable
- Help links for complex issues

## Migration & Updates

### Version Compatibility

- Maintains backward compatibility with free users
- Graceful handling of subscription changes
- Database migration for premium features
- Settings preservation across updates

### Future Enhancements

- Family Sharing support
- Corporate/Team subscriptions
- Regional pricing optimization
- Additional promotional offers
- Advanced analytics integration

## Compliance & Legal

### App Store Guidelines

- Subscription terms clearly displayed
- Cancellation policy prominent
- No alternative payment methods promoted
- Feature parity across platforms

### Privacy Considerations

- Purchase data handled securely
- No unnecessary personal data collection
- Clear privacy policy covering subscriptions
- GDPR/CCPA compliance where applicable

---

This subscription system provides a robust, user-friendly monetization strategy while maintaining excellent user experience for both free and premium users.