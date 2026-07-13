#!/usr/bin/env bats
# Tests for show_help() — a smoke test that --help stays truthful as flags
# get added/renamed. Cheap to run, catches typos in the usage text that
# nothing else in the suite would notice.

load "../lib/helpers"

setup() {
  source_wizard_functions
  discover_modules
}

@test "show_help exits 0" {
  run show_help
  [ "$status" -eq 0 ]
}

@test "show_help prints a Usage section" {
  run show_help
  [[ "$output" == *"Usage:"* ]]
}

@test "show_help mentions --here" {
  run show_help
  [[ "$output" == *"--here"* ]]
}

@test "show_help mentions --global" {
  run show_help
  [[ "$output" == *"--global"* ]]
}

@test "show_help mentions --docs-only" {
  run show_help
  [[ "$output" == *"--docs-only"* ]]
}

@test "show_help mentions --all-roles" {
  run show_help
  [[ "$output" == *"--all-roles"* ]]
}

@test "show_help mentions --uninstall" {
  run show_help
  [[ "$output" == *"--uninstall"* ]]
}

@test "show_help mentions --add-member" {
  run show_help
  [[ "$output" == *"--add-member"* ]]
}

@test "show_help mentions --create-role" {
  run show_help
  [[ "$output" == *"--create-role"* ]]
}

@test "show_help lists supported platforms" {
  run show_help
  [[ "$output" == *"Copilot"* ]]
  [[ "$output" == *"Claude"* ]]
  [[ "$output" == *"Cursor"* ]]
}

# ── Real CLI entrypoint (subprocess) ──────────────────────────────────────────
# Cheap and side-effect-free (show_help never touches disk), so no need for
# HOME/APPDATA isolation here.

@test "understudy --help exits 0 as a real subprocess" {
  run bash "${BATS_TEST_DIRNAME}/../../wizard.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}
