//
//  PrivateExpense.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/13/25.
//

import Foundation

/// PrivateExpense: Represents a simple IOU or debt between two users
///
/// This model tracks a one-way expense where one person (the payer) spent money
/// on behalf of another person (the recipient), creating a debt that needs to be settled.
///
/// Example Scenario:
/// - Alice pays $20 for Bob's lunch
/// - payerID = Alice's UID
/// - recipientID = Bob's UID
/// - amount = 20.0
/// - This means Bob owes Alice $20
///
/// Firestore Path: artifacts/{appId}/users/{userID}/private_expenses/{expenseID}
///
/// Note: Each user stores their own private expenses. When calculating balance,
/// we consider both expenses where the user is the payer and where they are the recipient.
struct PrivateExpense: Codable, Identifiable, Equatable {
    
    // MARK: - Properties
    
    /// Unique identifier for this expense
    /// Generated using UUID for uniqueness
    var id: String
    
    /// Firebase UID of the person who paid
    /// This person is owed money
    var payerID: String
    
    /// Firebase UID of the person who owes money
    /// This person needs to pay back the payer
    var recipientID: String
    
    /// The amount of money involved in this IOU
    /// Always stored as a positive number
    var amount: Double
    
    /// Description of what this expense was for
    /// Examples: "Lunch at restaurant", "Movie tickets", "Grocery shopping"
    var description: String
    
    /// Date when this expense was recorded
    var date: Date
    
    /// Optional note or additional context
    var note: String?
    
    // MARK: - Initialization
    
    /// Default initializer for creating a new private expense
    ///
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - payerID: UID of the person who paid
    ///   - recipientID: UID of the person who owes
    ///   - amount: Amount of the debt
    ///   - description: What the expense was for
    ///   - date: When the expense occurred (defaults to now)
    ///   - note: Optional additional information
    init(
        id: String = UUID().uuidString,
        payerID: String,
        recipientID: String,
        amount: Double,
        description: String,
        date: Date = Date(),
        note: String? = nil
    ) {
        self.id = id
        self.payerID = payerID
        self.recipientID = recipientID
        self.amount = abs(amount)  // Ensure amount is always positive
        self.description = description
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
        case description
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
    
    /// Short date format (e.g., "Oct 13")
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    // MARK: - Helper Methods
    
    /// Determines the net effect of this expense for a specific user
    ///
    /// - Parameter userID: The UID of the user to calculate for
    /// - Returns: Positive if they are owed money, negative if they owe money, 0 if not involved
    ///
    /// Example:
    /// - If userID is the payer: returns +amount (they are owed)
    /// - If userID is the recipient: returns -amount (they owe)
    /// - Otherwise: returns 0 (not involved in this expense)
    func netAmountFor(userID: String) -> Double {
        if payerID == userID {
            return amount  // This user paid, so they are owed
        } else if recipientID == userID {
            return -amount  // This user owes money
        } else {
            return 0  // This user is not involved
        }
    }
    
    /// Checks if a specific user is involved in this expense
    ///
    /// - Parameter userID: The UID to check
    /// - Returns: true if the user is either the payer or recipient
    func involves(userID: String) -> Bool {
        return payerID == userID || recipientID == userID
    }
}

// MARK: - Mock Data for Previews

#if DEBUG
extension PrivateExpense {
    /// Sample expense for SwiftUI previews
    static var sample: PrivateExpense {
        PrivateExpense(
            id: "expense-1",
            payerID: "user-1",
            recipientID: "user-2",
            amount: 25.50,
            description: "Lunch at Italian restaurant",
            date: Date(),
            note: "Split the pasta dish"
        )
    }
    
    /// Array of sample expenses for testing
    static var sampleArray: [PrivateExpense] {
        [
            PrivateExpense(
                payerID: "user-1",
                recipientID: "user-2",
                amount: 25.50,
                description: "Lunch",
                date: Date().addingTimeInterval(-86400)
            ),
            PrivateExpense(
                payerID: "user-2",
                recipientID: "user-1",
                amount: 15.00,
                description: "Coffee",
                date: Date().addingTimeInterval(-172800)
            ),
            PrivateExpense(
                payerID: "user-1",
                recipientID: "user-2",
                amount: 50.00,
                description: "Concert tickets",
                date: Date().addingTimeInterval(-259200)
            )
        ]
    }
}
#endif

