#!/usr/bin/env bats
# Integration tests for the full deployment flow of wizard.sh
# Runs the wizard non-interactively via environment variables to simulate
# all combinations: each platform alone, all three together, integration mode.
#
# Strategy: we call wizard.sh with stdin piped so interactive prompts are fed
# automatically, and we verify the output file tree.

WIZARD="${BATS_TEST_DIRNAME}/../../wizard.sh"
UNDERSTUDY_ROOT="${BATS_TEST_DIRNAME}/../.."

setup() {
  TEST_TMP="$(mktemp -d)"
}

teardown() {
  [[ -n "${TEST_TMP:-}" && -d "$TEST_TMP" ]] && rm -rf "$TEST_TMP"
}

# Helper: run wizard with pre-filled answers via stdin
# Arguments: project_name base_dir [platform answers: Y/n Y/n Y/n]
run_wizard_noninteractive() {
  local project_name="$1"
  local base_dir="$2"
  shift 2
  # Answers in order:
  # project name, base dir, description, stack, PM, repo URL,
  # guardrails mode (1=split), copilot (Y), claude (Y), cursor (Y),
  # keep AI config local (N), keep session memory local (N),
  # confirm deploy (Y), git init (n)
  printf '%s\n' \
    "$project_name" \
    "$base_dir" \
    "Test description" \
    ".NET + React" \
    "Test PM" \
    "local" \
    "1" \
    "$@" \
    "N" \
    "N" \
    "Y" \
    "n" \
    | bash "$WIZARD" 2>/dev/null
}

# ── All platforms ─────────────────────────────────────────────────────────────

@test "full deploy (all platforms) creates AGENTS.md" {
  run_wizard_noninteractive "myproject" "$TEST_TMP" "Y" "Y" "Y"
  [ -f "$TEST_TMP/myproject/AGENTS.md" ]
}

@test "full deploy (all platforms) creates CLAUDE.md" {
  run_wizard_noninteractive "myproject" "$TEST_TMP" "Y" "Y" "Y"
  [ -f "$TEST_TMP/myproject/CLAUDE.md" ]
}

@test "full deploy (all platforms) creates .github/copilot-instructions.md" {
  run_wizard_noninteractive "myproject" "$TEST_TMP" "Y" "Y" "Y"
  [ -f "$TEST_TMP/myproject/.github/copilot-instructions.md" ]
}

@test "full deploy (all platforms) creates all 6 Copilot instruction files" {
  run_wizard_noninteractive "myproject" "$TEST_TMP" "Y" "Y" "Y"
  local dir="$TEST_TMP/myproject/.github/instructions"
  [ -f "$dir/architect.instructions.md" ]
  [ -f "$dir/backend.instructions.md" ]
  [ -f "$dir/frontend.instructions.md" ]
  [ -f "$dir/devops.instructions.md" ]
  [ -f "$dir/security.instructions.md" ]
  [ -f "$dir/qa-engineer.instructions.md" ]
}

@test "full deploy creates guardrails.instructions.md in split mode" {
  run_wizard_noninteractive "myproject" "$TEST_TMP" "Y" "Y" "Y"
  [ -f "$TEST_TMP/myproject/.github/instructions/guardrails.instructions.md" ]
}

@test "full deploy creates all 6 Claude Code agent files" {
  run_wizard_noninteractive "myproject" "$TEST_TMP" "Y" "Y" "Y"
  local dir="$TEST_TMP/myproject/.claude/agents"
  [ -f "$dir/architect.md" ]
  [ -f "$dir/backend.md" ]
  [ -f "$dir/frontend.md" ]
  [ -f "$dir/devops.md" ]
  [ -f "$dir/security.md" ]
  [ -f "$dir/qa.md" ]
}

@test "full deploy creates all 4 Claude Code commands" {
  run_wizard_noninteractive "myproject" "$TEST_TMP" "Y" "Y" "Y"
  local dir="$TEST_TMP/myproject/.claude/commands"
  [ -f "$dir/start-session.md" ]
  [ -f "$dir/end-session.md" ]
  [ -f "$dir/design-feature.md" ]
  [ -f "$dir/security-review.md" ]
}

@test "full deploy creates Claude Code settings.json" {
  run_wizard_noninteractive "myproject" "$TEST_TMP" "Y" "Y" "Y"
  [ -f "$TEST_TMP/myproject/.claude/settings.json" ]
}

@test "full deploy creates guardrails hook and makes it executable" {
  run_wizard_noninteractive "myproject" "$TEST_TMP" "Y" "Y" "Y"
  local hook="$TEST_TMP/myproject/.claude/hooks/guardrails-check.sh"
  [ -f "$hook" ]
  [ -x "$hook" ]
}

@test "full deploy creates all 6 Cursor agent files" {
  run_wizard_noninteractive "myproject" "$TEST_TMP" "Y" "Y" "Y"
  local dir="$TEST_TMP/myproject/.cursor/agents"
  [ -f "$dir/architect.md" ]
  [ -f "$dir/backend.md" ]
  [ -f "$dir/frontend.md" ]
  [ -f "$dir/devops.md" ]
  [ -f "$dir/security.md" ]
  [ -f "$dir/qa-engineer.md" ]
}

@test "full deploy creates Cursor global rule files" {
  run_wizard_noninteractive "myproject" "$TEST_TMP" "Y" "Y" "Y"
  [ -f "$TEST_TMP/myproject/.cursor/rules/understudy-global.mdc" ]
  [ -f "$TEST_TMP/myproject/.cursor/rules/guardrails.mdc" ]
}

@test "full deploy creates docs/ memory files" {
  run_wizard_noninteractive "myproject" "$TEST_TMP" "Y" "Y" "Y"
  local dir="$TEST_TMP/myproject/docs"
  [ -f "$dir/spec.md" ]
  [ -f "$dir/decisions.md" ]
  [ -f "$dir/session-log.md" ]
  [ -f "$dir/team-roster.md" ]
}

@test "full deploy creates understudy.yaml at project root" {
  run_wizard_noninteractive "myproject" "$TEST_TMP" "Y" "Y" "Y"
  [ -f "$TEST_TMP/myproject/understudy.yaml" ]
}

@test "full deploy creates VS Code prompt files" {
  run_wizard_noninteractive "myproject" "$TEST_TMP" "Y" "Y" "Y"
  local dir="$TEST_TMP/myproject/.github/prompts"
  [ -f "$dir/start-session.prompt.md" ]
  [ -f "$dir/end-session.prompt.md" ]
  [ -f "$dir/design-feature.prompt.md" ]
  [ -f "$dir/security-review.prompt.md" ]
}

# ── Placeholder substitution in deployed files ────────────────────────────────

@test "AGENTS.md contains project name after deploy" {
  run_wizard_noninteractive "myproject" "$TEST_TMP" "Y" "Y" "Y"
  grep -q "myproject" "$TEST_TMP/myproject/AGENTS.md"
}

@test "CLAUDE.md contains project name after deploy" {
  run_wizard_noninteractive "myproject" "$TEST_TMP" "Y" "Y" "Y"
  grep -q "myproject" "$TEST_TMP/myproject/CLAUDE.md"
}

@test "CLAUDE.md has no leftover {{PLACEHOLDER}} tokens" {
  run_wizard_noninteractive "myproject" "$TEST_TMP" "Y" "Y" "Y"
  run grep -c '{{' "$TEST_TMP/myproject/CLAUDE.md"
  [ "$output" = "0" ]
}

@test "AGENTS.md has no leftover {{PLACEHOLDER}} tokens" {
  run_wizard_noninteractive "myproject" "$TEST_TMP" "Y" "Y" "Y"
  run grep -c '{{' "$TEST_TMP/myproject/AGENTS.md"
  [ "$output" = "0" ]
}

@test "guardrails are injected into copilot-instructions.md" {
  run_wizard_noninteractive "myproject" "$TEST_TMP" "Y" "Y" "Y"
  grep -q "GUARDRAIL" "$TEST_TMP/myproject/.github/copilot-instructions.md"
}

@test "guardrails are injected into CLAUDE.md" {
  run_wizard_noninteractive "myproject" "$TEST_TMP" "Y" "Y" "Y"
  grep -q "GUARDRAIL" "$TEST_TMP/myproject/CLAUDE.md"
}

# ── Claude only ───────────────────────────────────────────────────────────────

@test "Claude-only deploy creates CLAUDE.md but not AGENTS.md" {
  printf '%s\n' "claudeonly" "$TEST_TMP" "Desc" ".NET" "PM" "local" "1" "n" "Y" "n" "Y" "n" \
    | bash "$WIZARD" 2>/dev/null || true
  [ -f "$TEST_TMP/claudeonly/CLAUDE.md" ]
  [ ! -f "$TEST_TMP/claudeonly/AGENTS.md" ]
}

# ── Integration mode (project already has Understudy) ────────────────────────

@test "re-deploy does not overwrite existing CLAUDE.md" {
  # First deploy
  run_wizard_noninteractive "existing" "$TEST_TMP" "Y" "Y" "Y"

  # Modify CLAUDE.md to detect preservation
  echo "# CUSTOM CONTENT" >> "$TEST_TMP/existing/CLAUDE.md"

  # Second deploy (re-deploy) — wizard detects existing Understudy and asks to continue
  printf '%s\n' "existing" "$TEST_TMP" "Y" "Y" "n" \
    | bash "$WIZARD" 2>/dev/null || true

  grep -q "CUSTOM CONTENT" "$TEST_TMP/existing/CLAUDE.md"
}
