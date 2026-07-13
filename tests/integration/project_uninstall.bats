#!/usr/bin/env bats
# Integration tests for `understudy --uninstall` (project mode, no --global).
# Removes the well-known Understudy-owned paths from the current directory —
# the automated form of the manual "full reset" procedure documented in
# docs/09-configuration.md.

WIZARD="${BATS_TEST_DIRNAME}/../../wizard.sh"

setup() {
  TEST_TMP="$(mktemp -d)"
}

teardown() {
  [[ -n "${TEST_TMP:-}" && -d "$TEST_TMP" ]] && rm -rf "$TEST_TMP"
}

deploy_full_project() {
  local project_name="$1"
  printf '%s\n' \
    "$project_name" \
    "$TEST_TMP" \
    "Test description" \
    ".NET + React" \
    "Test PM" \
    "local" \
    "1" \
    "Y" "Y" "Y" \
    "N" "N" \
    "Y" "n" \
    | bash "$WIZARD" 2>/dev/null
}

@test "--uninstall --yes removes all Understudy-owned top-level files" {
  deploy_full_project "myproject"
  local dir="$TEST_TMP/myproject"
  (cd "$dir" && bash "$WIZARD" --uninstall --yes 2>/dev/null)
  [ ! -f "$dir/AGENTS.md" ]
  [ ! -f "$dir/CLAUDE.md" ]
  [ ! -f "$dir/understudy.yaml" ]
}

@test "--uninstall --yes removes Copilot, Claude and Cursor directories" {
  deploy_full_project "myproject"
  local dir="$TEST_TMP/myproject"
  (cd "$dir" && bash "$WIZARD" --uninstall --yes 2>/dev/null)
  [ ! -d "$dir/.github/instructions" ]
  [ ! -d "$dir/.github/prompts" ]
  [ ! -f "$dir/.github/copilot-instructions.md" ]
  [ ! -d "$dir/.claude" ]
  [ ! -d "$dir/.cursor/agents" ]
  [ ! -d "$dir/.cursor/commands" ]
  [ ! -d "$dir/.cursor/rules" ]
}

@test "--uninstall --yes removes docs/ memory files" {
  deploy_full_project "myproject"
  local dir="$TEST_TMP/myproject"
  (cd "$dir" && bash "$WIZARD" --uninstall --yes 2>/dev/null)
  [ ! -f "$dir/docs/spec.md" ]
  [ ! -f "$dir/docs/decisions.md" ]
  [ ! -f "$dir/docs/session-log.md" ]
  [ ! -f "$dir/docs/team-roster.md" ]
}

@test "--uninstall never touches files outside its known list" {
  deploy_full_project "myproject"
  local dir="$TEST_TMP/myproject"
  mkdir -p "$dir/src"
  echo "console.log('hi')" > "$dir/src/app.js"
  echo '{"name":"myproject"}' > "$dir/package.json"
  (cd "$dir" && bash "$WIZARD" --uninstall --yes 2>/dev/null)
  [ -f "$dir/src/app.js" ]
  [ -f "$dir/package.json" ]
}

@test "--uninstall without --yes declines by default (confirm defaults to N)" {
  deploy_full_project "myproject"
  local dir="$TEST_TMP/myproject"
  # No input piped -> confirm() falls back to its default, which
  # project_uninstall passes as "N".
  (cd "$dir" && echo "" | bash "$WIZARD" --uninstall 2>/dev/null)
  [ -f "$dir/AGENTS.md" ]
  [ -f "$dir/CLAUDE.md" ]
}

@test "--uninstall on a directory with no Understudy files reports nothing to remove" {
  mkdir -p "$TEST_TMP/plain-dir"
  run bash -c "cd '$TEST_TMP/plain-dir' && bash '$WIZARD' --uninstall --yes 2>&1"
  [ "$status" -eq 0 ]
  [[ "$output" == *"nothing to remove"* ]]
}
