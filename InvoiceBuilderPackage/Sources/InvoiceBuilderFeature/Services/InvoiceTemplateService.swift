import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
public final class InvoiceTemplateService: @unchecked Sendable {
    public static let shared = InvoiceTemplateService()
    
    private var modelContext: ModelContext?
    
    // Current selected template
    public var selectedTemplate: InvoiceTemplate = .classic
    
    // Available templates
    public var availableTemplates: [InvoiceTemplate] = []
    
    // Loading state
    public var isLoading = false
    
    // Error handling
    public var error: InvoiceTemplateError?
    
    private init() {
        loadBuiltInTemplates()
    }
    
    public func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        Task {
            await loadCustomTemplates()
        }
    }
    
    // MARK: - Template Loading
    
    private func loadBuiltInTemplates() {
        availableTemplates = InvoiceTemplate.builtInTemplates
    }
    
    private func loadCustomTemplates() async {
        guard let modelContext = modelContext else { return }
        
        do {
            isLoading = true
            
            let descriptor = FetchDescriptor<InvoiceTemplateEntity>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            
            let entities = try modelContext.fetch(descriptor)
            let customTemplates = entities.map { InvoiceTemplate(from: $0) }
            
            // Combine built-in and custom templates
            availableTemplates = InvoiceTemplate.builtInTemplates + customTemplates
            
            isLoading = false
        } catch {
            self.error = .loadingFailed(error)
            isLoading = false
        }
    }
    
    // MARK: - Template Management
    
    public func selectTemplate(_ template: InvoiceTemplate) {
        selectedTemplate = template
    }
    
    public func getTemplate(by id: UUID) -> InvoiceTemplate? {
        return availableTemplates.first { $0.id == id }
    }
    
    public func getTemplate(by name: String) -> InvoiceTemplate? {
        return availableTemplates.first { $0.name == name }
    }
    
    public func getTemplatesByCategory(_ category: TemplateCategory) -> [InvoiceTemplate] {
        if category == .all {
            return availableTemplates
        }
        return category.templates()
    }
    
    // MARK: - Custom Template Management
    
    public func createCustomTemplate(
        name: String,
        displayName: String,
        description: String? = nil,
        baseTemplate: InvoiceTemplate? = nil
    ) async throws -> InvoiceTemplate {
        guard let modelContext = modelContext else {
            throw InvoiceTemplateError.contextNotAvailable
        }
        
        // Create new template based on existing template or defaults
        let base = baseTemplate ?? .classic
        
        let customTemplate = InvoiceTemplate(
            name: name,
            displayName: displayName,
            templateDescription: description,
            isDefault: false,
            isCustom: true,
            primaryColor: base.primaryColor,
            secondaryColor: base.secondaryColor,
            accentColor: base.accentColor,
            fontFamily: base.fontFamily,
            fontSize: base.fontSize,
            logoPosition: base.logoPosition,
            headerLayout: base.headerLayout,
            footerLayout: base.footerLayout,
            showTaxColumn: base.showTaxColumn,
            showDiscountColumn: base.showDiscountColumn,
            showNotesSection: base.showNotesSection,
            showTermsSection: base.showTermsSection
        )
        
        // Save to database
        let entity = InvoiceTemplateEntity(
            id: customTemplate.id,
            name: customTemplate.name,
            displayName: customTemplate.displayName,
            templateDescription: customTemplate.templateDescription,
            isDefault: customTemplate.isDefault,
            isCustom: customTemplate.isCustom,
            primaryColor: customTemplate.primaryColor,
            secondaryColor: customTemplate.secondaryColor,
            accentColor: customTemplate.accentColor,
            fontFamily: customTemplate.fontFamily,
            fontSize: customTemplate.fontSize,
            logoPosition: customTemplate.logoPosition.rawValue,
            headerLayout: customTemplate.headerLayout.rawValue,
            footerLayout: customTemplate.footerLayout.rawValue,
            showTaxColumn: customTemplate.showTaxColumn,
            showDiscountColumn: customTemplate.showDiscountColumn,
            showNotesSection: customTemplate.showNotesSection,
            showTermsSection: customTemplate.showTermsSection,
            customCSS: customTemplate.customCSS,
            previewImageData: customTemplate.previewImageData
        )
        
        modelContext.insert(entity)
        try modelContext.save()
        
        // Add to available templates
        availableTemplates.append(customTemplate)
        
        return customTemplate
    }
    
    public func updateCustomTemplate(_ template: InvoiceTemplate) async throws {
        guard let modelContext = modelContext else {
            throw InvoiceTemplateError.contextNotAvailable
        }
        
        guard template.isCustom else {
            throw InvoiceTemplateError.cannotModifyBuiltIn
        }
        
        // Find existing entity
        let templateId = template.id
        let predicate = #Predicate<InvoiceTemplateEntity> { entity in
            entity.id == templateId
        }
        
        let descriptor = FetchDescriptor(predicate: predicate)
        let entities = try modelContext.fetch(descriptor)
        
        guard let entity = entities.first else {
            throw InvoiceTemplateError.templateNotFound
        }
        
        // Update entity
        entity.displayName = template.displayName
        entity.templateDescription = template.templateDescription
        entity.primaryColor = template.primaryColor
        entity.secondaryColor = template.secondaryColor
        entity.accentColor = template.accentColor
        entity.fontFamily = template.fontFamily
        entity.fontSize = template.fontSize
        entity.logoPosition = template.logoPosition.rawValue
        entity.headerLayout = template.headerLayout.rawValue
        entity.footerLayout = template.footerLayout.rawValue
        entity.showTaxColumn = template.showTaxColumn
        entity.showDiscountColumn = template.showDiscountColumn
        entity.showNotesSection = template.showNotesSection
        entity.showTermsSection = template.showTermsSection
        entity.customCSS = template.customCSS
        entity.previewImageData = template.previewImageData
        entity.updatedAt = Date()
        
        try modelContext.save()
        
        // Update in available templates
        if let index = availableTemplates.firstIndex(where: { $0.id == template.id }) {
            availableTemplates[index] = template
        }
    }
    
    public func deleteCustomTemplate(_ template: InvoiceTemplate) async throws {
        guard let modelContext = modelContext else {
            throw InvoiceTemplateError.contextNotAvailable
        }
        
        guard template.isCustom else {
            throw InvoiceTemplateError.cannotModifyBuiltIn
        }
        
        // Find and delete entity
        let templateId = template.id
        let predicate = #Predicate<InvoiceTemplateEntity> { entity in
            entity.id == templateId
        }
        
        let descriptor = FetchDescriptor(predicate: predicate)
        let entities = try modelContext.fetch(descriptor)
        
        if let entity = entities.first {
            modelContext.delete(entity)
            try modelContext.save()
        }
        
        // Remove from available templates
        availableTemplates.removeAll { $0.id == template.id }
        
        // If this was the selected template, switch to default
        if selectedTemplate.id == template.id {
            selectedTemplate = .classic
        }
    }
    
    // MARK: - Template Duplication
    
    public func duplicateTemplate(_ template: InvoiceTemplate, newName: String) async throws -> InvoiceTemplate {
        let duplicatedTemplate = InvoiceTemplate(
            name: "\(template.name)_copy",
            displayName: newName,
            templateDescription: template.templateDescription,
            isDefault: false,
            isCustom: true,
            primaryColor: template.primaryColor,
            secondaryColor: template.secondaryColor,
            accentColor: template.accentColor,
            fontFamily: template.fontFamily,
            fontSize: template.fontSize,
            logoPosition: template.logoPosition,
            headerLayout: template.headerLayout,
            footerLayout: template.footerLayout,
            showTaxColumn: template.showTaxColumn,
            showDiscountColumn: template.showDiscountColumn,
            showNotesSection: template.showNotesSection,
            showTermsSection: template.showTermsSection,
            customCSS: template.customCSS,
            previewImageData: template.previewImageData
        )
        
        return try await createCustomTemplate(
            name: duplicatedTemplate.name,
            displayName: duplicatedTemplate.displayName,
            description: duplicatedTemplate.templateDescription,
            baseTemplate: template
        )
    }
    
    // MARK: - Template Rendering
    
    public func renderInvoicePreview(
        invoice: Invoice,
        businessProfile: BusinessProfile,
        template: InvoiceTemplate? = nil
    ) -> some View {
        let templateToUse = template ?? selectedTemplate
        
        return InvoiceTemplateRenderer(
            invoice: invoice,
            businessProfile: businessProfile,
            template: templateToUse
        )
    }
    
    public func generateTemplatePreview(_ template: InvoiceTemplate) -> some View {
        // Create sample data for preview
        let sampleClient = Client(
            name: "Sample Client Co.",
            email: "client@example.com",
            phone: "+1 (555) 123-4567",
            address: Address(
                street: "123 Business St",
                city: "City",
                state: "State",
                postalCode: "12345",
                country: "USA"
            ),
            company: "Sample Company Inc."
        )
        
        let sampleItems = [
            InvoiceItem(
                name: "Consulting Services",
                description: "Strategic business consulting",
                quantity: 10,
                rate: 150.00
            ),
            InvoiceItem(
                name: "Design Work",
                description: "UI/UX design services",
                quantity: 5,
                rate: 120.00
            )
        ]
        
        var sampleInvoice = Invoice(
            invoiceNumber: "INV-0001",
            date: Date(),
            dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            client: sampleClient,
            items: sampleItems
        )
        sampleInvoice.updateStatus(.sent)
        sampleInvoice.notes = "Thank you for your business!"
        sampleInvoice.terms = "Payment due within 30 days"
        
        let sampleBusinessProfile = BusinessProfile(
            businessName: "Your Business Name",
            ownerName: "John Doe",
            email: "contact@yourbusiness.com",
            phone: "+1 (555) 123-4567",
            website: "www.yourbusiness.com",
            address: Address(
                street: "456 Business Ave, Suite 100",
                city: "City",
                state: "State",
                postalCode: "12345",
                country: "USA"
            ),
            taxId: "12-3456789"
        )
        
        return InvoiceTemplateRenderer(
            invoice: sampleInvoice,
            businessProfile: sampleBusinessProfile,
            template: template
        )
    }
    
    // MARK: - Error Handling
    
    public func clearError() {
        error = nil
    }
}

// MARK: - Error Types

public enum InvoiceTemplateError: LocalizedError, Sendable {
    case loadingFailed(Error)
    case templateNotFound
    case contextNotAvailable
    case cannotModifyBuiltIn
    case duplicateTemplateName
    case invalidTemplateData
    
    public var errorDescription: String? {
        switch self {
        case .loadingFailed(let error):
            return "Failed to load templates: \(error.localizedDescription)"
        case .templateNotFound:
            return "Template not found"
        case .contextNotAvailable:
            return "Database context not available"
        case .cannotModifyBuiltIn:
            return "Cannot modify built-in templates"
        case .duplicateTemplateName:
            return "A template with this name already exists"
        case .invalidTemplateData:
            return "Invalid template data"
        }
    }
}

// MARK: - Template Renderer

@MainActor
private struct InvoiceTemplateRenderer: View {
    let invoice: Invoice
    let businessProfile: BusinessProfile
    let template: InvoiceTemplate
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
                .padding(template.headerLayout == .minimal ? 16 : 24)
            
            Divider()
                .foregroundStyle(template.secondaryColorSwiftUI())
            
            // Invoice details
            invoiceDetailsSection
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            
            // Items table
            itemsTableSection
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            
            // Totals
            totalsSection
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            
            // Footer
            if template.footerLayout != .minimal {
                Divider()
                    .foregroundStyle(template.secondaryColorSwiftUI())
                
                footerSection
                    .padding(24)
            }
        }
        .background(Color.white)
        .foregroundStyle(template.primaryColorSwiftUI())
    }
    
    @ViewBuilder
    private var headerSection: some View {
        switch template.headerLayout {
        case .standard:
            standardHeader
        case .minimal:
            minimalHeader
        case .detailed:
            detailedHeader
        case .modern:
            modernHeader
        }
    }
    
    @ViewBuilder
    private var standardHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(businessProfile.businessName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(template.primaryColorSwiftUI())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(businessProfile.address?.formattedAddress ?? "")
                    Text(businessProfile.email)
                    Text(businessProfile.phone ?? "")
                }
                .font(.caption)
                .foregroundStyle(template.secondaryColorSwiftUI())
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("INVOICE")
                    .font(.title)
                    .fontWeight(.heavy)
                    .foregroundStyle(template.accentColorSwiftUI())
                
                Text(invoice.invoiceNumber)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
        }
    }
    
    @ViewBuilder
    private var minimalHeader: some View {
        HStack {
            Text(businessProfile.businessName)
                .font(.title3)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("Invoice \(invoice.invoiceNumber)")
                .font(.headline)
                .foregroundStyle(template.accentColorSwiftUI())
        }
    }
    
    @ViewBuilder
    private var detailedHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(businessProfile.businessName)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(template.primaryColorSwiftUI())
                    
                    if let website = businessProfile.website {
                        Text(website)
                            .font(.caption)
                            .foregroundStyle(template.accentColorSwiftUI())
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("INVOICE")
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .foregroundStyle(template.accentColorSwiftUI())
                    
                    Text(invoice.invoiceNumber)
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("From:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(template.secondaryColorSwiftUI())
                    
                    Text(businessProfile.ownerName)
                        .fontWeight(.medium)
                    Text(businessProfile.address?.formattedAddress ?? "")
                    Text("\(businessProfile.email) • \(businessProfile.phone ?? "")")
                    
                    if let taxId = businessProfile.taxId {
                        Text("Tax ID: \(taxId)")
                            .font(.caption)
                            .foregroundStyle(template.secondaryColorSwiftUI())
                    }
                }
                .font(.caption)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("To:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(template.secondaryColorSwiftUI())
                    
                    Text(invoice.client.name)
                        .fontWeight(.medium)
                    if let address = invoice.client.address {
                        Text(address.formattedAddress)
                    }
                    Text(invoice.client.email)
                }
                .font(.caption)
            }
        }
    }
    
    @ViewBuilder
    private var modernHeader: some View {
        VStack(spacing: 20) {
            HStack {
                Text(businessProfile.businessName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(template.primaryColorSwiftUI())
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("INVOICE")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(template.accentColorSwiftUI())
                    
                    Text(invoice.invoiceNumber)
                        .font(.subheadline)
                        .foregroundStyle(template.secondaryColorSwiftUI())
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bill To:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(template.secondaryColorSwiftUI())
                    
                    Text(invoice.client.name)
                        .fontWeight(.semibold)
                    Text(invoice.client.email)
                        .font(.caption)
                        .foregroundStyle(template.secondaryColorSwiftUI())
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Text("Date:")
                            .foregroundStyle(template.secondaryColorSwiftUI())
                        Text(invoice.date, style: .date)
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("Due:")
                            .foregroundStyle(template.secondaryColorSwiftUI())
                        Text(invoice.dueDate, style: .date)
                    }
                    .font(.caption)
                }
            }
        }
    }
    
    @ViewBuilder
    private var invoiceDetailsSection: some View {
        if template.headerLayout == .standard || template.headerLayout == .minimal {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bill To:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(template.secondaryColorSwiftUI())
                    
                    Text(invoice.client.name)
                        .fontWeight(.semibold)
                    Text(invoice.client.email)
                        .font(.caption)
                        .foregroundStyle(template.secondaryColorSwiftUI())
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Text("Date:")
                            .foregroundStyle(template.secondaryColorSwiftUI())
                        Text(invoice.date, style: .date)
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("Due:")
                            .foregroundStyle(template.secondaryColorSwiftUI())
                        Text(invoice.dueDate, style: .date)
                    }
                    .font(.caption)
                }
            }
        }
    }
    
    @ViewBuilder
    private var itemsTableSection: some View {
        VStack(spacing: 0) {
            // Table header
            HStack {
                Text("Description")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Qty")
                    .fontWeight(.semibold)
                    .frame(width: 50)
                
                Text("Rate")
                    .fontWeight(.semibold)
                    .frame(width: 80, alignment: .trailing)
                
                if template.showTaxColumn {
                    Text("Tax")
                        .fontWeight(.semibold)
                        .frame(width: 60, alignment: .trailing)
                }
                
                Text("Amount")
                    .fontWeight(.semibold)
                    .frame(width: 80, alignment: .trailing)
            }
            .font(.caption)
            .foregroundStyle(template.secondaryColorSwiftUI())
            .padding(.vertical, 8)
            .background(template.primaryColorSwiftUI().opacity(0.1))
            
            // Table rows
            ForEach(Array(invoice.items.enumerated()), id: \.offset) { index, item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .fontWeight(.medium)
                        if !item.description.isEmpty {
                            Text(item.description)
                                .font(.caption)
                                .foregroundStyle(template.secondaryColorSwiftUI())
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(String(format: "%.0f", Double(truncating: item.quantity as NSNumber)))
                        .frame(width: 50)
                    
                    Text(item.rate, format: .currency(code: "USD"))
                        .frame(width: 80, alignment: .trailing)
                    
                    if template.showTaxColumn {
                        Text(String(format: "%.1f%%", Double(truncating: item.taxRate as NSNumber)))
                            .frame(width: 60, alignment: .trailing)
                    }
                    
                    Text(item.total, format: .currency(code: "USD"))
                        .fontWeight(.semibold)
                        .frame(width: 80, alignment: .trailing)
                }
                .font(.caption)
                .padding(.vertical, 8)
                .background(index % 2 == 1 ? template.primaryColorSwiftUI().opacity(0.05) : Color.clear)
            }
        }
    }
    
    @ViewBuilder
    private var totalsSection: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Text("Subtotal:")
                        Spacer()
                        Text(invoice.subtotal, format: .currency(code: "USD"))
                    }
                    
                    if invoice.taxAmount > 0 {
                        HStack {
                            Text("Tax:")
                            Spacer()
                            Text(invoice.taxAmount, format: .currency(code: "USD"))
                        }
                    }
                    
                    if invoice.discountAmount > 0 && template.showDiscountColumn {
                        HStack {
                            Text("Discount:")
                            Spacer()
                            Text("-\(invoice.discountAmount, format: .currency(code: "USD"))")
                        }
                        .foregroundStyle(template.accentColorSwiftUI())
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total:")
                            .fontWeight(.bold)
                        Spacer()
                        Text(invoice.total, format: .currency(code: "USD"))
                            .fontWeight(.bold)
                            .foregroundStyle(template.accentColorSwiftUI())
                    }
                    .font(.headline)
                }
                .font(.caption)
                .frame(width: 200)
            }
        }
    }
    
    @ViewBuilder
    private var footerSection: some View {
        switch template.footerLayout {
        case .standard:
            standardFooter
        case .minimal:
            EmptyView() // Already handled by not showing footer
        case .detailed:
            detailedFooter
        case .signature:
            signatureFooter
        }
    }
    
    @ViewBuilder
    private var standardFooter: some View {
        VStack(spacing: 12) {
            if let notes = invoice.notes, template.showNotesSection {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(template.secondaryColorSwiftUI())
                    
                    Text(notes)
                        .font(.caption)
                }
            }
            
            if let terms = invoice.terms, template.showTermsSection {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Terms:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(template.secondaryColorSwiftUI())
                    
                    Text(terms)
                        .font(.caption)
                }
            }
        }
    }
    
    @ViewBuilder
    private var detailedFooter: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                if let notes = invoice.notes, template.showNotesSection {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(template.secondaryColorSwiftUI())
                        
                        Text(notes)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if let terms = invoice.terms, template.showTermsSection {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Payment Terms:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(template.secondaryColorSwiftUI())
                        
                        Text(terms)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            Text("Thank you for your business!")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(template.accentColorSwiftUI())
        }
    }
    
    @ViewBuilder
    private var signatureFooter: some View {
        VStack(spacing: 16) {
            standardFooter
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Authorized Signature:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(template.secondaryColorSwiftUI())
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(template.secondaryColorSwiftUI())
                        .frame(width: 200)
                    
                    Text(businessProfile.ownerName)
                        .font(.caption)
                        .foregroundStyle(template.secondaryColorSwiftUI())
                }
                
                Spacer()
            }
        }
    }
}