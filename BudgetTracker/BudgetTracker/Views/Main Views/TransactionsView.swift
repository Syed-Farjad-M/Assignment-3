import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var showingAddTransaction = false
    @State private var showingFilterSheet = false
    @State private var editingTransaction: Transaction?
    
    // Create a properly connected TransactionViewModel using the shared DataManager
    private var viewModel: TransactionViewModel {
        TransactionViewModel(dataManager: dataManager)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search and filter bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search transactions", text: Binding(
                            get: { viewModel.searchText },
                            set: { viewModel.searchText = $0 }
                        ))
                        .disableAutocorrection(true)
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    Button(action: {
                        showingFilterSheet = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        FilterChip(
                            title: viewModel.selectedDateRange.rawValue,
                            isSelected: true
                        ) {
                            showingFilterSheet = true
                        }
                        
                        if let type = viewModel.selectedTransactionType {
                            FilterChip(
                                title: type.rawValue,
                                isSelected: true
                            ) {
                                viewModel.selectedTransactionType = nil
                            }
                        }
                        
                        if let category = viewModel.selectedCategory {
                            FilterChip(
                                title: category.name,
                                isSelected: true
                            ) {
                                viewModel.selectedCategory = nil
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Transactions list
                if viewModel.filteredTransactions.isEmpty {
                    VStack {
                        Spacer()
                        Text("No transactions found")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(viewModel.filteredTransactions) { transaction in
                            TransactionRowView(transaction: transaction)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingTransaction = transaction
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        viewModel.deleteTransaction(transaction)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Transactions")
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
            .sheet(item: $editingTransaction) { transaction in
                AddTransactionView(editTransaction: transaction)
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterView(viewModel: viewModel)
            }
            .onAppear {
                // Force the view model to refresh data when the view appears
                viewModel.applyFilters()
            }
        }
    }
}

struct FilterChip: View {
    var title: String
    var isSelected: Bool
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.footnote)
                
                if isSelected {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(15)
        }
    }
}

struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: TransactionViewModel
    @EnvironmentObject private var dataManager: DataManager
    
    var body: some View {
        NavigationView {
            Form {
                // Date Range Filter
                Section(header: Text("Date Range")) {
                    ForEach(TransactionViewModel.DateRange.allCases) { range in
                        Button(action: {
                            viewModel.selectedDateRange = range
                        }) {
                            HStack {
                                Text(range.rawValue)
                                Spacer()
                                if viewModel.selectedDateRange == range {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                // Transaction Type Filter
                Section(header: Text("Transaction Type")) {
                    Button(action: {
                        viewModel.selectedTransactionType = nil
                    }) {
                        HStack {
                            Text("All")
                            Spacer()
                            if viewModel.selectedTransactionType == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    
                    ForEach(TransactionType.allCases) { type in
                        Button(action: {
                            viewModel.selectedTransactionType = type
                        }) {
                            HStack {
                                Text(type.rawValue)
                                Spacer()
                                if viewModel.selectedTransactionType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                // Category Filter
                Section(header: Text("Category")) {
                    Button(action: {
                        viewModel.selectedCategory = nil
                    }) {
                        HStack {
                            Text("All Categories")
                            Spacer()
                            if viewModel.selectedCategory == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    
                    ForEach(dataManager.categories) { category in
                        Button(action: {
                            viewModel.selectedCategory = category
                        }) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(category.color.opacity(0.2))
                                        .frame(width: 30, height: 30)
                                    
                                    Image(systemName: category.icon)
                                        .foregroundColor(category.color)
                                }
                                
                                Text(category.name)
                                Spacer()
                                if viewModel.selectedCategory?.id == category.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Filter Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
