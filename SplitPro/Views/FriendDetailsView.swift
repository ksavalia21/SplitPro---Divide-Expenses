//
//  FriendDetailsView.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/13/25.
//

import SwiftUI

/// FriendDetailsView: Displays detailed IOU/expense information with a specific friend
///
/// This view shows:
/// - Net balance between the current user and the friend
/// - List of all expenses/IOUs between them
/// - Options to add new expenses
/// - Expense history sorted by date
///
/// Balance calculation:
/// - Positive balance: Friend owes current user
/// - Negative balance: Current user owes friend
/// - Zero balance: All settled up
struct FriendDetailsView: View {
    
    // MARK: - Properties
    
    /// The friend whose details are being displayed
    let friend: User
    
    // MARK: - Environment Objects
    
    /// Access to authentication manager for current user info
    @EnvironmentObject var authManager: AuthenticationManager
    
    // MARK: - State Properties
    
    /// Net balance between users (positive = friend owes you, negative = you owe friend)
    @State private var balance: Double = 0.0
    
    /// All expenses between the two users
    @State private var expenses: [PrivateExpense] = []
    
    /// Indicates if data is being loaded
    @State private var isLoading: Bool = true
    
    /// Controls whether to show the Log IOU sheet
    @State private var showingLogIOU: Bool = false
    
    /// Error message (if any)
    @State private var errorMessage: String? = nil
    
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
                        // Friend info card
                        friendInfoCard
                        
                        // Balance card
                        balanceCard
                        
                        // Quick action buttons
                        quickActionButtons
                        
                        // Expense history
                        expenseHistorySection
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(friend.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingLogIOU) {
            LogIOUView()
        }
        .task {
            await loadData()
        }
        .refreshable {
            await loadData()
        }
    }
    
    // MARK: - Subviews
    
    /// Friend information card
    private var friendInfoCard: some View {
        VStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                
                Text(friend.displayName.prefix(1).uppercased())
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Name and email
            VStack(spacing: 4) {
                Text(friend.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(friend.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    /// Balance display card
    private var balanceCard: some View {
        VStack(spacing: 12) {
            Text("Current Balance")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Balance amount
            Text(formatCurrency(balance))
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
    
    /// Quick action buttons
    private var quickActionButtons: some View {
        HStack(spacing: 15) {
            // Log new IOU button
            Button(action: {
                showingLogIOU = true
            }) {
                Label("Log IOU", systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
    }
    
    /// Expense history section
    private var expenseHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transaction History")
                .font(.headline)
                .padding(.horizontal)
            
            if expenses.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    Text("No transactions yet")
                        .font(.subheadline)
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
                        ExpenseRowView(
                            expense: expense,
                            currentUserID: authManager.currentUserUID ?? ""
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Color for the balance display
    private var balanceColor: Color {
        if balance > 0 {
            return .green  // Friend owes you
        } else if balance < 0 {
            return .orange  // You owe friend
        } else {
            return .gray   // Settled up
        }
    }
    
    /// Text description of the balance status
    private var balanceStatusText: String {
        if balance > 0 {
            return "\(friend.displayName) owes you"
        } else if balance < 0 {
            return "You owe \(friend.displayName)"
        } else {
            return "You're all settled up!"
        }
    }
    
    // MARK: - Helper Methods
    
    /// Loads balance and expense data
    private func loadData() async {
        guard let currentUserID = authManager.currentUserUID else {
            errorMessage = "Not authenticated"
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch expenses between these two users
            expenses = try await FirestoreService.fetchPrivateExpensesWith(
                userID: currentUserID,
                friendID: friend.id
            )
            
            // Calculate balance
            balance = try await FirestoreService.calculateBalance(
                between: currentUserID,
                and: friend.id
            )
            
            print("✅ Loaded \(expenses.count) expenses, balance: \(balance)")
            
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
            print("❌ Error loading data: \(error)")
        }
        
        isLoading = false
    }
    
    /// Formats a currency value
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: abs(value))) ?? "$0.00"
    }
}

// MARK: - Expense Row View

/// Individual row view for displaying an expense
struct ExpenseRowView: View {
    let expense: PrivateExpense
    let currentUserID: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon based on direction
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
            }
            
            // Expense details
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(expense.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let note = expense.note {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text(expense.formattedAmount)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(amountColor)
                
                Text(directionText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    
    private var isPayer: Bool {
        expense.payerID == currentUserID
    }
    
    private var iconName: String {
        isPayer ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
    }
    
    private var iconColor: Color {
        isPayer ? .green : .orange
    }
    
    private var amountColor: Color {
        isPayer ? .green : .orange
    }
    
    private var directionText: String {
        isPayer ? "they owe you" : "you owe them"
    }
}

// MARK: - Preview

#Preview {
    let authManager = AuthenticationManager()
    authManager.currentUserUID = "user-1"
    
    return NavigationStack {
        FriendDetailsView(friend: User.sampleArray[0])
            .environmentObject(authManager)
    }
}

