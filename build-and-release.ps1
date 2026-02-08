#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Complete build and release automation for Stellar Forge
    Builds Windows app, packages it, creates release, and pushes to GitHub
.EXAMPLE
    .\build-and-release.ps1 -Version "0.2.0" -Message "Added new features"
    .\build-and-release.ps1 -Version "0.2.0"  # Uses default message
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Version,
    
    [Parameter(Mandatory=$false)]
    [string]$Message = "Release v$Version",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBuild,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipPush
)

# Colors
$SuccessColor = @{ ForegroundColor = "Green" }
$InfoColor = @{ ForegroundColor = "Cyan" }
$WarningColor = @{ ForegroundColor = "Yellow" }
$ErrorColor = @{ ForegroundColor = "Red" }

$startTime = Get-Date

Write-Host "`n" "@" * 60 @InfoColor
Write-Host "[BUILD & RELEASE] Stellar Forge v$Version" @InfoColor
Write-Host "@" * 60 "@n" @InfoColor

# ============================================================
# STEP 1: VALIDATE ENVIRONMENT
# ============================================================
Write-Host "`n[STEP 1] Validating environment..." @InfoColor

# Check Flutter
$flutterCheck = flutter doctor --no-analytics 2>&1 | Where-Object { $_ -like "*Flutter*" }
if (-not $flutterCheck) {
    Write-Host "[ERROR] Flutter not found! Install Flutter first." @ErrorColor
    exit 1
}
Write-Host "[OK] Flutter SDK found" @SuccessColor

# Check version format
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    Write-Host "[ERROR] Invalid version format. Use X.Y.Z (e.g., 0.2.0)" @ErrorColor
    exit 1
}
Write-Host "[OK] Version format valid" @SuccessColor

# Check if in git repo
if (!(Test-Path ".\.git")) {
    Write-Host "[ERROR] Not in a Git repository!" @ErrorColor
    exit 1
}
Write-Host "[OK] Git repository found" @SuccessColor

# ============================================================
# STEP 2: CLEAN PREVIOUS BUILDS
# ============================================================
Write-Host "`n[STEP 2] Cleaning previous builds..." @InfoColor

Push-Location "stellar_forge_flutter"
$buildDir = "build\windows\x64\runner\Release"

if (Test-Path $buildDir) {
    Write-Host "[*] Removing old build artifacts..."
    Remove-Item $buildDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Build directory cleaned" @SuccessColor
} else {
    Write-Host "[OK] No previous build found" @SuccessColor
}

Pop-Location

# ============================================================
# STEP 3: BUILD FLUTTER WINDOWS APP
# ============================================================
if (-not $SkipBuild) {
    Write-Host "`n[STEP 3] Building Windows release app..." @InfoColor
    Write-Host "[*] This may take 2-5 minutes..." @WarningColor
    
    Push-Location "stellar_forge_flutter"
    
    # Get dependencies
    Write-Host "[*] Getting Flutter dependencies..."
    $pubResult = flutter pub get 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to get dependencies!" @ErrorColor
        Write-Host $pubResult
        exit 1
    }
    
    # Build Windows app
    Write-Host "[*] Building Flutter Windows app in Release mode..."
    $buildResult = flutter build windows --release 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Build failed!" @ErrorColor
        Write-Host $buildResult | Select-Object -Last 20
        Pop-Location
        exit 1
    }
    
    if (-not (Test-Path $buildDir)) {
        Write-Host "[ERROR] Build output not found at expected location!" @ErrorColor
        Pop-Location
        exit 1
    }
    
    Write-Host "[OK] Windows app built successfully" @SuccessColor
    Pop-Location
} else {
    Write-Host "`n[STEP 3] Skipping build (--SkipBuild flag set)" @WarningColor
    Write-Host "[*] Using existing build from: $buildDir" @InfoColor
}

# ============================================================
# STEP 4: CREATE RELEASE PACKAGE
# ============================================================
Write-Host "`n[STEP 4] Creating release package..." @InfoColor

$packageName = "stellar-forge-windows-v$Version"
$packageZip = "$packageName.zip"
$tempPackageDir = "temp_package_$([guid]::NewGuid().ToString().Substring(0, 8))"

try {
    # Create temp directory for packaging
    if (Test-Path $tempPackageDir) {
        Remove-Item $tempPackageDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempPackageDir | Out-Null
    
    # Copy build output
    Write-Host "[*] Packaging game files..."
    $sourceDir = "stellar_forge_flutter\build\windows\x64\runner\Release"
    $destDir = "$tempPackageDir\stellar-forge"
    
    Copy-Item -Path $sourceDir -Destination $destDir -Recurse -Force
    Write-Host "[OK] Game files packaged" @SuccessColor
    
    # Create ZIP file
    Write-Host "[*] Creating ZIP archive..."
    if (Test-Path $packageZip) {
        Remove-Item $packageZip -Force
    }
    
    # Use PowerShell's Compress-Archive
    Compress-Archive -Path $tempPackageDir\* -DestinationPath $packageZip -Force
    $fileSize = (Get-Item $packageZip).Length / 1MB
    Write-Host "[OK] Created $packageZip ($('{0:N1}' -f $fileSize) MB)" @SuccessColor
    
} catch {
    Write-Host "[ERROR] Failed to create package: $_" @ErrorColor
    exit 1
} finally {
    # Cleanup temp directory
    if (Test-Path $tempPackageDir) {
        Remove-Item $tempPackageDir -Recurse -Force
    }
}

# ============================================================
# STEP 5: CREATE GIT RELEASE
# ============================================================
Write-Host "`n[STEP 5] Creating Git release..." @InfoColor

# Check for uncommitted changes
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "[WARNING] You have uncommitted changes:" @WarningColor
    Write-Host $gitStatus
    $response = Read-Host "Commit changes before release? (y/n)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        git add -A
        git commit -m "Pre-release commit for v$Version"
        Write-Host "[OK] Changes committed" @SuccessColor
    }
}

# Update version in pubspec.yaml
Write-Host "[*] Updating version in pubspec.yaml..."
$pubspecPath = "stellar_forge_flutter\pubspec.yaml"
$pubspecContent = Get-Content $pubspecPath -Raw
$newPubspecContent = $pubspecContent -replace 'version:\s*[0-9.]+(?:\+\d+)?', "version: $Version"
$newPubspecContent | Out-File -FilePath $pubspecPath -Encoding UTF8
Write-Host "[OK] Version updated to $Version" @SuccessColor

# Commit version bump
git add stellar_forge_flutter/pubspec.yaml
git commit -m "chore: bump version to $Version"
Write-Host "[OK] Version commit created" @SuccessColor

# Create git tag
Write-Host "[*] Creating git tag v$Version..."
git tag -a "v$Version" -m "$Message"
Write-Host "[OK] Git tag created" @SuccessColor

# ============================================================
# STEP 6: PUSH TO GITHUB
# ============================================================
if (-not $SkipPush) {
    Write-Host "`n[STEP 6] Pushing to GitHub..." @InfoColor
    
    Write-Host "[*] Pushing commits..."
    $pushResult = git push origin master:main 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to push commits!" @ErrorColor
        Write-Host $pushResult
        Write-Host ""
        Write-Host "[TIP] Try manually pushing with: git push origin master:main" @WarningColor
    } else {
        Write-Host "[OK] Commits pushed" @SuccessColor
    }
    
    Write-Host "[*] Pushing tag (triggers GitHub Actions build)..."
    $tagPush = git push origin v$Version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to push tag!" @ErrorColor
        Write-Host $tagPush
    } else {
        Write-Host "[OK] Tag pushed - GitHub Actions build triggered!" @SuccessColor
    }
} else {
    Write-Host "`n[STEP 6] Skipping push (--SkipPush flag set)" @WarningColor
    Write-Host "[*] Manually push with:" @InfoColor
    Write-Host "    git push origin master:main" @InfoColor
    Write-Host "    git push origin v$Version" @InfoColor
}

# ============================================================
# STEP 7: SUMMARY
# ============================================================
$duration = (Get-Date) - $startTime
$durationStr = "{0:mm}m {0:ss}s" -f $duration

Write-Host "`n" "@" * 60 @SuccessColor
Write-Host "[SUCCESS] Release v$Version Complete!" @SuccessColor
Write-Host "@" * 60 "@n" @SuccessColor

Write-Host "Release Package:" @InfoColor
Write-Host "  File: $packageZip" @InfoColor
Write-Host "  Size: $('{0:N1}' -f ((Get-Item $packageZip).Length / 1MB)) MB" @InfoColor

Write-Host "`nRelease Info:" @InfoColor
Write-Host "  Version: $Version" @InfoColor
Write-Host "  Message: $Message" @InfoColor
Write-Host "  Duration: $durationStr" @InfoColor

Write-Host "`nNext Steps:" @InfoColor
Write-Host "  1. Monitor build: https://github.com/runepro123/stellar-forge/actions" @InfoColor
Write-Host "  2. Check release: https://github.com/runepro123/stellar-forge/releases/tag/v$Version" @InfoColor
Write-Host "  3. Users get auto-update notification on next game launch!" @SuccessColor

Write-Host ""
