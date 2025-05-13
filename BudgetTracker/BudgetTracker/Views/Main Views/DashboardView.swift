import SwiftUI
import Combine

class DashboardViewModel: ObservableObject {
    var cancellables = Set<AnyCancellable>()
    @Published var showingBudgetAlert = false
    @Published var alertBudget: Budget?
    @Published var alertProgress: Double = 0
    
    func setupBudgetAlerts(dataManager: DataManager) {
        dataManager.budgetAlertPublisher.sink { [weak self] (budget, progress) in
            self?.alertBudget = budget
            self?.alertProgress = progress
            self?.showingBudgetAlert = true
        }
        .store(in: &cancellables)
    }
}

struct DashboardView: View {
    @EnvironmentObject private var dataManager: DataManager
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @State private var showingAddTransaction = false
    
    // Create the TransactionViewModel using the environment's DataManager
    private var viewModel: TransactionViewModel {
        TransactionViewModel(dataManager: dataManager)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Summary Cards
                    BalanceSummaryView(viewModel: viewModel)
                    
                    // Recent Transactions
                    RecentTransactionsView(viewModel: viewModel)
                    
                    // Budget Progress
                    BudgetOverviewView(budgets: dataManager.budgets, transactions: dataManager.transactions)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTransaction = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
            .alert("Budget Alert", isPresented: $dashboardViewModel.showingBudgetAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                if let budget = dashboardViewModel.alertBudget {
                    Text("You've used \(Int(dashboardViewModel.alertProgress * 100))% of your \(budget.category.name) budget for this \(budget.period.rawValue.lowercased()) period.")
                }
            }
            .onAppear {
                dashboardViewModel.setupBudgetAlerts(dataManager: dataManager)
            }
        }
    }
}

// MARK: - Subviews

struct BalanceSummaryView: View {
    var viewModel: TransactionViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Current Balance Card
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
                
                VStack {
                    Text("Current Balance")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(Formatters.formatCurrency(viewModel.balance()))
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(viewModel.balance() >= 0 ? .green : .red)
                }
                .padding()
            }
            .frame(height: 100)
            
            // Income and Expense Summary
            HStack(spacing: 16) {
                // Income Card
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "arrow.down")
                                .foregroundColor(.green)
                            Text("Income")
                                .font(.subheadline)
                        }
                        
                        Text(Formatters.formatCurrency(viewModel.totalIncome()))
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Expense Card
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.1))
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "arrow.up")
                                .foregroundColor(.red)
                            Text("Expenses")
                                .font(.subheadline)
                        }
                        
                        Text(Formatters.formatCurrency(viewModel.totalExpenses()))
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: 80)
        }
    }
}

struct RecentTransactionsView: View {
    var viewModel: TransactionViewModel
    @EnvironmentObject private var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Transactions")
                .font(.headline)
            
            if viewModel.filteredTransactions.isEmpty {
                Text("No transactions to display")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(Array(viewModel.filteredTransactions.prefix(5))) { transaction in
                    TransactionRowView(transaction: transaction)
                }
                
                NavigationLink(destination: TransactionsView()) {
                    Text("View All")
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
        .onAppear {
            // Force the view model to apply filters when the view appears
            viewModel.applyFilters()
        }
    }
}

// Rest of the subviews same as before...

struct BudgetOverviewView: View {
    var budgets: [Budget]
    var transactions: [Transaction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Budget Overview")
                .font(.headline)
            
            if budgets.isEmpty {
                Text("No budgets set")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(budgets) { budget in
                    BudgetProgressView(budget: budget, transactions: transactions)
                }
                
                NavigationLink(destination: BudgetSettingsView()) {
                    Text("Manage Budgets")
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

struct TransactionRowView: View {
    var transaction: Transaction
    
    var body: some View {
        HStack {
            // Category Icon
            ZStack {
                Circle()
                    .fill(transaction.category.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: transaction.category.icon)
                    .foregroundColor(transaction.category.color)
            }
            
            // Transaction details
            VStack(alignment: .leading) {
                Text(transaction.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(transaction.category.name)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing) {
                Text(Formatters.formatCurrency(transaction.amount))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(transaction.type == .income ? .green : .red)
                
                Text(Formatters.formatShortDate(transaction.date))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
}

struct BudgetProgressView: View {
    var budget: Budget
    var transactions: [Transaction]
    
    var progress: Double {
        budget.calculateProgress(for: transactions)
    }
    
    var spent: Double {
        let relevantTransactions = budget.getRelevantTransactions(from: transactions)
        return relevantTransactions.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Category info
                HStack {
                    Image(systemName: budget.category.icon)
                        .foregroundColor(budget.category.color)
                    
                    Text(budget.category.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Budget info
                Text("\(Formatters.formatCurrency(spent)) / \(Formatters.formatCurrency(budget.amount))")
                    .font(.caption)
                    .foregroundColor(progress > 1.0 ? .red : .primary)
            }
            
            // Progress bar
            ProgressView(value: min(progress, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                .frame(height: 5)
        }
        .padding(.vertical, 4)
    }
    
    var progressColor: Color {
        if progress >= 1.0 {
            return .red
        } else if progress >= 0.8 {
            return .orange
        } else {
            return .green
        }
    }
}
