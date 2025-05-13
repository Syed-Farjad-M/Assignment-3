import Foundation

class Formatters {
    // Currency formatter
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }()
    
    // Date formatter - short style
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    // Date formatter - medium style with time
    static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    // Month formatter
    static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    // Helper methods
    static func formatCurrency(_ amount: Double) -> String {
        return currencyFormatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    static func formatShortDate(_ date: Date) -> String {
        return shortDateFormatter.string(from: date)
    }
    
    static func formatMediumDate(_ date: Date) -> String {
        return mediumDateFormatter.string(from: date)
    }
    
    static func formatMonth(_ date: Date) -> String {
        return monthFormatter.string(from: date)
    }
}

