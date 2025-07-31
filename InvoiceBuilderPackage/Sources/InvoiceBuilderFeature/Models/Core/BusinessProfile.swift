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
    public var registrationNumber: String?
    public var invoiceNumberPrefix: String
    public var nextInvoiceNumber: Int
    public var invoiceNumberFormat: InvoiceNumberFormat
    public var includeYearInInvoiceNumber: Bool
    public var includeMonthInInvoiceNumber: Bool
    public var invoiceNumberPadding: Int
    public var defaultTaxRate: Decimal
    public var currency: Currency
    public var paymentTerms: PaymentTerms
    public var createdAt: Date
    public var updatedAt: Date
    
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
        registrationNumber: String? = nil,
        invoiceNumberPrefix: String = "INV",
        nextInvoiceNumber: Int = 1,
        invoiceNumberFormat: InvoiceNumberFormat = .sequential,
        includeYearInInvoiceNumber: Bool = false,
        includeMonthInInvoiceNumber: Bool = false,
        invoiceNumberPadding: Int = 4,
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
        self.registrationNumber = registrationNumber
        self.invoiceNumberPrefix = invoiceNumberPrefix
        self.nextInvoiceNumber = nextInvoiceNumber
        self.invoiceNumberFormat = invoiceNumberFormat
        self.includeYearInInvoiceNumber = includeYearInInvoiceNumber
        self.includeMonthInInvoiceNumber = includeMonthInInvoiceNumber
        self.invoiceNumberPadding = invoiceNumberPadding
        self.defaultTaxRate = defaultTaxRate
        self.currency = currency
        self.paymentTerms = paymentTerms
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    public init(from entity: BusinessProfileEntity) {
        self.id = entity.id
        self.businessName = entity.businessName
        self.ownerName = entity.ownerName
        self.email = entity.email
        self.phone = entity.phone
        self.website = entity.website
        self.address = entity.address != nil ? Address(from: entity.address!) : nil
        self.logo = entity.logoData
        self.signature = entity.signatureData
        self.taxId = entity.taxNumber
        self.registrationNumber = entity.registrationNumber
        self.invoiceNumberPrefix = entity.invoicePrefix
        self.nextInvoiceNumber = entity.nextInvoiceNumber
        self.invoiceNumberFormat = InvoiceNumberFormat(rawValue: entity.invoiceNumberFormat ?? "sequential") ?? .sequential
        self.includeYearInInvoiceNumber = entity.includeYearInInvoice
        self.includeMonthInInvoiceNumber = entity.includeMonthInInvoice
        self.invoiceNumberPadding = entity.invoiceNumberPadding
        self.defaultTaxRate = entity.taxRate
        self.currency = Currency(rawValue: entity.defaultCurrency) ?? .usd
        self.paymentTerms = PaymentTerms(rawValue: entity.defaultPaymentTerms ?? "net30") ?? .net30
        self.createdAt = entity.createdAt
        self.updatedAt = entity.updatedAt
    }
    
    public func generateNextInvoiceNumber() -> String {
        let date = Date()
        let formatter = DateFormatter()
        var components: [String] = [invoiceNumberPrefix]
        
        switch invoiceNumberFormat {
        case .sequential:
            // Simple sequential numbering: PREFIX-0001
            let paddedNumber = String(format: "%0\(invoiceNumberPadding)d", nextInvoiceNumber)
            components.append(paddedNumber)
            
        case .yearSequential:
            // Year-based sequential: PREFIX-2024-0001
            formatter.dateFormat = "yyyy"
            components.append(formatter.string(from: date))
            let paddedNumber = String(format: "%0\(invoiceNumberPadding)d", nextInvoiceNumber)
            components.append(paddedNumber)
            
        case .monthYearSequential:
            // Month-year sequential: PREFIX-012024-0001
            formatter.dateFormat = "MMyyyy"
            components.append(formatter.string(from: date))
            let paddedNumber = String(format: "%0\(invoiceNumberPadding)d", nextInvoiceNumber)
            components.append(paddedNumber)
            
        case .dateSequential:
            // Full date sequential: PREFIX-20240131-0001
            formatter.dateFormat = "yyyyMMdd"
            components.append(formatter.string(from: date))
            let paddedNumber = String(format: "%0\(invoiceNumberPadding)d", nextInvoiceNumber)
            components.append(paddedNumber)
            
        case .custom:
            // Custom format with optional year/month inclusion
            if includeYearInInvoiceNumber {
                formatter.dateFormat = "yyyy"
                components.append(formatter.string(from: date))
            }
            if includeMonthInInvoiceNumber {
                formatter.dateFormat = "MM"
                components.append(formatter.string(from: date))
            }
            let paddedNumber = String(format: "%0\(invoiceNumberPadding)d", nextInvoiceNumber)
            components.append(paddedNumber)
        }
        
        return components.joined(separator: "-")
    }
    
    public func previewInvoiceNumber() -> String {
        return generateNextInvoiceNumber()
    }
}

public enum InvoiceNumberFormat: String, CaseIterable, Sendable {
    case sequential = "sequential"
    case yearSequential = "year_sequential"
    case monthYearSequential = "month_year_sequential"
    case dateSequential = "date_sequential"
    case custom = "custom"
    
    public var displayName: String {
        switch self {
        case .sequential:
            return "Sequential (INV-0001)"
        case .yearSequential:
            return "Year Sequential (INV-2024-0001)"
        case .monthYearSequential:
            return "Month-Year Sequential (INV-012024-0001)"
        case .dateSequential:
            return "Date Sequential (INV-20240131-0001)"
        case .custom:
            return "Custom Format"
        }
    }
    
    public var description: String {
        switch self {
        case .sequential:
            return "Simple incremental numbering"
        case .yearSequential:
            return "Include current year in invoice number"
        case .monthYearSequential:
            return "Include month and year in invoice number"
        case .dateSequential:
            return "Include full date in invoice number"
        case .custom:
            return "Customize with year/month options"
        }
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
    
    public var locale: Locale {
        switch self {
        case .usd: return Locale(identifier: "en_US")
        case .eur: return Locale(identifier: "en_GB") // Use UK English for Euro
        case .gbp: return Locale(identifier: "en_GB")
        case .cad: return Locale(identifier: "en_CA")
        case .aud: return Locale(identifier: "en_AU")
        case .jpy: return Locale(identifier: "ja_JP")
        }
    }
    
    public var fractionDigits: Int {
        switch self {
        case .jpy: return 0 // Japanese Yen doesn't use decimal places
        default: return 2
        }
    }
    
    public func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = self.rawValue
        formatter.locale = self.locale
        formatter.maximumFractionDigits = self.fractionDigits
        formatter.minimumFractionDigits = self.fractionDigits
        
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(self.symbol)0\(self.fractionDigits > 0 ? ".00" : "")"
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