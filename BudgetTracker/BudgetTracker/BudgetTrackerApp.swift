import SwiftUI

@main
struct BudgetTrackerApp: App {
    // Create a shared data manager for the entire app
    @StateObject private var dataManager = DataManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
    }
}

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)
            
            TransactionsView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.rectangle")
                }
                .tag(1)
            
            BudgetSettingsView()
                .tabItem {
                    Label("Budgets", systemImage: "dollarsign.circle.fill")
                }
                .tag(2)
            
            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: "chart.pie.fill")
                }
                .tag(3)
        }
    }
}
