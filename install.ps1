# ═══════════════════════════════════════════════════════════════
# 🎭 Understudy — Windows Installer (PowerShell)
# ═══════════════════════════════════════════════════════════════
#
# Usage (one-liner):
#   irm https://raw.githubusercontent.com/erniker/understudy/main/install.ps1 | iex
#
# Or download and run with flags:
#   .\install.ps1 -Version v1.0.0
#
# Parameters:
#   -Version <tag>    Install a specific version (default: latest)
#   -InstallDir <p>   Install to a custom directory (default: ~/.understudy)
#   -NoPath           Skip PATH setup
#   -Uninstall        Remove Understudy from the system
#
# Requires: Git for Windows (provides bash.exe)
# ═══════════════════════════════════════════════════════════════

[CmdletBinding()]
param(
    [string]$Version = "",
    [string]$InstallDir = "",
    [switch]$NoPath,
    [switch]$Uninstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Constants ─────────────────────────────────────────────────
$Repo = "erniker/understudy"
if (-not $InstallDir) { $InstallDir = Join-Path $HOME ".understudy" }
$BinDir = Join-Path $HOME ".local" "bin"
$BinName = "understudy.ps1"
$GitHubApi = "https://api.github.com/repos/$Repo/releases/latest"
$GitHubDownload = "https://github.com/$Repo/releases/download"

# ── Helpers ───────────────────────────────────────────────────
function Write-Info    { param([string]$Msg) Write-Host "  i  $Msg" -ForegroundColor Blue }
function Write-Success { param([string]$Msg) Write-Host "  ✔  $Msg" -ForegroundColor Green }
function Write-Warn    { param([string]$Msg) Write-Host "  ⚠  $Msg" -ForegroundColor Yellow }
function Write-Err     { param([string]$Msg) Write-Host "  ✖  $Msg" -ForegroundColor Red }
function Write-Step    { param([string]$Msg) Write-Host "`n  ▸ $Msg" -ForegroundColor Cyan }

# ── Uninstall ─────────────────────────────────────────────────
function Invoke-Uninstall {
    Write-Step "Uninstalling Understudy"

    if (Test-Path $InstallDir) {
        Remove-Item -Recurse -Force $InstallDir
        Write-Success "Removed $InstallDir"
    } else {
        Write-Warn "Install directory not found: $InstallDir"
    }

    $launcher = Join-Path $BinDir $BinName
    if (Test-Path $launcher) {
        Remove-Item -Force $launcher
        Write-Success "Removed $launcher"
    }

    # Remove from user PATH if present
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -and $userPath.Contains($BinDir)) {
        $newPath = ($userPath.Split(';') | Where-Object { $_ -ne $BinDir }) -join ';'
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Success "Removed $BinDir from user PATH"
    }

    Write-Host ""
    Write-Info "Understudy has been uninstalled."
}

if ($Uninstall) {
    Invoke-Uninstall
    exit 0
}

# ── Dependency check ──────────────────────────────────────────
$script:BashPath = ""

function Test-Dependencies {
    Write-Step "Checking dependencies"

    # Prefer Git for Windows bash over WSL bash
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCmd) {
        $gitDir = Split-Path (Split-Path $gitCmd.Source)
        $gitBash = Join-Path $gitDir "bin" "bash.exe"
        if (Test-Path $gitBash) {
            $script:BashPath = $gitBash
        }
    }

    # Fallback: common Git for Windows locations
    if (-not $script:BashPath) {
        $candidates = @(
            "C:\Program Files\Git\bin\bash.exe",
            "C:\Program Files (x86)\Git\bin\bash.exe",
            "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
        )
        foreach ($c in $candidates) {
            if (Test-Path $c) { $script:BashPath = $c; break }
        }
    }

    # Last resort: any bash in PATH (may be WSL — we test it)
    if (-not $script:BashPath) {
        $bash = Get-Command bash -ErrorAction SilentlyContinue
        if ($bash) { $script:BashPath = $bash.Source }
    }

    if (-not $script:BashPath) {
        Write-Err "bash.exe not found."
        Write-Err "Understudy requires Git for Windows (includes bash)."
        Write-Err "Download from: https://git-scm.com/download/win"
        exit 1
    }

    # Verify it actually works (WSL bash fails if no distro installed)
    try {
        $testOut = & $script:BashPath -c "echo ok" 2>&1
        if ($testOut -ne "ok") { throw "unexpected output" }
    } catch {
        Write-Err "bash at '$script:BashPath' is not functional (WSL without a distro?)."
        Write-Err "Install Git for Windows: https://git-scm.com/download/win"
        exit 1
    }

    Write-Success "bash found: $script:BashPath"

    # Verify we can reach GitHub
    try {
        $null = Invoke-RestMethod -Uri "https://github.com" -Method Head -TimeoutSec 5 -ErrorAction Stop
    } catch {
        Write-Err "Cannot reach github.com. Check your internet connection."
        exit 1
    }
    Write-Success "Network connectivity OK"
}

# ── Resolve version ───────────────────────────────────────────
function Resolve-Version {
    if ($Version) {
        Write-Info "Version requested: $Version"
        return $Version
    }

    Write-Info "Fetching latest version from GitHub..."
    try {
        $release = Invoke-RestMethod -Uri $GitHubApi -Headers @{ Accept = "application/vnd.github+json" }
        $resolved = $release.tag_name
    } catch {
        Write-Err "Could not determine the latest version."
        Write-Err "Check your internet connection or specify -Version <tag>."
        exit 1
    }

    if (-not $resolved) {
        Write-Err "GitHub API returned no tag_name."
        exit 1
    }

    Write-Info "Latest version: $resolved"
    return $resolved
}

# ── Download and extract ──────────────────────────────────────
function Install-Understudy {
    param([string]$Ver)

    $archive = "understudy-${Ver}.tar.gz"
    $url = "$GitHubDownload/$Ver/$archive"
    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "understudy-install-$([guid]::NewGuid().ToString('N').Substring(0,8))"
    $null = New-Item -ItemType Directory -Path $tmpDir -Force

    Write-Step "Downloading $archive"
    Write-Info "From: $url"

    try {
        $archivePath = Join-Path $tmpDir $archive
        Invoke-WebRequest -Uri $url -OutFile $archivePath -UseBasicParsing
    } catch {
        Write-Err "Download failed. Is the version tag correct? ($Ver)"
        Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
        exit 1
    }
    Write-Success "Downloaded"

    Write-Step "Installing to $InstallDir"

    # Remove old installation if present
    if (Test-Path $InstallDir) {
        Write-Warn "Existing installation found — replacing it."
        Remove-Item -Recurse -Force $InstallDir
    }

    $null = New-Item -ItemType Directory -Path $InstallDir -Force

    # Extract .tar.gz — use tar (ships with Windows 10+)
    $tar = Get-Command tar -ErrorAction SilentlyContinue
    if ($tar) {
        & tar -xzf $archivePath -C $InstallDir --strip-components=0
    } else {
        # Fallback: use bash's tar
        & bash -c "tar -xzf '$($archivePath -replace '\\','/')' -C '$($InstallDir -replace '\\','/')' --strip-components=0"
    }

    Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
    Write-Success "Files installed to $InstallDir"
}

# ── Create launcher ───────────────────────────────────────────
function New-Launcher {
    Write-Step "Creating launcher: $BinDir\$BinName"

    $null = New-Item -ItemType Directory -Path $BinDir -Force

    $launcherContent = @"
#!/usr/bin/env pwsh
# Understudy launcher (Windows) — managed by install.ps1, do not edit.
`$wizardPath = Join-Path `"$InstallDir`" "wizard.sh"
`$bashExe = "$($script:BashPath -replace '\\', '\\')"
& `$bashExe `$wizardPath @args
"@

    $launcherPath = Join-Path $BinDir $BinName
    Set-Content -Path $launcherPath -Value $launcherContent -Encoding UTF8
    Write-Success "Launcher created"
}

# ── PATH setup ────────────────────────────────────────────────
function Set-UserPath {
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")

    if ($userPath -and $userPath.Contains($BinDir)) {
        Write-Info "$BinDir is already in PATH."
        return
    }

    Write-Step "Adding $BinDir to user PATH"

    if ($userPath) {
        $newPath = "$BinDir;$userPath"
    } else {
        $newPath = $BinDir
    }

    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Success "Added to user PATH (persistent)"

    # Also update current session
    $env:Path = "$BinDir;$env:Path"
    Write-Info "PATH updated for this session too."
}

# ── Post-install summary ──────────────────────────────────────
function Show-PostInstall {
    param([string]$Ver)

    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║  🎭  Understudy $Ver installed!         ║" -ForegroundColor Green
    Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Step "Quick start"
    Write-Host ""
    Write-Info "Deploy Understudy in any project:"
    Write-Host ""
    Write-Host "      cd C:\path\to\your\project" -ForegroundColor Cyan
    Write-Host "      understudy" -ForegroundColor Cyan
    Write-Host ""
    Write-Info "Add a team member:"
    Write-Host "      understudy --add-member" -ForegroundColor Cyan
    Write-Host ""
    Write-Info "Docs: https://github.com/$Repo#readme"
    Write-Host ""

    if (-not (Get-Command understudy -ErrorAction SilentlyContinue)) {
        Write-Warn "Open a new PowerShell window for PATH changes to take effect."
    }
}

# ── Main ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "  🎭 Understudy Installer (Windows)" -ForegroundColor White
Write-Host ""

Test-Dependencies
$Version = Resolve-Version

Install-Understudy -Ver $Version
New-Launcher

if (-not $NoPath) {
    Set-UserPath
}

Show-PostInstall -Ver $Version
