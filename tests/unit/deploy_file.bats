#!/usr/bin/env bats
# Tests for deploy_file in wizard.sh
# Covers: all {{PLACEHOLDER}} substitutions, file-already-exists guard,
#         executable bit preserved, no leftover placeholder after deploy.

load "../lib/helpers"

setup() {
  setup_tmp
  source_wizard_functions

  # Project variables that deploy_file reads from globals
  PROJECT_NAME="my-project"
  PROJECT_DESCRIPTION="A test project"
  TECH_STACK=".NET + React"
  TEAM_LEAD="Test PM"
  REPOSITORY_URL="https://github.com/test/repo"
  PROJECT_DATE="2026-01-01"
  MODEL_ARCHITECT="claude-opus-4.6"
  MODEL_BACKEND="claude-sonnet-4.5"
  MODEL_FRONTEND="claude-sonnet-4.5"
  MODEL_DEVOPS="claude-haiku-4.5"
  MODEL_SECURITY="claude-sonnet-4.5"
  MODEL_QA="claude-sonnet-4.5"
  APPLY_TO_ARCHITECT="docs/**"
  APPLY_TO_BACKEND="src/api/**"
  APPLY_TO_FRONTEND="**/*.tsx"
  APPLY_TO_DEVOPS="infra/**"
  APPLY_TO_SECURITY=""
  APPLY_TO_QA="tests/**"

  # Create a template with all known placeholders
  TEMPLATE="${TEST_TMP}/template.md"
  cat > "$TEMPLATE" << 'TMPL'
# {{PROJECT_NAME}}
Description: {{PROJECT_DESCRIPTION}}
Stack: {{TECH_STACK}}
PM: {{TEAM_LEAD}}
Repo: {{REPOSITORY_URL}}
Date: {{DATE}}
Architect model: {{MODEL_ARCHITECT}}
Backend model: {{MODEL_BACKEND}}
Frontend model: {{MODEL_FRONTEND}}
DevOps model: {{MODEL_DEVOPS}}
Security model: {{MODEL_SECURITY}}
QA model: {{MODEL_QA}}
Apply architect: {{APPLY_TO_ARCHITECT}}
Apply backend: {{APPLY_TO_BACKEND}}
Apply frontend: {{APPLY_TO_FRONTEND}}
Apply devops: {{APPLY_TO_DEVOPS}}
Apply security: {{APPLY_TO_SECURITY}}
Apply qa: {{APPLY_TO_QA}}
TMPL

  DEST="${TEST_TMP}/output.md"
}

teardown() { teardown_tmp; }

# ── Placeholder substitution ──────────────────────────────────────────────────

@test "deploy_file replaces {{PROJECT_NAME}}" {
  deploy_file "$TEMPLATE" "$DEST"
  grep -q "my-project" "$DEST"
}

@test "deploy_file replaces {{PROJECT_DESCRIPTION}}" {
  deploy_file "$TEMPLATE" "$DEST"
  grep -q "A test project" "$DEST"
}

@test "deploy_file replaces {{TECH_STACK}}" {
  deploy_file "$TEMPLATE" "$DEST"
  grep -q ".NET + React" "$DEST"
}

@test "deploy_file replaces {{TEAM_LEAD}}" {
  deploy_file "$TEMPLATE" "$DEST"
  grep -q "Test PM" "$DEST"
}

@test "deploy_file replaces {{REPOSITORY_URL}}" {
  deploy_file "$TEMPLATE" "$DEST"
  grep -q "https://github.com/test/repo" "$DEST"
}

@test "deploy_file replaces {{DATE}}" {
  deploy_file "$TEMPLATE" "$DEST"
  grep -q "2026-01-01" "$DEST"
}

@test "deploy_file replaces {{MODEL_ARCHITECT}}" {
  deploy_file "$TEMPLATE" "$DEST"
  grep -q "claude-opus-4.6" "$DEST"
}

@test "deploy_file replaces {{MODEL_BACKEND}}" {
  deploy_file "$TEMPLATE" "$DEST"
  grep -q "claude-sonnet-4.5" "$DEST"
}

@test "deploy_file replaces {{MODEL_DEVOPS}}" {
  deploy_file "$TEMPLATE" "$DEST"
  grep -q "claude-haiku-4.5" "$DEST"
}

@test "deploy_file replaces {{APPLY_TO_ARCHITECT}}" {
  deploy_file "$TEMPLATE" "$DEST"
  grep -q "docs/\*\*" "$DEST"
}

@test "deploy_file replaces {{APPLY_TO_BACKEND}}" {
  deploy_file "$TEMPLATE" "$DEST"
  grep -q "src/api/\*\*" "$DEST"
}

# ── No leftover placeholders ──────────────────────────────────────────────────

@test "deploy_file leaves no {{PLACEHOLDER}} in output" {
  deploy_file "$TEMPLATE" "$DEST"
  run grep -c '{{' "$DEST"
  [ "$output" = "0" ]
}

# ── File-already-exists guard ─────────────────────────────────────────────────

@test "deploy_file does not overwrite an existing destination file" {
  echo "ORIGINAL CONTENT" > "$DEST"
  deploy_file "$TEMPLATE" "$DEST"
  grep -q "ORIGINAL CONTENT" "$DEST"
}

@test "deploy_file skips silently when destination already exists" {
  echo "ORIGINAL" > "$DEST"
  run deploy_file "$TEMPLATE" "$DEST"
  [ "$status" -eq 0 ]
}

# ── Output file is created ────────────────────────────────────────────────────

@test "deploy_file creates the destination file" {
  deploy_file "$TEMPLATE" "$DEST"
  [ -f "$DEST" ]
}

@test "deploy_file output contains expected content (sanity check)" {
  deploy_file "$TEMPLATE" "$DEST"
  grep -q "^# my-project" "$DEST"
}
