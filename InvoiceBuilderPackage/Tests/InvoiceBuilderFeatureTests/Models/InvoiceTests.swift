import Testing
import Foundation
@testable import InvoiceBuilderFeature

@Suite("Invoice Model Tests")
struct InvoiceTests {
    
    @Test("Invoice initialization with valid data")
    func testInvoiceInitialization() async throws {
        let client = Client(
            name: "Test Client",
            email: "test@example.com"
        )
        
        let item = InvoiceItem(
            name: "Test Service",
            description: "Test service description",
            quantity: 2,
            rate: 100
        )
        
        let invoice = Invoice(
            invoiceNumber: "INV-001",
            date: Date(),
            dueDate: Date().addingTimeInterval(86400 * 30), // 30 days
            client: client,
            items: [item],
            currency: .usd
        )
        
        #expect(invoice.invoiceNumber == "INV-001")
        #expect(invoice.client.name == "Test Client")
        #expect(invoice.items.count == 1)
        #expect(invoice.currency == .usd)
        #expect(invoice.subtotal == 200) // 2 * 100
        #expect(invoice.status == .draft)
    }
    
    @Test("Invoice total calculations")
    func testInvoiceTotalCalculations() async throws {
        let client = Client(name: "Test", email: "test@example.com")
        
        let item1 = InvoiceItem(
            name: "Service 1",
            description: "First service",
            quantity: 1,
            rate: 100,
            taxRate: 10 // 10% tax
        )
        
        let item2 = InvoiceItem(
            name: "Service 2", 
            description: "Second service",
            quantity: 2,
            rate: 50,
            discountAmount: 10
        )
        
        let invoice = Invoice(
            invoiceNumber: "INV-002",
            date: Date(),
            dueDate: Date().addingTimeInterval(86400 * 30),
            client: client,
            items: [item1, item2],
            taxRate: 0.05 // 5% overall tax
        )
        
        // item1: 100 + 10 (tax) = 110
        // item2: 100 - 10 (discount) = 90
        // Expected subtotal: 110 + 90 = 200
        #expect(invoice.subtotal == 200)
        
        // Tax on subtotal: 200 * 0.05 = 10
        #expect(invoice.taxAmount == 10)
        
        // Total: 200 + 10 = 210
        #expect(invoice.total == 210)
    }
    
    @Test("Invoice status enum")
    func testInvoiceStatusEnum() async throws {
        #expect(InvoiceStatus.draft.displayName == "Draft")
        #expect(InvoiceStatus.sent.displayName == "Sent")
        #expect(InvoiceStatus.paid.displayName == "Paid")
        #expect(InvoiceStatus.overdue.displayName == "Overdue")
        #expect(InvoiceStatus.cancelled.displayName == "Cancelled")
        
        #expect(InvoiceStatus.draft.rawValue == "draft")
        #expect(InvoiceStatus.paid.rawValue == "paid")
    }
    
    @Test("Invoice creation from entity")
    func testInvoiceFromEntity() async throws {
        let clientEntity = ClientEntity(
            name: "Entity Client",
            email: "entity@example.com"
        )
        
        let invoiceEntity = InvoiceEntity(
            number: "INV-ENTITY",
            dueDate: Date().addingTimeInterval(86400 * 30)
        )
        invoiceEntity.client = clientEntity
        invoiceEntity.subtotal = 100
        invoiceEntity.taxAmount = 10
        invoiceEntity.totalAmount = 110
        
        let invoice = Invoice(from: invoiceEntity)
        
        #expect(invoice.invoiceNumber == "INV-ENTITY")
        #expect(invoice.client.name == "Entity Client")
        #expect(invoice.subtotal == 100)
        #expect(invoice.taxAmount == 10)
        #expect(invoice.total == 110)
    }
}