#!/usr/bin/env bats
# Tests for global_manifest_add and deploy_file_global — the bookkeeping that
# lets `understudy --global --uninstall` remove exactly what a global deploy
# created, and never a file the user already had.

load "../lib/helpers"

setup() {
  setup_tmp
  source_wizard_functions

  # Project variables deploy_file reads from globals (same set used by
  # tests/unit/deploy_file.bats).
  PROJECT_NAME="test"
  PROJECT_DESCRIPTION="desc"
  TECH_STACK="stack"
  TEAM_LEAD="lead"
  REPOSITORY_URL="url"
  PROJECT_DATE="2026-01-01"
  MODEL_ARCHITECT="m" MODEL_BACKEND="m" MODEL_FRONTEND="m"
  MODEL_DEVOPS="m" MODEL_SECURITY="m" MODEL_QA="m"
  APPLY_TO_ARCHITECT="" APPLY_TO_BACKEND="" APPLY_TO_FRONTEND=""
  APPLY_TO_DEVOPS="" APPLY_TO_SECURITY="" APPLY_TO_QA=""

  FAKE_HOME="${TEST_TMP}/home"
  mkdir -p "$FAKE_HOME"
}

teardown() { teardown_tmp; }

@test "global_manifest_add records a new path under \$HOME/.understudy-global" {
  HOME="$FAKE_HOME" global_manifest_add "/some/path/file.md"
  grep -qxF "/some/path/file.md" "${FAKE_HOME}/.understudy-global/manifest"
}

@test "global_manifest_add does not duplicate an existing entry" {
  HOME="$FAKE_HOME" global_manifest_add "/some/path/file.md"
  HOME="$FAKE_HOME" global_manifest_add "/some/path/file.md"
  [ "$(grep -cxF "/some/path/file.md" "${FAKE_HOME}/.understudy-global/manifest")" -eq 1 ]
}

@test "global_manifest_add keeps its state out of ~/.understudy (install payload)" {
  HOME="$FAKE_HOME" global_manifest_add "/some/path/file.md"
  [ ! -d "${FAKE_HOME}/.understudy" ]
  [ -f "${FAKE_HOME}/.understudy-global/manifest" ]
}

@test "deploy_file_global creates the destination file" {
  echo "hello {{PROJECT_NAME}}" > "${TEST_TMP}/src.md"
  HOME="$FAKE_HOME" deploy_file_global "${TEST_TMP}/src.md" "${FAKE_HOME}/dst.md"
  [ -f "${FAKE_HOME}/dst.md" ]
  grep -q "hello test" "${FAKE_HOME}/dst.md"
}

@test "deploy_file_global tracks a newly created file in the manifest" {
  echo "content" > "${TEST_TMP}/src.md"
  HOME="$FAKE_HOME" deploy_file_global "${TEST_TMP}/src.md" "${FAKE_HOME}/dst.md"
  grep -qxF "${FAKE_HOME}/dst.md" "${FAKE_HOME}/.understudy-global/manifest"
}

@test "deploy_file_global does not overwrite a pre-existing destination file" {
  echo "ORIGINAL" > "${FAKE_HOME}/dst.md"
  echo "NEW" > "${TEST_TMP}/src.md"
  HOME="$FAKE_HOME" deploy_file_global "${TEST_TMP}/src.md" "${FAKE_HOME}/dst.md"
  grep -q "ORIGINAL" "${FAKE_HOME}/dst.md"
}

@test "deploy_file_global never records a pre-existing destination file in the manifest" {
  echo "ORIGINAL" > "${FAKE_HOME}/dst.md"
  echo "NEW" > "${TEST_TMP}/src.md"
  HOME="$FAKE_HOME" deploy_file_global "${TEST_TMP}/src.md" "${FAKE_HOME}/dst.md"
  if [[ -f "${FAKE_HOME}/.understudy-global/manifest" ]]; then
    run grep -cxF "${FAKE_HOME}/dst.md" "${FAKE_HOME}/.understudy-global/manifest"
    [ "$output" = "0" ]
  fi
}
