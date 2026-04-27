# ============================================================================
#  RealFlow - ONECLICK.ps1  (LOCAL FOLDER VERSION)
#
#  Usage: invoked by REALFLOW-1-CLICK-DEPLOY.bat from the SAME folder
#         where this script lives (extracted from GitHub ZIP).
#
#  Pre-filled values - no prompts:
#     Domain      : realflow.online
#     Admin Email : admin@realflow.online
#     Password    : auto-generated (random 16-char)
#
#  What this does:
#     1. Installs Git, Docker Desktop, cloudflared (if missing) via winget
#     2. Makes sure Docker engine is running
#     3. Generates a strong random admin password
#     4. Runs deployment/home-pc/setup.ps1 with those values
#     5. Shows credentials + saves them to Desktop\realflow-LOGIN.txt
# ============================================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# -- Hard-coded pre-filled values (customize here if you fork) ---------------
$Domain     = "realflow.online"
$AdminEmail = "admin@realflow.online"

# -- Where we are (the extracted project folder) -----------------------------
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot

function Write-Header($text) {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  $text" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
}
function Write-OK($t)   { Write-Host "  [OK] $t" -ForegroundColor Green }
function Write-Step($t) { Write-Host "  [>] $t"  -ForegroundColor White }
function Write-Err($t)  { Write-Host "  [X] $t"  -ForegroundColor Red }
function Write-Skip($t) { Write-Host "  [=] $t (already present)" -ForegroundColor DarkGray }

Write-Header "RealFlow - ONE CLICK DEPLOY (from local folder)"
Write-Host "  Project folder : $ProjectRoot" -ForegroundColor DarkGray
Write-Host "  Domain         : $Domain"      -ForegroundColor DarkGray
Write-Host "  Admin email    : $AdminEmail"  -ForegroundColor DarkGray
Write-Host ""

# --- Admin check ------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Err "Not running as Administrator."
    Write-Host "  Close this window, right-click REALFLOW-1-CLICK-DEPLOY.bat -> Run as administrator." -ForegroundColor Yellow
    Read-Host "Press ENTER to exit"
    exit 1
}
Write-OK "Running as Administrator"

# --- Sanity check: make sure this is the right folder ----------------------
foreach ($required in @("docker-compose.yml", "backend", "frontend", "deployment\home-pc\setup.ps1")) {
    if (-not (Test-Path (Join-Path $ProjectRoot $required))) {
        Write-Err "Missing: $required"
        Write-Host "  This .bat must sit inside the extracted RealFlow project folder." -ForegroundColor Yellow
        Read-Host "Press ENTER to exit"
        exit 1
    }
}
Write-OK "Project folder structure verified"

# --- Phase 1: Install prerequisites ----------------------------------------
Write-Header "Phase 1/3 : Prerequisites (Git, Docker Desktop, cloudflared)"

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Err "winget is missing."
    Write-Host "  Install 'App Installer' from Microsoft Store first, then rerun." -ForegroundColor Yellow
    Read-Host "Press ENTER to exit"
    exit 1
}
Write-OK "winget available"

# 1.1 Git (not strictly needed since we're using local files, but setup.ps1 may expect it)
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Skip "Git"
} else {
    Write-Step "Installing Git..."
    winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements | Out-Null
    $env:PATH = "C:\Program Files\Git\cmd;$env:PATH"
    Write-OK "Git installed"
}

# 1.2 Docker Desktop
$dockerExe = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if (Test-Path $dockerExe) {
    Write-Skip "Docker Desktop"
} else {
    Write-Step "Installing Docker Desktop (this can take 5+ minutes)..."
    winget install --id Docker.DockerDesktop -e --silent --accept-package-agreements --accept-source-agreements | Out-Null
    Write-OK "Docker Desktop installed"
    Write-Host ""
    Write-Host "  !! IMPORTANT: Docker Desktop was just installed." -ForegroundColor Yellow
    Write-Host "  !! Please REBOOT your PC, then double-click REALFLOW-1-CLICK-DEPLOY.bat again." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press ENTER to exit (reboot required)"
    exit 0
}

# 1.3 cloudflared
if (Get-Command cloudflared -ErrorAction SilentlyContinue) {
    Write-Skip "cloudflared"
} else {
    Write-Step "Installing cloudflared..."
    winget install --id Cloudflare.cloudflared -e --silent --accept-package-agreements --accept-source-agreements | Out-Null
    $env:PATH = "C:\Program Files (x86)\cloudflared;C:\Program Files\cloudflared;$env:PATH"
    Write-OK "cloudflared installed"
}

# 1.4 Make sure Docker engine is running
Write-Step "Checking Docker engine..."
$dockerRunning = $false
for ($i = 0; $i -lt 3; $i++) {
    try {
        docker info --format '{{.ServerVersion}}' 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $dockerRunning = $true; break }
    } catch {}
    Start-Sleep -Seconds 2
}
if (-not $dockerRunning) {
    Write-Step "Starting Docker Desktop (can take up to 2 minutes)..."
    if (Test-Path $dockerExe) { Start-Process -FilePath $dockerExe }
    $waited = 0
    while ($waited -lt 120) {
        Start-Sleep -Seconds 5
        $waited += 5
        try {
            docker info --format '{{.ServerVersion}}' 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) { $dockerRunning = $true; break }
        } catch {}
        Write-Host "    still waiting for Docker... ($waited s)" -ForegroundColor DarkGray
    }
}
if (-not $dockerRunning) {
    Write-Err "Docker did not start within 2 minutes."
    Write-Host "  Open Docker Desktop manually, wait for green 'Engine running', then rerun the .bat." -ForegroundColor Yellow
    Read-Host "Press ENTER to exit"
    exit 1
}
Write-OK "Docker engine is running"

# --- Phase 2: Generate admin password --------------------------------------
Write-Header "Phase 2/3 : Configuration"

$envFile = Join-Path $ProjectRoot ".env"
$adminPassword = $null

# Reuse existing password if .env already exists
if (Test-Path $envFile) {
    $existing = @{}
    Get-Content $envFile | Where-Object { $_ -match "^[^#].*=" } | ForEach-Object {
        $parts = $_ -split '=', 2
        $existing[$parts[0].Trim()] = $parts[1].Trim().Trim('"')
    }
    if ($existing["ADMIN_PASSWORD"] -and $existing["ADMIN_PASSWORD"] -notmatch "CHANGE_ME" -and $existing["ADMIN_PASSWORD"].Length -ge 8) {
        $adminPassword = $existing["ADMIN_PASSWORD"]
        Write-OK "Reusing existing admin password from previous run"
    }
}

if (-not $adminPassword) {
    # Generate a strong random password (16 chars, alphanumeric + symbols)
    $chars  = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#%&*"
    $bytes  = New-Object byte[] 16
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $adminPassword = -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })
    Write-OK "Generated a strong random admin password"
}

$securePwd = ConvertTo-SecureString $adminPassword -AsPlainText -Force

# --- Phase 3: Run the real setup -------------------------------------------
Write-Header "Phase 3/3 : Running full setup (10-15 min)"

$setupScript = Join-Path $ProjectRoot "deployment\home-pc\setup.ps1"

Write-Host ""
Write-Host "  The next step will open your browser ONCE for Cloudflare login." -ForegroundColor Yellow
Write-Host "  Just select your domain ($Domain) and click 'Authorize'." -ForegroundColor Yellow
Write-Host "  Everything else is automatic." -ForegroundColor Yellow
Write-Host ""

$script:DockerFailed = $false
& $setupScript -Domain $Domain -AdminEmail $AdminEmail -AdminPassword $securePwd
$setupExitCode = $LASTEXITCODE

# --- Final: show credentials -----------------------------------------------
if ($script:DockerFailed -or $setupExitCode -ne 0) {
    Write-Header "SETUP HAD ERRORS - See above"
    Write-Host ""
    Write-Host "  The installer finished but Docker containers did not start properly." -ForegroundColor Yellow
    Write-Host "  Your .env file is saved. Credentials below are still valid." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  TO FIX: Double-click FIX-AND-RESTART.bat in the same folder." -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Header "All done - RealFlow is LIVE!"
}
Write-Host ""
Write-Host "  Frontend : https://$Domain"                 -ForegroundColor Green
Write-Host "  Backend  : https://api.$Domain"             -ForegroundColor Green
Write-Host "  Health   : https://api.$Domain/health"      -ForegroundColor Green
Write-Host ""
Write-Host "  ADMIN LOGIN (save these!):"                 -ForegroundColor Yellow
Write-Host "     Email    : $AdminEmail"                  -ForegroundColor Yellow
Write-Host "     Password : $adminPassword"               -ForegroundColor Yellow
Write-Host ""

# Save credentials to Desktop for safety
$credFile = Join-Path $env:USERPROFILE "Desktop\realflow-LOGIN.txt"
$credContent = @"
RealFlow - Admin Login
=======================
Frontend      : https://$Domain
Backend       : https://api.$Domain
Health check  : https://api.$Domain/health
Admin email   : $AdminEmail
Admin pass    : $adminPassword

Change this password anytime after first login from
the Admin panel -> Settings -> Account.

Project folder: $ProjectRoot
"@
Set-Content -Path $credFile -Value $credContent -Encoding UTF8
Write-Host "  Credentials also saved to:" -ForegroundColor Green
Write-Host "    $credFile" -ForegroundColor Green
Write-Host ""
Write-Host "  Management scripts (double-click any):" -ForegroundColor DarkGray
Write-Host "    $ProjectRoot\deployment\home-pc\start.bat" -ForegroundColor DarkGray
Write-Host "    $ProjectRoot\deployment\home-pc\stop.bat" -ForegroundColor DarkGray
Write-Host "    $ProjectRoot\deployment\home-pc\status.bat" -ForegroundColor DarkGray
Write-Host "    $ProjectRoot\deployment\home-pc\logs.bat" -ForegroundColor DarkGray
Write-Host ""
