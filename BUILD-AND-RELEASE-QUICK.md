# ⚡ One-Command Build & Release - Quick Start

## 🎯 What You Now Have

A **complete automated build + release + update system** in ONE command.

## 🚀 Usage

### The Easiest Way

Double-click `build-and-release.bat` and follow prompts OR:

```bash
.\build-and-release.bat 0.2.0 "Your release message"
```

That's it. Everything else happens automatically:
- ✅ Builds your Windows game
- ✅ Packages it
- ✅ Creates GitHub release  
- ✅ Uploads to GitHub
- ✅ Pushes code
- ✅ Triggers GitHub Actions
- ✅ Users get auto-update

## 📋 Required Before First Use

1. **GitHub Token** (already done if you set it up before) ✅
2. **Repository Secrets** (already done) ✅  
3. **.github/workflows/build-windows.yml** exists ✅

## 🎮 Complete Workflow Example

```bash
# 1. You make changes to your game
# 2. Test locally to ensure it works
# 3. Run the release command:

.\build-and-release.bat 0.2.0 "Added multiplayer mode"

# WHAT HAPPENS AUTOMATICALLY:

# Phase 1 - Local (Your PC) - Takes 3-8 minutes
# ├─ Validates Flutter is installed
# ├─ Cleans old build files
# ├─ Builds Flutter Windows app
# │  └─ Compiles all your code
# ├─ Creates ZIP package
# ├─ Creates Git commit & tag
# └─ Pushes to GitHub

# Phase 2 - GitHub (Automatic) - Takes 5-10 minutes
# ├─ GitHub Actions receives tag
# ├─ Builds Windows release again (for consistency)
# ├─ Creates official release
# ├─ Uploads stellar-forge-windows-v0.2.0.zip
# └─ Makes it available for download

# Phase 3 - Users (Automatic)
# ├─ On next game launch, users see: "Update available!"
# ├─ Download happens in background (they keep playing)
# ├─ When done: "Click to restart and update"
# └─ Game updates automatically!
```

## 🔗 What to Check After Running

### 1. GitHub Actions Build (5-10 min after push)
```
https://github.com/runepro123/stellar-forge/actions
```
Look for a green checkmark ✅ = Build successful

### 2. Your Release Page
```
https://github.com/runepro123/stellar-forge/releases/tag/v0.2.0
```
See your release with download link

### 3. Users Getting Updates
- They launch the game on next run
- See "Update available!" notification
- Download happens automatically
- They click "Restart & Update"
- Game updates complete ✅

## 📊 Timeline Example

```
1:00 PM - You run: .\build-and-release.bat 0.2.0 "New level"
1:02 PM - Flutter builds your game
1:04 PM - ZIP package created
1:05 PM - Pushed to GitHub + GitHub Actions starts
1:15 PM - GitHub Actions finishes building + release published
1:16 PM - Users see "Update available" on next launch
1:17 PM - Users download in background (game keeps running)
1:20 PM - Users click "Restart & Update"
1:21 PM - User's game has v0.2.0! 🎉
```

## 🎓 Advanced Usage

### Skip Local Build (use existing build)
```bash
# If you built recently and just want to release again
.\build-and-release.bat 0.2.0 /skip-build
```

### Don't Push to GitHub Yet
```bash
# Build and package, but don't push (for testing)
.\build-and-release.bat 0.2.0 /skip-push
```

### Both Options
```bash
.\build-and-release.bat 0.2.0 /skip-build /skip-push
```

## ✅ Checking Everything Works

### Test 1: Local Build
```bash
# See your stellar-forge-windows-v0.2.0.zip created
.\build-and-release.bat 0.2.0 "Test release" /skip-push
```

### Test 2: Full Release
```bash
# Do everything
.\build-and-release.bat 0.2.0 "First real release"

# Watch: https://github.com/runepro123/stellar-forge/actions
# See build progress in real-time
```

### Test 3: User Update (If you have testers)
1. Install v0.1.0
2. Launch game
3. Should see "Update available v0.2.0"
4. Download happens automatically
5. Click "Restart & Update"
6. Game restarts with v0.2.0 ✅

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| "Flutter not found" | Install Flutter from flutter.dev |
| "Build failed" | Run `cd stellar_forge_flutter && flutter pub get` |
| "Tag already exists" | Use different version (0.2.1 instead of 0.2.0) |
| "GitHub Actions failed" | Check actions page for error details |
| "Users not getting update" | Verify release is published (not draft) on GitHub |

## 📚 Full Docs

For more detailed information, see: **ADVANCED-UPDATER-GUIDE.md**

Contains:
- Complete workflow explanation
- Detailed troubleshooting
- Performance optimization
- Advanced techniques

## 🎯 Your Next Steps

1. **Make game changes** in Flutter code
2. **Test locally** with `flutter run`
3. **Run release** with `.\build-and-release.bat 0.2.0 "Message"`
4. **Wait 10-15 minutes** for everything to complete
5. **Users get automatic update** on next app launch!

---

**That's it!** You have a production-grade auto-update system. 🚀

**Every release now:**
- Builds automatically
- Deploys automatically  
- Users update automatically
- Zero user effort needed!
