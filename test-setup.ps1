Write-Host "
=======================================================
Stellar Forge Auto-Update System - Initialization Test 
=======================================================
"

$allGood = $true

# Test 1: Check project structure
Write-Host "Checking project structure..." -ForegroundColor Yellow
$projectFiles = @(
    "stellar_forge_flutter/lib/update_service.dart",
    "stellar_forge_flutter/lib/widgets/update_progress_bar.dart",
    "stellar_forge_flutter/lib/main.dart",
    "stellar_forge_flutter/pubspec.yaml",
    "stellar_forge_flutter/.github/workflows/build-windows.yml",
    "stellar_forge_flutter/scripts/create-release.ps1"
)

foreach ($file in $projectFiles) {
    if (Test-Path $file) {
        Write-Host "  OK: $file" -ForegroundColor Green
    } else {
        Write-Host "  ERROR: MISSING $file" -ForegroundColor Red
        $allGood = $false
    }
}

# Test 2: Check configuration
Write-Host "`nChecking configuration..." -ForegroundColor Yellow
$updateServicePath = "stellar_forge_flutter/lib/update_service.dart"
$content = Get-Content $updateServicePath -Raw

if ($content -match 'final String githubUser') {
    Write-Host "  OK: GitHub user configured" -ForegroundColor Green
} else {
    Write-Host "  WARN: GitHub user not found" -ForegroundColor Yellow
}

if ($content -match 'final String githubRepo') {
    Write-Host "  OK: GitHub repo configured" -ForegroundColor Green
} else {
    Write-Host "  WARN: GitHub repo not found" -ForegroundColor Yellow
}

# Test 3: Check Git
Write-Host "`nChecking Git..." -ForegroundColor Yellow
if (Test-Path "./.git") {
    Write-Host "  OK: Git repository initialized" -ForegroundColor Green
    $remoteUrl = &{ git config --get remote.origin.url } 2>&1
    if ($remoteUrl -and $remoteUrl -notcontains "error") {
        Write-Host "  OK: Remote configured" -ForegroundColor Green
    } else {
        Write-Host "  WARN: No remote configured" -ForegroundColor Yellow
    }
} else {
    Write-Host "  WARN: Git repository not initialized" -ForegroundColor Yellow
}

# Test 4: Check Flutter
Write-Host "`nChecking Flutter..." -ForegroundColor Yellow
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    Write-Host "  OK: Flutter found" -ForegroundColor Green
    $pubspec = Get-Content "stellar_forge_flutter/pubspec.yaml" -Raw
    if ($pubspec -match 'version:') {
        Write-Host "  OK: Version configured in pubspec.yaml" -ForegroundColor Green
    }
} else {
    Write-Host "  ERROR: Flutter not found" -ForegroundColor Red
    $allGood = $false
}

# Test 5: Check docs
Write-Host "`nChecking documentation..." -ForegroundColor Yellow
$docs = @("QUICK-START.md", "SETUP-GUIDE.md", "AUTO-UPDATE-README.md")
foreach ($doc in $docs) {
    if (Test-Path $doc) {
        Write-Host "  OK: $doc" -ForegroundColor Green
    } else {
        Write-Host "  WARN: $doc not found" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`n=======================================================" -ForegroundColor Cyan
if ($allGood) {
    Write-Host "System Ready!" -ForegroundColor Green
    Write-Host "`nNext Steps:`n" -ForegroundColor Green
    Write-Host "  1. Read: SETUP-GUIDE.md" -ForegroundColor White
    Write-Host "  2. Configure GitHub token" -ForegroundColor White
    Write-Host "  3. Run: release-game.bat 0.1.0" -ForegroundColor White
} else {
    Write-Host "Issues Found - See Above" -ForegroundColor Red
}
Write-Host ""
