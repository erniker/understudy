#!/usr/bin/env bats
# Tests for deploy_gitignore() in wizard.sh
# Covers: no-op when disabled, AI config entries per platform,
#         session memory entries, combined mode, idempotency.

load "../lib/helpers"

setup() {
  setup_tmp
  source_wizard_functions

  # Required globals
  TARGET_DIR="$TEST_TMP/project"
  mkdir -p "$TARGET_DIR"

  PLATFORM_COPILOT=true
  PLATFORM_CLAUDE=true
  PLATFORM_CURSOR=true
  GIT_LOCAL_CONFIG=false
  GIT_LOCAL_MEMORY=false
}

teardown() { teardown_tmp; }

# ── No-op when both flags off ─────────────────────────────────────────────────

@test "does not create .gitignore when both flags are false" {
  GIT_LOCAL_CONFIG=false
  GIT_LOCAL_MEMORY=false
  deploy_gitignore
  [ ! -f "$TARGET_DIR/.gitignore" ]
}

# ── AI config mode ────────────────────────────────────────────────────────────

@test "creates .gitignore when GIT_LOCAL_CONFIG=true" {
  GIT_LOCAL_CONFIG=true
  deploy_gitignore
  [ -f "$TARGET_DIR/.gitignore" ]
}

@test "adds AGENTS.md when GIT_LOCAL_CONFIG=true" {
  GIT_LOCAL_CONFIG=true
  deploy_gitignore
  grep -q "AGENTS.md" "$TARGET_DIR/.gitignore"
}

@test "adds CLAUDE.md when GIT_LOCAL_CONFIG=true" {
  GIT_LOCAL_CONFIG=true
  deploy_gitignore
  grep -q "CLAUDE.md" "$TARGET_DIR/.gitignore"
}

@test "adds understudy.yaml when GIT_LOCAL_CONFIG=true" {
  GIT_LOCAL_CONFIG=true
  deploy_gitignore
  grep -q "understudy.yaml" "$TARGET_DIR/.gitignore"
}

@test "adds Copilot files when GIT_LOCAL_CONFIG=true and PLATFORM_COPILOT=true" {
  GIT_LOCAL_CONFIG=true
  PLATFORM_COPILOT=true
  deploy_gitignore
  grep -q "copilot-instructions.md" "$TARGET_DIR/.gitignore"
  grep -q ".github/instructions/" "$TARGET_DIR/.gitignore"
  grep -q ".github/prompts/" "$TARGET_DIR/.gitignore"
}

@test "does NOT add Copilot files when PLATFORM_COPILOT=false" {
  GIT_LOCAL_CONFIG=true
  PLATFORM_COPILOT=false
  deploy_gitignore
  run grep "copilot-instructions.md" "$TARGET_DIR/.gitignore"
  [ "$status" -ne 0 ]
}

@test "adds .claude/ when GIT_LOCAL_CONFIG=true and PLATFORM_CLAUDE=true" {
  GIT_LOCAL_CONFIG=true
  PLATFORM_CLAUDE=true
  deploy_gitignore
  grep -q ".claude/" "$TARGET_DIR/.gitignore"
}

@test "does NOT add .claude/ when PLATFORM_CLAUDE=false" {
  GIT_LOCAL_CONFIG=true
  PLATFORM_CLAUDE=false
  deploy_gitignore
  run grep ".claude/" "$TARGET_DIR/.gitignore"
  [ "$status" -ne 0 ]
}

@test "adds Cursor files when GIT_LOCAL_CONFIG=true and PLATFORM_CURSOR=true" {
  GIT_LOCAL_CONFIG=true
  PLATFORM_CURSOR=true
  deploy_gitignore
  grep -q ".cursor/agents/" "$TARGET_DIR/.gitignore"
  grep -q "understudy-global.mdc" "$TARGET_DIR/.gitignore"
  grep -q "guardrails.mdc" "$TARGET_DIR/.gitignore"
}

@test "does NOT add Cursor files when PLATFORM_CURSOR=false" {
  GIT_LOCAL_CONFIG=true
  PLATFORM_CURSOR=false
  deploy_gitignore
  run grep ".cursor/agents/" "$TARGET_DIR/.gitignore"
  [ "$status" -ne 0 ]
}

# ── Session memory mode ───────────────────────────────────────────────────────

@test "creates .gitignore when GIT_LOCAL_MEMORY=true" {
  GIT_LOCAL_MEMORY=true
  deploy_gitignore
  [ -f "$TARGET_DIR/.gitignore" ]
}

@test "adds docs/spec.md when GIT_LOCAL_MEMORY=true" {
  GIT_LOCAL_MEMORY=true
  deploy_gitignore
  grep -q "docs/spec.md" "$TARGET_DIR/.gitignore"
}

@test "adds docs/decisions.md when GIT_LOCAL_MEMORY=true" {
  GIT_LOCAL_MEMORY=true
  deploy_gitignore
  grep -q "docs/decisions.md" "$TARGET_DIR/.gitignore"
}

@test "adds docs/session-log.md when GIT_LOCAL_MEMORY=true" {
  GIT_LOCAL_MEMORY=true
  deploy_gitignore
  grep -q "docs/session-log.md" "$TARGET_DIR/.gitignore"
}

@test "adds docs/team-roster.md when GIT_LOCAL_MEMORY=true" {
  GIT_LOCAL_MEMORY=true
  deploy_gitignore
  grep -q "docs/team-roster.md" "$TARGET_DIR/.gitignore"
}

@test "does NOT add memory files when GIT_LOCAL_MEMORY=false" {
  GIT_LOCAL_CONFIG=true
  GIT_LOCAL_MEMORY=false
  deploy_gitignore
  run grep "docs/spec.md" "$TARGET_DIR/.gitignore"
  [ "$status" -ne 0 ]
}

# ── Combined mode ─────────────────────────────────────────────────────────────

@test "adds both config and memory entries when both flags are true" {
  GIT_LOCAL_CONFIG=true
  GIT_LOCAL_MEMORY=true
  deploy_gitignore
  grep -q "CLAUDE.md" "$TARGET_DIR/.gitignore"
  grep -q "docs/spec.md" "$TARGET_DIR/.gitignore"
}

# ── Idempotency ───────────────────────────────────────────────────────────────

@test "is idempotent: calling twice does not duplicate entries" {
  GIT_LOCAL_CONFIG=true
  GIT_LOCAL_MEMORY=true
  deploy_gitignore
  deploy_gitignore
  local count
  count=$(grep -c "CLAUDE.md" "$TARGET_DIR/.gitignore")
  [ "$count" -eq 1 ]
}

# ── Appends to existing .gitignore ────────────────────────────────────────────

@test "appends to existing .gitignore without overwriting it" {
  echo "node_modules/" > "$TARGET_DIR/.gitignore"
  GIT_LOCAL_CONFIG=true
  deploy_gitignore
  grep -q "node_modules/" "$TARGET_DIR/.gitignore"
  grep -q "CLAUDE.md" "$TARGET_DIR/.gitignore"
}

# ── Understudy section header ─────────────────────────────────────────────────

@test "adds Understudy section header to .gitignore" {
  GIT_LOCAL_CONFIG=true
  deploy_gitignore
  grep -q "Understudy" "$TARGET_DIR/.gitignore"
}
