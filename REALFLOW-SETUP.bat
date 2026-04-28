@echo off
REM ============================================================================
REM   RealFlow - ULTIMATE ONE-CLICK SETUP (v2.0 - Bulletproof)
REM
REM   This version fixes EVERY issue discovered during real-world deployment:
REM     - Container name conflicts (auto-cleanup before every start)
REM     - Cloudflared service registration failures (registry + service cleanup)
REM     - Admin password not updating (force-recreate containers on .env change)
REM     - Docker Desktop not running (auto-start + wait)
REM     - Registry key "already exists" errors (clean pre-install)
REM
REM   USAGE:
REM     1. Extract RealFlow ZIP anywhere (e.g., C:\RealFlow)
REM     2. Put this .bat in the extracted folder (already included)
REM     3. Right-click -> Run as administrator
REM     4. Follow prompts (first time only: domain/email/password)
REM     5. All subsequent runs: ZERO prompts, pure automation
REM ============================================================================

setlocal EnableDelayedExpansion

REM -- Self-elevate to Administrator ------------------------------------------
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
title RealFlow - Ultimate Setup v2.0

echo.
echo ============================================================================
echo   RealFlow - ULTIMATE ONE-CLICK SETUP v2.0
echo ============================================================================
echo   Project folder: %~dp0
echo ============================================================================
echo.

REM -- Verify folder structure ------------------------------------------------
if not exist "%~dp0docker-compose.yml" (
    echo [ERROR] docker-compose.yml not found in this folder!
    echo.
    echo This .bat MUST be inside the extracted RealFlow project folder.
    echo Expected files/folders:  backend\  frontend\  deployment\  docker-compose.yml
    echo.
    pause
    exit /b 1
)

REM -- Launch the bulletproof PowerShell installer -----------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deployment\home-pc\ULTIMATE-SETUP.ps1"
set "SETUP_EXIT=%errorlevel%"

echo.
echo ============================================================================
if %SETUP_EXIT% EQU 0 (
    echo   SUCCESS! RealFlow is LIVE. Check Desktop\realflow-LOGIN.txt for credentials.
) else (
    echo   Setup encountered errors. See messages above.
)
echo ============================================================================
echo.
pause
endlocal
