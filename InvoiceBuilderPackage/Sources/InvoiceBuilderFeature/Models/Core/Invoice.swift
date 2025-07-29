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
    
    public init(
        id: UUID = UUID(),
        invoiceNumber: String,
        date: Date,
        dueDate: Date,
        client: Client,
        items: [InvoiceItem] = [],
        status: InvoiceStatus = .draft,
        notes: String? = nil,
        taxRate: Decimal = 0
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
        
        // Calculate totals
        self.subtotal = items.reduce(0) { $0 + $1.total }
        self.taxAmount = subtotal * taxRate
        self.total = subtotal + taxAmount
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