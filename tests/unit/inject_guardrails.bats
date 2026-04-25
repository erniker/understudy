#!/usr/bin/env bats
# Tests for inject_guardrails_block and generate_guardrails_critical in wizard.sh
# Covers: split mode, embedded mode, marker cleanup, idempotency.

load "../lib/helpers"

setup() {
  setup_tmp
  source_wizard_functions

  # A minimal file with the marker block
  MARKED_FILE="${TEST_TMP}/instructions.md"
  cat > "$MARKED_FILE" << 'EOF'
# Project instructions

Some content above.

<!-- GUARDRAILS_START -->
old guardrails content
<!-- GUARDRAILS_END -->

Some content below.
EOF
}

teardown() { teardown_tmp; }

# ── generate_guardrails_critical ──────────────────────────────────────────────

@test "generate_guardrails_critical (split) contains Security section" {
  run generate_guardrails_critical "split"
  [[ "$output" == *"### Security"* ]]
}

@test "generate_guardrails_critical (split) contains Destructive section" {
  run generate_guardrails_critical "split"
  [[ "$output" == *"### Destructive"* ]]
}

@test "generate_guardrails_critical (split) contains reference to guardrails file" {
  run generate_guardrails_critical "split"
  [[ "$output" == *"guardrails.instructions.md"* ]]
}

@test "generate_guardrails_critical (embedded) does NOT reference guardrails file" {
  run generate_guardrails_critical "embedded"
  [[ "$output" != *"guardrails.instructions.md"* ]]
}

@test "generate_guardrails_critical (embedded) still contains Security section" {
  run generate_guardrails_critical "embedded"
  [[ "$output" == *"### Security"* ]]
}

@test "generate_guardrails_critical output is non-empty" {
  run generate_guardrails_critical "split"
  [ -n "$output" ]
}

# ── inject_guardrails_block ───────────────────────────────────────────────────

@test "inject_guardrails_block (split) removes old guardrails content" {
  inject_guardrails_block "$MARKED_FILE" "split"
  run grep "old guardrails content" "$MARKED_FILE"
  [ "$status" -ne 0 ]
}

@test "inject_guardrails_block (split) injects Security section" {
  inject_guardrails_block "$MARKED_FILE" "split"
  grep -q "### Security" "$MARKED_FILE"
}

@test "inject_guardrails_block (split) preserves content above markers" {
  inject_guardrails_block "$MARKED_FILE" "split"
  grep -q "Some content above." "$MARKED_FILE"
}

@test "inject_guardrails_block (split) preserves content below markers" {
  inject_guardrails_block "$MARKED_FILE" "split"
  grep -q "Some content below." "$MARKED_FILE"
}

@test "inject_guardrails_block (split) keeps markers in file" {
  inject_guardrails_block "$MARKED_FILE" "split"
  grep -q "GUARDRAILS_START" "$MARKED_FILE"
  grep -q "GUARDRAILS_END" "$MARKED_FILE"
}

@test "inject_guardrails_block (embedded) also injects guardrails" {
  inject_guardrails_block "$MARKED_FILE" "embedded"
  grep -q "### Security" "$MARKED_FILE"
}

@test "inject_guardrails_block (embedded) does not leave reference to guardrails file" {
  inject_guardrails_block "$MARKED_FILE" "embedded"
  run grep "guardrails.instructions.md" "$MARKED_FILE"
  [ "$status" -ne 0 ]
}

@test "inject_guardrails_block is idempotent (running twice gives same result)" {
  inject_guardrails_block "$MARKED_FILE" "split"
  local after_first
  after_first=$(grep -c "### Security" "$MARKED_FILE")

  inject_guardrails_block "$MARKED_FILE" "split"
  local after_second
  after_second=$(grep -c "### Security" "$MARKED_FILE")

  [ "$after_first" = "$after_second" ]
}

@test "inject_guardrails_block does not create temp files" {
  inject_guardrails_block "$MARKED_FILE" "split"
  run ls "${MARKED_FILE}.tmp" 2>/dev/null
  [ "$status" -ne 0 ]
}

# ── File without markers (defensive) ─────────────────────────────────────────

@test "inject_guardrails_block on file without markers does not corrupt it" {
  local no_markers="${TEST_TMP}/no-markers.md"
  echo "# Just a plain file" > "$no_markers"
  inject_guardrails_block "$no_markers" "split"
  grep -q "# Just a plain file" "$no_markers"
}
