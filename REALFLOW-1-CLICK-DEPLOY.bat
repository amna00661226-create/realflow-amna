@echo off
REM ============================================================================
REM   RealFlow - ONE CLICK DEPLOY (FINAL version with auto-cleanup)
REM
REM   HOW TO USE:
REM     1. Download ZIP from GitHub -> Extract anywhere
REM     2. Double-click this .bat from inside the extracted folder
REM     3. Wait 15-20 minutes - everything is automatic
REM
REM   Pre-filled values:
REM     Domain     : realflow.online
REM     Admin Email: admin@realflow.online
REM     Password   : auto-generated (shown + saved to Desktop at the end)
REM ============================================================================

setlocal

REM -- Self-elevate to Administrator ------------------------------------------
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

REM -- Always work from the folder where this .bat lives ---------------------
cd /d "%~dp0"
title RealFlow - One Click Deploy

echo.
echo ============================================================================
echo   RealFlow - ONE CLICK DEPLOY
echo ============================================================================
echo   Project folder : %~dp0
echo   Domain         : realflow.online
echo   Admin email    : admin@realflow.online
echo ============================================================================
echo.

REM -- Verify this is actually the RealFlow project folder -------------------
if not exist "%~dp0docker-compose.yml" (
    echo [ERROR] docker-compose.yml not found in this folder!
    echo.
    echo This .bat file MUST be inside the extracted RealFlow project folder.
    echo You should see these files/folders next to this .bat:
    echo    backend\   frontend\   deployment\   docker-compose.yml
    echo.
    pause
    exit /b 1
)

if not exist "%~dp0deployment\home-pc\setup.ps1" (
    echo [ERROR] deployment\home-pc\setup.ps1 not found!
    echo Re-download the ZIP from GitHub and extract it FULLY.
    pause
    exit /b 1
)

REM -- PRE-CLEANUP: remove any stuck containers from previous runs -----------
echo [Pre-step] Cleaning up any stuck containers from previous runs...
docker rm -f realflow-mongo 2>nul
docker rm -f realflow-backend 2>nul
docker rm -f realflow-frontend 2>nul
echo           Done. Proceeding with installer.
echo.

REM -- Launch the PowerShell installer from LOCAL files ----------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ONECLICK.ps1"

echo.
echo ============================================================================
echo   Installer finished. Press any key to close this window.
echo ============================================================================
pause >nul
endlocal
