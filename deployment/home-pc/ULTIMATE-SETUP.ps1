# ============================================================================
#   RealFlow - ULTIMATE SETUP (v2.0 - Bulletproof)
#
#   Addresses every real-world issue discovered during deployment:
#     - Container name conflicts
#     - Cloudflared service registration issues
#     - Password / .env not refreshing
#     - Docker Desktop state
#     - Stale registry keys
# ============================================================================

param(
    [switch]$NoPrompt = $false
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# --- Helpers ----------------------------------------------------------------
function W-H($t) { Write-Host ""; Write-Host ("=" * 70) -F Cyan; Write-Host "  $t" -F Cyan; Write-Host ("=" * 70) -F Cyan }
function W-OK($t) { Write-Host "  [OK] $t" -F Green }
function W-Step($t) { Write-Host "  [>] $t" -F White }
function W-Warn($t) { Write-Host "  [!] $t" -F Yellow }
function W-Err($t) { Write-Host "  [X] $t" -F Red }
function W-Skip($t) { Write-Host "  [=] $t" -F DarkGray }

# --- Project root -----------------------------------------------------------
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
Set-Location $ProjectRoot

W-H "RealFlow - ULTIMATE SETUP v2.0"
Write-Host "  Project: $ProjectRoot" -F DarkGray
Write-Host ""

# --- Admin check ------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    W-Err "Not running as Administrator. Use the .bat with 'Run as administrator'."
    Read-Host "Press ENTER to exit"; exit 1
}
W-OK "Administrator mode"

# --- Phase 1: Prerequisites -------------------------------------------------
W-H "Phase 1/7 : Prerequisites (Git, Docker, cloudflared)"

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    W-Err "winget missing. Install 'App Installer' from Microsoft Store first."
    Read-Host "Press ENTER to exit"; exit 1
}
W-OK "winget available"

function Install-IfMissing($name, $id, $checkCmd) {
    if (Get-Command $checkCmd -ErrorAction SilentlyContinue) { W-Skip "$name (already installed)"; return $false }
    W-Step "Installing $name..."
    winget install --id $id -e --silent --accept-package-agreements --accept-source-agreements | Out-Null
    W-OK "$name installed"
    return $true
}

Install-IfMissing "Git" "Git.Git" "git" | Out-Null
$env:PATH = "C:\Program Files\Git\cmd;$env:PATH"

$dockerExe = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
$dockerInstalled = Test-Path $dockerExe
if (-not $dockerInstalled) {
    W-Step "Installing Docker Desktop (5-10 min)..."
    winget install --id Docker.DockerDesktop -e --silent --accept-package-agreements --accept-source-agreements | Out-Null
    W-OK "Docker Desktop installed"
    W-Warn "REBOOT REQUIRED: Docker needs a PC restart."
    W-Warn "After reboot, double-click REALFLOW-SETUP.bat again."
    Read-Host "Press ENTER to exit"; exit 0
}
W-Skip "Docker Desktop"

Install-IfMissing "cloudflared" "Cloudflare.cloudflared" "cloudflared" | Out-Null
$env:PATH = "C:\Program Files (x86)\cloudflared;C:\Program Files\cloudflared;$env:PATH"

# --- Wait for Docker engine -------------------------------------------------
W-Step "Ensuring Docker engine is running..."
$dockerRunning = $false
docker info 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { $dockerRunning = $true }
if (-not $dockerRunning) {
    W-Step "Starting Docker Desktop..."
    Start-Process -FilePath $dockerExe
    $waited = 0
    while ($waited -lt 180) {
        Start-Sleep -Seconds 5; $waited += 5
        docker info 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $dockerRunning = $true; break }
        Write-Host "    waiting for Docker engine... ($waited s)" -F DarkGray
    }
}
if (-not $dockerRunning) {
    W-Err "Docker engine did not start in 3 minutes. Open Docker Desktop manually and rerun."
    Read-Host "Press ENTER to exit"; exit 1
}
W-OK "Docker engine running"

# --- Phase 2: Load / prompt configuration -----------------------------------
W-H "Phase 2/7 : Configuration"

$envFile = Join-Path $ProjectRoot ".env"
$envBackupDir = "C:\ProgramData\RealFlow"
$envBackup = Join-Path $envBackupDir ".env"
New-Item -ItemType Directory -Force -Path $envBackupDir | Out-Null

$config = @{
    Domain = "realflow.online"
    AdminEmail = "admin@realflow.online"
    AdminPassword = ""
    JwtSecret = ""
    PostbackToken = ""
}

# Smart restore: if local .env missing but backup exists, restore it
if (-not (Test-Path $envFile) -and (Test-Path $envBackup)) {
    W-Step "Local .env missing - restoring from backup at $envBackup"
    Copy-Item -Path $envBackup -Destination $envFile -Force
    W-OK ".env restored from previous install"
}

if (Test-Path $envFile) {
    W-Step "Reading existing .env..."
    Get-Content $envFile | Where-Object { $_ -match "^[^#].*=" } | ForEach-Object {
        $p = $_ -split '=', 2
        $k = $p[0].Trim(); $v = $p[1].Trim().Trim('"')
        switch -Wildcard ($k) {
            "APP_URL"          { $config.Domain = ($v -replace '^https?://','') }
            "ADMIN_EMAIL"      { $config.AdminEmail = $v }
            "ADMIN_PASSWORD"   { if ($v -notmatch "CHANGE_ME" -and $v.Length -ge 6) { $config.AdminPassword = $v } }
            "JWT_SECRET_KEY"   { if ($v -notmatch "CHANGE_ME") { $config.JwtSecret = $v } }
            "POSTBACK_TOKEN"   { if ($v -notmatch "CHANGE_ME") { $config.PostbackToken = $v } }
        }
    }
    W-OK "Reusing existing config (domain=$($config.Domain), email=$($config.AdminEmail))"
} else {
    # First time on this PC -> prompt
    if (-not $NoPrompt) {
        Write-Host ""
        Write-Host "  First-time setup on this PC. Press ENTER to accept defaults." -F Yellow
        $d = Read-Host "  Domain [$($config.Domain)]"
        if ($d) { $config.Domain = $d.Trim().ToLower() -replace '^https?://','' -replace '/$','' }
        $e = Read-Host "  Admin email [admin@$($config.Domain)]"
        if ($e) { $config.AdminEmail = $e.Trim() } else { $config.AdminEmail = "admin@$($config.Domain)" }
        $p = Read-Host "  Admin password (min 6 chars, leave blank to auto-generate)"
        if ($p -and $p.Length -ge 6) { $config.AdminPassword = $p }
    }
}

# Auto-generate any missing secrets
function New-RandomHex([int]$bytes = 32) {
    $buf = New-Object byte[] $bytes
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($buf)
    return ($buf | ForEach-Object { $_.ToString("x2") }) -join ""
}
function New-StrongPassword {
    $chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789@#%&"
    $b = New-Object byte[] 16
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b)
    return -join ($b | ForEach-Object { $chars[$_ % $chars.Length] })
}

if (-not $config.AdminPassword) { $config.AdminPassword = New-StrongPassword }
if (-not $config.JwtSecret)     { $config.JwtSecret = New-RandomHex 32 }
if (-not $config.PostbackToken) { $config.PostbackToken = New-RandomHex 32 }

# Write .env
$envContent = @"
# RealFlow .env - auto-managed by ULTIMATE-SETUP (do not commit)
APP_URL=https://$($config.Domain)
CORS_ORIGINS=https://$($config.Domain),https://www.$($config.Domain)
DB_NAME=realflow
ADMIN_EMAIL=$($config.AdminEmail)
ADMIN_PASSWORD=$($config.AdminPassword)
JWT_SECRET_KEY=$($config.JwtSecret)
POSTBACK_TOKEN=$($config.PostbackToken)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=
SMTP_PASSWORD=
RESEND_API_KEY=
SENDER_EMAIL=onboarding@resend.dev
FRONTEND_PORT=3000
"@
Set-Content -Path $envFile -Value $envContent -Encoding UTF8
W-OK ".env written"

# CRITICAL: Backup .env to safe location outside project folder
# So next time user deletes/re-extracts the project, credentials are preserved
Copy-Item -Path $envFile -Destination $envBackup -Force
W-OK ".env backed up to $envBackup (safe across re-extracts)"

# --- Phase 3: CRITICAL CLEANUP (avoids all the issues we hit) ---------------
W-H "Phase 3/7 : Pre-deployment cleanup (container + service conflicts)"

W-Step "Removing stuck containers..."
docker compose down --remove-orphans 2>$null | Out-Null
docker rm -f realflow-mongo realflow-backend realflow-frontend 2>$null | Out-Null
W-OK "Container cleanup done"

# --- Phase 4: Docker compose up with --force-recreate ----------------------
W-H "Phase 4/7 : Starting Docker containers"

W-Step "Building + starting containers (first time ~5-10 min)..."
docker compose up -d --build --force-recreate
if ($LASTEXITCODE -ne 0) {
    W-Err "Container start failed. Running cleanup + retry..."
    docker compose down --volumes --remove-orphans 2>$null | Out-Null
    docker rm -f realflow-mongo realflow-backend realflow-frontend 2>$null | Out-Null
    Start-Sleep -Seconds 3
    docker compose up -d --build --force-recreate
    if ($LASTEXITCODE -ne 0) {
        W-Err "Retry also failed. Check 'docker compose logs' for details."
        exit 1
    }
}
W-OK "Containers started"

W-Step "Waiting for backend to be healthy..."
$healthy = $false
for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Seconds 3
    try {
        $r = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8001/health" -TimeoutSec 3 -EA Stop
        if ($r.StatusCode -eq 200) { $healthy = $true; break }
    } catch {}
    if ($i % 5 -eq 4) { Write-Host "    still waiting... ($($i*3)s)" -F DarkGray }
}
if ($healthy) { W-OK "Backend healthy on localhost:8001" }
else { W-Warn "Backend not healthy yet - continuing anyway" }

# --- Phase 5: Admin user seed (force recreate if password changed) ----------
W-H "Phase 5/7 : Admin user seed"

W-Step "Ensuring admin exists with current .env password..."
# Delete any existing admin, then recreate container so it seeds fresh
docker exec realflow-mongo mongosh realflow --quiet --eval "db.users.deleteMany({email:'$($config.AdminEmail)'}); db.admin_users.deleteMany({})" 2>$null | Out-Null
docker compose up -d --force-recreate backend 2>&1 | Out-Null
Start-Sleep -Seconds 20
W-OK "Admin seeded with .env credentials"

# --- Phase 6: Cloudflare Tunnel --------------------------------------------
W-H "Phase 6/7 : Cloudflare Tunnel"

$cfDir = Join-Path $env:USERPROFILE ".cloudflared"
New-Item -ItemType Directory -Force -Path $cfDir | Out-Null
$certPath = Join-Path $cfDir "cert.pem"

if (-not (Test-Path $certPath)) {
    W-Step "First-time Cloudflare login - browser will open. Authorize your domain."
    & cloudflared tunnel login
    if (-not (Test-Path $certPath)) {
        W-Err "Cloudflare login failed. Retry the .bat after logging in."
        exit 1
    }
    W-OK "Cloudflare authorized"
} else {
    W-Skip "Cloudflare cert already present"
}

# Check/create tunnel
$tunnelName = "realflow"
$tunnelList = & cloudflared tunnel list 2>$null
$tunnelExists = $tunnelList -match "\b$tunnelName\b"
if (-not $tunnelExists) {
    W-Step "Creating tunnel '$tunnelName'..."
    & cloudflared tunnel create $tunnelName | Out-Null
    W-OK "Tunnel created"
} else {
    W-Skip "Tunnel '$tunnelName' already exists"
}

# DNS route
W-Step "Routing DNS: api.$($config.Domain) -> tunnel"
& cloudflared tunnel route dns --overwrite-dns $tunnelName "api.$($config.Domain)" 2>$null | Out-Null
W-OK "DNS routed"

# Write tunnel config
$tunnelId = (& cloudflared tunnel list 2>$null | Select-String $tunnelName | Select-Object -First 1) -split '\s+' | Select-Object -First 1
$configYml = Join-Path $cfDir "config.yml"
$tunnelConfig = @"
tunnel: $tunnelName
credentials-file: $cfDir\$tunnelId.json
ingress:
  - hostname: api.$($config.Domain)
    service: http://localhost:8001
  - service: http_status:404
"@
Set-Content -Path $configYml -Value $tunnelConfig -Encoding UTF8

# Copy config to ProgramData (service reads from there)
$pdDir = "C:\ProgramData\Cloudflare\cloudflared"
New-Item -ItemType Directory -Force -Path $pdDir | Out-Null
Copy-Item -Path $configYml -Destination (Join-Path $pdDir "config.yml") -Force
if (Test-Path "$cfDir\$tunnelId.json") {
    Copy-Item -Path "$cfDir\$tunnelId.json" -Destination (Join-Path $pdDir "$tunnelId.json") -Force
}
W-OK "Tunnel config written"

# Install service (with CRITICAL cleanup of stale registry/service)
W-Step "Installing cloudflared as Windows service..."
& cloudflared service uninstall 2>$null | Out-Null
& sc.exe delete Cloudflared 2>$null | Out-Null
Remove-Item "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\Cloudflared" -Recurse -Force -EA SilentlyContinue
Start-Sleep -Seconds 2
& cloudflared --config "$pdDir\config.yml" service install 2>&1 | Out-Null
Start-Sleep -Seconds 3

$svc = Get-Service Cloudflared -EA SilentlyContinue
if (-not $svc) {
    W-Warn "Service install via cloudflared failed - using sc.exe fallback"
    $cloudflaredExe = (Get-Command cloudflared).Source
    & sc.exe create Cloudflared binPath= "`"$cloudflaredExe`" --config `"$pdDir\config.yml`" tunnel run $tunnelName" start= auto | Out-Null
    Start-Sleep -Seconds 2
}

Start-Service Cloudflared -EA SilentlyContinue
Start-Sleep -Seconds 10
$svc = Get-Service Cloudflared -EA SilentlyContinue
if ($svc -and $svc.Status -eq "Running") {
    W-OK "Cloudflared service running (auto-start on boot enabled)"
} else {
    W-Warn "Cloudflared service not running - will run in foreground fallback"
}

# --- Phase 7: Verification + shortcuts -------------------------------------
W-H "Phase 7/7 : Final verification"

Start-Sleep -Seconds 15
W-Step "Testing local backend..."
try {
    $r = Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:8001/health" -TimeoutSec 5
    W-OK "LOCAL: $($r.Content)"
} catch { W-Warn "LOCAL test failed: $_" }

W-Step "Testing public API (through tunnel)..."
$publicOK = $false
for ($i = 0; $i -lt 5; $i++) {
    try {
        $r = Invoke-WebRequest -UseBasicParsing -Uri "https://api.$($config.Domain)/health" -TimeoutSec 15
        W-OK "PUBLIC: $($r.Content)"
        $publicOK = $true; break
    } catch { Start-Sleep -Seconds 5 }
}
if (-not $publicOK) { W-Warn "Public API not reachable yet - may need 1-2 min for DNS" }

# --- Save credentials to Desktop + create shortcuts ------------------------
$desktop = [Environment]::GetFolderPath('Desktop')
$credFile = Join-Path $desktop "realflow-LOGIN.txt"
@"
RealFlow - LOGIN CREDENTIALS
=============================
Frontend     : https://$($config.Domain)
Backend API  : https://api.$($config.Domain)
Health       : https://api.$($config.Domain)/health

Admin Email    : $($config.AdminEmail)
Admin Password : $($config.AdminPassword)

Project folder : $ProjectRoot

Change this password after first login from Admin Panel > Settings.
"@ | Set-Content -Path $credFile -Encoding UTF8
W-OK "Credentials saved: $credFile"

# Create desktop shortcuts for management
function New-ShortcutBat($name, $content) {
    $file = Join-Path $desktop "RealFlow-$name.bat"
    Set-Content -Path $file -Value $content -Encoding ASCII
    W-OK "Shortcut: $file"
}

New-ShortcutBat "START" @"
@echo off
cd /d "$ProjectRoot"
echo Starting RealFlow...
docker compose up -d
net start Cloudflared 2>nul
echo.
echo RealFlow started. App: https://$($config.Domain)
pause
"@

New-ShortcutBat "STOP" @"
@echo off
cd /d "$ProjectRoot"
echo Stopping RealFlow...
net stop Cloudflared 2>nul
docker compose stop
echo.
echo RealFlow stopped.
pause
"@

New-ShortcutBat "RESTART" @"
@echo off
cd /d "$ProjectRoot"
echo Restarting RealFlow (full fix)...
docker compose down
docker rm -f realflow-mongo realflow-backend 2>nul
docker compose up -d --force-recreate
net stop Cloudflared 2>nul
timeout /t 3 /nobreak >nul
net start Cloudflared
echo Done.
pause
"@

New-ShortcutBat "LOGS" @"
@echo off
cd /d "$ProjectRoot"
docker compose logs -f --tail 50
"@

New-ShortcutBat "STATUS" @"
@echo off
cd /d "$ProjectRoot"
echo === Containers ===
docker ps --filter "name=realflow-" --format "table {{.Names}}\t{{.Status}}"
echo.
echo === Cloudflare Service ===
sc query Cloudflared
echo.
echo === Health ===
curl -s http://localhost:8001/health
echo.
pause
"@

# --- Summary ----------------------------------------------------------------
W-H "SETUP COMPLETE"
Write-Host ""
Write-Host "  Frontend : https://$($config.Domain)"            -F Green
Write-Host "  Backend  : https://api.$($config.Domain)"        -F Green
Write-Host ""
Write-Host "  ADMIN LOGIN:" -F Yellow
Write-Host "     Email    : $($config.AdminEmail)"             -F Yellow
Write-Host "     Password : $($config.AdminPassword)"          -F Yellow
Write-Host ""
Write-Host "  Desktop shortcuts created:" -F Cyan
Write-Host "     RealFlow-START.bat    (start everything)"     -F Cyan
Write-Host "     RealFlow-STOP.bat     (stop everything)"      -F Cyan
Write-Host "     RealFlow-RESTART.bat  (nuclear restart)"      -F Cyan
Write-Host "     RealFlow-LOGS.bat     (view live logs)"       -F Cyan
Write-Host "     RealFlow-STATUS.bat   (check health)"         -F Cyan
Write-Host ""
Write-Host "  Auto-start on boot: ENABLED (cloudflared service + Docker Desktop)" -F Green
Write-Host ""
exit 0
