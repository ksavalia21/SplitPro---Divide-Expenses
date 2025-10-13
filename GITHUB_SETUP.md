# GitHub Setup Guide

Follow these steps to push your SplitPro project to GitHub.

## ⚠️ IMPORTANT - Before You Start

**DO NOT commit your `GoogleService-Info.plist` file!** It contains sensitive Firebase configuration.

The `.gitignore` file is already configured to exclude it, but double-check:
```bash
cat .gitignore | grep GoogleService
```
You should see: `GoogleService-Info.plist`

---

## 📋 Step-by-Step Instructions

### 1. Initialize Git Repository (if not already done)

```bash
cd /Users/keyursavalia/Desktop/PROJECTS/SplitPro
git init
```

### 2. Add All Files to Staging

```bash
git add .
```

### 3. Verify What Will Be Committed

Check that `GoogleService-Info.plist` is NOT included:
```bash
git status
```

Look through the list and make sure you see:
- ✅ README.md
- ✅ .gitignore
- ✅ All `.swift` files
- ✅ Project files (`.xcodeproj`)
- ❌ GoogleService-Info.plist (should NOT appear)
- ❌ xcuserdata/ folder (should NOT appear)

### 4. Create Your First Commit

```bash
git commit -m "Sprint 0-2: Complete authentication, friends, and group expense features

- Implemented Firebase Authentication (email/password)
- Added user profile management and friend relationships
- Created group expense sharing with equal split
- Integrated real-time Firestore listeners
- Built complete SwiftUI interface with 4 main tabs
- Added comprehensive error handling and validation"
```

### 5. Create GitHub Repository

1. Go to [GitHub](https://github.com)
2. Click the **+** icon (top right) → **New repository**
3. Repository name: `SplitPro`
4. Description: `iOS expense sharing app built with SwiftUI and Firebase`
5. Choose: **Private** or **Public** (your choice)
6. **DO NOT** initialize with README (we already have one)
7. **DO NOT** add .gitignore (we already have one)
8. Click **Create repository**

### 6. Link Local Repository to GitHub

Copy the commands from GitHub (they'll look like this):

```bash
git remote add origin https://github.com/YOUR_USERNAME/SplitPro.git
git branch -M main
git push -u origin main
```

Replace `YOUR_USERNAME` with your actual GitHub username.

### 7. Verify Upload

Go to your GitHub repository page and verify you see:
- ✅ README.md is displayed
- ✅ All Swift files are present
- ✅ Project structure is intact
- ❌ No `GoogleService-Info.plist` (security!)

---

## 🔄 Making Future Commits

After making changes to your code:

```bash
# Check what changed
git status

# Add changed files
git add .

# Commit with a descriptive message
git commit -m "Add feature: [describe what you added]"

# Push to GitHub
git push
```

---

## 📝 Commit Message Guidelines

Use clear, descriptive commit messages:

**Good examples:**
- `"Add expense editing feature"`
- `"Fix balance calculation bug for groups with 2 members"`
- `"Update UI: Improve group details layout"`
- `"Refactor: Extract balance calculation to separate method"`

**Bad examples:**
- `"Update"` (too vague)
- `"asdf"` (meaningless)
- `"Fixed stuff"` (not specific)

---

## 🏷️ Tagging Releases

Create tags for each completed sprint:

```bash
# Sprint 0
git tag -a v0.1.0 -m "Sprint 0: Authentication foundation"

# Sprint 1  
git tag -a v0.2.0 -m "Sprint 1: User profiles and private IOUs"

# Sprint 2
git tag -a v0.3.0 -m "Sprint 2: Group expenses and equal split"

# Push tags to GitHub
git push --tags
```

---

## 🔐 Security Reminders

### Files That Should NEVER Be Committed:
- ❌ `GoogleService-Info.plist` (Firebase config)
- ❌ `.env` files (environment variables)
- ❌ API keys or secrets
- ❌ `xcuserdata/` (user-specific Xcode data)

### Already Protected by `.gitignore`:
All of the above are already in your `.gitignore` file! ✅

### If You Accidentally Commit a Secret:

1. **Remove from Git history:**
   ```bash
   git rm --cached GoogleService-Info.plist
   git commit -m "Remove sensitive file"
   git push
   ```

2. **Regenerate Firebase credentials:**
   - Go to Firebase Console
   - Download a new `GoogleService-Info.plist`
   - The old one is now public, so regenerate!

---

## 📊 Project Stats

Run this command to see your project statistics:

```bash
# Count lines of code
find . -name "*.swift" -not -path "*/DerivedData/*" | xargs wc -l

# Count number of Swift files
find . -name "*.swift" -not -path "*/DerivedData/*" | wc -l

# See commit history
git log --oneline
```

---

## 🎯 Next Steps After Pushing

1. ✅ Verify repository on GitHub
2. ✅ Add repository topics: `swift`, `swiftui`, `firebase`, `ios`, `expense-sharing`
3. ✅ Update repository description
4. ✅ Add a license (MIT recommended)
5. ✅ Enable GitHub Issues (for bug tracking)
6. ✅ Consider adding GitHub Actions for CI/CD (future)

---

## 🆘 Troubleshooting

### "Repository not found"
- Verify you created the repository on GitHub
- Check that you're using the correct username
- Make sure you have push access

### "Large file detected"
- Check if you accidentally added build files
- Run: `git rm --cached path/to/large/file`
- Update `.gitignore` to exclude the file type

### "Permission denied"
- Set up SSH keys or use HTTPS with personal access token
- See: https://docs.github.com/en/authentication

### "Nothing to commit"
- You might have already committed everything
- Run `git status` to check

---

## 📚 Useful Git Commands

```bash
# View commit history
git log --oneline --graph

# Undo last commit (keeps changes)
git reset --soft HEAD~1

# See what changed in a file
git diff filename.swift

# Create a new branch
git checkout -b feature/new-feature

# Switch branches
git checkout main

# View remote repositories
git remote -v

# Pull latest changes
git pull origin main
```

---

**Happy Coding! 🚀**

For questions about Git/GitHub, see:
- [GitHub Docs](https://docs.github.com)
- [Git Tutorial](https://git-scm.com/docs/gittutorial)

