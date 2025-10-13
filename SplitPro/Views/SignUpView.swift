//
//  SignUpView.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/13/25.
//

import SwiftUI

/// SignUpView: The user interface for new users to create an account
///
/// This view provides a clean, modern interface with:
/// - Email and password input fields
/// - Password confirmation field
/// - Sign up button that triggers account creation
/// - Navigation back to sign in screen for existing users
/// - Error message display
struct SignUpView: View {
    
    // MARK: - Environment Objects
    
    /// Access to the authentication manager for handling sign-up operations
    @EnvironmentObject var authManager: AuthenticationManager
    
    /// Environment variable to dismiss this view
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State Properties
    
    /// User's email input
    @State private var email: String = ""
    
    /// User's password input
    @State private var password: String = ""
    
    /// User's password confirmation input
    @State private var confirmPassword: String = ""
    
    /// Indicates if a sign-up operation is in progress
    @State private var isSigningUp: Bool = false
    
    /// Local error message for password validation
    @State private var localError: String? = nil
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient for visual appeal
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top section with app branding
                    VStack(spacing: 16) {
                        // App icon
                        Image(systemName: "person.badge.plus.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white)
                        
                        // Title
                        Text("Create Account")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Subtitle
                        Text("Join SplitPro today")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                    
                    // Form section with white card background
                    VStack(spacing: 20) {
                        // Sign Up header
                        Text("Sign Up")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Email input field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                        }
                        
                        // Password input field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            SecureField("Create a password", text: $password)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .textInputAutocapitalization(.never)
                            
                            // Password requirements hint
                            Text("Minimum 6 characters")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Confirm password input field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            SecureField("Re-enter your password", text: $confirmPassword)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .textInputAutocapitalization(.never)
                        }
                        
                        // Error message display (if any)
                        if let errorMessage = localError ?? authManager.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // Sign Up button
                        Button(action: {
                            // Validate passwords match before attempting sign up
                            localError = nil
                            
                            guard password == confirmPassword else {
                                localError = "Passwords do not match"
                                return
                            }
                            
                            // Trigger sign-up operation
                            Task {
                                isSigningUp = true
                                await authManager.signUp(email: email, password: password)
                                isSigningUp = false
                            }
                        }) {
                            HStack {
                                if isSigningUp {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(isSigningUp ? "Creating Account..." : "Sign Up")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isSigningUp)
                        .padding(.top, 10)
                        
                        // Divider with "or" text
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            Text("or")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 10)
                        
                        // Navigate back to Sign In button
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Already have an account? **Sign In**")
                                .font(.subheadline)
                                .foregroundColor(.purple)
                        }
                    }
                    .padding(30)
                    .background(Color(.systemBackground))
                    .cornerRadius(30, corners: [.topLeft, .topRight])
                    
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SignUpView()
        .environmentObject(AuthenticationManager())
}

