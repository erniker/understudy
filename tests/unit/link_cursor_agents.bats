#!/usr/bin/env bats
# Unit tests for link_cursor_agents_into_project() — the hard-link mechanism
# that gives Cursor real per-role agents shared with the global install,
# instead of copies that drift out of sync.

load "../lib/helpers"

setup() {
  setup_tmp
  source_wizard_functions
}

teardown() { teardown_tmp; }

@test "no-ops when no global cursor-agents source exists" {
  HOME="${TEST_TMP}/home" link_cursor_agents_into_project "${TEST_TMP}/project"
  [ ! -d "${TEST_TMP}/project/.cursor" ]
}

@test "hard-links a role file into the project's .cursor/agents" {
  mkdir -p "${TEST_TMP}/home/.understudy-global/cursor-agents"
  echo "content" > "${TEST_TMP}/home/.understudy-global/cursor-agents/architect.md"

  HOME="${TEST_TMP}/home" link_cursor_agents_into_project "${TEST_TMP}/project"

  local dst="${TEST_TMP}/project/.cursor/agents/architect.md"
  [ -f "$dst" ]
  local src_inode dst_inode
  src_inode="$(ls -i "${TEST_TMP}/home/.understudy-global/cursor-agents/architect.md" | awk '{print $1}')"
  dst_inode="$(ls -i "$dst" | awk '{print $1}')"
  [ "$src_inode" = "$dst_inode" ]
}

@test "links every file present in the global cursor-agents source" {
  mkdir -p "${TEST_TMP}/home/.understudy-global/cursor-agents"
  for role in architect backend frontend; do
    echo "content for $role" > "${TEST_TMP}/home/.understudy-global/cursor-agents/${role}.md"
  done

  HOME="${TEST_TMP}/home" link_cursor_agents_into_project "${TEST_TMP}/project"

  [ -f "${TEST_TMP}/project/.cursor/agents/architect.md" ]
  [ -f "${TEST_TMP}/project/.cursor/agents/backend.md" ]
  [ -f "${TEST_TMP}/project/.cursor/agents/frontend.md" ]
}

@test "falls back to a plain copy when ln fails (e.g. different filesystem)" {
  mkdir -p "${TEST_TMP}/home/.understudy-global/cursor-agents"
  echo "content" > "${TEST_TMP}/home/.understudy-global/cursor-agents/architect.md"
  ln() { return 1; }

  HOME="${TEST_TMP}/home" link_cursor_agents_into_project "${TEST_TMP}/project"

  local dst="${TEST_TMP}/project/.cursor/agents/architect.md"
  [ -f "$dst" ]
  grep -q "content" "$dst"
}

@test "never overwrites a pre-existing project agent file" {
  mkdir -p "${TEST_TMP}/home/.understudy-global/cursor-agents"
  echo "global content" > "${TEST_TMP}/home/.understudy-global/cursor-agents/architect.md"
  mkdir -p "${TEST_TMP}/project/.cursor/agents"
  echo "existing content" > "${TEST_TMP}/project/.cursor/agents/architect.md"

  HOME="${TEST_TMP}/home" link_cursor_agents_into_project "${TEST_TMP}/project"

  grep -q "existing content" "${TEST_TMP}/project/.cursor/agents/architect.md"
}
