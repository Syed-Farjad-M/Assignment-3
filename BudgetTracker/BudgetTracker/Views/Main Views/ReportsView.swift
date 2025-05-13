import SwiftUI

struct ReportsView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var selectedReportType: ReportType = .expensesByCategory
    @State private var selectedDateRange: TransactionViewModel.DateRange = .thisMonth
    
    // Create viewModel using the shared dataManager
    private var viewModel: TransactionViewModel {
        let model = TransactionViewModel(dataManager: dataManager)
        model.selectedDateRange = selectedDateRange
        return model
    }
    
    enum ReportType: String, CaseIterable, Identifiable {
        case expensesByCategory = "Expenses by Category"
        case incomeVsExpenses = "Income vs Expenses"
        case spendingTrends = "Spending Trends"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Report Type Picker
                Picker("Report Type", selection: $selectedReportType) {
                    ForEach(ReportType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Date Range Picker
                Menu {
                    ForEach(TransactionViewModel.DateRange.allCases) { range in
                        Button {
                            selectedDateRange = range
                        } label: {
                            if selectedDateRange == range {
                                Label(range.rawValue, systemImage: "checkmark")
                            } else {
                                Text(range.rawValue)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text("Period: \(selectedDateRange.rawValue)")
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.down")
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                // Report Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Summary Cards
                        HStack(spacing: 16) {
                            // Income Card
                            SummaryCardView(
                                title: "Income",
                                amount: viewModel.totalIncome(),
                                iconName: "arrow.down",
                                color: .green
                            )
                            
                            // Expense Card
                            SummaryCardView(
                                title: "Expenses",
                                amount: viewModel.totalExpenses(),
                                iconName: "arrow.up",
                                color: .red
                            )
                        }
                        .padding(.horizontal)
                        
                        // Report visualization based on selected type
                        Group {
                            switch selectedReportType {
                            case .expensesByCategory:
                                ExpensesByCategoryView(viewModel: viewModel)
                            case .incomeVsExpenses:
                                IncomeVsExpensesView(viewModel: viewModel)
                            case .spendingTrends:
                                SpendingTrendsView(viewModel: viewModel)
                            }
                        }
                        .frame(minHeight: 400)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Reports")
            .onChange(of: selectedDateRange) { _ in
                // Force refresh when date range changes
                viewModel.selectedDateRange = selectedDateRange
                viewModel.applyFilters()
            }
            .onAppear {
                // Ensure we're using the selected date range and refresh data
                viewModel.selectedDateRange = selectedDateRange
                viewModel.applyFilters()
            }
        }
    }
}

// MARK: - Subviews

struct SummaryCardView: View {
    var title: String
    var amount: Double
    var iconName: String
    var color: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: iconName)
                        .foregroundColor(color)
                    Text(title)
                        .font(.subheadline)
                }
                
                Text(Formatters.formatCurrency(amount))
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 80)
    }
}

struct ExpensesByCategoryView: View {
    var viewModel: TransactionViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Expenses by Category")
                .font(.headline)
                .padding(.leading)
            
            if viewModel.totalExpenses() == 0 {
                Text("No expenses in this period")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // Pie Chart
                SimplePieChartView(data: viewModel.categorySpendingData())
                    .frame(height: 250)
                    .padding()
                
                // Legend & Details
                VStack(spacing: 12) {
                    ForEach(viewModel.categorySpendingData(), id: \.0.id) { category, amount in
                        HStack {
                            // Color indicator
                            Circle()
                                .fill(category.color)
                                .frame(width: 12, height: 12)
                            
                            // Category name
                            Text(category.name)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            // Amount
                            Text(Formatters.formatCurrency(amount))
                                .font(.subheadline)
                            
                            // Percentage
                            Text("(\(Int(amount / viewModel.totalExpenses() * 100))%)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
        .padding(.horizontal)
    }
}

struct IncomeVsExpensesView: View {
    var viewModel: TransactionViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Income vs Expenses")
                .font(.headline)
                .padding(.leading)
            
            if viewModel.filteredTransactions.isEmpty {
                Text("No transactions in this period")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // Simple Bar Chart
                SimpleBarChartView(income: viewModel.totalIncome(), expenses: viewModel.totalExpenses())
                    .frame(height: 250)
                    .padding()
                
                // Net Savings
                VStack(spacing: 4) {
                    Text("Net Savings")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    let netSavings = viewModel.totalIncome() - viewModel.totalExpenses()
                    Text(Formatters.formatCurrency(netSavings))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(netSavings >= 0 ? .green : .red)
                    
                    // Only show this if there's income
                    if viewModel.totalIncome() > 0 {
                        let savingsRate = netSavings / viewModel.totalIncome() * 100
                        Text("Savings Rate: \(Int(max(0, savingsRate)))%")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
        .padding(.horizontal)
    }
}

struct SpendingTrendsView: View {
    var viewModel: TransactionViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Trends")
                .font(.headline)
                .padding(.leading)
            
            if viewModel.filteredTransactions.isEmpty {
                Text("No transactions in this period")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // Simple Line Chart
                SimpleLineChartView(transactions: viewModel.filteredTransactions)
                    .frame(height: 250)
                    .padding()
                
                // Top Spending Categories
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top Spending Categories")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    ForEach(viewModel.categorySpendingData().prefix(3), id: \.0.id) { category, amount in
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(category.color.opacity(0.2))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: category.icon)
                                    .foregroundColor(category.color)
                            }
                            
                            Text(category.name)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text(Formatters.formatCurrency(amount))
                                .font(.subheadline)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.vertical)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
        .padding(.horizontal)
    }
}

// MARK: - Simplified Chart Views for macOS Compatibility

struct SimplePieChartView: View {
    var data: [(Category, Double)]
    
    var body: some View {
        GeometryReader { geometry in
            if data.isEmpty {
                Text("No data to display")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ZStack {
                    ForEach(0..<data.count, id: \.self) { index in
                        PieSliceView(
                            startAngle: startAngle(for: index),
                            endAngle: endAngle(for: index),
                            color: data[index].0.color
                        )
                    }
                    
                    // Center hole
                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: geometry.size.width * 0.5, height: geometry.size.width * 0.5)
                    
                    // Total amount in center
                    VStack {
                        Text("Total")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(Formatters.formatCurrency(totalAmount))
                            .font(.headline)
                    }
                }
            }
        }
    }
    
    private var totalAmount: Double {
        data.reduce(0) { $0 + $1.1 }
    }
    
    private func startAngle(for index: Int) -> Double {
        let prior = data.prefix(index).reduce(0) { $0 + $1.1 }
        return (prior / totalAmount) * 360
    }
    
    private func endAngle(for index: Int) -> Double {
        let including = data.prefix(index + 1).reduce(0) { $0 + $1.1 }
        return (including / totalAmount) * 360
    }
}

struct PieSliceView: View {
    var startAngle: Double
    var endAngle: Double
    var color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                
                path.move(to: center)
                
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(startAngle - 90),
                    endAngle: .degrees(endAngle - 90),
                    clockwise: false
                )
                
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}

struct SimpleBarChartView: View {
    var income: Double
    var expenses: Double
    
    var body: some View {
        GeometryReader { geometry in
            let maxValue = max(income, expenses) * 1.2 // Add 20% headroom
            let barWidth = geometry.size.width * 0.25
            let spacing = geometry.size.width * 0.2
            let availableHeight = geometry.size.height - 50 // Space for labels
            
            VStack {
                HStack(alignment: .bottom, spacing: spacing) {
                    // Income bar
                    VStack {
                        Rectangle()
                            .fill(Color.green.opacity(0.7))
                            .frame(
                                width: barWidth,
                                height: income > 0 ? CGFloat(income / maxValue) * availableHeight : 0
                            )
                            .cornerRadius(8)
                        
                        Text("Income")
                            .font(.caption)
                            .padding(.top, 8)
                    }
                    
                    // Expenses bar
                    VStack {
                        Rectangle()
                            .fill(Color.red.opacity(0.7))
                            .frame(
                                width: barWidth,
                                height: expenses > 0 ? CGFloat(expenses / maxValue) * availableHeight : 0
                            )
                            .cornerRadius(8)
                        
                        Text("Expenses")
                            .font(.caption)
                            .padding(.top, 8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 30)
            }
            
            // Y-axis values (simplified)
            VStack(alignment: .leading, spacing: 0) {
                Text(Formatters.formatCurrency(maxValue))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(Formatters.formatCurrency(maxValue / 2))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(Formatters.formatCurrency(0))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 50)
            .padding(.leading, 2)
        }
    }
}

struct SimpleLineChartView: View {
    var transactions: [Transaction]
    
    private var groupedData: [Date: Double] {
        let calendar = Calendar.current
        
        // Group by day and sum expenses
        let grouped = Dictionary(grouping: transactions.filter { $0.type == .expense }) { transaction in
            calendar.startOfDay(for: transaction.date)
        }
        
        return grouped.mapValues { transactions in
            transactions.reduce(0) { $0 + $1.amount }
        }
    }
    
    private var chartData: [(Date, Double)] {
        let sorted = groupedData.sorted { $0.key < $1.key }
        return sorted.map { ($0.key, $0.value) }
    }
    
    var body: some View {
        if chartData.isEmpty {
            Text("Not enough data to display chart")
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
        } else {
            GeometryReader { geometry in
                let maxAmount = chartData.map { $0.1 }.max() ?? 0
                let adjustedMax = maxAmount > 0 ? maxAmount * 1.2 : 1 // Add 20% headroom
                
                // Draw line chart
                ZStack {
                    // Horizontal grid lines (simplified)
                    VStack(spacing: 0) {
                        ForEach(0..<4) { i in
                            Divider()
                                .background(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            
                            if i < 3 {
                                Spacer()
                            }
                        }
                    }
                    
                    // Line chart
                    Path { path in
                        for i in 0..<chartData.count {
                            let xPosition = CGFloat(i) * (geometry.size.width / CGFloat(max(1, chartData.count - 1)))
                            let yPosition = geometry.size.height - CGFloat(chartData[i].1 / adjustedMax) * geometry.size.height
                            
                            if i == 0 {
                                path.move(to: CGPoint(x: xPosition, y: yPosition))
                            } else {
                                path.addLine(to: CGPoint(x: xPosition, y: yPosition))
                            }
                        }
                    }
                    .stroke(Color.blue, lineWidth: 2)
                    
                    // Data points
                    ForEach(0..<chartData.count, id: \.self) { i in
                        let xPosition = CGFloat(i) * (geometry.size.width / CGFloat(max(1, chartData.count - 1)))
                        let yPosition = geometry.size.height - CGFloat(chartData[i].1 / adjustedMax) * geometry.size.height
                        
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                            .position(x: xPosition, y: yPosition)
                    }
                    
                    // X-axis date labels (simplified)
                    VStack {
                        Spacer()
                        HStack {
                            if !chartData.isEmpty {
                                Text(Formatters.formatShortDate(chartData.first!.0))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                if chartData.count > 1 {
                                    Text(Formatters.formatShortDate(chartData.last!.0))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
