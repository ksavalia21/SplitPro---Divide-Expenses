//
//  GroupExpense.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/13/25.
//

import Foundation

/// GroupExpense: Represents an expense shared among group members
///
/// This model tracks expenses that are split among multiple people in a group.
/// The expense records:
/// - Who paid the total bill (paidByID)
/// - How much each member owes (memberOwed dictionary)
/// - The split method used (currently only "equal" is supported)
///
/// Example:
/// - Alice paid $60 for dinner
/// - Group has 3 members: Alice, Bob, Charlie
/// - Split equally: each owes $20
/// - memberOwed = ["alice_id": 0, "bob_id": 20, "charlie_id": 20]
/// - (Alice owes $0 because she paid)
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
    /// Current options: "equal" (more options in future sprints)
    /// - "equal": Total divided equally among all members
    /// - Future: "percentage", "shares", "exact amounts", etc.
    var splitType: String
    
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
    
    // MARK: - Initialization
    
    /// Default initializer for creating a new GroupExpense
    ///
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - groupID: ID of the group this expense belongs to
    ///   - description: What the expense was for
    ///   - totalAmount: Total bill amount
    ///   - paidByID: UID of the person who paid
    ///   - splitType: How to split the expense (defaults to "equal")
    ///   - memberOwed: Dictionary of member UIDs to amounts owed
    ///   - date: When the expense occurred (defaults to now)
    init(
        id: String = UUID().uuidString,
        groupID: String,
        description: String,
        totalAmount: Double,
        paidByID: String,
        splitType: String = "equal",
        memberOwed: [String: Double],
        date: Date = Date()
    ) {
        self.id = id
        self.groupID = groupID
        self.description = description
        self.totalAmount = abs(totalAmount)  // Ensure positive
        self.paidByID = paidByID
        self.splitType = splitType
        self.memberOwed = memberOwed
        self.date = date
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
    /// Sample expense for SwiftUI previews
    static var sample: GroupExpense {
        GroupExpense(
            id: "expense-1",
            groupID: "group-1",
            description: "Dinner at Italian restaurant",
            totalAmount: 60.0,
            paidByID: "user-1",
            splitType: "equal",
            memberOwed: [
                "user-1": 0.0,    // Alice paid, so owes 0
                "user-2": 20.0,   // Bob owes $20
                "user-3": 20.0    // Charlie owes $20
            ],
            date: Date()
        )
    }
    
    /// Array of sample expenses for testing
    static var sampleArray: [GroupExpense] {
        [
            GroupExpense(
                groupID: "group-1",
                description: "Grocery shopping",
                totalAmount: 45.50,
                paidByID: "user-1",
                memberOwed: ["user-1": 0, "user-2": 22.75, "user-3": 22.75]
            ),
            GroupExpense(
                groupID: "group-1",
                description: "Utilities bill",
                totalAmount: 120.0,
                paidByID: "user-2",
                memberOwed: ["user-1": 40.0, "user-2": 0, "user-3": 40.0]
            ),
            GroupExpense(
                groupID: "group-1",
                description: "Movie tickets",
                totalAmount: 36.0,
                paidByID: "user-3",
                memberOwed: ["user-1": 12.0, "user-2": 12.0, "user-3": 0]
            )
        ]
    }
}
#endif

