import Foundation

public struct InvoiceItem: Sendable, Identifiable {
    public let id: UUID
    public var name: String
    public var description: String?
    public var quantity: Decimal
    public var rate: Decimal
    public var total: Decimal
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        quantity: Decimal,
        rate: Decimal
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.quantity = quantity
        self.rate = rate
        self.total = quantity * rate
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