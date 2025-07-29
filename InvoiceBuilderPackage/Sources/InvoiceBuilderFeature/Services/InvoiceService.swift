import SwiftUI

@Observable
@MainActor
public final class InvoiceService {
    public var invoices: [Invoice] = []
    public var isLoading: Bool = false
    
    public init() {}
    
    public func loadInvoices() async {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Load from persistent storage
        // Simulate network delay
        try? await Task.sleep(for: .seconds(1))
        
        // Mock data for development
        invoices = []
    }
    
    public func createInvoice(_ invoice: Invoice) async throws {
        // TODO: Save to persistent storage
        invoices.append(invoice)
    }
    
    public func updateInvoice(_ invoice: Invoice) async throws {
        // TODO: Update in persistent storage
        if let index = invoices.firstIndex(where: { $0.id == invoice.id }) {
            invoices[index] = invoice
        }
    }
    
    public func deleteInvoice(_ invoice: Invoice) async throws {
        // TODO: Delete from persistent storage
        invoices.removeAll { $0.id == invoice.id }
    }
    
    public func generateInvoiceNumber() -> String {
        // TODO: Get from business profile settings
        let nextNumber = invoices.count + 1
        return "INV-\(String(format: "%04d", nextNumber))"
    }
}