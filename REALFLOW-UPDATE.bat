@echo off
REM ============================================================================
REM   RealFlow - QUICK UPDATE (for code changes only)
REM
REM   USE THIS WHEN:
REM     - You downloaded a new ZIP from GitHub with code changes
REM     - You want to apply backend/frontend code updates
REM     - You DON'T want to re-do Cloudflare setup or change admin password
REM
REM   HOW TO USE:
REM     1. Download fresh ZIP from GitHub
REM     2. Extract to your existing project folder (REPLACE files when asked)
REM        OR extract to same location, choose "Replace files in destination"
REM     3. Right-click this .bat -> Run as administrator
REM     4. Wait 3-5 minutes - automatic rebuild and restart
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
title RealFlow - Quick Update

echo.
echo ============================================================================
echo   RealFlow - QUICK UPDATE (code refresh)
echo ============================================================================
echo   Project folder: %~dp0
echo ============================================================================
echo.

REM -- Verify folder structure ------------------------------------------------
if not exist "%~dp0docker-compose.yml" (
    echo [ERROR] docker-compose.yml not found in this folder!
    echo This .bat must sit inside the extracted RealFlow project folder.
    pause
    exit /b 1
)

REM -- Check .env exists (else this is a fresh install, not an update) -------
if not exist "%~dp0.env" (
    echo [WARNING] .env file missing!
    echo.
    echo This appears to be a FRESH install, not an update.
    echo For first-time setup use REALFLOW-SETUP.bat instead.
    echo.
    echo If you just extracted a new ZIP to a NEW folder ^(not the existing one^),
    echo the .env didn't carry over. Either:
    echo   A^) Copy .env from your previous project folder to here
    echo   B^) Run REALFLOW-SETUP.bat to create a new .env ^(new password^)
    echo.
    pause
    exit /b 1
)

REM -- Verify Docker is running ----------------------------------------------
echo [1/5] Checking Docker engine...
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

REM -- Stop existing containers (preserves .env, volumes, mongo data) --------
echo.
echo [2/5] Stopping existing containers...
docker compose stop 2>nul
echo       Done.

REM -- Force-cleanup any stuck containers by name ----------------------------
echo.
echo [3/5] Cleaning up stuck containers...
docker rm -f realflow-mongo realflow-backend realflow-frontend 2>nul >nul
echo       Done.

REM -- Rebuild and restart with new code -------------------------------------
echo.
echo [4/5] Rebuilding and starting containers (3-5 min)...
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
echo [5/5] Waiting for backend to be ready...
set /a CHECK=0
:health_check
timeout /t 5 /nobreak >nul
set /a CHECK+=5
powershell -NoProfile -Command "try { (Invoke-WebRequest http://localhost:8001/health -UseBasicParsing -TimeoutSec 3).StatusCode } catch { 0 }" > %TEMP%\rfhealth.txt 2>nul
set /p STATUS=<%TEMP%\rfhealth.txt
del %TEMP%\rfhealth.txt 2>nul
if "%STATUS%"=="200" goto health_ok
if %CHECK% GEQ 90 (
    echo       Backend not healthy after 90s - check logs with: docker logs realflow-backend
    goto done
)
echo       still warming up... ^(%CHECK%s^)
goto health_check

:health_ok
echo       Backend is healthy!

:done
echo.
echo Container status:
docker ps --filter "name=realflow-" --format "table {{.Names}}\t{{.Status}}"
echo.

echo Quick test:
curl -s http://localhost:8001/health
echo.
echo.
echo ============================================================================
echo   UPDATE COMPLETE!
echo.
echo   Your existing .env, admin password, Cloudflare tunnel, and MongoDB data
echo   are all preserved. Only the application code was refreshed.
echo.
echo   Open https://realflow.online and refresh ^(Ctrl+F5^) to see changes.
echo ============================================================================
echo.
pause
endlocal
