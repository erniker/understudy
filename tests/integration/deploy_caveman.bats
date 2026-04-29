#!/usr/bin/env bats
# Integration tests for the opt-in caveman role deploy across all platforms.
#
# Mirrors the pattern of deploy_all_platforms.bats but adds --caveman to the
# wizard invocation. The unit tests in tests/unit/caveman_role.bats already
# exercise add_optional_role_to_project() and the INCLUDE_CAVEMAN gate
# directly; this file closes the end-to-end gap by running the full wizard
# pipeline so a regression that breaks caveman deploy on, say, Cursor only
# surfaces in CI.
#
# Tracked by issue #53.

WIZARD="${BATS_TEST_DIRNAME}/../../wizard.sh"

setup() {
  TEST_TMP="$(mktemp -d)"
}

teardown() {
  [[ -n "${TEST_TMP:-}" && -d "$TEST_TMP" ]] && rm -rf "$TEST_TMP"
}

# Helper: run wizard non-interactively with extra CLI flags.
# Same answer order as deploy_all_platforms.bats::run_wizard_noninteractive().
# Arguments: project_name base_dir cli_flags... -- copilot claude cursor
run_wizard_with_flags() {
  local project_name="$1"
  local base_dir="$2"
  shift 2
  # Split CLI flags from platform answers via the literal '--' delimiter.
  local flags=()
  while [[ "$#" -gt 0 && "$1" != "--" ]]; do
    flags+=("$1")
    shift
  done
  shift  # drop '--'

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
    | bash "$WIZARD" "${flags[@]}" 2>/dev/null
}

# ── Caveman opt-in: all platforms ─────────────────────────────────────────────

@test "wizard --caveman deploys Copilot caveman.instructions.md" {
  run_wizard_with_flags "myproject" "$TEST_TMP" --caveman -- "Y" "Y" "Y"
  [ -f "$TEST_TMP/myproject/.github/instructions/caveman.instructions.md" ]
}

@test "wizard --caveman deploys Claude caveman.md with frontmatter" {
  run_wizard_with_flags "myproject" "$TEST_TMP" --caveman -- "Y" "Y" "Y"
  local dst="$TEST_TMP/myproject/.claude/agents/caveman.md"
  [ -f "$dst" ]
  grep -q "^name: caveman" "$dst"
  grep -q "^model:" "$dst"
  grep -q "^tools:" "$dst"
}

@test "wizard --caveman deploys Cursor caveman.md with frontmatter" {
  run_wizard_with_flags "myproject" "$TEST_TMP" --caveman -- "Y" "Y" "Y"
  local dst="$TEST_TMP/myproject/.cursor/agents/caveman.md"
  [ -f "$dst" ]
  grep -q "^name: caveman" "$dst"
}

@test "wizard --caveman appends Caveman row to docs/team-roster.md" {
  run_wizard_with_flags "myproject" "$TEST_TMP" --caveman -- "Y" "Y" "Y"
  grep -q "Caveman" "$TEST_TMP/myproject/docs/team-roster.md"
}

@test "wizard --caveman: deployed caveman files have no {{PLACEHOLDER}} leftovers" {
  run_wizard_with_flags "myproject" "$TEST_TMP" --caveman -- "Y" "Y" "Y"
  run grep -E '\{\{[A-Z_]+\}\}' \
    "$TEST_TMP/myproject/.github/instructions/caveman.instructions.md" \
    "$TEST_TMP/myproject/.claude/agents/caveman.md" \
    "$TEST_TMP/myproject/.cursor/agents/caveman.md"
  [ "$status" -ne 0 ]
}

# ── Caveman opt-in: per-platform isolation ────────────────────────────────────

@test "wizard --caveman with Claude only deploys only the Claude caveman file" {
  run_wizard_with_flags "claudeonly" "$TEST_TMP" --caveman -- "n" "Y" "n"
  [ -f "$TEST_TMP/claudeonly/.claude/agents/caveman.md" ]
  [ ! -f "$TEST_TMP/claudeonly/.github/instructions/caveman.instructions.md" ]
  [ ! -f "$TEST_TMP/claudeonly/.cursor/agents/caveman.md" ]
}

@test "wizard --caveman with Cursor only deploys only the Cursor caveman file" {
  run_wizard_with_flags "cursoronly" "$TEST_TMP" --caveman -- "n" "n" "Y"
  [ -f "$TEST_TMP/cursoronly/.cursor/agents/caveman.md" ]
  [ ! -f "$TEST_TMP/cursoronly/.claude/agents/caveman.md" ]
  [ ! -f "$TEST_TMP/cursoronly/.github/instructions/caveman.instructions.md" ]
}

# ── Default (no --caveman): role must NOT be deployed ────────────────────────

@test "wizard without --caveman does NOT deploy any caveman files" {
  run_wizard_with_flags "default" "$TEST_TMP" -- "Y" "Y" "Y"
  [ ! -f "$TEST_TMP/default/.github/instructions/caveman.instructions.md" ]
  [ ! -f "$TEST_TMP/default/.claude/agents/caveman.md" ]
  [ ! -f "$TEST_TMP/default/.cursor/agents/caveman.md" ]
}
