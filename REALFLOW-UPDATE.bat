@echo off
REM ============================================================================
REM   RealFlow - SMART UPDATE (works even after folder delete + fresh extract)
REM
REM   USE THIS FILE FOR EVERY UPDATE:
REM     1. Delete old project folder (or replace files - both work)
REM     2. Extract fresh ZIP from GitHub
REM     3. Right-click this .bat -> Run as administrator
REM     4. Done!
REM
REM   The script automatically:
REM     - Restores .env from safe backup (C:\ProgramData\RealFlow\.env)
REM     - Reuses existing admin password / secrets
REM     - Preserves Cloudflare tunnel & MongoDB data
REM     - Just rebuilds containers with new code
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
title RealFlow - Smart Update

echo.
echo ============================================================================
echo   RealFlow - SMART UPDATE
echo ============================================================================
echo   Project folder: %~dp0
echo ============================================================================
echo.

REM -- Verify folder structure ------------------------------------------------
if not exist "%~dp0docker-compose.yml" (
    echo [ERROR] docker-compose.yml not found here!
    echo This .bat must sit inside the extracted RealFlow project folder.
    pause
    exit /b 1
)

REM -- SMART RESTORE: if .env missing, restore from safe backup --------------
if not exist "%~dp0.env" (
    if exist "C:\ProgramData\RealFlow\.env" (
        echo [Smart Restore] .env missing - restoring from backup...
        copy /Y "C:\ProgramData\RealFlow\.env" "%~dp0.env" >nul
        echo                 .env restored from C:\ProgramData\RealFlow\.env
        echo.
    ) else (
        echo [WARNING] No .env found and no backup exists.
        echo This appears to be a FIRST-TIME install.
        echo.
        echo Please use REALFLOW-SETUP.bat instead for first-time setup.
        pause
        exit /b 1
    )
)

REM -- Verify Docker is running ----------------------------------------------
echo [1/6] Checking Docker engine...
docker info >nul 2>&1
if errorlevel 1 (
    echo       Docker is NOT running. Starting Docker Desktop...
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    set /a WAITED=0
    :wait_docker
    timeout /t 5 /nobreak >nul
    set /a WAITED+=5
    docker info >nul 2>&1
    if errorlevel 1 (
        if %WAITED% GEQ 120 (
            echo       [ERROR] Docker did not start in 2 min. Open it manually.
            pause
            exit /b 1
        )
        echo       waiting... ^(%WAITED%s^)
        goto wait_docker
    )
)
echo       Docker engine running.

REM -- Stop existing containers ----------------------------------------------
echo.
echo [2/6] Stopping existing containers...
docker compose stop 2>nul
echo       Done.

REM -- Force-cleanup any stuck containers by name ----------------------------
echo.
echo [3/6] Cleaning up stuck containers...
docker rm -f realflow-mongo realflow-backend realflow-frontend 2>nul >nul
echo       Done.

REM -- Rebuild and restart with new code -------------------------------------
echo.
echo [4/6] Rebuilding containers with new code (3-5 min)...
echo.
docker compose up -d --build --force-recreate

if errorlevel 1 (
    echo.
    echo [ERROR] docker compose up failed!
    echo Try running REALFLOW-SETUP.bat for a full reinstall.
    pause
    exit /b 1
)

REM -- Wait for backend health check -----------------------------------------
echo.
echo [5/6] Waiting for backend to be ready...
set /a CHECK=0
:health_check
timeout /t 5 /nobreak >nul
set /a CHECK+=5
powershell -NoProfile -Command "try { (Invoke-WebRequest http://localhost:8001/health -UseBasicParsing -TimeoutSec 3).StatusCode } catch { 0 }" > %TEMP%\rfhealth.txt 2>nul
set /p STATUS=<%TEMP%\rfhealth.txt
del %TEMP%\rfhealth.txt 2>nul
if "%STATUS%"=="200" goto health_ok
if %CHECK% GEQ 90 (
    echo       Backend not healthy after 90s - check 'docker logs realflow-backend'
    goto done
)
echo       still warming up... ^(%CHECK%s^)
goto health_check

:health_ok
echo       Backend is healthy!

:done

REM -- Update backup with current .env (in case user changed something) -----
echo.
echo [6/6] Backing up .env for next update...
if not exist "C:\ProgramData\RealFlow\" mkdir "C:\ProgramData\RealFlow"
copy /Y "%~dp0.env" "C:\ProgramData\RealFlow\.env" >nul
echo       Backup saved.

echo.
echo Container status:
docker ps --filter "name=realflow-" --format "table {{.Names}}\t{{.Status}}"
echo.

echo Quick health test:
curl -s http://localhost:8001/health
echo.
echo.
echo ============================================================================
echo   UPDATE COMPLETE!
echo.
echo   What was preserved (auto-restored from C:\ProgramData\RealFlow\.env):
echo     - Admin email and password
echo     - JWT secrets and tokens
echo     - Cloudflare tunnel ^(Windows service^)
echo     - MongoDB data ^(Docker volume^)
echo.
echo   What was updated:
echo     - Application code ^(backend + frontend^)
echo.
echo   Open https://realflow.online and refresh ^(Ctrl+F5^).
echo ============================================================================
echo.
pause
endlocal
