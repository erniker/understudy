#!/usr/bin/env bats
# Tests for claude_model_id in wizard.sh
# Covers: dotted Copilot-style names -> Claude Code family aliases, and every
#         kind of value that must pass through untouched.

load "../lib/helpers"

setup() {
  setup_tmp
  source_wizard_functions
}

teardown() { teardown_tmp; }

# ── Dotted names become family aliases ────────────────────────────────────────

@test "claude_model_id maps claude-opus-4.6 to the opus alias" {
  run claude_model_id "claude-opus-4.6"
  [ "$status" -eq 0 ]
  [ "$output" = "opus" ]
}

@test "claude_model_id maps claude-sonnet-4.5 to the sonnet alias" {
  run claude_model_id "claude-sonnet-4.5"
  [ "$output" = "sonnet" ]
}

@test "claude_model_id maps claude-haiku-4.5 to the haiku alias" {
  run claude_model_id "claude-haiku-4.5"
  [ "$output" = "haiku" ]
}

# ── Everything else passes through ────────────────────────────────────────────

@test "claude_model_id leaves the family aliases unchanged" {
  run claude_model_id "opus"
  [ "$output" = "opus" ]
  run claude_model_id "sonnet"
  [ "$output" = "sonnet" ]
  run claude_model_id "haiku"
  [ "$output" = "haiku" ]
}

@test "claude_model_id leaves inherit unchanged" {
  run claude_model_id "inherit"
  [ "$output" = "inherit" ]
}

@test "claude_model_id leaves dashed full IDs unchanged (pinning escape hatch)" {
  run claude_model_id "claude-sonnet-4-5"
  [ "$output" = "claude-sonnet-4-5" ]
  run claude_model_id "claude-haiku-4-5-20251001"
  [ "$output" = "claude-haiku-4-5-20251001" ]
  run claude_model_id "claude-opus-4-6"
  [ "$output" = "claude-opus-4-6" ]
}

@test "claude_model_id leaves unknown/custom strings unchanged" {
  run claude_model_id "custom-model"
  [ "$output" = "custom-model" ]
  run claude_model_id "gpt-4.1"
  [ "$output" = "gpt-4.1" ]
}

@test "claude_model_id leaves the empty string unchanged" {
  run claude_model_id ""
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}
