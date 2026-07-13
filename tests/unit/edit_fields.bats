#!/usr/bin/env bats
# Tests for _here_edit_field() / _global_edit_field() — the "e to edit"
# numbered-field dispatch used by --here and --global before deploying.
# Never exercised by any integration test, since those either pipe --yes
# (skips editing entirely) or answer the full interactive flow without
# touching "e".
#
# `ask` is stubbed as a no-op by source_wizard_functions; each test below
# defines its own `ask` override to simulate what the user would have typed,
# using `printf -v` to assign into the caller-named variable (mirrors the
# real `ask "prompt" VARNAME "default"` contract).

load "../lib/helpers"

setup() {
  setup_tmp
  source_wizard_functions
}

teardown() { teardown_tmp; }

# ── _here_edit_field: simple text fields (1-5) ────────────────────────────────

@test "_here_edit_field 1 updates PROJECT_NAME" {
  ask() { printf -v "$2" '%s' "new-project-name"; }
  PROJECT_NAME="old-name"
  _here_edit_field 1
  [ "$PROJECT_NAME" = "new-project-name" ]
}

@test "_here_edit_field 3 updates TECH_STACK" {
  ask() { printf -v "$2" '%s' "Node.js + Vue"; }
  TECH_STACK="Unknown"
  _here_edit_field 3
  [ "$TECH_STACK" = "Node.js + Vue" ]
}

# ── _here_edit_field: guardrails mode (6) ─────────────────────────────────────

@test "_here_edit_field 6 sets GUARDRAILS_MODE to embedded when answer is 2" {
  ask() { printf -v "$2" '%s' "2"; }
  GUARDRAILS_MODE="split"
  _here_edit_field 6
  [ "$GUARDRAILS_MODE" = "embedded" ]
}

@test "_here_edit_field 6 sets GUARDRAILS_MODE to split for any other answer" {
  ask() { printf -v "$2" '%s' "1"; }
  GUARDRAILS_MODE="embedded"
  _here_edit_field 6
  [ "$GUARDRAILS_MODE" = "split" ]
}

# ── _here_edit_field: platforms (7) ───────────────────────────────────────────

@test "_here_edit_field 7 updates all three platform booleans in order" {
  local call=0
  ask() {
    call=$((call + 1))
    case $call in
      1) printf -v "$2" '%s' "n" ;; # Copilot
      2) printf -v "$2" '%s' "Y" ;; # Claude
      3) printf -v "$2" '%s' "n" ;; # Cursor
    esac
  }
  PLATFORM_COPILOT=true
  PLATFORM_CLAUDE=false
  PLATFORM_CURSOR=true
  _here_edit_field 7
  [ "$PLATFORM_COPILOT" = "false" ]
  [ "$PLATFORM_CLAUDE" = "true" ]
  [ "$PLATFORM_CURSOR" = "false" ]
}

@test "_here_edit_field 7 re-enables Copilot if the user disables all three platforms" {
  ask() { printf -v "$2" '%s' "n"; }
  PLATFORM_COPILOT=true
  PLATFORM_CLAUDE=true
  PLATFORM_CURSOR=true
  _here_edit_field 7
  [ "$PLATFORM_COPILOT" = "true" ]
  [ "$PLATFORM_CLAUDE" = "false" ]
  [ "$PLATFORM_CURSOR" = "false" ]
}

# ── _here_edit_field: git-local flags (8, 9) ──────────────────────────────────

@test "_here_edit_field 8 sets GIT_LOCAL_CONFIG true on y" {
  ask() { printf -v "$2" '%s' "y"; }
  GIT_LOCAL_CONFIG=false
  _here_edit_field 8
  [ "$GIT_LOCAL_CONFIG" = "true" ]
}

@test "_here_edit_field 9 sets GIT_LOCAL_MEMORY false on n" {
  ask() { printf -v "$2" '%s' "n"; }
  GIT_LOCAL_MEMORY=true
  _here_edit_field 9
  [ "$GIT_LOCAL_MEMORY" = "false" ]
}

@test "_here_edit_field warns on an out-of-range field instead of crashing" {
  run _here_edit_field 42
  [ "$status" -eq 0 ]
}

# ── _global_edit_field: guardrails mode (1) ───────────────────────────────────

@test "_global_edit_field 1 sets GUARDRAILS_MODE to embedded when answer is 2" {
  ask() { printf -v "$2" '%s' "2"; }
  GUARDRAILS_MODE="split"
  _global_edit_field 1
  [ "$GUARDRAILS_MODE" = "embedded" ]
}

# ── _global_edit_field: platforms (2) ─────────────────────────────────────────

@test "_global_edit_field 2 updates all three platform booleans in order" {
  local call=0
  ask() {
    call=$((call + 1))
    case $call in
      1) printf -v "$2" '%s' "Y" ;; # Copilot
      2) printf -v "$2" '%s' "n" ;; # Claude
      3) printf -v "$2" '%s' "Y" ;; # Cursor
    esac
  }
  PLATFORM_COPILOT=false
  PLATFORM_CLAUDE=true
  PLATFORM_CURSOR=false
  _global_edit_field 2
  [ "$PLATFORM_COPILOT" = "true" ]
  [ "$PLATFORM_CLAUDE" = "false" ]
  [ "$PLATFORM_CURSOR" = "true" ]
}

@test "_global_edit_field 2 re-enables Claude if the user disables all three platforms" {
  ask() { printf -v "$2" '%s' "n"; }
  PLATFORM_COPILOT=true
  PLATFORM_CLAUDE=true
  PLATFORM_CURSOR=true
  _global_edit_field 2
  [ "$PLATFORM_CLAUDE" = "true" ]
  [ "$PLATFORM_COPILOT" = "false" ]
  [ "$PLATFORM_CURSOR" = "false" ]
}

@test "_global_edit_field warns on an out-of-range field instead of crashing" {
  run _global_edit_field 99
  [ "$status" -eq 0 ]
}

# ── Edit loops: d/q dispatch (no interactive field editing) ──────────────────
# _here_print_summary/_global_print_summary echo real text (not stubbed), so
# the loop runs safely; only the terminal "d"/"q" answer matters here.

@test "_here_edit_loop returns 0 immediately when the user answers d (deploy)" {
  ask() { printf -v "$2" '%s' "d"; }
  PROJECT_NAME="x"; PROJECT_DESCRIPTION="x"; TECH_STACK="x"
  REPOSITORY_URL="x"; TEAM_LEAD="x"; GUARDRAILS_MODE="split"
  PLATFORM_COPILOT=true; PLATFORM_CLAUDE=true; PLATFORM_CURSOR=true
  GIT_LOCAL_CONFIG=false; GIT_LOCAL_MEMORY=false; TARGET_DIR="/tmp/x"
  run _here_edit_loop
  [ "$status" -eq 0 ]
}

@test "_here_edit_loop exits 0 when the user answers q (quit)" {
  ask() { printf -v "$2" '%s' "q"; }
  PROJECT_NAME="x"; PROJECT_DESCRIPTION="x"; TECH_STACK="x"
  REPOSITORY_URL="x"; TEAM_LEAD="x"; GUARDRAILS_MODE="split"
  PLATFORM_COPILOT=true; PLATFORM_CLAUDE=true; PLATFORM_CURSOR=true
  GIT_LOCAL_CONFIG=false; GIT_LOCAL_MEMORY=false; TARGET_DIR="/tmp/x"
  run _here_edit_loop
  [ "$status" -eq 0 ]
}

@test "_global_edit_loop returns 0 immediately when the user answers d (deploy)" {
  ask() { printf -v "$2" '%s' "d"; }
  GUARDRAILS_MODE="split"
  PLATFORM_COPILOT=true; PLATFORM_CLAUDE=true; PLATFORM_CURSOR=true
  HOME="${TEST_TMP}" run _global_edit_loop
  [ "$status" -eq 0 ]
}
