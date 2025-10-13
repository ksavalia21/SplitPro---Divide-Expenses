//
//  AppRouterView.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/13/25.
//

import SwiftUI

/// AppRouterView: The main routing controller for the application
///
/// This view acts as the "traffic controller" for the entire app, deciding which
/// screen to display based on the current authentication state. It implements
/// conditional routing logic based on three possible states:
///
/// 1. Loading State (isLoading = true):
///    - Displayed when the app is first launched
///    - Shows a loading indicator while Firebase checks for existing authentication
///
/// 2. Unauthenticated State (isAuthenticated = false):
///    - Displayed when no user is signed in
///    - Shows the SignInView with option to navigate to SignUpView
///
/// 3. Authenticated State (isAuthenticated = true):
///    - Displayed when a user is successfully signed in
///    - Shows the HomeView (main app content)
///
/// This architecture ensures:
/// - Clean separation of authenticated and unauthenticated flows
/// - Smooth transitions between states
/// - Centralized routing logic
struct AppRouterView: View {
    
    // MARK: - Environment Objects
    
    /// Access to the authentication manager to determine which view to show
    /// This is injected via the environment from the App struct
    @EnvironmentObject var authManager: AuthenticationManager
    
    // MARK: - Body
    
    var body: some View {
        // Use conditional logic to determine which view to display
        // ZStack with alignment allows us to return different view types
        ZStack {
            if authManager.isLoading {
                // State 1: Still determining authentication state
                // Show a loading screen while Firebase checks for existing sessions
                LoadingView()
                
            } else if authManager.isAuthenticated {
                // State 2: User is authenticated
                // Show the main app content (HomeView)
                HomeView()
                
            } else {
                // State 3: User is not authenticated
                // Show the sign-in screen
                SignInView()
            }
        }
        // Animate transitions between different authentication states
        // This provides a smooth user experience when logging in/out
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authManager.isLoading)
    }
}

// MARK: - Preview

#Preview("Loading State") {
    let authManager = AuthenticationManager()
    authManager.isLoading = true
    
    return AppRouterView()
        .environmentObject(authManager)
}

#Preview("Unauthenticated State") {
    let authManager = AuthenticationManager()
    authManager.isLoading = false
    authManager.isAuthenticated = false
    
    return AppRouterView()
        .environmentObject(authManager)
}

#Preview("Authenticated State") {
    let authManager = AuthenticationManager()
    authManager.isLoading = false
    authManager.isAuthenticated = true
    authManager.currentUserUID = "preview-user-id"
    
    return AppRouterView()
        .environmentObject(authManager)
}

