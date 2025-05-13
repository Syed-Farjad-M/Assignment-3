import Foundation
import Combine

class TransactionViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var filteredTransactions: [Transaction] = []
    
    @Published var searchText: String = ""
    @Published var selectedTransactionType: TransactionType?
    @Published var selectedCategory: Category?
    @Published var selectedDateRange: DateRange = .thisMonth
    
    var cancellables = Set<AnyCancellable>()
    private var dataManager: DataManager
    
    enum DateRange: String, CaseIterable, Identifiable {
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case last3Months = "Last 3 Months"
        case thisYear = "This Year"
        case allTime = "All Time"
        
        var id: String { self.rawValue }
    }
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        
        // Subscribe to the dataManager's transactions updates
        dataManager.$transactions
            .sink { [weak self] transactions in
                self?.transactions = transactions
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        // Subscribe to filter changes
        $searchText
            .combineLatest($selectedTransactionType, $selectedCategory, $selectedDateRange)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        // Initial filter application
        DispatchQueue.main.async {
            self.applyFilters()
        }
    }
    
    // MARK: - Transaction Operations
    
    func addTransaction(_ transaction: Transaction) {
        dataManager.addTransaction(transaction)
    }
    
    func updateTransaction(_ transaction: Transaction) {
        dataManager.updateTransaction(transaction)
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        dataManager.deleteTransaction(transaction)
    }
    
    // MARK: - Computed Properties
    
    func totalIncome(for transactions: [Transaction] = []) -> Double {
        let transactionsToAnalyze = transactions.isEmpty ? self.filteredTransactions : transactions
        return transactionsToAnalyze
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    func totalExpenses(for transactions: [Transaction] = []) -> Double {
        let transactionsToAnalyze = transactions.isEmpty ? self.filteredTransactions : transactions
        return transactionsToAnalyze
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    func balance(for transactions: [Transaction] = []) -> Double {
        return totalIncome(for: transactions) - totalExpenses(for: transactions)
    }
    
    func groupTransactionsByCategory() -> [Category: [Transaction]] {
        let expenseTransactions = filteredTransactions.filter { $0.type == .expense }
        return Dictionary(grouping: expenseTransactions, by: { $0.category })
    }
    
    func categorySpendingData() -> [(Category, Double)] {
        let groupedTransactions = groupTransactionsByCategory()
        
        return groupedTransactions.map { category, transactions in
            let total = transactions.reduce(0) { $0 + $1.amount }
            return (category, total)
        }.sorted { $0.1 > $1.1 } // Sort by amount descending
    }
    
    // MARK: - Filtering
    
    func applyFilters() {
        // Start with all transactions
        filteredTransactions = transactions
        print("Filtering \(transactions.count) transactions")
        
        // Apply search text filter
        if !searchText.isEmpty {
            filteredTransactions = filteredTransactions.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.notes?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        // Apply transaction type filter
        if let type = selectedTransactionType {
            filteredTransactions = filteredTransactions.filter { $0.type == type }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            filteredTransactions = filteredTransactions.filter { $0.category.id == category.id }
        }
        
        // Apply date range filter
        filteredTransactions = filteredTransactions.filter { isTransactionInSelectedDateRange($0) }
        
        // Sort by date (newest first)
        filteredTransactions.sort { $0.date > $1.date }
        
        print("After filtering: \(filteredTransactions.count) transactions")
    }
    
    private func isTransactionInSelectedDateRange(_ transaction: Transaction) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedDateRange {
        case .today:
            return calendar.isDate(transaction.date, inSameDayAs: now)
            
        case .thisWeek:
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            return transaction.date >= weekStart && transaction.date < weekEnd
            
        case .thisMonth:
            return calendar.isDate(transaction.date, equalTo: now, toGranularity: .month)
            
        case .last3Months:
            guard let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) else {
                return false
            }
            return transaction.date >= threeMonthsAgo
            
        case .thisYear:
            return calendar.isDate(transaction.date, equalTo: now, toGranularity: .year)
            
        case .allTime:
            return true
        }
    }
    
    // Helper method to store a cancellable
    func storeCancellable(_ cancellable: AnyCancellable) {
        cancellable.store(in: &cancellables)
    }
}
