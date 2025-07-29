import Foundation

public struct CurrencyFormatter {
    private let formatter: NumberFormatter
    
    public init(currency: Currency = .usd) {
        self.formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.rawValue
        formatter.locale = Locale.current
    }
    
    public func string(from decimal: Decimal) -> String {
        return formatter.string(from: NSDecimalNumber(decimal: decimal)) ?? "$0.00"
    }
    
    public func string(from double: Double) -> String {
        return formatter.string(from: NSNumber(value: double)) ?? "$0.00"
    }
    
    public static func format(_ decimal: Decimal, currency: Currency = .usd) -> String {
        let formatter = CurrencyFormatter(currency: currency)
        return formatter.string(from: decimal)
    }
}