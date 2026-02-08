# ⚡ Quick Reference Card

## One-Command Release

```bash
.\build-and-release.bat VERSION "Message"
```

**Example:**
```bash
.\build-and-release.bat 0.2.0 "Added new level"
```

---

## What It Does (Automatically)

| Step | What | Time |
|------|------|------|
| 1 | Checks Flutter installed | <1 min |
| 2 | Cleans old builds | <1 min |
| 3 | Builds Windows game | 2-5 min |
| 4 | Creates ZIP package | 1-2 min |
| 5 | Updates version number | <1 min |
| 6 | Creates Git tag | <1 min |
| 7 | Pushes to GitHub | <1 min |
| 8 | GitHub Actions builds | 5-10 min |
| 9 | Release published | <1 min |
| 10 | Users see update | Next launch |

---

## Version Format

Always use: `X.Y.Z`

- `0.1.0` ← First release
- `0.1.1` ← Bug fix
- `0.2.0` ← New features
- `1.0.0` ← Major release

---

## Monitor Your Release

**GitHub Actions Build (5-10 min):**
```
https://github.com/runepro123/stellar-forge/actions
```

**Your Release (After build done):**
```
https://github.com/runepro123/stellar-forge/releases/tag/v0.2.0
```

---

## Advanced Options

```bash
# Use existing build (skip rebuild)
.\build-and-release.bat 0.2.0 "Message" /skip-build

# Don't push to GitHub yet (test first)
.\build-and-release.bat 0.2.0 "Message" /skip-push

# Both
.\build-and-release.bat 0.2.0 "Message" /skip-build /skip-push
```

---

## What Users See

**On Game Launch (if update available):**
```
┌─────────────────────────────────┐
│ 🚀 Update Found!                │
│ Version 0.2.0                   │
│                                 │
│ Downloading in background...    │
│ [████████░░░░░░░░░░] 45%        │
│                                 │
│ [CANCEL]                        │
└─────────────────────────────────┘
```

**After Download:**
```
┌─────────────────────────────────┐
│ 🚀 Update Ready!                │
│                                 │
│ Release Notes:                  │
│ • Added new level               │
│ • Fixed bugs                    │
│                                 │
│ [LATER] [RESTART & UPDATE]      │
└─────────────────────────────────┘
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Flutter not found" | Install from flutter.dev |
| Build fails | Run `flutter pub get` |
| Tag already exists | Use different version (0.2.1) |
| GitHub Actions failed | Check actions page for error |
| Users don't see update | Verify release is published on GitHub |

---

## Workflow

1. **Make changes** to your Flutter code
2. **Test locally** - `flutter run`
3. **Release** - `.\build-and-release.bat 0.2.0 "Message"`
4. **Wait 15 min** for everything to complete
5. **Users get update** automatically! 🎉

---

## Files

| File | Use |
|------|-----|
| `build-and-release.bat` | Windows build script (MAIN) |
| `build-and-release.ps1` | PowerShell automation engine |
| `ADVANCED-UPDATER-GUIDE.md` | Complete docs (15,000 words) |
| `BUILD-AND-RELEASE-QUICK.md` | Quick guide (2,000 words) |
| `VERIFY-AND-TEST.md` | Testing checklist |
| `SYSTEM-COMPLETE.md` | System overview |

---

## Key Shortcuts

```bash
# Fast release
.\build-and-release.bat 0.2.0 "Message"

# Quick test (no build, no push)
.\build-and-release.bat 0.2.0 "Test" /skip-build /skip-push

# Check your releases
https://github.com/runepro123/stellar-forge/releases

# Watch build progress
https://github.com/runepro123/stellar-forge/actions
```

---

## That's It! 🚀

Your game now has enterprise-grade auto-updates. Every release is:
- ✅ Fully automated
- ✅ One command to execute
- ✅ Zero user friction
- ✅ Professional quality

**Happy releasing!**
