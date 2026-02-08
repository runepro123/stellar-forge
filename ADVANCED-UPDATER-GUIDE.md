# 🚀 Advanced Auto-Update System - Complete Documentation

## 🎯 Overview

Your Stellar Forge now has an **enterprise-grade auto-update system** that:

✅ Builds your Windows app locally  
✅ Packages it automatically  
✅ Creates GitHub releases  
✅ Uploads to GitHub  
✅ Notifies users automatically  
✅ Lets users update while playing  

**One command does it all:**

```bash
.\build-and-release.bat 0.2.0 "Your message"
```

---

## 🏗️ Complete Workflow

### Phase 1: Local Build (Your PC)

```
You run: build-and-release.bat 0.2.0
    ↓
[1] Validates Flutter installation
    ↓
[2] Cleans old build artifacts
    ↓
[3] Builds Flutter Windows app in Release mode
    ├─ Compiles Dart code
    ├─ Links dependencies
    └─ Creates: build/windows/x64/runner/Release/
    ↓
[4] Packages into ZIP file
    └─ stellar-forge-windows-v0.2.0.zip
    ↓
[5] Creates Git release
    ├─ Updates pubspec.yaml version
    ├─ Commits changes
    └─ Creates tag: v0.2.0
    ↓
[6] Pushes to GitHub
    ├─ Pushes commits to main branch
    └─ Pushes tag (TRIGGERS GITHUB ACTIONS)
```

### Phase 2: GitHub Build (Automatic)

```
GitHub receives v0.2.0 tag
    ↓
GitHub Actions triggered automatically
    ↓
[1] Checks out your code
    ↓
[2] Builds Windows release
    ├─ flutter pub get
    ├─ flutter build windows --release
    └─ Creates: stellar-forge-windows-v0.2.0.zip
    ↓
[3] Creates release on GitHub with:
    ├─ stellar-forge-windows-v0.2.0.zip
    ├─ Release notes from commit messages
    └─ Published = Users can see it
```

### Phase 3: User Experience (Automatic)

```
User launches Stellar Forge
    ↓
App checks GitHub: "Any new versions?"
    ↓ (v0.2.0 is available)
┌─────────────────────────────────┐
│ 🚀 Update Available!            │
│ Version 0.2.0                   │
│                                 │
│ What's new:                     │
│ • Added new features            │
│ • Fixed bugs                    │
│ • Improved performance          │
│                                 │
│ Downloading in background...    │
│ (Users can keep playing!)       │
│ [Downloading: 45%]              │
└─────────────────────────────────┘
    ↓ (After download completes)
┌─────────────────────────────────┐
│ 🚀 Update Ready!                │
│ Version 0.2.0                   │
│                                 │
│ Ready to install, click when    │
│ you want to restart             │
│                                 │
│ [LATER] [RESTART & UPDATE]      │
└─────────────────────────────────┘
    ↓ (User clicks "RESTART & UPDATE")
    ├─ App saves state
    ├─ Update script runs
    ├─ Old files → new files
    └─ App restarts with v0.2.0
    ↓
Game runs with latest version!
```

---

## 🖥️ Using the Build & Release System

### Method 1: Windows Batch File (Easiest)

Double-click or run from PowerShell:

```bash
.\build-and-release.bat 0.2.0 "Your release message"
```

**Options:**

```bash
# Basic release
.\build-and-release.bat 0.2.0

# With custom message
.\build-and-release.bat 0.2.0 "Added multiplayer support"

# Build only (no push)
.\build-and-release.bat 0.2.0 "Message" /skip-push

# Use existing build (skip recompile)
.\build-and-release.bat 0.2.0 "Message" /skip-build

# Both options
.\build-and-release.bat 0.2.0 "Message" /skip-build /skip-push
```

### Method 2: PowerShell (Advanced)

```powershell
.\build-and-release.ps1 -Version "0.2.0" -Message "Your message"

# Skip build step
.\build-and-release.ps1 -Version "0.2.0" -SkipBuild

# Skip GitHub push
.\build-and-release.ps1 -Version "0.2.0" -SkipPush
```

### Step-By-Step Example

```bash
# 1. Decide on version (using semantic versioning)
#    Current: 0.1.0
#    Next: 0.1.1 (bug fix) or 0.2.0 (new features)

# 2. Run the build command
.\build-and-release.bat 0.2.0 "Added new gameplay features"

# Output will show:
# [STEP 1] Validating environment... OK
# [STEP 2] Cleaning previous builds... OK
# [STEP 3] Building Windows release app... (takes 2-5 min)
# [STEP 4] Creating release package... OK
# [STEP 5] Creating Git release... OK
# [STEP 6] Pushing to GitHub... OK
# [SUCCESS] Release v0.2.0 Complete!

# 3. Watch the build at:
#    https://github.com/runepro123/stellar-forge/actions

# 4. After build completes (5-10 mins), see release:
#    https://github.com/runepro123/stellar-forge/releases

# 5. Users get update notification on next launch!
```

---

## 📊 What Happens Under the Hood

### Build Phase Details

```
build-and-release.ps1
├─ Validates environment
│  ├─ Checks Flutter installed
│  ├─ Checks version format (X.Y.Z)
│  └─ Checks Git repository exists
│
├─ Cleans previous builds
│  └─ Removes: build/windows/x64/runner/Release/*
│
├─ Builds Flutter Windows Release
│  ├─ flutter pub get
│  │  └─ Downloads dependencies
│  └─ flutter build windows --release
│     ├─ Compiles Dart → x86-64 binary
│     ├─ Optimizes code (tree-shaking)
│     └─ Creates: runner.exe + DLLs
│
├─ Creates ZIP package
│  └─ stellar-forge-windows-v0.2.0.zip (100-300 MB typically)
│
├─ Git release
│  ├─ Updates pubspec.yaml: version: 0.2.0
│  ├─ git add stellar_forge_flutter/pubspec.yaml
│  ├─ git commit "chore: bump version to 0.2.0"
│  └─ git tag -a v0.2.0 -m "Your message"
│
└─ Push to GitHub
   ├─ git push origin master:main
   │  └─ Pushes your code changes
   └─ git push origin v0.2.0
      └─ TRIGGERS GitHub Actions automatically!
```

### GitHub Actions Phase

```
GitHub receives: git push origin v0.2.0
    ↓
.github/workflows/build-windows.yml triggered
    ↓
├─ Checkout code
├─ Setup Flutter SDK
├─ Run: flutter pub get
├─ Run: flutter build windows --release
├─ Create: stellar-forge-windows-v0.2.0.zip
├─ Create release on GitHub
├─ Upload ZIP to release
└─ Publish release (users can see it)
```

### Update Detection Phase

```
App startup in update_service.dart:
    ↓
checkForUpdates()
    ├─ GET https://api.github.com/repos/runepro123/stellar-forge/releases/latest
    ├─ Current version: 0.1.0
    ├─ Latest version: 0.2.0
    ├─ Compare: 0.2.0 > 0.1.0 ? YES
    └─ Get download URL from GitHub API
        ↓
    startDownload()
    ├─ Stream download: stellar-forge-windows-v0.2.0.zip
    ├─ Track progress: 0% → 100%
    ├─ Save to temp directory
    └─ Extract ZIP with progress
        ↓
    updateReady = true
    ├─ Show UI: "Update ready! Restart?"
    └─ Wait for user to click "Restart & Update"
        ↓
    applyUpdateAndRestart()
    ├─ Create update batch script
    ├─ Copy new files over old
    ├─ Restart application
    └─ Remove temporary files
```

---

## 🔧 File Structure

```
stellar-forge/
├── build-and-release.bat          ← Run this to build & release (MAIN FILE)
├── build-and-release.ps1          ← PowerShell automation script
├── release-game.bat               ← Git release only (no build)
│
├── stellar_forge_flutter/
│   ├── lib/
│   │   ├── update_service.dart    ← Update logic (core updater)
│   │   └── widgets/
│   │       └── update_progress_bar.dart  ← Beautiful UI
│   │
│   ├── pubspec.yaml               ← Version managed automatically
│   ├── build/windows/x64/runner/Release/  ← Your built app (created by build process)
│   │
│   ├── scripts/
│   │   └── create-release.ps1     ← Git tag creation
│   │
│   └── .github/workflows/
│       └── build-windows.yml      ← GitHub Actions CI/CD
│
└── [Release packages created here]
    ├── stellar-forge-windows-v0.1.0.zip
    ├── stellar-forge-windows-v0.2.0.zip
    └── stellar-forge-windows-v0.3.0.zip
```

---

## 🚀 Workflow Examples

### Example 1: First Release After Updates

**Scenario:** You've made changes to the game, tested locally, ready to release.

```bash
# 1. Make sure all changes are saved
# 2. Run the build & release command
.\build-and-release.bat 0.2.0 "New level: The Nebula"

# What happens automatically:
# ✓ Builds game
# ✓ Creates stellar-forge-windows-v0.2.0.zip
# ✓ Updates version in pubspec.yaml
# ✓ Creates Git commit and tag
# ✓ Pushes to GitHub
# ✓ GitHub Actions builds (you see it at /actions)
# ✓ Release created at /releases
# ✓ Users get notification on next launch
```

### Example 2: Quick Hotfix

**Scenario:** Found a critical bug, fixed it, need to release ASAP.

```bash
# 1. Fix the bug
# 2. Test locally
# 3. Release patch version (0.2.1)
.\build-and-release.bat 0.2.1 "Hotfix: Crash on level 3"

# Takes 2-5 minutes total
# Users get the fix automatically on next launch
```

### Example 3: Major Feature Release

**Scenario:** Spent weeks on new features, ready for big release.

```bash
# 1. Thoroughly test
# 2. Update CHANGELOG (optional)
# 3. Release with version bump
.\build-and-release.bat 1.0.0 "Major: Multiplayer support, new engine, 50+ fixes"

# GitHub release will include:
# - All your commit messages from previous release
# - stellar-forge-windows-v1.0.0.zip
# - Download available immediately
```

---

## 🔍 Monitoring the Release

### Real-time Build Status

While the script runs:
- **Building:** You'll see build progress on your screen
- **Packaging:** Creating ZIP file (usually 1-2 minutes)
- **Git:** Pushing to GitHub (usually seconds)

After it completes, watch the GitHub build:

**1. GitHub Actions Build (5-10 minutes)**
```
https://github.com/runepro123/stellar-forge/actions
```
Look for the workflow run and see the progress. It will:
- Checkout code
- Setup Flutter
- Build
- Create release
- Upload ZIP

**2. Release Page (After build done)**
```
https://github.com/runepro123/stellar-forge/releases/tag/v0.2.0
```
See the release with:
- Release notes
- Download link for stellar-forge-windows-v0.2.0.zip
- Build date/time

**3. Users Getting Updates**
- On next game launch, they see: "Update available!"
- Downloads happen in background
- Click "Restart & Update" when ready
- Game updates automatically!

---

## 🎮 User-Facing Update Flow

### First-time Seeing an Update

```
┌─────────────────────────────────────┐
│ 🎮 Stellar Forge (running v0.1.0)  │
│                                     │
│ Game is playing normally...         │
│                                     │
│ ┌──────────────────────────────────┐│
│ │ 🚀 Update Found!                 ││
│ │ New version 0.2.0 available      ││
│ │                                  ││
│ │ Release Notes:                   ││
│ │ • New Level: The Nebula          ││
│ │ • Fixed crash on level 3         ││
│ │ • Improved graphics              ││
│ │                                  ││
│ │ Downloading in background...     ││
│ │ Progress: 🟩🟩🟩⬜⬜ 60%          ││
│ │                                  ││
│ │ (You can keep playing, it'll    ││
│ │  download while running)         ││
│ │                                  ││
│ │ [CANCEL]                         ││
│ └──────────────────────────────────┘│
│                                     │
│ [Game continues normally...]        │
└─────────────────────────────────────┘

After download completes:

│ ┌──────────────────────────────────┐│
│ │ 🚀 Update Ready!                 ││
│ │                                  ││
│ │ Version 0.2.0 ready to install   ││
│ │ Size: 250 MB                     ││
│ │                                  ││
│ │ Release Notes:                   ││
│ │ • New Level: The Nebula          ││
│ │ • Fixed crash on level 3         ││
│ │ • Improved graphics              ││
│ │                                  ││
│ │ [LATER] [RESTART & UPDATE NOW]   ││
│ └──────────────────────────────────┘│

User clicks [RESTART & UPDATE NOW]:
│ ✓ Game closes
│ ✓ Update script runs
│ ✓ New files installed
│ ✓ Game restarts
│ Game opens with v0.2.0! 🎉
```

---

## ⚡ Performance & Optimization

### Build Times

Typical timeline:

```
build-and-release.bat 0.2.0
    ↓
[2min] Validation and cleanup
[3min] Flutter build (varies by code changes)
[1min] ZIP packaging
[1min] Git operations
[1min] Push to GitHub
────────────────────
~8 min total (first time)
~5 min next time (incremental builds)
```

### Download Sizes

- Windows Release build: 150-300 MB (compressed to ZIP)
- Users download smart:
  - Only downloads when new version exists
  - Downloads in background (game keeps running)
  - Resume supports built-in

### Network Optimization

```
User's game               GitHub Release (Cloudflare CDN)
    ↓                               ↓
    └──→ Download stellar-forge-windows-v0.2.0.zip
         • Uses GitHub's CDN (fast)
         • Supports resume (interruption-safe)
         • Automatic retries
         • Progress tracking
```

---

## 🐛 Troubleshooting

### Issue: "Flutter not found"

**Solution:**
```bash
# Install Flutter: https://flutter.dev/docs/get-started/install
# After installing, verify:
flutter doctor
```

### Issue: "Build failed"

**Solution:**
Check error output, usually:
```bash
# Missing dependencies
cd stellar_forge_flutter
flutter pub get
flutter pub upgrade

# Try again
.\build-and-release.bat 0.2.0
```

### Issue: "Git tag already exists"

**Solution:**
Use different version number:
```bash
# If v0.2.0 exists, use v0.2.1 instead
.\build-and-release.bat 0.2.1 "Your message"
```

### Issue: "GitHub Actions build failed"

**Solution:**
Check at: https://github.com/runepro123/stellar-forge/actions

Usually:
1. Version mismatch between local and GitHub
2. Missing dependencies
3. Code compilation error

Fix the code and retry:
```bash
.\build-and-release.bat 0.2.1 "Hotfix"
```

### Issue: "Users not getting update notification"

**Solution:**
1. Verify release is published (not draft):
   ```
   https://github.com/runepro123/stellar-forge/releases
   ```

2. Verify ZIP file uploaded to release

3. Users need to restart app (check not in background)

4. Check version in pubspec.yaml:
   ```
   stellar_forge_flutter/pubspec.yaml
   ```

---

## 🔐 Security Considerations

### GitHub Token Security

Your GitHub token (GITHUB_TOKEN secret):
- ✅ Hidden in GitHub (never shown even to you)
- ✅ Only used by GitHub Actions
- ✅ Automatically rotated/managed by GitHub

### Release Integrity

GitHub provides:
- ✅ HTTPS encryption for downloads
- ✅ File checksums
- ✅ Digital signatures on releases
- ✅ User verification they're from your account

---

## 📈 Analytics

### Track Update Adoption

GitHub shows you:
```
https://github.com/runepro123/stellar-forge/releases
```

For each release:
- ✓ Download count
- ✓ Release date
- ✓ Number of users who downloaded

Stack your releases to see adoption:
```
v0.1.0: 150 downloads
v0.2.0: 320 downloads (new features)
v0.2.1: 280 downloads (hotfix)
v1.0.0: 500 downloads (major launch)
```

---

## 🎓 Advanced Topics

### Using /skip-build Flag

When to use:
```bash
# You're testing the release process
.\build-and-release.bat 0.2.0 /skip-build

# Or you already have a build from 5 minutes ago
# and just want to package & release it
```

**Note:** This skips Flutter build, uses existing `build/windows/x64/runner/Release/`

### Custom Release Messages

GitHub uses commit messages as release notes:

```bash
# Your commits become your release notes:
git commit -m "feat: added new nebula level"
git commit -m "fix: crash on level 3"
git commit -m "perf: optimized rendering"

# When you do:
.\build-and-release.bat 0.2.0

# GitHub creates release notes showing all commits!
```

### Semantic Versioning Guide

Use this format:

```
MAJOR.MINOR.PATCH

0.1.0    (first release)
0.1.1    (bug fix)
0.2.0    (new feature)
0.2.1    (bug fix)
1.0.0    (production ready)
1.1.0    (new feature)
2.0.0    (breaking changes)
```

**Rules:**
- MAJOR: Breaking changes, major features
- MINOR: New features, backwards compatible
- PATCH: Bug fixes only

---

## 🎯 Summary

### The Process

1. Make changes to your game
2. Test locally
3. Run: `.\build-and-release.bat 0.2.0 "Message"`
4. Wait 5-10 minutes
5. Release is live
6. Users get automatic update on next launch

### What You Get

✅ Fully automated Windows builds  
✅ GitHub releases created automatically  
✅ Users notified automatically  
✅ Updates download in background  
✅ Beautiful update UI overlay  
✅ Users can play while updating  
✅ One-click update for users  

### Time Savings

- Previous way: Manual zipping, uploading, GitHub release creation
- New way: One command does it all
- **Saves 15-20 minutes per release**

---

## 📞 Quick Reference Commands

```bash
# Standard release
.\build-and-release.bat 0.2.0

# Release with custom message
.\build-and-release.bat 0.2.0 "Added new features"

# Build only (no push)
.\build-and-release.bat 0.2.0 /skip-push

# Package existing build
.\build-and-release.bat 0.2.0 /skip-build

# Push manually if needed
git push origin master:main
git push origin v0.2.0

# Check build status
https://github.com/runepro123/stellar-forge/actions

# See release
https://github.com/runepro123/stellar-forge/releases
```

---

**You now have a production-grade auto-update system! 🚀**

Every release is:
- Automatically built
- Automatically packaged
- Automatically uploaded
- Automatically published
- Automatically notified to users
- Automatically applied

Enjoy your advanced update system!
