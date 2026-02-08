# 🎮 Stellar Forge Setup Guide - Auto-Update System

## ✨ What You Just Got

A **complete, production-ready auto-update system** with:

```
Your Game                                Users
    ↓                                      ↓
Runs Normally                      See Beautiful UI
    ↓                              ↓
Checks GitHub  ← ─ ─ ─ ─ ─ → Automatic Update Check
    ↓                              ↓
Downloads Update          Can Play While Downloading
    ↓                              ↓
Shows Progress                  Displays Progress
    ↓                              ↓
User Clicks "Update"        App Restarts with New Version
    ↓
Everyone Happy! 🎉
```

---

## 🚀 Getting Started in 5 Minutes

### Step 1: Configure GitHub (2 min)

**A. Create a GitHub Token**

1. Go to: https://github.com/settings/tokens
2. Click: "Generate new token (classic)"
3. Fill in:
   - Name: `Stellar Forge Release Token`
   - Expiration: 90 days
4. Check these boxes:
   - ✅ `repo` (Full control)
   - ✅ `workflow` (Update workflows)
5. Click "Generate token"
6. **Copy the token** (you'll use it once)

**B. Add to Repository Secrets**

1. Go to your repo on GitHub: `github.com/YOUR_USER/stellar-forge`
2. Click: Settings → Secrets and variables → Actions
3. New repository secret:
   - Name: `GITHUB_TOKEN`
   - Value: Paste your token
4. Save!

### Step 2: Update Configuration (1 min)

Open your Flutter project and edit:  
**File:** `stellar_forge_flutter/lib/update_service.dart`

Find these lines (around line 12):
```dart
final String githubUser = 'runepro123';      // ← Change to YOUR GitHub username
final String githubRepo = 'stellar-forge';    // ← Keep as is (or change to your repo)
```

That's it! ✅

### Step 3: Test the Setup (2 min)

```bash
# From the stellar-forge directory, run:
cd stellar_forge_flutter
flutter pub get

# Try creating a test release:
cd ..
release-game.bat 0.1.0 "Initial setup test"

# Follow the on-screen instructions to push your code
```

---

## 📦 Creating Your First Release

### Quick Method (Recommended)

Simply double-click and follow prompts:
```
release-game.bat
```

Or from command line:
```bash
# Create release v0.2.0
release-game.bat 0.2.0 "Added cool new features"

# Push changes (follow the command output)
git push origin main
git push origin v0.2.0
```

### What Happens Automatically

1. ✅ Version updates in `pubspec.yaml`
2. ✅ Changes get committed
3. ✅ Tag created: `v0.2.0`
4. ✅ GitHub Actions builds your game
5. ✅ Release created with download link
6. ✅ Users get automatic update notification

---

## 🎯 Release Workflow Explained

```
┌─ You create release
│  release-game.bat 0.2.0
│
├─ Version updated automatically
│  pubspec.yaml: version: 0.2.0
│
├─ Commit and tag created
│  git commit (automatic)
│  git tag v0.2.0 (automatic)
│
├─ You push to GitHub
│  git push origin main
│  git push origin v0.2.0
│
├─ GitHub Actions Triggered (automatic)
│  ✓ Builds Windows release
│  ✓ Creates ZIP package
│  ✓ Generates release notes
│  ✓ Uploads to GitHub Releases
│
├─ Release Published (automatic)
│  https://github.com/YOUR_USER/stellar-forge/releases
│
└─ Users Get Updates (automatic)
   On next app launch:
   ✓ Downloads new version
   ✓ Shows progress
   ✓ Lets user update when ready
```

---

## 📱 User Experience Flow

### First-Time User

```
User Launches Game
    ↓
Game Checks GitHub for Updates
    ↓ (If update available)
┌─────────────────────────────────┐
│ 🚀 Update Found!                │
│ Downloads in background...      │
│ Users can keep playing!         │
│                                 │
│ Progress bar at top             │
│ [Downloading: 23%]              │
└─────────────────────────────────┘
    ↓ (After downloading)
┌─────────────────────────────────┐
│ 🚀 Update Ready!                │
│ Click button when ready         │
│                                 │
│ Release Notes:                  │
│ • Added multiplayer             │
│ • Fixed crash bug               │
│                                 │
│ [LATER]  [UPDATE NOW]           │
└─────────────────────────────────┘
    ↓ (User clicks "UPDATE NOW")
    ├─ App saves state
    ├─ App closes
    ├─ Update script runs
    ├─ Files copied
    └─ App restarts with new version
    ↓
Game Runs (Updated Version!)
```

### Returning User

Just keeps playing! If they don't click "Update Now":

```
Next time they launch:
├─ Update reminder appears again
├─ They can play now, update later
├─ Eventually they'll click "Update"
└─ Game updates smoothly
```

---

## 🔧 File Reference

### Main Files Created

```
stellar-forge/
├── release-game.bat                 # Double-click to create releases
├── setup-auto-update.ps1            # Initial setup (run once)
├── QUICK-START.md                   # Quick reference (this folder)
├── AUTO-UPDATE-README.md            # Technical docs
│
├── stellar_forge_flutter/
│   ├── lib/
│   │   ├── update_service.dart     # Update logic (edit only githubUser/Repo)
│   │   └── widgets/
│   │       └── update_progress_bar.dart  # Beautiful UI (production-ready)
│   │
│   ├── scripts/
│   │   └── create-release.ps1      # PowerShell version (advanced)
│   │
│   └── .github/workflows/
│       └── build-windows.yml       # GitHub Actions (fully automated)
```

### Configuration Points (3 places to edit)

1. **Update service config** (1-time)
   ```
   stellar_forge_flutter/lib/update_service.dart
   - Line 12: githubUser
   - Line 13: githubRepo
   ```

2. **GitHub secrets** (1-time)
   ```
   GitHub.com → Settings → Secrets
   - GITHUB_TOKEN = your token
   ```

3. **Release message** (every release)
   ```
   release-game.bat 0.2.0 "Your message here"
   ```

---

## ✅ Checklist Before First Release

- [ ] GitHub token created and added to secrets
- [ ] `githubUser` updated in `update_service.dart`
- [ ] `githubRepo` updated in `update_service.dart`
- [ ] Code committed to Git
- [ ] Tested game builds locally

---

## 🚨 Troubleshooting

### "Token expired or invalid"
→ Regenerate at https://github.com/settings/tokens  
→ Update the secret on GitHub

### "Release doesn't show up"
→ Check GitHub Actions → See if build succeeded  
→ Verify release is "Published" (not "Draft")

### "Users say they don't see updates"
→ Confirm GitHub token is working  
→ Verify ZIP file is uploaded  
→ Try restarting the app

### "I pushed the tag but nothing happened"
→ Verify tag format: `v0.2.0` (starts with `v`)  
→ Verify it shows in releases page  
→ Check Actions tab for build status

---

## 🎓 Semantic Versioning

Use this format for versions:

```
MAJOR . MINOR . PATCH
  0   .   1   .   0

MAJOR: Big changes (breaking changes)
MINOR: New features
PATCH: Bug fixes
```

**Examples:**
- `0.1.0` → First release
- `0.1.1` → Bug fix
- `0.2.0` → New level/features
- `1.0.0` → Public launch / major milestone
- `1.0.1` → Critical hotfix

**Never use:**
- ❌ `v0.1` (missing patch)
- ❌ `0.1.0-beta` (pre-release syntax)
- ❌ `release-1` (invalid format)

---

## 💡 Pro Tips

### Tip 1: Draft Releases for Testing
```bash
# Build without publishing
.\scripts\create-release.ps1 -Version "0.2.0" -Draft
```

### Tip 2: Detailed Release Notes
```bash
# Write meaningful commit messages:
git commit -m "feat: add multiplayer support"
git commit -m "fix: crash when loading save files"
git commit -m "perf: optimize rendering by 30%"

# They become your release notes!
```

### Tip 3: Check Build Status
```
https://github.com/YOUR_USER/stellar-forge/actions
```

### Tip 4: Test Locally First
```bash
cd stellar_forge_flutter
flutter build windows --release

# Test the built executable before releasing
```

---

## 🔐 Security Best Practices

1. **Never share your token** (it's like your password)
2. **GitHub secrets are hidden** (you can view but not edit - security!)
3. **Regular resets** (regenerate token every 90 days)
4. **Monitor usage** (check GitHub Actions logs)

---

## 📊 What You Can Monitor

**After releasing, check:**

1. **Build Status**
   ```
   https://github.com/YOUR_USER/stellar-forge/actions
   ```
   Green ✅ = Success  
   Red ❌ = Failed

2. **Release Link**
   ```
   https://github.com/YOUR_USER/stellar-forge/releases
   ```
   See your release with download link

3. **Download Statistics** (GitHub shows this)
   ```
   How many users downloaded each version
   ```

---

## 🎉 You're Ready!

Your game now has **enterprise-grade auto-updates**!

```bash
# Create your first release:
release-game.bat 0.1.0 "Stellar Forge v0.1.0"

# Push it out:
git push origin main
git push origin v0.1.0

# Watch the magic happen:
# - GitHub builds your game
# - Release is created
# - Users get updates automatically
```

### Need Help?

- **Quick questions?** → Read `QUICK-START.md`
- **Technical details?** → Read `AUTO-UPDATE-README.md`
- **GitHub Actions?** → Check `.github/workflows/build-windows.yml`

---

## 🚀 Next Steps

1. ✅ Configure GitHub token (5 min)
2. ✅ Update githubUser/Repo (1 min)
3. ✅ Create first release (2 min)
4. ✅ Push to GitHub (1 min)
5. ✅ Watch build complete (5-10 min)
6. ✅ Users enjoy auto-updates! 🎮

---

**Happy releasing!** 🎊  
*Your game is now update-ready.*
