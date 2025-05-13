import Foundation

struct Budget: Identifiable, Codable {
    var id = UUID()
    var category: Category
    var amount: Double
    var period: BudgetPeriod
    var startDate: Date
    
    // For checking if budget exceeded or near threshold
    func calculateProgress(for transactions: [Transaction]) -> Double {
        let relevantTransactions = getRelevantTransactions(from: transactions)
        let totalSpent = relevantTransactions.reduce(0) { $0 + $1.amount }
        return totalSpent / amount
    }
    
    func getRelevantTransactions(from transactions: [Transaction]) -> [Transaction] {
        // Filter transactions based on category and time period
        let filteredByCategory = transactions.filter { $0.category.id == self.category.id && $0.type == .expense }
        
        // Apply date filtering based on period
        switch period {
        case .monthly:
            let calendar = Calendar.current
            return filteredByCategory.filter { transaction in
                calendar.isDate(transaction.date, equalTo: startDate, toGranularity: .month) &&
                calendar.isDate(transaction.date, equalTo: startDate, toGranularity: .year)
            }
        case .weekly:
            let calendar = Calendar.current
            guard let weekOfYear = calendar.dateComponents([.weekOfYear], from: startDate).weekOfYear else {
                return []
            }
            return filteredByCategory.filter { transaction in
                let transactionWeek = calendar.dateComponents([.weekOfYear], from: transaction.date).weekOfYear
                return transactionWeek == weekOfYear &&
                       calendar.isDate(transaction.date, equalTo: startDate, toGranularity: .year)
            }
        case .yearly:
            let calendar = Calendar.current
            return filteredByCategory.filter { transaction in
                calendar.isDate(transaction.date, equalTo: startDate, toGranularity: .year)
            }
        }
    }
}

enum BudgetPeriod: String, CaseIterable, Identifiable, Codable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    var id: String { self.rawValue }
}

// Sample data for preview
extension Budget {
    static var sampleData: [Budget] {
        [
            Budget(
                category: Category.sampleData[0], // Food
                amount: 300.00,
                period: .monthly,
                startDate: Date().startOfMonth()
            ),
            Budget(
                category: Category.sampleData[1], // Transport
                amount: 150.00,
                period: .monthly,
                startDate: Date().startOfMonth()
            ),
            Budget(
                category: Category.sampleData[3], // Entertainment
                amount: 100.00,
                period: .monthly,
                startDate: Date().startOfMonth()
            )
        ]
    }
}

// Helper extension for date calculations
extension Date {
    func startOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
}
