@echo off
REM ============================================================================
REM   RealFlow - ONE CLICK DEPLOY (pre-configured for amna00661226-create)
REM   Domain     : realflow.online
REM   Admin Email: admin@realflow.online
REM   Repo       : https://github.com/amna00661226-create/realflow-amna
REM
REM   Just double-click this file. Everything else is automatic.
REM ============================================================================

setlocal

REM -- Self-elevate to Administrator ------------------------------------------
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
title RealFlow - One Click Deploy

REM -- Launch the embedded PowerShell installer -------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:REALFLOW_DOMAIN='realflow.online'; $env:REALFLOW_ADMIN_EMAIL='admin@realflow.online'; $env:REALFLOW_GITHUB_OWNER='amna00661226-create'; $env:REALFLOW_GITHUB_REPO='realflow-amna'; $env:REALFLOW_BRANCH='main'; irm https://raw.githubusercontent.com/amna00661226-create/realflow-amna/main/ONECLICK.ps1 | iex"

echo.
echo ============================================================================
echo   Installer finished. Press any key to close this window.
echo ============================================================================
pause >nul
endlocal
