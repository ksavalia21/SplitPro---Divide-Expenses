//
//  CreateGroupView.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/13/25.
//

import SwiftUI

/// CreateGroupView: Interface for creating a new expense-sharing group
///
/// This view allows users to:
/// - Name the group
/// - Select multiple friends to add as members
/// - Create the group in Firestore
///
/// The current user is automatically added as a member and marked as the creator.
struct CreateGroupView: View {
    
    // MARK: - Environment Objects
    
    /// Access to authentication manager for current user and friends
    @EnvironmentObject var authManager: AuthenticationManager
    
    /// Environment variable to dismiss this view
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State Properties
    
    /// Name of the group being created
    @State private var groupName: String = ""
    
    /// Set of selected friend IDs
    @State private var selectedFriendIDs: Set<String> = []
    
    /// Indicates if group creation is in progress
    @State private var isCreating: Bool = false
    
    /// Error message to display
    @State private var errorMessage: String? = nil
    
    // MARK: - Computed Properties
    
    /// True if the form is valid and ready to submit
    private var isFormValid: Bool {
        !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedFriendIDs.isEmpty
    }
    
    /// Array of selected friends (User objects)
    private var selectedFriends: [User] {
        authManager.friends.filter { selectedFriendIDs.contains($0.id) }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // Group name section
                groupNameSection
                
                // Member selection section
                memberSelectionSection
                
                // Selected members preview
                if !selectedFriendIDs.isEmpty {
                    selectedMembersSection
                }
                
                // Error message (if any)
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createGroup()
                    }
                    .disabled(!isFormValid || isCreating)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Form Sections
    
    /// Section for entering group name
    private var groupNameSection: some View {
        Section {
            TextField("e.g., Apartment 4B, Europe Trip", text: $groupName)
        } header: {
            Text("Group Name")
        } footer: {
            Text("Choose a descriptive name for your group")
        }
    }
    
    /// Section for selecting group members
    private var memberSelectionSection: some View {
        Section {
            if authManager.friends.isEmpty {
                // No friends available
                VStack(spacing: 12) {
                    Image(systemName: "person.2.slash")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    Text("No Friends Yet")
                        .font(.headline)
                    
                    Text("Add friends first to create a group")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                // List of friends with checkboxes
                ForEach(authManager.friends) { friend in
                    Button(action: {
                        toggleFriend(friend)
                    }) {
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
                                
                                Text(friend.displayName.prefix(1).uppercased())
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            
                            // Friend info
                            VStack(alignment: .leading, spacing: 2) {
                                Text(friend.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                Text(friend.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Checkbox
                            Image(systemName: selectedFriendIDs.contains(friend.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedFriendIDs.contains(friend.id) ? .blue : .gray)
                                .font(.title3)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            Text("Select Members")
        } footer: {
            Text("Select friends to add to the group. You'll be added automatically.")
        }
    }
    
    /// Section showing selected members count
    private var selectedMembersSection: some View {
        Section {
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.blue)
                
                Text("\(selectedFriendIDs.count + 1) members selected")
                    .font(.subheadline)
                
                Spacer()
                
                Text("(including you)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Toggles selection of a friend
    private func toggleFriend(_ friend: User) {
        if selectedFriendIDs.contains(friend.id) {
            selectedFriendIDs.remove(friend.id)
        } else {
            selectedFriendIDs.insert(friend.id)
        }
    }
    
    /// Creates the group in Firestore
    private func createGroup() {
        guard let currentUserID = authManager.currentUserUID else {
            errorMessage = "Not authenticated"
            return
        }
        
        let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a group name"
            return
        }
        
        guard !selectedFriendIDs.isEmpty else {
            errorMessage = "Please select at least one friend"
            return
        }
        
        isCreating = true
        errorMessage = nil
        
        Task {
            do {
                // Get User objects for selected friends
                let members = selectedFriends
                
                // Create the group
                let _ = try await FirestoreService.createGroup(
                    name: trimmedName,
                    members: members,
                    creatorID: currentUserID
                )
                
                print("✅ Group created successfully")
                
                // Dismiss the view
                // The groups list will automatically update via the snapshot listener
                dismiss()
                
            } catch {
                errorMessage = "Failed to create group: \(error.localizedDescription)"
                isCreating = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let authManager = AuthenticationManager()
    authManager.currentUserUID = "current-user-123"
    authManager.friends = User.sampleArray
    
    return CreateGroupView()
        .environmentObject(authManager)
}

