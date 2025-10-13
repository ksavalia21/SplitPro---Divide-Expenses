//
//  RecordSettlementView.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/17/25.
//  Sprint 4: Settlement Recording Interface
//

import SwiftUI

/// RecordSettlementView: Interface for recording a debt settlement/payment
///
/// This view allows users to:
/// - Select which friend/member they are settling up with
/// - Enter the amount being paid
/// - Add an optional note about the payment
/// - Record the settlement to reduce debt
///
/// **Use Cases:**
/// - User owes money to a friend and wants to record a payment
/// - User received cash/Venmo and wants to log it in the app
/// - Settling up after a trip or shared expenses
///
/// **How It Works:**
/// - Settlement is stored as a special expense in Firestore
/// - Balance calculation automatically incorporates settlements
/// - Reduces or eliminates debt between the two users
struct RecordSettlementView: View {
    
    // MARK: - Properties
    
    /// The group this settlement is for
    let group: Group
    
    /// Array of member User objects
    let members: [User]
    
    // MARK: - Environment Objects
    
    /// Access to authentication manager for current user info
    @EnvironmentObject var authManager: AuthenticationManager
    
    /// Environment variable to dismiss this view
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State Properties
    
    /// ID of the member the user is settling up with
    @State private var selectedMemberID: String = ""
    
    /// Amount being settled
    @State private var amount: String = ""
    
    /// Optional note about the settlement
    @State private var note: String = ""
    
    /// Who is paying: true = current user paying, false = current user receiving
    @State private var currentUserIsPaying: Bool = true
    
    /// Indicates if saving is in progress
    @State private var isSaving: Bool = false
    
    /// Error message to display
    @State private var errorMessage: String? = nil
    
    // MARK: - Computed Properties
    
    /// True if all required fields are filled
    private var isFormValid: Bool {
        !selectedMemberID.isEmpty &&
        !amount.isEmpty &&
        Double(amount) != nil &&
        (Double(amount) ?? 0) > 0
    }
    
    /// Selected member's User object
    private var selectedMember: User? {
        members.first(where: { $0.id == selectedMemberID })
    }
    
    /// Formatted amount for display
    private var formattedAmount: String {
        guard let amountValue = Double(amount) else { return "$0.00" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amountValue)) ?? "$0.00"
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // Who section
                whoSection
                
                // Amount section
                amountSection
                
                // Direction section
                directionSection
                
                // Note section
                noteSection
                
                // Summary section
                summarySection
                
                // Error message (if any)
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Settle Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Record") {
                        recordSettlement()
                    }
                    .disabled(!isFormValid || isSaving)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Pre-select first member if available
                if selectedMemberID.isEmpty, let firstMember = selectableMembers.first {
                    selectedMemberID = firstMember.id
                }
            }
        }
    }
    
    // MARK: - Form Sections
    
    /// Section for selecting who to settle with
    private var whoSection: some View {
        Section {
            Picker("Settle with", selection: $selectedMemberID) {
                ForEach(selectableMembers) { member in
                    Text(member.displayName)
                        .tag(member.id)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("Who")
        } footer: {
            Text("Select the person you're settling up with")
        }
    }
    
    /// Section for entering amount
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
        } footer: {
            Text("Enter the amount being paid")
        }
    }
    
    /// Section for selecting payment direction
    private var directionSection: some View {
        Section {
            Picker("Direction", selection: $currentUserIsPaying) {
                Text("I am paying").tag(true)
                Text("I am receiving").tag(false)
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Payment Direction")
        } footer: {
            if currentUserIsPaying {
                Text("You are paying \(selectedMember?.displayName ?? "them") to reduce your debt")
            } else {
                Text("\(selectedMember?.displayName ?? "They") paid you to reduce their debt")
            }
        }
    }
    
    /// Section for optional note
    private var noteSection: some View {
        Section {
            TextField("e.g., Cash payment, Venmo transfer", text: $note)
        } header: {
            Text("Note (Optional)")
        } footer: {
            Text("Add a note about how the payment was made")
        }
    }
    
    /// Summary section showing what will be recorded
    private var summarySection: some View {
        Section {
            VStack(spacing: 12) {
                // Payment summary
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if currentUserIsPaying {
                            Text("You pay \(selectedMember?.displayName ?? "them")")
                                .fontWeight(.semibold)
                        } else {
                            Text("\(selectedMember?.displayName ?? "They") pay you")
                                .fontWeight(.semibold)
                        }
                        
                        Text(formattedAmount)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                // Effect on balance
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Effect on Balance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if currentUserIsPaying {
                            Text("Your debt reduced by \(formattedAmount)")
                                .font(.caption)
                        } else {
                            Text("Their debt reduced by \(formattedAmount)")
                                .font(.caption)
                        }
                    }
                    
                    Spacer()
                }
            }
        } header: {
            Text("Summary")
        }
    }
    
    // MARK: - Computed Properties
    
    /// Members that can be selected (excluding current user)
    private var selectableMembers: [User] {
        guard let currentUserID = authManager.currentUserUID else { return members }
        return members.filter { $0.id != currentUserID }
    }
    
    // MARK: - Helper Methods
    
    /// Records the settlement to Firestore
    private func recordSettlement() {
        guard let amountValue = Double(amount) else {
            errorMessage = "Please enter a valid amount"
            return
        }
        
        guard amountValue > 0 else {
            errorMessage = "Amount must be greater than 0"
            return
        }
        
        guard let currentUserID = authManager.currentUserUID else {
            errorMessage = "User not authenticated"
            return
        }
        
        guard !selectedMemberID.isEmpty else {
            errorMessage = "Please select who you're settling with"
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        Task {
            do {
                // Determine payer and recipient based on direction
                let payerID: String
                let recipientID: String
                
                if currentUserIsPaying {
                    payerID = currentUserID
                    recipientID = selectedMemberID
                } else {
                    payerID = selectedMemberID
                    recipientID = currentUserID
                }
                
                // Create settlement object
                let settlement = Settlement(
                    payerID: payerID,
                    recipientID: recipientID,
                    amount: amountValue,
                    groupID: group.id,
                    date: Date(),
                    note: note.isEmpty ? nil : note
                )
                
                // Record settlement to Firestore
                try await FirestoreService.recordSettlement(
                    settlement: settlement,
                    groupID: group.id
                )
                
                print("✅ Settlement recorded successfully")
                
                // Trigger balance recalculation
                await authManager.recalculateGlobalBalances()
                
                // Dismiss the view
                dismiss()
                
            } catch {
                errorMessage = "Failed to record settlement: \(error.localizedDescription)"
                isSaving = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let authManager = AuthenticationManager()
    authManager.currentUserUID = "user-1"
    
    return RecordSettlementView(
        group: Group.sample,
        members: User.sampleArray
    )
    .environmentObject(authManager)
}


