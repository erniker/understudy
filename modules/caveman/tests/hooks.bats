#!/usr/bin/env bats
# Tests for modules/caveman/bin/install-hooks across the three target
# platforms (Claude Code real hooks, Copilot text injection, Cursor
# always-applied rule). Also covers wizard.sh wiring via --caveman-hooks.

load '../../../tests/lib/helpers'

INSTALL_HOOKS="${BATS_TEST_DIRNAME}/../bin/install-hooks"

setup() {
    setup_tmp
    cd "$TEST_TMP"
    mkdir -p .claude .github .cursor/rules
    printf '{}\n' > .claude/settings.json
    printf '# Project Copilot rules\n' > .github/copilot-instructions.md
}

teardown() { teardown_tmp; }

# ── Detection ────────────────────────────────────────────────────────

@test "install-hooks --help returns 0 and mentions install/uninstall" {
    run "$INSTALL_HOOKS" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"install"* ]]
    [[ "$output" == *"uninstall"* ]]
}

@test "install-hooks aborts when no AI platforms are present" {
    rm -rf .claude .github .cursor
    run "$INSTALL_HOOKS" install
    [ "$status" -ne 0 ]
    [[ "$output" == *"no AI platforms detected"* ]]
}

# ── Claude (real hooks) ─────────────────────────────────────────────

@test "install --mode remind wires SessionStart hook in settings.json" {
    run "$INSTALL_HOOKS" install --mode remind --platforms claude
    [ "$status" -eq 0 ]
    run grep -q '"SessionStart"' .claude/settings.json
    [ "$status" -eq 0 ]
    [ -x .claude/hooks/caveman/session-start.sh ]
    # No compress hook in remind-only mode.
    run grep -q '"UserPromptSubmit"' .claude/settings.json
    [ "$status" -ne 0 ]
}

@test "install --mode compress wires UserPromptSubmit hook and creates paths file" {
    run "$INSTALL_HOOKS" install --mode compress --platforms claude
    [ "$status" -eq 0 ]
    run grep -q '"UserPromptSubmit"' .claude/settings.json
    [ "$status" -eq 0 ]
    [ -x .claude/hooks/caveman/user-prompt-submit.sh ]
    [ -f .caveman/auto-compress.paths ]
    # No remind hook in compress-only mode.
    run grep -q '"SessionStart"' .claude/settings.json
    [ "$status" -ne 0 ]
}

@test "install --mode both wires both hooks" {
    run "$INSTALL_HOOKS" install --mode both --platforms claude
    [ "$status" -eq 0 ]
    run grep -q '"SessionStart"' .claude/settings.json
    [ "$status" -eq 0 ]
    run grep -q '"UserPromptSubmit"' .claude/settings.json
    [ "$status" -eq 0 ]
}

@test "install preserves pre-existing non-caveman hooks (PreToolUse stays)" {
    cat > .claude/settings.json <<'JSON'
{
  "permissions": {"deny": ["Read(.env)"]},
  "hooks": {
    "PreToolUse": [
      {"matcher": "Bash", "hooks": [{"type": "command", "command": ".claude/hooks/guardrails-check.sh"}]}
    ]
  }
}
JSON
    run "$INSTALL_HOOKS" install --mode remind --platforms claude
    [ "$status" -eq 0 ]
    run grep -q '"PreToolUse"' .claude/settings.json
    [ "$status" -eq 0 ]
    run grep -q '"SessionStart"' .claude/settings.json
    [ "$status" -eq 0 ]
    run grep -q '"deny"' .claude/settings.json
    [ "$status" -eq 0 ]
}

@test "reinstall is idempotent (no duplicate SessionStart entries)" {
    "$INSTALL_HOOKS" install --mode remind --platforms claude
    "$INSTALL_HOOKS" install --mode remind --platforms claude
    run grep -c '__caveman' .claude/settings.json
    [ "$status" -eq 0 ]
    [ "$output" -eq 1 ]
}

@test "uninstall removes only the caveman entries" {
    cat > .claude/settings.json <<'JSON'
{"hooks": {"PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "x"}]}]}}
JSON
    "$INSTALL_HOOKS" install --mode both --platforms claude
    run "$INSTALL_HOOKS" uninstall --platforms claude
    [ "$status" -eq 0 ]
    run grep -q '"SessionStart"' .claude/settings.json
    [ "$status" -ne 0 ]
    run grep -q '"PreToolUse"' .claude/settings.json
    [ "$status" -eq 0 ]
    [ ! -f .claude/hooks/caveman/session-start.sh ]
    [ ! -f .claude/hooks/caveman/user-prompt-submit.sh ]
}

# ── Copilot (degraded text injection) ───────────────────────────────

@test "install drops a marker-delimited block in copilot-instructions.md" {
    run "$INSTALL_HOOKS" install --mode remind --platforms copilot
    [ "$status" -eq 0 ]
    run grep -c "caveman:hooks:start" .github/copilot-instructions.md
    [ "$output" -eq 1 ]
    run grep -q "Project Copilot rules" .github/copilot-instructions.md
    [ "$status" -eq 0 ]
}

@test "reinstall replaces the copilot block in place (no duplicates)" {
    "$INSTALL_HOOKS" install --mode remind --platforms copilot
    "$INSTALL_HOOKS" install --mode remind --platforms copilot
    run grep -c "caveman:hooks:start" .github/copilot-instructions.md
    [ "$output" -eq 1 ]
}

@test "uninstall removes only the copilot block" {
    "$INSTALL_HOOKS" install --mode remind --platforms copilot
    run "$INSTALL_HOOKS" uninstall --platforms copilot
    [ "$status" -eq 0 ]
    run grep -q "caveman:hooks:start" .github/copilot-instructions.md
    [ "$status" -ne 0 ]
    run grep -q "Project Copilot rules" .github/copilot-instructions.md
    [ "$status" -eq 0 ]
}

# ── Cursor (degraded always-applied rule) ───────────────────────────

@test "install writes a Cursor rule with alwaysApply: true" {
    run "$INSTALL_HOOKS" install --mode remind --platforms cursor
    [ "$status" -eq 0 ]
    [ -f .cursor/rules/00-caveman-active.mdc ]
    run grep -q "alwaysApply: true" .cursor/rules/00-caveman-active.mdc
    [ "$status" -eq 0 ]
}

@test "uninstall removes the Cursor rule" {
    "$INSTALL_HOOKS" install --mode remind --platforms cursor
    run "$INSTALL_HOOKS" uninstall --platforms cursor
    [ "$status" -eq 0 ]
    [ ! -f .cursor/rules/00-caveman-active.mdc ]
}

# ── Wizard wiring ───────────────────────────────────────────────────

@test "wizard --help lists --caveman-hooks under post-install flags" {
    run "$WIZARD" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"--caveman-hooks"* ]]
}

@test "discover_modules registers the --caveman-hooks post-install flag" {
    source_wizard_functions
    run postinstall_index_by_flag --caveman-hooks
    [ "$status" -eq 0 ]
}

@test "post-install action is skipped if its module is not included" {
    source_wizard_functions
    # Mark the post-install flag as requested but leave the module out.
    local idx
    idx="$(postinstall_index_by_flag --caveman-hooks)"
    POSTINSTALL_REQUESTED[$idx]=true
    module_set_included caveman false
    TARGET_DIR="$TEST_TMP"
    run run_postinstall_actions
    [ "$status" -eq 0 ]
    [[ "$output" == *"Skipping --caveman-hooks"* ]]
}
