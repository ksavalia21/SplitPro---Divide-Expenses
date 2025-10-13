//
//  HomeView.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/13/25.
//

import SwiftUI

/// HomeView: The main authenticated view shown after successful login
///
/// This is the main dashboard that provides access to all SplitPro features:
/// - Dashboard with overview statistics
/// - Friends management
/// - Profile settings
///
/// Uses a TabView for easy navigation between main sections.
struct HomeView: View {
    
    // MARK: - Environment Objects
    
    /// Access to the authentication manager for logout and user info
    @EnvironmentObject var authManager: AuthenticationManager
    
    // MARK: - State Properties
    
    /// Currently selected tab
    @State private var selectedTab: Tab = .dashboard
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(Tab.dashboard)
            
            // Groups Tab
            GroupsView()
                .tabItem {
                    Label("Groups", systemImage: "person.3.fill")
                }
                .tag(Tab.groups)
            
            // Friends Tab
            FriendsView()
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }
                .tag(Tab.friends)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(Tab.profile)
        }
    }
    
    // MARK: - Tab Enum
    
    enum Tab {
        case dashboard
        case groups
        case friends
        case profile
    }
}

// MARK: - Dashboard View

/// Main dashboard showing overview and quick actions
struct DashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingLogIOU = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Welcome card
                        welcomeCard
                        
                        // Quick stats
                        quickStatsSection
                        
                        // Quick actions
                        quickActionsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingLogIOU) {
                LogIOUView()
            }
        }
    }
    
    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome back!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let profile = authManager.currentUserProfile {
                        Text(profile.displayName)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 60, height: 60)
                    
                    if let profile = authManager.currentUserProfile {
                        Text(profile.displayName.prefix(1).uppercased())
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var quickStatsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Quick Stats")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 12) {
                // Friends count
                StatCard(
                    title: "Friends",
                    value: "\(authManager.friends.count)",
                    icon: "person.2.fill",
                    color: .blue
                )
                
                // Groups count
                StatCard(
                    title: "Groups",
                    value: "\(authManager.activeGroups.count)",
                    icon: "person.3.fill",
                    color: .green
                )
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Quick Actions")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Log IOU button
                Button(action: {
                    showingLogIOU = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Log New IOU")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Profile View

/// User profile and settings view
struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationStack {
            Form {
                // User info section
                if let profile = authManager.currentUserProfile {
                    Section {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(profile.name)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(profile.email)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("User ID")
                            Spacer()
                            Text(profile.id.prefix(8) + "...")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text("Profile Information")
                    }
                }
                
                // Statistics section
                Section {
                    HStack {
                        Label("Friends", systemImage: "person.2.fill")
                        Spacer()
                        Text("\(authManager.friends.count)")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Statistics")
                }
                
                // Actions section
                Section {
                    Button(role: .destructive, action: {
                        authManager.logOut()
                    }) {
                        HStack {
                            Spacer()
                            Label("Log Out", systemImage: "arrow.right.square")
                            Spacer()
                        }
                    }
                } header: {
                    Text("Actions")
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Preview

#Preview {
    // Create a mock authentication manager for preview
    let authManager = AuthenticationManager()
    authManager.isAuthenticated = true
    authManager.currentUserUID = "preview-user-id-12345"
    
    return HomeView()
        .environmentObject(authManager)
}

