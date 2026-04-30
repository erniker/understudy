#!/usr/bin/env bats
# Tests for the caveman optional role.
# Covers:
#   - role file exists in modules/caveman/ with the expected shape
#   - add_optional_role_to_project "caveman" deploys to all 3 platforms
#   - frontmatter shape per platform
#   - team-roster.md row added
#   - role is opt-in: NOT auto-deployed by deploy_default_optional_roles when
#     INCLUDE_CAVEMAN=false (the default)

load "../../../tests/lib/helpers"

setup() {
  setup_tmp
  source_wizard_functions

  TARGET_DIR="${TEST_TMP}/proj"
  mkdir -p "${TARGET_DIR}/.github/instructions"
  mkdir -p "${TARGET_DIR}/.claude/agents"
  mkdir -p "${TARGET_DIR}/.cursor/agents"
  mkdir -p "${TARGET_DIR}/docs"

  # Minimal team-roster with the expected marker
  cat > "${TARGET_DIR}/docs/team-roster.md" << 'ROSTER'
# Team roster

| Name | Role | File | Status |
| --- | --- | --- | --- |
<!-- new members here -->
ROSTER
}

teardown() { teardown_tmp; }

# ── Catalog ───────────────────────────────────────────────────────────────────

@test "caveman role file exists in modules/caveman/" {
  [ -f "${UNDERSTUDY_ROOT}/modules/caveman/role.instructions.md" ]
}

@test "caveman role file declares its identity and motto" {
  run grep -q "Caveman of the Understudy team" "${UNDERSTUDY_ROOT}/modules/caveman/role.instructions.md"
  [ "$status" -eq 0 ]
  run grep -q "Why use many token when few token do trick" "${UNDERSTUDY_ROOT}/modules/caveman/role.instructions.md"
  [ "$status" -eq 0 ]
}

@test "caveman role file documents the three intensity levels" {
  run grep -E "lite|full|ultra" "${UNDERSTUDY_ROOT}/modules/caveman/role.instructions.md"
  [ "$status" -eq 0 ]
}

# ── Deployment via add_optional_role_to_project ──────────────────────────────

@test "add_optional_role_to_project caveman deploys Copilot file" {
  add_optional_role_to_project "caveman"
  [ -f "${TARGET_DIR}/.github/instructions/caveman.instructions.md" ]
}

@test "add_optional_role_to_project caveman deploys Claude file with frontmatter" {
  add_optional_role_to_project "caveman"
  local dst="${TARGET_DIR}/.claude/agents/caveman.md"
  [ -f "$dst" ]
  run grep -q "^name: caveman" "$dst"
  [ "$status" -eq 0 ]
  run grep -q "^model:" "$dst"
  [ "$status" -eq 0 ]
  run grep -q "^tools:" "$dst"
  [ "$status" -eq 0 ]
}

@test "add_optional_role_to_project caveman deploys Cursor file with frontmatter" {
  add_optional_role_to_project "caveman"
  local dst="${TARGET_DIR}/.cursor/agents/caveman.md"
  [ -f "$dst" ]
  run grep -q "^name: caveman" "$dst"
  [ "$status" -eq 0 ]
}

@test "add_optional_role_to_project caveman appends a team-roster row" {
  add_optional_role_to_project "caveman"
  run grep -q "Caveman" "${TARGET_DIR}/docs/team-roster.md"
  [ "$status" -eq 0 ]
}

@test "deployed caveman files have no leftover {{PLACEHOLDER}} tokens" {
  add_optional_role_to_project "caveman"
  run grep -E '\{\{[A-Z_]+\}\}' \
    "${TARGET_DIR}/.github/instructions/caveman.instructions.md" \
    "${TARGET_DIR}/.claude/agents/caveman.md" \
    "${TARGET_DIR}/.cursor/agents/caveman.md"
  [ "$status" -ne 0 ]
}

# ── Opt-in behaviour ─────────────────────────────────────────────────────────

@test "deploy_default_optional_roles does NOT include caveman by default" {
  # Required globals for the function
  TECH_STACK="Python"
  DETECTED_STACK=""
  DETECTED_HAS_SHELL=false
  # MODULE_INCLUDE was populated by source_wizard_functions; keep it default
  # (caveman = false) so this asserts the opt-in default.
  MODULE_INCLUDE[caveman]=false

  deploy_default_optional_roles

  [ ! -f "${TARGET_DIR}/.github/instructions/caveman.instructions.md" ]
  [ ! -f "${TARGET_DIR}/.claude/agents/caveman.md" ]
  [ ! -f "${TARGET_DIR}/.cursor/agents/caveman.md" ]
}

@test "deploy_default_optional_roles includes caveman when its module flag is set" {
  TECH_STACK="Python"
  DETECTED_STACK=""
  DETECTED_HAS_SHELL=false
  MODULE_INCLUDE[caveman]=true

  deploy_default_optional_roles

  [ -f "${TARGET_DIR}/.github/instructions/caveman.instructions.md" ]
  [ -f "${TARGET_DIR}/.claude/agents/caveman.md" ]
  [ -f "${TARGET_DIR}/.cursor/agents/caveman.md" ]
}
