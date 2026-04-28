@echo off
REM ============================================================================
REM   RealFlow - CHANGE ADMIN CREDENTIALS
REM
REM   Asks for new admin email + password, updates .env, deletes old admin
REM   from MongoDB, and force-recreates the backend so the new admin is seeded.
REM
REM   USAGE:
REM     1. Put this .bat inside the project folder
REM     2. Right-click -> Run as administrator
REM     3. Enter new email and password when prompted
REM     4. Done! Use new credentials to login.
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
title RealFlow - Change Admin Credentials

echo.
echo ============================================================================
echo   RealFlow - CHANGE ADMIN CREDENTIALS
echo ============================================================================
echo.

if not exist "%~dp0.env" (
    echo [ERROR] .env file not found in this folder.
    echo Run REALFLOW-MAGIC.bat or REALFLOW-SETUP.bat first.
    pause
    exit /b 1
)

REM -- Read current values for display ---------------------------------------
echo Current admin credentials:
powershell -NoProfile -Command "Get-Content '%~dp0.env' | Select-String 'ADMIN_'"
echo.
echo ----------------------------------------------------------------------------

REM -- Prompt new values -----------------------------------------------------
set /p NEW_EMAIL="Enter new admin email: "
if "%NEW_EMAIL%"=="" (
    echo [ERROR] Email cannot be empty.
    pause
    exit /b 1
)

set /p NEW_PASSWORD="Enter new admin password (min 6 chars): "
if "%NEW_PASSWORD%"=="" (
    echo [ERROR] Password cannot be empty.
    pause
    exit /b 1
)

echo.
echo Updating credentials...
echo   Email    : %NEW_EMAIL%
echo   Password : %NEW_PASSWORD%
echo.

REM -- Update .env via PowerShell --------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -Command "$env_file='%~dp0.env'; $c = Get-Content $env_file -Raw; $c = $c -replace '(?m)^ADMIN_EMAIL=.*$', 'ADMIN_EMAIL=%NEW_EMAIL%'; $c = $c -replace '(?m)^ADMIN_PASSWORD=.*$', 'ADMIN_PASSWORD=%NEW_PASSWORD%'; Set-Content -Path $env_file -Value $c -Encoding UTF8; Write-Host '.env updated' -F Green"

REM -- Backup the new .env to safe location ----------------------------------
if not exist "C:\ProgramData\RealFlow\" mkdir "C:\ProgramData\RealFlow"
copy /Y "%~dp0.env" "C:\ProgramData\RealFlow\.env" >nul
echo Backup updated at C:\ProgramData\RealFlow\.env

REM -- Verify Docker is running ----------------------------------------------
docker info >nul 2>&1
if errorlevel 1 (
    echo.
    echo [ERROR] Docker Desktop is not running. Start it and rerun this .bat.
    pause
    exit /b 1
)

REM -- Delete old admin user from MongoDB ------------------------------------
echo.
echo Deleting old admin from MongoDB...
docker exec realflow-mongo mongosh realflow --quiet --eval "db.users.deleteMany({}); db.admin_users.deleteMany({}); print('done')" 2>nul
echo Done.

REM -- Force-recreate backend so it seeds new admin from .env ----------------
echo.
echo Recreating backend container with new credentials...
docker compose up -d --force-recreate backend 2>nul
echo Waiting 25s for admin to be seeded...
timeout /t 25 /nobreak >nul

REM -- Verify backend is healthy ---------------------------------------------
echo.
echo Verifying backend...
powershell -NoProfile -Command "try { (Invoke-WebRequest http://localhost:8001/health -UseBasicParsing -TimeoutSec 5).Content } catch { 'backend may still be starting' }"
echo.

REM -- Update Desktop credentials file ---------------------------------------
powershell -NoProfile -Command "$d = [Environment]::GetFolderPath('Desktop'); $f = Join-Path $d 'realflow-LOGIN.txt'; @'
RealFlow - LOGIN CREDENTIALS (UPDATED)
=======================================
Frontend     : https://realflow.online
Backend API  : https://api.realflow.online

Admin Email    : %NEW_EMAIL%
Admin Password : %NEW_PASSWORD%

(updated on $(Get-Date))
'@ | Set-Content $f -Encoding UTF8; Write-Host \"Desktop\realflow-LOGIN.txt updated\" -F Green"

echo.
echo ============================================================================
echo   ADMIN CREDENTIALS UPDATED!
echo.
echo   New Email    : %NEW_EMAIL%
echo   New Password : %NEW_PASSWORD%
echo.
echo   Browser refresh ^(Ctrl+F5^) and login with new credentials at:
echo   https://realflow.online
echo.
echo   Credentials also saved to: Desktop\realflow-LOGIN.txt
echo ============================================================================
echo.
pause
endlocal
