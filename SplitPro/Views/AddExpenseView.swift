//
//  AddExpenseView.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/13/25.
//

import SwiftUI

/// AddExpenseView: Interface for adding a new group expense with equal split
///
/// This view allows users to:
/// - Enter expense description
/// - Enter total amount
/// - Select who paid
/// - Automatically calculate equal split among all members
///
/// Split Logic (Equal):
/// - Total amount is divided equally among all group members
/// - The person who paid owes $0 (already paid their share)
/// - Everyone else owes their equal share to the payer
struct AddExpenseView: View {
    
    // MARK: - Properties
    
    /// The group this expense belongs to
    let group: Group
    
    /// Array of member User objects
    let members: [User]
    
    // MARK: - Environment Objects
    
    /// Access to authentication manager for current user info
    @EnvironmentObject var authManager: AuthenticationManager
    
    /// Environment variable to dismiss this view
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State Properties
    
    /// Description of the expense
    @State private var description: String = ""
    
    /// Total amount of the expense
    @State private var totalAmount: String = ""
    
    /// ID of the member who paid
    @State private var paidByID: String
    
    /// Indicates if saving is in progress
    @State private var isSaving: Bool = false
    
    /// Error message to display
    @State private var errorMessage: String? = nil
    
    // MARK: - Initialization
    
    /// Initializer with default payer as current user
    init(group: Group, members: [User]) {
        self.group = group
        self.members = members
        // Default payer to current user if they're in the group
        _paidByID = State(initialValue: "")
    }
    
    // MARK: - Computed Properties
    
    /// True if all required fields are filled
    private var isFormValid: Bool {
        !description.isEmpty &&
        !totalAmount.isEmpty &&
        Double(totalAmount) != nil &&
        !paidByID.isEmpty
    }
    
    /// Calculated amount per person (equal split)
    private var perPersonAmount: Double {
        guard let total = Double(totalAmount), total > 0 else { return 0 }
        return total / Double(members.count)
    }
    
    /// Formatted per-person amount
    private var formattedPerPerson: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: perPersonAmount)) ?? "$0.00"
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // Description section
                descriptionSection
                
                // Amount section
                amountSection
                
                // Paid by selector
                paidBySection
                
                // Split preview
                splitPreviewSection
                
                // Error message (if any)
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Add Expense")
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
            .onAppear {
                // Set default payer to current user
                if let currentUserID = authManager.currentUserUID,
                   members.contains(where: { $0.id == currentUserID }) {
                    paidByID = currentUserID
                } else if let firstMember = members.first {
                    paidByID = firstMember.id
                }
            }
        }
    }
    
    // MARK: - Form Sections
    
    /// Section for entering expense description
    private var descriptionSection: some View {
        Section {
            TextField("e.g., Dinner, Groceries, Rent", text: $description)
        } header: {
            Text("What was this expense for?")
        }
    }
    
    /// Section for entering total amount
    private var amountSection: some View {
        Section {
            HStack {
                Text("$")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                TextField("0.00", text: $totalAmount)
                    .keyboardType(.decimalPad)
                    .font(.title3)
            }
        } header: {
            Text("Total Amount")
        } footer: {
            Text("Enter the total amount that was paid")
        }
    }
    
    /// Section for selecting who paid
    private var paidBySection: some View {
        Section {
            Picker("Who paid?", selection: $paidByID) {
                ForEach(members) { member in
                    HStack {
                        Text(member.displayName)
                        if member.id == authManager.currentUserUID {
                            Text("(You)")
                                .foregroundColor(.blue)
                        }
                    }
                    .tag(member.id)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("Paid By")
        }
    }
    
    /// Section showing split preview
    private var splitPreviewSection: some View {
        Section {
            VStack(spacing: 12) {
                // Split type indicator
                HStack {
                    Image(systemName: "equal.circle.fill")
                        .foregroundColor(.blue)
                    Text("Split Equally")
                        .fontWeight(.medium)
                    Spacer()
                }
                
                Divider()
                
                // Per-person amount
                HStack {
                    Text("Amount per person:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formattedPerPerson)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                // Member breakdown
                VStack(alignment: .leading, spacing: 8) {
                    Text("Member Breakdown:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(members) { member in
                        HStack {
                            Text(memberDisplayName(member))
                                .font(.caption)
                            
                            Spacer()
                            
                            if member.id == paidByID {
                                Text("Paid \(formattedPerPerson)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Text("Owes \(formattedPerPerson)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        } header: {
            Text("Split Details")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Returns display name with (You) indicator if applicable
    private func memberDisplayName(_ member: User) -> String {
        if member.id == authManager.currentUserUID {
            return "\(member.displayName) (You)"
        } else {
            return member.displayName
        }
    }
    
    /// Saves the expense to Firestore
    private func saveExpense() {
        guard let amountValue = Double(totalAmount) else {
            errorMessage = "Please enter a valid amount"
            return
        }
        
        guard amountValue > 0 else {
            errorMessage = "Amount must be greater than 0"
            return
        }
        
        guard !description.isEmpty else {
            errorMessage = "Please enter a description"
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        Task {
            do {
                // Calculate equal split for each member
                let perPerson = amountValue / Double(members.count)
                
                // Build memberOwed dictionary
                var memberOwed: [String: Double] = [:]
                for member in members {
                    if member.id == paidByID {
                        // The person who paid owes 0 (they already paid their share)
                        memberOwed[member.id] = 0.0
                    } else {
                        // Everyone else owes their equal share
                        memberOwed[member.id] = perPerson
                    }
                }
                
                // Create the expense object
                let expense = GroupExpense(
                    groupID: group.id,
                    description: description,
                    totalAmount: amountValue,
                    paidByID: paidByID,
                    splitType: "equal",
                    memberOwed: memberOwed,
                    date: Date()
                )
                
                // Save to Firestore
                try await FirestoreService.logGroupExpense(
                    expense: expense,
                    groupID: group.id
                )
                
                print("✅ Group expense saved successfully")
                
                // Dismiss the view
                // The expense list will automatically update via the snapshot listener
                dismiss()
                
            } catch {
                errorMessage = "Failed to save expense: \(error.localizedDescription)"
                isSaving = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let authManager = AuthenticationManager()
    authManager.currentUserUID = "user-1"
    
    return AddExpenseView(
        group: Group.sample,
        members: User.sampleArray
    )
    .environmentObject(authManager)
}

