import Foundation

public struct Validators {
    
    // MARK: - String Validators
    
    public static func validateRequired(_ value: String?, field: String) -> ValidationResult {
        guard let value = value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .invalid(.required(field: field))
        }
        return .valid
    }
    
    public static func validateEmail(_ email: String?) -> ValidationResult {
        guard let email = email, !email.isEmpty else {
            return .invalid(.required(field: "Email"))
        }
        
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if emailPredicate.evaluate(with: email) {
            return .valid
        } else {
            return .invalid(.invalidEmail(email))
        }
    }
    
    public static func validatePhone(_ phone: String?) -> ValidationResult {
        guard let phone = phone, !phone.isEmpty else {
            return .valid // Phone is optional
        }
        
        // Remove all non-digit characters for validation
        let digitsOnly = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Check if it has at least 10 digits
        if digitsOnly.count >= 10 {
            return .valid
        } else {
            return .invalid(.invalidPhone(phone))
        }
    }
    
    public static func validateURL(_ urlString: String?) -> ValidationResult {
        guard let urlString = urlString, !urlString.isEmpty else {
            return .valid // URL is optional
        }
        
        var validURL = urlString
        if !urlString.lowercased().hasPrefix("http://") && !urlString.lowercased().hasPrefix("https://") {
            validURL = "https://" + urlString
        }
        
        if URL(string: validURL) != nil {
            return .valid
        } else {
            return .invalid(.invalidURL(urlString))
        }
    }
    
    public static func validateLength(_ value: String?, field: String, minLength: Int? = nil, maxLength: Int? = nil) -> ValidationResult {
        guard let value = value else {
            return .valid
        }
        
        var errors: [ValidationError] = []
        
        if let minLength = minLength, value.count < minLength {
            errors.append(.tooShort(field: field, minLength: minLength))
        }
        
        if let maxLength = maxLength, value.count > maxLength {
            errors.append(.tooLong(field: field, maxLength: maxLength))
        }
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
    
    // MARK: - Numeric Validators
    
    public static func validateAmount(_ amount: Decimal?) -> ValidationResult {
        guard let amount = amount else {
            return .invalid(.required(field: "Amount"))
        }
        
        if amount >= 0 {
            return .valid
        } else {
            return .invalid(.invalidAmount(amount.description))
        }
    }
    
    public static func validateQuantity(_ quantity: Decimal?) -> ValidationResult {
        guard let quantity = quantity else {
            return .invalid(.required(field: "Quantity"))
        }
        
        if quantity > 0 {
            return .valid
        } else {
            return .invalid(.invalidQuantity(quantity.description))
        }
    }
    
    public static func validateTaxRate(_ taxRate: Decimal?) -> ValidationResult {
        guard let taxRate = taxRate else {
            return .valid // Tax rate is optional
        }
        
        if taxRate >= 0 && taxRate <= 100 {
            return .valid
        } else {
            return .invalid(.invalidTaxRate(taxRate.description))
        }
    }
    
    // MARK: - Date Validators
    
    public static func validateDate(_ date: Date?, field: String) -> ValidationResult {
        guard date != nil else {
            return .invalid(.required(field: field))
        }
        return .valid
    }
    
    public static func validateDueDate(_ dueDate: Date?, issueDate: Date?) -> ValidationResult {
        guard let dueDate = dueDate else {
            return .invalid(.required(field: "Due Date"))
        }
        
        guard let issueDate = issueDate else {
            return .valid // Can't validate without issue date
        }
        
        if dueDate >= issueDate {
            return .valid
        } else {
            return .invalid(.custom("Due date must be on or after the issue date"))
        }
    }
    
    // MARK: - Business Object Validators
    
    public static func validateClient(_ client: Client) -> ValidationResult {
        var errors: [ValidationError] = []
        
        // Validate required fields
        let nameResult = validateRequired(client.name, field: "Name")
        if !nameResult.isValid {
            errors.append(contentsOf: nameResult.errors)
        }
        
        let emailResult = validateEmail(client.email)
        if !emailResult.isValid {
            errors.append(contentsOf: emailResult.errors)
        }
        
        // Validate optional fields
        let phoneResult = validatePhone(client.phone)
        if !phoneResult.isValid {
            errors.append(contentsOf: phoneResult.errors)
        }
        
        let websiteResult = validateURL(client.website)
        if !websiteResult.isValid {
            errors.append(contentsOf: websiteResult.errors)
        }
        
        // Validate field lengths
        let nameLengthResult = validateLength(client.name, field: "Name", maxLength: 100)
        if !nameLengthResult.isValid {
            errors.append(contentsOf: nameLengthResult.errors)
        }
        
        let companyLengthResult = validateLength(client.company, field: "Company", maxLength: 100)
        if !companyLengthResult.isValid {
            errors.append(contentsOf: companyLengthResult.errors)
        }
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
    
    public static func validateInvoiceItem(_ item: InvoiceItem) -> ValidationResult {
        var errors: [ValidationError] = []
        
        // Validate required fields
        let nameResult = validateRequired(item.name, field: "Item Name")
        if !nameResult.isValid {
            errors.append(contentsOf: nameResult.errors)
        }
        
        let descriptionResult = validateRequired(item.description, field: "Description")
        if !descriptionResult.isValid {
            errors.append(contentsOf: descriptionResult.errors)
        }
        
        let quantityResult = validateQuantity(item.quantity)
        if !quantityResult.isValid {
            errors.append(contentsOf: quantityResult.errors)
        }
        
        let rateResult = validateAmount(item.rate)
        if !rateResult.isValid {
            errors.append(contentsOf: rateResult.errors)
        }
        
        let taxRateResult = validateTaxRate(item.taxRate)
        if !taxRateResult.isValid {
            errors.append(contentsOf: taxRateResult.errors)
        }
        
        // Validate discount amount
        if item.discountAmount < 0 {
            errors.append(.invalidAmount(item.discountAmount.description))
        }
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
    
    public static func validateInvoice(_ invoice: Invoice) -> ValidationResult {
        var errors: [ValidationError] = []
        
        // Validate required fields
        let numberResult = validateRequired(invoice.invoiceNumber, field: "Invoice Number")
        if !numberResult.isValid {
            errors.append(contentsOf: numberResult.errors)
        }
        
        let dateResult = validateDate(invoice.date, field: "Issue Date")
        if !dateResult.isValid {
            errors.append(contentsOf: dateResult.errors)
        }
        
        let dueDateResult = validateDueDate(invoice.dueDate, issueDate: invoice.date)
        if !dueDateResult.isValid {
            errors.append(contentsOf: dueDateResult.errors)
        }
        
        // Validate client
        let clientResult = validateClient(invoice.client)
        if !clientResult.isValid {
            errors.append(contentsOf: clientResult.errors)
        }
        
        // Validate items
        if invoice.items.isEmpty {
            errors.append(.custom("Invoice must have at least one item"))
        } else {
            for (index, item) in invoice.items.enumerated() {
                let itemResult = validateInvoiceItem(item)
                if !itemResult.isValid {
                    for error in itemResult.errors {
                        errors.append(.custom("Item \(index + 1): \(error.localizedDescription)"))
                    }
                }
            }
        }
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
    
    public static func validateBusinessProfile(_ profile: BusinessProfile) -> ValidationResult {
        var errors: [ValidationError] = []
        
        // Validate required fields
        let businessNameResult = validateRequired(profile.businessName, field: "Business Name")
        if !businessNameResult.isValid {
            errors.append(contentsOf: businessNameResult.errors)
        }
        
        let ownerNameResult = validateRequired(profile.ownerName, field: "Owner Name")
        if !ownerNameResult.isValid {
            errors.append(contentsOf: ownerNameResult.errors)
        }
        
        let emailResult = validateEmail(profile.email)
        if !emailResult.isValid {
            errors.append(contentsOf: emailResult.errors)
        }
        
        // Validate optional fields
        let phoneResult = validatePhone(profile.phone)
        if !phoneResult.isValid {
            errors.append(contentsOf: phoneResult.errors)
        }
        
        let websiteResult = validateURL(profile.website)
        if !websiteResult.isValid {
            errors.append(contentsOf: websiteResult.errors)
        }
        
        // Validate tax rate
        let taxRateResult = validateTaxRate(profile.defaultTaxRate)
        if !taxRateResult.isValid {
            errors.append(contentsOf: taxRateResult.errors)
        }
        
        // Validate next invoice number
        if profile.nextInvoiceNumber < 1 {
            errors.append(.custom("Next invoice number must be at least 1"))
        }
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
}