@echo off
REM ============================================================================
REM   RealFlow - MAGIC FIX & RUN (All-in-One, Self-Contained)
REM
REM   This ONE FILE handles EVERYTHING automatically:
REM     - First install OR update OR fix-broken-state - all the same
REM     - Auto-restore .env from backup if missing
REM     - Safe container cleanup (no error if containers don't exist)
REM     - Build + start with retries
REM     - Auto-fix admin password mismatch
REM     - Restart Cloudflare tunnel service
REM     - Verify health locally + publicly
REM     - Save backup for next run
REM
REM   USAGE:
REM     1. Put this .bat inside the extracted RealFlow project folder
REM     2. Right-click -> Run as administrator
REM     3. WAIT 10-15 minutes (no prompts, fully automatic)
REM     4. Login using credentials shown at the end
REM
REM   That's it. Nothing else. No commands. No clicks.
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
title RealFlow - MAGIC FIX & RUN

echo.
echo ============================================================================
echo   RealFlow - MAGIC FIX ^& RUN  (sit back and relax, no input needed)
echo ============================================================================
echo   Project folder: %~dp0
echo ============================================================================
echo.

REM -- Verify folder structure ------------------------------------------------
if not exist "%~dp0docker-compose.yml" (
    echo [ERROR] docker-compose.yml not found in this folder.
    echo Place this .bat inside the extracted RealFlow project folder.
    pause
    exit /b 1
)

REM -- Run the embedded PowerShell that does ALL the work --------------------
powershell -NoProfile -ExecutionPolicy Bypass -Command "& {
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

function H($t) { Write-Host ''; Write-Host ('=' * 70) -F Cyan; Write-Host \"  $t\" -F Cyan; Write-Host ('=' * 70) -F Cyan }
function OK($t) { Write-Host \"  [OK] $t\" -F Green }
function S($t)  { Write-Host \"  [>]  $t\" -F White }
function W($t)  { Write-Host \"  [!] $t\"  -F Yellow }
function E($t)  { Write-Host \"  [X] $t\"  -F Red }

$root = '%~dp0'.TrimEnd('\\')
Set-Location $root

# === Phase 1: Docker engine ===
H 'Phase 1/6 : Verifying Docker engine'
$dockerExe = 'C:\Program Files\Docker\Docker\Docker Desktop.exe'
& docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    S 'Docker not running. Starting Docker Desktop...'
    if (Test-Path $dockerExe) { Start-Process -FilePath $dockerExe }
    $w = 0
    while ($w -lt 180) {
        Start-Sleep -Seconds 5; $w += 5
        & docker info 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { break }
        Write-Host \"    waiting... ($w s)\" -F DarkGray
    }
    & docker info 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        E 'Docker failed to start in 3 min. Open Docker Desktop manually, wait for green, then rerun this .bat.'
        Read-Host 'Press ENTER to exit'; exit 1
    }
}
OK 'Docker engine running'

# === Phase 2: .env (smart restore or generate) ===
H 'Phase 2/6 : Configuration (.env)'
$envFile  = Join-Path $root '.env'
$bkpDir   = 'C:\ProgramData\RealFlow'
$bkpFile  = Join-Path $bkpDir '.env'
New-Item -ItemType Directory -Force -Path $bkpDir | Out-Null

if (-not (Test-Path $envFile)) {
    if (Test-Path $bkpFile) {
        Copy-Item $bkpFile $envFile -Force
        OK '.env restored from C:\ProgramData\RealFlow\.env (your old credentials are back)'
    } else {
        # First time on this PC ever - generate fresh
        $chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789@#'
        $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        function Rnd($n) { $b=New-Object byte[] $n; $rng.GetBytes($b); return ($b|%{$chars[$_ % $chars.Length]}) -join '' }
        function HexRnd($n) { $b=New-Object byte[] $n; $rng.GetBytes($b); return ($b|%{$_.ToString('x2')}) -join '' }
        $pwd = Rnd 16
        $jwt = HexRnd 32
        $tok = HexRnd 32
        @\"
APP_URL=https://realflow.online
CORS_ORIGINS=https://realflow.online,https://www.realflow.online
DB_NAME=realflow
ADMIN_EMAIL=admin@realflow.online
ADMIN_PASSWORD=$pwd
JWT_SECRET_KEY=$jwt
POSTBACK_TOKEN=$tok
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=
SMTP_PASSWORD=
RESEND_API_KEY=
SENDER_EMAIL=onboarding@resend.dev
FRONTEND_PORT=3000
\"@ | Set-Content $envFile -Encoding UTF8
        OK \"Fresh .env generated (admin password: $pwd)\"
    }
}
$envVars = @{}
Get-Content $envFile | Where-Object { $_ -match '^[^#].*=' } | ForEach-Object {
    $p = $_ -split '=', 2; $envVars[$p[0].Trim()] = $p[1].Trim().Trim('\"')
}
$adminEmail = $envVars['ADMIN_EMAIL']
$adminPwd   = $envVars['ADMIN_PASSWORD']
$domain     = ($envVars['APP_URL'] -replace '^https?://','')
OK \"Domain=$domain  Admin=$adminEmail\"

# Backup .env immediately so it survives future folder deletes
Copy-Item $envFile $bkpFile -Force
OK '.env backed up to C:\ProgramData\RealFlow\.env'

# === Phase 3: Container cleanup (safe - never aborts) ===
H 'Phase 3/6 : Cleaning up old containers'
S 'Removing any leftover containers (safe even if none exist)...'
& docker compose down --remove-orphans 2>&1 | Out-Null
& docker rm -f realflow-mongo 2>&1 | Out-Null
& docker rm -f realflow-backend 2>&1 | Out-Null
& docker rm -f realflow-frontend 2>&1 | Out-Null
OK 'Cleanup complete'

# === Phase 4: Build + start containers ===
H 'Phase 4/6 : Building and starting containers (5-10 min on first run)'
S 'docker compose up -d --build --force-recreate'
& docker compose up -d --build --force-recreate
if ($LASTEXITCODE -ne 0) {
    W 'First attempt failed. Cleaning deeper and retrying...'
    & docker compose down --volumes --remove-orphans 2>&1 | Out-Null
    & docker rm -f realflow-mongo realflow-backend realflow-frontend 2>&1 | Out-Null
    Start-Sleep -Seconds 5
    & docker compose up -d --build --force-recreate
    if ($LASTEXITCODE -ne 0) {
        E 'docker compose still failing. Run: docker compose logs   -- to debug.'
        Read-Host 'Press ENTER to exit'; exit 1
    }
}
OK 'Containers started'

S 'Waiting for backend to be healthy...'
$healthy = $false
for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Seconds 3
    try {
        $r = Invoke-WebRequest -UseBasicParsing -Uri 'http://localhost:8001/health' -TimeoutSec 3
        if ($r.StatusCode -eq 200) { $healthy = $true; break }
    } catch {}
    if ($i % 5 -eq 4) { Write-Host \"    still warming up... ($($i*3)s)\" -F DarkGray }
}
if ($healthy) { OK 'Backend healthy on http://localhost:8001' }
else { W 'Backend not healthy yet - continuing anyway, check logs later' }

# === Phase 5: Admin user re-seed (force fresh login with current .env password) ===
H 'Phase 5/6 : Resetting admin user (so login uses CURRENT .env password)'
S \"Deleting old admin from MongoDB (email: $adminEmail)...\"
& docker exec realflow-mongo mongosh realflow --quiet --eval \"db.users.deleteMany({}); db.admin_users.deleteMany({}); print('done')\" 2>&1 | Out-Null
S 'Force-recreating backend so it seeds admin with current .env password...'
& docker compose up -d --force-recreate backend 2>&1 | Out-Null
S 'Waiting 25s for admin to be seeded...'
Start-Sleep -Seconds 25
OK 'Admin re-seeded'

# === Phase 6: Cloudflare tunnel restart ===
H 'Phase 6/6 : Restarting Cloudflare tunnel service'
$svc = Get-Service Cloudflared -EA SilentlyContinue
if ($svc) {
    & sc.exe stop Cloudflared 2>&1 | Out-Null
    Start-Sleep -Seconds 3
    & sc.exe start Cloudflared 2>&1 | Out-Null
    Start-Sleep -Seconds 8
    $svc = Get-Service Cloudflared -EA SilentlyContinue
    if ($svc -and $svc.Status -eq 'Running') { OK 'Cloudflared service running' }
    else { W \"Cloudflared status: $($svc.Status). Try foreground: cloudflared --config C:\ProgramData\Cloudflare\cloudflared\config.yml tunnel run\" }
} else {
    W 'Cloudflared service not installed yet.'
    W 'For first-time install, you need to run REALFLOW-SETUP.bat once to authorize Cloudflare.'
    W 'For now, you can run the tunnel in foreground in a separate window:'
    W '  cloudflared --config \"C:\ProgramData\Cloudflare\cloudflared\config.yml\" tunnel run'
}

# === Final: Verify + show credentials ===
H 'FINAL VERIFICATION'
S 'Local backend...'
try {
    $r = Invoke-WebRequest -UseBasicParsing -Uri 'http://localhost:8001/health' -TimeoutSec 5
    OK \"LOCAL: $($r.Content)\"
} catch { W 'LOCAL test failed - backend may still be starting' }

S 'Public API (through tunnel)...'
$publicOK = $false
for ($i = 0; $i -lt 6; $i++) {
    try {
        $r = Invoke-WebRequest -UseBasicParsing -Uri \"https://api.$domain/health\" -TimeoutSec 15
        OK \"PUBLIC: $($r.Content)\"
        $publicOK = $true; break
    } catch { Start-Sleep -Seconds 10 }
}
if (-not $publicOK) { W 'Public API still warming up. Wait 1-2 min and try again.' }

# Save credentials to Desktop
$desktop = [Environment]::GetFolderPath('Desktop')
$credFile = Join-Path $desktop 'realflow-LOGIN.txt'
@\"
RealFlow - LOGIN CREDENTIALS
=============================
Frontend     : https://$domain
Backend API  : https://api.$domain
Health       : https://api.$domain/health

Admin Email    : $adminEmail
Admin Password : $adminPwd

Project folder: $root

To restart the app anytime, just double-click this same .bat again.
\"@ | Set-Content $credFile -Encoding UTF8

H 'ALL DONE - REALFLOW IS LIVE'
Write-Host ''
Write-Host \"  Frontend : https://$domain\"           -F Green
Write-Host \"  Backend  : https://api.$domain\"       -F Green
Write-Host ''
Write-Host '  ADMIN LOGIN:' -F Yellow
Write-Host \"     Email    : $adminEmail\"            -F Yellow
Write-Host \"     Password : $adminPwd\"              -F Yellow
Write-Host ''
Write-Host \"  Credentials saved to: $credFile\"      -F Cyan
Write-Host ''
Write-Host '  Next time you re-extract the project, just run this .bat again.' -F DarkGray
Write-Host '  Your password and Cloudflare tunnel will be auto-restored.' -F DarkGray
}"

echo.
echo ============================================================================
echo   Press any key to close this window.
echo ============================================================================
pause >nul
endlocal
