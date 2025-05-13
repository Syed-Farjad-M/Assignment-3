import Foundation

enum TransactionType: String, CaseIterable, Identifiable, Codable {
    case income = "Income"
    case expense = "Expense"
    
    var id: String { self.rawValue }
}

struct Transaction: Identifiable, Codable {
    var id = UUID()
    var amount: Double
    var title: String
    var category: Category
    var date: Date
    var type: TransactionType
    var notes: String?
    
    // Computed property to get sign-adjusted amount
    var signedAmount: Double {
        return type == .expense ? -amount : amount
    }
}

// Sample data for preview
extension Transaction {
    static var sampleData: [Transaction] {
        [
            Transaction(
                amount: 45.50,
                title: "Grocery Shopping",
                category: Category.sampleData[0],
                date: Date().addingTimeInterval(-86400), // Yesterday
                type: .expense,
                notes: "Weekly groceries"
            ),
            Transaction(
                amount: 1500.00,
                title: "Salary",
                category: Category.sampleData[5],
                date: Date().addingTimeInterval(-604800), // Last week
                type: .income,
                notes: "Monthly salary"
            ),
            Transaction(
                amount: 25.00,
                title: "Movie tickets",
                category: Category.sampleData[3],
                date: Date().addingTimeInterval(-172800), // Two days ago
                type: .expense,
                notes: nil
            )
        ]
    }
}
