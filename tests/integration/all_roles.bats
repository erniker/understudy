#!/usr/bin/env bats
# Integration tests for `--all-roles` — deploys every role in roles/ instead
# of just the defaults (git-specialist, repo-documenter, shell-scripting if
# detected). Mirrors the pattern used by modules/caveman/tests/deploy.bats.

WIZARD="${BATS_TEST_DIRNAME}/../../wizard.sh"

setup() {
  TEST_TMP="$(mktemp -d)"
}

teardown() {
  [[ -n "${TEST_TMP:-}" && -d "$TEST_TMP" ]] && rm -rf "$TEST_TMP"
}

run_wizard_with_flags() {
  local project_name="$1"
  local base_dir="$2"
  shift 2
  local flags=()
  while [[ "$#" -gt 0 && "$1" != "--" ]]; do
    flags+=("$1")
    shift
  done
  shift # drop '--'

  printf '%s\n' \
    "$project_name" \
    "$base_dir" \
    "Test description" \
    ".NET + React" \
    "Test PM" \
    "local" \
    "1" \
    "$@" \
    "N" \
    "N" \
    "Y" \
    "n" \
    | bash "$WIZARD" "${flags[@]}" 2>/dev/null
}

@test "--all-roles deploys every role in the catalog (Claude)" {
  run_wizard_with_flags "myproject" "$TEST_TMP" --all-roles -- "Y" "Y" "Y"
  local dir="$TEST_TMP/myproject/.claude/agents"
  [ -f "$dir/data-engineer.md" ]
  [ -f "$dir/ml-engineer.md" ]
  [ -f "$dir/mobile-engineer.md" ]
  [ -f "$dir/sre.md" ]
  [ -f "$dir/tech-writer.md" ]
  [ -f "$dir/shell-scripting.md" ]
  [ -f "$dir/git-specialist.md" ]
  [ -f "$dir/repo-documenter.md" ]
}

@test "--all-roles deploys every role in the catalog (Copilot)" {
  run_wizard_with_flags "myproject" "$TEST_TMP" --all-roles -- "Y" "Y" "Y"
  local dir="$TEST_TMP/myproject/.github/instructions"
  [ -f "$dir/data-engineer.instructions.md" ]
  [ -f "$dir/ml-engineer.instructions.md" ]
  [ -f "$dir/mobile-engineer.instructions.md" ]
  [ -f "$dir/sre.instructions.md" ]
  [ -f "$dir/tech-writer.instructions.md" ]
}

@test "--all-roles deploys shell-scripting even without a scripting-heavy stack" {
  # Without --all-roles, shell-scripting only auto-deploys when *.sh/*.bash
  # files are detected; --all-roles must deploy it unconditionally.
  run_wizard_with_flags "myproject" "$TEST_TMP" --all-roles -- "Y" "Y" "Y"
  [ -f "$TEST_TMP/myproject/.claude/agents/shell-scripting.md" ]
}

@test "without --all-roles, the extended catalog is NOT auto-deployed" {
  run_wizard_with_flags "myproject" "$TEST_TMP" -- "Y" "Y" "Y"
  [ ! -f "$TEST_TMP/myproject/.claude/agents/data-engineer.md" ]
  [ ! -f "$TEST_TMP/myproject/.claude/agents/ml-engineer.md" ]
  # Defaults are still deployed.
  [ -f "$TEST_TMP/myproject/.claude/agents/git-specialist.md" ]
  [ -f "$TEST_TMP/myproject/.claude/agents/repo-documenter.md" ]
}

@test "--all-roles updates docs/team-roster.md for every deployed role" {
  run_wizard_with_flags "myproject" "$TEST_TMP" --all-roles -- "Y" "Y" "Y"
  local roster="$TEST_TMP/myproject/docs/team-roster.md"
  grep -qi "data engineer" "$roster"
  grep -qi "ml engineer" "$roster"
  grep -qi "sre" "$roster"
}
