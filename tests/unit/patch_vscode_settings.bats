#!/usr/bin/env bats
# Tests for patch_vscode_settings() — the real jq merge logic that edits a
# VS Code user settings.json. Every other test in the suite forces
# UNDERSTUDY_SKIP_JQ_INSTALL=1 (this dev machine has no jq installed and we
# never want a test to trigger a real package-manager install), which means
# this specific code path has never run in CI/locally. These tests `skip`
# gracefully when jq isn't available, and run for real wherever it is
# (e.g. a CI image that ships jq) — closing the gap without any risk here.

load "../lib/helpers"

setup() {
  setup_tmp
  source_wizard_functions
}

teardown() { teardown_tmp; }

require_jq() {
  command -v jq &>/dev/null || skip "jq not installed on this machine"
}

@test "patch_vscode_settings merges instructions/prompts locations into existing settings.json" {
  require_jq
  local vs_dir="${TEST_TMP}/vscode-profile"
  mkdir -p "$vs_dir"
  cat > "${vs_dir}/settings.json" << 'EOF'
{
  "editor.fontSize": 14
}
EOF

  patch_vscode_settings "$vs_dir" "${vs_dir}/understudy/instructions" "${vs_dir}/understudy/prompts"

  grep -q '"editor.fontSize": 14' "${vs_dir}/settings.json"
  grep -q "understudy/instructions" "${vs_dir}/settings.json"
  grep -q "understudy/prompts" "${vs_dir}/settings.json"
}

@test "patch_vscode_settings produces valid JSON" {
  require_jq
  local vs_dir="${TEST_TMP}/vscode-profile-valid"
  mkdir -p "$vs_dir"
  echo '{"foo": "bar"}' > "${vs_dir}/settings.json"

  patch_vscode_settings "$vs_dir" "${vs_dir}/understudy/instructions" "${vs_dir}/understudy/prompts"

  jq empty "${vs_dir}/settings.json"
}

@test "patch_vscode_settings creates settings.json when it doesn't exist yet" {
  require_jq
  local vs_dir="${TEST_TMP}/vscode-profile-new"
  mkdir -p "$vs_dir"

  patch_vscode_settings "$vs_dir" "${vs_dir}/understudy/instructions" "${vs_dir}/understudy/prompts"

  [ -f "${vs_dir}/settings.json" ]
  grep -q "understudy/instructions" "${vs_dir}/settings.json"
}

@test "patch_vscode_settings writes a restorable backup of the original file" {
  require_jq
  local vs_dir="${TEST_TMP}/vscode-profile-backup"
  mkdir -p "$vs_dir"
  echo '{"foo": "bar"}' > "${vs_dir}/settings.json"

  patch_vscode_settings "$vs_dir" "${vs_dir}/understudy/instructions" "${vs_dir}/understudy/prompts"

  [ -f "${vs_dir}/settings.json.bak-understudy" ]
  grep -q '"foo": "bar"' "${vs_dir}/settings.json.bak-understudy"
}

@test "patch_vscode_settings preserves an existing chat.instructionsFilesLocations entry" {
  require_jq
  local vs_dir="${TEST_TMP}/vscode-profile-preserve"
  mkdir -p "$vs_dir"
  cat > "${vs_dir}/settings.json" << 'EOF'
{
  "chat.instructionsFilesLocations": { "/some/other/path": true }
}
EOF

  patch_vscode_settings "$vs_dir" "${vs_dir}/understudy/instructions" "${vs_dir}/understudy/prompts"

  grep -q "/some/other/path" "${vs_dir}/settings.json"
  grep -q "understudy/instructions" "${vs_dir}/settings.json"
}
