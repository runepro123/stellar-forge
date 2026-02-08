@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo.
    echo Stellar Forge Build and Release Automation
    echo.
    echo Usage: build-and-release.bat VERSION [MESSAGE] [/skip-build] [/skip-push]
    echo.
    echo Examples:
    echo   build-and-release.bat 0.2.0
    echo   build-and-release.bat 0.2.0 "New features"
    echo   build-and-release.bat 0.2.0 "Release message" /skip-push
    echo   build-and-release.bat 0.2.0 "Message" /skip-build /skip-push
    echo.
    exit /b 1
)

set VERSION=%1
set MESSAGE=%~2

cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "build-and-release.ps1" -Version "%VERSION%" -Message "%MESSAGE%" %3 %4

pause
