#!/usr/bin/env bats
# Integration tests for `understudy --upgrade` (project and --global) and for
# the baseline state file (.understudy-state / ~/.understudy-global/state)
# that makes it safe. The real wizard.sh runs as a subprocess with HOME and
# APPDATA faked, so nothing here can touch the developer's real machine.
#
# Helpers from wizard.sh (state_set, file_sha256, run_upgrade) are also
# sourced in-process, to forge baselines and to drive the interactive prompt
# through a stub instead of a terminal.

load "../lib/helpers"

setup() {
  setup_tmp
  source_wizard_functions
  FAKE_HOME="${TEST_TMP}/home"
  PROJ="${TEST_TMP}/proj"
  mkdir -p "$FAKE_HOME" "$PROJ"
  export UNDERSTUDY_SKIP_JQ_INSTALL=1 UNDERSTUDY_SKIP_UPDATE_CHECK=1
}

teardown() { teardown_tmp; }

# ── helpers ──────────────────────────────────────────────────────────────────

run_wizard() {
  HOME="$FAKE_HOME" APPDATA="${FAKE_HOME}/AppData/Roaming" bash "$WIZARD" "$@" < /dev/null
}

deploy_project() {
  (cd "$PROJ" && run_wizard --here --yes > /dev/null 2>&1)
}

deploy_global() {
  run_wizard --global --yes > /dev/null 2>&1
}

# Forge the baseline of a project file so it counts as "untouched".
rebaseline_project() {
  local rel="$1"
  TARGET_DIR="$PROJ" state_set "$rel" "$(file_sha256 "${PROJ}/${rel}")"
}

rebaseline_global() {
  local path="$1"
  DEPLOY_STATE_SCOPE=global HOME="$FAKE_HOME" state_set "$path" "$(file_sha256 "$path")"
}

# Portable content checksum of a whole tree (file list + cksum of each file).
tree_sum() {
  (cd "$1" && find . -type f | LC_ALL=C sort | while IFS= read -r f; do
    printf '%s %s\n' "$f" "$(cksum < "$f")"
  done)
}

state_hash_of() {
  awk -v k="$2" 'substr($0, 67) == k { print substr($0, 1, 64) }' "$1"
}

# ── baseline recording ───────────────────────────────────────────────────────

@test "project deploy writes .understudy-state with relative paths and correct sha256" {
  deploy_project
  local state="${PROJ}/.understudy-state"
  [ -f "$state" ]
  [ "$(state_hash_of "$state" ".claude/agents/backend.md")" = "$(file_sha256 "${PROJ}/.claude/agents/backend.md")" ]
  # No absolute path is ever recorded in project mode.
  ! awk '{ p = substr($0, 67); if (p ~ /^\//) bad = 1 } END { exit !bad }' "$state"
}

@test "re-recording a file replaces its entry instead of duplicating it" {
  deploy_project
  echo "edited" >> "${PROJ}/.claude/agents/backend.md"
  TARGET_DIR="$PROJ" state_record "${PROJ}/.claude/agents/backend.md"
  TARGET_DIR="$PROJ" state_record "${PROJ}/.claude/agents/backend.md"
  local n
  n="$(awk 'substr($0, 67) == ".claude/agents/backend.md"' "${PROJ}/.understudy-state" | wc -l | tr -d ' ')"
  [ "$n" -eq 1 ]
  [ "$(state_hash_of "${PROJ}/.understudy-state" ".claude/agents/backend.md")" = "$(file_sha256 "${PROJ}/.claude/agents/backend.md")" ]
}

@test "the guardrails-injected file is baselined with its final content" {
  deploy_project
  [ "$(state_hash_of "${PROJ}/.understudy-state" ".cursor/rules/guardrails.mdc")" = "$(file_sha256 "${PROJ}/.cursor/rules/guardrails.mdc")" ]
}

@test "global deploy writes the state file with absolute paths" {
  deploy_global
  local state="${FAKE_HOME}/.understudy-global/state"
  [ -f "$state" ]
  local target="${FAKE_HOME}/.claude/agents/backend.md"
  [ "$(state_hash_of "$state" "$target")" = "$(file_sha256 "$target")" ]
}

@test "normal deploy never overwrites an existing file and records no baseline for it" {
  mkdir -p "${PROJ}/.claude/agents"
  echo "mine" > "${PROJ}/.claude/agents/backend.md"
  deploy_project
  [ "$(cat "${PROJ}/.claude/agents/backend.md")" = "mine" ]
  [ -z "$(state_hash_of "${PROJ}/.understudy-state" ".claude/agents/backend.md")" ]
}

@test "--uninstall removes .understudy-state" {
  deploy_project
  [ -f "${PROJ}/.understudy-state" ]
  (cd "$PROJ" && run_wizard --uninstall --yes > /dev/null 2>&1)
  [ ! -f "${PROJ}/.understudy-state" ]
}

@test "--global --uninstall removes the state file" {
  deploy_global
  [ -f "${FAKE_HOME}/.understudy-global/state" ]
  run_wizard --global --uninstall --yes > /dev/null 2>&1
  [ ! -f "${FAKE_HOME}/.understudy-global/state" ]
}

# ── classification ───────────────────────────────────────────────────────────

@test "up-to-date file is not written and a legacy file gains a baseline" {
  deploy_project
  rm -f "${PROJ}/.understudy-state"    # legacy deploy: files but no baseline
  local file="${PROJ}/.claude/agents/backend.md"
  touch -r "$file" "${TEST_TMP}/ref"
  local before
  before="$(tree_sum "$PROJ")"

  cd "$PROJ"
  run run_wizard --upgrade --yes
  [ "$status" -eq 0 ]
  [[ "$output" == *"up-to-date"* ]]
  [[ "$output" != *"differ from the new templates"* ]]
  [ ! "$file" -nt "${TEST_TMP}/ref" ]
  [ ! -f "${file}.bak-understudy" ]
  # Only the state file may differ from the snapshot.
  [ "$(tree_sum "$PROJ" | grep -v '\./\.understudy-state')" = "$(printf '%s\n' "$before" | grep -v '\./\.understudy-state')" ]
  [ "$(state_hash_of "${PROJ}/.understudy-state" ".claude/agents/backend.md")" = "$(file_sha256 "$file")" ]
}

@test "pristine-outdated file is overwritten under --yes with a .bak-understudy backup" {
  deploy_project
  local file="${PROJ}/.claude/agents/devops.md"
  local template_render
  template_render="$(cat "$file")"
  echo "older template line" >> "$file"
  rebaseline_project ".claude/agents/devops.md"     # untouched since "deploy"

  cd "$PROJ"
  run run_wizard --upgrade --yes
  [ "$status" -eq 0 ]
  [[ "$output" == *"upgraded"* ]]
  [ "$(cat "$file")" = "$template_render" ]
  [ -f "${file}.bak-understudy" ]
  grep -q "older template line" "${file}.bak-understudy"
  [ "$(state_hash_of "${PROJ}/.understudy-state" ".claude/agents/devops.md")" = "$(file_sha256 "$file")" ]
}

@test "customized file is NOT overwritten under --yes and is reported as kept" {
  deploy_project
  local file="${PROJ}/.claude/agents/security.md"
  echo "my own rule" >> "$file"
  local before
  before="$(cksum < "$file")"

  cd "$PROJ"
  run run_wizard --upgrade --yes
  [ "$status" -eq 0 ]
  [[ "$output" == *"kept (customized)"* ]]
  [[ "$output" == *"without --yes"* ]]
  [ "$(cksum < "$file")" = "$before" ]
  [ ! -f "${file}.bak-understudy" ]
}

@test "a legacy customized file (no baseline) is kept, never guessed pristine" {
  deploy_project
  rm -f "${PROJ}/.understudy-state"
  echo "my own rule" >> "${PROJ}/.claude/agents/security.md"

  cd "$PROJ"
  run run_wizard --upgrade --yes
  [ "$status" -eq 0 ]
  [[ "$output" == *"kept (customized)"* ]]
  grep -q "my own rule" "${PROJ}/.claude/agents/security.md"
}

@test "customized file is overwritten only after an interactive 'y'" {
  deploy_project
  local file="${PROJ}/.claude/agents/security.md"
  local rendered
  rendered="$(cat "$file")"
  echo "my own rule" >> "$file"

  cd "$PROJ"
  # Answer 'no': nothing changes.
  upgrade_prompt_overwrite() { return 1; }
  HOME="$FAKE_HOME" run run_upgrade
  [ "$status" -eq 0 ]
  grep -q "my own rule" "$file"

  # Answer 'yes': overwritten, backed up, baseline follows.
  upgrade_prompt_overwrite() { return 0; }
  HOME="$FAKE_HOME" run run_upgrade
  [ "$status" -eq 0 ]
  [ "$(cat "$file")" = "$rendered" ]
  grep -q "my own rule" "${file}.bak-understudy"
  [ "$(state_hash_of "${PROJ}/.understudy-state" ".claude/agents/security.md")" = "$(file_sha256 "$file")" ]
}

@test "--dry-run writes nothing: no file, no backup, no state change" {
  deploy_project
  echo "older template line" >> "${PROJ}/.claude/agents/devops.md"
  rebaseline_project ".claude/agents/devops.md"
  echo "my own rule" >> "${PROJ}/.claude/agents/security.md"
  sed 's/^model: sonnet/model: claude-sonnet-4.5/' "${PROJ}/.claude/agents/backend.md" > "${TEST_TMP}/b"
  cat "${TEST_TMP}/b" > "${PROJ}/.claude/agents/backend.md"
  local before
  before="$(tree_sum "$PROJ")"

  cd "$PROJ"
  run run_wizard --upgrade --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"would-upgrade"* ]]
  [[ "$output" == *"would-migrate"* ]]
  [ "$(tree_sum "$PROJ")" = "$before" ]
}

# ── model-line migration ─────────────────────────────────────────────────────

@test "migration rewrites only the frontmatter model line of a customized legacy agent" {
  deploy_project
  local file="${PROJ}/.claude/agents/backend.md"
  sed 's/^model: sonnet$/model: claude-sonnet-4.5/' "$file" > "${TEST_TMP}/legacy.md"
  printf '\nA paragraph the user added.\n' >> "${TEST_TMP}/legacy.md"
  cat "${TEST_TMP}/legacy.md" > "$file"
  sed 's/^model: claude-sonnet-4.5$/model: sonnet/' "${TEST_TMP}/legacy.md" > "${TEST_TMP}/expected.md"

  cd "$PROJ"
  run run_wizard --upgrade --yes
  [ "$status" -eq 0 ]
  cmp "$file" "${TEST_TMP}/expected.md"
  [ -f "${file}.bak-understudy" ]
  cmp "${file}.bak-understudy" "${TEST_TMP}/legacy.md"
}

@test "a legacy file that differs from the template only by the model line becomes up-to-date" {
  deploy_project
  rm -f "${PROJ}/.understudy-state"
  local file="${PROJ}/.claude/agents/backend.md"
  sed 's/^model: sonnet$/model: claude-sonnet-4.5/' "$file" > "${TEST_TMP}/legacy.md"
  cat "${TEST_TMP}/legacy.md" > "$file"

  cd "$PROJ"
  run run_wizard --upgrade --yes
  [ "$status" -eq 0 ]
  [[ "$output" != *"differ from the new templates"* ]]
  grep -q '^model: sonnet$' "$file"
  [ "$(state_hash_of "${PROJ}/.understudy-state" ".claude/agents/backend.md")" = "$(file_sha256 "$file")" ]
}

@test "migration leaves dashed IDs, aliases and body lines untouched" {
  deploy_project
  local dashed="${PROJ}/.claude/agents/frontend.md"
  sed 's/^model: sonnet$/model: claude-sonnet-4-5/' "$dashed" > "${TEST_TMP}/d.md"
  cat "${TEST_TMP}/d.md" > "$dashed"

  local body="${PROJ}/.claude/agents/architect.md"
  printf '\nmodel: claude-sonnet-4.5\n' >> "$body"
  local body_before
  body_before="$(cat "$body")"

  cd "$PROJ"
  run run_wizard --upgrade --yes
  [ "$status" -eq 0 ]
  grep -q '^model: claude-sonnet-4-5$' "$dashed"
  [ "$(cat "$body")" = "$body_before" ]
  grep -q '^model: opus$' "$body"    # the real frontmatter alias is intact
}

# ── denylist, scope, isolation ───────────────────────────────────────────────

@test "denylisted files are never modified nor reported" {
  deploy_project
  local f
  for f in CLAUDE.md AGENTS.md docs/spec.md understudy.yaml .claude/settings.json; do
    echo "user edit" >> "${PROJ}/${f}"
  done
  local before
  before="$(for f in CLAUDE.md AGENTS.md docs/spec.md understudy.yaml .claude/settings.json; do cksum < "${PROJ}/${f}"; done)"

  cd "$PROJ"
  run run_wizard --upgrade --yes
  [ "$status" -eq 0 ]
  [ "$(for f in CLAUDE.md AGENTS.md docs/spec.md understudy.yaml .claude/settings.json; do cksum < "${PROJ}/${f}"; done)" = "$before" ]
  [[ "$output" != *"CLAUDE.md"* ]]
  [[ "$output" != *"AGENTS.md"* ]]
  [[ "$output" != *"docs/spec.md"* ]]
  [[ "$output" != *"understudy.yaml"* ]]
  [[ "$output" != *"settings.json"* ]]
}

@test "upgrade never adds files for platforms or roles that are not deployed" {
  deploy_project
  rm -rf "${PROJ}/.cursor"
  rm -f "${PROJ}/.github/instructions/backend.instructions.md" "${PROJ}/.claude/agents/git-specialist.md"

  cd "$PROJ"
  run run_wizard --upgrade --yes
  [ "$status" -eq 0 ]
  [ ! -e "${PROJ}/.cursor" ]
  [ ! -f "${PROJ}/.github/instructions/backend.instructions.md" ]
  [ ! -f "${PROJ}/.claude/agents/git-specialist.md" ]
  [[ "$output" == *"skipped (not deployed)"* ]]
}

@test "an optional role is refreshed like a core one" {
  deploy_project
  local file="${PROJ}/.claude/agents/git-specialist.md"
  local rendered
  rendered="$(cat "$file")"
  echo "older role text" >> "$file"
  rebaseline_project ".claude/agents/git-specialist.md"

  cd "$PROJ"
  run run_wizard --upgrade --yes
  [ "$status" -eq 0 ]
  [ "$(cat "$file")" = "$rendered" ]
}

@test "a deployed role whose catalog source vanished is reported and left alone" {
  deploy_project
  local file="${PROJ}/.claude/agents/retired-role.md"
  printf -- '---\nname: retired-role\n---\nbody\n' > "$file"
  rebaseline_project ".claude/agents/retired-role.md"

  cd "$PROJ"
  run run_wizard --upgrade --yes
  [ "$status" -eq 0 ]
  [[ "$output" == *"skipped (role source missing)"* ]]
  grep -q '^body$' "$file"
}

@test "project upgrade leaves no staging residue in HOME" {
  deploy_project
  cd "$PROJ"
  run run_wizard --upgrade --yes
  [ "$status" -eq 0 ]
  [ ! -e "${FAKE_HOME}/.understudy-global" ]
  [ ! -e "${FAKE_HOME}/.claude" ]
}

@test "--upgrade in a directory with no deployment is a harmless no-op" {
  cd "$PROJ"
  run run_wizard --upgrade --yes
  [ "$status" -eq 0 ]
  [[ "$output" == *"nothing to upgrade"* ]]
  [ ! -f "${PROJ}/.understudy-state" ]
}

@test "project upgrade skips Cursor agents hard-linked to the global install" {
  deploy_global
  cd "$PROJ"
  run_wizard --docs-only --yes > /dev/null 2>&1
  [ -f "${PROJ}/.cursor/agents/backend.md" ]
  local src="${FAKE_HOME}/.understudy-global/cursor-agents/backend.md"
  [ "${PROJ}/.cursor/agents/backend.md" -ef "$src" ] || skip "hard links unsupported here"

  run run_wizard --upgrade --yes
  [ "$status" -eq 0 ]
  [[ "$output" == *"skipped (linked to global)"* ]]
}

# ── global mode ──────────────────────────────────────────────────────────────

@test "--upgrade --global refreshes an untouched file and migrates the Claude model line" {
  deploy_global
  local claude="${FAKE_HOME}/.claude/agents/devops.md"
  local rendered
  rendered="$(cat "$claude")"
  echo "older template line" >> "$claude"
  rebaseline_global "$claude"

  local qa="${FAKE_HOME}/.claude/agents/qa.md"
  sed 's/^model: sonnet$/model: claude-sonnet-4.5/' "$qa" > "${TEST_TMP}/qa.md"
  cat "${TEST_TMP}/qa.md" > "$qa"

  run run_wizard --upgrade --global --yes
  [ "$status" -eq 0 ]
  [ "$(cat "$claude")" = "$rendered" ]
  [ -f "${claude}.bak-understudy" ]
  grep -q '^model: sonnet$' "$qa"
}

@test "--upgrade --global never touches CLAUDE.md, settings.json or cursor-user-rules.md" {
  deploy_global
  local f
  for f in "${FAKE_HOME}/.claude/CLAUDE.md" "${FAKE_HOME}/.claude/settings.json" "${FAKE_HOME}/.understudy-global/cursor-user-rules.md"; do
    echo "user edit" >> "$f"
  done
  local before
  before="$(cksum < "${FAKE_HOME}/.claude/CLAUDE.md"; cksum < "${FAKE_HOME}/.claude/settings.json"; cksum < "${FAKE_HOME}/.understudy-global/cursor-user-rules.md")"

  run run_wizard --upgrade --global --yes
  [ "$status" -eq 0 ]
  [ "$(cksum < "${FAKE_HOME}/.claude/CLAUDE.md"; cksum < "${FAKE_HOME}/.claude/settings.json"; cksum < "${FAKE_HOME}/.understudy-global/cursor-user-rules.md")" = "$before" ]
}

@test "--upgrade --global does not add manifest entries or files" {
  deploy_global
  local manifest_before files_before
  manifest_before="$(cksum < "${FAKE_HOME}/.understudy-global/manifest")"
  files_before="$(cd "$FAKE_HOME" && find . -type f | LC_ALL=C sort | grep -v -e '\.understudy-global/state$')"

  run run_wizard --upgrade --global --yes
  [ "$status" -eq 0 ]
  [ "$(cksum < "${FAKE_HOME}/.understudy-global/manifest")" = "$manifest_before" ]
  [ "$(cd "$FAKE_HOME" && find . -type f | LC_ALL=C sort | grep -v -e '\.understudy-global/state$')" = "$files_before" ]
}

@test "in-place upgrade keeps a hard link between the global and a second Cursor agent path" {
  deploy_global
  local src="${FAKE_HOME}/.understudy-global/cursor-agents/devops.md"
  local link="${TEST_TMP}/linked-devops.md"
  ln "$src" "$link" 2> /dev/null || skip "hard links unsupported here"
  local rendered
  rendered="$(cat "$src")"
  echo "older template line" >> "$src"
  rebaseline_global "$src"

  run run_wizard --upgrade --global --yes
  [ "$status" -eq 0 ]
  [ "$src" -ef "$link" ]
  [ "$(cat "$link")" = "$rendered" ]
}

@test "--upgrade --global --dry-run writes nothing" {
  deploy_global
  echo "older template line" >> "${FAKE_HOME}/.claude/agents/devops.md"
  rebaseline_global "${FAKE_HOME}/.claude/agents/devops.md"
  local before
  before="$(tree_sum "$FAKE_HOME")"

  run run_wizard --upgrade --global --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"would-upgrade"* ]]
  [ "$(tree_sum "$FAKE_HOME")" = "$before" ]
}

@test "--upgrade --global ignores a project override found via an inherited TARGET_DIR" {
  deploy_global
  mkdir -p "${TEST_TMP}/stray"
  printf 'models:\n  architect: "project-override-model"\n' > "${TEST_TMP}/stray/understudy.yaml"

  TARGET_DIR="${TEST_TMP}/stray" run run_wizard --upgrade --global --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *", 0 would-upgrade,"* ]]
}

# ── CLI ──────────────────────────────────────────────────────────────────────

@test "--upgrade --dry-run runs end-to-end as a subprocess" {
  deploy_project
  cd "$PROJ"
  run run_wizard --upgrade --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"Summary:"* ]]
}

@test "--dry-run without --upgrade is rejected" {
  cd "$PROJ"
  run run_wizard --dry-run
  [ "$status" -eq 1 ]
  [[ "$output" == *"--dry-run only applies to --upgrade"* ]]
}
