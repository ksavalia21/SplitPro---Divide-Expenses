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

<<<<<<< HEAD
/// Global Dashboard showing comprehensive financial overview
///
/// **Sprint 4 Enhancements:**
/// - Overall net balance summary (You Owe / You Are Owed)
/// - Individual balance breakdown by group and friend
/// - Real-time updates from globalNetBalance
/// - Color-coded indicators for positive/negative balances
=======
/// Main dashboard showing overview and quick actions
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
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
                        
<<<<<<< HEAD
                        // Global balance summary (Sprint 4)
                        globalBalanceSummarySection
                        
                        // Individual balances breakdown (Sprint 4)
                        individualBalancesSection
                        
=======
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
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
    
<<<<<<< HEAD
    /// Global balance summary cards (Sprint 4)
    private var globalBalanceSummarySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Overall Balance")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 12) {
                // You Owe card
                BalanceCard(
                    title: "You Owe",
                    amount: authManager.totalYouOwe,
                    color: .orange,
                    icon: "arrow.down.circle.fill"
                )
                
                // You Are Owed card
                BalanceCard(
                    title: "You Are Owed",
                    amount: authManager.totalOwedToYou,
                    color: .green,
                    icon: "arrow.up.circle.fill"
                )
            }
            
            // Net balance indicator
            if authManager.totalYouOwe != authManager.totalOwedToYou {
                HStack {
                    Image(systemName: "equal.circle")
                        .foregroundColor(.secondary)
                    
                    Text("Net Balance: ")
                        .foregroundColor(.secondary)
                    
                    let netBalance = authManager.totalOwedToYou - authManager.totalYouOwe
                    Text(formatCurrency(netBalance))
                        .fontWeight(.semibold)
                        .foregroundColor(netBalance >= 0 ? .green : .orange)
                }
                .font(.subheadline)
                .padding(.horizontal)
            }
        }
    }
    
    /// Individual balances breakdown section (Sprint 4)
    private var individualBalancesSection: some View {
        VStack(spacing: 12) {
            if !authManager.globalNetBalance.isEmpty {
                HStack {
                    Text("Individual Balances")
                        .font(.headline)
                    Spacer()
                }
                
                VStack(spacing: 8) {
                    ForEach(sortedBalances(), id: \.key) { friendID, balance in
                        IndividualBalanceRow(
                            friendID: friendID,
                            balance: balance,
                            friendName: friendName(for: friendID)
                        )
                    }
                }
            }
        }
    }
    
    /// Returns sorted balances (non-zero balances first, then by absolute value)
    private func sortedBalances() -> [(key: String, value: Double)] {
        authManager.globalNetBalance
            .filter { abs($0.value) > 0.01 }  // Only show non-zero balances
            .sorted { abs($0.value) > abs($1.value) }  // Sort by absolute value descending
    }
    
    /// Returns friend's display name
    private func friendName(for friendID: String) -> String {
        authManager.friends.first(where: { $0.id == friendID })?.displayName ?? "Unknown"
    }
    
    /// Formats currency value
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: abs(value))) ?? "$0.00"
    }
    
=======
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
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

<<<<<<< HEAD
// MARK: - Balance Card (Sprint 4)

/// Card displaying overall balance summary (You Owe / You Are Owed)
struct BalanceCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            // Amount
            Text(formatCurrency(amount))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            // Title
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 2)
        )
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - Individual Balance Row (Sprint 4)

/// Row displaying balance with a specific friend/member
struct IndividualBalanceRow: View {
    let friendID: String
    let balance: Double
    let friendName: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(balanceColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text(friendName.prefix(1).uppercased())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(balanceColor)
            }
            
            // Friend name
            Text(friendName)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            // Balance amount and status
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(balance))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(balanceColor)
                
                Text(balanceStatusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var balanceColor: Color {
        if balance > 0 {
            return .green  // They owe you
        } else if balance < 0 {
            return .orange  // You owe them
        } else {
            return .gray   // Settled
        }
    }
    
    private var balanceStatusText: String {
        if balance > 0 {
            return "owes you"
        } else if balance < 0 {
            return "you owe"
        } else {
            return "settled"
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: abs(value))) ?? "$0.00"
    }
}

=======
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
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

