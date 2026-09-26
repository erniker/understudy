#!/usr/bin/env bats
# Tests for the model names written into Claude Code agent files.
# Claude Code cannot resolve the dotted Copilot-style names, so every path that
# writes a Claude agent file must translate them to family aliases, while the
# Cursor and Copilot files of the same run keep the raw configured value.
#
# $HOME is overridden per test: the global deploys read it directly and would
# otherwise touch the real developer machine's ~/.claude.

load "../lib/helpers"

setup() {
  setup_tmp
  source_wizard_functions

  PROJECT_NAME="my-project"
  PROJECT_DESCRIPTION="A test project"
  TECH_STACK=".NET + React"
  TEAM_LEAD="Test PM"
  REPOSITORY_URL="https://github.com/test/repo"
  PROJECT_DATE="2026-01-01"
  MODEL_ARCHITECT="claude-opus-4.6"
  MODEL_BACKEND="claude-sonnet-4.5"
  MODEL_FRONTEND="claude-sonnet-4.5"
  MODEL_DEVOPS="claude-haiku-4.5"
  MODEL_SECURITY="claude-sonnet-4.5"
  MODEL_QA="claude-sonnet-4.5"

  TARGET_DIR="${TEST_TMP}/project"
  mkdir -p "$TARGET_DIR"
  FAKE_HOME="${TEST_TMP}/home"
  mkdir -p "$FAKE_HOME"
}

teardown() { teardown_tmp; }

# Assert the frontmatter model line of an agent file.
assert_model() {
  local file="$1" expected="$2"
  [ -f "$file" ]
  [ "$(grep -m1 '^model:' "$file")" = "model: ${expected}" ]
}

assert_claude_aliases() {
  local dir="$1"
  assert_model "${dir}/architect.md" "opus"
  assert_model "${dir}/backend.md" "sonnet"
  assert_model "${dir}/frontend.md" "sonnet"
  assert_model "${dir}/security.md" "sonnet"
  assert_model "${dir}/qa.md" "sonnet"
  assert_model "${dir}/devops.md" "haiku"
}

# ── Project deploy ────────────────────────────────────────────────────────────

@test "deploy_claude writes family aliases into .claude/agents" {
  deploy_claude
  assert_claude_aliases "${TARGET_DIR}/.claude/agents"
}

@test "deploy_claude does not leak the aliases into the MODEL_* globals" {
  deploy_claude
  [ "$MODEL_ARCHITECT" = "claude-opus-4.6" ]
  [ "$MODEL_BACKEND" = "claude-sonnet-4.5" ]
  [ "$MODEL_DEVOPS" = "claude-haiku-4.5" ]
}

@test "Cursor output of the same run keeps the dotted names" {
  deploy_claude
  deploy_cursor
  assert_model "${TARGET_DIR}/.cursor/agents/architect.md" "claude-opus-4.6"
  assert_model "${TARGET_DIR}/.cursor/agents/backend.md" "claude-sonnet-4.5"
  assert_model "${TARGET_DIR}/.cursor/agents/devops.md" "claude-haiku-4.5"
}

@test "Copilot output of the same run keeps the dotted names" {
  deploy_claude
  deploy_copilot
  grep -q 'claude-opus-4\.6' "${TARGET_DIR}/.github/instructions/architect.instructions.md"
  grep -q 'claude-haiku-4\.5' "${TARGET_DIR}/.github/instructions/devops.instructions.md"
}

@test "deploy_claude passes a dashed full ID configured by the user through" {
  MODEL_BACKEND="claude-sonnet-4-5"
  MODEL_QA="claude-haiku-4-5-20251001"
  deploy_claude
  assert_model "${TARGET_DIR}/.claude/agents/backend.md" "claude-sonnet-4-5"
  assert_model "${TARGET_DIR}/.claude/agents/qa.md" "claude-haiku-4-5-20251001"
  assert_model "${TARGET_DIR}/.claude/agents/architect.md" "opus"
}

@test "deploy_claude still preserves an existing customised agent file" {
  mkdir -p "${TARGET_DIR}/.claude/agents"
  printf -- '---\nmodel: claude-sonnet-4.5\n---\nCUSTOM\n' > "${TARGET_DIR}/.claude/agents/backend.md"
  deploy_claude
  grep -q 'CUSTOM' "${TARGET_DIR}/.claude/agents/backend.md"
  assert_model "${TARGET_DIR}/.claude/agents/backend.md" "claude-sonnet-4.5"
}

# ── Global deploy ─────────────────────────────────────────────────────────────

@test "deploy_claude_global writes family aliases into ~/.claude/agents" {
  HOME="$FAKE_HOME" deploy_claude_global
  assert_claude_aliases "${FAKE_HOME}/.claude/agents"
}

@test "global Claude and Cursor deploys of the same run do not cross-contaminate" {
  HOME="$FAKE_HOME" deploy_claude_global
  HOME="$FAKE_HOME" deploy_cursor_global
  assert_claude_aliases "${FAKE_HOME}/.claude/agents"
  assert_model "${FAKE_HOME}/.understudy-global/cursor-agents/architect.md" "claude-opus-4.6"
  assert_model "${FAKE_HOME}/.understudy-global/cursor-agents/backend.md" "claude-sonnet-4.5"
  assert_model "${FAKE_HOME}/.understudy-global/cursor-agents/devops.md" "claude-haiku-4.5"
}

@test "deploy_claude_global passes a dashed full ID configured by the user through" {
  MODEL_ARCHITECT="claude-opus-4-6"
  HOME="$FAKE_HOME" deploy_claude_global
  assert_model "${FAKE_HOME}/.claude/agents/architect.md" "claude-opus-4-6"
  assert_model "${FAKE_HOME}/.claude/agents/backend.md" "sonnet"
}

# ── Optional roles (heredoc-generated frontmatter) ────────────────────────────

@test "add_optional_role_to_project writes an alias for Claude and the dotted name for Cursor" {
  mkdir -p "${TARGET_DIR}/.claude/agents" "${TARGET_DIR}/.cursor/agents" "${TARGET_DIR}/.github/instructions"
  add_optional_role_to_project "data-engineer"
  assert_model "${TARGET_DIR}/.claude/agents/data-engineer.md" "sonnet"
  assert_model "${TARGET_DIR}/.cursor/agents/data-engineer.md" "claude-sonnet-4.5"
}
