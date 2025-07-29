import Testing
import Foundation
@testable import InvoiceBuilderFeature

@Suite("Validators Tests")
struct ValidatorsTests {
    
    @Test("Email validation")
    func testEmailValidation() async throws {
        // Valid emails
        let validEmails = [
            "test@example.com",
            "user.name@domain.co.uk",
            "user+tag@example.org",
            "123@test.com"
        ]
        
        for email in validEmails {
            let result = Validators.validateEmail(email)
            #expect(result.isValid == true, "Email '\(email)' should be valid")
        }
        
        // Invalid emails
        let invalidEmails = [
            "invalid-email",
            "@example.com",
            "test@",
            "test..test@example.com",
            ""
        ]
        
        for email in invalidEmails {
            let result = Validators.validateEmail(email)
            #expect(result.isValid == false, "Email '\(email)' should be invalid")
        }
        
        // Nil email
        let nilResult = Validators.validateEmail(nil)
        #expect(nilResult.isValid == false)
    }
    
    @Test("Phone validation")
    func testPhoneValidation() async throws {
        // Valid phones (optional field, so valid includes nil)
        let validPhones = [
            "+1234567890",
            "(555) 123-4567",
            "555-123-4567",
            "15551234567",
            nil // Phone is optional
        ]
        
        for phone in validPhones {
            let result = Validators.validatePhone(phone)
            #expect(result.isValid == true, "Phone '\(phone ?? "nil")' should be valid")
        }
        
        // Invalid phones (too short)
        let invalidPhones = [
            "123",
            "12345",
            "abc123def"
        ]
        
        for phone in invalidPhones {
            let result = Validators.validatePhone(phone)
            #expect(result.isValid == false, "Phone '\(phone)' should be invalid")
        }
    }
    
    @Test("URL validation")
    func testURLValidation() async throws {
        // Valid URLs
        let validURLs = [
            "https://example.com",
            "http://test.org",
            "example.com", // Should be valid, gets https:// prepended
            "www.test.com",
            nil // URL is optional
        ]
        
        for url in validURLs {
            let result = Validators.validateURL(url)
            #expect(result.isValid == true, "URL '\(url ?? "nil")' should be valid")
        }
        
        // Invalid URLs
        let invalidURLs = [
            "not a url",
            "://example.com",
            "ht tp://example.com"
        ]
        
        for url in invalidURLs {
            let result = Validators.validateURL(url)
            #expect(result.isValid == false, "URL '\(url)' should be invalid")
        }
    }
    
    @Test("Amount validation")
    func testAmountValidation() async throws {
        // Valid amounts
        let validAmounts: [Decimal] = [0, 10.50, 1000, 0.01]
        
        for amount in validAmounts {
            let result = Validators.validateAmount(amount)
            #expect(result.isValid == true, "Amount '\(amount)' should be valid")
        }
        
        // Invalid amounts
        let invalidAmounts: [Decimal] = [-1, -0.01, -100]
        
        for amount in invalidAmounts {
            let result = Validators.validateAmount(amount)
            #expect(result.isValid == false, "Amount '\(amount)' should be invalid")
        }
        
        // Nil amount
        let nilResult = Validators.validateAmount(nil)
        #expect(nilResult.isValid == false)
    }
    
    @Test("Quantity validation")
    func testQuantityValidation() async throws {
        // Valid quantities
        let validQuantities: [Decimal] = [1, 10.5, 0.1, 100]
        
        for quantity in validQuantities {
            let result = Validators.validateQuantity(quantity)
            #expect(result.isValid == true, "Quantity '\(quantity)' should be valid")
        }
        
        // Invalid quantities
        let invalidQuantities: [Decimal] = [0, -1, -0.5]
        
        for quantity in invalidQuantities {
            let result = Validators.validateQuantity(quantity)
            #expect(result.isValid == false, "Quantity '\(quantity)' should be invalid")
        }
        
        // Nil quantity
        let nilResult = Validators.validateQuantity(nil)
        #expect(nilResult.isValid == false)
    }
    
    @Test("Tax rate validation")
    func testTaxRateValidation() async throws {
        // Valid tax rates
        let validRates: [Decimal?] = [nil, 0, 5.5, 10, 25, 100]
        
        for rate in validRates {
            let result = Validators.validateTaxRate(rate)
            #expect(result.isValid == true, "Tax rate '\(rate?.description ?? "nil")' should be valid")
        }
        
        // Invalid tax rates
        let invalidRates: [Decimal] = [-1, 101, 150]
        
        for rate in invalidRates {
            let result = Validators.validateTaxRate(rate)
            #expect(result.isValid == false, "Tax rate '\(rate)' should be invalid")
        }
    }
    
    @Test("Required field validation")
    func testRequiredValidation() async throws {
        // Valid required fields
        let validValues = ["test", "  value  ", "123"]
        
        for value in validValues {
            let result = Validators.validateRequired(value, field: "Test Field")
            #expect(result.isValid == true, "Value '\(value)' should be valid")
        }
        
        // Invalid required fields
        let invalidValues: [String?] = [nil, "", "  ", "\t\n"]
        
        for value in invalidValues {
            let result = Validators.validateRequired(value, field: "Test Field")
            #expect(result.isValid == false, "Value '\(value ?? "nil")' should be invalid")
        }
    }
    
    @Test("Length validation")
    func testLengthValidation() async throws {
        let testValue = "Hello World"
        
        // Valid lengths
        let validMinResult = Validators.validateLength(testValue, field: "Test", minLength: 5)
        #expect(validMinResult.isValid == true)
        
        let validMaxResult = Validators.validateLength(testValue, field: "Test", maxLength: 20)
        #expect(validMaxResult.isValid == true)
        
        let validBothResult = Validators.validateLength(testValue, field: "Test", minLength: 5, maxLength: 20)
        #expect(validBothResult.isValid == true)
        
        // Invalid lengths
        let invalidMinResult = Validators.validateLength(testValue, field: "Test", minLength: 20)
        #expect(invalidMinResult.isValid == false)
        
        let invalidMaxResult = Validators.validateLength(testValue, field: "Test", maxLength: 5)
        #expect(invalidMaxResult.isValid == false)
        
        // Nil value (should be valid for optional fields)
        let nilResult = Validators.validateLength(nil, field: "Test", minLength: 5)
        #expect(nilResult.isValid == true)
    }
    
    @Test("Client validation")
    func testClientValidation() async throws {
        // Valid client
        let validClient = Client(
            name: "John Doe",
            email: "john@example.com",
            phone: "+1234567890",
            company: "Test Corp",
            website: "https://example.com"
        )
        
        let validResult = Validators.validateClient(validClient)
        #expect(validResult.isValid == true)
        
        // Invalid client (missing required fields)
        let invalidClient = Client(
            name: "", // Empty name
            email: "invalid-email", // Invalid email
            phone: "123", // Invalid phone
            website: "not a url" // Invalid URL
        )
        
        let invalidResult = Validators.validateClient(invalidClient)
        #expect(invalidResult.isValid == false)
        #expect(invalidResult.errors.count > 0)
    }
    
    @Test("Invoice item validation")
    func testInvoiceItemValidation() async throws {
        // Valid invoice item
        let validItem = InvoiceItem(
            name: "Test Service",
            description: "Test description",
            quantity: 1,
            rate: 100,
            taxRate: 10
        )
        
        let validResult = Validators.validateInvoiceItem(validItem)
        #expect(validResult.isValid == true)
        
        // Invalid invoice item
        let invalidItem = InvoiceItem(
            name: "", // Empty name
            description: "", // Empty description
            quantity: 0, // Invalid quantity
            rate: -10, // Invalid rate
            taxRate: 150, // Invalid tax rate
            discountAmount: -5 // Invalid discount
        )
        
        let invalidResult = Validators.validateInvoiceItem(invalidItem)
        #expect(invalidResult.isValid == false)
        #expect(invalidResult.errors.count > 0)
    }
    
    @Test("Due date validation")
    func testDueDateValidation() async throws {
        let issueDate = Date()
        let validDueDate = Date().addingTimeInterval(86400) // Tomorrow
        let invalidDueDate = Date().addingTimeInterval(-86400) // Yesterday
        
        // Valid due date
        let validResult = Validators.validateDueDate(validDueDate, issueDate: issueDate)
        #expect(validResult.isValid == true)
        
        // Invalid due date (before issue date)
        let invalidResult = Validators.validateDueDate(invalidDueDate, issueDate: issueDate)
        #expect(invalidResult.isValid == false)
        
        // Nil due date
        let nilResult = Validators.validateDueDate(nil, issueDate: issueDate)
        #expect(nilResult.isValid == false)
    }
}