//
//  Settlement.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/17/25.
//  Sprint 4: Debt Settlement Model
//

import Foundation

/// Settlement: Represents a payment made to settle debts between users
///
/// A settlement records when one user pays another to reduce or eliminate debt.
/// Settlements can be:
/// - **Group Settlements**: Within a specific group context (groupID is set)
/// - **Private Settlements**: Between two friends outside of groups (groupID is nil)
///
/// Example:
/// - Alice owes Bob $50 from various group expenses
/// - Alice pays Bob $50
/// - Settlement is created with payerID=Alice, recipientID=Bob, amount=50
/// - This reduces/eliminates Alice's debt to Bob
///
/// **Integration with Balance Calculation:**
/// Settlements are stored in the same collection as expenses. When calculating balances,
/// settlements are treated as "reverse expenses" that reduce the debt.
///
/// Firestore Path:
/// - Group settlements: artifacts/{appId}/public/data/groups/{groupID}/expenses/{settlementID}
/// - Private settlements: artifacts/{appId}/users/{userID}/private_expenses/{settlementID}
struct Settlement: Codable, Identifiable, Equatable {
    
    // MARK: - Properties
    
    /// Unique identifier for this settlement
    var id: String
    
    /// Firebase UID of the person who is making the payment
    /// This person is reducing their debt / paying back money they owed
    var payerID: String
    
    /// Firebase UID of the person who is receiving the payment
    /// This person was owed money and is now receiving it
    var recipientID: String
    
    /// Amount being paid/settled
    /// Always stored as a positive number
    var amount: Double
    
    /// Optional: Group ID if this settlement is in the context of a specific group
    /// If nil, this is a private settlement between two friends
    var groupID: String?
    
    /// Date when this settlement was recorded
    var date: Date
    
    /// Optional note about the settlement
    /// Example: "Paying back for groceries", "Venmo transfer completed"
    var note: String?
    
    // MARK: - Initialization
    
    /// Default initializer for creating a new Settlement
    ///
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - payerID: UID of the person making the payment
    ///   - recipientID: UID of the person receiving the payment
    ///   - amount: Amount being settled
    ///   - groupID: Optional group context
    ///   - date: When the settlement occurred (defaults to now)
    ///   - note: Optional description/note
    init(
        id: String = UUID().uuidString,
        payerID: String,
        recipientID: String,
        amount: Double,
        groupID: String? = nil,
        date: Date = Date(),
        note: String? = nil
    ) {
        self.id = id
        self.payerID = payerID
        self.recipientID = recipientID
        self.amount = abs(amount)  // Ensure positive
        self.groupID = groupID
        self.date = date
        self.note = note
    }
    
    // MARK: - Coding Keys
    
    /// Custom coding keys to match Firestore field names
    enum CodingKeys: String, CodingKey {
        case id
        case payerID = "payer_id"
        case recipientID = "recipient_id"
        case amount
        case groupID = "group_id"
        case date
        case note
    }
    
    // MARK: - Computed Properties
    
    /// Formatted amount as currency string
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Short date format (e.g., "Oct 17")
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    /// Indicates if this is a group settlement (vs private)
    var isGroupSettlement: Bool {
        return groupID != nil
    }
    
    // MARK: - Helper Methods
    
    /// Determines the net effect of this settlement for a specific user
    ///
    /// - Parameter userID: The UID of the user to calculate for
    /// - Returns: Positive if they received payment, negative if they paid, 0 if not involved
    ///
    /// Example:
    /// - If userID is the payer: returns -amount (they paid out money)
    /// - If userID is the recipient: returns +amount (they received money)
    /// - Otherwise: returns 0 (not involved in this settlement)
    func netAmountFor(userID: String) -> Double {
        if payerID == userID {
            return -amount  // This user paid money out
        } else if recipientID == userID {
            return amount   // This user received money
        } else {
            return 0  // This user is not involved
        }
    }
    
    /// Checks if a specific user is involved in this settlement
    ///
    /// - Parameter userID: The UID to check
    /// - Returns: true if the user is either the payer or recipient
    func involves(userID: String) -> Bool {
        return payerID == userID || recipientID == userID
    }
}

// MARK: - Mock Data for Previews

#if DEBUG
extension Settlement {
    /// Sample settlement for SwiftUI previews
    static var sample: Settlement {
        Settlement(
            id: "settlement-1",
            payerID: "user-1",
            recipientID: "user-2",
            amount: 50.00,
            groupID: "group-1",
            date: Date(),
            note: "Settling up for last month's groceries"
        )
    }
    
    /// Array of sample settlements for testing
    static var sampleArray: [Settlement] {
        [
            Settlement(
                payerID: "user-1",
                recipientID: "user-2",
                amount: 50.00,
                groupID: "group-1",
                date: Date().addingTimeInterval(-86400),
                note: "Paid via Venmo"
            ),
            Settlement(
                payerID: "user-2",
                recipientID: "user-1",
                amount: 25.00,
                groupID: nil,  // Private settlement
                date: Date().addingTimeInterval(-172800),
                note: "Cash payment"
            ),
            Settlement(
                payerID: "user-3",
                recipientID: "user-1",
                amount: 100.00,
                groupID: "group-1",
                date: Date().addingTimeInterval(-259200)
            )
        ]
    }
}
#endif


