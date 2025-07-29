import SwiftUI
import SwiftData

@Observable
@MainActor
public final class InvoiceService {
    public var invoices: [Invoice] = []
    public var isLoading: Bool = false
    
    private let dataStack: SwiftDataStack
    
    public init(dataStack: SwiftDataStack = .shared) {
        self.dataStack = dataStack
    }
    
    public func loadInvoices() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let entities = try dataStack.fetchInvoices()
            invoices = entities.map { Invoice(from: $0) }
        } catch {
            print("Failed to load invoices: \(error)")
            invoices = []
        }
    }
    
    public func createInvoice(_ invoice: Invoice) async throws {
        let entity = InvoiceEntity(
            number: invoice.invoiceNumber,
            issueDate: invoice.date,
            dueDate: invoice.dueDate,
            status: invoice.status.rawValue,
            currency: invoice.currency.rawValue,
            subtotal: invoice.subtotal,
            taxAmount: invoice.taxAmount,
            totalAmount: invoice.total,
            notes: invoice.notes,
            poNumber: invoice.poNumber,
            terms: invoice.terms
        )
        
        // Find and set client relationship
        if let clientEntity = try dataStack.fetchClient(by: invoice.client.id) {
            entity.client = clientEntity
        }
        
        // Create invoice items
        for item in invoice.items {
            let itemEntity = InvoiceItemEntity(
                itemDescription: item.description,
                quantity: item.quantity,
                unitPrice: item.rate,
                taxRate: item.taxRate,
                discountAmount: item.discountAmount
            )
            itemEntity.invoice = entity
            entity.items.append(itemEntity)
            dataStack.insert(itemEntity)
        }
        
        dataStack.insert(entity)
        try dataStack.save()
        
        // Reload invoices
        await loadInvoices()
    }
    
    public func updateInvoice(_ invoice: Invoice) async throws {
        guard let entity = try dataStack.fetchInvoice(by: invoice.id) else {
            throw InvoiceServiceError.invoiceNotFound
        }
        
        entity.number = invoice.invoiceNumber
        entity.issueDate = invoice.date
        entity.dueDate = invoice.dueDate
        entity.status = invoice.status.rawValue
        entity.currency = invoice.currency.rawValue
        entity.subtotal = invoice.subtotal
        entity.taxAmount = invoice.taxAmount
        entity.totalAmount = invoice.total
        entity.notes = invoice.notes
        entity.poNumber = invoice.poNumber
        entity.terms = invoice.terms
        entity.updatedAt = Date()
        
        // Update client relationship
        if let clientEntity = try dataStack.fetchClient(by: invoice.client.id) {
            entity.client = clientEntity
        }
        
        // Remove existing items
        for item in entity.items {
            dataStack.delete(item)
        }
        entity.items.removeAll()
        
        // Add updated items
        for item in invoice.items {
            let itemEntity = InvoiceItemEntity(
                itemDescription: item.description,
                quantity: item.quantity,
                unitPrice: item.rate,
                taxRate: item.taxRate,
                discountAmount: item.discountAmount
            )
            itemEntity.invoice = entity
            entity.items.append(itemEntity)
            dataStack.insert(itemEntity)
        }
        
        try dataStack.save()
        
        // Reload invoices
        await loadInvoices()
    }
    
    public func deleteInvoice(_ invoice: Invoice) async throws {
        guard let entity = try dataStack.fetchInvoice(by: invoice.id) else {
            throw InvoiceServiceError.invoiceNotFound
        }
        
        dataStack.delete(entity)
        try dataStack.save()
        
        // Remove from local array
        invoices.removeAll { $0.id == invoice.id }
    }
    
    public func generateInvoiceNumber() async -> String {
        do {
            let businessProfiles = try dataStack.fetchBusinessProfiles()
            if let profile = businessProfiles.first {
                let number = "\(profile.invoicePrefix)-\(String(format: "%04d", profile.nextInvoiceNumber))"
                profile.nextInvoiceNumber += 1
                try dataStack.save()
                return number
            }
        } catch {
            print("Failed to generate invoice number: \(error)")
        }
        
        // Fallback to simple numbering
        let nextNumber = invoices.count + 1
        return "INV-\(String(format: "%04d", nextNumber))"
    }
}

public enum InvoiceServiceError: Error, LocalizedError {
    case invoiceNotFound
    case invalidData
    case saveFailed
    
    public var errorDescription: String? {
        switch self {
        case .invoiceNotFound:
            return "Invoice not found"
        case .invalidData:
            return "Invalid invoice data"
        case .saveFailed:
            return "Failed to save invoice"
        }
    }
}