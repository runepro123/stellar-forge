# ✅ Build & Release System - Verification & Testing

## Pre-Release Checklist

Before attempting your first full release, verify everything is ready:

### ✓ GitHub Setup
- [ ] You have a GitHub account
- [ ] You have a personal access token in repo secrets as `GITHUB_TOKEN`
- [ ] Token has `repo` and `workflow` permissions

### ✓ Code Setup
- [ ] `githubUser` is set correctly in `update_service.dart`
- [ ] `githubRepo` is set correctly in `update_service.dart`
- [ ] `.github/workflows/build-windows.yml` exists

### ✓ Flutter Setup
- [ ] Flutter SDK installed (run `flutter doctor` - all green)
- [ ] You can build locally: `flutter build windows --release`
- [ ] In folder: `stellar_forge_flutter/`

### ✓ Git Setup
- [ ] Git initialized (`.git` folder exists)
- [ ] Remote set: `git remote -v` shows `origin`
- [ ] Main branch exists and connected

---

## Test Phase 1: Local Build Test

**Goal:** Verify your local machine can build the app.

```bash
# 1. Navigate to project
cd d:\stellar-forge remake

# 2. Test the Flutter build (builds app but doesn't package)
cd stellar_forge_flutter
flutter pub get
flutter build windows --release

# Expected output:
# ✓ Compiling for Windows...
# ✓ Build complete!
# ✓ Output: build/windows/x64/runner/Release/

# 3. Check if build exists
if exist build\windows\x64\runner\Release\runner.exe (
    echo Build successful!
) else (
    echo Build failed - check error output above
)

# 4. Return to main folder
cd ..
```

If this succeeds ✅, your environment is ready.

---

## Test Phase 2: Script Validation

**Goal:** Verify the build-and-release scripts work.

```bash
# 1. Test with existing build (skips full build, just packages)
.\build-and-release.bat 0.2.0 "Test run" /skip-build /skip-push

# This should:
# ✓ Not error out
# ✓ Create stellar-forge-windows-v0.2.0.zip
# ✓ Say "Done!" 

# 2. Check the ZIP was created
if exist stellar-forge-windows-v0.2.0.zip (
    echo ZIP created successfully! 
    # Get the size
    dir stellar-forge-windows-v0.2.0.zip
) else (
    echo ZIP was not created - check errors above
)
```

If ZIP is created ✅, scripts are working.

---

## Test Phase 3: Git & Tagging

**Goal:** Verify Git operations work.

```bash
# 1. Check current branch
git branch -a

# Should show:
# * master (or main)
# remotes/origin/main
# remotes/origin/master

# 2. Check status
git status
# Should show: "working tree clean" (no uncommitted changes)

# 3. Check tags
git tag -l
# Should show existing tags like: v0.1.0

# 4. Try creating a test tag
git tag -a v-test -m "Testing tagging"

# 5. Delete test tag
git tag -d v-test

# If no errors ✅, Git operations work
```

If all commands succeed ✅, Git is ready.

---

## Test Phase 4: Full Release Test (With /skip-push)

**Goal:** Test the entire workflow except GitHub push.

```bash
# 1. Create a test release (don't push to GitHub yet)
.\build-and-release.bat 0.3.0 "Test full release" /skip-push

# This will:
# ✓ Build the game
# ✓ Create ZIP package
# ✓ Update version in pubspec.yaml
# ✓ Create Git tag v0.3.0
# ✓ NOT push to GitHub (because /skip-push)

# 2. Verify outputs exist
if exist stellar-forge-windows-v0.3.0.zip (
    echo Release package created!
)

# 3. Check Git tag was created
git tag | find /c "v0.3.0"
# Should output: 1 (meaning tag exists)

# 4. Check version was updated
findstr /c "version: 0.3.0" stellar_forge_flutter\pubspec.yaml
# Should find the version line
```

If everything is created ✅, workflow is ready.

**Note:** The tag was created locally but NOT pushed yet, so it's safe to delete if testing:
```bash
git tag -d v0.3.0
```

---

## Test Phase 5: Live Release (Full Workflow)

**Goal:** Do a complete release including publishing to GitHub.

```bash
# 1. Use a real version number
# Previous: 0.1.0
# Next test: 0.2.1 (patch version = low risk if issues)

.\build-and-release.bat 0.2.1 "Test release to GitHub"

# This will:
# ✓ Build game
# ✓ Package to ZIP
# ✓ Update version
# ✓ Create Git tag
# ✓ PUSH to GitHub ← This triggers the build!
# ✓ GitHub Actions starts automatically

# 2. Watch the GitHub build
# Go to: https://github.com/runepro123/stellar-forge/actions
# You should see a yellow circle (in progress) that turns:
#   - 🟢 Green = Success!
#   - 🔴 Red = Failed (check logs)

# 3. Wait 5-10 minutes for build to complete

# 4. Check the release
# https://github.com/runepro123/stellar-forge/releases/tag/v0.2.1
# Should show:
#   ✓ Release visible
#   ✓ stellar-forge-windows-v0.2.1.zip available
#   ✓ Download option visible
```

If release publishes successfully ✅, you're ready for production!

---

## Test Phase 6: User Update Test (Optional)

**Goal:** Test that the auto-updater actually works.

**Prerequisites:**
- Version 0.2.0 (or earlier) installed on test machine
- Version 0.2.1 (or later) released to GitHub

**Steps:**

```bash
# 1. Install older version (v0.2.0)
# Download from GitHub releases and run it

# 2. Launch the game
# The app will:
# ✓ Check for updates
# ✓ Find v0.2.1 available
# ✓ Show "Update Available" overlay
# ✓ Start downloading in background

# 3. Wait for download to complete
# Look for: "Update Ready! Click to restart"

# 4. Click "Restart & Update"
# The app will:
# ✓ Close
# ✓ Run update script
# ✓ Copy new version
# ✓ Restart with v0.2.1
# ✓ Show "Game is up to date" on next check

# 5. Verify version changed
# Look at window title or settings menu
# Should show v0.2.1 now!
```

If it updates successfully ✅, the entire system works!

---

## Verification Checklist Summary

After testing, verify:

- [ ] **Local Build Test** - Can build Windows app locally
- [ ] **Script Validation** - Scripts create ZIP files
- [ ] **Git Operations** - Tagging and status work
- [ ] **Test Release** - Can create releases locally
- [ ] **GitHub Build** - GitHub Actions completes successfully
- [ ] **Release Published** - Release visible on GitHub
- [ ] **(Optional) User Update** - App updates automatically

---

## Common Issues During Testing

### Issue: "Error: version already exists"

**Cause:** You're trying to release v0.2.0 but it already exists.

**Solution:**
```bash
# Use a different version
.\build-and-release.bat 0.2.1 "Updated message"

# Or delete the tag locally (if not pushed yet)
git tag -d v0.2.0

# Then retry
.\build-and-release.bat 0.2.0 "Message"
```

### Issue: "GitHub Actions failed"

**Cause:** Build server couldn't compile your code.

**Solution:**
1. Check the error at: https://github.com/runepro123/stellar-forge/actions
2. Usually a code compilation error
3. Fix the code
4. Run another release:
```bash
.\build-and-release.bat 0.2.2 "Fixed build error"
```

### Issue: "ZIP file not created"

**Cause:** Build didn't complete successfully.

**Solution:**
```bash
# Check what went wrong
cd stellar_forge_flutter
flutter build windows --release

# Fix any errors, then retry
.\build-and-release.bat 0.2.0 /skip-push

# Look for error messages in output
```

### Issue: "Update doesn't appear in game"

**Cause:** Release not published or version comparison failed.

**Solution:**
1. Verify release is published (not draft)
2. Verify ZIP file is uploaded to release
3. Verify version format in pubspec.yaml is correct
4. Check that user's current version is LOWER than release version

---

## Success Indicators

### Phase 1 (Local Build)
✅ Console shows: "Build complete!"  
✅ File exists: `build/windows/x64/runner/Release/runner.exe`

### Phase 2 (Scripting)
✅ File exists: `stellar-forge-windows-v0.2.0.zip`  
✅ File size > 100 MB (typical)

### Phase 3 (Git Tagging)
✅ Command `git tag -l` shows your new tag  
✅ Git status shows clean working tree

### Phase 4 (GitHub Push)
✅ No error messages about authentication  
✅ Console shows: "✓ Tag pushed"

### Phase 5 (GitHub Actions)
✅ Actions page shows green checkmark  
✅ Build completed successfully (not in progress/failed)

### Phase 6 (Release Published)
✅ Release page shows stellar-forge-windows-v0.2.0.zip  
✅ ZIP is marked as downloadable

### Phase 7 (User Update - Optional)
✅ Update overlay appears in game  
✅ File downloads successfully  
✅ Game restarts with new version

---

## Performance Expectations

| Phase | Time | Notes |
|-------|------|-------|
| Local build | 2-5 min | First time slower |
| ZIP creation | 1-2 min | Compressing files |
| Git operations | <1 min | Creating tag, commits |
| GitHub push | <1 min | Uploading commits |
| **Total local** | **5-10 min** | **Your PC** |
| GitHub Actions build | 5-10 min | Server-side |
| Release publishing | <1 min | Automatic |
| **Total start-to-finish** | **15-20 min** | **Until users see it** |

---

## Ready to Go!

Once you've completed the verification checklist:

```bash
# You're ready to release like this:
.\build-and-release.bat 1.0.0 "Major release to production"

# Everything will work automatically:
# ✅ Builds your game
# ✅ Packages it
# ✅ Creates release
# ✅ Uploads to GitHub
# ✅ Users get notified
# ✅ Users update automatically
```

**Congratulations!** You have a production-grade auto-update system! 🚀

For questions, see: **ADVANCED-UPDATER-GUIDE.md**
