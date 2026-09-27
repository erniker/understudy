#!/usr/bin/env bats
# Tests for the project-override layer of load_config in wizard.sh.
# The override path is "${TARGET_DIR}/understudy.yaml". --global has no project
# directory (TARGET_DIR is unset when load_config runs), so that path used to
# collapse to "/understudy.yaml" — or to whatever TARGET_DIR happened to be in
# the environment. A machine-wide install must ignore project overrides.
# TARGET_DIR is the variable that resolves the path, so pointing it at a temp
# dir simulates the accidental lookup without ever touching the filesystem root.

load "../lib/helpers"

setup() {
  setup_tmp
  source_wizard_functions
  PROJECT_DIR="${TEST_TMP}/project"
  mkdir -p "$PROJECT_DIR"
  cat > "${PROJECT_DIR}/understudy.yaml" <<'EOF'
models:
  architect: "project-override-model"
platforms:
  cursor: false
EOF
}

teardown() { teardown_tmp; }

@test "load_config applies the project override in project mode" {
  GLOBAL_MODE=false
  TARGET_DIR="$PROJECT_DIR"
  load_config
  [ "$MODEL_ARCHITECT" = "project-override-model" ]
  [ "$PLATFORM_CURSOR" = "false" ]
}

@test "load_config ignores the project override in --global mode" {
  GLOBAL_MODE=true
  TARGET_DIR="$PROJECT_DIR"
  load_config
  [ "$MODEL_ARCHITECT" = "claude-opus-4.6" ]
  [ "$PLATFORM_CURSOR" = "true" ]
}

@test "load_config in --global mode never reads any file but the global defaults" {
  local read_files="${TEST_TMP}/read_files"
  : > "$read_files"
  config_read() { printf '%s\n' "$4" >> "$read_files"; echo "$3"; }
  GLOBAL_MODE=true
  TARGET_DIR="$PROJECT_DIR"
  load_config
  [ -s "$read_files" ]
  run awk -v d="$DEFAULT_CONFIG" '$0 != d { bad = 1 } END { exit bad }' "$read_files"
  [ "$status" -eq 0 ]
}

@test "load_config in --global mode still applies the global defaults" {
  GLOBAL_MODE=true
  unset TARGET_DIR
  load_config
  [ "$MODEL_ARCHITECT" = "$(config_read "models" "architect" "" "$DEFAULT_CONFIG")" ]
}
