//
//  FriendsView.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/13/25.
//

import SwiftUI

/// FriendsView: Displays a list of the current user's friends
///
/// This view shows all friends from the AuthenticationManager's friends array
/// and provides navigation to:
/// - AddFriendView (to add new friends)
/// - FriendDetailsView (to see IOU details with a specific friend)
///
/// Features:
/// - Clean list interface with user information
/// - Empty state when user has no friends
/// - Pull-to-refresh to reload friend list
/// - Navigation to friend details on tap
struct FriendsView: View {
    
    // MARK: - Environment Objects
    
    /// Access to authentication manager for current user and friend list
    @EnvironmentObject var authManager: AuthenticationManager
    
    // MARK: - State Properties
    
    /// Controls whether to show the Add Friend sheet
    @State private var showingAddFriend = false
    
    /// Indicates if friends are being refreshed
    @State private var isRefreshing = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Main content
                if authManager.friends.isEmpty {
                    // Empty state when user has no friends
                    emptyStateView
                } else {
                    // List of friends
                    friendsListView
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // Add Friend button in toolbar
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddFriend = true
                    }) {
                        Image(systemName: "person.badge.plus")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView()
            }
            .refreshable {
                // Pull-to-refresh functionality
                await refreshFriends()
            }
        }
    }
    
    // MARK: - Subviews
    
    /// List view displaying all friends
    private var friendsListView: some View {
        List {
            ForEach(authManager.friends) { friend in
                // Navigate to friend details on tap
                NavigationLink(destination: FriendDetailsView(friend: friend)) {
                    FriendRowView(friend: friend)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    /// Empty state view shown when user has no friends
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: "person.2.slash")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.gray)
            
            // Title
            Text("No Friends Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Description
            Text("Add friends to start tracking expenses together")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Add Friend button
            Button(action: {
                showingAddFriend = true
            }) {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Add Your First Friend")
                }
                .fontWeight(.semibold)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.top, 20)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Refreshes the friend list from Firestore
    private func refreshFriends() async {
        isRefreshing = true
        
        // Refresh the user profile first (to get updated friend IDs)
        await authManager.refreshUserProfile()
        
        isRefreshing = false
    }
}

// MARK: - Friend Row View

/// Individual row view for displaying a friend in the list
struct FriendRowView: View {
    let friend: User
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar circle with initials
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                
                Text(friend.displayName.prefix(1).uppercased())
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            // Friend info
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayName)
                    .font(.headline)
                
                Text(friend.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview("With Friends") {
    let authManager = AuthenticationManager()
    authManager.friends = User.sampleArray
    
    return FriendsView()
        .environmentObject(authManager)
}

#Preview("Empty State") {
    let authManager = AuthenticationManager()
    authManager.friends = []
    
    return FriendsView()
        .environmentObject(authManager)
}

