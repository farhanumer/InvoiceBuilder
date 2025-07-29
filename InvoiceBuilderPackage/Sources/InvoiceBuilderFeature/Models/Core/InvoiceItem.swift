import Foundation

public struct InvoiceItem: Sendable, Identifiable {
    public let id: UUID
    public var name: String
    public var description: String
    public var quantity: Decimal
    public var rate: Decimal
    public var taxRate: Decimal
    public var discountAmount: Decimal
    public var total: Decimal
    public var category: String?
    public var sku: String?
    public var notes: String?
    public var sortOrder: Int
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        quantity: Decimal,
        rate: Decimal,
        taxRate: Decimal = 0,
        discountAmount: Decimal = 0,
        category: String? = nil,
        sku: String? = nil,      
        notes: String? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.quantity = quantity
        self.rate = rate
        self.taxRate = taxRate
        self.discountAmount = discountAmount
        self.category = category
        self.sku = sku
        self.notes = notes
        self.sortOrder = sortOrder
        
        // Calculate total with tax and discount
        let subtotal = quantity * rate
        let taxAmount = subtotal * (taxRate / 100)
        self.total = subtotal + taxAmount - discountAmount
    }
    
    public init(from entity: InvoiceItemEntity) {
        self.id = entity.id
        self.name = entity.itemDescription // Entity uses 'itemDescription' for the name
        self.description = entity.itemDescription
        self.quantity = entity.quantity
        self.rate = entity.unitPrice
        self.taxRate = entity.taxRate
        self.discountAmount = entity.discountAmount
        self.total = entity.totalAmount
        self.category = entity.category
        self.sku = entity.sku
        self.notes = entity.notes
        self.sortOrder = entity.sortOrder
    }
    
    public var subtotal: Decimal {
        quantity * rate
    }
    
    public var taxAmount: Decimal {
        subtotal * (taxRate / 100)
    }
    
    public mutating func updateTotal() {
        let subtotal = quantity * rate
        let taxAmount = subtotal * (taxRate / 100)
        self.total = subtotal + taxAmount - discountAmount
    }
}

public struct ServiceItem: Sendable, Identifiable {
    public let id: UUID
    public var name: String
    public var description: String?
    public var defaultRate: Decimal
    public var category: String?
    public var isActive: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        defaultRate: Decimal,
        category: String? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.defaultRate = defaultRate
        self.category = category
        self.isActive = isActive
    }
}