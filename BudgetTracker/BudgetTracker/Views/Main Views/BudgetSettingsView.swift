import SwiftUI

struct BudgetSettingsView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var showingAddBudget = false
    @State private var editingBudget: Budget?
    
    var body: some View {
        NavigationView {
            List {
                if dataManager.budgets.isEmpty {
                    Text("No budgets set yet. Tap the + button to add a budget.")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(dataManager.budgets) { budget in
                        BudgetRowView(budget: budget, transactions: dataManager.transactions)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingBudget = budget
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    dataManager.deleteBudget(budget)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .navigationTitle("Budget Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddBudget = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddBudget) {
                AddBudgetView()
            }
            .sheet(item: $editingBudget) { budget in
                AddBudgetView(editBudget: budget)
            }
        }
    }
}

struct BudgetRowView: View {
    var budget: Budget
    var transactions: [Transaction]
    
    var progress: Double {
        budget.calculateProgress(for: transactions)
    }
    
    var spent: Double {
        let relevantTransactions = budget.getRelevantTransactions(from: transactions)
        return relevantTransactions.reduce(0) { $0 + $1.amount }
    }
    
    var remaining: Double {
        return budget.amount - spent
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with category and amount
            HStack {
                // Category icon
                ZStack {
                    Circle()
                        .fill(budget.category.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: budget.category.icon)
                        .foregroundColor(budget.category.color)
                }
                
                VStack(alignment: .leading) {
                    Text(budget.category.name)
                        .font(.headline)
                    
                    Text("\(budget.period.rawValue) Budget")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Amount
                Text(Formatters.formatCurrency(budget.amount))
                    .font(.headline)
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                // Progress percentage
                HStack {
                    Text("Progress")
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .foregroundColor(progressColor)
                }
                .font(.caption)
                
                ProgressView(value: min(progress, 1.0))
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                    .frame(height: 8)
            }
            
            // Spent and remaining
            HStack {
                VStack(alignment: .leading) {
                    Text("Spent")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(Formatters.formatCurrency(spent))
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(Formatters.formatCurrency(remaining))
                        .font(.subheadline)
                        .foregroundColor(remaining < 0 ? .red : .primary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
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

struct AddBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    
    // Properties for tracking the budget fields
    @State private var selectedCategory: Category?
    @State private var amount: String = ""
    @State private var selectedPeriod: BudgetPeriod = .monthly
    @State private var startDate: Date = Date().startOfMonth()
    
    // Properties for validation
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    // For edit mode
    var editBudget: Budget?
    var isEditMode: Bool { editBudget != nil }
    
    init(editBudget: Budget? = nil) {
        self.editBudget = editBudget
        
        // Initialize state variables if in edit mode
        if let budget = editBudget {
            _selectedCategory = State(initialValue: budget.category)
            _amount = State(initialValue: String(format: "%.2f", budget.amount))
            _selectedPeriod = State(initialValue: budget.period)
            _startDate = State(initialValue: budget.startDate)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Budget Category
                Section(header: Text("Category")) {
                    NavigationLink(destination: BudgetCategoryPickerView(selectedCategory: $selectedCategory)) {
                        HStack {
                            Text("Category")
                            Spacer()
                            if let category = selectedCategory {
                                HStack {
                                    Text(category.name)
                                    Image(systemName: category.icon)
                                        .foregroundColor(category.color)
                                }
                                .foregroundColor(.primary)
                            } else {
                                Text("Select")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                // Budget Amount
                Section(header: Text("Budget Amount")) {
                    HStack {
                        Text(Locale.current.currencySymbol ?? "$")
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                }
                
                // Budget Period
                Section(header: Text("Budget Period")) {
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(BudgetPeriod.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    DatePicker(
                        "Start Date",
                        selection: $startDate,
                        displayedComponents: [.date]
                    )
                }
            }
            .navigationTitle(isEditMode ? "Edit Budget" : "Add Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditMode ? "Update" : "Save") {
                        if validateInput() {
                            saveBudget()
                            dismiss()
                        }
                    }
                }
            }
            .alert(isPresented: $showingValidationAlert) {
                Alert(
                    title: Text("Invalid Input"),
                    message: Text(validationMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func validateInput() -> Bool {
        // Check for category
        if selectedCategory == nil {
            validationMessage = "Please select a category."
            showingValidationAlert = true
            return false
        }
        
        // Check for valid amount
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            validationMessage = "Please enter a valid amount."
            showingValidationAlert = true
            return false
        }
        
        if amountValue <= 0 {
            validationMessage = "Amount must be greater than zero."
            showingValidationAlert = true
            return false
        }
        
        // Check if a budget for this category and period already exists
        let existingBudgets = dataManager.budgets.filter { budget in
            let isSameCategory = budget.category.id == selectedCategory?.id
            let isSamePeriod = budget.period == selectedPeriod
            
            var isSameTimeFrame = false
            switch selectedPeriod {
            case .monthly:
                isSameTimeFrame = Calendar.current.isDate(budget.startDate, equalTo: startDate, toGranularity: .month)
            case .weekly:
                isSameTimeFrame = Calendar.current.isDate(budget.startDate, equalTo: startDate, toGranularity: .weekOfYear)
            case .yearly:
                isSameTimeFrame = Calendar.current.isDate(budget.startDate, equalTo: startDate, toGranularity: .year)
            }
            
            // Exclude the current budget being edited
            let isDifferentBudget = isEditMode ? budget.id != editBudget?.id : true
            
            return isSameCategory && isSamePeriod && isSameTimeFrame && isDifferentBudget
        }
        
        if !existingBudgets.isEmpty {
            validationMessage = "A budget for this category and period already exists."
            showingValidationAlert = true
            return false
        }
        
        return true
    }
    
    private func saveBudget() {
        // Convert amount to Double
        let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0
        
        // Ensure we have a category
        guard let category = selectedCategory else { return }
        
        if isEditMode, let existingBudget = editBudget {
            // Create updated budget
            let updatedBudget = Budget(
                id: existingBudget.id,
                category: category,
                amount: amountValue,
                period: selectedPeriod,
                startDate: startDate
            )
            
            // Update in data manager
            dataManager.updateBudget(updatedBudget)
        } else {
            // Create new budget
            let newBudget = Budget(
                category: category,
                amount: amountValue,
                period: selectedPeriod,
                startDate: startDate
            )
            
            // Add to data manager
            dataManager.addBudget(newBudget)
        }
    }
}

struct BudgetCategoryPickerView: View {
    @Binding var selectedCategory: Category?
    @EnvironmentObject private var dataManager: DataManager
    
    // Only show expense categories for budgets
    var expenseCategories: [Category] {
        dataManager.categories.filter { $0.name.lowercased() != "income" }
    }
    
    var body: some View {
        List {
            ForEach(expenseCategories) { category in
                Button(action: {
                    selectedCategory = category
                }) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(category.color.opacity(0.2))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                        }
                        
                        Text(category.name)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedCategory?.id == category.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Select Category")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BudgetSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager()
        return BudgetSettingsView()
            .environmentObject(dataManager)
    }
}
