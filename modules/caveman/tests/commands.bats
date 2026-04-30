#!/usr/bin/env bats
# Tests for modules/caveman/bin/install-commands across the three target
# platforms. Also covers wizard.sh wiring via --caveman-commands.

load '../../../tests/lib/helpers'

INSTALL_COMMANDS="${BATS_TEST_DIRNAME}/../bin/install-commands"

setup() {
    setup_tmp
    cd "$TEST_TMP"
    mkdir -p .claude .github .cursor
}

teardown() { teardown_tmp; }

# ── Detection ────────────────────────────────────────────────────────

@test "install-commands --help returns 0 and mentions install/uninstall" {
    run "$INSTALL_COMMANDS" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"install"* ]]
    [[ "$output" == *"uninstall"* ]]
}

@test "install-commands aborts when no AI platforms are present" {
    rm -rf .claude .github .cursor
    run "$INSTALL_COMMANDS" install
    [ "$status" -ne 0 ]
    [[ "$output" == *"no AI platforms detected"* ]]
}

# ── Claude commands ──────────────────────────────────────────────────

@test "install drops compress.md and restore.md under .claude/commands/" {
    run "$INSTALL_COMMANDS" install --platforms claude
    [ "$status" -eq 0 ]
    [ -f .claude/commands/compress.md ]
    [ -f .claude/commands/restore.md ]
    grep -qF 'caveman:command' .claude/commands/compress.md
    grep -qF 'caveman:command' .claude/commands/restore.md
}

@test "install is idempotent (reinstall does not duplicate or corrupt files)" {
    "$INSTALL_COMMANDS" install --platforms claude
    "$INSTALL_COMMANDS" install --platforms claude
    [ -f .claude/commands/compress.md ]
    # Single, well-formed frontmatter (only one `name: compress` line).
    run grep -c '^name: compress$' .claude/commands/compress.md
    [ "$output" -eq 1 ]
}

@test "uninstall removes only files carrying the caveman sentinel" {
    "$INSTALL_COMMANDS" install --platforms claude
    # User-authored file in the same directory: must survive uninstall.
    printf 'user authored, no sentinel\n' > .claude/commands/my-own.md
    run "$INSTALL_COMMANDS" uninstall --platforms claude
    [ "$status" -eq 0 ]
    [ ! -f .claude/commands/compress.md ]
    [ ! -f .claude/commands/restore.md ]
    [ -f .claude/commands/my-own.md ]
}

@test "uninstall preserves a user file that happens to share a name with a caveman command" {
    "$INSTALL_COMMANDS" install --platforms claude
    # Replace the caveman compress.md with a user-authored version (no sentinel).
    printf -- '---\nname: compress\n---\n\nMy own override.\n' > .claude/commands/compress.md
    run "$INSTALL_COMMANDS" uninstall --platforms claude
    [ "$status" -eq 0 ]
    [ -f .claude/commands/compress.md ]
    grep -qF 'My own override' .claude/commands/compress.md
}

# ── Copilot prompts ─────────────────────────────────────────────────

@test "install drops .prompt.md files under .github/prompts/" {
    run "$INSTALL_COMMANDS" install --platforms copilot
    [ "$status" -eq 0 ]
    [ -f .github/prompts/compress.prompt.md ]
    [ -f .github/prompts/restore.prompt.md ]
    grep -qF 'caveman:command' .github/prompts/compress.prompt.md
}

@test "uninstall removes only sentinel-tagged Copilot prompts" {
    "$INSTALL_COMMANDS" install --platforms copilot
    printf 'user authored, no sentinel\n' > .github/prompts/my-own.prompt.md
    run "$INSTALL_COMMANDS" uninstall --platforms copilot
    [ "$status" -eq 0 ]
    [ ! -f .github/prompts/compress.prompt.md ]
    [ -f .github/prompts/my-own.prompt.md ]
}

# ── Cursor commands ─────────────────────────────────────────────────

@test "install drops compress.md and restore.md under .cursor/commands/" {
    run "$INSTALL_COMMANDS" install --platforms cursor
    [ "$status" -eq 0 ]
    [ -f .cursor/commands/compress.md ]
    [ -f .cursor/commands/restore.md ]
    grep -qF 'caveman:command' .cursor/commands/compress.md
}

@test "uninstall removes only sentinel-tagged Cursor commands" {
    "$INSTALL_COMMANDS" install --platforms cursor
    printf 'user authored, no sentinel\n' > .cursor/commands/my-own.md
    run "$INSTALL_COMMANDS" uninstall --platforms cursor
    [ "$status" -eq 0 ]
    [ ! -f .cursor/commands/compress.md ]
    [ -f .cursor/commands/my-own.md ]
}

# ── Wizard wiring ───────────────────────────────────────────────────

@test "wizard --help lists --caveman-commands under post-install flags" {
    run "$WIZARD" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"--caveman-commands"* ]]
}

@test "discover_modules registers the --caveman-commands post-install flag" {
    source_wizard_functions
    run postinstall_index_by_flag --caveman-commands
    [ "$status" -eq 0 ]
}

@test "post-install action is skipped if its module is not included" {
    source_wizard_functions
    local idx
    idx="$(postinstall_index_by_flag --caveman-commands)"
    POSTINSTALL_REQUESTED[$idx]=true
    module_set_included caveman false
    TARGET_DIR="$TEST_TMP"
    run run_postinstall_actions
    [ "$status" -eq 0 ]
    [[ "$output" == *"Skipping --caveman-commands"* ]]
}
