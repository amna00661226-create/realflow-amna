# ============================================================================
#  RealFlow - ONECLICK.ps1
#  Fully automated installer - no prompts, pre-filled values.
#  Called by REALFLOW-1-CLICK-DEPLOY.bat via `irm | iex`.
#
#  Inputs (from environment variables set by the .bat):
#     REALFLOW_DOMAIN        e.g. realflow.online
#     REALFLOW_ADMIN_EMAIL   e.g. admin@realflow.online
#     REALFLOW_GITHUB_OWNER  GitHub account that hosts the repo
#     REALFLOW_GITHUB_REPO   Repo name
#     REALFLOW_BRANCH        branch to clone (default: main)
#
#  What this does (everything automatic):
#     1. Installs Git, Docker Desktop, cloudflared (if missing) via winget
#     2. Clones the repo to Desktop\realflow
#     3. Creates .env with pre-filled domain/email + auto-random JWT/Postback/Password
#     4. Shows the auto-generated admin password at the end (save it!)
#     5. Runs deployment/home-pc/setup.ps1 with those pre-filled values
# ============================================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

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

# --- Read pre-filled values from env ----------------------------------------
$Domain      = if ($env:REALFLOW_DOMAIN)       { $env:REALFLOW_DOMAIN }       else { "realflow.online" }
$AdminEmail  = if ($env:REALFLOW_ADMIN_EMAIL)  { $env:REALFLOW_ADMIN_EMAIL }  else { "admin@$Domain" }
$Owner       = if ($env:REALFLOW_GITHUB_OWNER) { $env:REALFLOW_GITHUB_OWNER } else { "amna00661226-create" }
$Repo        = if ($env:REALFLOW_GITHUB_REPO)  { $env:REALFLOW_GITHUB_REPO }  else { "realflow-amna" }
$Branch      = if ($env:REALFLOW_BRANCH)       { $env:REALFLOW_BRANCH }       else { "main" }
$CloneDir    = Join-Path $env:USERPROFILE "Desktop\realflow"
$RepoUrl     = "https://github.com/$Owner/$Repo.git"

Write-Header "RealFlow - ONE CLICK DEPLOY"
Write-Host "  Domain       : $Domain"              -ForegroundColor DarkGray
Write-Host "  Admin email  : $AdminEmail"          -ForegroundColor DarkGray
Write-Host "  GitHub repo  : $RepoUrl"             -ForegroundColor DarkGray
Write-Host "  Clone to     : $CloneDir"            -ForegroundColor DarkGray
Write-Host ""

# --- Admin check ------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Err "Not running as Administrator. Relaunch the .bat file using 'Run as administrator'."
    Read-Host "Press ENTER to exit"
    exit 1
}
Write-OK "Running as Administrator"

# --- Phase 1: Install prerequisites via winget ------------------------------
Write-Header "Phase 1/4 : Prerequisites (Git, Docker Desktop, cloudflared)"

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Err "winget is missing. Install 'App Installer' from Microsoft Store, then rerun."
    Read-Host "Press ENTER to exit"
    exit 1
}
Write-OK "winget available"

# 1.1 Git
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
    Write-Host "  !! Please REBOOT your PC, then double-click this .bat again to finish." -ForegroundColor Yellow
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
    Write-Step "Starting Docker Desktop (can take up to 90 seconds)..."
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
    Write-Host "  Open Docker Desktop manually, wait for 'Engine running', then rerun the .bat." -ForegroundColor Yellow
    Read-Host "Press ENTER to exit"
    exit 1
}
Write-OK "Docker engine is running"

# --- Phase 2: Clone repo ----------------------------------------------------
Write-Header "Phase 2/4 : Getting the source code"

if (Test-Path (Join-Path $CloneDir ".git")) {
    Write-Step "Repo already cloned, pulling latest..."
    Push-Location $CloneDir
    git pull --quiet
    Pop-Location
    Write-OK "Repo up-to-date"
} else {
    Write-Step "Cloning $RepoUrl -> $CloneDir ..."
    git clone --quiet --branch $Branch $RepoUrl $CloneDir
    if (-not (Test-Path (Join-Path $CloneDir ".git"))) {
        Write-Err "git clone failed. Check internet connection and repo visibility (must be public)."
        Read-Host "Press ENTER to exit"
        exit 1
    }
    Write-OK "Repo cloned"
}

# --- Phase 3: Auto-generate password + write .env ---------------------------
Write-Header "Phase 3/4 : Configuration"

$envFile = Join-Path $CloneDir ".env"
$adminPassword = $null

# Reuse existing password if .env already exists and is valid
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
    Add-Type -AssemblyName System.Web -ErrorAction SilentlyContinue
    try {
        $adminPassword = [System.Web.Security.Membership]::GeneratePassword(16, 3)
    } catch {
        # Fallback: manual random
        $chars  = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#%&*"
        $bytes  = New-Object byte[] 16
        [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
        $adminPassword = -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })
    }
    Write-OK "Generated a strong random admin password"
}

# Pass values to setup.ps1 via SecureString
$securePwd = ConvertTo-SecureString $adminPassword -AsPlainText -Force

# --- Phase 4: Run the real setup --------------------------------------------
Write-Header "Phase 4/4 : Running full setup (this takes 10-15 min)"

$setupScript = Join-Path $CloneDir "deployment\home-pc\setup.ps1"
if (-not (Test-Path $setupScript)) {
    Write-Err "setup.ps1 not found at $setupScript"
    Write-Host "  The repo appears to be missing the deployment folder." -ForegroundColor Yellow
    Read-Host "Press ENTER to exit"
    exit 1
}

Write-Host ""
Write-Host "  The next step will open your browser ONCE for Cloudflare login." -ForegroundColor Yellow
Write-Host "  Just click 'Authorize' for your domain ($Domain)." -ForegroundColor Yellow
Write-Host "  Everything else is automatic." -ForegroundColor Yellow
Write-Host ""

& $setupScript -Domain $Domain -AdminEmail $AdminEmail -AdminPassword $securePwd

# --- Final: show credentials ------------------------------------------------
Write-Header "All done - RealFlow is LIVE!"
Write-Host ""
Write-Host "  Frontend : https://$Domain"                 -ForegroundColor Green
Write-Host "  Backend  : https://api.$Domain"             -ForegroundColor Green
Write-Host "  Health   : https://api.$Domain/health"      -ForegroundColor Green
Write-Host ""
Write-Host "  ADMIN LOGIN (save these - you'll need them!):" -ForegroundColor Yellow
Write-Host "     Email    : $AdminEmail"                  -ForegroundColor Yellow
Write-Host "     Password : $adminPassword"               -ForegroundColor Yellow
Write-Host ""
Write-Host "  These credentials are also saved in:"       -ForegroundColor DarkGray
Write-Host "     $CloneDir\.env"                          -ForegroundColor DarkGray
Write-Host ""

# Also write credentials to a handy file on the Desktop
$credFile = Join-Path $env:USERPROFILE "Desktop\realflow-LOGIN.txt"
$credContent = @"
RealFlow - Admin Login
=======================
Frontend     : https://$Domain
Backend      : https://api.$Domain
Admin email  : $AdminEmail
Admin pass   : $adminPassword

Change this password anytime after first login from
the Admin panel -> Settings -> Account.
"@
Set-Content -Path $credFile -Value $credContent -Encoding UTF8
Write-Host "  Credentials also saved to: $credFile" -ForegroundColor Green
Write-Host ""
