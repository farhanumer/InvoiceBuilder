import Foundation

public enum ValidationError: Error, LocalizedError, Equatable {
    case required(field: String)
    case invalidEmail(String)
    case invalidPhone(String) 
    case invalidURL(String)
    case invalidAmount(String)
    case invalidQuantity(String)
    case invalidTaxRate(String)
    case invalidDate(String)
    case tooLong(field: String, maxLength: Int)
    case tooShort(field: String, minLength: Int)
    case custom(String)
    
    public var errorDescription: String? {
        switch self {
        case .required(let field):
            return "\(field) is required"
        case .invalidEmail(let email):
            return "'\(email)' is not a valid email address"
        case .invalidPhone(let phone):
            return "'\(phone)' is not a valid phone number"
        case .invalidURL(let url):
            return "'\(url)' is not a valid URL"
        case .invalidAmount(let amount):
            return "'\(amount)' is not a valid amount"
        case .invalidQuantity(let quantity):
            return "'\(quantity)' is not a valid quantity"
        case .invalidTaxRate(let rate):
            return "'\(rate)' is not a valid tax rate"
        case .invalidDate(let date):
            return "'\(date)' is not a valid date"
        case .tooLong(let field, let maxLength):
            return "\(field) cannot be longer than \(maxLength) characters"
        case .tooShort(let field, let minLength):
            return "\(field) must be at least \(minLength) characters"
        case .custom(let message):
            return message
        }
    }
}

public struct ValidationResult: Sendable {
    public let isValid: Bool
    public let errors: [ValidationError]
    
    public init(isValid: Bool, errors: [ValidationError] = []) {
        self.isValid = isValid
        self.errors = errors
    }
    
    public static let valid = ValidationResult(isValid: true)
    
    public static func invalid(_ errors: [ValidationError]) -> ValidationResult {
        ValidationResult(isValid: false, errors: errors)
    }
    
    public static func invalid(_ error: ValidationError) -> ValidationResult {
        ValidationResult(isValid: false, errors: [error])
    }
}