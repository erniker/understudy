#!/usr/bin/env bats
# Unit tests for the pure helpers behind `understudy --upgrade`: hashing,
# the denylist, and the Claude model-line migration.

load "../lib/helpers"

setup() {
  setup_tmp
  source_wizard_functions
}

teardown() { teardown_tmp; }

# ── file_sha256 ──────────────────────────────────────────────────────────────

@test "file_sha256 prints the SHA-256 of a file" {
  printf 'abc' > "${TEST_TMP}/f"
  run file_sha256 "${TEST_TMP}/f"
  [ "$status" -eq 0 ]
  [ "$output" = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" ]
}

@test "file_sha256 falls back to shasum when sha256sum is missing" {
  command -v shasum > /dev/null || skip "shasum not installed"
  printf 'abc' > "${TEST_TMP}/f"
  command() {
    if [[ "$1" == "-v" && "$2" == "sha256sum" ]]; then return 1; fi
    builtin command "$@"
  }
  run file_sha256 "${TEST_TMP}/f"
  [ "$output" = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" ]
}

# ── state helpers ────────────────────────────────────────────────────────────

@test "state_record is a no-op while upgrade staging is active" {
  mkdir -p "${TEST_TMP}/p"
  echo x > "${TEST_TMP}/p/a.md"
  UPGRADE_STAGING=true TARGET_DIR="${TEST_TMP}/p" state_record "${TEST_TMP}/p/a.md"
  [ ! -f "${TEST_TMP}/p/.understudy-state" ]
}

@test "state_record without a project target does nothing and does not fail" {
  echo x > "${TEST_TMP}/a.md"
  unset TARGET_DIR
  run state_record "${TEST_TMP}/a.md"
  [ "$status" -eq 0 ]
}

@test "state entries with spaces in the path round-trip" {
  mkdir -p "${TEST_TMP}/p"
  DEPLOY_STATE_SCOPE=global HOME="${TEST_TMP}/h" state_set "/x/Code - Insiders/User/a.md" "$(printf 'a%.0s' {1..64})"
  local got
  got="$(DEPLOY_STATE_SCOPE=global HOME="${TEST_TMP}/h" state_get "/x/Code - Insiders/User/a.md")"
  [ "$got" = "$(printf 'a%.0s' {1..64})" ]
}

# ── upgrade_is_denied ────────────────────────────────────────────────────────

@test "upgrade_is_denied covers the mixed-content files" {
  local f
  for f in CLAUDE.md AGENTS.md .github/copilot-instructions.md .claude/settings.json \
           understudy.yaml docs/spec.md docs/decisions.md docs/session-log.md docs/team-roster.md \
           .gitignore /h/.claude/CLAUDE.md /h/.understudy-global/cursor-user-rules.md \
           /h/.understudy-global/state /h/x/understudy-global.instructions.md .claude/agents/a.md.bak-understudy; do
    upgrade_is_denied "$f"
  done
}

@test "upgrade_is_denied lets pure-render files through" {
  local f
  for f in .claude/agents/backend.md .github/instructions/backend.instructions.md \
           .cursor/rules/guardrails.mdc .claude/hooks/guardrails-check.sh; do
    ! upgrade_is_denied "$f"
  done
}

# ── upgrade_model_line_fix ───────────────────────────────────────────────────

@test "model fix targets a dotted Claude model in the frontmatter" {
  printf -- '---\nname: x\nmodel: claude-opus-4.6\n---\nbody\n' > "${TEST_TMP}/a.md"
  run upgrade_model_line_fix "${TEST_TMP}/a.md"
  [ "$output" = "$(printf '3\tmodel: opus')" ]
}

@test "model fix ignores aliases, dashed IDs, inherit and non-Claude models" {
  local m
  for m in sonnet claude-sonnet-4-5 inherit gpt-5.1 "claude-sonnet-4.5-preview"; do
    printf -- '---\nname: x\nmodel: %s\n---\nbody\n' "$m" > "${TEST_TMP}/a.md"
    run upgrade_model_line_fix "${TEST_TMP}/a.md"
    [ -z "$output" ]
  done
}

@test "model fix ignores a model line outside the frontmatter block" {
  printf -- '---\nname: x\n---\nmodel: claude-sonnet-4.5\n' > "${TEST_TMP}/a.md"
  run upgrade_model_line_fix "${TEST_TMP}/a.md"
  [ -z "$output" ]
}

@test "model fix ignores files without frontmatter" {
  printf -- 'model: claude-sonnet-4.5\n' > "${TEST_TMP}/a.md"
  run upgrade_model_line_fix "${TEST_TMP}/a.md"
  [ -z "$output" ]
}

@test "model fix only considers the FIRST model line of the frontmatter" {
  printf -- '---\nmodel: sonnet\nmodel: claude-sonnet-4.5\n---\n' > "${TEST_TMP}/a.md"
  run upgrade_model_line_fix "${TEST_TMP}/a.md"
  [ -z "$output" ]
}

@test "model fix keeps a CRLF line ending" {
  printf -- '---\r\nmodel: claude-haiku-4.5\r\n---\r\n' > "${TEST_TMP}/a.md"
  run upgrade_model_line_fix "${TEST_TMP}/a.md"
  [ "$output" = "$(printf '2\tmodel: haiku\r')" ]
}

@test "model apply is byte-identical elsewhere, including a missing final newline" {
  printf -- '---\nmodel: claude-sonnet-4.5\n---\nno trailing newline' > "${TEST_TMP}/a.md"
  upgrade_model_line_apply "${TEST_TMP}/a.md" 2 "model: sonnet" > "${TEST_TMP}/out.md"
  printf -- '---\nmodel: sonnet\n---\nno trailing newline' > "${TEST_TMP}/expected.md"
  cmp "${TEST_TMP}/out.md" "${TEST_TMP}/expected.md"
}
