//
//  BalanceCalculator.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/17/25.
//  Sprint 4: Balance Calculation and Debt Simplification
//

import Foundation

/// TransactionSuggestion: Represents a suggested payment to simplify debts
///
/// Used by the debt simplification algorithm to suggest the minimum number
/// of transactions needed to settle all debts within a group.
///
/// Example:
/// - Alice owes $30 to Bob
/// - TransactionSuggestion(payerID: "alice", recipientID: "bob", amount: 30)
struct TransactionSuggestion: Identifiable, Equatable {
    let id = UUID()
    let payerID: String
    let recipientID: String
    let amount: Double
    
    /// Formatted amount as currency string
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

/// BalanceCalculator: Handles complex balance calculations and debt simplification
///
/// This class provides two main functionalities:
/// 1. **Global Balance Calculation**: Aggregates all expenses and settlements across
///    all groups and private IOUs to calculate net balances with every friend/member
/// 2. **Debt Simplification**: Calculates the minimum number of transactions needed
///    to settle all debts within a group
///
/// **Algorithm Notes:**
/// - Settlements are treated as "reverse expenses" that reduce debt
/// - Group expenses and private expenses are calculated separately then merged
/// - Debt simplification uses a greedy algorithm with creditors and debtors lists
class BalanceCalculator {
    
    // MARK: - Global Balance Calculation
    
    /// Calculates the net balance with every friend/member across all groups and private IOUs
    ///
    /// This function aggregates:
    /// - All group expenses from all active groups
    /// - All private expenses (IOUs)
    /// - All settlements (both group and private)
    ///
    /// **Algorithm:**
    /// 1. Initialize empty balance dictionary
    /// 2. For each group expense:
    ///    - If current user is payer: they are owed (positive balance)
    ///    - If current user is in memberOwed: they owe (negative balance)
    /// 3. For each private expense:
    ///    - If current user is payer: they are owed
    ///    - If current user is recipient: they owe
    /// 4. Aggregate balances by counterparty ID
    ///
    /// - Parameters:
    ///   - currentUserID: The UID of the current user
    ///   - groups: All active groups the user is a member of
    ///   - groupExpenses: Dictionary mapping groupID to array of expenses
    ///   - privateExpenses: All private expenses (IOUs) for the current user
    ///
    /// - Returns: Dictionary [String: Double] where:
    ///   - Key: Friend/member UID
    ///   - Value: Net balance (positive = they owe user, negative = user owes them)
    ///
    /// Example:
    /// ```
    /// [
    ///   "bob-id": 50.0,    // Bob owes user $50
    ///   "alice-id": -30.0, // User owes Alice $30
    ///   "charlie-id": 0.0  // All settled up
    /// ]
    /// ```
    static func calculateAllBalances(
        currentUserID: String,
        groups: [Group],
        groupExpenses: [String: [GroupExpense]],
        privateExpenses: [PrivateExpense]
    ) -> [String: Double] {
        
        print("💰 Calculating global balances for user: \(currentUserID)")
        
        var balances: [String: Double] = [:]
        
        // MARK: - Process Group Expenses
        
        for group in groups {
            guard let expenses = groupExpenses[group.id] else { continue }
            
            print("  Processing \(expenses.count) expenses from group: \(group.name)")
            
            for expense in expenses {
                // If current user paid this expense
                if expense.paidByID == currentUserID {
                    // User is owed money by everyone in memberOwed (except themselves)
                    for (memberID, amountOwed) in expense.memberOwed {
                        if memberID != currentUserID && amountOwed > 0 {
                            balances[memberID, default: 0.0] += amountOwed
                        }
                    }
                }
                // If current user owes money for this expense
                else if let amountOwed = expense.memberOwed[currentUserID], amountOwed > 0 {
                    // User owes money to the payer
                    balances[expense.paidByID, default: 0.0] -= amountOwed
                }
            }
        }
        
        // MARK: - Process Private Expenses
        
        print("  Processing \(privateExpenses.count) private expenses")
        
        for expense in privateExpenses {
            let netAmount = expense.netAmountFor(userID: currentUserID)
            
            if expense.payerID == currentUserID && netAmount > 0 {
                // Current user paid, recipient owes them
                balances[expense.recipientID, default: 0.0] += netAmount
            } else if expense.recipientID == currentUserID && netAmount < 0 {
                // Current user is recipient, they owe the payer
                balances[expense.payerID, default: 0.0] += netAmount
            }
        }
        
        // MARK: - Clean up near-zero balances
        
        // Remove balances that are essentially zero (due to floating point precision)
        for (key, value) in balances {
            if abs(value) < 0.01 {
                balances[key] = 0.0
            }
        }
        
        print("✅ Calculated balances with \(balances.count) people")
        
        return balances
    }
    
    // MARK: - Debt Simplification Algorithm
    
    /// Simplifies debts within a group to minimize the number of transactions
    ///
    /// This function implements a greedy debt simplification algorithm that reduces
    /// the number of transactions needed to settle all debts within a group.
    ///
    /// **Algorithm Overview:**
    /// 1. Calculate net balance for each member
    /// 2. Separate into creditors (owed money) and debtors (owe money)
    /// 3. Repeatedly match largest creditor with largest debtor
    /// 4. Create transactions until all debts are settled
    ///
    /// **Example:**
    /// Before:
    /// - Alice paid $60, Bob owes $20, Charlie owes $20, Dan owes $20
    /// - Naive: 3 transactions (Bob→Alice, Charlie→Alice, Dan→Alice)
    ///
    /// After simplification:
    /// - Alice is owed $60 total
    /// - Bob, Charlie, Dan each owe $20
    /// - Result: 3 transactions (can't simplify further in this case)
    ///
    /// Better example:
    /// - Alice paid $30 for Bob
    /// - Bob paid $30 for Alice
    /// - Simplified: 0 transactions (they cancel out)
    ///
    /// - Parameters:
    ///   - groupMembers: Array of all member UIDs in the group
    ///   - rawBalances: Dictionary of net balances from calculateAllBalances
    ///   - groupID: The group ID to filter relevant balances
    ///
    /// - Returns: Array of TransactionSuggestion objects representing simplified payments
    static func simplifyDebts(
        groupMembers: [String],
        rawBalances: [String: Double],
        groupID: String
    ) -> [TransactionSuggestion] {
        
        print("🔄 Simplifying debts for group with \(groupMembers.count) members")
        
        // MARK: - Step 1: Extract relevant balances for this group
        
        var netBalances: [String: Double] = [:]
        
        for memberID in groupMembers {
            netBalances[memberID] = rawBalances[memberID] ?? 0.0
        }
        
        // MARK: - Step 2: Separate into creditors and debtors
        
        var creditors: [(id: String, amount: Double)] = []
        var debtors: [(id: String, amount: Double)] = []
        
        for (memberID, balance) in netBalances {
            if balance > 0.01 {
                // This person is owed money (creditor)
                creditors.append((id: memberID, amount: balance))
            } else if balance < -0.01 {
                // This person owes money (debtor)
                debtors.append((id: memberID, amount: -balance))
            }
        }
        
        // Sort creditors by amount descending (largest creditor first)
        creditors.sort { $0.amount > $1.amount }
        
        // Sort debtors by amount descending (largest debtor first)
        debtors.sort { $0.amount > $1.amount }
        
        print("  Creditors: \(creditors.count), Debtors: \(debtors.count)")
        
        // MARK: - Step 3: Generate simplified transactions
        
        var transactions: [TransactionSuggestion] = []
        var creditorIndex = 0
        var debtorIndex = 0
        
        while creditorIndex < creditors.count && debtorIndex < debtors.count {
            let creditor = creditors[creditorIndex]
            let debtor = debtors[debtorIndex]
            
            // Amount to transfer is minimum of what creditor is owed and debtor owes
            let transferAmount = min(creditor.amount, debtor.amount)
            
            // Create transaction: debtor pays creditor
            let transaction = TransactionSuggestion(
                payerID: debtor.id,
                recipientID: creditor.id,
                amount: transferAmount
            )
            transactions.append(transaction)
            
            print("  Transaction: \(debtor.id) → \(creditor.id): $\(transferAmount)")
            
            // Update remaining amounts
            creditors[creditorIndex].amount -= transferAmount
            debtors[debtorIndex].amount -= transferAmount
            
            // Move to next creditor/debtor if current one is settled
            if creditors[creditorIndex].amount < 0.01 {
                creditorIndex += 1
            }
            if debtors[debtorIndex].amount < 0.01 {
                debtorIndex += 1
            }
        }
        
        print("✅ Simplified to \(transactions.count) transactions")
        
        return transactions
    }
    
    // MARK: - Helper Methods
    
    /// Calculates total amount owed TO the user (sum of positive balances)
    ///
    /// - Parameter balances: Global balance dictionary from calculateAllBalances
    /// - Returns: Total amount owed to the user
    static func totalOwedToUser(balances: [String: Double]) -> Double {
        return balances.values.filter { $0 > 0 }.reduce(0, +)
    }
    
    /// Calculates total amount the user OWES (sum of negative balances)
    ///
    /// - Parameter balances: Global balance dictionary from calculateAllBalances
    /// - Returns: Total amount user owes (as positive number)
    static func totalUserOwes(balances: [String: Double]) -> Double {
        return abs(balances.values.filter { $0 < 0 }.reduce(0, +))
    }
    
    /// Calculates net balance for a specific user (you are owed - you owe)
    ///
    /// - Parameter balances: Global balance dictionary from calculateAllBalances
    /// - Returns: Net balance (positive = overall owed, negative = overall owing)
    static func overallNetBalance(balances: [String: Double]) -> Double {
        return balances.values.reduce(0, +)
    }
}


