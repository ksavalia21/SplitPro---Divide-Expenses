//
//  SplitProApp.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/12/25.
//

import SwiftUI
import SwiftData
import FirebaseCore

/// SplitProApp: The main entry point for the SplitPro application
///
/// This struct is marked with @main, making it the starting point of the app.
/// It handles:
/// - Firebase initialization
/// - Authentication state management
/// - SwiftData model container setup (for local data persistence)
/// - Injection of environment objects throughout the app
@main
struct SplitProApp: App {
    
    // MARK: - State Objects
    
    /// Initialize the AuthenticationManager as a StateObject
    /// StateObject ensures this instance persists for the lifetime of the app
    /// and all child views can access it via @EnvironmentObject
    @StateObject private var authManager = AuthenticationManager()
    
    // MARK: - SwiftData Container
    
    /// SwiftData model container for local data persistence
    /// This will be used in future sprints for storing expense data
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    // MARK: - Initialization
    
    /// Initializer: Configure Firebase before the app launches
    /// This is called once when the app starts
    init() {
        // Initialize Firebase with the configuration from GoogleService-Info.plist
        // This must be called before any Firebase services are used
        FirebaseApp.configure()
        print("✅ Firebase configured successfully")
    }

    // MARK: - App Body
    
    var body: some Scene {
        WindowGroup {
            // AppRouterView is the root view that handles navigation
            // based on authentication state
            AppRouterView()
                // Inject the AuthenticationManager into the environment
                // This makes it available to all child views via @EnvironmentObject
                .environmentObject(authManager)
        }
        // Provide the SwiftData model container to all views
        // This will be used in future sprints for data persistence
        .modelContainer(sharedModelContainer)
    }
}

/*
 ARCHITECTURE NOTES:
 
 The app uses a centralized routing architecture:
 
 SplitProApp (entry point)
    └── AppRouterView (routing logic)
         ├── LoadingView (shown while checking auth state)
         ├── SignInView (unauthenticated)
         │    └── SignUpView (sheet presentation)
         └── HomeView (authenticated)
 
 The AuthenticationManager is injected at the top level and flows down
 through the environment, allowing any view to access authentication
 state and functions without prop drilling.
 
 State Flow:
 1. App launches → Firebase initializes
 2. AuthenticationManager checks for existing session
 3. AppRouterView displays appropriate view based on auth state
 4. User interactions update AuthenticationManager
 5. UI automatically updates via @Published properties
 */
