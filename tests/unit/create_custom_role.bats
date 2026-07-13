#!/usr/bin/env bats
# Tests for create_custom_role() (the `understudy --create-role` flow).
#
# ROLES_DIR is overridden to an isolated temp directory for every test:
# the real function writes to "${ROLES_DIR}/${ROLE_NAME}.instructions.md",
# and ROLES_DIR defaults to the real repo's roles/ catalog — without this
# override, a real invocation would litter the actual repo with test roles.
#
# `ask` is stubbed (by source_wizard_functions) as a no-op, so these tests
# pre-set the ROLE_* variables directly instead of simulating stdin —
# equivalent to what `ask "prompt" ROLE_NAME` would have assigned.

load "../lib/helpers"

setup() {
  setup_tmp
  source_wizard_functions
  ROLES_DIR="${TEST_TMP}/roles"
  mkdir -p "$ROLES_DIR"
}

teardown() { teardown_tmp; }

set_role_vars() {
  ROLE_NAME="data-wizard"
  ROLE_TITLE="Data Wizard"
  ROLE_DESC="Handles data pipelines end to end."
  ROLE_EXPERTISE="ETL, SQL, dbt"
  ROLE_MOTTO="Garbage in, gold out."
}

@test "create_custom_role writes the role file under ROLES_DIR" {
  set_role_vars
  run create_custom_role
  [ "$status" -eq 0 ]
  [ -f "${ROLES_DIR}/data-wizard.instructions.md" ]
}

@test "create_custom_role never touches the real repo's roles/ catalog" {
  set_role_vars
  run create_custom_role
  [ ! -f "${UNDERSTUDY_ROOT}/roles/data-wizard.instructions.md" ]
}

@test "create_custom_role includes the role title and motto" {
  set_role_vars
  create_custom_role
  local f="${ROLES_DIR}/data-wizard.instructions.md"
  grep -q "Data Wizard" "$f"
  grep -q "Garbage in, gold out." "$f"
}

@test "create_custom_role formats comma-separated expertise as a bullet list" {
  set_role_vars
  create_custom_role
  local f="${ROLES_DIR}/data-wizard.instructions.md"
  grep -q "^- ETL$" "$f"
  grep -q "^- SQL$" "$f"
  grep -q "^- dbt$" "$f"
}
