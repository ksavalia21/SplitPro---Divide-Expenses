//
//  SignInView.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/13/25.
//

import SwiftUI

/// SignInView: The user interface for existing users to sign into their accounts
///
/// This view provides a clean, modern interface with:
/// - Email and password input fields
/// - Sign in button that triggers authentication
/// - Navigation to sign up screen for new users
/// - Error message display
struct SignInView: View {
    
    // MARK: - Environment Objects
    
    /// Access to the authentication manager for handling sign-in operations
    @EnvironmentObject var authManager: AuthenticationManager
    
    // MARK: - State Properties
    
    /// User's email input
    @State private var email: String = ""
    
    /// User's password input
    @State private var password: String = ""
    
    /// Controls whether to show the sign-up view
    @State private var showingSignUp: Bool = false
    
    /// Indicates if a sign-in operation is in progress
    @State private var isSigningIn: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient for visual appeal
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top section with app branding
                    VStack(spacing: 16) {
                        // App icon
                        Image(systemName: "dollarsign.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white)
                        
                        // App name
                        Text("SplitPro")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Tagline
                        Text("Split expenses with ease")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                    
                    // Form section with white card background
                    VStack(spacing: 20) {
                        // Sign In header
                        Text("Sign In")
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
                            
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .textInputAutocapitalization(.never)
                        }
                        
                        // Error message display (if any)
                        if let errorMessage = authManager.errorMessage {
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
                        
                        // Sign In button
                        Button(action: {
                            // Trigger sign-in operation
                            Task {
                                isSigningIn = true
                                await authManager.signIn(email: email, password: password)
                                isSigningIn = false
                            }
                        }) {
                            HStack {
                                if isSigningIn {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(isSigningIn ? "Signing In..." : "Sign In")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isSigningIn)
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
                        
                        // Navigate to Sign Up button
                        Button(action: {
                            showingSignUp = true
                        }) {
                            Text("Don't have an account? **Sign Up**")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(30)
                    .background(Color(.systemBackground))
                    .cornerRadius(30, corners: [.topLeft, .topRight])
                    
                    Spacer()
                }
            }
            // Navigation to SignUpView
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
        }
    }
}

// MARK: - Helper Extension for Rounded Corners

/// Extension to enable rounding specific corners of a view
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

/// Custom shape for rounding specific corners
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview {
    SignInView()
        .environmentObject(AuthenticationManager())
}

