//
//  User.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/13/25.
//

import Foundation

/// User: The core data model representing a user in the SplitPro application
///
/// This struct defines all the properties needed to represent a user, including
/// their authentication details, profile information, and relationships with other users.
///
/// Conformances:
/// - Codable: Enables encoding/decoding to/from Firestore
/// - Identifiable: Allows SwiftUI to uniquely identify users in lists
/// - Equatable: Enables comparison between User instances
///
/// Firestore Path: artifacts/{appId}/users/{userId}/user_data/profile
struct User: Codable, Identifiable, Equatable {
    
    // MARK: - Properties
    
    /// Unique identifier for the user (matches Firebase Auth UID)
    /// This is used as the Firestore document ID
    var id: String
    
    /// User's email address (from Firebase Authentication)
    var email: String
    
    /// User's display name
    /// This can be set by the user and is different from their email
    var name: String
    
    /// Array of Firebase UIDs representing the user's friends
    /// Each string in this array corresponds to another User's id
    /// This enables quick lookups of friend relationships
    var friendIDs: [String]
    
    /// Optional public key for future payment integration
    /// This is a placeholder for future features like cryptocurrency payments
    /// or integration with payment providers
    var publicKey: String?
    
    // MARK: - Initialization
    
    /// Default initializer for creating a new User
    ///
    /// - Parameters:
    ///   - id: The Firebase Auth UID
    ///   - email: The user's email address
    ///   - name: The user's display name (defaults to email if not provided)
    ///   - friendIDs: Array of friend UIDs (defaults to empty array)
    ///   - publicKey: Optional payment key (defaults to nil)
    init(
        id: String,
        email: String,
        name: String? = nil,
        friendIDs: [String] = [],
        publicKey: String? = nil
    ) {
        self.id = id
        // Always store email in lowercase for consistent searching
        self.email = email.lowercased()
        // If no name is provided, use the email prefix as the default name
        self.name = name ?? email.components(separatedBy: "@").first ?? email
        self.friendIDs = friendIDs
        self.publicKey = publicKey
    }
    
    // MARK: - Coding Keys
    
    /// Custom coding keys to match Firestore field names
    /// This ensures proper encoding/decoding when saving to and reading from Firestore
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case friendIDs = "friend_ids"  // Snake case for Firestore convention
        case publicKey = "public_key"  // Snake case for Firestore convention
    }
    
    // MARK: - Computed Properties
    
    /// Returns true if the user has at least one friend
    var hasFriends: Bool {
        return !friendIDs.isEmpty
    }
    
    /// Returns the number of friends this user has
    var friendCount: Int {
        return friendIDs.count
    }
    
    // MARK: - Helper Methods
    
    /// Checks if this user is friends with another user
    ///
    /// - Parameter userID: The UID of the user to check
    /// - Returns: true if they are friends, false otherwise
    func isFriend(with userID: String) -> Bool {
        return friendIDs.contains(userID)
    }
    
    /// Returns a display name or email for UI purposes
    /// Prioritizes name over email for better UX
    var displayName: String {
        return name.isEmpty ? email : name
    }
}

// MARK: - Mock Data for Previews

#if DEBUG
extension User {
    /// Sample user for SwiftUI previews and testing
    static var sample: User {
        User(
            id: "sample-user-123",
            email: "john.doe@example.com",
            name: "John Doe",
            friendIDs: ["friend-1", "friend-2"],
            publicKey: nil
        )
    }
    
    /// Array of sample users for testing list views
    static var sampleArray: [User] {
        [
            User(id: "user-1", email: "alice@example.com", name: "Alice Johnson"),
            User(id: "user-2", email: "bob@example.com", name: "Bob Smith"),
            User(id: "user-3", email: "charlie@example.com", name: "Charlie Brown")
        ]
    }
}
#endif

