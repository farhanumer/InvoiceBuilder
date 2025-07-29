import Foundation

public struct Invoice: Sendable, Identifiable {
    public let id: UUID
    public var invoiceNumber: String
    public var date: Date
    public var dueDate: Date
    public var client: Client
    public var items: [InvoiceItem]
    public var status: InvoiceStatus
    public var notes: String?
    public var subtotal: Decimal
    public var taxRate: Decimal
    public var taxAmount: Decimal
    public var total: Decimal
    public var currency: Currency
    public var poNumber: String?
    public var terms: String?
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        invoiceNumber: String,
        date: Date,
        dueDate: Date,
        client: Client,
        items: [InvoiceItem] = [],
        status: InvoiceStatus = .draft,
        notes: String? = nil,
        taxRate: Decimal = 0,
        currency: Currency = .usd,
        poNumber: String? = nil,
        terms: String? = nil
    ) {
        self.id = id
        self.invoiceNumber = invoiceNumber
        self.date = date
        self.dueDate = dueDate
        self.client = client
        self.items = items
        self.status = status
        self.notes = notes
        self.taxRate = taxRate
        self.currency = currency
        self.poNumber = poNumber
        self.terms = terms
        self.createdAt = Date()
        self.updatedAt = Date()
        
        // Calculate totals
        self.subtotal = items.reduce(0) { $0 + $1.total }
        self.taxAmount = subtotal * taxRate
        self.total = subtotal + taxAmount
    }
    
    public init(from entity: InvoiceEntity) {
        self.id = entity.id
        self.invoiceNumber = entity.number
        self.date = entity.issueDate
        self.dueDate = entity.dueDate
        self.client = entity.client != nil ? Client(from: entity.client!) : Client(id: UUID(), name: "Unknown", email: "")
        self.items = entity.items.map { InvoiceItem(from: $0) }
        self.status = InvoiceStatus(rawValue: entity.status) ?? .draft
        self.notes = entity.notes
        self.currency = Currency(rawValue: entity.currency) ?? .usd
        self.poNumber = entity.poNumber
        self.terms = entity.terms
        self.createdAt = entity.createdAt
        self.updatedAt = entity.updatedAt
        
        // Use entity calculated values
        self.subtotal = entity.subtotal
        self.taxAmount = entity.taxAmount
        self.total = entity.totalAmount
        self.taxRate = entity.taxAmount > 0 ? (entity.taxAmount / entity.subtotal) : 0
    }
}

public enum InvoiceStatus: String, CaseIterable, Sendable {
    case draft = "draft"
    case sent = "sent"
    case paid = "paid"
    case overdue = "overdue"
    case cancelled = "cancelled"
    
    public var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .sent: return "Sent"
        case .paid: return "Paid"
        case .overdue: return "Overdue"
        case .cancelled: return "Cancelled"
        }
    }
}