//
//  GroupExpense.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/13/25.
//

import Foundation

/// SplitType: Enum representing the different ways an expense can be split
///
/// This enum defines the supported split methods for group expenses:
/// - `.equal`: Total amount divided equally among all members
/// - `.exactAmounts`: Each member owes a specific dollar amount (user-defined)
/// - `.percentages`: Each member owes a percentage of the total (must sum to 100%)
///
/// Example Usage:
/// - Equal: $60 ÷ 3 people = $20 each
/// - Exact: Alice owes $30, Bob owes $20, Charlie owes $10
/// - Percentage: Alice 50%, Bob 30%, Charlie 20%
enum SplitType: String, Codable {
    case equal = "equal"
    case exactAmounts = "exact_amounts"
    case percentages = "percentages"
    
    /// Human-readable display name for the split type
    var displayName: String {
        switch self {
        case .equal:
            return "Split Equally"
        case .exactAmounts:
            return "Exact Amounts"
        case .percentages:
            return "By Percentages"
        }
    }
    
    /// Icon name for the split type
    var iconName: String {
        switch self {
        case .equal:
            return "equal.circle.fill"
        case .exactAmounts:
            return "dollarsign.circle.fill"
        case .percentages:
            return "percent"
        }
    }
}

/// GroupExpense: Represents an expense shared among group members
///
/// This model tracks expenses that are split among multiple people in a group.
/// The expense records:
/// - Who paid the total bill (paidByID)
/// - How much each member owes (memberOwed dictionary)
/// - The split method used (equal, exact amounts, or percentages)
/// - Optional receipt image URL
///
/// Example (Equal Split):
/// - Alice paid $60 for dinner
/// - Group has 3 members: Alice, Bob, Charlie
/// - Split equally: each owes $20
/// - memberOwed = ["alice_id": 0, "bob_id": 20, "charlie_id": 20]
/// - (Alice owes $0 because she paid)
///
/// Example (Exact Amounts):
/// - Bob paid $60 for dinner
/// - Alice owes $30, Bob owes $0, Charlie owes $30
/// - memberOwed = ["alice_id": 30, "bob_id": 0, "charlie_id": 30]
///
/// Example (Percentages):
/// - Charlie paid $100 for utilities
/// - Alice 50%, Bob 30%, Charlie 20%
/// - memberOwed = ["alice_id": 50, "bob_id": 30, "charlie_id": 0]
///
/// Firestore Path: artifacts/{appId}/public/data/groups/{groupID}/expenses/{expenseID}
struct GroupExpense: Codable, Identifiable, Equatable {
    
    // MARK: - Properties
    
    /// Unique identifier for this expense
    var id: String
    
    /// ID of the group this expense belongs to
    var groupID: String
    
    /// Description of what this expense was for
    /// Examples: "Grocery shopping", "Dinner at Italian restaurant", "Utilities bill"
    var description: String
    
    /// Total amount paid (before splitting)
    /// This is the full bill amount that was paid by one person
    var totalAmount: Double
    
    /// Firebase UID of the person who paid the total amount
    /// This person is owed money by the other members
    var paidByID: String
    
    /// Method used to split the expense
    /// Options: .equal, .exactAmounts, .percentages
    /// - .equal: Total divided equally among all members
    /// - .exactAmounts: Each member has a specific dollar amount they owe
    /// - .percentages: Each member owes a percentage of the total
    var splitType: SplitType
    
    /// Dictionary mapping member UID to the amount they owe
    /// Key: Firebase UID of the member
    /// Value: Amount this member owes for this expense
    ///
    /// Important: The person who paid (paidByID) has an owed amount of 0
    /// because they already paid their share.
    ///
    /// Example for $60 split among 3 people:
    /// ["alice_id": 0.0, "bob_id": 20.0, "charlie_id": 20.0]
    var memberOwed: [String: Double]
    
    /// Date when this expense was recorded
    var date: Date
    
    /// Optional URL to the receipt image stored in Firebase Storage
    /// This is a mock implementation for Sprint 3
    /// In a production app, this would link to an actual uploaded receipt image
    var receiptURL: String?
    
    // MARK: - Initialization
    
    /// Default initializer for creating a new GroupExpense
    ///
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - groupID: ID of the group this expense belongs to
    ///   - description: What the expense was for
    ///   - totalAmount: Total bill amount
    ///   - paidByID: UID of the person who paid
    ///   - splitType: How to split the expense (defaults to .equal)
    ///   - memberOwed: Dictionary of member UIDs to amounts owed
    ///   - date: When the expense occurred (defaults to now)
    ///   - receiptURL: Optional URL to receipt image (defaults to nil)
    init(
        id: String = UUID().uuidString,
        groupID: String,
        description: String,
        totalAmount: Double,
        paidByID: String,
        splitType: SplitType = .equal,
        memberOwed: [String: Double],
        date: Date = Date(),
        receiptURL: String? = nil
    ) {
        self.id = id
        self.groupID = groupID
        self.description = description
        self.totalAmount = abs(totalAmount)  // Ensure positive
        self.paidByID = paidByID
        self.splitType = splitType
        self.memberOwed = memberOwed
        self.date = date
        self.receiptURL = receiptURL
    }
    
    // MARK: - Coding Keys
    
    /// Custom coding keys to match Firestore field names
    enum CodingKeys: String, CodingKey {
        case id
        case groupID = "group_id"
        case description
        case totalAmount = "total_amount"
        case paidByID = "paid_by_id"
        case splitType = "split_type"
        case memberOwed = "member_owed"
        case date
        case receiptURL = "receipt_url"
    }
    
    // MARK: - Computed Properties
    
    /// Formatted total amount as currency string
    var formattedTotalAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalAmount)) ?? "$\(totalAmount)"
    }
    
    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Short date format (e.g., "Oct 13")
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    /// Amount each member should pay in an equal split
    var perPersonAmount: Double {
        guard !memberOwed.isEmpty else { return 0 }
        return totalAmount / Double(memberOwed.count)
    }
    
    /// Indicates whether this expense has a receipt attached
    var hasReceipt: Bool {
        return receiptURL != nil && !(receiptURL?.isEmpty ?? true)
    }
    
    /// Human-readable split type display name
    var splitTypeDisplayName: String {
        return splitType.displayName
    }
    
    // MARK: - Helper Methods
    
    /// Gets the amount a specific member owes for this expense
    ///
    /// - Parameter userID: The UID of the member
    /// - Returns: Amount owed, or 0 if not found
    func amountOwed(by userID: String) -> Double {
        return memberOwed[userID] ?? 0
    }
    
    /// Formatted amount owed by a specific member
    ///
    /// - Parameter userID: The UID of the member
    /// - Returns: Formatted currency string
    func formattedAmountOwed(by userID: String) -> String {
        let amount = amountOwed(by: userID)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    /// Checks if a specific user paid for this expense
    ///
    /// - Parameter userID: The UID to check
    /// - Returns: true if this user paid, false otherwise
    func isPaidBy(userID: String) -> Bool {
        return paidByID == userID
    }
    
    /// Calculates the net balance effect of this expense for a user
    ///
    /// - Parameter userID: The UID of the user
    /// - Returns: Positive if they paid and are owed, negative if they owe
    ///
    /// Example:
    /// - Alice paid $60, each person owes $20
    /// - For Alice: returns +$40 (she paid $60, owes $20, net +$40)
    /// - For Bob: returns -$20 (he owes $20)
    func netBalanceFor(userID: String) -> Double {
        if isPaidBy(userID: userID) {
            // User paid the full amount, subtract what they owe
            return totalAmount - amountOwed(by: userID)
        } else {
            // User didn't pay, so they owe money (negative balance)
            return -amountOwed(by: userID)
        }
    }
}

// MARK: - Mock Data for Previews

#if DEBUG
extension GroupExpense {
    /// Sample expense for SwiftUI previews (Equal Split)
    static var sample: GroupExpense {
        GroupExpense(
            id: "expense-1",
            groupID: "group-1",
            description: "Dinner at Italian restaurant",
            totalAmount: 60.0,
            paidByID: "user-1",
            splitType: .equal,
            memberOwed: [
                "user-1": 0.0,    // Alice paid, so owes 0
                "user-2": 20.0,   // Bob owes $20
                "user-3": 20.0    // Charlie owes $20
            ],
            date: Date(),
            receiptURL: "https://example.com/receipts/mock-receipt-1.jpg"
        )
    }
    
    /// Array of sample expenses for testing (various split types)
    static var sampleArray: [GroupExpense] {
        [
            GroupExpense(
                groupID: "group-1",
                description: "Grocery shopping",
                totalAmount: 45.50,
                paidByID: "user-1",
                splitType: .equal,
                memberOwed: ["user-1": 0, "user-2": 22.75, "user-3": 22.75],
                receiptURL: "https://example.com/receipts/mock-receipt-2.jpg"
            ),
            GroupExpense(
                groupID: "group-1",
                description: "Utilities bill",
                totalAmount: 120.0,
                paidByID: "user-2",
                splitType: .percentages,
                memberOwed: ["user-1": 48.0, "user-2": 0, "user-3": 36.0],
                receiptURL: nil
            ),
            GroupExpense(
                groupID: "group-1",
                description: "Movie tickets",
                totalAmount: 36.0,
                paidByID: "user-3",
                splitType: .exactAmounts,
                memberOwed: ["user-1": 15.0, "user-2": 15.0, "user-3": 0],
                receiptURL: nil
            )
        ]
    }
}
#endif

