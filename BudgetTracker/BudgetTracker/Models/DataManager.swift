import Foundation
import Combine

class DataManager: ObservableObject {
    // Published properties for UI updates
    @Published var transactions: [Transaction] = []
    @Published var categories: [Category] = []
    @Published var budgets: [Budget] = []
    
    // File URLs for persistence
    private let transactionsURL = URL.documentsDirectory.appendingPathComponent("transactions.json")
    private let categoriesURL = URL.documentsDirectory.appendingPathComponent("categories.json")
    private let budgetsURL = URL.documentsDirectory.appendingPathComponent("budgets.json")
    
    // Notification publisher for budget alerts
    let budgetAlertPublisher = PassthroughSubject<(Budget, Double), Never>()
    
    init() {
        loadData()
        
        // If no categories exist, use sample data
        if categories.isEmpty {
            categories = Category.sampleData
            saveCategories()
        }
    }
    
    // MARK: - Data Operations
    
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        saveTransactions()
        checkBudgetLimits()
    }
    
    func updateTransaction(_ transaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
            saveTransactions()
            checkBudgetLimits()
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        transactions.removeAll { $0.id == transaction.id }
        saveTransactions()
        checkBudgetLimits()
    }
    
    func addCategory(_ category: Category) {
        categories.append(category)
        saveCategories()
    }
    
    func updateCategory(_ category: Category) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveCategories()
        }
    }
    
    func deleteCategory(_ category: Category) {
        // Remove related budgets first
        budgets.removeAll { $0.category.id == category.id }
        saveBudgets()
        
        // Then remove the category
        categories.removeAll { $0.id == category.id }
        saveCategories()
    }
    
    func addBudget(_ budget: Budget) {
        budgets.append(budget)
        saveBudgets()
        checkBudgetLimits()
    }
    
    func updateBudget(_ budget: Budget) {
        if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
            budgets[index] = budget
            saveBudgets()
            checkBudgetLimits()
        }
    }
    
    func deleteBudget(_ budget: Budget) {
        budgets.removeAll { $0.id == budget.id }
        saveBudgets()
    }
    
    // MARK: - Budget Alert Management
    
    private func checkBudgetLimits() {
        for budget in budgets {
            let progress = budget.calculateProgress(for: transactions)
            
            // Alert at 80% of budget
            if progress >= 0.8 {
                budgetAlertPublisher.send((budget, progress))
            }
        }
    }
    
    // MARK: - Persistence
    
    private func loadData() {
        transactions = loadTransactions()
        categories = loadCategories()
        budgets = loadBudgets()
    }
    
    private func saveTransactions() {
        do {
            let data = try JSONEncoder().encode(transactions)
            try data.write(to: transactionsURL)
        } catch {
            print("Error saving transactions: \(error)")
        }
    }
    
    private func saveCategories() {
        do {
            let data = try JSONEncoder().encode(categories)
            try data.write(to: categoriesURL)
        } catch {
            print("Error saving categories: \(error)")
        }
    }
    
    private func saveBudgets() {
        do {
            let data = try JSONEncoder().encode(budgets)
            try data.write(to: budgetsURL)
        } catch {
            print("Error saving budgets: \(error)")
        }
    }
    
    private func loadTransactions() -> [Transaction] {
        do {
            let data = try Data(contentsOf: transactionsURL)
            return try JSONDecoder().decode([Transaction].self, from: data)
        } catch {
            return []
        }
    }
    
    private func loadCategories() -> [Category] {
        do {
            let data = try Data(contentsOf: categoriesURL)
            return try JSONDecoder().decode([Category].self, from: data)
        } catch {
            return []
        }
    }
    
    private func loadBudgets() -> [Budget] {
        do {
            let data = try Data(contentsOf: budgetsURL)
            return try JSONDecoder().decode([Budget].self, from: data)
        } catch {
            return []
        }
    }
}

// Extension for URL documents directory
extension URL {
    static var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
