import Testing
import SwiftUI
@testable import InvoiceBuilderFeature

@Suite("Invoice Template Service Tests")
struct InvoiceTemplateServiceTests {
    
    @Test("InvoiceTemplateService shared instance exists")
    @MainActor
    func sharedInstanceExists() {
        let service = InvoiceTemplateService.shared
        // Reset to classic template for test consistency
        service.selectTemplate(.classic)
        #expect(service.selectedTemplate.name == "classic")
        #expect(service.availableTemplates.count > 0)
    }
    
    @Test("Template selection works correctly")
    @MainActor
    func templateSelection() {
        let service = InvoiceTemplateService.shared
        
        service.selectTemplate(.modern)
        #expect(service.selectedTemplate.name == "modern")
        
        service.selectTemplate(.executive)
        #expect(service.selectedTemplate.name == "executive")
        
        service.selectTemplate(.minimal)
        #expect(service.selectedTemplate.name == "minimal")
    }
    
    @Test("Invoice preview rendering does not crash")
    @MainActor
    func invoicePreviewRendering() {
        let service = InvoiceTemplateService.shared
        
        let client = Client(name: "Test Client", email: "test@example.com")
        let item = InvoiceItem(
            name: "Test Service",
            description: "Test service description",
            quantity: 1,
            rate: 100.00
        )
        
        let invoice = Invoice(
            invoiceNumber: "INV-TEST",
            date: Date(),
            dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            client: client,
            items: [item]
        )
        
        let businessProfile = BusinessProfile(
            businessName: "Test Business",
            ownerName: "Test Owner",
            email: "owner@test.com"
        )
        
        // Test that preview rendering doesn't crash for different templates
        let templates: [InvoiceTemplate] = [.classic, .modern, .executive, .minimal]
        
        for template in templates {
            let preview = service.renderInvoicePreview(
                invoice: invoice,
                businessProfile: businessProfile,
                template: template
            )
            
            // Just check that we get a view back (non-nil)
            // Just check that we get a view back - it should not be nil
            // SwiftUI views are never nil, so this test just ensures no crash
            let _ = preview
        }
    }
}

@Suite("Invoice Template Struct Tests")
struct InvoiceTemplateStructTests {
    
    @Test("Built-in templates exist")
    func builtInTemplatesExist() {
        let templates = InvoiceTemplate.builtInTemplates
        
        #expect(templates.contains { $0.name == "classic" })
        #expect(templates.contains { $0.name == "modern" })
        #expect(templates.contains { $0.name == "executive" })
        #expect(templates.contains { $0.name == "minimal" })
        #expect(templates.count >= 4)
    }
    
    @Test("InvoiceTemplate display names are correct")
    func templateDisplayNames() {
        #expect(InvoiceTemplate.classic.displayName == "Classic")
        #expect(InvoiceTemplate.modern.displayName == "Modern")
        #expect(InvoiceTemplate.executive.displayName == "Executive")
        #expect(InvoiceTemplate.minimal.displayName == "Minimal")
    }
    
    @Test("Template categories work correctly")
    func templateCategories() {
        #expect(TemplateCategory.professional.templates().count == 4)
        #expect(TemplateCategory.creative.templates().count == 3)
        #expect(TemplateCategory.minimal.templates().count == 3)
        #expect(TemplateCategory.service.templates().count == 3)
        #expect(TemplateCategory.product.templates().count == 3)
        #expect(TemplateCategory.all.templates().count == InvoiceTemplate.builtInTemplates.count)
    }
    
    @Test("Template colors are valid")
    func templateColors() {
        let template = InvoiceTemplate.classic
        
        #expect(template.primaryColor.hasPrefix("#"))
        #expect(template.secondaryColor.hasPrefix("#"))
        #expect(template.accentColor.hasPrefix("#"))
        
        // Test SwiftUI color conversion doesn't crash
        let _ = template.primaryColorSwiftUI()
        let _ = template.secondaryColorSwiftUI()
        let _ = template.accentColorSwiftUI()
    }
}

@Suite("Currency Formatting Tests")
struct CurrencyFormattingTests {
    
    @Test("Currency enum has all major currencies")
    func currencyEnumCases() {
        let currencies = Currency.allCases
        
        #expect(currencies.contains(.usd))
        #expect(currencies.contains(.eur))
        #expect(currencies.contains(.gbp))
        #expect(currencies.contains(.cad))
        #expect(currencies.contains(.aud))
        #expect(currencies.contains(.jpy))
        #expect(currencies.count >= 6)
    }
    
    @Test("Currency symbols are correct")
    func currencySymbols() {
        #expect(Currency.usd.symbol == "$")
        #expect(Currency.eur.symbol == "€")
        #expect(Currency.gbp.symbol == "£")
        #expect(Currency.cad.symbol == "C$")
        #expect(Currency.aud.symbol == "A$")
        #expect(Currency.jpy.symbol == "¥")
    }
    
    @Test("Currency names are correct")
    func currencyNames() {
        #expect(Currency.usd.name == "US Dollar")
        #expect(Currency.eur.name == "Euro")
        #expect(Currency.gbp.name == "British Pound")
        #expect(Currency.cad.name == "Canadian Dollar")
        #expect(Currency.aud.name == "Australian Dollar")
        #expect(Currency.jpy.name == "Japanese Yen")
    }
    
    @Test("Currency formatting works correctly")
    func currencyFormatting() {
        let amount = Decimal(1234.56)
        
        let usdFormatted = Currency.usd.formatAmount(amount)
        #expect(usdFormatted.contains("$"))
        #expect(usdFormatted.contains("1,234") || usdFormatted.contains("1234"))
        
        let eurFormatted = Currency.eur.formatAmount(amount)
        #expect(eurFormatted.contains("€"))
        
        let gbpFormatted = Currency.gbp.formatAmount(amount)
        #expect(gbpFormatted.contains("£"))
    }
    
    @Test("Currency zero amounts format correctly")
    func currencyZeroFormatting() {
        let zeroAmount = Decimal(0)
        
        let formatted = Currency.usd.formatAmount(zeroAmount)
        #expect(formatted.contains("$"))
        #expect(formatted.contains("0"))
    }
    
    @Test("Currency large amounts format correctly")
    func currencyLargeAmountFormatting() {
        let largeAmount = Decimal(1000000.50) // 1 million
        
        let formatted = Currency.usd.formatAmount(largeAmount)
        #expect(formatted.contains("$"))
        #expect(formatted.contains("1,000,000") || formatted.contains("1000000"))
    }
}

@Suite("Business Profile Invoice Numbering Tests")
struct BusinessProfileInvoiceNumberingTests {
    
    @Test("InvoiceNumberFormat enum cases")
    func invoiceNumberFormatCases() {
        let formats = InvoiceNumberFormat.allCases
        
        #expect(formats.contains(.sequential))
        #expect(formats.contains(.yearSequential))
        #expect(formats.contains(.monthYearSequential))
        #expect(formats.contains(.dateSequential))
        #expect(formats.contains(.custom))
    }
    
    @Test("InvoiceNumberFormat display names")
    func invoiceNumberFormatDisplayNames() {
        #expect(InvoiceNumberFormat.sequential.displayName == "Sequential (INV-0001)")
        #expect(InvoiceNumberFormat.yearSequential.displayName == "Year Sequential (INV-2024-0001)")
        #expect(InvoiceNumberFormat.monthYearSequential.displayName == "Month-Year Sequential (INV-012024-0001)")
        #expect(InvoiceNumberFormat.dateSequential.displayName == "Date Sequential (INV-20240131-0001)")
        #expect(InvoiceNumberFormat.custom.displayName == "Custom Format")
    }
    
    @Test("BusinessProfile generates invoice numbers correctly")
    func businessProfileInvoiceNumberGeneration() {
        var businessProfile = BusinessProfile(
            businessName: "Test Business",
            ownerName: "Test Owner",
            email: "test@business.com"
        )
        
        businessProfile.invoiceNumberPrefix = "INV"
        businessProfile.nextInvoiceNumber = 1
        businessProfile.invoiceNumberPadding = 4
        businessProfile.invoiceNumberFormat = .sequential
        
        let invoiceNumber = businessProfile.generateNextInvoiceNumber()
        
        #expect(invoiceNumber == "INV-0001")
    }
    
    @Test("BusinessProfile year sequential format")
    func businessProfileYearSequentialFormat() {
        var businessProfile = BusinessProfile(
            businessName: "Test Business",
            ownerName: "Test Owner",
            email: "test@business.com"
        )
        
        businessProfile.invoiceNumberPrefix = "INV"
        businessProfile.nextInvoiceNumber = 5
        businessProfile.invoiceNumberPadding = 3
        businessProfile.invoiceNumberFormat = .yearSequential
        
        let invoiceNumber = businessProfile.generateNextInvoiceNumber()
        let currentYear = Calendar.current.component(.year, from: Date())
        
        #expect(invoiceNumber == "INV-\(currentYear)-005")
    }
    
    @Test("BusinessProfile custom format with year and month")
    func businessProfileCustomFormat() {
        var businessProfile = BusinessProfile(
            businessName: "Test Business",
            ownerName: "Test Owner",
            email: "test@business.com"
        )
        
        businessProfile.invoiceNumberPrefix = "INVOICE"
        businessProfile.nextInvoiceNumber = 10
        businessProfile.invoiceNumberPadding = 2
        businessProfile.invoiceNumberFormat = .custom
        businessProfile.includeYearInInvoiceNumber = true
        businessProfile.includeMonthInInvoiceNumber = true
        
        let invoiceNumber = businessProfile.generateNextInvoiceNumber()
        let currentYear = Calendar.current.component(.year, from: Date())
        let currentMonth = String(format: "%02d", Calendar.current.component(.month, from: Date()))
        
        #expect(invoiceNumber.contains("INVOICE"))
        #expect(invoiceNumber.contains("\(currentYear)"))
        #expect(invoiceNumber.contains(currentMonth))
        #expect(invoiceNumber.contains("10"))
    }
}

@Suite("Payment Terms Tests")
struct PaymentTermsTests {
    
    @Test("PaymentTerms enum cases")
    func paymentTermsCases() {
        let terms = PaymentTerms.allCases
        
        #expect(terms.contains(.immediate))
        #expect(terms.contains(.net15))
        #expect(terms.contains(.net30))
        #expect(terms.contains(.net60))
        #expect(terms.contains(.net90))
    }
    
    @Test("PaymentTerms display names")
    func paymentTermsDisplayNames() {
        #expect(PaymentTerms.immediate.displayName == "Due Immediately")
        #expect(PaymentTerms.net15.displayName == "Net 15")
        #expect(PaymentTerms.net30.displayName == "Net 30")
        #expect(PaymentTerms.net60.displayName == "Net 60")
        #expect(PaymentTerms.net90.displayName == "Net 90")
    }
    
    @Test("PaymentTerms days values")
    func paymentTermsDays() {
        #expect(PaymentTerms.immediate.days == 0)
        #expect(PaymentTerms.net15.days == 15)
        #expect(PaymentTerms.net30.days == 30)
        #expect(PaymentTerms.net60.days == 60)
        #expect(PaymentTerms.net90.days == 90)
    }
}