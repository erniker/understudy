#!/usr/bin/env bats
# Integration tests for `understudy --docs-only` — creates persistent
# per-repo memory (docs/spec.md, decisions.md, session-log.md,
# team-roster.md) and understudy.yaml, without deploying any Claude/Copilot
# agent files. This is the complement to `understudy --global`: a shared
# team across every repo, plus real spec-driven memory only for the repos
# that need it.
#
# $HOME is overridden to an isolated temp dir for every test: deploy_docs_only
# calls link_cursor_agents_into_project(), which reads $HOME/.understudy-global
# — without isolation these tests would touch the real developer machine's
# global state (harmless today since hard links only ever add, never delete,
# but not hermetic).

WIZARD="${BATS_TEST_DIRNAME}/../../wizard.sh"

setup() {
  TEST_TMP="$(mktemp -d)"
  FAKE_HOME="${TEST_TMP}/home"
  mkdir -p "$FAKE_HOME"
  PROJ="${TEST_TMP}/myproject"
  mkdir -p "$PROJ"
  echo '{"name":"myproject","description":"A test project"}' > "$PROJ/package.json"
}

teardown() {
  [[ -n "${TEST_TMP:-}" && -d "$TEST_TMP" ]] && rm -rf "$TEST_TMP"
}

run_docs_only() {
  (cd "$PROJ" && HOME="$FAKE_HOME" bash "$WIZARD" --docs-only --yes 2>/dev/null)
}

@test "--docs-only creates the four persistent memory files" {
  run_docs_only
  [ -f "$PROJ/docs/spec.md" ]
  [ -f "$PROJ/docs/decisions.md" ]
  [ -f "$PROJ/docs/session-log.md" ]
  [ -f "$PROJ/docs/team-roster.md" ]
}

@test "--docs-only creates a project-level understudy.yaml" {
  run_docs_only
  [ -f "$PROJ/understudy.yaml" ]
}

@test "--docs-only does NOT deploy any agent files or platform directories" {
  run_docs_only
  [ ! -d "$PROJ/.claude" ]
  [ ! -d "$PROJ/.github" ]
  [ ! -d "$PROJ/.cursor" ]
  [ ! -f "$PROJ/AGENTS.md" ]
  [ ! -f "$PROJ/CLAUDE.md" ]
}

@test "--docs-only infers the real project name from package.json into docs/spec.md" {
  run_docs_only
  grep -q "myproject" "$PROJ/docs/spec.md"
}

@test "--docs-only's team-roster.md points to the global team, not project-relative agent files" {
  run_docs_only
  local roster="$PROJ/docs/team-roster.md"
  grep -q "~/.claude/agents" "$roster"
  ! grep -q "\.github/instructions/architect.instructions.md" "$roster"
}

@test "--docs-only leaves no {{PLACEHOLDER}} tokens in docs/spec.md" {
  run_docs_only
  run grep -c '{{' "$PROJ/docs/spec.md"
  [ "$output" = "0" ]
}

@test "re-running --docs-only does not overwrite a hand-edited docs/spec.md" {
  run_docs_only
  echo "# CUSTOM SPEC CONTENT" >> "$PROJ/docs/spec.md"
  run_docs_only
  grep -q "CUSTOM SPEC CONTENT" "$PROJ/docs/spec.md"
}

@test "--docs-only without --yes proceeds by default (non-destructive, defaults to Y)" {
  echo "" | (cd "$PROJ" && HOME="$FAKE_HOME" bash "$WIZARD" --docs-only 2>/dev/null)
  [ -f "$PROJ/docs/spec.md" ]
}

@test "project --uninstall also removes files created by --docs-only" {
  run_docs_only
  (cd "$PROJ" && HOME="$FAKE_HOME" bash "$WIZARD" --uninstall --yes 2>/dev/null)
  [ ! -f "$PROJ/docs/spec.md" ]
  [ ! -f "$PROJ/understudy.yaml" ]
}

@test "understudy --here still works normally after --docs-only (adds full agent set on top)" {
  run_docs_only
  # --here --yes skips the gather-info confirmation; the one remaining
  # prompt is "Initialize git repository?" at the end of deploy_team().
  echo "n" | (cd "$PROJ" && HOME="$FAKE_HOME" bash "$WIZARD" --here --yes 2>/dev/null)
  # docs/spec.md from --docs-only is preserved (skip-if-exists), and the
  # full agent set now exists alongside it.
  [ -f "$PROJ/docs/spec.md" ]
  [ -f "$PROJ/.claude/agents/architect.md" ]
}

# ── Cursor agent hard-linking ─────────────────────────────────────────────────
# link_cursor_agents_into_project() only has anything to link once a --global
# deploy has populated ~/.understudy-global/cursor-agents/. These tests seed
# that directory directly (cheaper and more focused than running a full
# --global deploy) to exercise the linking logic in isolation.

seed_fake_global_cursor_agents() {
  mkdir -p "${FAKE_HOME}/.understudy-global/cursor-agents"
  cat > "${FAKE_HOME}/.understudy-global/cursor-agents/architect.md" << 'EOF'
---
name: architect
description: "Solutions Architect"
model: claude-opus-4.6
---

You are the Architect.
EOF
}

@test "--docs-only hard-links Cursor agents when a --global cursor source exists" {
  seed_fake_global_cursor_agents
  run_docs_only
  local dst="$PROJ/.cursor/agents/architect.md"
  [ -f "$dst" ]
  # Same inode as the global source == real hard link, not a copy.
  local src_inode dst_inode
  src_inode="$(ls -i "${FAKE_HOME}/.understudy-global/cursor-agents/architect.md" | awk '{print $1}')"
  dst_inode="$(ls -i "$dst" | awk '{print $1}')"
  [ "$src_inode" = "$dst_inode" ]
}

@test "editing the global Cursor agent source is visible through the linked project copy" {
  seed_fake_global_cursor_agents
  run_docs_only
  echo "EXTRA LINE APPENDED GLOBALLY" >> "${FAKE_HOME}/.understudy-global/cursor-agents/architect.md"
  grep -q "EXTRA LINE APPENDED GLOBALLY" "$PROJ/.cursor/agents/architect.md"
}

@test "--docs-only never overwrites a pre-existing .cursor/agents file" {
  seed_fake_global_cursor_agents
  mkdir -p "$PROJ/.cursor/agents"
  echo "MY OWN CUSTOM AGENT" > "$PROJ/.cursor/agents/architect.md"
  run_docs_only
  grep -q "MY OWN CUSTOM AGENT" "$PROJ/.cursor/agents/architect.md"
}

@test "--docs-only creates no .cursor directory when Cursor wasn't part of the global deploy" {
  # No seed_fake_global_cursor_agents call — mirrors a --global run with
  # PLATFORM_CURSOR=false, or no --global run at all.
  run_docs_only
  [ ! -d "$PROJ/.cursor" ]
}

# ── shell-scripting auto-detection ────────────────────────────────────────────
# --global can't scan any single repo, so by default it only deploys
# git-specialist/repo-documenter. --docs-only fills that gap: it runs the
# same detection --here uses and, if the repo has scripts, adds
# shell-scripting globally (not just to this repo) without needing
# --all-roles or --add-member ahead of time. Claude presence is simulated by
# creating $FAKE_HOME/.claude/agents (the filesystem evidence
# deploy_docs_only uses to reconstruct which platforms are actually live,
# since there's no stored record of a prior --global run's choices).

seed_fake_global_claude() {
  mkdir -p "${FAKE_HOME}/.claude/agents"
}

@test "--docs-only adds shell-scripting globally when the repo has a shell script" {
  seed_fake_global_claude
  echo '#!/bin/bash' > "$PROJ/deploy.sh"
  run_docs_only
  [ -f "${FAKE_HOME}/.claude/agents/shell-scripting.md" ]
}

@test "--docs-only does NOT add shell-scripting when the repo has no scripts" {
  seed_fake_global_claude
  run_docs_only
  [ ! -f "${FAKE_HOME}/.claude/agents/shell-scripting.md" ]
}

@test "--docs-only auto-detected shell-scripting also gets linked into Cursor agents" {
  seed_fake_global_claude
  seed_fake_global_cursor_agents
  echo '#!/bin/bash' > "$PROJ/deploy.sh"
  run_docs_only
  [ -f "$PROJ/.cursor/agents/shell-scripting.md" ]
}

@test "--docs-only shell-scripting auto-detection is idempotent (no error on second run)" {
  seed_fake_global_claude
  echo '#!/bin/bash' > "$PROJ/deploy.sh"
  run_docs_only
  run_docs_only
  [ -f "${FAKE_HOME}/.claude/agents/shell-scripting.md" ]
}

@test "--docs-only does not re-add shell-scripting if --all-roles already deployed it globally" {
  seed_fake_global_claude
  cat > "${FAKE_HOME}/.claude/agents/shell-scripting.md" << 'EOF'
---
name: shell-scripting
description: "Pre-existing from --all-roles"
model: claude-sonnet-4.5
---
PRE-EXISTING CONTENT
EOF
  echo '#!/bin/bash' > "$PROJ/deploy.sh"
  run_docs_only
  grep -q "PRE-EXISTING CONTENT" "${FAKE_HOME}/.claude/agents/shell-scripting.md"
}
