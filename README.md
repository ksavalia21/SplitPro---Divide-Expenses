# SplitPro - Expense Sharing & Bill Splitting App

<div align="center">
  <img src="https://img.shields.io/badge/Platform-iOS-blue.svg" alt="Platform: iOS">
  <img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/SwiftUI-5.0-blue.svg" alt="SwiftUI 5.0">
  <img src="https://img.shields.io/badge/Firebase-10.0+-yellow.svg" alt="Firebase 10.0+">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT">
</div>

## 📱 Overview

SplitPro is a modern iOS expense-sharing application built with SwiftUI and Firebase. It enables users to easily track shared expenses with friends and groups, calculate balances, and settle debts efficiently.

### ✨ Key Features

- **User Authentication** - Secure email/password authentication with Firebase Auth
- **Friend Management** - Add and manage friends for expense sharing
- **Private IOUs** - Track one-on-one debts between friends
- **Group Expenses** - Create groups and split expenses among multiple people
- **Advanced Splitting** - Equal, exact amounts, or percentage-based splits
- **Receipt Attachments** - Attach receipt images to expenses (mock implementation)
- **Settlement Tracking** - Record payments to settle debts
- **Debt Simplification** - Algorithm to minimize number of transactions
- **Global Dashboard** - Comprehensive financial overview across all groups
- **Real-time Updates** - Instant synchronization using Firestore snapshot listeners
- **Balance Tracking** - Visual balance displays with color-coded indicators
- **Clean UI/UX** - Modern, intuitive interface with smooth animations

---

## 🎯 Current Development Status

### ✅ Sprint 0: Foundation and Authentication (Completed)
- Firebase Authentication integration
- Email/password sign-in and sign-up
- Conditional routing based on auth state
- Session persistence
- Error handling and user feedback

### ✅ Sprint 1: User Profile and Private IOUs (Completed)
- User profile creation and management
- Friend search by email
- Two-way friend relationships
- Private expense (IOU) tracking between friends
- Balance calculation for friend pairs
- Firestore integration for data persistence

### ✅ Sprint 2: Core Group Management and Basic Expenses (Completed)
- Group creation with multiple members
- Member selection from friends list
- Equal split expense calculation
- Real-time group and expense updates
- Per-group balance tracking
- Expense history with member breakdown

### ✅ Sprint 3: Advanced Splitting and Real-Time Ledger (Completed)
- SplitType enum with three split methods (equal, exact amounts, percentages)
- Dynamic split configuration UI that adapts to selected type
- Exact amounts split with live validation (sum must equal total)
- Percentage split with live validation (must sum to 100%)
- Receipt attachment with mock Firebase Storage integration
- Enhanced expense rows showing split type and receipt indicators
- Real-time activity feed with newest expenses first

### ✅ Sprint 4: Settlement and Final Dashboard (Completed)
- Settlement model for recording debt payments
- Global balance aggregation across all groups and IOUs
- BalanceCalculator with debt simplification algorithm
- RecordSettlementView for logging settlements
- "Settle Up" button in group details
- Simplified payment suggestions (minimum transactions)
- Comprehensive global dashboard with "You Owe" and "You Are Owed" cards
- Individual balance breakdown by friend/member
- Real-time balance updates throughout the app

---

## 🏗️ Architecture

### Tech Stack
- **Frontend**: SwiftUI
- **Backend**: Firebase (Authentication, Firestore)
- **Language**: Swift 5.9
- **Minimum iOS**: iOS 17.0+
- **Architecture Pattern**: MVVM with centralized state management

### Project Structure
```
SplitPro/
├── SplitProApp.swift              # App entry point
├── AuthenticationManager.swift    # Centralized auth & state management
├── Models/
│   ├── User.swift                 # User profile data model
│   ├── PrivateExpense.swift       # 1-on-1 IOU model
│   ├── Group.swift                # Expense group model
│   ├── GroupExpense.swift         # Group expense model (with SplitType enum)
│   └── Settlement.swift           # Settlement/payment model
├── Services/
│   ├── FirestoreService.swift     # Firestore database operations
│   └── BalanceCalculator.swift    # Balance aggregation & debt simplification
└── Views/
    ├── AppRouterView.swift        # Authentication routing
    ├── LoadingView.swift          # Loading state screen
    ├── SignInView.swift           # User login
    ├── SignUpView.swift           # User registration
    ├── HomeView.swift             # Global dashboard with balance cards
    ├── FriendsView.swift          # Friends list
    ├── AddFriendView.swift        # Friend search and add
    ├── FriendDetailsView.swift    # Private IOU balance with friend
    ├── LogIOUView.swift           # Log private expense
    ├── GroupsView.swift           # Groups list
    ├── CreateGroupView.swift      # Group creation
    ├── GroupDetailsView.swift     # Group dashboard with simplified payments
    ├── AddExpenseView.swift       # Advanced expense logging (3 split types)
    └── RecordSettlementView.swift # Record debt settlement/payment
```

### Firestore Data Structure
```
artifacts/
  └── splitpro_main/
      ├── public/
      │   └── data/
      │       └── groups/
      │           └── {groupId}/
      │               ├── (group document)
      │               └── expenses/
      │                   └── {expenseId}
      └── users/
          └── {userId}/
              ├── user_data/
              │   └── profile
              └── private_expenses/
                  └── {expenseId}
```

---

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0 or later
- macOS 14.0 (Sonoma) or later
- iOS 17.0+ simulator or device
- Firebase account (free tier works)
- CocoaPods or Swift Package Manager

### Firebase Setup

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project named "SplitPro"
   - Enable Google Analytics (optional)

2. **Add iOS App to Firebase**
   - Click iOS icon in Firebase Console
   - Enter your Bundle ID (found in Xcode project settings)
   - Download `GoogleService-Info.plist`
   - Add the file to your Xcode project (make sure to check "Copy items if needed")

3. **Install Firebase SDK**
   - In Xcode: File → Add Package Dependencies
   - Add: `https://github.com/firebase/firebase-ios-sdk`
   - Select packages:
     - ✅ FirebaseAuth
     - ✅ FirebaseCore
     - ✅ FirebaseFirestore
     - ✅ FirebaseFirestoreSwift

4. **Enable Authentication**
   - Firebase Console → Authentication → Get Started
   - Enable "Email/Password" sign-in method

5. **Enable Firestore Database**
   - Firebase Console → Firestore Database → Create Database
   - Start in **test mode** (update security rules later)
   - Choose a location (cannot be changed later)

6. **Update Firestore Security Rules**
   - Go to Firestore Database → Rules tab
   - Copy the security rules from `Documentation/firestore.rules`
   - Publish the updated rules

7. **Create Required Indexes**
   - When you first run the app, Firestore will provide links to create indexes
   - Click the links and create the required composite indexes
   - Wait 2-3 minutes for indexes to build

### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/SplitPro.git
   cd SplitPro
   ```

2. **Open in Xcode**
   ```bash
   open SplitPro.xcodeproj
   ```

3. **Add Firebase Configuration**
   - Add your `GoogleService-Info.plist` to the project
   - Ensure it's added to the SplitPro target

4. **Build and Run**
   - Select a simulator (iPhone 15 Pro recommended)
   - Press `⌘ + R` to build and run

---

## 📖 Usage

### First-Time Setup
1. Launch the app
2. Tap "Sign Up" to create an account
3. Enter email and password (minimum 6 characters)
4. Firestore profile is created automatically

### Adding Friends
1. Navigate to **Friends** tab
2. Tap the **+** icon
3. Search by friend's email address
4. Tap "Add Friend"
5. Both users will see each other in their friends list

### Creating a Group
1. Navigate to **Groups** tab
2. Tap **+** icon or "Create Your First Group"
3. Enter a group name
4. Select friends to add as members
5. Tap "Create"

### Logging a Group Expense
1. Open a group from the Groups list
2. Tap "Add Expense"
3. Enter description and amount
4. Select who paid
5. Choose split type:
   - **Equal**: Divides equally among all members
   - **Exact Amounts**: Enter specific dollar amounts for each member
   - **Percentages**: Enter percentage owed by each member (must sum to 100%)
6. (Optional) Attach a receipt
7. Review the split preview
8. Tap "Save"
9. Balance updates in real-time!

### Recording a Settlement
1. Open a group from the Groups list
2. Tap "Settle Up"
3. Select who you're settling with
4. Enter the amount
5. Choose direction (you pay or you receive)
6. (Optional) Add a note
7. Tap "Record"
8. Balances automatically update everywhere

### Viewing Global Dashboard
1. Navigate to **Dashboard** tab
2. View "You Owe" and "You Are Owed" summary cards
3. See net balance calculation
4. Scroll to "Individual Balances" for per-person breakdown
5. All data updates in real-time as expenses/settlements are added

### Logging a Private IOU
1. Navigate to **Friends** tab
2. Tap on a friend
3. Tap "Log IOU"
4. Select who paid and enter details
5. Balance updates automatically

---

## 🔐 Security

### Authentication
- Firebase Authentication with email/password
- Secure session management
- Automatic session persistence
- Password validation (minimum 6 characters)

### Firestore Security Rules
- User profiles: Read by all authenticated users, write by owner only
- Friend lists: Two-way updates with field-level validation
- Private expenses: Read/write by owner only
- Groups: Read by all, write by members only
- Group expenses: Read/write by group members only

### Data Privacy
- All data encrypted in transit (HTTPS/SSL)
- Firestore data encrypted at rest
- Email addresses stored in lowercase for consistency
- No sensitive data logged to console in production

---

## 🧪 Testing

### Test Accounts
Create multiple test accounts to test friend and group features:
```
alice@test.com / password123
bob@test.com / password123
charlie@test.com / password123
```

### Testing Scenarios

**Scenario 1: Friend Relationship**
1. Create two accounts (Alice and Bob)
2. From Alice's account, add Bob as friend
3. Sign in as Bob, verify Alice appears in friends list
4. Test two-way relationship works

**Scenario 2: Split Calculation**
1. Create a group with 3 members (Alice, Bob, Charlie)
2. Test Equal Split:
   - Alice pays $60 for dinner, split equally
   - Verify each owes $20, Alice's balance is +$40
3. Test Exact Amounts:
   - Bob pays $60, Alice owes $30, Charlie owes $30
   - Verify validation prevents saving if amounts don't sum to total
4. Test Percentages:
   - Charlie pays $100, Alice 50%, Bob 30%, Charlie 20%
   - Verify validation prevents saving if percentages don't sum to 100%
5. Check dashboard shows correct total balances

**Scenario 3: Real-Time Updates**
1. Sign in as User A on one device
2. Sign in as User B on another device
3. User A adds an expense to shared group
4. Verify User B sees the update instantly
5. User B records a settlement
6. Verify User A's dashboard updates immediately

**Scenario 4: Debt Simplification**
1. Create a group with 4 members
2. Add multiple expenses with different payers
3. Open group details
4. Scroll to "Simplified Payments" section
5. Verify it shows minimum number of transactions
6. Check that complex multi-party debts are simplified

**Scenario 5: Settlement and Balance**
1. Note your balance with a friend in the dashboard
2. Record a settlement payment
3. Verify dashboard balance decreases
4. Check group's simplified payments update
5. Confirm all balances recalculate correctly

---

## 🎨 Design Principles

### User Experience
- **Intuitive Navigation**: Tab-based interface for main features
- **Visual Feedback**: Color-coded balances (green = owed, orange = owes, gray = settled)
- **Real-Time Updates**: Instant synchronization using Firestore listeners
- **Error Handling**: User-friendly error messages
- **Loading States**: Clear loading indicators during async operations

### Code Quality
- **Well-Commented**: Comprehensive inline documentation
- **MARK Comments**: Clear section organization
- **Type Safety**: Strong typing with Swift
- **Error Handling**: Try-catch blocks with proper error propagation
- **Async/Await**: Modern Swift concurrency
- **MVVM Pattern**: Separation of concerns

---

## 🛣️ Roadmap

### Completed Sprints
- [x] **Sprint 0**: Foundation and Authentication
- [x] **Sprint 1**: User Profile and Private IOUs
- [x] **Sprint 2**: Core Group Management and Basic Expenses
- [x] **Sprint 3**: Advanced Splitting and Real-Time Ledger
- [x] **Sprint 4**: Settlement and Final Dashboard

### Planned Features
- [ ] **Sprint 5**: Expense categories and filtering
- [ ] **Sprint 6**: Real receipt scanning with Firebase Storage
- [ ] **Sprint 7**: Payment integration (Venmo, PayPal, etc.)
- [ ] **Sprint 8**: Push notifications for new expenses
- [ ] **Sprint 9**: Export and reporting (PDF, CSV)
- [ ] **Sprint 10**: Multi-currency support

### Future Enhancements
- Dark mode support
- iPad optimization
- Expense editing and deletion
- Group settings (rename, remove members)
- Advanced filtering and search
- Data export to CSV/PDF
- Profile customization with avatars
- Expense templates
- Recurring expenses
- Split by shares (e.g., 2:1:1 ratio)
- Multi-currency with exchange rates
- Expense categories with icons
- Charts and analytics

---

## 📝 Known Issues

- Collection group indexes must be created manually on first run
- Email search is case-sensitive (emails stored in lowercase)
- No password reset functionality yet (planned for future sprint)
- No offline mode (requires internet connection)
- Receipt upload is mock implementation (actual Firebase Storage integration pending)
- Cannot edit or delete expenses after creation (planned for future sprint)

---

## 🤝 Contributing

This is currently a personal learning project. Contributions, issues, and feature requests are welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🙏 Acknowledgments

- Built as part of a structured sprint-based development process
- Uses Firebase for backend infrastructure
- SwiftUI for modern iOS development
- Inspired by apps like Splitwise and Settle Up

---

## 📞 Contact

**Developer**: Keyur Savalia

**Project Link**: [https://github.com/yourusername/SplitPro](https://github.com/yourusername/SplitPro)

---

## 📸 Screenshots

*(Add screenshots here once you have the app running)*

### Authentication
- Sign In Screen
- Sign Up Screen
- Loading Screen

### Main Features
- Dashboard
- Groups List
- Group Details with Balance
- Add Expense
- Friends List
- Private IOU Details

---

## 🔧 Troubleshooting

### Build Errors

**"Cannot find type 'ListenerRegistration'"**
- Solution: Add `import FirebaseFirestore` to AuthenticationManager.swift

**"Missing GoogleService-Info.plist"**
- Solution: Download from Firebase Console and add to project with "Copy items if needed" checked

**"Permission denied" in Firestore**
- Solution: Update Firestore security rules in Firebase Console

### Runtime Issues

**"No user found with email"**
- Solution: Ensure email is stored in lowercase in Firestore
- Check that collection group index is created

**"Missing index" error**
- Solution: Click the link in error message to create required index
- Wait 2-3 minutes for index to build

**App crashes on launch**
- Solution: Verify GoogleService-Info.plist is properly added
- Check Firebase configuration in console
- Clean build folder (⌘ + Shift + K) and rebuild

---

## 📚 Documentation

For detailed sprint documentation and implementation guides, see:
- **Sprint 0**: Foundation and Authentication
- **Sprint 1**: User Profile and Private IOUs  
- **Sprint 2**: Core Group Management and Basic Expenses
- **Sprint 3**: Advanced Splitting and Real-Time Ledger
- **Sprint 4**: Settlement and Final Dashboard

Each sprint includes:
- Detailed requirements
- Implementation steps
- Testing procedures
- Firebase setup instructions
- Code documentation
- Troubleshooting guides

---

**Last Updated**: October 18, 2025  
**Version**: 0.5.0 (Sprint 4 Complete)  
**Build Status**: ✅ Passing

