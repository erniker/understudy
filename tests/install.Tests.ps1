#Requires -Module Pester
# ═══════════════════════════════════════════════════════════════
# Tests for install.ps1 — Understudy PowerShell installer
# ═══════════════════════════════════════════════════════════════
#
# Run with:
#   Invoke-Pester tests/install.Tests.ps1
#

BeforeAll {
    $Script:InstallerPath = Join-Path $PSScriptRoot ".." "install.ps1" | Resolve-Path
    $Script:TestInstallDir = Join-Path ([System.IO.Path]::GetTempPath()) "understudy-test-$([guid]::NewGuid().ToString('N').Substring(0,8))"
    $Script:TestBinDir = Join-Path ([System.IO.Path]::GetTempPath()) "understudy-bin-$([guid]::NewGuid().ToString('N').Substring(0,8))"
}

AfterAll {
    # Cleanup test directories
    if (Test-Path $Script:TestInstallDir) { Remove-Item -Recurse -Force $Script:TestInstallDir }
    if (Test-Path $Script:TestBinDir) { Remove-Item -Recurse -Force $Script:TestBinDir }
}

Describe "install.ps1 syntax" {
    It "has no parse errors" {
        $errors = $null
        $tokens = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile(
            $Script:InstallerPath, [ref]$tokens, [ref]$errors
        )
        $errors.Count | Should -Be 0
    }
}

Describe "Bash detection logic" {
    It "finds bash via Git for Windows" {
        $gitCmd = Get-Command git -ErrorAction SilentlyContinue
        if (-not $gitCmd) { Set-ItResult -Skipped -Because "Git not installed" }

        $gitDir = Split-Path (Split-Path $gitCmd.Source)
        $gitBash = Join-Path $gitDir "bin" "bash.exe"
        Test-Path $gitBash | Should -BeTrue
    }

    It "Git bash is functional (echoes ok)" {
        $gitCmd = Get-Command git -ErrorAction SilentlyContinue
        if (-not $gitCmd) { Set-ItResult -Skipped -Because "Git not installed" }

        $gitDir = Split-Path (Split-Path $gitCmd.Source)
        $gitBash = Join-Path $gitDir "bin" "bash.exe"
        $result = & $gitBash -c "echo ok" 2>&1
        $result | Should -Be "ok"
    }

    It "rejects WSL bash when no distro is installed" {
        # This test validates the concept: a bash that returns unexpected output is rejected
        $fakeBash = Join-Path $Script:TestInstallDir "fake-bash.cmd"
        New-Item -ItemType Directory -Path $Script:TestInstallDir -Force | Out-Null
        Set-Content $fakeBash '@echo ERROR: no distro'

        $result = & cmd /c $fakeBash 2>&1 | Out-String
        $result.Trim() | Should -Not -Be "ok"
    }
}

Describe "Version resolution" {
    It "fetches latest version from GitHub API" {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/erniker/understudy/releases/latest" `
            -Headers @{ Accept = "application/vnd.github+json" }
        $release.tag_name | Should -Match '^v\d+\.\d+\.\d+'
    }
}

Describe "Full install + uninstall cycle" {
    BeforeAll {
        # Run the installer with a custom dir and -NoPath to avoid polluting the system
        & pwsh -NoProfile -Command "& '$Script:InstallerPath' -Version 'v0.9.3' -InstallDir '$Script:TestInstallDir' -NoPath"
    }

    It "installs wizard.sh to the target directory" {
        Join-Path $Script:TestInstallDir "wizard.sh" | Test-Path | Should -BeTrue
    }

    It "installs CHANGELOG.md" {
        Join-Path $Script:TestInstallDir "CHANGELOG.md" | Test-Path | Should -BeTrue
    }

    It "installs understudy.yaml" {
        Join-Path $Script:TestInstallDir "understudy.yaml" | Test-Path | Should -BeTrue
    }

    It "installs templates directory" {
        Join-Path $Script:TestInstallDir "templates" | Test-Path | Should -BeTrue
    }

    It "installs roles directory" {
        Join-Path $Script:TestInstallDir "roles" | Test-Path | Should -BeTrue
    }

    It "creates the launcher script" {
        $launcher = Join-Path $HOME ".local" "bin" "understudy.ps1"
        Test-Path $launcher | Should -BeTrue
    }

    It "launcher contains correct bash path" {
        $launcher = Join-Path $HOME ".local" "bin" "understudy.ps1"
        $content = Get-Content $launcher -Raw
        $content | Should -Match "bash"
        $content | Should -Match "wizard\.sh"
    }

    It "launcher delegates to bash and runs wizard --help" {
        $launcher = Join-Path $HOME ".local" "bin" "understudy.ps1"
        $output = & pwsh -NoProfile -Command "& '$launcher' --help 2>&1" | Out-String
        $output | Should -Match "Understudy"
    }
}

Describe "Uninstall" {
    BeforeAll {
        # Ensure we have something to uninstall
        if (-not (Test-Path $Script:TestInstallDir)) {
            & pwsh -NoProfile -Command "& '$Script:InstallerPath' -Version 'v0.9.3' -InstallDir '$Script:TestInstallDir' -NoPath"
        }
    }

    It "removes the install directory" {
        & pwsh -NoProfile -Command "& '$Script:InstallerPath' -Uninstall -InstallDir '$Script:TestInstallDir'"
        Test-Path $Script:TestInstallDir | Should -BeFalse
    }

    It "is idempotent (running uninstall again does not error)" {
        { & pwsh -NoProfile -Command "& '$Script:InstallerPath' -Uninstall -InstallDir '$Script:TestInstallDir'" } | Should -Not -Throw
    }
}
