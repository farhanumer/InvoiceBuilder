import Testing
import Foundation
@testable import InvoiceBuilderFeature

@Suite("InvoiceItem Model Tests")
struct InvoiceItemTests {
    
    @Test("InvoiceItem initialization and calculations")
    func testInvoiceItemInitialization() async throws {
        let item = InvoiceItem(
            name: "Web Development",
            description: "Custom website development",
            quantity: 10,
            rate: 75
        )
        
        #expect(item.name == "Web Development")
        #expect(item.description == "Custom website development")
        #expect(item.quantity == 10)
        #expect(item.rate == 75)
        #expect(item.total == 750) // 10 * 75
        #expect(item.taxRate == 0)
        #expect(item.discountAmount == 0)
    }
    
    @Test("InvoiceItem with tax calculations")
    func testInvoiceItemWithTax() async throws {
        let item = InvoiceItem(
            name: "Consulting",
            description: "Business consulting services",
            quantity: 5,
            rate: 100,
            taxRate: 10 // 10% tax
        )
        
        let subtotal = item.subtotal // 5 * 100 = 500
        let taxAmount = item.taxAmount // 500 * 0.10 = 50
        let total = item.total // 500 + 50 = 550
        
        #expect(subtotal == 500)
        #expect(taxAmount == 50)
        #expect(total == 550)
    }
    
    @Test("InvoiceItem with discount calculations")
    func testInvoiceItemWithDiscount() async throws {
        let item = InvoiceItem(
            name: "Design Services",
            description: "Logo and branding design",
            quantity: 1,
            rate: 500,
            taxRate: 8.25, // 8.25% tax
            discountAmount: 50
        )
        
        let subtotal = item.subtotal // 1 * 500 = 500
        let taxAmount = item.taxAmount // 500 * 0.0825 = 41.25
        let total = item.total // 500 + 41.25 - 50 = 491.25
        
        #expect(subtotal == 500)
        #expect(taxAmount == 41.25)
        #expect(total == 491.25)
    }
    
    @Test("InvoiceItem total update")
    func testInvoiceItemUpdateTotal() async throws {
        var item = InvoiceItem(
            name: "Testing",
            description: "Software testing",
            quantity: 1,
            rate: 100
        )
        
        #expect(item.total == 100)
        
        // Modify values
        item.quantity = 2
        item.rate = 150
        item.taxRate = 5
        item.discountAmount = 25
        
        // Update total
        item.updateTotal()
        
        // Expected: (2 * 150) + (300 * 0.05) - 25 = 300 + 15 - 25 = 290
        #expect(item.total == 290)
    }
    
    @Test("InvoiceItem from entity")
    func testInvoiceItemFromEntity() async throws {
        let itemEntity = InvoiceItemEntity(
            itemDescription: "Entity Item",
            quantity: 3,
            unitPrice: 200,
            taxRate: 7.5,
            discountAmount: 30
        )
        itemEntity.category = "Services"
        itemEntity.sku = "SKU123"
        itemEntity.notes = "Special item"
        itemEntity.sortOrder = 1
        
        // Calculate expected total manually since entity calculates it
        let subtotal = Decimal(3) * Decimal(200) // 600
        let taxAmount = subtotal * (Decimal(7.5) / 100) // 45
        let expectedTotal = subtotal + taxAmount - Decimal(30) // 615
        itemEntity.totalAmount = expectedTotal
        
        let item = InvoiceItem(from: itemEntity)
        
        #expect(item.name == "Entity Item") // Uses description as name
        #expect(item.description == "Entity Item")
        #expect(item.quantity == 3)
        #expect(item.rate == 200)
        #expect(item.taxRate == 7.5)
        #expect(item.discountAmount == 30)
        #expect(item.total == 615)
        #expect(item.category == "Services")
        #expect(item.sku == "SKU123")
        #expect(item.notes == "Special item")
        #expect(item.sortOrder == 1)
    }
    
    @Test("ServiceItem initialization")
    func testServiceItemInitialization() async throws {
        let serviceItem = ServiceItem(
            name: "Standard Consultation",
            description: "One hour business consultation",
            defaultRate: 150,
            category: "Consulting",
            isActive: true
        )
        
        #expect(serviceItem.name == "Standard Consultation")
        #expect(serviceItem.description == "One hour business consultation")
        #expect(serviceItem.defaultRate == 150)
        #expect(serviceItem.category == "Consulting")
        #expect(serviceItem.isActive == true)
    }
}