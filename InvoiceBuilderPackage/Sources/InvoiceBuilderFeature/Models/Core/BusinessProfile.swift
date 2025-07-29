import Foundation

public struct BusinessProfile: Sendable, Identifiable {
    public let id: UUID
    public var businessName: String
    public var ownerName: String
    public var email: String
    public var phone: String?
    public var website: String?
    public var address: Address?
    public var logo: Data?
    public var signature: Data?
    public var taxId: String?
    public var invoiceNumberPrefix: String
    public var nextInvoiceNumber: Int
    public var defaultTaxRate: Decimal
    public var currency: Currency
    public var paymentTerms: PaymentTerms
    
    public init(
        id: UUID = UUID(),
        businessName: String,
        ownerName: String,
        email: String,
        phone: String? = nil,
        website: String? = nil,
        address: Address? = nil,
        logo: Data? = nil,
        signature: Data? = nil,
        taxId: String? = nil,
        invoiceNumberPrefix: String = "INV",
        nextInvoiceNumber: Int = 1,
        defaultTaxRate: Decimal = 0,
        currency: Currency = .usd,
        paymentTerms: PaymentTerms = .net30
    ) {
        self.id = id
        self.businessName = businessName
        self.ownerName = ownerName
        self.email = email
        self.phone = phone
        self.website = website
        self.address = address
        self.logo = logo
        self.signature = signature
        self.taxId = taxId
        self.invoiceNumberPrefix = invoiceNumberPrefix
        self.nextInvoiceNumber = nextInvoiceNumber
        self.defaultTaxRate = defaultTaxRate
        self.currency = currency
        self.paymentTerms = paymentTerms
    }
}

public enum Currency: String, CaseIterable, Sendable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case cad = "CAD"
    case aud = "AUD"
    case jpy = "JPY"
    
    public var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .cad: return "C$"
        case .aud: return "A$"
        case .jpy: return "¥"
        }
    }
    
    public var name: String {
        switch self {
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .gbp: return "British Pound"
        case .cad: return "Canadian Dollar"
        case .aud: return "Australian Dollar"
        case .jpy: return "Japanese Yen"
        }
    }
}

public enum PaymentTerms: String, CaseIterable, Sendable {
    case immediate = "immediate"
    case net15 = "net15"
    case net30 = "net30"
    case net60 = "net60"
    case net90 = "net90"
    
    public var displayName: String {
        switch self {
        case .immediate: return "Due Immediately"
        case .net15: return "Net 15"
        case .net30: return "Net 30"
        case .net60: return "Net 60"
        case .net90: return "Net 90"
        }
    }
    
    public var days: Int {
        switch self {
        case .immediate: return 0
        case .net15: return 15
        case .net30: return 30
        case .net60: return 60
        case .net90: return 90
        }
    }
}