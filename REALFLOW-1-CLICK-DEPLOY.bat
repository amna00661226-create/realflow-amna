@echo off
REM ============================================================================
REM   RealFlow - ONE CLICK DEPLOY (local folder version)
REM
REM   HOW TO USE:
REM     1. Download ZIP from GitHub -> Extract anywhere (e.g. D:\MyApps\realflow)
REM     2. Put this .bat file INSIDE that extracted folder (it's already there)
REM     3. Double-click this .bat - that's it!
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

REM -- Always work from the folder where this .bat lives -----------------------
cd /d "%~dp0"
title RealFlow - One Click Deploy

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
    echo Please extract the GitHub ZIP completely and put this .bat inside
    echo the extracted folder, then double-click again.
    echo.
    pause
    exit /b 1
)

if not exist "%~dp0deployment\home-pc\setup.ps1" (
    echo [ERROR] deployment\home-pc\setup.ps1 not found!
    echo Your extracted folder seems incomplete. Re-download the ZIP from GitHub
    echo and extract it FULLY ^(not just some files^), then try again.
    echo.
    pause
    exit /b 1
)

REM -- Launch the embedded PowerShell installer from LOCAL files -------------
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ONECLICK.ps1"

echo.
echo ============================================================================
echo   Installer finished. Press any key to close this window.
echo ============================================================================
pause >nul
endlocal
