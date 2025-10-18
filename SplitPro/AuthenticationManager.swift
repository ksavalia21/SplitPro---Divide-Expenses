//
//  AuthenticationManager.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/13/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

/// AuthenticationManager: A centralized class responsible for managing user authentication state
/// throughout the application. This class uses the ObservableObject protocol to allow SwiftUI views
/// to react to authentication state changes automatically.
///
/// Key Responsibilities:
/// - Monitor Firebase Authentication state changes
/// - Handle user sign-in and sign-up operations
/// - Manage user logout
/// - Maintain the current authentication state across the app
/// - Fetch and manage user profile data from Firestore
/// - Manage friend relationships
@MainActor
class AuthenticationManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Indicates whether the user is currently authenticated
    /// When true, the app displays authenticated screens (HomeView)
    /// When false, the app displays authentication screens (SignInView/SignUpView)
    @Published var isAuthenticated: Bool = false
    
    /// Indicates whether the authentication state is being determined
    /// Used to show a loading screen while checking if a user session exists
    @Published var isLoading: Bool = true
    
    /// Stores the current Firebase user's unique identifier (UID)
    /// This is nil when no user is authenticated
    @Published var currentUserUID: String? = nil
    
    /// Stores the current user's complete profile from Firestore
    /// This includes name, email, friend list, and other profile data
    /// Updated when user signs in or profile changes
    @Published var currentUserProfile: User? = nil
    
    /// Array of User objects representing the current user's friends
    /// Populated by fetching the full User data for each friend ID
    /// Updated when friends are added/removed or when user signs in
    @Published var friends: [User] = []
    
    /// Array of Group objects where the current user is a member
    /// Updated in real-time via Firestore snapshot listener
    /// Automatically refreshes when groups are created/modified
    @Published var activeGroups: [Group] = []
    
<<<<<<< HEAD
    /// Global net balance dictionary tracking balance with every friend/member
    /// Key: Friend/member UID
    /// Value: Net balance (positive = they owe you, negative = you owe them)
    ///
    /// This is recalculated whenever:
    /// - New expenses are added
    /// - Settlements are recorded
    /// - Groups are updated
    ///
    /// Example:
    /// ["bob-id": 50.0, "alice-id": -30.0] means:
    /// - Bob owes you $50
    /// - You owe Alice $30
    @Published var globalNetBalance: [String: Double] = [:]
    
    /// Total amount you are owed across all groups and IOUs
    @Published var totalOwedToYou: Double = 0.0
    
    /// Total amount you owe across all groups and IOUs
    @Published var totalYouOwe: Double = 0.0
    
=======
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
    /// Stores error messages to be displayed to the user
    /// This is cleared before each authentication operation
    @Published var errorMessage: String? = nil
    
    // MARK: - Private Properties
    
    /// Handle to the Firebase Auth state listener
    /// Stored so we can remove the listener when needed
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    /// Handle to the Firestore groups listener
    /// Stored so we can remove the listener when needed
    private var groupsListener: ListenerRegistration?
    
    // MARK: - Initialization
    
    /// Initializer: Sets up the authentication state listener
    /// This listener monitors Firebase Auth state changes and updates our properties accordingly
    init() {
        // Register a listener for authentication state changes
        // This will be called immediately with the current auth state, and then
        // whenever the auth state changes (login, logout, etc.)
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            Task {
                // Update authentication state based on whether a user exists
                self.isAuthenticated = user != nil
                self.currentUserUID = user?.uid
                
                // If user is authenticated, fetch their profile and friends
                if let user = user {
                    print("✅ User is authenticated with UID: \(user.uid)")
                    await self.loadUserProfile(uid: user.uid)
                } else {
                    print("❌ No authenticated user")
                    // Clear user data when logged out
                    self.currentUserProfile = nil
                    self.friends = []
                    self.activeGroups = []
<<<<<<< HEAD
                    self.globalNetBalance = [:]
                    self.totalOwedToYou = 0.0
                    self.totalYouOwe = 0.0
=======
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
                    
                    // Remove groups listener if it exists
                    self.groupsListener?.remove()
                    self.groupsListener = nil
                }
                
                // Loading is complete once we've determined the initial state
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Deinitialization
    
    /// Removes the authentication state listener when this object is deallocated
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        groupsListener?.remove()
    }
    
    // MARK: - Public Authentication Methods
    
    /// Signs in an existing user with email and password
    ///
    /// - Parameters:
    ///   - email: The user's email address
    ///   - password: The user's password
    ///
    /// This method uses Firebase Authentication to sign in the user.
    /// If successful, the authStateListener will automatically update isAuthenticated to true.
    /// If it fails, an error message is stored in errorMessage property.
    func signIn(email: String, password: String) async {
        // Clear any previous error messages
        errorMessage = nil
        
        // Validate input fields
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address"
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            return
        }
        
        do {
            // Attempt to sign in with Firebase Authentication
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            print("✅ Sign in successful for user: \(authResult.user.uid)")
            
            // Note: We don't manually set isAuthenticated here because
            // the authStateListener will automatically update it
            
        } catch let error as NSError {
            // Handle Firebase Authentication errors
            print("❌ Sign in failed: \(error.localizedDescription)")
            errorMessage = parseAuthError(error)
        }
    }
    
    /// Creates a new user account with email and password
    ///
    /// - Parameters:
    ///   - email: The desired email address for the new account
    ///   - password: The desired password for the new account
    ///   - name: Optional display name for the user
    ///
    /// This method uses Firebase Authentication to create a new user account.
    /// If successful, the user is automatically signed in and a Firestore profile is created.
    func signUp(email: String, password: String, name: String? = nil) async {
        // Clear any previous error messages
        errorMessage = nil
        
        // Validate input fields
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address"
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            return
        }
        
        // Validate password length (Firebase requires at least 6 characters)
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        do {
            // Attempt to create a new user account with Firebase Authentication
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            print("✅ Sign up successful for user: \(authResult.user.uid)")
            
            // Create the user's Firestore profile immediately after sign-up
            do {
                try await FirestoreService.createUserProfile(
                    id: authResult.user.uid,
                    email: email,
                    name: name
                )
                print("✅ Firestore profile created")
            } catch {
                print("⚠️ Failed to create Firestore profile: \(error.localizedDescription)")
                // Note: User is still signed in even if profile creation fails
                // The profile can be created later or manually
            }
            
            // Note: The user is automatically signed in after account creation
            // The authStateListener will automatically update isAuthenticated
            // and load the user profile
            
        } catch let error as NSError {
            // Handle Firebase Authentication errors
            print("❌ Sign up failed: \(error.localizedDescription)")
            errorMessage = parseAuthError(error)
        }
    }
    
    /// Signs out the current user
    ///
    /// This method signs out the user from Firebase Authentication.
    /// The authStateListener will automatically update isAuthenticated to false.
    func logOut() {
        do {
            // Sign out from Firebase Authentication
            try Auth.auth().signOut()
            print("✅ User signed out successfully")
            // Clear the current user data
            currentUserUID = nil
            currentUserProfile = nil
            friends = []
            activeGroups = []
<<<<<<< HEAD
            globalNetBalance = [:]
            totalOwedToYou = 0.0
            totalYouOwe = 0.0
=======
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
            
            // Remove groups listener
            groupsListener?.remove()
            groupsListener = nil
            
            // Note: The authStateListener will automatically update isAuthenticated
            
        } catch {
            // Handle sign out errors (rare, but possible)
            print("❌ Sign out failed: \(error.localizedDescription)")
            errorMessage = "Failed to sign out. Please try again."
        }
    }
    
    // MARK: - User Profile Methods
    
    /// Loads the user's profile from Firestore
    ///
    /// - Parameter uid: The Firebase UID of the user
    ///
    /// This is called automatically when a user signs in through the auth state listener.
<<<<<<< HEAD
    /// After loading the profile, it automatically fetches the user's friends and
    /// sets up real-time listeners for groups, which triggers balance calculation.
=======
    /// After loading the profile, it automatically fetches the user's friends.
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
    private func loadUserProfile(uid: String) async {
        do {
            // Fetch the user profile from Firestore
            let profile = try await FirestoreService.fetchUser(id: uid)
            self.currentUserProfile = profile
            print("✅ User profile loaded: \(profile.email)")
            
            // After profile is loaded, fetch friends
            await fetchFriends()
            
            // Set up real-time listener for groups
<<<<<<< HEAD
            // This will trigger balance calculation when groups are loaded
=======
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
            setupGroupsListener(uid: uid)
            
        } catch {
            print("❌ Failed to load user profile: \(error.localizedDescription)")
            // Profile might not exist yet (e.g., during initial sign-up)
            // This is okay, the profile will be created during sign-up process
        }
    }
    
    /// Fetches the complete User objects for all of the current user's friends
    ///
    /// This method reads the friendIDs from the current user's profile,
    /// then fetches the full User data for each friend from Firestore.
    ///
    /// Call this method whenever the friend list changes (add/remove friend)
    /// or when the user profile is first loaded.
    func fetchFriends() async {
        guard let profile = currentUserProfile else {
            print("⚠️ Cannot fetch friends: No user profile loaded")
            self.friends = []
            return
        }
        
        // If user has no friends, clear the array and return
        guard !profile.friendIDs.isEmpty else {
            print("ℹ️ User has no friends")
            self.friends = []
            return
        }
        
        print("🔄 Fetching \(profile.friendIDs.count) friends...")
        
        // Fetch all friends concurrently
        let fetchedFriends = await FirestoreService.fetchUsers(ids: profile.friendIDs)
        self.friends = fetchedFriends
        
        print("✅ Loaded \(friends.count) friends")
    }
    
    /// Refreshes the current user's profile from Firestore
    ///
    /// Call this after making changes to the user's profile to ensure
    /// the local data is in sync with Firestore.
    func refreshUserProfile() async {
        guard let uid = currentUserUID else { return }
        await loadUserProfile(uid: uid)
    }
    
    // MARK: - Group Management Methods
    
    /// Sets up a real-time listener for the user's groups
    ///
    /// This listener automatically updates the activeGroups array whenever:
    /// - A new group is created with the user as a member
    /// - A group the user is in is modified
    /// - A group the user was in is deleted
    ///
<<<<<<< HEAD
    /// After groups are updated, it triggers a balance recalculation.
    ///
=======
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
    /// - Parameter uid: The Firebase UID of the user
    private func setupGroupsListener(uid: String) {
        // Remove existing listener if any
        groupsListener?.remove()
        
        // Set up new listener
        groupsListener = FirestoreService.listenToUserGroups(userID: uid) { [weak self] groups in
            guard let self = self else { return }
            self.activeGroups = groups
            print("✅ Active groups updated: \(groups.count) groups")
<<<<<<< HEAD
            
            // Recalculate balances when groups change
            Task {
                await self.recalculateGlobalBalances()
            }
        }
    }
    
    // MARK: - Balance Calculation Methods
    
    /// Recalculates global net balances across all groups and private IOUs
    ///
    /// This function:
    /// 1. Fetches all expenses from all active groups
    /// 2. Fetches all private expenses
    /// 3. Uses BalanceCalculator to compute net balances
    /// 4. Updates published properties for UI
    ///
    /// Called automatically when:
    /// - Groups are updated
    /// - User signs in
    /// - (External: Should be called after adding expenses or settlements)
    func recalculateGlobalBalances() async {
        guard let currentUserID = currentUserUID else {
            print("⚠️ Cannot calculate balances: No current user")
            return
        }
        
        print("💰 Recalculating global balances...")
        
        // MARK: - Fetch all group expenses
        
        var groupExpenses: [String: [GroupExpense]] = [:]
        
        for group in activeGroups {
            do {
                let expenses = try await FirestoreService.fetchGroupExpenses(groupID: group.id)
                groupExpenses[group.id] = expenses
            } catch {
                print("⚠️ Failed to fetch expenses for group \(group.id): \(error)")
                groupExpenses[group.id] = []
            }
        }
        
        // MARK: - Fetch all private expenses
        
        var privateExpenses: [PrivateExpense] = []
        
        do {
            privateExpenses = try await FirestoreService.fetchPrivateExpenses(userID: currentUserID)
        } catch {
            print("⚠️ Failed to fetch private expenses: \(error)")
        }
        
        // MARK: - Calculate balances using BalanceCalculator
        
        let balances = BalanceCalculator.calculateAllBalances(
            currentUserID: currentUserID,
            groups: activeGroups,
            groupExpenses: groupExpenses,
            privateExpenses: privateExpenses
        )
        
        // MARK: - Update published properties
        
        self.globalNetBalance = balances
        self.totalOwedToYou = BalanceCalculator.totalOwedToUser(balances: balances)
        self.totalYouOwe = BalanceCalculator.totalUserOwes(balances: balances)
        
        print("✅ Global balances calculated")
        print("   Total owed to you: $\(totalOwedToYou)")
        print("   Total you owe: $\(totalYouOwe)")
    }
    
=======
        }
    }
    
>>>>>>> ad50dba30aad4e9f230e0c481146a6b1e65b8a18
    // MARK: - Private Helper Methods
    
    /// Converts Firebase Authentication error codes into user-friendly messages
    ///
    /// - Parameter error: The NSError from Firebase Authentication
    /// - Returns: A user-friendly error message string
    private func parseAuthError(_ error: NSError) -> String {
        // Check if this is a Firebase Auth error
        guard let errorCode = AuthErrorCode(rawValue: error.code) else {
            return "An unexpected error occurred. Please try again."
        }
        
        // Map Firebase error codes to user-friendly messages
        switch errorCode {
        case .invalidEmail:
            return "The email address is invalid. Please check and try again."
        case .wrongPassword:
            return "The password is incorrect. Please try again."
        case .userNotFound:
            return "No account found with this email. Please sign up."
        case .emailAlreadyInUse:
            return "This email is already in use. Please sign in or use a different email."
        case .weakPassword:
            return "The password is too weak. Please use a stronger password."
        case .networkError:
            return "Network error. Please check your internet connection."
        case .tooManyRequests:
            return "Too many failed attempts. Please try again later."
        default:
            return "Authentication failed: \(error.localizedDescription)"
        }
    }
}

