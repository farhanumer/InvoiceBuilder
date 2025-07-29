import Foundation
import SwiftData

@Model
public final class InvoiceEntity {
    public var id: UUID
    public var number: String
    public var issueDate: Date
    public var dueDate: Date
    public var status: String
    public var currency: String
    public var subtotal: Decimal
    public var taxAmount: Decimal
    public var discountAmount: Decimal
    public var totalAmount: Decimal
    public var notes: String?
    public var poNumber: String?
    public var terms: String?
    public var createdAt: Date
    public var updatedAt: Date
    
    // Relationships
    @Relationship(deleteRule: .cascade) public var items: [InvoiceItemEntity]
    @Relationship public var client: ClientEntity?
    @Relationship public var businessProfile: BusinessProfileEntity?
    @Relationship public var template: InvoiceTemplateEntity?
    
    public init(
        id: UUID = UUID(),
        number: String,
        issueDate: Date = Date(),
        dueDate: Date,
        status: String = "draft",
        currency: String = "USD",
        subtotal: Decimal = 0,
        taxAmount: Decimal = 0,
        discountAmount: Decimal = 0,
        totalAmount: Decimal = 0,
        notes: String? = nil,
        poNumber: String? = nil,
        terms: String? = nil
    ) {
        self.id = id
        self.number = number
        self.issueDate = issueDate
        self.dueDate = dueDate
        self.status = status
        self.currency = currency
        self.subtotal = subtotal
        self.taxAmount = taxAmount
        self.discountAmount = discountAmount
        self.totalAmount = totalAmount
        self.notes = notes
        self.poNumber = poNumber
        self.terms = terms
        self.createdAt = Date()
        self.updatedAt = Date()
        self.items = []
    }
}