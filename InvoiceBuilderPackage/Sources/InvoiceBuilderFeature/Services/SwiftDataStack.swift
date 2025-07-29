import Foundation
import SwiftData

@Observable
@MainActor
public final class SwiftDataStack {
    public static let shared = SwiftDataStack()
    
    public private(set) var modelContainer: ModelContainer
    
    private init() {
        let schema = Schema([
            InvoiceEntity.self,
            ClientEntity.self,
            BusinessProfileEntity.self,
            InvoiceItemEntity.self,
            InvoiceTemplateEntity.self,
            AddressEntity.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            "InvoiceBuilderDatabase",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .automatic,
            cloudKitDatabase: .automatic
        )
        
        do {
            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    public var modelContext: ModelContext {
        modelContainer.mainContext
    }
    
    public func save() throws {
        guard modelContext.hasChanges else { return }
        try modelContext.save()
    }
    
    public func rollback() {
        modelContext.rollback()
    }
    
    public func delete<T: PersistentModel>(_ object: T) {
        modelContext.delete(object)
    }
    
    public func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) throws -> [T] {
        return try modelContext.fetch(descriptor)
    }
    
    public func insert<T: PersistentModel>(_ object: T) {
        modelContext.insert(object)
    }
    
    // MARK: - Convenience Methods
    
    public func fetchInvoices() throws -> [InvoiceEntity] {
        let descriptor = FetchDescriptor<InvoiceEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try fetch(descriptor)
    }
    
    public func fetchClients() throws -> [ClientEntity] {
        let descriptor = FetchDescriptor<ClientEntity>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try fetch(descriptor)
    }
    
    public func fetchBusinessProfiles() throws -> [BusinessProfileEntity] {
        let descriptor = FetchDescriptor<BusinessProfileEntity>()
        return try fetch(descriptor)
    }
    
    public func fetchInvoiceTemplates() throws -> [InvoiceTemplateEntity] {
        let descriptor = FetchDescriptor<InvoiceTemplateEntity>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try fetch(descriptor)
    }
    
    public func fetchInvoice(by id: UUID) throws -> InvoiceEntity? {
        let descriptor = FetchDescriptor<InvoiceEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try fetch(descriptor).first
    }
    
    public func fetchClient(by id: UUID) throws -> ClientEntity? {
        let descriptor = FetchDescriptor<ClientEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try fetch(descriptor).first
    }
    
    public func fetchBusinessProfile(by id: UUID) throws -> BusinessProfileEntity? {
        let descriptor = FetchDescriptor<BusinessProfileEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try fetch(descriptor).first
    }
    
    public func createSampleData() throws {
        // Create sample business profile
        let businessProfile = BusinessProfileEntity(
            businessName: "Sample Business",
            ownerName: "John Doe",
            email: "john@samplebusiness.com",
            phone: "+1234567890",
            website: "https://samplebusiness.com"
        )
        insert(businessProfile)
        
        // Create sample client
        let clientAddress = AddressEntity(
            street: "123 Client St",
            city: "Client City",
            state: "CA",
            postalCode: "90210",
            country: "USA"
        )
        
        let client = ClientEntity(
            name: "Sample Client",
            email: "client@example.com",
            phone: "+0987654321",
            company: "Client Company",
            address: clientAddress
        )
        insert(client)
        
        // Create sample invoice template
        let template = InvoiceTemplateEntity(
            name: "default",
            displayName: "Default Template",
            templateDescription: "A clean, professional invoice template"
        )
        template.businessProfile = businessProfile
        insert(template)
        
        // Create sample invoice
        let invoice = InvoiceEntity(
            number: "INV-0001",
            dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        )
        invoice.client = client
        invoice.businessProfile = businessProfile
        invoice.template = template
        
        // Create sample invoice items
        let item1 = InvoiceItemEntity(
            itemDescription: "Web Development Services",
            quantity: 40,
            unitPrice: 75
        )
        item1.invoice = invoice
        insert(item1)
        
        let item2 = InvoiceItemEntity(
            itemDescription: "Design Consultation",
            quantity: 5,
            unitPrice: 100
        )
        item2.invoice = invoice
        insert(item2)
        
        invoice.items = [item1, item2]
        
        // Calculate invoice totals
        invoice.subtotal = invoice.items.reduce(0) { $0 + $1.totalAmount }
        invoice.taxAmount = invoice.subtotal * 0.0875 // 8.75% tax
        invoice.totalAmount = invoice.subtotal + invoice.taxAmount
        
        insert(invoice)
        
        try save()
    }
}