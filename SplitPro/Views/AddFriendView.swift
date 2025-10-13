//
//  AddFriendView.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/13/25.
//

import SwiftUI

/// AddFriendView: Interface for searching and adding new friends
///
/// This view allows users to:
/// - Search for other users by email address or UID
/// - View search results
/// - Send friend requests (add friends)
///
/// The friend relationship is created as a two-way connection,
/// meaning both users will see each other in their friend lists.
struct AddFriendView: View {
    
    // MARK: - Environment Objects
    
    /// Access to authentication manager for current user info
    @EnvironmentObject var authManager: AuthenticationManager
    
    /// Environment variable to dismiss this view
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State Properties
    
    /// Search query entered by the user (email or UID)
    @State private var searchQuery: String = ""
    
    /// User found by the search (if any)
    @State private var foundUser: User? = nil
    
    /// Indicates if a search is in progress
    @State private var isSearching: Bool = false
    
    /// Indicates if adding friend operation is in progress
    @State private var isAddingFriend: Bool = false
    
    /// Error message to display (if any)
    @State private var errorMessage: String? = nil
    
    /// Success message to display (if any)
    @State private var successMessage: String? = nil
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Instructions
                    instructionsView
                        .padding(.top, 20)
                    
                    // Search bar
                    searchBarView
                        .padding(.horizontal)
                    
                    // Search result or messages
                    if isSearching {
                        ProgressView("Searching...")
                            .padding()
                    } else if let user = foundUser {
                        userResultView(user: user)
                            .padding(.horizontal)
                    } else if let error = errorMessage {
                        errorView(message: error)
                            .padding(.horizontal)
                    } else if let success = successMessage {
                        successView(message: success)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Instructions for the user
    private var instructionsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.blue)
            
            Text("Find Friends")
                .font(.headline)
            
            Text("Search by email address to add friends")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }
    
    /// Search bar with search button
    private var searchBarView: some View {
        HStack(spacing: 12) {
            // Search field
            TextField("Enter email address", text: $searchQuery)
                .textFieldStyle(.plain)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .onSubmit {
                    performSearch()
                }
            
            // Search button
            Button(action: performSearch) {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(searchQuery.isEmpty || isSearching)
        }
    }
    
    /// Display search result (found user)
    private func userResultView(user: User) -> some View {
        VStack(spacing: 16) {
            // User card
            VStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.green, .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                    
                    Text(user.displayName.prefix(1).uppercased())
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // User info
                VStack(spacing: 4) {
                    Text(user.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            // Add Friend button
            Button(action: addFriend) {
                HStack {
                    if isAddingFriend {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text(isAddingFriend ? "Adding..." : "Add Friend")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isAddingFriend)
        }
    }
    
    /// Error message view
    private func errorView(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.red)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    /// Success message view
    private func successView(message: String) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.green)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    /// Performs search for user by email
    private func performSearch() {
        // Reset state
        foundUser = nil
        errorMessage = nil
        successMessage = nil
        isSearching = true
        
        // Trim and validate search query
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !query.isEmpty else {
            errorMessage = "Please enter an email address"
            isSearching = false
            return
        }
        
        // Perform search
        Task {
            do {
                // Add debug logging
                print("🔍 Searching for user with email: \(query)")
                
                // Search by email
                if let user = try await FirestoreService.searchUserByEmail(email: query) {
                    print("✅ Found user: \(user.email) (ID: \(user.id))")
                    
                    // Check if this is the current user
                    if user.id == authManager.currentUserUID {
                        errorMessage = "You cannot add yourself as a friend"
                        foundUser = nil
                    }
                    // Check if already friends
                    else if authManager.currentUserProfile?.isFriend(with: user.id) == true {
                        errorMessage = "You are already friends with \(user.displayName)"
                        foundUser = nil
                    }
                    // User found and can be added
                    else {
                        foundUser = user
                    }
                } else {
                    print("❌ No user found with email: \(query)")
                    errorMessage = "No user found with email: \(query)"
                    foundUser = nil
                }
            } catch {
                print("❌ Search error: \(error.localizedDescription)")
                errorMessage = "Search failed: \(error.localizedDescription)"
                foundUser = nil
            }
            
            isSearching = false
        }
    }
    
    /// Adds the found user as a friend
    private func addFriend() {
        guard let friend = foundUser,
              let currentUserID = authManager.currentUserUID else {
            return
        }
        
        isAddingFriend = true
        errorMessage = nil
        
        Task {
            do {
                // Add friend relationship in Firestore
                try await FirestoreService.addFriend(
                    currentUserID: currentUserID,
                    friendID: friend.id
                )
                
                // Refresh user profile and friends list
                await authManager.refreshUserProfile()
                
                // Show success message
                successMessage = "\(friend.displayName) added as a friend!"
                foundUser = nil
                searchQuery = ""
                
                // Automatically dismiss after 1.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
                
            } catch {
                errorMessage = "Failed to add friend: \(error.localizedDescription)"
            }
            
            isAddingFriend = false
        }
    }
}

// MARK: - Preview

#Preview {
    let authManager = AuthenticationManager()
    authManager.currentUserUID = "current-user-123"
    authManager.currentUserProfile = User.sample
    
    return AddFriendView()
        .environmentObject(authManager)
}

