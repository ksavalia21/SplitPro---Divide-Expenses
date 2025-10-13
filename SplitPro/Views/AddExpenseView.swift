//
//  AddExpenseView.swift
//  SplitPro
//
//  Created by Keyur Savalia on 10/13/25.
//  Updated for Sprint 3: Advanced Splitting and Receipt Attachments
//

import SwiftUI

/// AddExpenseView: Interface for adding a new group expense with flexible split options
///
/// This view allows users to:
/// - Enter expense description
/// - Enter total amount
/// - Select who paid
/// - Choose split type (equal, exact amounts, or percentages)
/// - Configure splits based on selected type
/// - Attach receipt images (mock implementation)
///
/// Split Types:
/// - **Equal**: Total amount divided equally among all members
/// - **Exact Amounts**: User specifies exact dollar amount each member owes
/// - **Percentages**: User specifies percentage of total each member owes (must sum to 100%)
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
    @State private var paidByID: String = ""
    
    /// Selected split type
    @State private var selectedSplitType: SplitType = .equal
    
    /// Dictionary mapping member UID to exact amount they owe (for exactAmounts split)
    @State private var exactAmounts: [String: String] = [:]
    
    /// Dictionary mapping member UID to percentage they owe (for percentages split)
    @State private var percentages: [String: String] = [:]
    
    /// Mock state for receipt attachment
    @State private var hasAttachedReceipt: Bool = false
    
    /// Indicates if saving is in progress
    @State private var isSaving: Bool = false
    
    /// Error message to display
    @State private var errorMessage: String? = nil
    
    // MARK: - Initialization
    
    /// Initializer with group and members
    init(group: Group, members: [User]) {
        self.group = group
        self.members = members
        _paidByID = State(initialValue: "")
    }
    
    // MARK: - Computed Properties
    
    /// True if all required fields are filled and valid
    private var isFormValid: Bool {
        guard !description.isEmpty,
              !totalAmount.isEmpty,
              let _ = Double(totalAmount),
              !paidByID.isEmpty else {
            return false
        }
        
        // Additional validation based on split type
        switch selectedSplitType {
        case .equal:
            return true
        case .exactAmounts:
            return validateExactAmounts()
        case .percentages:
            return validatePercentages()
        }
    }
    
    /// Calculated amount per person (equal split)
    private var perPersonAmount: Double {
        guard let total = Double(totalAmount), total > 0 else { return 0 }
        return total / Double(members.count)
    }
    
    /// Total of all exact amounts entered
    private var totalExactAmounts: Double {
        var total = 0.0
        for member in members {
            if let amountStr = exactAmounts[member.id],
               let amount = Double(amountStr) {
                total += amount
            }
        }
        return total
    }
    
    /// Remaining amount to be allocated (for exact amounts)
    private var remainingToAllocate: Double {
        guard let total = Double(totalAmount) else { return 0 }
        return total - totalExactAmounts
    }
    
    /// Total of all percentages entered
    private var totalPercentages: Double {
        var total = 0.0
        for member in members {
            if let percentStr = percentages[member.id],
               let percent = Double(percentStr) {
                total += percent
            }
        }
        return total
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
                
                // Split type picker
                splitTypeSection
                
                // Dynamic split configuration based on selected type
                splitConfigurationSection
                
                // Receipt attachment
                receiptSection
                
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
                setupInitialState()
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
    
    /// Section for selecting split type
    private var splitTypeSection: some View {
        Section {
            Picker("Split Type", selection: $selectedSplitType) {
                ForEach([SplitType.equal, SplitType.exactAmounts, SplitType.percentages], id: \.self) { type in
                    HStack {
                        Image(systemName: type.iconName)
                        Text(type.displayName)
                    }
                    .tag(type)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedSplitType) { oldValue, newValue in
                // Clear error when split type changes
                errorMessage = nil
            }
        } header: {
            Text("How should this be split?")
        } footer: {
            Text(splitTypeFooterText)
        }
    }
    
    /// Dynamic split configuration section based on selected type
    private var splitConfigurationSection: some View {
        Section {
            switch selectedSplitType {
            case .equal:
                equalSplitView
            case .exactAmounts:
                exactAmountsSplitView
            case .percentages:
                percentagesSplitView
            }
        } header: {
            Text("Split Configuration")
        }
    }
    
    /// Receipt attachment section
    private var receiptSection: some View {
        Section {
            Button(action: {
                // Mock receipt attachment - just toggle the flag
                hasAttachedReceipt.toggle()
            }) {
                HStack {
                    Image(systemName: hasAttachedReceipt ? "checkmark.circle.fill" : "camera.circle")
                        .font(.title2)
                        .foregroundColor(hasAttachedReceipt ? .green : .blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hasAttachedReceipt ? "Receipt Attached" : "Attach Receipt")
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(hasAttachedReceipt ? "Tap to remove" : "Optional: Add a photo of the receipt")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        } header: {
            Text("Receipt")
        } footer: {
            Text("📸 Mock implementation: Tapping simulates receipt attachment. In production, this would use the camera or photo library.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Split Configuration Views
    
    /// Equal split display view
    private var equalSplitView: some View {
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
                Text(formatCurrency(perPersonAmount))
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
                            Text("Paid \(formatCurrency(perPersonAmount))")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Text("Owes \(formatCurrency(perPersonAmount))")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
    }
    
    /// Exact amounts split configuration view
    private var exactAmountsSplitView: some View {
        VStack(spacing: 12) {
            // Instructions
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.blue)
                Text("Exact Amounts")
                    .fontWeight(.medium)
                Spacer()
            }
            
            Divider()
            
            // Live calculation labels
            VStack(spacing: 8) {
                HStack {
                    Text("Total Owed:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatCurrency(totalExactAmounts))
                        .fontWeight(.semibold)
                        .foregroundColor(totalExactAmounts == (Double(totalAmount) ?? 0) ? .green : .orange)
                }
                
                HStack {
                    Text("Remaining to Split:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatCurrency(remainingToAllocate))
                        .fontWeight(.semibold)
                        .foregroundColor(abs(remainingToAllocate) < 0.01 ? .green : .red)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Divider()
            
            // Member amount input fields
            VStack(alignment: .leading, spacing: 12) {
                Text("Enter amount owed by each member:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(members) { member in
                    HStack {
                        Text(memberDisplayName(member))
                            .font(.subheadline)
                            .frame(width: 120, alignment: .leading)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("$")
                                .foregroundColor(.secondary)
                            
                            TextField("0.00", text: Binding(
                                get: { exactAmounts[member.id] ?? "" },
                                set: { exactAmounts[member.id] = $0 }
                            ))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .textFieldStyle(.roundedBorder)
                        }
                    }
                }
            }
            
            // Validation message
            if !validateExactAmounts() && totalExactAmounts > 0 {
                Text("⚠️ Total amounts must equal \(formatCurrency(Double(totalAmount) ?? 0))")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
    }
    
    /// Percentages split configuration view
    private var percentagesSplitView: some View {
        VStack(spacing: 12) {
            // Instructions
            HStack {
                Image(systemName: "percent")
                    .foregroundColor(.blue)
                Text("By Percentages")
                    .fontWeight(.medium)
                Spacer()
            }
            
            Divider()
            
            // Live calculation label
            HStack {
                Text("Total Percentage:")
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.1f%%", totalPercentages))
                    .fontWeight(.semibold)
                    .foregroundColor(abs(totalPercentages - 100.0) < 0.1 ? .green : .red)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Divider()
            
            // Member percentage input fields
            VStack(alignment: .leading, spacing: 12) {
                Text("Enter percentage owed by each member:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(members) { member in
                    HStack {
                        Text(memberDisplayName(member))
                            .font(.subheadline)
                            .frame(width: 120, alignment: .leading)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            TextField("0.0", text: Binding(
                                get: { percentages[member.id] ?? "" },
                                set: { percentages[member.id] = $0 }
                            ))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                            
                            Text("%")
                                .foregroundColor(.secondary)
                        }
                        
                        // Show calculated dollar amount
                        if let percentStr = percentages[member.id],
                           let percent = Double(percentStr),
                           let total = Double(totalAmount) {
                            Text("= \(formatCurrency(total * percent / 100.0))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 70, alignment: .trailing)
                        }
                    }
                }
            }
            
            // Validation message
            if !validatePercentages() && totalPercentages > 0 {
                Text("⚠️ Total percentages must equal 100%")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Sets up initial state when view appears
    private func setupInitialState() {
        // Set default payer to current user
        if let currentUserID = authManager.currentUserUID,
           members.contains(where: { $0.id == currentUserID }) {
            paidByID = currentUserID
        } else if let firstMember = members.first {
            paidByID = firstMember.id
        }
        
        // Initialize exact amounts and percentages dictionaries
        for member in members {
            exactAmounts[member.id] = ""
            percentages[member.id] = ""
        }
    }
    
    /// Returns display name with (You) indicator if applicable
    private func memberDisplayName(_ member: User) -> String {
        if member.id == authManager.currentUserUID {
            return "\(member.displayName) (You)"
        } else {
            return member.displayName
        }
    }
    
    /// Returns footer text for split type section
    private var splitTypeFooterText: String {
        switch selectedSplitType {
        case .equal:
            return "Total divided equally among all members"
        case .exactAmounts:
            return "Specify exact dollar amounts for each member"
        case .percentages:
            return "Specify percentage of total for each member"
        }
    }
    
    /// Validates exact amounts split
    private func validateExactAmounts() -> Bool {
        guard let total = Double(totalAmount) else { return false }
        
        // Check that all members have valid amounts entered
        var sum = 0.0
        for member in members {
            guard let amountStr = exactAmounts[member.id],
                  !amountStr.isEmpty,
                  let amount = Double(amountStr),
                  amount >= 0 else {
                return false
            }
            sum += amount
        }
        
        // Check that sum equals total (with small tolerance for floating point)
        return abs(sum - total) < 0.01
    }
    
    /// Validates percentages split
    private func validatePercentages() -> Bool {
        // Check that all members have valid percentages entered
        var sum = 0.0
        for member in members {
            guard let percentStr = percentages[member.id],
                  !percentStr.isEmpty,
                  let percent = Double(percentStr),
                  percent >= 0 && percent <= 100 else {
                return false
            }
            sum += percent
        }
        
        // Check that sum equals 100% (with small tolerance)
        return abs(sum - 100.0) < 0.1
    }
    
    /// Formats a double value as currency
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
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
        
        // Additional validation based on split type
        switch selectedSplitType {
        case .equal:
            break // No additional validation needed
        case .exactAmounts:
            if !validateExactAmounts() {
                errorMessage = "Exact amounts must sum to total amount"
                return
            }
        case .percentages:
            if !validatePercentages() {
                errorMessage = "Percentages must sum to 100%"
                return
            }
        }
        
        isSaving = true
        errorMessage = nil
        
        Task {
            do {
                // Calculate memberOwed dictionary based on split type
                var memberOwed: [String: Double] = [:]
                
                switch selectedSplitType {
                case .equal:
                    let perPerson = amountValue / Double(members.count)
                    for member in members {
                        if member.id == paidByID {
                            memberOwed[member.id] = 0.0
                        } else {
                            memberOwed[member.id] = perPerson
                        }
                    }
                    
                case .exactAmounts:
                    for member in members {
                        if member.id == paidByID {
                            memberOwed[member.id] = 0.0
                        } else if let amountStr = exactAmounts[member.id],
                                  let amount = Double(amountStr) {
                            memberOwed[member.id] = amount
                        }
                    }
                    
                case .percentages:
                    for member in members {
                        if member.id == paidByID {
                            memberOwed[member.id] = 0.0
                        } else if let percentStr = percentages[member.id],
                                  let percent = Double(percentStr) {
                            memberOwed[member.id] = amountValue * percent / 100.0
                        }
                    }
                }
                
                // Handle receipt upload (mock)
                var receiptURL: String? = nil
                if hasAttachedReceipt {
                    let expenseID = UUID().uuidString
                    let mockImageData = Data() // Mock image data
                    receiptURL = await FirestoreService.uploadReceipt(
                        imageData: mockImageData,
                        groupID: group.id,
                        expenseID: expenseID
                    )
                }
                
                // Create the expense object
                let expense = GroupExpense(
                    groupID: group.id,
                    description: description,
                    totalAmount: amountValue,
                    paidByID: paidByID,
                    splitType: selectedSplitType,
                    memberOwed: memberOwed,
                    date: Date(),
                    receiptURL: receiptURL
                )
                
                // Save to Firestore
                try await FirestoreService.logGroupExpense(
                    expense: expense,
                    groupID: group.id
                )
                
                print("✅ Group expense saved successfully")
                
                // Dismiss the view
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
