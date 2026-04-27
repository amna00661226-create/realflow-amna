@echo off
REM ============================================================================
REM   RealFlow - EMERGENCY FIX & RESTART
REM   
REM   Use this when backend isn't working because of container conflicts.
REM   Forcefully removes old containers, then starts fresh.
REM
REM   Double-click this file from inside your extracted project folder.
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
title RealFlow - Fix and Restart

echo.
echo ============================================================================
echo   RealFlow - FIX and RESTART
echo ============================================================================
echo   Project folder: %~dp0
echo.
echo   This will:
echo     1. Forcefully remove any stuck old containers
echo     2. Build and start fresh containers
echo     3. Verify everything is running
echo ============================================================================
echo.

if not exist "%~dp0docker-compose.yml" (
    echo [ERROR] docker-compose.yml not found in this folder.
    echo Place this .bat inside the extracted RealFlow project folder, next to docker-compose.yml.
    echo.
    pause
    exit /b 1
)

REM -- Step 1: Stop + remove any existing containers -------------------------
echo [1/4] Stopping existing containers (if any)...
docker compose down --remove-orphans 2>nul

echo [2/4] Force-removing stuck containers by name...
docker rm -f realflow-mongo 2>nul
docker rm -f realflow-backend 2>nul
docker rm -f realflow-frontend 2>nul
echo       Done.
echo.

REM -- Step 2: Make sure Docker engine is running ----------------------------
echo [3/4] Verifying Docker engine is running...
docker info >nul 2>&1
if errorlevel 1 (
    echo       Docker engine is NOT running. Starting Docker Desktop...
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    echo       Waiting up to 2 minutes for Docker to start...
    set /a WAITED=0
    :wait_docker
    timeout /t 5 /nobreak >nul
    set /a WAITED+=5
    docker info >nul 2>&1
    if errorlevel 1 (
        if %WAITED% GEQ 120 (
            echo       [ERROR] Docker did not start within 2 minutes.
            echo       Open Docker Desktop manually and wait for green "Engine running" status.
            pause
            exit /b 1
        )
        echo       still waiting... ^(%WAITED% s^)
        goto wait_docker
    )
)
echo       Docker engine is running.
echo.

REM -- Step 3: Start containers ---------------------------------------------
echo [4/4] Starting containers (build if needed)...
echo       This may take a few minutes on the first run.
echo.
docker compose up -d --build

if errorlevel 1 (
    echo.
    echo [ERROR] docker compose up failed again. Common causes:
    echo   - Disk space full: free up some space and try again
    echo   - Corrupted image: run "docker system prune -a" then rerun this .bat
    echo   - Docker daemon issue: restart Docker Desktop and rerun
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================================
echo   Containers started! Waiting 30s for backend to warm up...
echo ============================================================================
timeout /t 30 /nobreak >nul

echo.
echo Current container status:
docker ps --filter "name=realflow-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo.

echo Testing local backend health...
powershell -NoProfile -Command "try { $r = Invoke-WebRequest -UseBasicParsing -Uri 'http://localhost:8001/health' -TimeoutSec 5; Write-Host '  LOCAL:  OK -' $r.Content -ForegroundColor Green } catch { Write-Host '  LOCAL:  FAILED - backend may still be starting' -ForegroundColor Yellow }"
echo.

echo Testing public backend (through Cloudflare Tunnel)...
powershell -NoProfile -Command "try { $r = Invoke-WebRequest -UseBasicParsing -Uri 'https://api.realflow.online/health' -TimeoutSec 10; Write-Host '  PUBLIC: OK -' $r.Content -ForegroundColor Green } catch { Write-Host '  PUBLIC: FAILED - tunnel may need a moment, retry in 1 min' -ForegroundColor Yellow }"
echo.

echo ============================================================================
echo   Done! If LOCAL = OK but PUBLIC = FAILED, wait 1 min and refresh:
echo         https://api.realflow.online/health
echo.
echo   If LOCAL = FAILED, check logs with:
echo         deployment\home-pc\logs.bat
echo ============================================================================
echo.
pause
endlocal
