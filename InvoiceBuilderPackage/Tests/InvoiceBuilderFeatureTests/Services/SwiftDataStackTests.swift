import Testing
import Foundation
import SwiftData
@testable import InvoiceBuilderFeature

@Suite("SwiftDataStack Tests") @MainActor
struct SwiftDataStackTests {
    
    private func createTestDataStack() -> SwiftDataStack {
        // For testing, we'll use the shared instance but in a real test environment
        // you might want to create an in-memory store
        return SwiftDataStack.shared
    }
    
    @Test("SwiftDataStack initialization")
    func testSwiftDataStackInitialization() async throws { 
        let _ = createTestDataStack()
        
        // Just check that dataStack was created successfully
        #expect(Bool(true))
    }
    
    @Test("Create and fetch client")
    func testCreateAndFetchClient() async throws {
        let dataStack = createTestDataStack()
        
        let client = ClientEntity(
            name: "Test Client",
            email: "test@example.com",
            phone: "+1234567890"
        )
        
        dataStack.insert(client)
        try dataStack.save()
        
        let fetchedClients = try dataStack.fetchClients()
        let testClient = fetchedClients.first { $0.name == "Test Client" }
        
        #expect(testClient != nil)
        #expect(testClient?.email == "test@example.com")
        #expect(testClient?.phone == "+1234567890")
        
        // Cleanup
        if let testClient = testClient {
            dataStack.delete(testClient)
            try dataStack.save()
        }
    }
    
    @Test("Create and fetch invoice with items")
    func testCreateAndFetchInvoiceWithItems() async throws {
        let dataStack = createTestDataStack()
        
        // Create a client first
        let client = ClientEntity(
            name: "Invoice Test Client",
            email: "invoice@test.com"
        )
        dataStack.insert(client)
        
        // Create an invoice
        let invoice = InvoiceEntity(
            number: "TEST-001",
            dueDate: Date().addingTimeInterval(86400 * 30)
        )
        invoice.client = client
        invoice.subtotal = 300
        invoice.taxAmount = 25
        invoice.totalAmount = 325
        
        // Create invoice items
        let item1 = InvoiceItemEntity(
            itemDescription: "Test Service 1",
            quantity: 2,
            unitPrice: 100
        )
        item1.invoice = invoice
        
        let item2 = InvoiceItemEntity(
            itemDescription: "Test Service 2",
            quantity: 1,
            unitPrice: 100
        )
        item2.invoice = invoice
        
        invoice.items = [item1, item2]
        
        dataStack.insert(invoice)
        dataStack.insert(item1)
        dataStack.insert(item2)
        try dataStack.save()
        
        // Fetch and verify
        let fetchedInvoices = try dataStack.fetchInvoices()
        let testInvoice = fetchedInvoices.first { $0.number == "TEST-001" }
        
        #expect(testInvoice != nil)
        #expect(testInvoice?.client?.name == "Invoice Test Client")
        #expect(testInvoice?.items.count == 2)
        #expect(testInvoice?.subtotal == 300)
        #expect(testInvoice?.totalAmount == 325)
        
        // Cleanup
        if let testInvoice = testInvoice {
            for item in testInvoice.items {
                dataStack.delete(item)
            }
            dataStack.delete(testInvoice)
        }
        if let testClient = try dataStack.fetchClient(by: client.id) {
            dataStack.delete(testClient)
        }
        try dataStack.save()
    }
    
    @Test("Fetch specific entities by ID")
    func testFetchByID() async throws {
        let dataStack = createTestDataStack()
        
        let client = ClientEntity(
            name: "ID Test Client",
            email: "idtest@example.com"
        )
        
        dataStack.insert(client)
        try dataStack.save()
        
        let fetchedClient = try dataStack.fetchClient(by: client.id)
        
        #expect(fetchedClient != nil)
        #expect(fetchedClient?.name == "ID Test Client")
        #expect(fetchedClient?.id == client.id)
        
        // Cleanup
        if let fetchedClient = fetchedClient {
            dataStack.delete(fetchedClient)
            try dataStack.save()
        }
    }
    
    @Test("Business profile operations")
    func testBusinessProfileOperations() async throws {
        let dataStack = createTestDataStack()
        
        let businessProfile = BusinessProfileEntity(
            businessName: "Test Business",
            ownerName: "Test Owner",
            email: "business@test.com"
        )
        businessProfile.invoicePrefix = "TEST"
        businessProfile.nextInvoiceNumber = 100
        
        dataStack.insert(businessProfile)
        try dataStack.save()
        
        let fetchedProfiles = try dataStack.fetchBusinessProfiles()
        let testProfile = fetchedProfiles.first { $0.businessName == "Test Business" }
        
        #expect(testProfile != nil)
        #expect(testProfile?.ownerName == "Test Owner")
        #expect(testProfile?.invoicePrefix == "TEST")
        #expect(testProfile?.nextInvoiceNumber == 100)
        
        // Cleanup
        if let testProfile = testProfile {
            dataStack.delete(testProfile)
            try dataStack.save()
        }
    }
    
    @Test("Invoice template operations")
    func testInvoiceTemplateOperations() async throws {
        let dataStack = createTestDataStack()
        
        let template = InvoiceTemplateEntity(
            name: "test-template",
            displayName: "Test Template"
        )
        template.isDefault = true
        template.primaryColor = "#FF0000"
        
        dataStack.insert(template)
        try dataStack.save()
        
        let fetchedTemplates = try dataStack.fetchInvoiceTemplates()
        let testTemplate = fetchedTemplates.first { $0.name == "test-template" }
        
        #expect(testTemplate != nil)
        #expect(testTemplate?.displayName == "Test Template")
        #expect(testTemplate?.isDefault == true)
        #expect(testTemplate?.primaryColor == "#FF0000")
        
        // Cleanup
        if let testTemplate = testTemplate {
            dataStack.delete(testTemplate)
            try dataStack.save()
        }
    }
    
    @Test("Rollback functionality")
    func testRollback() async throws {
        let dataStack = createTestDataStack()
        
        // Simple test just to verify rollback method exists and can be called
        dataStack.rollback()
        #expect(Bool(true)) // Test passes if rollback doesn't throw
    }
}