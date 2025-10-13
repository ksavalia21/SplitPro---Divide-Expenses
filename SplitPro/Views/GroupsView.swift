//
//  GroupsView.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/13/25.
//

import SwiftUI

/// GroupsView: Displays a list of all groups the current user is a member of
///
/// This view shows groups in real-time using Firestore snapshot listeners.
/// Users can:
/// - View all their groups
/// - Create new groups
/// - Navigate to group details
///
/// The groups list automatically updates when:
/// - New groups are created
/// - Group members change
/// - Groups are deleted
struct GroupsView: View {
    
    // MARK: - Environment Objects
    
    /// Access to authentication manager for groups and user info
    @EnvironmentObject var authManager: AuthenticationManager
    
    // MARK: - State Properties
    
    /// Controls whether to show the Create Group sheet
    @State private var showingCreateGroup = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Main content
                if authManager.activeGroups.isEmpty {
                    // Empty state when user has no groups
                    emptyStateView
                } else {
                    // List of groups
                    groupsListView
                }
            }
            .navigationTitle("Groups")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // Create Group button in toolbar
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateGroup = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView()
            }
        }
    }
    
    // MARK: - Subviews
    
    /// List view displaying all groups
    private var groupsListView: some View {
        List {
            ForEach(authManager.activeGroups) { group in
                // Navigate to group details on tap
                NavigationLink(destination: GroupDetailsView(group: group)) {
                    GroupRowView(group: group)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    /// Empty state view shown when user has no groups
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: "person.3.slash")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.gray)
            
            // Title
            Text("No Groups Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Description
            Text("Create a group to start splitting expenses with friends")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Create Group button
            Button(action: {
                showingCreateGroup = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Your First Group")
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
}

// MARK: - Group Row View

/// Individual row view for displaying a group in the list
struct GroupRowView: View {
    let group: Group
    
    var body: some View {
        HStack(spacing: 15) {
            // Group icon with member count
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.green, .blue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                
                VStack(spacing: 2) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    
                    Text("\(group.memberCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            // Group info
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                
                Text("\(group.memberCount) members")
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

#Preview("With Groups") {
    let authManager = AuthenticationManager()
    authManager.activeGroups = Group.sampleArray
    
    return GroupsView()
        .environmentObject(authManager)
}

#Preview("Empty State") {
    let authManager = AuthenticationManager()
    authManager.activeGroups = []
    
    return GroupsView()
        .environmentObject(authManager)
}

