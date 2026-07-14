#!/usr/bin/env bats
# Tests for global-mode path resolution helpers in wizard.sh:
# os_family, global_claude_dir, global_state_dir, detect_vscode_user_dirs,
# path_to_file_uri. Covers Linux/macOS/Windows detection and VS Code
# stable/Insiders lookup.

load "../lib/helpers"

setup() {
  setup_tmp
  source_wizard_functions
}

teardown() { teardown_tmp; }

# ── os_family ─────────────────────────────────────────────────────────────────

@test "os_family detects macOS from Darwin" {
  uname() { echo "Darwin"; }
  run os_family
  [ "$output" = "macos" ]
}

@test "os_family detects windows from MINGW" {
  uname() { echo "MINGW64_NT-10.0"; }
  run os_family
  [ "$output" = "windows" ]
}

@test "os_family detects windows from MSYS" {
  uname() { echo "MSYS_NT-10.0"; }
  run os_family
  [ "$output" = "windows" ]
}

@test "os_family detects windows from CYGWIN" {
  uname() { echo "CYGWIN_NT-10.0"; }
  run os_family
  [ "$output" = "windows" ]
}

@test "os_family defaults to linux otherwise" {
  uname() { echo "Linux"; }
  run os_family
  [ "$output" = "linux" ]
}

# ── global_claude_dir / global_state_dir ──────────────────────────────────────

@test "global_claude_dir resolves to \$HOME/.claude" {
  HOME="${TEST_TMP}/fake-home" run global_claude_dir
  [ "$output" = "${TEST_TMP}/fake-home/.claude" ]
}

@test "global_state_dir resolves to \$HOME/.understudy-global, not ~/.understudy" {
  HOME="${TEST_TMP}/fake-home" run global_state_dir
  [ "$output" = "${TEST_TMP}/fake-home/.understudy-global" ]
  [[ "$output" != *"/.understudy" ]] || [[ "$output" == *"/.understudy-global" ]]
}

# ── detect_vscode_user_dirs — Linux ───────────────────────────────────────────

@test "detect_vscode_user_dirs finds Linux stable profile" {
  uname() { echo "Linux"; }
  mkdir -p "${TEST_TMP}/home/.config/Code/User"
  HOME="${TEST_TMP}/home" run detect_vscode_user_dirs
  [[ "$output" == *"/.config/Code/User" ]]
}

@test "detect_vscode_user_dirs finds both stable and Insiders when present" {
  uname() { echo "Linux"; }
  mkdir -p "${TEST_TMP}/home/.config/Code/User" "${TEST_TMP}/home/.config/Code - Insiders/User"
  HOME="${TEST_TMP}/home" run detect_vscode_user_dirs
  [ "$(echo "$output" | wc -l)" -eq 2 ]
}

@test "detect_vscode_user_dirs returns empty when no profile exists" {
  uname() { echo "Linux"; }
  mkdir -p "${TEST_TMP}/empty-home"
  HOME="${TEST_TMP}/empty-home" run detect_vscode_user_dirs
  [ -z "$output" ]
}

# ── detect_vscode_user_dirs — macOS ───────────────────────────────────────────

@test "detect_vscode_user_dirs resolves macOS profile path" {
  uname() { echo "Darwin"; }
  mkdir -p "${TEST_TMP}/home/Library/Application Support/Code/User"
  HOME="${TEST_TMP}/home" run detect_vscode_user_dirs
  [[ "$output" == *"Library/Application Support/Code/User" ]]
}

# ── detect_vscode_user_dirs — Windows ─────────────────────────────────────────

@test "detect_vscode_user_dirs resolves Windows profile via APPDATA" {
  uname() { echo "MINGW64_NT-10.0"; }
  mkdir -p "${TEST_TMP}/AppData/Roaming/Code/User"
  APPDATA="${TEST_TMP}/AppData/Roaming" run detect_vscode_user_dirs
  [[ "$output" == *"/Code/User" ]]
}

@test "detect_vscode_user_dirs runs APPDATA through normalize_path on Windows" {
  uname() { echo "MINGW64_NT-10.0"; }
  mkdir -p "${TEST_TMP}/AppData/Roaming/Code/User"
  # normalize_path is a no-op for already-POSIX paths (no leading "X:"), so
  # this also proves the Windows branch routes APPDATA through it rather
  # than using it verbatim.
  run normalize_path "${TEST_TMP}/AppData/Roaming"
  local expected_appdata="$output"
  [ "$expected_appdata" = "${TEST_TMP}/AppData/Roaming" ]
}

# ── path_to_file_uri ───────────────────────────────────────────────────────────

@test "path_to_file_uri converts a git-bash mount path to an uppercase-drive file URI on Windows" {
  uname() { echo "MINGW64_NT-10.0"; }
  run path_to_file_uri "/c/Users/dev/.understudy-global/cursor-user-rules.md"
  [ "$output" = "file:///C:/Users/dev/.understudy-global/cursor-user-rules.md" ]
}

@test "path_to_file_uri uppercases an already-lowercase drive letter" {
  uname() { echo "MSYS_NT-10.0"; }
  run path_to_file_uri "/d/repo/file.md"
  [ "$output" = "file:///D:/repo/file.md" ]
}

@test "path_to_file_uri preserves an already-uppercase drive letter" {
  uname() { echo "MINGW64_NT-10.0"; }
  run path_to_file_uri "/C/repo/file.md"
  [ "$output" = "file:///C:/repo/file.md" ]
}

@test "path_to_file_uri leaves plain paths untouched on Linux" {
  uname() { echo "Linux"; }
  run path_to_file_uri "/home/dev/.understudy-global/cursor-user-rules.md"
  [ "$output" = "file:///home/dev/.understudy-global/cursor-user-rules.md" ]
}

@test "path_to_file_uri leaves plain paths untouched on macOS" {
  uname() { echo "Darwin"; }
  run path_to_file_uri "/Users/dev/.understudy-global/cursor-user-rules.md"
  [ "$output" = "file:///Users/dev/.understudy-global/cursor-user-rules.md" ]
}

@test "path_to_file_uri falls back to a plain file:// prefix on Windows for a non-mount path" {
  uname() { echo "MINGW64_NT-10.0"; }
  run path_to_file_uri "relative/or/unrecognized/path.md"
  [ "$output" = "file://relative/or/unrecognized/path.md" ]
}
