//
//  LogIOUView.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/13/25.
//

import SwiftUI

/// LogIOUView: Interface for creating a new private expense (IOU) between two people
///
/// This view allows the current user to record a debt/IOU with a friend.
/// The user specifies:
/// - Who is involved (which friend)
/// - Who paid (direction of debt)
/// - How much
/// - What it was for
///
/// Example scenarios:
/// 1. "I paid $20 for Bob's lunch" → Bob owes me $20
/// 2. "Alice paid $15 for my coffee" → I owe Alice $15
struct LogIOUView: View {
    
    // MARK: - Environment Objects
    
    /// Access to authentication manager for current user and friends
    @EnvironmentObject var authManager: AuthenticationManager
    
    /// Environment variable to dismiss this view
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State Properties
    
    /// The friend involved in this IOU
    @State private var selectedFriend: User? = nil
    
    /// Who paid: true = current user paid, false = friend paid
    @State private var currentUserPaid: Bool = true
    
    /// Amount of the expense
    @State private var amount: String = ""
    
    /// Description of what the expense was for
    @State private var description: String = ""
    
    /// Optional additional note
    @State private var note: String = ""
    
    /// Indicates if saving is in progress
    @State private var isSaving: Bool = false
    
    /// Error message to display
    @State private var errorMessage: String? = nil
    
    /// Shows friend picker sheet
    @State private var showingFriendPicker: Bool = false
    
    // MARK: - Computed Properties
    
    /// True if all required fields are filled
    private var isFormValid: Bool {
        selectedFriend != nil &&
        !amount.isEmpty &&
        Double(amount) != nil &&
        !description.isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // Friend selection section
                friendSelectionSection
                
                // Payment direction section
                paymentDirectionSection
                
                // Amount section
                amountSection
                
                // Description section
                descriptionSection
                
                // Optional note section
                noteSection
                
                // Error message (if any)
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Log IOU")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveExpense()
                    }
                    .disabled(!isFormValid || isSaving)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingFriendPicker) {
                FriendPickerView(selectedFriend: $selectedFriend)
            }
        }
    }
    
    // MARK: - Form Sections
    
    /// Section for selecting which friend is involved
    private var friendSelectionSection: some View {
        Section {
            Button(action: {
                showingFriendPicker = true
            }) {
                HStack {
                    Text("Friend")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if let friend = selectedFriend {
                        Text(friend.displayName)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Select Friend")
                            .foregroundColor(.blue)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Who is involved?")
        }
    }
    
    /// Section for specifying who paid
    private var paymentDirectionSection: some View {
        Section {
            Picker("Who paid?", selection: $currentUserPaid) {
                Text("I paid").tag(true)
                Text("\(selectedFriend?.displayName ?? "Friend") paid").tag(false)
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Payment Direction")
        } footer: {
            if let friend = selectedFriend {
                if currentUserPaid {
                    Text("\(friend.displayName) will owe you money")
                        .foregroundColor(.green)
                } else {
                    Text("You will owe \(friend.displayName) money")
                        .foregroundColor(.orange)
                }
            }
        }
    }
    
    /// Section for entering the amount
    private var amountSection: some View {
        Section {
            HStack {
                Text("$")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                TextField("0.00", text: $amount)
                    .keyboardType(.decimalPad)
                    .font(.title3)
            }
        } header: {
            Text("Amount")
        }
    }
    
    /// Section for describing the expense
    private var descriptionSection: some View {
        Section {
            TextField("e.g., Lunch, Movie tickets, Groceries", text: $description)
        } header: {
            Text("What was this for?")
        }
    }
    
    /// Section for optional notes
    private var noteSection: some View {
        Section {
            TextField("Optional note", text: $note, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Text("Additional Note (Optional)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Saves the expense to Firestore
    private func saveExpense() {
        guard let friend = selectedFriend,
              let currentUserID = authManager.currentUserUID,
              let amountValue = Double(amount) else {
            errorMessage = "Please fill in all required fields"
            return
        }
        
        // Validate amount
        guard amountValue > 0 else {
            errorMessage = "Amount must be greater than 0"
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        Task {
            do {
                // Determine payer and recipient based on who paid
                let payerID = currentUserPaid ? currentUserID : friend.id
                let recipientID = currentUserPaid ? friend.id : currentUserID
                
                // Create the expense object
                let expense = PrivateExpense(
                    payerID: payerID,
                    recipientID: recipientID,
                    amount: amountValue,
                    description: description,
                    date: Date(),
                    note: note.isEmpty ? nil : note
                )
                
                // Save to Firestore (in current user's collection)
                try await FirestoreService.logPrivateExpense(
                    expense: expense,
                    userID: currentUserID
                )
                
                print("✅ IOU logged successfully")
                
                // Dismiss the view
                dismiss()
                
            } catch {
                errorMessage = "Failed to save: \(error.localizedDescription)"
                isSaving = false
            }
        }
    }
}

// MARK: - Friend Picker View

/// A simple picker sheet for selecting a friend from the list
struct FriendPickerView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @Binding var selectedFriend: User?
    
    var body: some View {
        NavigationStack {
            List(authManager.friends) { friend in
                Button(action: {
                    selectedFriend = friend
                    dismiss()
                }) {
                    HStack {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 40, height: 40)
                            
                            Text(friend.displayName.prefix(1).uppercased())
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        // Friend info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(friend.displayName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(friend.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Checkmark if selected
                        if selectedFriend?.id == friend.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let authManager = AuthenticationManager()
    authManager.currentUserUID = "current-user-123"
    authManager.friends = User.sampleArray
    
    return LogIOUView()
        .environmentObject(authManager)
}

