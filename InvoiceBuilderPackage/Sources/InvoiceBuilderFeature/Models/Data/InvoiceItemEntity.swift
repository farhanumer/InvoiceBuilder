import Foundation
import SwiftData

@Model
public final class InvoiceItemEntity {
    public var id: UUID
    public var itemDescription: String
    public var quantity: Decimal
    public var unitPrice: Decimal
    public var taxRate: Decimal
    public var discountAmount: Decimal
    public var totalAmount: Decimal
    public var category: String?
    public var sku: String?
    public var notes: String?
    public var sortOrder: Int
    
    // Relationships
    @Relationship public var invoice: InvoiceEntity?
    
    public init(
        id: UUID = UUID(),
        itemDescription: String,
        quantity: Decimal = 1,
        unitPrice: Decimal = 0,
        taxRate: Decimal = 0,
        discountAmount: Decimal = 0,
        category: String? = nil,
        sku: String? = nil,
        notes: String? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.itemDescription = itemDescription
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.taxRate = taxRate
        self.discountAmount = discountAmount
        self.category = category
        self.sku = sku
        self.notes = notes
        self.sortOrder = sortOrder
        
        // Calculate total amount
        let subtotal = quantity * unitPrice
        let taxAmount = subtotal * (taxRate / 100)
        self.totalAmount = subtotal + taxAmount - discountAmount
    }
    
    public func updateTotalAmount() {
        let subtotal = quantity * unitPrice
        let taxAmount = subtotal * (taxRate / 100)
        self.totalAmount = subtotal + taxAmount - discountAmount
    }
}