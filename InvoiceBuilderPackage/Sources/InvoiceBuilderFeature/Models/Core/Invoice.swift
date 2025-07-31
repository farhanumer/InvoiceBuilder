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
    
    // Computed properties
    public var isOverdue: Bool {
        status == .sent && dueDate < Date()
    }
    
    public var daysPastDue: Int {
        guard isOverdue else { return 0 }
        return Calendar.current.dateComponents([.day], from: dueDate, to: Date()).day ?? 0
    }
    
    public var formattedTotal: String {
        formatCurrency(total)
    }
    
    public var formattedSubtotal: String {
        formatCurrency(subtotal)
    }
    
    public var formattedTaxAmount: String {
        formatCurrency(taxAmount)
    }
    
    public var discountAmount: Decimal {
        items.reduce(0) { $0 + $1.discountAmount }
    }
    
    public var formattedDiscountAmount: String {
        formatCurrency(discountAmount)
    }
    
    public var paymentTerms: String? {
        terms
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.rawValue
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
    
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
    
    // MARK: - Methods
    
    public mutating func updateStatus(_ newStatus: InvoiceStatus) {
        status = newStatus
        updatedAt = Date()
    }
    
    public mutating func addItem(_ item: InvoiceItem) {
        items.append(item)
        recalculateTotals()
    }
    
    public mutating func removeItem(at index: Int) {
        guard index < items.count else { return }
        items.remove(at: index)
        recalculateTotals()
    }
    
    public mutating func recalculateTotals() {
        subtotal = items.reduce(0) { $0 + $1.total }
        taxAmount = subtotal * taxRate
        total = subtotal + taxAmount - discountAmount
        updatedAt = Date()
    }
    
    public mutating func updateTotals(subtotal: Decimal, taxAmount: Decimal, discountAmount: Decimal) {
        self.subtotal = subtotal
        self.taxAmount = taxAmount
        self.total = subtotal + taxAmount - discountAmount
        self.updatedAt = Date()
    }
    
    public func toEntity() -> InvoiceEntity {
        let entity = InvoiceEntity(
            id: id,
            number: invoiceNumber,
            issueDate: date,
            dueDate: dueDate,
            status: status.rawValue,
            currency: currency.rawValue,
            subtotal: subtotal,
            taxAmount: taxAmount,
            discountAmount: discountAmount,
            totalAmount: total,
            notes: notes,
            poNumber: poNumber,
            terms: terms
        )
        return entity
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