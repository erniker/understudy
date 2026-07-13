#!/usr/bin/env bats
# Integration tests for `understudy --global`. Runs the real wizard.sh as a
# subprocess with $HOME AND $APPDATA overridden to an isolated temp directory
# so these tests never touch the real developer machine's ~/.claude,
# ~/.config, or (on Windows) the real %APPDATA%/Code/User VS Code profile.
# detect_vscode_user_dirs() reads $APPDATA directly on Windows — it is a
# separate env var from $HOME, so both must be overridden or the wizard will
# find and write to the tester's real VS Code profile.
#
# check_for_updates() short-circuits immediately here because SCRIPT_DIR
# (the real understudy repo) has a .git directory — no network call happens.

WIZARD="${BATS_TEST_DIRNAME}/../../wizard.sh"

setup() {
  TEST_TMP="$(mktemp -d)"
  FAKE_HOME="${TEST_TMP}/home"
  mkdir -p "$FAKE_HOME"
}

teardown() {
  [[ -n "${TEST_TMP:-}" && -d "$TEST_TMP" ]] && rm -rf "$TEST_TMP"
}

run_global_deploy() {
  # UNDERSTUDY_SKIP_JQ_INSTALL=1 guarantees no test ever attempts a real
  # package-manager install, regardless of whether jq happens to be present
  # on the machine running the suite.
  HOME="$FAKE_HOME" APPDATA="${FAKE_HOME}/AppData/Roaming" UNDERSTUDY_SKIP_JQ_INSTALL=1 \
    bash "$WIZARD" --global --yes "$@" 2>/dev/null
}

# ── Claude Code (full support) ────────────────────────────────────────────────

@test "--global creates ~/.claude/CLAUDE.md" {
  run_global_deploy
  [ -f "${FAKE_HOME}/.claude/CLAUDE.md" ]
}

@test "--global creates all 6 Claude Code agent files" {
  run_global_deploy
  local dir="${FAKE_HOME}/.claude/agents"
  [ -f "$dir/architect.md" ]
  [ -f "$dir/backend.md" ]
  [ -f "$dir/frontend.md" ]
  [ -f "$dir/devops.md" ]
  [ -f "$dir/security.md" ]
  [ -f "$dir/qa.md" ]
}

@test "--global auto-deploys optional roles (git-specialist, repo-documenter)" {
  run_global_deploy
  local dir="${FAKE_HOME}/.claude/agents"
  [ -f "$dir/git-specialist.md" ]
  [ -f "$dir/repo-documenter.md" ]
}

@test "--global does NOT deploy the extended role catalog without --all-roles" {
  run_global_deploy
  [ ! -f "${FAKE_HOME}/.claude/agents/data-engineer.md" ]
  [ ! -f "${FAKE_HOME}/.claude/agents/sre.md" ]
}

@test "--global --all-roles deploys the entire role catalog" {
  run_global_deploy --all-roles
  local dir="${FAKE_HOME}/.claude/agents"
  [ -f "$dir/data-engineer.md" ]
  [ -f "$dir/ml-engineer.md" ]
  [ -f "$dir/mobile-engineer.md" ]
  [ -f "$dir/sre.md" ]
  [ -f "$dir/tech-writer.md" ]
  [ -f "$dir/shell-scripting.md" ]
  [ -f "$dir/git-specialist.md" ]
  [ -f "$dir/repo-documenter.md" ]
}

@test "--global creates Claude settings.json with an ABSOLUTE hook path" {
  run_global_deploy
  local settings="${FAKE_HOME}/.claude/settings.json"
  [ -f "$settings" ]
  grep -qF "${FAKE_HOME}/.claude/hooks/guardrails-check.sh" "$settings"
  # The project-mode relative form must NOT appear here — it would not
  # resolve, since this hook runs with cwd = whatever repo is open.
  ! grep -qF '".claude/hooks/guardrails-check.sh' "$settings"
}

@test "--global makes the guardrails hook executable" {
  run_global_deploy
  [ -x "${FAKE_HOME}/.claude/hooks/guardrails-check.sh" ]
}

@test "--global injects guardrails into the global CLAUDE.md" {
  run_global_deploy
  grep -q "GUARDRAIL" "${FAKE_HOME}/.claude/CLAUDE.md"
}

@test "--global deploys the localize-project command for Claude" {
  run_global_deploy
  local f="${FAKE_HOME}/.claude/commands/localize-project.md"
  [ -f "$f" ]
  grep -q "understudy --docs-only --yes" "$f"
}

@test "--global's start-session command mentions localize-project" {
  run_global_deploy
  grep -q "localize-project" "${FAKE_HOME}/.claude/commands/start-session.md"
}

@test "--global CLAUDE.md has no leftover {{PLACEHOLDER}} tokens" {
  run_global_deploy
  run grep -c '{{' "${FAKE_HOME}/.claude/CLAUDE.md"
  [ "$output" = "0" ]
}

# ── Copilot / VS Code (best-effort — no profile present in the fake home) ────

@test "--global skips Copilot gracefully when no VS Code profile is found" {
  run_global_deploy
  # No VS Code profile exists under the fake $HOME, so nothing Copilot-shaped
  # should have been fabricated, and the run must still succeed (Claude and
  # Cursor artifacts land regardless).
  [ ! -d "${FAKE_HOME}/.config/Code" ]
  ! grep -q "understudy/instructions" "${FAKE_HOME}/.understudy-global/manifest"
  [ -f "${FAKE_HOME}/.claude/CLAUDE.md" ]
}

# Fake profile covering every OS branch detect_vscode_user_dirs checks, so
# this test exercises the Copilot path regardless of which OS runs the suite.
create_fake_vscode_profile() {
  mkdir -p "${FAKE_HOME}/.config/Code/User"
  mkdir -p "${FAKE_HOME}/AppData/Roaming/Code/User"
  mkdir -p "${FAKE_HOME}/Library/Application Support/Code/User"
}

@test "--global deploys the localize-project prompt for Copilot when a VS Code profile exists" {
  create_fake_vscode_profile
  run_global_deploy
  local found=""
  for f in "${FAKE_HOME}/.config/Code/User/understudy/prompts/localize-project.prompt.md" \
           "${FAKE_HOME}/AppData/Roaming/Code/User/understudy/prompts/localize-project.prompt.md" \
           "${FAKE_HOME}/Library/Application Support/Code/User/understudy/prompts/localize-project.prompt.md"; do
    [[ -f "$f" ]] && found="$f"
  done
  [ -n "$found" ]
  grep -q "understudy --docs-only --yes" "$found"
}

@test "--global's Copilot start-session prompt is global-flavored (mentions localize-project)" {
  create_fake_vscode_profile
  run_global_deploy
  local found=""
  for f in "${FAKE_HOME}/.config/Code/User/understudy/prompts/start-session.prompt.md" \
           "${FAKE_HOME}/AppData/Roaming/Code/User/understudy/prompts/start-session.prompt.md" \
           "${FAKE_HOME}/Library/Application Support/Code/User/understudy/prompts/start-session.prompt.md"; do
    [[ -f "$f" ]] && found="$f"
  done
  [ -n "$found" ]
  grep -q "localize-project" "$found"
}

# ── Cursor (manual paste-block) ───────────────────────────────────────────────

@test "--global generates the Cursor paste-block file" {
  run_global_deploy
  local f="${FAKE_HOME}/.understudy-global/cursor-user-rules.md"
  [ -f "$f" ]
  grep -q "GUARDRAIL" "$f"
  grep -qi "User Rules" "$f"
}

# ── Manifest + install-payload separation ─────────────────────────────────────

@test "--global writes a deploy manifest under ~/.understudy-global" {
  run_global_deploy
  [ -f "${FAKE_HOME}/.understudy-global/manifest" ]
  grep -qF "${FAKE_HOME}/.claude/CLAUDE.md" "${FAKE_HOME}/.understudy-global/manifest"
}

@test "--global never writes state under ~/.understudy (that's the install payload dir)" {
  run_global_deploy
  [ ! -d "${FAKE_HOME}/.understudy" ]
}

# ── Idempotency / re-run safety ───────────────────────────────────────────────

@test "re-running --global does not overwrite a hand-edited global CLAUDE.md" {
  run_global_deploy
  echo "# CUSTOM GLOBAL CONTENT" >> "${FAKE_HOME}/.claude/CLAUDE.md"
  run_global_deploy
  grep -q "CUSTOM GLOBAL CONTENT" "${FAKE_HOME}/.claude/CLAUDE.md"
}

# ── Uninstall ──────────────────────────────────────────────────────────────────

@test "--global --uninstall removes manifest-tracked files" {
  run_global_deploy
  [ -f "${FAKE_HOME}/.claude/CLAUDE.md" ]
  HOME="$FAKE_HOME" APPDATA="${FAKE_HOME}/AppData/Roaming" bash "$WIZARD" --global --uninstall 2>/dev/null
  [ ! -f "${FAKE_HOME}/.claude/CLAUDE.md" ]
  [ ! -f "${FAKE_HOME}/.understudy-global/manifest" ]
}

@test "--global --uninstall never removes a file the user already had" {
  mkdir -p "${FAKE_HOME}/.claude/agents"
  echo "# my own agent, not from Understudy" > "${FAKE_HOME}/.claude/agents/my-custom-agent.md"
  run_global_deploy
  HOME="$FAKE_HOME" APPDATA="${FAKE_HOME}/AppData/Roaming" bash "$WIZARD" --global --uninstall 2>/dev/null
  [ -f "${FAKE_HOME}/.claude/agents/my-custom-agent.md" ]
}

# ── Regression guard ───────────────────────────────────────────────────────────
# Per-project deploy (understudy/--here) is exercised unmodified by
# tests/integration/deploy_all_platforms.bats — this file only adds global
# mode coverage and must never need changes there.
