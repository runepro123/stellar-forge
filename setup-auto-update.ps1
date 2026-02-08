#!/usr/bin/env pwsh

<#
.SYNOPSIS
    One-command setup for Stellar Forge auto-update system
.DESCRIPTION
    Configures GitHub releases and auto-update functionality
.EXAMPLE
    .\setup-auto-update.ps1 -GitHubUser "your-username" -GitHubRepo "your-repo" -GitHubToken "ghp_xxx"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$GitHubUser = "runepro123",
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubRepo = "stellar-forge",
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubToken,
    
    [Parameter(Mandatory=$false)]
    [string]$InitialVersion = "0.1.0"
)

# Colors for output
$ErrorColor = @{ ForegroundColor = "Red" }
$SuccessColor = @{ ForegroundColor = "Green" }
$InfoColor = @{ ForegroundColor = "Cyan" }
$WarningColor = @{ ForegroundColor = "Yellow" }

Write-Host "`n═══════════════════════════════════════════════════════" @InfoColor
Write-Host "🚀 Stellar Forge auto-update system setup" @InfoColor
Write-Host "═══════════════════════════════════════════════════════`n" @InfoColor

# Check if git is installed
Write-Host "Checking prerequisites..." @InfoColor
if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Git is not installed. Please install Git first." @ErrorColor
    exit 1
}

$gitVersion = git --version
Write-Host "✓ Git found: $gitVersion" @SuccessColor

# Check if we're in the right directory
if (!(Test-Path "./stellar_forge_flutter")) {
    Write-Host "❌ This script must be run from the stellar-forge repository root." @ErrorColor
    Write-Host "   (stellar_forge_flutter folder not found)" @ErrorColor
    exit 1
}

Write-Host "✓ Found stellar_forge_flutter directory" @SuccessColor

# Check if GitHub token is provided
if (-not $GitHubToken) {
    Write-Host "`n⚠️  No GitHub token provided!" @WarningColor
    Write-Host "To enable automatic releases, you need a GitHub token.`n" @WarningColor
    
    Write-Host "Steps to get a GitHub token:" @InfoColor
    Write-Host "1. Go to: https://github.com/settings/tokens" @InfoColor
    Write-Host "2. Click 'Generate new token (classic)'" @InfoColor
    Write-Host "3. Give it these permissions:" @InfoColor
    Write-Host "   - repo (Full control of private repositories)" @InfoColor
    Write-Host "   - workflow (Update GitHub Action workflows)" @InfoColor
    Write-Host "4. Click 'Generate token' and copy it" @InfoColor
    Write-Host ""
    
    $GitHubToken = Read-Host "Paste your GitHub token (or press Enter to skip)"
}

# Initialize git if not already initialized
if (!(Test-Path "./.git")) {
    Write-Host "`nInitializing Git repository..." @InfoColor
    git init
    git add .
    git commit -m "Initial commit: Stellar Forge with auto-update system"
    Write-Host "✓ Git repository initialized" @SuccessColor
}

# Check if repository is configured
$remoteUrl = git config --get remote.origin.url
if (-not $remoteUrl) {
    Write-Host "`n⚠️  Git remote not configured" @WarningColor
    Write-Host "Configure remote manually with: git remote add origin https://github.com/$GitHubUser/$GitHubRepo.git" @InfoColor
} else {
    Write-Host "`n✓ Git remote configured: $remoteUrl" @SuccessColor
}

# Create initial release tag
$latestTag = git describe --tags 2>/dev/null
if (-not $?) {
    Write-Host "`nCreating initial release tag..." @InfoColor
    git tag -a "v$InitialVersion" -m "Initial release - Stellar Forge v$InitialVersion"
    Write-Host "✓ Created tag: v$InitialVersion" @SuccessColor
    Write-Host "  Push it with: git push origin v$InitialVersion" @InfoColor
} else {
    Write-Host "`n✓ Found existing tags" @SuccessColor
}

# Setup repository secrets if token provided
if ($GitHubToken) {
    Write-Host "`nConfiguring GitHub secrets..." @InfoColor
    Write-Host "Note: Secrets must be configured on GitHub.com directly" @WarningColor
    Write-Host "`nVisit: https://github.com/$GitHubUser/$GitHubRepo/settings/secrets/actions" @InfoColor
    Write-Host "And add this secret (if not already set):" @InfoColor
    Write-Host "  Name: GITHUB_TOKEN" @InfoColor
    Write-Host "  Value: <your token>" @InfoColor
}

# Create version management files
Write-Host "`nSetting up version management..." @InfoColor

# Update pubspec.yaml with correct version
$pubspecPath = "./stellar_forge_flutter/pubspec.yaml"
$pubspecContent = Get-Content $pubspecPath -Raw

# Extract version from pubspec if it exists, otherwise use initial version
$versionMatch = $pubspecContent | Select-String -Pattern "^version:\s*([0-9.]+(?:\+\d+)?)" -List
if ($versionMatch.Matches.Count -gt 0) {
    $currentVersion = $versionMatch.Matches[0].Groups[1].Value
    Write-Host "✓ Current version in pubspec.yaml: $currentVersion" @SuccessColor
} else {
    Write-Host "⚠️  Could not find version in pubspec.yaml" @WarningColor
}

# Create update_config.json for reference
$configContent = @{
    githubUser = $GitHubUser
    githubRepo = $GitHubRepo
    autoUpdate = $true
    updateCheckInterval = 3600  # seconds
    supportedPlatforms = @("windows", "linux")
    releaseChannel = "stable"
} | ConvertTo-Json -Indent 2

$configContent | Out-File -FilePath "./stellar_forge_flutter/update_config.json" -Encoding UTF8
Write-Host "✓ Created update_config.json" @SuccessColor

# Create a release script
$releaseScriptContent = @'
#!/usr/bin/env pwsh

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [Parameter(Mandatory=$false)]
    [string]$Message = "Release v$Version"
)

Write-Host "Preparing release v$Version..."

# Update version in pubspec.yaml
$pubspecPath = "./stellar_forge_flutter/pubspec.yaml"
$pubspecContent = Get-Content $pubspecPath -Raw
$pubspecContent = $pubspecContent -replace 'version:\s*[0-9.]+\+\d+', "version: $Version+1"
$pubspecContent | Out-File -FilePath $pubspecPath -Encoding UTF8

Write-Host "✓ Updated pubspec.yaml to version $Version"

# Commit changes
git add stellar_forge_flutter/pubspec.yaml
git commit -m "bump: Release v$Version"

# Create tag
git tag -a "v$Version" -m "$Message"
Write-Host "✓ Created tag v$Version"

Write-Host "`n📤 To release:"
Write-Host "  git push origin main"
Write-Host "  git push origin v$Version"
Write-Host ""
Write-Host "This will trigger the GitHub Actions workflow to build and release!"
'@

$releaseScriptPath = "./scripts/create-release.ps1"
New-Item -ItemType Directory -Force -Path "./scripts" | Out-Null
$releaseScriptContent | Out-File -FilePath $releaseScriptPath -Encoding UTF8
Write-Host "✓ Created release script at: $releaseScriptPath" @SuccessColor

# Create comprehensive README for updates
$readmeContent = @"
# 🚀 Stellar Forge Auto-Update System

This setup enables automatic updates for Stellar Forge on Windows and Linux.

## How it works

1. **Automatic Check**: The game checks for updates on startup
2. **Non-blocking Download**: Updates download in the background while you play
3. **Visual Feedback**: A beautiful progress bar shows download and extraction status
4. **User Control**: Users can click "RESTART & UPDATE" when ready, or choose "LATER"
5. **Seamless Apply**: The app restarts and applies the update automatically

## Creating a Release

### Option 1: Using the PowerShell script (Recommended)

\`\`\`powershell
.\scripts\create-release.ps1 -Version "0.2.0" -Message "Added new features"
git push origin main
git push origin v0.2.0
\`\`\`

### Option 2: Manual Release

1. Update version in \`stellar_forge_flutter/pubspec.yaml\`
2. Commit with: \`git commit -m "bump: Release v0.2.0"\`
3. Tag with: \`git tag -a v0.2.0 -m "Release v0.2.0"\`
4. Push with: \`git push origin main\` and \`git push origin v0.2.0\`

## GitHub Actions Workflow

When you push a tag (v*), the GitHub Actions workflow automatically:

1. ✅ Builds the Flutter app for Windows
2. 📦 Packages it as a ZIP file
3. 🏷️ Creates a GitHub Release
4. 📝 Generates release notes from commit history
5. ⬆️ Uploads the build artifact

## Update Configuration

The game is configured to:
- Check for updates: **Every hour** (when launched)
- Download updates: **In the background**
- Show progress: **Beautiful UI overlay**
- Allow gaming: **While updating**

You can modify these in \`lib/update_service.dart\`

## Troubleshooting

### "No update checks happening"
- Ensure your app is built with the correct GitHub user/repo
- Check that releases are published (not as drafts)

### "Updates not downloading"
- Verify GitHub token has proper permissions
- Check firewall/network settings
- Ensure release assets (ZIP files) are properly uploaded

### "Update fails to apply"
- Make sure you have write permissions to the installation directory
- Check Windows/Linux permissions on the executable directory
- Verify the ZIP structure matches the app directory structure

## Configuration

Edit \`lib/update_service.dart\` to change:

\`\`\`dart
final String githubUser = 'runepro123';      // Change to your username
final String githubRepo = 'stellar-forge';    // Change to your repo name
\`\`\`

---

Made with ❤️ for Stellar Forge
"@

$readmeContent | Out-File -FilePath "./AUTO-UPDATE-README.md" -Encoding UTF8
Write-Host "✓ Created AUTO-UPDATE-README.md" @SuccessColor

# Display summary
Write-Host "`n═══════════════════════════════════════════════════════" @SuccessColor
Write-Host "✅ Setup Complete!" @SuccessColor
Write-Host "═══════════════════════════════════════════════════════`n" @SuccessColor

Write-Host "📋 Configuration Summary:" @InfoColor
Write-Host "  Repository: $GitHubUser/$GitHubRepo" @InfoColor
Write-Host "  Initial Version: $InitialVersion" @InfoColor

Write-Host "`n📚 Next Steps:" @InfoColor
Write-Host ""
Write-Host "1. Push your code to GitHub:" @InfoColor
Write-Host "   git push origin main" @InfoColor
Write-Host ""

Write-Host "2. Create your first release:" @InfoColor
Write-Host "   .\scripts\create-release.ps1 -Version '0.1.0'" @InfoColor
Write-Host ""

Write-Host "3. Push the release tag:" @InfoColor
Write-Host "   git push origin v0.1.0" @InfoColor
Write-Host ""

Write-Host "4. Watch the build:" @InfoColor
Write-Host "   https://github.com/$GitHubUser/$GitHubRepo/actions" @InfoColor
Write-Host ""

Write-Host "5. Get your release link:" @InfoColor
Write-Host "   https://github.com/$GitHubUser/$GitHubRepo/releases" @InfoColor
Write-Host ""

Write-Host "📖 For detailed information, see AUTO-UPDATE-README.md" @InfoColor
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════`n" @SuccessColor
"@

$setupScriptPath = "./setup-auto-update.ps1"
$setupScriptContent | Out-File -FilePath $setupScriptPath -Encoding UTF8
Write-Host "✓ Setup script saved for future reference" @SuccessColor

Write-Host "`n🎮 Your game now has automatic updates enabled!`n" @SuccessColor
