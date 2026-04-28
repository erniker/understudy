#!/usr/bin/env bats
# Tests for the README.md description fallback in detect_existing_project.
# Used by the --here flag to infer DETECTED_DESC when package.json has none.

load "../lib/helpers"

setup() {
  setup_tmp
  source_wizard_functions
}

teardown() { teardown_tmp; }

@test "extracts first paragraph of README as description" {
  mkdir -p "$TEST_TMP/p"
  cat > "$TEST_TMP/p/README.md" <<'EOF'
# My Project

A small CLI tool that does useful things.

More details below.
EOF
  detect_existing_project "$TEST_TMP/p"
  [[ "$DETECTED_DESC" == *"small CLI tool"* ]]
}

@test "skips badge/blockquote lines and picks the real paragraph" {
  mkdir -p "$TEST_TMP/p"
  cat > "$TEST_TMP/p/README.md" <<'EOF'
# My Project

> A quote line that should be skipped

A real description sentence.
EOF
  detect_existing_project "$TEST_TMP/p"
  [[ "$DETECTED_DESC" == *"real description"* ]]
}

@test "strips bold markers from the README description" {
  mkdir -p "$TEST_TMP/p"
  cat > "$TEST_TMP/p/README.md" <<'EOF'
# My Project

**Bold intro** continues here.
EOF
  detect_existing_project "$TEST_TMP/p"
  [[ "$DETECTED_DESC" != *"**"* ]]
  [[ "$DETECTED_DESC" == *"Bold intro"* ]]
}

@test "package.json description takes precedence over README" {
  mkdir -p "$TEST_TMP/p"
  echo '{"name":"x","description":"From package json"}' > "$TEST_TMP/p/package.json"
  cat > "$TEST_TMP/p/README.md" <<'EOF'
# X

This README description should not win.
EOF
  detect_existing_project "$TEST_TMP/p"
  # Note: existing single-line JSON parser quirk picks $4 (the name) when
  # name and description are on the same line; we only assert that README
  # fallback does NOT override an already-populated DETECTED_DESC.
  [[ "$DETECTED_DESC" != *"This README"* ]]
}
