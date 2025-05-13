import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    
    // Properties for tracking the transaction fields
    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var selectedType: TransactionType = .expense
    @State private var selectedCategory: Category?
    @State private var date: Date = Date()
    @State private var notes: String = ""
    
    // Properties for validation
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    // For edit mode
    var editTransaction: Transaction?
    var isEditMode: Bool { editTransaction != nil }
    
    init(editTransaction: Transaction? = nil) {
        self.editTransaction = editTransaction
        
        // Initialize state variables if in edit mode
        if let transaction = editTransaction {
            _title = State(initialValue: transaction.title)
            _amount = State(initialValue: String(format: "%.2f", transaction.amount))
            _selectedType = State(initialValue: transaction.type)
            _selectedCategory = State(initialValue: transaction.category)
            _date = State(initialValue: transaction.date)
            _notes = State(initialValue: transaction.notes ?? "")
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Transaction Type Picker
                Section(header: Text("Transaction Type")) {
                    Picker("Type", selection: $selectedType) {
                        ForEach(TransactionType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Transaction Details
                Section(header: Text("Details")) {
                    TextField("Title", text: $title)
                    
                    HStack {
                        Text(Locale.current.currencySymbol ?? "$")
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    
                    NavigationLink(destination: CategoryPickerView(selectedCategory: $selectedCategory)) {
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
                    
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                // Optional Notes
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(isEditMode ? "Edit Transaction" : "Add Transaction")
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
                            saveTransaction()
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
            .onAppear {
                // Set default category if none selected
                if selectedCategory == nil && !dataManager.categories.isEmpty {
                    // Default category based on transaction type
                    if selectedType == .income {
                        selectedCategory = dataManager.categories.first { $0.name.lowercased() == "income" }
                    } else {
                        selectedCategory = dataManager.categories.first { $0.name.lowercased() != "income" }
                    }
                    
                    // If still nil, just use the first category
                    if selectedCategory == nil {
                        selectedCategory = dataManager.categories.first
                    }
                }
            }
        }
    }
    
    private func validateInput() -> Bool {
        // Check for title
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = "Please enter a title for the transaction."
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
        
        // Check for category
        if selectedCategory == nil {
            validationMessage = "Please select a category."
            showingValidationAlert = true
            return false
        }
        
        return true
    }
    
    private func saveTransaction() {
        // Convert amount to Double
        let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0
        
        // Ensure we have a category
        guard let category = selectedCategory else { return }
        
        if isEditMode, let existingTransaction = editTransaction {
            // Create updated transaction
            let updatedTransaction = Transaction(
                id: existingTransaction.id,
                amount: amountValue,
                title: title,
                category: category,
                date: date,
                type: selectedType,
                notes: notes.isEmpty ? nil : notes
            )
            
            // Update in data manager
            dataManager.updateTransaction(updatedTransaction)
        } else {
            // Create new transaction
            let newTransaction = Transaction(
                amount: amountValue,
                title: title,
                category: category,
                date: date,
                type: selectedType,
                notes: notes.isEmpty ? nil : notes
            )
            
            // Add to data manager
            dataManager.addTransaction(newTransaction)
        }
    }
}

struct CategoryPickerView: View {
    @Binding var selectedCategory: Category?
    @EnvironmentObject private var dataManager: DataManager
    
    var body: some View {
        List {
            ForEach(dataManager.categories) { category in
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

struct AddTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager()
        return AddTransactionView()
            .environmentObject(dataManager)
    }
}
