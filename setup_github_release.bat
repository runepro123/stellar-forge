@echo off
setlocal enabledelayedexpansion

:: Check if git is installed
where git >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Git is not installed or not in PATH.
    pause
    exit /b 1
)

:: Get current version from pubspec.yaml
set "VERSION="
for /f "tokens=2 delims=: " %%a in ('findstr "version:" stellar_forge_flutter\pubspec.yaml') do (
    set "VERSION=%%a"
)

if "%VERSION%"=="" (
    echo [ERROR] Could not find version in pubspec.yaml
    pause
    exit /b 1
)

:: Split version at + to get only the tag part
for /f "tokens=1 delims=+" %%a in ("%VERSION%") do set "TAG_VERSION=v%%a"

echo [INFO] Detected version: %TAG_VERSION%

:: Check if git is initialized
if not exist .git (
    echo [INFO] Initializing git repository...
    git init
    git add .
    git commit -m "Initial commit with auto-updater"
)

:: Prompt for GitHub URL if remote doesn't exist
git remote get-url origin >nul 2>nul
if %ERRORLEVEL% neq 0 (
    set /p "REPO_URL=Enter your GitHub Repository URL (e.g. https://github.com/user/repo): "
    if "!REPO_URL!"=="" (
        echo [ERROR] Repository URL is required.
        pause
        exit /b 1
    )
    git remote add origin !REPO_URL!
)

:: Update UpdateService with repository info
for /f "tokens=3 delims=/" %%a in ('git remote get-url origin') do set "DOMAIN=%%a"
for /f "tokens=4,5 delims=/:. " %%a in ('git remote get-url origin') do (
    set "GH_USER=%%a"
    set "GH_REPO=%%b"
)

echo [INFO] Updating UpdateService with Repo: %GH_USER%/%GH_REPO%

:: Use powershell to replace the placeholders in UpdateService
powershell -Command "(gc stellar_forge_flutter\lib\update_service.dart) -replace 'YOUR_GITHUB_USER', '%GH_USER%' -replace 'YOUR_GITHUB_REPO', '%GH_REPO%' | Out-File -encoding utf8 stellar_forge_flutter\lib\update_service.dart"

echo [INFO] Committing changes and pushing tag...
git add stellar_forge_flutter\lib\update_service.dart
git commit -m "Configure auto-updater for %GH_USER%/%GH_REPO%"
git push origin main

:: Create and push tag to trigger GitHub Action
git tag -a %TAG_VERSION% -m "Release %TAG_VERSION%"
git push origin %TAG_VERSION%

echo [SUCCESS] Draft build setup and tag pushed to GitHub.
echo [INFO] The GitHub Action will now build the project and create a release.
pause
