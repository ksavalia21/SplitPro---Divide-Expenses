//
//  FirestoreService.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/13/25.
//

import Foundation
import FirebaseFirestore

/// FirestoreService: A centralized service for all Firestore database operations
///
/// This class encapsulates all interactions with Firebase Firestore, providing
/// a clean API for reading and writing user data, friend relationships, and expenses.
///
/// Design Pattern: Singleton-like static methods for easy access throughout the app
///
/// Key Responsibilities:
/// - User profile CRUD (Create, Read, Update, Delete)
/// - Friend relationship management (two-way updates)
/// - Private expense tracking
/// - Query operations for finding users
///
/// Firestore Structure:
/// artifacts/
///   └── {appId}/
///       └── users/
///           └── {userId}/
///               ├── user_data/
///               │   └── profile (User document)
///               └── private_expenses/
///                   └── {expenseId} (PrivateExpense documents)
class FirestoreService {
    
    // MARK: - Constants
    
    /// The app identifier used in Firestore paths
    /// This allows multiple apps or environments to share the same Firestore instance
    private static let appId = "splitpro_main"
    
    /// Reference to the Firestore database instance
    private static let db = Firestore.firestore()
    
    // MARK: - Path Helpers
    
    /// Returns the base collection path for all users
    /// Path: artifacts/{appId}/users
    private static var usersCollectionPath: String {
        return "artifacts/\(appId)/users"
    }
    
    /// Returns the path to a specific user's profile document
    /// Path: artifacts/{appId}/users/{userId}/user_data/profile
    ///
    /// - Parameter userId: The Firebase UID of the user
    /// - Returns: Complete Firestore path string
    private static func userProfilePath(userId: String) -> String {
        return "\(usersCollectionPath)/\(userId)/user_data/profile"
    }
    
    /// Returns the path to a user's private expenses collection
    /// Path: artifacts/{appId}/users/{userId}/private_expenses
    ///
    /// - Parameter userId: The Firebase UID of the user
    /// - Returns: Complete Firestore path string
    private static func privateExpensesPath(userId: String) -> String {
        return "\(usersCollectionPath)/\(userId)/private_expenses"
    }
    
    /// Returns the base collection path for all groups
    /// Path: artifacts/{appId}/public/data/groups
    private static var groupsCollectionPath: String {
        return "artifacts/\(appId)/public/data/groups"
    }
    
    /// Returns the path to a specific group's expenses collection
    /// Path: artifacts/{appId}/public/data/groups/{groupID}/expenses
    ///
    /// - Parameter groupID: The ID of the group
    /// - Returns: Complete Firestore path string
    private static func groupExpensesPath(groupID: String) -> String {
        return "\(groupsCollectionPath)/\(groupID)/expenses"
    }
    
    // MARK: - User Profile Operations
    
    /// Creates a new user profile in Firestore
    ///
    /// This should be called immediately after a successful Firebase Auth sign-up
    /// to create the user's profile document in Firestore.
    ///
    /// - Parameters:
    ///   - id: The Firebase Auth UID
    ///   - email: The user's email address
    ///   - name: Optional display name (defaults to email prefix)
    /// - Throws: Error if the Firestore write fails
    static func createUserProfile(id: String, email: String, name: String? = nil) async throws {
        print("📝 Creating user profile for: \(email)")
        
        // Create a new User object with default values
        // Store email in lowercase for consistent searching
        let newUser = User(
            id: id,
            email: email.lowercased(),
            name: name,
            friendIDs: [],
            publicKey: nil
        )
        
        // Get reference to the profile document
        let profileRef = db.document(userProfilePath(userId: id))
        
        // Encode the User object to Firestore format
        try profileRef.setData(from: newUser)
        
        print("✅ User profile created successfully")
    }
    
    /// Fetches a single user profile from Firestore
    ///
    /// - Parameter id: The Firebase UID of the user to fetch
    /// - Returns: User object if found
    /// - Throws: Error if the user doesn't exist or decoding fails
    static func fetchUser(id: String) async throws -> User {
        print("🔍 Fetching user profile: \(id)")
        
        // Get reference to the profile document
        let profileRef = db.document(userProfilePath(userId: id))
        
        // Fetch the document
        let document = try await profileRef.getDocument()
        
        // Check if document exists
        guard document.exists else {
            print("❌ User profile not found: \(id)")
            throw FirestoreError.userNotFound
        }
        
        // Decode the document to User object
        let user = try document.data(as: User.self)
        print("✅ User profile fetched: \(user.email)")
        
        return user
    }
    
    /// Fetches multiple users by their IDs
    ///
    /// - Parameter ids: Array of Firebase UIDs to fetch
    /// - Returns: Array of User objects (only includes successfully fetched users)
    static func fetchUsers(ids: [String]) async -> [User] {
        print("🔍 Fetching \(ids.count) users")
        
        // Use TaskGroup to fetch users concurrently for better performance
        var users: [User] = []
        
        await withTaskGroup(of: User?.self) { group in
            // Add a task for each user ID
            for id in ids {
                group.addTask {
                    do {
                        return try await fetchUser(id: id)
                    } catch {
                        print("⚠️ Failed to fetch user \(id): \(error.localizedDescription)")
                        return nil
                    }
                }
            }
            
            // Collect results
            for await user in group {
                if let user = user {
                    users.append(user)
                }
            }
        }
        
        print("✅ Fetched \(users.count)/\(ids.count) users")
        return users
    }
    
    /// Updates a user's profile information
    ///
    /// - Parameters:
    ///   - userId: The Firebase UID of the user
    ///   - updates: Dictionary of fields to update
    /// - Throws: Error if the update fails
    static func updateUserProfile(userId: String, updates: [String: Any]) async throws {
        print("📝 Updating user profile: \(userId)")
        
        let profileRef = db.document(userProfilePath(userId: userId))
        try await profileRef.updateData(updates)
        
        print("✅ User profile updated")
    }
    
    // MARK: - Friend Management
    
    /// Adds a two-way friend relationship between two users
    ///
    /// This function performs two operations atomically:
    /// 1. Adds friendID to currentUserID's friendIDs array
    /// 2. Adds currentUserID to friendID's friendIDs array
    ///
    /// - Parameters:
    ///   - currentUserID: The UID of the current user
    ///   - friendID: The UID of the friend to add
    /// - Throws: Error if either update fails
    static func addFriend(currentUserID: String, friendID: String) async throws {
        print("👥 Adding friend relationship: \(currentUserID) <-> \(friendID)")
        
        // Prevent adding yourself as a friend
        guard currentUserID != friendID else {
            print("❌ Cannot add yourself as a friend")
            throw FirestoreError.cannotAddSelfAsFriend
        }
        
        // Get references to both user profiles
        let currentUserRef = db.document(userProfilePath(userId: currentUserID))
        let friendRef = db.document(userProfilePath(userId: friendID))
        
        // Verify both users exist
        let currentUserDoc = try await currentUserRef.getDocument()
        let friendDoc = try await friendRef.getDocument()
        
        guard currentUserDoc.exists else {
            throw FirestoreError.userNotFound
        }
        
        guard friendDoc.exists else {
            throw FirestoreError.friendNotFound
        }
        
        // Get current friend lists
        let currentUser = try currentUserDoc.data(as: User.self)
        let friend = try friendDoc.data(as: User.self)
        
        // Check if already friends
        if currentUser.isFriend(with: friendID) {
            print("⚠️ Users are already friends")
            throw FirestoreError.alreadyFriends
        }
        
        // Perform two-way update using batch write for atomicity
        let batch = db.batch()
        
        // Add friend to current user's friend list
        batch.updateData([
            "friend_ids": FieldValue.arrayUnion([friendID])
        ], forDocument: currentUserRef)
        
        // Add current user to friend's friend list
        batch.updateData([
            "friend_ids": FieldValue.arrayUnion([currentUserID])
        ], forDocument: friendRef)
        
        // Commit the batch
        try await batch.commit()
        
        print("✅ Friend relationship created successfully")
    }
    
    /// Removes a two-way friend relationship between two users
    ///
    /// - Parameters:
    ///   - currentUserID: The UID of the current user
    ///   - friendID: The UID of the friend to remove
    /// - Throws: Error if either update fails
    static func removeFriend(currentUserID: String, friendID: String) async throws {
        print("👥 Removing friend relationship: \(currentUserID) <-> \(friendID)")
        
        let currentUserRef = db.document(userProfilePath(userId: currentUserID))
        let friendRef = db.document(userProfilePath(userId: friendID))
        
        // Perform two-way update using batch write
        let batch = db.batch()
        
        batch.updateData([
            "friend_ids": FieldValue.arrayRemove([friendID])
        ], forDocument: currentUserRef)
        
        batch.updateData([
            "friend_ids": FieldValue.arrayRemove([currentUserID])
        ], forDocument: friendRef)
        
        try await batch.commit()
        
        print("✅ Friend relationship removed")
    }
    
    // MARK: - User Search
    
    /// Searches for a user by email address
    ///
    /// - Parameter email: The email to search for
    /// - Returns: User object if found, nil otherwise
    static func searchUserByEmail(email: String) async throws -> User? {
        let searchEmail = email.lowercased()
        print("🔍 Searching for user by email: \(searchEmail)")
        
        // Use collection group query on "user_data" collection
        // Then filter for documents with matching email
        print("🔍 Using collectionGroup query for 'user_data' collection...")
        
        let querySnapshot = try await db.collectionGroup("user_data")
            .whereField("email", isEqualTo: searchEmail)
            .limit(to: 1)
            .getDocuments()
        
        print("🔍 Query returned \(querySnapshot.documents.count) documents")
        
        guard let document = querySnapshot.documents.first else {
            print("❌ No user found with email: \(searchEmail)")
            print("💡 Tip: Check Firestore Console to verify the email is stored as: \(searchEmail)")
            return nil
        }
        
        let user = try document.data(as: User.self)
        print("✅ User found: \(user.email) (ID: \(user.id))")
        
        return user
    }
    
    // MARK: - Private Expense Operations
    
    /// Logs a new private expense (IOU) for a user
    ///
    /// - Parameters:
    ///   - expense: The PrivateExpense object to save
    ///   - userID: The UID of the user who owns this expense record
    /// - Throws: Error if the write fails
    static func logPrivateExpense(expense: PrivateExpense, userID: String) async throws {
        print("💰 Logging private expense for user: \(userID)")
        
        // Get reference to the expense document
        let expenseRef = db.collection(privateExpensesPath(userId: userID))
            .document(expense.id)
        
        // Save the expense
        try expenseRef.setData(from: expense)
        
        print("✅ Private expense logged: \(expense.description) - \(expense.formattedAmount)")
    }
    
    /// Fetches all private expenses for a specific user
    ///
    /// - Parameter userID: The UID of the user
    /// - Returns: Array of PrivateExpense objects, sorted by date (newest first)
    static func fetchPrivateExpenses(userID: String) async throws -> [PrivateExpense] {
        print("🔍 Fetching private expenses for user: \(userID)")
        
        let expensesRef = db.collection(privateExpensesPath(userId: userID))
        
        let querySnapshot = try await expensesRef
            .order(by: "date", descending: true)
            .getDocuments()
        
        let expenses = try querySnapshot.documents.compactMap { document in
            try document.data(as: PrivateExpense.self)
        }
        
        print("✅ Fetched \(expenses.count) private expenses")
        return expenses
    }
    
    /// Fetches private expenses between two specific users
    ///
    /// - Parameters:
    ///   - userID: The current user's UID
    ///   - friendID: The friend's UID
    /// - Returns: Array of expenses involving both users
    static func fetchPrivateExpensesWith(userID: String, friendID: String) async throws -> [PrivateExpense] {
        print("🔍 Fetching expenses between \(userID) and \(friendID)")
        
        // Fetch all expenses for the current user
        let allExpenses = try await fetchPrivateExpenses(userID: userID)
        
        // Filter to only include expenses with the specific friend
        let filteredExpenses = allExpenses.filter { expense in
            (expense.payerID == userID && expense.recipientID == friendID) ||
            (expense.payerID == friendID && expense.recipientID == userID)
        }
        
        print("✅ Found \(filteredExpenses.count) expenses between users")
        return filteredExpenses
    }
    
    /// Calculates the net balance between two users
    ///
    /// - Parameters:
    ///   - userID: The current user's UID
    ///   - friendID: The friend's UID
    /// - Returns: Net amount (positive = friend owes user, negative = user owes friend)
    static func calculateBalance(between userID: String, and friendID: String) async throws -> Double {
        let expenses = try await fetchPrivateExpensesWith(userID: userID, friendID: friendID)
        
        let balance = expenses.reduce(0.0) { total, expense in
            return total + expense.netAmountFor(userID: userID)
        }
        
        print("💵 Balance: \(balance)")
        return balance
    }
    
    /// Deletes a private expense
    ///
    /// - Parameters:
    ///   - expenseID: The ID of the expense to delete
    ///   - userID: The UID of the user who owns the expense
    /// - Throws: Error if deletion fails
    static func deletePrivateExpense(expenseID: String, userID: String) async throws {
        print("🗑️ Deleting expense: \(expenseID)")
        
        let expenseRef = db.collection(privateExpensesPath(userId: userID))
            .document(expenseID)
        
        try await expenseRef.delete()
        
        print("✅ Expense deleted")
    }
    
    // MARK: - Group Management Operations
    
    /// Creates a new group with specified members
    ///
    /// - Parameters:
    ///   - name: Display name for the group
    ///   - members: Array of User objects who will be members (including creator)
    ///   - creatorID: UID of the user creating the group
    /// - Returns: The created Group object
    /// - Throws: Error if the Firestore write fails
    static func createGroup(name: String, members: [User], creatorID: String) async throws -> Group {
        print("📝 Creating group: \(name)")
        
        // Extract member IDs from User objects
        let memberIDs = members.map { $0.id }
        
        // Ensure creator is included in members
        var finalMemberIDs = memberIDs
        if !finalMemberIDs.contains(creatorID) {
            finalMemberIDs.append(creatorID)
        }
        
        // Create the Group object
        let group = Group(
            name: name,
            creatorID: creatorID,
            memberIDs: finalMemberIDs,
            createdAt: Date()
        )
        
        // Get reference to the group document
        let groupRef = db.collection(groupsCollectionPath).document(group.id)
        
        // Save the group to Firestore
        try groupRef.setData(from: group)
        
        print("✅ Group created successfully: \(name) with \(finalMemberIDs.count) members")
        
        return group
    }
    
    /// Fetches a single group by ID
    ///
    /// - Parameter groupID: The ID of the group to fetch
    /// - Returns: Group object if found
    /// - Throws: Error if the group doesn't exist or decoding fails
    static func fetchGroup(groupID: String) async throws -> Group {
        print("🔍 Fetching group: \(groupID)")
        
        let groupRef = db.collection(groupsCollectionPath).document(groupID)
        let document = try await groupRef.getDocument()
        
        guard document.exists else {
            throw FirestoreError.groupNotFound
        }
        
        let group = try document.data(as: Group.self)
        print("✅ Group fetched: \(group.name)")
        
        return group
    }
    
    /// Fetches all groups where the user is a member
    ///
    /// - Parameter userID: The UID of the user
    /// - Returns: Array of Group objects
    static func fetchUserGroups(userID: String) async throws -> [Group] {
        print("🔍 Fetching groups for user: \(userID)")
        
        let querySnapshot = try await db.collection(groupsCollectionPath)
            .whereField("member_ids", arrayContains: userID)
            .order(by: "created_at", descending: true)
            .getDocuments()
        
        let groups = try querySnapshot.documents.compactMap { document in
            try document.data(as: Group.self)
        }
        
        print("✅ Fetched \(groups.count) groups")
        return groups
    }
    
    /// Sets up a real-time listener for user's groups
    ///
    /// - Parameters:
    ///   - userID: The UID of the user
    ///   - completion: Callback with updated groups array
    /// - Returns: ListenerRegistration to remove listener when done
    static func listenToUserGroups(userID: String, completion: @escaping ([Group]) -> Void) -> ListenerRegistration {
        print("👂 Setting up real-time listener for groups (user: \(userID))")
        
        return db.collection(groupsCollectionPath)
            .whereField("member_ids", arrayContains: userID)
            .order(by: "created_at", descending: true)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("❌ Group listener error: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    completion([])
                    return
                }
                
                let groups = documents.compactMap { document -> Group? in
                    try? document.data(as: Group.self)
                }
                
                print("🔄 Groups updated: \(groups.count) groups")
                completion(groups)
            }
    }
    
    // MARK: - Group Expense Operations
    
<<<<<<< HEAD
    /// Logs a new group expense to Firestore
    ///
    /// This function handles all split types (equal, exact amounts, percentages) automatically.
    /// The split calculation is performed in the UI layer (AddExpenseView), and this function
    /// simply persists the expense to Firestore.
    ///
    /// **Supported Split Types:**
    /// - `.equal`: Total divided equally among all members
    /// - `.exactAmounts`: Each member owes a specific dollar amount
    /// - `.percentages`: Each member owes a percentage of the total
    ///
    /// **Receipt Support:**
    /// - If expense.receiptURL is present, it's saved with the expense
    /// - Receipt URL should be obtained from `uploadReceipt()` function
    ///
    /// - Parameters:
    ///   - expense: The GroupExpense object to save (with calculated memberOwed dictionary)
    ///   - groupID: The ID of the group this expense belongs to
    /// - Throws: Error if the write fails
    ///
    /// Example:
    /// ```swift
    /// let expense = GroupExpense(
    ///     groupID: "group-123",
    ///     description: "Dinner",
    ///     totalAmount: 60.0,
    ///     paidByID: "user-1",
    ///     splitType: .percentages,
    ///     memberOwed: ["user-1": 0, "user-2": 36, "user-3": 24],
    ///     receiptURL: "https://..."
    /// )
    /// try await FirestoreService.logGroupExpense(expense: expense, groupID: "group-123")
    /// ```
    static func logGroupExpense(expense: GroupExpense, groupID: String) async throws {
        print("💰 Logging group expense: \(expense.description) for group: \(groupID)")
        print("   Split Type: \(expense.splitType.displayName)")
        print("   Receipt: \(expense.hasReceipt ? "Attached" : "None")")
=======
    /// Logs a new group expense
    ///
    /// - Parameters:
    ///   - expense: The GroupExpense object to save
    ///   - groupID: The ID of the group this expense belongs to
    /// - Throws: Error if the write fails
    static func logGroupExpense(expense: GroupExpense, groupID: String) async throws {
        print("💰 Logging group expense: \(expense.description) for group: \(groupID)")
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
        
        // Get reference to the expense document
        let expenseRef = db.collection(groupExpensesPath(groupID: groupID))
            .document(expense.id)
        
<<<<<<< HEAD
        // Save the expense (Codable automatically handles all split types and optional receiptURL)
=======
        // Save the expense
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
        try expenseRef.setData(from: expense)
        
        print("✅ Group expense logged: \(expense.description) - \(expense.formattedTotalAmount)")
    }
    
    /// Fetches all expenses for a specific group
    ///
    /// - Parameter groupID: The ID of the group
    /// - Returns: Array of GroupExpense objects, sorted by date (newest first)
    static func fetchGroupExpenses(groupID: String) async throws -> [GroupExpense] {
        print("🔍 Fetching expenses for group: \(groupID)")
        
        let querySnapshot = try await db.collection(groupExpensesPath(groupID: groupID))
            .order(by: "date", descending: true)
            .getDocuments()
        
        let expenses = try querySnapshot.documents.compactMap { document in
            try document.data(as: GroupExpense.self)
        }
        
        print("✅ Fetched \(expenses.count) group expenses")
        return expenses
    }
    
    /// Sets up a real-time listener for group expenses
    ///
    /// - Parameters:
    ///   - groupID: The ID of the group
    ///   - completion: Callback with updated expenses array
    /// - Returns: ListenerRegistration to remove listener when done
    static func listenToGroupExpenses(groupID: String, completion: @escaping ([GroupExpense]) -> Void) -> ListenerRegistration {
        print("👂 Setting up real-time listener for group expenses (group: \(groupID))")
        
        return db.collection(groupExpensesPath(groupID: groupID))
            .order(by: "date", descending: true)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("❌ Expense listener error: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    completion([])
                    return
                }
                
                let expenses = documents.compactMap { document -> GroupExpense? in
                    try? document.data(as: GroupExpense.self)
                }
                
                print("🔄 Group expenses updated: \(expenses.count) expenses")
                completion(expenses)
            }
    }
    
    /// Deletes a group expense
    ///
    /// - Parameters:
    ///   - expenseID: The ID of the expense to delete
    ///   - groupID: The ID of the group the expense belongs to
    /// - Throws: Error if deletion fails
    static func deleteGroupExpense(expenseID: String, groupID: String) async throws {
        print("🗑️ Deleting group expense: \(expenseID)")
        
        let expenseRef = db.collection(groupExpensesPath(groupID: groupID))
            .document(expenseID)
        
        try await expenseRef.delete()
        
        print("✅ Group expense deleted")
    }
    
    /// Calculates the net balance for a user within a group
    ///
    /// - Parameters:
    ///   - userID: The UID of the user
    ///   - groupID: The ID of the group
    /// - Returns: Net balance (positive = owed money, negative = owes money)
    static func calculateUserBalanceInGroup(userID: String, groupID: String) async throws -> Double {
        print("💵 Calculating balance for user \(userID) in group \(groupID)")
        
        let expenses = try await fetchGroupExpenses(groupID: groupID)
        
        // Sum up the net balance from all expenses
        let balance = expenses.reduce(0.0) { total, expense in
            return total + expense.netBalanceFor(userID: userID)
        }
        
        print("💵 Balance: \(balance)")
        return balance
    }
<<<<<<< HEAD
    
    // MARK: - Settlement Operations
    
    /// Records a settlement (payment) between two users in a group
    ///
    /// A settlement is stored as a special type of expense in the group's expenses collection.
    /// When calculating balances, settlements reduce the debt between the payer and recipient.
    ///
    /// **How Settlements Work:**
    /// - Payer is the person making the payment (reducing their debt)
    /// - Recipient is the person receiving the payment (being paid back)
    /// - The settlement is recorded as a GroupExpense where:
    ///   - paidByID = recipient (the person receiving money)
    ///   - memberOwed[payer] = amount (the payer "owes" this amount, which cancels their actual debt)
    ///   - splitType = .equal (not really relevant for settlements)
    ///
    /// **Example:**
    /// - Alice owes Bob $50 from previous expenses
    /// - Alice pays Bob $50
    /// - Settlement is recorded:
    ///   - payerID = Alice, recipientID = Bob, amount = 50
    ///   - Stored as GroupExpense: paidByID = Bob, memberOwed[Alice] = 50
    /// - Balance calculation sees Bob "paid" $50 and Alice "owes" $50
    /// - This reduces Alice's debt to Bob by $50
    ///
    /// - Parameters:
    ///   - settlement: The Settlement object containing payment details
    ///   - groupID: The ID of the group this settlement is for
    /// - Throws: Error if the write fails
    static func recordSettlement(settlement: Settlement, groupID: String) async throws {
        print("💳 Recording settlement: \(settlement.payerID) → \(settlement.recipientID): \(settlement.formattedAmount)")
        
        // Convert settlement to a special GroupExpense
        // The recipient is marked as having "paid" this amount
        // The payer is marked as "owing" this amount
        // This effectively reduces the payer's debt to the recipient
        
        let memberOwed: [String: Double] = [
            settlement.recipientID: 0.0,        // Recipient doesn't owe anything (they received payment)
            settlement.payerID: settlement.amount  // Payer "owes" this amount (which cancels their real debt)
        ]
        
        let settlementExpense = GroupExpense(
            id: settlement.id,
            groupID: groupID,
            description: "Settlement: \(settlement.note ?? "Payment")",
            totalAmount: settlement.amount,
            paidByID: settlement.recipientID,  // Recipient is treated as having "paid"
            splitType: .equal,  // Split type doesn't matter for settlements
            memberOwed: memberOwed,
            date: settlement.date,
            receiptURL: nil
        )
        
        // Save to the same expenses collection
        try await logGroupExpense(expense: settlementExpense, groupID: groupID)
        
        print("✅ Settlement recorded successfully")
    }
    
    /// Records a private settlement (payment) between two friends outside of a group
    ///
    /// Similar to group settlements, but stored in the user's private expenses collection.
    ///
    /// - Parameters:
    ///   - settlement: The Settlement object containing payment details
    ///   - userID: The UID of the user recording the settlement
    /// - Throws: Error if the write fails
    static func recordPrivateSettlement(settlement: Settlement, userID: String) async throws {
        print("💳 Recording private settlement: \(settlement.payerID) → \(settlement.recipientID): \(settlement.formattedAmount)")
        
        // Convert settlement to a PrivateExpense
        // If current user is the payer, they are paying the recipient
        // If current user is the recipient, they are receiving from the payer
        
        let privateExpense = PrivateExpense(
            id: settlement.id,
            payerID: settlement.recipientID,     // Recipient is treated as payer
            recipientID: settlement.payerID,     // Payer is treated as recipient
            amount: settlement.amount,
            description: "Settlement: \(settlement.note ?? "Payment")",
            date: settlement.date,
            note: settlement.note
        )
        
        // Save to private expenses collection
        try await logPrivateExpense(expense: privateExpense, userID: userID)
        
        print("✅ Private settlement recorded successfully")
    }
    
    // MARK: - Receipt Upload Operations (Mock Implementation)
    
    /// Mock function to simulate receipt image upload to Firebase Storage
    ///
    /// **IMPORTANT**: This is a mock implementation for Sprint 3.
    /// In a production app, this would:
    /// 1. Compress the image to reduce file size
    /// 2. Upload to Firebase Storage at path: receipts/{groupID}/{expenseID}.jpg
    /// 3. Return the actual download URL from Firebase Storage
    ///
    /// For Sprint 3, we immediately return a mock URL to simulate a successful upload.
    ///
    /// - Parameters:
    ///   - imageData: The receipt image data (not used in mock)
    ///   - groupID: The ID of the group (used in mock URL)
    ///   - expenseID: The ID of the expense (used in mock URL)
    /// - Returns: Mock download URL string
    ///
    /// Example Usage:
    /// ```swift
    /// let mockURL = await FirestoreService.uploadReceipt(
    ///     imageData: imageData,
    ///     groupID: "group-123",
    ///     expenseID: "expense-456"
    /// )
    /// // Returns: "https://firebasestorage.googleapis.com/mock/receipts/group-123/expense-456.jpg"
    /// ```
    static func uploadReceipt(imageData: Data, groupID: String, expenseID: String) async -> String {
        print("📸 [MOCK] Uploading receipt for expense \(expenseID) in group \(groupID)")
        
        // Simulate a slight delay to mimic network upload
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Generate a mock download URL that looks realistic
        let mockURL = "https://firebasestorage.googleapis.com/v0/b/splitpro-mock.appspot.com/o/receipts%2F\(groupID)%2F\(expenseID).jpg?alt=media&token=mock-token-\(UUID().uuidString.prefix(8))"
        
        print("✅ [MOCK] Receipt uploaded successfully")
        print("📎 [MOCK] Download URL: \(mockURL)")
        
        return mockURL
    }
=======
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
}

// MARK: - Custom Errors

/// Custom errors for Firestore operations
enum FirestoreError: LocalizedError {
    case userNotFound
    case friendNotFound
    case alreadyFriends
    case cannotAddSelfAsFriend
    case groupNotFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User profile not found"
        case .friendNotFound:
            return "Friend's profile not found"
        case .alreadyFriends:
            return "You are already friends with this user"
        case .cannotAddSelfAsFriend:
            return "You cannot add yourself as a friend"
        case .groupNotFound:
            return "Group not found"
        case .invalidData:
            return "Invalid data format"
        }
    }
}

