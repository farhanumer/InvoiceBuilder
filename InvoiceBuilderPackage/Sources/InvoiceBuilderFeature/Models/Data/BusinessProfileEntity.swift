import Foundation
import SwiftData

@Model
public final class BusinessProfileEntity {
    public var id: UUID
    public var businessName: String
    public var ownerName: String
    public var email: String
    public var phone: String?
    public var website: String?
    public var taxNumber: String?
    public var registrationNumber: String?
    public var address: AddressEntity?
    public var logoData: Data?
    public var signatureData: Data?
    public var defaultCurrency: String
    public var defaultPaymentTerms: String?
    public var invoicePrefix: String
    public var nextInvoiceNumber: Int
    public var invoiceNumberFormat: String?
    public var includeYearInInvoice: Bool = false
    public var includeMonthInInvoice: Bool = false
    public var invoiceNumberPadding: Int = 4
    public var taxRate: Decimal
    public var createdAt: Date
    public var updatedAt: Date
    
    // Relationships
    @Relationship(deleteRule: .cascade) 
    public var invoices: [InvoiceEntity] = []
    @Relationship(deleteRule: .cascade) 
    public var templates: [InvoiceTemplateEntity] = []
    @Relationship(deleteRule: .cascade) 
    public var serviceItems: [ServiceItemEntity] = []
    
    public init(
        id: UUID = UUID(),
        businessName: String,
        ownerName: String,
        email: String,
        phone: String? = nil,
        website: String? = nil,
        taxNumber: String? = nil,
        registrationNumber: String? = nil,
        address: AddressEntity? = nil,
        logoData: Data? = nil,
        signatureData: Data? = nil,
        defaultCurrency: String = "USD",
        defaultPaymentTerms: String? = nil,
        invoicePrefix: String = "INV",
        nextInvoiceNumber: Int = 1,
        invoiceNumberFormat: String? = nil,
        includeYearInInvoice: Bool = false,
        includeMonthInInvoice: Bool = false,
        invoiceNumberPadding: Int = 4,
        taxRate: Decimal = 0.0
    ) {
        self.id = id
        self.businessName = businessName
        self.ownerName = ownerName
        self.email = email
        self.phone = phone
        self.website = website
        self.taxNumber = taxNumber
        self.registrationNumber = registrationNumber
        self.address = address
        self.logoData = logoData
        self.signatureData = signatureData
        self.defaultCurrency = defaultCurrency
        self.defaultPaymentTerms = defaultPaymentTerms
        self.invoicePrefix = invoicePrefix
        self.nextInvoiceNumber = nextInvoiceNumber
        self.invoiceNumberFormat = invoiceNumberFormat
        self.includeYearInInvoice = includeYearInInvoice
        self.includeMonthInInvoice = includeMonthInInvoice
        self.invoiceNumberPadding = invoiceNumberPadding
        self.taxRate = taxRate
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}