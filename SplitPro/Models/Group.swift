//
//  Group.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/13/25.
//

import Foundation

/// Group: Represents a shared expense group with multiple members
///
/// A group is a collection of users who share expenses together.
/// Examples: "Roommates", "Vacation Trip", "Office Lunch Group"
///
/// Groups are stored in a shared public collection so all members can access them.
/// Each member can view the group and its expenses.
///
/// Firestore Path: artifacts/{appId}/public/data/groups/{groupID}
struct Group: Codable, Identifiable, Equatable {
    
    // MARK: - Properties
    
    /// Unique identifier for the group
    /// Generated using UUID when creating a new group
    var id: String
    
    /// Display name of the group
    /// Examples: "Apartment 4B", "Europe Trip 2025", "Weekly Dinners"
    var name: String
    
    /// Firebase UID of the user who created this group
    /// The creator has no special privileges (democratic group)
    var creatorID: String
    
    /// Array of Firebase UIDs for all members in this group
    /// Includes the creator and all added members
    /// Used to filter which groups a user can see
    var memberIDs: [String]
    
    /// Timestamp when the group was created
    var createdAt: Date
    
    // MARK: - Initialization
    
    /// Default initializer for creating a new Group
    ///
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - name: Display name for the group
    ///   - creatorID: UID of the user creating the group
    ///   - memberIDs: Array of member UIDs (should include creator)
    ///   - createdAt: Creation timestamp (defaults to now)
    init(
        id: String = UUID().uuidString,
        name: String,
        creatorID: String,
        memberIDs: [String],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.creatorID = creatorID
        self.memberIDs = memberIDs
        self.createdAt = createdAt
    }
    
    // MARK: - Coding Keys
    
    /// Custom coding keys to match Firestore field names
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case creatorID = "creator_id"
        case memberIDs = "member_ids"
        case createdAt = "created_at"
    }
    
    // MARK: - Computed Properties
    
    /// Number of members in the group
    var memberCount: Int {
        return memberIDs.count
    }
    
    /// Formatted creation date string
    var formattedCreatedAt: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: createdAt)
    }
    
    // MARK: - Helper Methods
    
    /// Checks if a specific user is a member of this group
    ///
    /// - Parameter userID: The UID to check
    /// - Returns: true if the user is a member, false otherwise
    func isMember(userID: String) -> Bool {
        return memberIDs.contains(userID)
    }
    
    /// Checks if a specific user is the creator of this group
    ///
    /// - Parameter userID: The UID to check
    /// - Returns: true if the user created this group
    func isCreator(userID: String) -> Bool {
        return creatorID == userID
    }
}

// MARK: - Mock Data for Previews

#if DEBUG
extension Group {
    /// Sample group for SwiftUI previews
    static var sample: Group {
        Group(
            id: "group-1",
            name: "Apartment 4B",
            creatorID: "user-1",
            memberIDs: ["user-1", "user-2", "user-3"],
            createdAt: Date()
        )
    }
    
    /// Array of sample groups for testing
    static var sampleArray: [Group] {
        [
            Group(
                id: "group-1",
                name: "Apartment 4B",
                creatorID: "user-1",
                memberIDs: ["user-1", "user-2", "user-3"]
            ),
            Group(
                id: "group-2",
                name: "Europe Trip 2025",
                creatorID: "user-2",
                memberIDs: ["user-1", "user-2", "user-3", "user-4"]
            ),
            Group(
                id: "group-3",
                name: "Weekly Dinners",
                creatorID: "user-1",
                memberIDs: ["user-1", "user-2"]
            )
        ]
    }
}
#endif

