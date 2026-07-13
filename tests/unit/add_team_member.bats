#!/usr/bin/env bats
# Tests for add_team_member() (the `understudy --add-member` flow, project
# mode). `ask` is stubbed as a no-op by source_wizard_functions, so these
# tests pre-set `selection`/`TARGET_DIR` directly instead of simulating
# stdin — equivalent to what `ask "Select a number" selection` would have
# assigned.

load "../lib/helpers"

setup() {
  setup_tmp
  source_wizard_functions
  MODEL_BACKEND="claude-sonnet-4.5"

  ROLES_DIR="${TEST_TMP}/roles"
  mkdir -p "$ROLES_DIR"
  cat > "${ROLES_DIR}/data-engineer.instructions.md" << 'EOF'
# Data Engineer — role body
Handles ETL pipelines.
EOF

  PROJECT_DIR="${TEST_TMP}/project"
  mkdir -p "${PROJECT_DIR}/.claude/agents" \
           "${PROJECT_DIR}/.github/instructions" \
           "${PROJECT_DIR}/.cursor/agents"
}

teardown() { teardown_tmp; }

@test "add_team_member copies the role into Claude, Copilot and Cursor" {
  selection=1
  TARGET_DIR="$PROJECT_DIR"
  run add_team_member
  [ "$status" -eq 0 ]
  [ -f "${PROJECT_DIR}/.claude/agents/data-engineer.md" ]
  [ -f "${PROJECT_DIR}/.github/instructions/data-engineer.instructions.md" ]
  [ -f "${PROJECT_DIR}/.cursor/agents/data-engineer.md" ]
}

@test "add_team_member's Claude file has correct frontmatter and model" {
  selection=1
  TARGET_DIR="$PROJECT_DIR"
  add_team_member
  local f="${PROJECT_DIR}/.claude/agents/data-engineer.md"
  grep -q "^name: data-engineer" "$f"
  grep -q "^model: claude-sonnet-4.5" "$f"
  grep -q "Handles ETL pipelines." "$f"
}

@test "add_team_member only copies to platforms that already exist in the target" {
  selection=1
  TARGET_DIR="${TEST_TMP}/claude-only-project"
  mkdir -p "${TARGET_DIR}/.claude/agents"
  add_team_member
  [ -f "${TARGET_DIR}/.claude/agents/data-engineer.md" ]
  [ ! -d "${TARGET_DIR}/.github" ]
  [ ! -d "${TARGET_DIR}/.cursor" ]
}

@test "add_team_member errors out when the target isn't an Understudy project" {
  selection=1
  TARGET_DIR="${TEST_TMP}/not-a-project"
  mkdir -p "$TARGET_DIR"
  run add_team_member
  [ "$status" -eq 1 ]
}

@test "add_team_member updates docs/team-roster.md when present" {
  mkdir -p "${PROJECT_DIR}/docs"
  cp "${UNDERSTUDY_ROOT}/templates/docs/team-roster.md" "${PROJECT_DIR}/docs/team-roster.md"
  selection=1
  TARGET_DIR="$PROJECT_DIR"
  add_team_member
  grep -qi "data engineer" "${PROJECT_DIR}/docs/team-roster.md"
}

@test "add_team_member does not duplicate an already-added role on a second run" {
  selection=1
  TARGET_DIR="$PROJECT_DIR"
  add_team_member
  run add_team_member
  [ "$status" -eq 0 ]
  [ "$(grep -c "^name: data-engineer" "${PROJECT_DIR}/.claude/agents/data-engineer.md")" -eq 1 ]
}
