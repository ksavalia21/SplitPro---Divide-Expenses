//
//  GroupDetailsView.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/13/25.
//

import SwiftUI
import FirebaseFirestore

/// GroupDetailsView: Displays detailed information about a specific group
///
/// This view shows:
/// - Group name and members
/// - Current user's net balance in the group
/// - List of all group expenses (real-time updates)
/// - Option to add new expenses
///
/// Features real-time updates via Firestore snapshot listeners.
struct GroupDetailsView: View {
    
    // MARK: - Properties
    
    /// The group being displayed
    let group: Group
    
    // MARK: - Environment Objects
    
    /// Access to authentication manager for current user info
    @EnvironmentObject var authManager: AuthenticationManager
    
    // MARK: - State Properties
    
    /// Net balance for the current user in this group
    /// Positive = others owe you, Negative = you owe others
    @State private var userBalance: Double = 0.0
    
    /// All expenses in this group
    @State private var expenses: [GroupExpense] = []
    
    /// Member User objects (fetched from Firestore)
    @State private var members: [User] = []
    
    /// Indicates if data is being loaded
    @State private var isLoading: Bool = true
    
    /// Controls whether to show the Add Expense sheet
    @State private var showingAddExpense: Bool = false
    
    /// Error message (if any)
    @State private var errorMessage: String? = nil
    
    /// Firestore listener for expenses
    @State private var expensesListener: ListenerRegistration? = nil
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if isLoading {
                // Loading state
                ProgressView("Loading...")
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Balance card
                        balanceCard
                        
                        // Members section
                        membersSection
                        
                        // Quick action button
                        addExpenseButton
                        
                        // Expenses list
                        expensesSection
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(group: group, members: members)
        }
        .task {
            await loadData()
            setupExpensesListener()
        }
        .onDisappear {
            // Remove listener when view disappears
            expensesListener?.remove()
        }
    }
    
    // MARK: - Subviews
    
    /// Balance display card
    private var balanceCard: some View {
        VStack(spacing: 12) {
            Text("Your Balance")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Balance amount
            Text(formatCurrency(userBalance))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(balanceColor)
            
            // Balance status text
            Text(balanceStatusText)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(balanceColor.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(balanceColor.opacity(0.3), lineWidth: 2)
        )
    }
    
    /// Members section
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Members (\(members.count))")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(members) { member in
                    HStack {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 35, height: 35)
                            
                            Text(member.displayName.prefix(1).uppercased())
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        
                        // Member info
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(member.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                if member.id == authManager.currentUserUID {
                                    Text("(You)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                
                                if member.id == group.creatorID {
                                    Text("(Creator)")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                            
                            Text(member.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
    
    /// Add expense button
    private var addExpenseButton: some View {
        Button(action: {
            showingAddExpense = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Expense")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
    
    /// Expenses history section
    private var expensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expenses")
                .font(.headline)
            
            if expenses.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    Text("No expenses yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Add your first group expense above")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            } else {
                // List of expenses
                VStack(spacing: 8) {
                    ForEach(expenses) { expense in
                        GroupExpenseRowView(
                            expense: expense,
                            currentUserID: authManager.currentUserUID ?? "",
                            members: members
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Color for the balance display
    private var balanceColor: Color {
        if userBalance > 0 {
            return .green  // You are owed money
        } else if userBalance < 0 {
            return .orange  // You owe money
        } else {
            return .gray   // Settled up
        }
    }
    
    /// Text description of the balance status
    private var balanceStatusText: String {
        if userBalance > 0 {
            return "You are owed"
        } else if userBalance < 0 {
            return "You owe"
        } else {
            return "You're all settled up!"
        }
    }
    
    // MARK: - Helper Methods
    
    /// Loads initial data (members and balance)
    private func loadData() async {
        isLoading = true
        errorMessage = nil
        
        // Fetch members
        members = await FirestoreService.fetchUsers(ids: group.memberIDs)
        
        // Calculate user's balance
        if let currentUserID = authManager.currentUserUID {
            do {
                userBalance = try await FirestoreService.calculateUserBalanceInGroup(
                    userID: currentUserID,
                    groupID: group.id
                )
            } catch {
                print("❌ Failed to calculate balance: \(error)")
            }
        }
        
        isLoading = false
    }
    
    /// Sets up real-time listener for expenses
    private func setupExpensesListener() {
        expensesListener = FirestoreService.listenToGroupExpenses(groupID: group.id) { [self] updatedExpenses in
            self.expenses = updatedExpenses
            
            // Recalculate balance when expenses change
            Task {
                if let currentUserID = authManager.currentUserUID {
                    do {
                        userBalance = try await FirestoreService.calculateUserBalanceInGroup(
                            userID: currentUserID,
                            groupID: group.id
                        )
                    } catch {
                        print("❌ Failed to recalculate balance: \(error)")
                    }
                }
            }
        }
    }
    
    /// Formats a currency value
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: abs(value))) ?? "$0.00"
    }
}

// MARK: - Group Expense Row View

/// Individual row view for displaying a group expense
struct GroupExpenseRowView: View {
    let expense: GroupExpense
    let currentUserID: String
    let members: [User]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Expense description
                Text(expense.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                // Total amount
                Text(expense.formattedTotalAmount)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            // Who paid
            HStack {
                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Paid by \(payerName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Date
                Text(expense.shortDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Your share
            HStack {
                if expense.isPaidBy(userID: currentUserID) {
                    Text("You paid • Others owe you \(expense.formattedAmountOwed(by: currentUserID))")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("You owe \(expense.formattedAmountOwed(by: currentUserID))")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var payerName: String {
        if expense.isPaidBy(userID: currentUserID) {
            return "you"
        } else {
            return members.first(where: { $0.id == expense.paidByID })?.displayName ?? "Unknown"
        }
    }
}

// MARK: - Preview

#Preview {
    let authManager = AuthenticationManager()
    authManager.currentUserUID = "user-1"
    
    return NavigationStack {
        GroupDetailsView(group: Group.sample)
            .environmentObject(authManager)
    }
}

