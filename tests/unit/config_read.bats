#!/usr/bin/env bats
# Tests for the config_read function in wizard.sh
# Covers: value retrieval, defaults, missing keys, missing files, quoted values.

load "../lib/helpers"

setup() {
  setup_tmp
  source_wizard_functions
  FULL_CFG="${FIXTURES}/configs/full.yaml"
  PARTIAL_CFG="${FIXTURES}/configs/partial.yaml"
  EMPTY_CFG="${FIXTURES}/configs/empty.yaml"
  MISSING_CFG="${TEST_TMP}/does-not-exist.yaml"
}

teardown() { teardown_tmp; }

# ── Happy path ────────────────────────────────────────────────────────────────

@test "config_read returns architect model from full config" {
  run config_read "models" "architect" "fallback" "$FULL_CFG"
  [ "$status" -eq 0 ]
  [ "$output" = "claude-opus-4.6" ]
}

@test "config_read returns backend model from full config" {
  run config_read "models" "backend" "fallback" "$FULL_CFG"
  [ "$output" = "claude-sonnet-4.5" ]
}

@test "config_read returns devops model from full config" {
  run config_read "models" "devops" "fallback" "$FULL_CFG"
  [ "$output" = "claude-haiku-4.5" ]
}

@test "config_read returns guardrails mode from full config" {
  run config_read "guardrails" "mode" "split" "$FULL_CFG"
  [ "$output" = "embedded" ]
}

@test "config_read returns platform copilot flag from full config" {
  run config_read "platforms" "copilot" "false" "$FULL_CFG"
  [ "$output" = "true" ]
}

@test "config_read returns platform claude flag (false) from full config" {
  run config_read "platforms" "claude" "true" "$FULL_CFG"
  [ "$output" = "false" ]
}

# ── Defaults and missing keys ─────────────────────────────────────────────────

@test "config_read returns default when key is missing from partial config" {
  run config_read "models" "frontend" "MY_DEFAULT" "$PARTIAL_CFG"
  [ "$output" = "MY_DEFAULT" ]
}

@test "config_read returns custom value when key exists in partial config" {
  run config_read "models" "architect" "fallback" "$PARTIAL_CFG"
  [ "$output" = "custom-model" ]
}

@test "config_read returns default when section is missing" {
  run config_read "nonexistent_section" "some_key" "DEFAULT_VALUE" "$FULL_CFG"
  [ "$output" = "DEFAULT_VALUE" ]
}

@test "config_read returns default for empty config file" {
  run config_read "models" "architect" "DEFAULT" "$EMPTY_CFG"
  [ "$output" = "DEFAULT" ]
}

# ── Missing file ──────────────────────────────────────────────────────────────

@test "config_read returns default when file does not exist" {
  run config_read "models" "architect" "SAFE_DEFAULT" "$MISSING_CFG"
  [ "$status" -eq 0 ]
  [ "$output" = "SAFE_DEFAULT" ]
}

@test "config_read does not error when file does not exist" {
  run config_read "any" "key" "ok" "$MISSING_CFG"
  [ "$status" -eq 0 ]
}

# ── Quoted value stripping ────────────────────────────────────────────────────

@test "config_read strips double quotes from values" {
  run config_read "models" "architect" "fallback" "$FULL_CFG"
  [[ "$output" != *'"'* ]]
}
