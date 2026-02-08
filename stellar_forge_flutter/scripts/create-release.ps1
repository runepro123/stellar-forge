#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Create a new Stellar Forge release with one command
.EXAMPLE
    .\create-release.ps1 -Version "0.2.0"
    .\create-release.ps1 -Version "0.2.0" -Message "Added multiplayer support"
    .\create-release.ps1 -Version "0.2.0" -Draft  # Create as draft only
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Version,
    
    [Parameter(Mandatory=$false)]
    [string]$Message = "Release v$Version",
    
    [Parameter(Mandatory=$false)]
    [switch]$Draft,
    
    [Parameter(Mandatory=$false)]
    [switch]$PreRelease,
    
    [Parameter(Mandatory=$false)]
    [switch]$NoCommit
)

# Colors
$SuccessColor = @{ ForegroundColor = "Green" }
$InfoColor = @{ ForegroundColor = "Cyan" }
$WarningColor = @{ ForegroundColor = "Yellow" }
$ErrorColor = @{ ForegroundColor = "Red" }

Write-Host "`n========================================================" @InfoColor
Write-Host "[*] Creating Release: Stellar Forge v$Version" @InfoColor
Write-Host "========================================================`n" @InfoColor

# Validate version format
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    Write-Host "[ERROR] Invalid version format. Use semantic versioning (e.g., 1.2.3)" @ErrorColor
    exit 1
}

# Check if in git repository
if (!(Test-Path ".\.git")) {
    Write-Host "[ERROR] Not in a Git repository!" @ErrorColor
    Write-Host "   Run this from the stellar-forge repository root" @ErrorColor
    exit 1
}

# Check if tag already exists
$existingTag = git tag -l "v$Version" 2>$null
if ($existingTag) {
    Write-Host "[ERROR] Tag v$Version already exists!" @ErrorColor
    Write-Host "   Use a different version number" @ErrorColor
    exit 1
}

# Get current git status
$gitStatus = git status --porcelain
if ($gitStatus -and !$NoCommit) {
    Write-Host "[WARNING] You have uncommitted changes:" @WarningColor
    Write-Host $gitStatus @WarningColor
    Write-Host ""
    $response = Read-Host "Commit these changes? (y/n)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        git add -A
        git commit -m "Pre-release commit for v$Version"
        Write-Host "[OK] Changes committed" @SuccessColor
    } else {
        Write-Host "[WARNING] Proceeding with uncommitted changes" @WarningColor
    }
}

# Update pubspec.yaml
Write-Host "[*] Updating version in pubspec.yaml..." @InfoColor
$pubspecPath = ".\stellar_forge_flutter\pubspec.yaml"

if (!(Test-Path $pubspecPath)) {
    Write-Host "[ERROR] pubspec.yaml not found!" @ErrorColor
    exit 1
}

$pubspecContent = Get-Content $pubspecPath -Raw
$newPubspecContent = $pubspecContent -replace 'version:\s*[0-9.]+(?:\+\d+)?', "version: $Version"

if ($pubspecContent -eq $newPubspecContent) {
    Write-Host "[ERROR] Could not update version in pubspec.yaml" @ErrorColor
    exit 1
}

$newPubspecContent | Out-File -FilePath $pubspecPath -Encoding UTF8
Write-Host "[OK] Updated version to $Version" @SuccessColor

# Commit version bump
if (!$NoCommit) {
    Write-Host "[*] Committing version update..." @InfoColor
    git add stellar_forge_flutter/pubspec.yaml
    git commit -m "chore: bump version to $Version"
    Write-Host "[OK] Committed version bump" @SuccessColor
}

# Create tag
Write-Host "[*] Creating git tag..." @InfoColor
$tagMessage = "$Message"
if ($PreRelease) {
    $tagMessage = "[PRE-RELEASE] $tagMessage"
}
if ($Draft) {
    $tagMessage = "[DRAFT] $tagMessage"
}

git tag -a "v$Version" -m "$tagMessage"
Write-Host "[OK] Created tag: v$Version" @SuccessColor

# Show next steps
Write-Host "`n========================================================" @SuccessColor
Write-Host "[SUCCESS] Release Prepared!" @SuccessColor
Write-Host "========================================================`n" @SuccessColor

Write-Host "[*] To publish this release:" @InfoColor
Write-Host ""
Write-Host "  Step 1 - Push commits:" @InfoColor
Write-Host "    git push origin main" @InfoColor
Write-Host ""
Write-Host "  Step 2 - Push tag (triggers build):" @InfoColor
Write-Host "    git push origin v$Version" @InfoColor
Write-Host ""

Write-Host "[*] Monitor the build:" @InfoColor
$gitConfig = git config --get remote.origin.url
if ($gitConfig) {
    $repoMatch = $gitConfig -match '(?:https://github.com/|git@github.com:)([^/]+)/([^/.]+)'
    if ($repoMatch) {
        $user = $matches[1]
        $repo = $matches[2] -replace '\.git$', ''
        Write-Host "  https://github.com/$user/$repo/actions" @InfoColor
        Write-Host ""
        Write-Host "[*] After build completes (5-10 mins):" @InfoColor
        Write-Host "  https://github.com/$user/$repo/releases/tag/v$Version" @InfoColor
    }
}

Write-Host ""
Write-Host "Release Info:" @InfoColor
Write-Host "  Version: $Version" @InfoColor
Write-Host "  Message: $Message" @InfoColor
if ($Draft) {
    Write-Host "  Status: DRAFT (not auto-published)" @WarningColor
}
if ($PreRelease) {
    Write-Host "  Status: PRE-RELEASE" @WarningColor
}

Write-Host ""
Write-Host "========================================================`n" @SuccessColor
