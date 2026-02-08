# ⚡ Stellar Forge Auto-Update System - Quick Start

## 🎯 What You Have

Your game now has a **production-ready automatic update system** with:

✅ **Non-blocking updates** - Users can play while the game updates  
✅ **Beautiful UI** - Modern progress overlay with animations  
✅ **One-command releases** - Simple version management  
✅ **GitHub integration** - Automated builds and releases  
✅ **User control** - "Later" and "Update Now" buttons  
✅ **Release notes** - Automatic changelog generation  

---

## 🚀 How to Use

### Quick Release (Windows)

Simply run from the project root and you're done:

```bash
# Option 1: Double-click the batch file
release-game.bat

# Option 2: Command line
release-game.bat 0.2.0 "Added cool new features"
```

### Detailed Release (PowerShell)

```powershell
cd stellar_forge_flutter/scripts
.\create-release.ps1 -Version "0.2.0" -Message "Added multiplayer"
```

### What Happens Next

1. ✅ Your code gets committed and tagged
2. ✅ When you `git push`, GitHub Actions builds the app
3. ✅ A release is created with download link
4. ✅ Users get automatic update notifications

---

## 📱 How Users Experience It

### First Time
1. User downloads and runs your game
2. On next launch, it checks for updates
3. A beautiful progress bar appears at the top
4. Download happens **in the background** ⭐
5. User can **keep playing** while downloading

### When Ready
1. User clicks **"RESTART & UPDATE"**
2. Game saves state and exits
3. Update is applied automatically
4. Game restarts with new version

---

## 🎮 For Users: The Update UI

When an update is available, users see:

```
╔════════════════════════════════════════╗
║  🚀 Updating Stellar Forge             ║
║  ⬇️ Downloading: 45.2%                  ║
║  ████████░░░░░░░░░░░░░░                ║
║                        [CANCEL]        ║
╚════════════════════════════════════════╝
```

When ready:

```
╔════════════════════════════════════════╗
║  🚀 Update Ready!                      ║
║  Version 0.2.0 is ready to install     ║
║                                        ║
║  What's New:                           ║
║  • Added multiplayer support           ║
║  • Fixed crash on startup              ║
║  • Improved performance                ║
║                                        ║
║  [LATER]  [RESTART & UPDATE]           ║
╚════════════════════════════════════════╝
```

---

## 🔧 File Structure

```
stellar-forge/
├── release-game.bat                    # Quick release (Windows)
├── setup-auto-update.ps1               # Initial setup script
├── stellar_forge_flutter/
│   ├── pubspec.yaml                    # Version lives here
│   ├── lib/
│   │   ├── update_service.dart        # Update logic
│   │   └── widgets/
│   │       └── update_progress_bar.dart  # Beautiful UI
│   ├── scripts/
│   │   └── create-release.ps1         # Release creation
│   └── .github/workflows/
│       └── build-windows.yml          # GitHub Actions build
└── AUTO-UPDATE-README.md              # Full documentation
```

---

## ⚙️ Configuration

### GitHub Setup (One-time)

1. **Get a GitHub token:**
   - Go to https://github.com/settings/tokens
   - Create a "Personal access token (classic)"
   - Enable: `repo` + `workflow` permissions
   - Copy the token

2. **Add to your repo secrets:**
   - Go to your repo → Settings → Secrets and variables → Actions
   - Create secret: `GITHUB_TOKEN` = your token
   - Done! ✅

3. **Configure your repo info:**
   - Open: `stellar_forge_flutter/lib/update_service.dart`
   - Update: `githubUser` and `githubRepo`
   - Just 2 lines to change! 🎯

### User Preferences (Customizable)

Edit `stellar_forge_flutter/lib/update_service.dart`:

```dart
// Check updates every 3600 seconds (1 hour)
// Adjust timing as needed

// Supported platforms: 'windows', 'linux'
// Add more as you expand!
```

---

## 📦 Version Numbering

Use **Semantic Versioning**:

```
MAJOR.MINOR.PATCH
  0  .  1  .  0

MAJOR: Big features (breaking changes)
MINOR: New features (backward compatible)
PATCH: Bug fixes
```

Examples:
- `0.1.0` → First release
- `0.1.1` → Bug fix
- `0.2.0` → New level/features
- `1.0.0` → Public launch

---

## 🎯 Release Checklist

Before each release:

- [ ] Update `pubspec.yaml` with new version (or let the script do it)
- [ ] Test the game build locally
- [ ] Write release notes/changelog
- [ ] Commit code: `git add .` then `git commit -m "..."`
- [ ] Run release: `release-game.bat 0.2.0 "Your message"`
- [ ] Push code: `git push origin main`
- [ ] Push tag: `git push origin v0.2.0` (or let the script tell you)

That's 6 steps → Now just 1 command! 🎉

---

## ❓ Common Questions

**Q: Will users lose their progress?**  
A: No! Updates are applied cleanly, saves are preserved.

**Q: Can users skip updates?**  
A: Yes! They click "LATER" and can play indefinitely.

**Q: What if the download fails?**  
A: Users can retry, cancel, or continue playing.

**Q: Do I need to release every day?**  
A: Nope! Release when you have features/fixes ready.

**Q: Can I have draft releases?**  
A: Yes! Add `-Draft` flag to create unpublished builds for testing.

---

## 📊 Monitoring Releases

View your game's releases:
```
https://github.com/YOUR_USERNAME/stellar-forge/releases
```

Monitor build status:
```
https://github.com/YOUR_USERNAME/stellar-forge/actions
```

---

## 🛠️ Troubleshooting

**"File not found" error:**
- Run scripts from the repository root
- Make sure you're in the stellar-forge folder

**"Tag already exists" error:**
- Use a different version number (increment it)
- Example: 0.2.0 instead of 0.1.9

**"GitHub Actions won't trigger:**
- Ensure tag starts with `v` (e.g., `v0.2.0`)
- Check the tag was pushed: `git push origin v0.2.0`

**Updates not showing:**
- Check GitHub token permissions
- Verify release isn't still in draft mode
- Users need to restart the app to check

---

## 🎓 Learning More

- **GitHub Actions**: https://docs.github.com/en/actions
- **Flutter Desktop**: https://flutter.dev/desktop
- **Semantic Versioning**: https://semver.org

---

## 💡 Pro Tips

1. **Create Drafts First**: Use `-Draft` to test before publishing
2. **Detailed Changelogs**: Include what's new in release message
3. **Regular Releases**: Users love seeing progress!
4. **Git Commits**: Make your commit messages clear for changelogs

---

## 🎉 You're All Set!

Your game now has **enterprise-grade auto-updates** with just a single command to release.

```bash
release-game.bat 0.2.0 "Your awesome features!"
```

That's it! The rest happens automatically. Happy developing! 🚀

---

**Need help?** Check → `AUTO-UPDATE-README.md` for detailed technical docs.
