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
    public var taxRate: Decimal
    public var createdAt: Date
    public var updatedAt: Date
    
    // Relationships
    @Relationship(inverse: \InvoiceEntity.businessProfile) public var invoices: [InvoiceEntity]
    @Relationship(inverse: \InvoiceTemplateEntity.businessProfile) public var templates: [InvoiceTemplateEntity]
    
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
        self.taxRate = taxRate
        self.createdAt = Date()
        self.updatedAt = Date()
        self.invoices = []
        self.templates = []
    }
}