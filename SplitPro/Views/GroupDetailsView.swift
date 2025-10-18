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
<<<<<<< HEAD
/// - Real-time activity feed / ledger of all group expenses
/// - Split type indicators for each expense
/// - Receipt attachment indicators
/// - Option to add new expenses
///
/// **Real-Time Updates:**
/// - Uses Firestore onSnapshot listener for instant synchronization
/// - Expenses automatically sorted by date (newest first)
/// - Balance recalculates automatically when new expenses are added
///
/// **Sprint 3 Enhancements:**
/// - Displays split type (equal, exact amounts, or percentages) for each expense
/// - Shows receipt indicators when receipts are attached
/// - Enhanced expense row with better visual hierarchy
=======
/// - List of all group expenses (real-time updates)
/// - Option to add new expenses
///
/// Features real-time updates via Firestore snapshot listeners.
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
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
    
<<<<<<< HEAD
    /// Controls whether to show the Settle Up sheet
    @State private var showingSettlement: Bool = false
    
    /// Simplified payment suggestions
    @State private var simplifiedPayments: [TransactionSuggestion] = []
    
=======
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
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
                        
<<<<<<< HEAD
                        // Simplified payments section (Sprint 4)
                        simplifiedPaymentsSection
                        
                        // Quick action buttons
                        actionButtonsSection
=======
                        // Quick action button
                        addExpenseButton
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
                        
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
<<<<<<< HEAD
        .sheet(isPresented: $showingSettlement) {
            RecordSettlementView(group: group, members: members)
        }
=======
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
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
    
<<<<<<< HEAD
    /// Simplified payments section showing debt simplification results
    @ViewBuilder
    private var simplifiedPaymentsSection: some View {
        if !simplifiedPayments.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Simplified Payments")
                    .font(.headline)
                
                Text("To settle all debts, make these \(simplifiedPayments.count) payment(s):")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    ForEach(simplifiedPayments) { suggestion in
                        SimplifiedPaymentRowView(
                            suggestion: suggestion,
                            members: members,
                            currentUserID: authManager.currentUserUID ?? ""
                        )
                    }
                }
            }
        }
    }
    
    /// Action buttons section (Add Expense and Settle Up)
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            // Add Expense button
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
            
            // Settle Up button
            Button(action: {
                showingSettlement = true
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Settle Up")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
=======
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
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
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
            
<<<<<<< HEAD
            // Recalculate balance and simplified payments when expenses change
=======
            // Recalculate balance when expenses change
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
            Task {
                if let currentUserID = authManager.currentUserUID {
                    do {
                        userBalance = try await FirestoreService.calculateUserBalanceInGroup(
                            userID: currentUserID,
                            groupID: group.id
                        )
<<<<<<< HEAD
                        
                        // Calculate simplified payments
                        await recalculateSimplifiedPayments()
=======
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
                    } catch {
                        print("❌ Failed to recalculate balance: \(error)")
                    }
                }
            }
        }
    }
    
<<<<<<< HEAD
    /// Recalculates the simplified payment suggestions
    private func recalculateSimplifiedPayments() async {
        // Get member IDs for this group
        let memberIDs = group.memberIDs
        
        // Use the global balance from AuthenticationManager
        let globalBalance = authManager.globalNetBalance
        
        // Calculate simplified payments
        simplifiedPayments = BalanceCalculator.simplifyDebts(
            groupMembers: memberIDs,
            rawBalances: globalBalance,
            groupID: group.id
        )
    }
    
=======
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
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
<<<<<<< HEAD
///
/// This view shows:
/// - Expense description with receipt indicator (if available)
/// - Total amount and split type
/// - Who paid and when
/// - Current user's share
=======
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
struct GroupExpenseRowView: View {
    let expense: GroupExpense
    let currentUserID: String
    let members: [User]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
<<<<<<< HEAD
                // Expense description with receipt indicator
                HStack(spacing: 6) {
                    Text(expense.description)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    // Receipt indicator icon
                    if expense.hasReceipt {
                        Image(systemName: "paperclip.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
=======
                // Expense description
                Text(expense.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
                
                Spacer()
                
                // Total amount
                Text(expense.formattedTotalAmount)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
<<<<<<< HEAD
            // Split type and paid by info
            HStack {
                // Split type indicator
                Image(systemName: expense.splitType.iconName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(expense.splitTypeDisplayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Who paid
=======
            // Who paid
            HStack {
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
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
<<<<<<< HEAD
                
                Spacer()
                
                // Receipt attached label
                if expense.hasReceipt {
                    HStack(spacing: 2) {
                        Image(systemName: "photo")
                            .font(.caption2)
                        Text("Receipt")
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                }
=======
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
<<<<<<< HEAD
    /// Returns the display name of who paid
=======
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
    private var payerName: String {
        if expense.isPaidBy(userID: currentUserID) {
            return "you"
        } else {
            return members.first(where: { $0.id == expense.paidByID })?.displayName ?? "Unknown"
        }
    }
}

<<<<<<< HEAD
// MARK: - Simplified Payment Row View

/// Individual row view for displaying a simplified payment suggestion
struct SimplifiedPaymentRowView: View {
    let suggestion: TransactionSuggestion
    let members: [User]
    let currentUserID: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Payment direction icon
            Image(systemName: "arrow.right.circle.fill")
                .font(.title2)
                .foregroundColor(suggestion.payerID == currentUserID ? .orange : .green)
            
            // Payment details
            VStack(alignment: .leading, spacing: 4) {
                // Who owes whom
                HStack(spacing: 4) {
                    Text(payerName)
                        .fontWeight(.semibold)
                    
                    Image(systemName: "arrow.forward")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(recipientName)
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                
                // Amount
                Text(suggestion.formattedAmount)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Highlight if involves current user
            if suggestion.payerID == currentUserID {
                Text("You pay")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
            } else if suggestion.recipientID == currentUserID {
                Text("You receive")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var payerName: String {
        if suggestion.payerID == currentUserID {
            return "You"
        } else {
            return members.first(where: { $0.id == suggestion.payerID })?.displayName ?? "Unknown"
        }
    }
    
    private var recipientName: String {
        if suggestion.recipientID == currentUserID {
            return "you"
        } else {
            return members.first(where: { $0.id == suggestion.recipientID })?.displayName ?? "Unknown"
        }
    }
}

=======
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
// MARK: - Preview

#Preview {
    let authManager = AuthenticationManager()
    authManager.currentUserUID = "user-1"
    
    return NavigationStack {
        GroupDetailsView(group: Group.sample)
            .environmentObject(authManager)
    }
}

