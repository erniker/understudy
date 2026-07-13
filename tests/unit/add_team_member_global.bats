#!/usr/bin/env bats
# Tests for add_team_member_global() (the `understudy --global --add-member`
# flow). `ask` is stubbed as a no-op by source_wizard_functions, so these
# tests pre-set `selection` directly instead of simulating stdin.
#
# $HOME is overridden per test: global_claude_dir()/global_state_dir() read
# it directly, and without isolation these tests would touch the real
# developer machine's ~/.claude and ~/.understudy-global.

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

  FAKE_HOME="${TEST_TMP}/home"
  mkdir -p "${FAKE_HOME}/.claude/agents"
}

teardown() { teardown_tmp; }

@test "add_team_member_global adds the role to the global Claude agents dir" {
  selection=1
  HOME="$FAKE_HOME" run add_team_member_global
  [ "$status" -eq 0 ]
  [ -f "${FAKE_HOME}/.claude/agents/data-engineer.md" ]
}

@test "add_team_member_global also seeds the Cursor canonical source" {
  mkdir -p "${FAKE_HOME}/.understudy-global/cursor-agents"
  selection=1
  HOME="$FAKE_HOME" run add_team_member_global
  [ -f "${FAKE_HOME}/.understudy-global/cursor-agents/data-engineer.md" ]
}

@test "add_team_member_global errors when no global deployment is found" {
  local empty_home="${TEST_TMP}/empty-home"
  mkdir -p "$empty_home"
  selection=1
  HOME="$empty_home" APPDATA="${empty_home}/AppData/Roaming" run add_team_member_global
  [ "$status" -eq 1 ]
}

@test "add_team_member_global warns and returns (not exit) when the catalog is empty" {
  rm -f "${ROLES_DIR}/data-engineer.instructions.md"
  selection=1
  HOME="$FAKE_HOME" run add_team_member_global
  [ "$status" -eq 0 ]
}
