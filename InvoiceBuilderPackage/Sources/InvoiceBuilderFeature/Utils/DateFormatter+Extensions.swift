import Foundation

public extension DateFormatter {
    static let invoiceDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()
}

public extension Date {
    var invoiceDateString: String {
        DateFormatter.invoiceDateFormatter.string(from: self)
    }
    
    var shortDateString: String {
        DateFormatter.shortDateFormatter.string(from: self)
    }
    
    var fullDateString: String {
        DateFormatter.fullDateFormatter.string(from: self)
    }
}