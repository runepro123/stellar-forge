# 📚 Stellar Forge Auto-Update System - Technical Documentation

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Component Description](#component-description)
3. [Update Flow](#update-flow)
4. [GitHub Actions Workflow](#github-actions-workflow)
5. [Configuration & Customization](#configuration--customization)
6. [API Reference](#api-reference)
7. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### System Design

```
┌─────────────────────────────────────────────────────────────┐
│                    Stellar Forge Game App                    │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  UpdateService (Provider - State Management)         │   │
│  │  • Checks GitHub releases                            │   │
│  │  • Manages downloads                                 │   │
│  │  • Extracts archives                                 │   │
│  │  • Handles version comparison                        │   │
│  └──────────────────────────────────────────────────────┘   │
│           ↓                                                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  UpdateProgressBar (UI Widget)                       │   │
│  │  • Shows progress overlay                            │   │
│  │  • Displays release notes                            │   │
│  │  • Provides user controls                            │   │
│  └──────────────────────────────────────────────────────┘   │
│           ↓                                                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Game Content (Continues Running)                    │   │
│  │  • Game loop runs normally                           │   │
│  │  • Users can play while updating                     │   │
│  │  • Non-blocking architecture                         │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
         ↓                                    ↓
    GitHub API                         Local File System
    (Check releases)                   (Cache updates)
```

### Technology Stack

- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **Networking**: http package
- **Compression**: archive package
- **Platform Integration**: process, path_provider
- **CI/CD**: GitHub Actions
- **Version Control**: Git

---

## Component Description

### 1. UpdateService (lib/update_service.dart)

**Core service handling all update logic**

```dart
class UpdateService extends ChangeNotifier {
  // Properties
  bool _isChecking              // Currently checking for updates
  bool _isDownloading           // Currently downloading
  double _downloadProgress      // 0.0 to 1.0
  String? _newVersion           // Available version
  String? _downloadUrl          // URL to download from
  bool _updateReady             // Ready to install
  String _status                // User-friendly status message
  
  // Methods
  Future<void> checkForUpdates()           // Check GitHub for updates
  Future<void> startDownload()             // Begin downloading
  void cancelUpdate()                      // Cancel in-progress update
  Future<void> applyUpdateAndRestart()     // Install and restart
  
  // Private Methods
  bool _isVersionNewer(String, String)     // Compare versions
  Future<void> _prepareUpdate(List<int>)   // Extract and prepare
}
```

**Key Features:**
- ✅ Background checking (doesn't block game)
- ✅ Streaming download with progress tracking
- ✅ Cancelable operations
- ✅ ZIP extraction in background
- ✅ Cross-platform support (Windows/Linux)
- ✅ Comprehensive error handling

### 2. UpdateProgressBar (lib/widgets/update_progress_bar.dart)

**Beautiful UI overlay for update display**

**State Management:**
```dart
class _UpdateProgressBarState extends State<UpdateProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController
  // Slide animation for top-down entry
  // Opacity animation for fade in/out
}
```

**Features:**
- ✅ Smooth slide-in animation
- ✅ Contextual display (downloading vs. ready)
- ✅ Progress bar with shimmer effect
- ✅ Percentage display
- ✅ Release notes display
- ✅ User action buttons
- ✅ Responsive design

**UI States:**

```
State 1: Downloading
┌─────────────────────────────────────┐
│ 🔵 ⬇️ Downloading Update v0.2.0      │
│ Status: Extracting: 45.2%           │
│ ████████░░░░░░░░░░░░                │
│              [CANCEL]               │
└─────────────────────────────────────┘

State 2: Ready to Install
┌─────────────────────────────────────┐
│ 🟢 🚀 Update Ready!                  │
│ Status: Update ready! Click restart  │
│ Version 0.2.0 available             │
│                          [Dark Background]
│ What's New:                         │
│ • Added multiplayer                 │
│ • Fixed crash bugs                  │
│                                     │
│ [LATER]  [RESTART & UPDATE]         │
└─────────────────────────────────────┘
```

---

## Update Flow

### Sequence Diagram

```
App Start
   ↓
Check for Updates (async)
   ↓ (if available)
Show "Update Available"
   ↓
Download in Background
   ├─ User can still play
   ├─ Progress updates in real-time
   └─ Show progress bar
   ↓
Extraction Phase
   ├─ Extract to temp directory
   └─ Update progress bar
   ↓
Show "Ready to Install"
   ├─ [Later] - Continue playing
   └─ [Restart] - Prepare restart
   ↓
Exit App
   ↓
Execute Update Script
   ├─ Copy files to app directory
   ├─ Windows: batch script (xcopy)
   └─ Linux: bash script (cp)
   ↓
Restart App
   ↓
Launch with New Version
```

### State Transitions

```
IDLE
 ├─ checkForUpdates() → CHECKING
 │   ├─ (no update) → IDLE
 │   └─ (update found) → READY_TO_DOWNLOAD
 │
 └─ READY_TO_DOWNLOAD
     └─ startDownload() → DOWNLOADING
         ├─ Download progress updates
         ├─ (download complete) → EXTRACTING
         │   ├─ Extract progress updates
         │   └─ (extract complete) → READY_TO_INSTALL
         ├─ (cancelled) → IDLE
         └─ (error) → IDLE
         
READY_TO_INSTALL
 ├─ cancelUpdate() → IDLE
 └─ applyUpdateAndRestart() → EXIT_AND_UPDATE
```

---

## GitHub Actions Workflow

### Workflow File: `.github/workflows/build-windows.yml`

**Trigger Events:**
- On tag push: `v*` (e.g., `v0.2.0`)
- Manual trigger: `workflow_dispatch` with draft option

**Build Steps:**

1. **Checkout Code**
   ```yaml
   - uses: actions/checkout@v4
     with:
       fetch-depth: 0  # Get full history for changelog
   ```

2. **Setup Flutter**
   ```yaml
   - uses: subosito/flutter-action@v2
     with:
       flutter-version: '3.19.0'
   ```

3. **Build Windows Release**
   ```bash
   flutter build windows --release --verbose
   ```

4. **Package as ZIP**
   ```powershell
   # Copies build output
   # Creates ZIP archive
   # Named: stellar-forge-windows-v0.2.0.zip
   ```

5. **Generate Release Notes**
   ```bash
   # Gets commits since last tag
   # Formats as changelog
   # Embeds in release body
   ```

6. **Create GitHub Release**
   ```yaml
   - uses: softprops/action-gh-release@v1
     with:
       files: stellar-forge-windows-*.zip
       draft: true|false
       prerelease: true|false
       body: Auto-generated notes
   ```

**Build Artifacts:**
```
stellar-forge-windows-v0.2.0.zip
├── galactic.exe          # Main executable
├── flutter_windows.dll   # Flutter runtime
├── launcher_icon.png     # Application icon
├── data/                 # Game assets
│   ├── fonts/
│   ├── packages/
│   └── shaders/
└── ... (other depends)
```

---

## Configuration & Customization

### 1. Update Check Frequency

**File:** `lib/update_service.dart`

```dart
// Change after download completes:
Future<void> checkForUpdates() async {
  if (kIsWeb || _isChecking || _isDownloading || _updateReady) return;
  // Add custom timing here
}
```

**Recommended:**
- Check on app start (already implemented)
- Check every 1 hour (can customize in app)
- Check on resume from background (can add)

### 2. GitHub User/Repo

**File:** `lib/update_service.dart`

```dart
final String githubUser = 'runepro123';      // Your GitHub username
final String githubRepo = 'stellar-forge';    // Your repo name
```

### 3. Supported Platforms

**File:** `lib/update_service.dart` - `checkForUpdates()`

```dart
String platformSuffix = Platform.isWindows ? 'windows' : 'linux';
// Platform detection happens automatically
// Add support for more platforms:
// - macOS: 'macos'
// - Web: Not recommended (releases only work on desktop)
```

### 4. Progress Bar Styling

**File:** `lib/widgets/update_progress_bar.dart`

```dart
// Colors
gradient: LinearGradient(colors: [
  const Color(0xFF1a1a2e),  // Dark background
  const Color(0xFF16213e),  // Slightly lighter
])

// Animation duration
duration: const Duration(milliseconds: 500)

// Progress bar colors
Colors.blueAccent        // Default progress color
Colors.lightBlueAccent   // Shimmer highlight
```

### 5. Release Notes Format

**File:** `.github/workflows/build-windows.yml`

Automatically generated from git commits. To control it:

```bash
# Make descriptive commits:
git commit -m "feat: add multiplayer support"
git commit -m "fix: crash on startup"
git commit -m "perf: improve frame rate"

# They'll appear as:
# - Add multiplayer support
# - Crash on startup fix
# - Improve frame rate
```

---

## API Reference

### UpdateService Public API

#### `checkForUpdates()`
```dart
Future<void> checkForUpdates()
```
- **Description**: Check GitHub for new releases
- **Returns**: Future (non-blocking)
- **Side Effects**: 
  - Sets `_isChecking` → true
  - Retrieves latest release from GitHub
  - Auto-starts download if newer version found
- **Called Automatically**: On app startup (in main.dart)
- **Thread**: Runs on background thread

#### `startDownload()`
```dart
Future<void> startDownload()
```
- **Description**: Begin downloading update from URL
- **Returns**: Future
- **Prerequisites**: `_downloadUrl` must be set
- **Side Effects**:
  - Sets `_isDownloading` → true
  - Streams data and updates progress
  - Automatically extracts when complete
- **Progress**: Real-time via `_downloadProgress` (0.0-1.0)

#### `cancelUpdate()`
```dart
void cancelUpdate()
```
- **Description**: Cancel ongoing download
- **Returns**: void
- **Side Effects**:
  - Closes HTTP stream
  - Sets `_updateCancelled` → true
  - Resets UI to initial state
- **Usage**: Called when user clicks "Cancel" button

#### `applyUpdateAndRestart()`
```dart
Future<void> applyUpdateAndRestart()
```
- **Description**: Install update and restart app
- **Returns**: Future (app exits before completion)
- **Prerequisites**: `_updateReady` must be true
- **Platform-Specific**:
  - **Windows**: Creates batch script, uses `xcopy`
  - **Linux**: Creates bash script, uses `cp`
- **Side Effects**: Exits application (exit code 0)

### Getters (Observable)

```dart
bool get isChecking          // Currently checking
bool get isDownloading       // Currently downloading
double get downloadProgress  // 0.0 - 1.0
String? get newVersion       // Available version string
bool get updateReady         // Ready to install
String get status            // User-friendly message
String? get currentOperation // 'downloading'|'extracting'|'ready'
String? get releaseNotes     // Release notes from GitHub
bool get updateCancelled     // Was cancelled
```

### File Locations

```
Windows:
  Temp Dir: System.IO.Path.GetTempPath()
  Update Dir: {TempDir}/update_temp/
  App Dir: C:\Users\User\AppData\Local\YourGame\
  Scripts: {TempDir}/update.bat

Linux:
  Temp Dir: /tmp/
  Update Dir: /tmp/update_temp/
  App Dir: ~/.local/share/YourGame/
  Scripts: /tmp/update.sh
```

---

## Troubleshooting

### Issue: Updates not appearing

**Symptoms:**
- `checkForUpdates()` returns no new version
- Status shows "You are up to date!"

**Solutions:**
1. ✅ Verify tag format is `v1.2.3` (starts with 'v')
2. ✅ Confirm release is published (not draft)
3. ✅ Check ZIP file is uploaded to release
4. ✅ Verify ZIP name contains 'windows' or 'linux'
5. ✅ Look at app logs for API errors

**Debug:**
```dart
// In UpdateService.checkForUpdates(), add:
print('GitHub API Response: ${response.statusCode}');
print('Latest Tag: $latestVersion');
print('Current Version: $currentVersion');
```

### Issue: Download fails silently

**Symptoms:**
- Download starts but never completes
- Progress stops at some percentage

**Solutions:**
1. ✅ Check network connectivity
2. ✅ Verify GitHub release file is < 2GB
3. ✅ Check machine disk space
4. ✅ Verify temp folder exists and is writable
5. ✅ Check Windows Defender/antivirus isn't blocking

**Debug:**
```dart
// Add error logging in startDownload():
.onError: (e) {
  _status = 'Download error: $e';
  debugPrint('Full error: ${e.toString()}');
}
```

### Issue: Update applies but app doesn't restart

**Symptoms:**
- Files are copied but no restart happens
- Verify folder shows new files
- Old app still running

**Solutions:**
1. ✅ Verify old executable isn't locked
2. ✅ Check `applyUpdateAndRestart()` is called
3. ✅ Ensure batch/bash script has permissions
4. ✅ Try manual restart after update

**Windows Specific:**
```batch
REM Ensure old .exe is not locked before copying
taskkill /IM galactic.exe /F 2>nul
timeout /t 1
REM Then proceed with copy
```

### Issue: Version comparison fails

**Symptoms:**
- Updates available show as "0.0.1" or gibberish
- `_isVersionNewer()` returns unexpected results

**Solutions:**
1. ✅ Verify version format in pubspec.yaml: `X.Y.Z`
2. ✅ Verify GitHub tag format: `vX.Y.Z`
3. ✅ Check JSON parsing of release response
4. ✅ Add debug logging to `_isVersionNewer()`

```dart
bool _isVersionNewer(String current, String latest) {
  print('Comparing: $current vs $latest');
  List<int> c = current.split('.').map(int.parse).toList();
  List<int> l = latest.split('.').map(int.parse).toList();
  // ... rest of logic
}
```

### Issue: GitHub Actions doesn't trigger

**Symptoms:**
- Tag pushed but no "Actions" tab activity
- No release created

**Solutions:**
1. ✅ Verify tag starts with `v`: `git tag -l`
2. ✅ Check GITHUB_TOKEN has permissions
3. ✅ Verify workflow file syntax (YAML)
4. ✅ Check if branch is configured to run workflows
5. ✅ Look at Actions tab for error details

```bash
# Verify tag format
git tag v0.2.0
git push origin v0.2.0

# Check workflow file
cd .github/workflows
# Validate YAML at: https://www.yamllint.com/
```

---

## Performance Considerations

### Memory Usage

| Phase | Memory | Notes |
|-------|--------|-------|
| Checking | < 5MB | Lightweight API call |
| Downloading | Variable | Streams data (~50KB chunks) |
| Extracting | Peak | Uncompresses entire ZIP in memory |
| Ready to Install | < 10MB | Waits for user action |

**Optimization:**
- ZIP extraction uses streaming where possible
- Large files broken into chunks
- Memory freed after extraction

### Network Usage

```dart
// Example: 50MB update file
Download:     50MB
Compression:  20MB in ZIP (~60% compression)
Network:      ~20-30 seconds (10 Mbps connection)
Extraction:   ~5-10 seconds
Total Time:   ~35-40 seconds
```

### Disk Usage

```
While updating:
├── Original install:     ~100MB
├── Update ZIP cache:     ~30MB (temporary)
├── Extracted update:     ~100MB (temporary)
└── Total needed:         ~230MB

After update:
└── Updated install:      ~100MB
```

---

## Security Considerations

### SSL/TLS

- ✅ All GitHub API calls use HTTPS
- ✅ Certificate validation included
- ✅ No MITM vulnerabilities

### Package Integrity

- ✅ ZIP files not verified (GitHub provides)
- ✅ Consider adding SHA256 checksum verification for sensitive content
- ✅ Recommend HTTPS for custom update servers

### File Permissions

```
Windows: UAC elevation not required (copies to user folder)
Linux:   User directory write access required
macOS:   App code signature validation occurs
```

---

## Monitoring & Analytics (Optional)

You can add analytics to track updates:

```dart
// In UpdateService, add analytics:
Future<void> checkForUpdates() async {
  // Log: User has active app
  _analytics.logEvent('update_check_started');
  
  // When update found:
  _analytics.logEvent('update_available', 
    parameters: {'version': _newVersion}
  );
}
```

---

## Future Enhancements

Consider adding:

- [ ] Delta updates (only changed files)
- [ ] Optional vs. required updates
- [ ] Update scheduling (download at night)
- [ ] Rollback capability
- [ ] Multi-platform builds (macOS, iOS)
- [ ] Update stats dashboard
- [ ] A/B testing framework

---

## Support & Resources

- **Flutter Docs**: https://flutter.dev/docs
- **GitHub Actions**: https://docs.github.com/en/actions
- **Update Patterns**: https://en.wikipedia.org/wiki/Software_update#Approaches
- **Security Best Practices**: https://owasp.org/www-community/attacks/mitm

---

**Made with ❤️ for Stellar Forge**  
Last Updated: 2026-02-08
