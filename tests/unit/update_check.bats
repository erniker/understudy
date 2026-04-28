#!/usr/bin/env bats
# Tests for update-check helper functions in wizard.sh.

load "../lib/helpers"

setup() {
  source_wizard_functions
  setup_tmp
}

teardown() {
  teardown_tmp
}

@test "read_local_version reads first released version from changelog" {
  cat > "${TEST_TMP}/CHANGELOG.md" << 'EOF'
# Changelog

## [0.4.1] - 2026-05-01
### Added
- Something

## [0.4.0] - 2026-04-30
### Fixed
- Something else
EOF

  run read_local_version "${TEST_TMP}/CHANGELOG.md"
  [ "$status" -eq 0 ]
  [ "$output" = "v0.4.1" ]
}

@test "read_local_version fails if changelog is missing" {
  run read_local_version "${TEST_TMP}/missing.md"
  [ "$status" -eq 1 ]
}

@test "version_is_newer returns true when latest major is higher" {
  run version_is_newer "v1.0.0" "v0.9.9"
  [ "$status" -eq 0 ]
}

@test "version_is_newer returns true when latest minor is higher" {
  run version_is_newer "v0.4.0" "v0.3.9"
  [ "$status" -eq 0 ]
}

@test "version_is_newer returns true when latest patch is higher" {
  run version_is_newer "v0.3.1" "v0.3.0"
  [ "$status" -eq 0 ]
}

@test "version_is_newer returns false when versions are equal" {
  run version_is_newer "v0.3.0" "v0.3.0"
  [ "$status" -eq 1 ]
}

@test "version_is_newer returns false when latest is lower" {
  run version_is_newer "v0.2.9" "v0.3.0"
  [ "$status" -eq 1 ]
}

@test "version_is_newer ignores prerelease suffix" {
  run version_is_newer "v0.4.0-rc1" "v0.3.9"
  [ "$status" -eq 0 ]
}
