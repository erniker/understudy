#!/usr/bin/env bats
# Tests for ensure_jq/cleanup_jq — the ephemeral jq dependency used only to
# patch VS Code's settings.json in global mode. Understudy must never leave
# jq behind: install only when missing, uninstall only what it installed,
# and never attempt a blind sudo install without a controlling terminal.
#
# `command`/`uname`/package-manager binaries are shadowed with plain bash
# functions per test (not real executables on PATH) so these tests are fully
# deterministic regardless of what's actually installed on the machine
# running the suite.

load "../lib/helpers"

setup() {
  setup_tmp
  source_wizard_functions
  JQ_INSTALLED_BY_UNDERSTUDY=false
  JQ_PM_USED=""
}

teardown() { teardown_tmp; }

# ── jq already present — no-op ────────────────────────────────────────────────

@test "ensure_jq no-ops when jq is already installed" {
  command() { [[ "$1" == "-v" && "$2" == "jq" ]] && return 0 || builtin command "$@"; }
  ensure_jq
  [ "$JQ_INSTALLED_BY_UNDERSTUDY" = "false" ]
  [ -z "$JQ_PM_USED" ]
}

# ── macOS ──────────────────────────────────────────────────────────────────────

@test "ensure_jq installs via brew on macOS when jq is missing" {
  uname() { echo "Darwin"; }
  # Stateful: jq is "not found" until the brew stub "installs" it, mirroring
  # a real install making the binary callable afterward.
  _jq_now_available=false
  command() {
    if [[ "$1" == "-v" ]]; then
      case "$2" in
        jq)   $_jq_now_available && return 0 || return 1 ;;
        brew) return 0 ;;
      esac
    fi
    builtin command "$@"
  }
  brew() { _jq_now_available=true; return 0; }
  AUTO_CONFIRM=true

  ensure_jq

  [ "$JQ_INSTALLED_BY_UNDERSTUDY" = "true" ]
  [ "$JQ_PM_USED" = "brew" ]
}

@test "ensure_jq does not report success when the package manager exits 0 but jq is still not callable" {
  # Regression test: a package manager (observed with winget on Windows) can
  # exit 0 without jq actually being invokable in this shell yet (PATH not
  # refreshed). ensure_jq must not trust the exit code alone.
  uname() { echo "MINGW64_NT-10.0"; }
  command() {
    if [[ "$1" == "-v" ]]; then
      case "$2" in
        jq)    return 1 ;;
        scoop) return 0 ;;
      esac
    fi
    builtin command "$@"
  }
  scoop() { return 0; }
  AUTO_CONFIRM=true

  ensure_jq || true

  [ "$JQ_INSTALLED_BY_UNDERSTUDY" = "false" ]
}

@test "ensure_jq never attempts an install when UNDERSTUDY_SKIP_JQ_INSTALL=1" {
  # Safety valve for automated tests/CI: even with a working package manager
  # available and AUTO_CONFIRM set, this must short-circuit before touching
  # the real system.
  uname() { echo "Darwin"; }
  command() {
    if [[ "$1" == "-v" ]]; then
      case "$2" in jq) return 1 ;; brew) return 0 ;; esac
    fi
    builtin command "$@"
  }
  brew() { echo "brew should never be called" >&2; return 1; }
  AUTO_CONFIRM=true
  UNDERSTUDY_SKIP_JQ_INSTALL=1

  ensure_jq || true

  [ "$JQ_INSTALLED_BY_UNDERSTUDY" = "false" ]
}

@test "ensure_jq does nothing on macOS without brew available" {
  uname() { echo "Darwin"; }
  command() { [[ "$1" == "-v" ]] && return 1 || builtin command "$@"; }
  AUTO_CONFIRM=true

  ensure_jq || true

  [ "$JQ_INSTALLED_BY_UNDERSTUDY" = "false" ]
}

# ── Windows: scoop > winget > choco ───────────────────────────────────────────

@test "ensure_jq prefers scoop on Windows when available (no elevation)" {
  uname() { echo "MINGW64_NT-10.0"; }
  _jq_now_available=false
  command() {
    if [[ "$1" == "-v" ]]; then
      case "$2" in
        jq)     $_jq_now_available && return 0 || return 1 ;;
        scoop)  return 0 ;;
        winget) return 0 ;;
        choco)  return 0 ;;
      esac
    fi
    builtin command "$@"
  }
  scoop() { _jq_now_available=true; return 0; }
  winget() { _jq_now_available=true; return 0; }
  choco() { _jq_now_available=true; return 0; }
  AUTO_CONFIRM=true

  ensure_jq

  [ "$JQ_INSTALLED_BY_UNDERSTUDY" = "true" ]
  [ "$JQ_PM_USED" = "scoop" ]
}

@test "ensure_jq falls back to winget on Windows when scoop is unavailable" {
  uname() { echo "MINGW64_NT-10.0"; }
  _jq_now_available=false
  command() {
    if [[ "$1" == "-v" ]]; then
      case "$2" in
        jq)     $_jq_now_available && return 0 || return 1 ;;
        scoop)  return 1 ;;
        winget) return 0 ;;
        choco)  return 0 ;;
      esac
    fi
    builtin command "$@"
  }
  winget() { _jq_now_available=true; return 0; }
  choco() { _jq_now_available=true; return 0; }
  AUTO_CONFIRM=true

  ensure_jq

  [ "$JQ_INSTALLED_BY_UNDERSTUDY" = "true" ]
  [ "$JQ_PM_USED" = "winget" ]
}

# ── Linux: needs a controlling terminal (sudo safety) ─────────────────────────

@test "ensure_jq does NOT attempt a Linux install without a controlling terminal" {
  uname() { echo "Linux"; }
  command() {
    if [[ "$1" == "-v" ]]; then
      case "$2" in
        jq)      return 1 ;;
        apt-get) return 0 ;;
      esac
    fi
    builtin command "$@"
  }
  sudo() { return 0; }
  AUTO_CONFIRM=true

  # bats runs tests non-interactively (stdin is not a tty), so the [[ -t 0 ]]
  # guard in ensure_jq must prevent any install attempt here.
  ensure_jq || true

  [ "$JQ_INSTALLED_BY_UNDERSTUDY" = "false" ]
  [ -z "$JQ_PM_USED" ]
}

# ── Confirmation prompt ────────────────────────────────────────────────────────

@test "ensure_jq aborts when the user declines the confirmation prompt" {
  uname() { echo "Darwin"; }
  command() {
    if [[ "$1" == "-v" ]]; then
      case "$2" in jq) return 1 ;; brew) return 0 ;; esac
    fi
    builtin command "$@"
  }
  confirm() { return 1; }
  brew() { return 0; }
  AUTO_CONFIRM=false

  ensure_jq || true

  [ "$JQ_INSTALLED_BY_UNDERSTUDY" = "false" ]
}

@test "ensure_jq skips the confirmation prompt when AUTO_CONFIRM is set" {
  uname() { echo "Darwin"; }
  _jq_now_available=false
  command() {
    if [[ "$1" == "-v" ]]; then
      case "$2" in
        jq)   $_jq_now_available && return 0 || return 1 ;;
        brew) return 0 ;;
      esac
    fi
    builtin command "$@"
  }
  confirm() { echo "confirm should not be called" >&2; return 1; }
  brew() { _jq_now_available=true; return 0; }
  AUTO_CONFIRM=true

  ensure_jq

  [ "$JQ_INSTALLED_BY_UNDERSTUDY" = "true" ]
}

# ── cleanup_jq ─────────────────────────────────────────────────────────────────

@test "cleanup_jq no-ops when jq was not installed by understudy" {
  JQ_INSTALLED_BY_UNDERSTUDY=false
  JQ_PM_USED=""
  cleanup_jq
  [ "$JQ_INSTALLED_BY_UNDERSTUDY" = "false" ]
}

@test "cleanup_jq uninstalls via the same package manager used to install" {
  JQ_INSTALLED_BY_UNDERSTUDY=true
  JQ_PM_USED="brew"
  brew() { echo "$*" > "${TEST_TMP}/brew-call.log"; return 0; }

  cleanup_jq

  [ "$JQ_INSTALLED_BY_UNDERSTUDY" = "false" ]
  grep -q "uninstall jq" "${TEST_TMP}/brew-call.log"
}
