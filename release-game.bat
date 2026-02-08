@echo off
REM One-command release script for Windows users
REM Usage: release-game.bat 0.2.0 "Your release message"

setlocal enabledelayedexpansion

if "%~1"=="" (
    echo.
    echo ╔════════════════════════════════════════════════════════╗
    echo ║         Stellar Forge Release Helper for Windows       ║
    echo ╚════════════════════════════════════════════════════════╝
    echo.
    echo Usage: release-game.bat VERSION [MESSAGE]
    echo.
    echo Examples:
    echo   release-game.bat 0.2.0
    echo   release-game.bat 0.2.0 "Added new gameplay features"
    echo.
    exit /b 1
)

set VERSION=%~1
set MESSAGE=%~2
if "!MESSAGE!"=="" set MESSAGE=Release v!VERSION!

echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║   Creating Release: Stellar Forge v!VERSION!
echo ╚════════════════════════════════════════════════════════╝
echo.

REM Run PowerShell script
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "stellar_forge_flutter\scripts\create-release.ps1" -Version "%VERSION%" -Message "%MESSAGE%"

if errorlevel 1 (
    echo.
    echo Error creating release!
    exit /b 1
)

echo.
echo Done! Your release is ready.
echo.
pause
