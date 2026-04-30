#!/usr/bin/env bats
# Tests for modules/caveman/bin/install-statusline. Statusline is
# Claude-only; no Copilot/Cursor branches to test.

load '../../../tests/lib/helpers'

INSTALL_STATUSLINE="${BATS_TEST_DIRNAME}/../bin/install-statusline"
STATUSLINE_SH="${BATS_TEST_DIRNAME}/../statusline/caveman-statusline.sh"

setup() {
    setup_tmp
    cd "$TEST_TMP"
    mkdir -p .claude
    printf '{}\n' > .claude/settings.json
}

teardown() { teardown_tmp; }

# ── Installer ────────────────────────────────────────────────────────

@test "install-statusline --help returns 0 and mentions install/uninstall" {
    run "$INSTALL_STATUSLINE" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"install"* ]]
    [[ "$output" == *"uninstall"* ]]
}

@test "install-statusline aborts when .claude/ is missing" {
    rm -rf .claude
    run "$INSTALL_STATUSLINE" install
    [ "$status" -ne 0 ]
    [[ "$output" == *"no Claude Code deployment found"* ]]
}

@test "install copies the script and points settings.json at it" {
    run "$INSTALL_STATUSLINE" install
    [ "$status" -eq 0 ]
    [ -x .claude/statusline/caveman-statusline.sh ]
    run python3 -c 'import json,sys; d=json.load(open(".claude/settings.json")); s=d["statusLine"]; sys.exit(0 if s.get("__caveman") and s.get("command")==".claude/statusline/caveman-statusline.sh" else 1)'
    [ "$status" -eq 0 ]
}

@test "install is idempotent (reinstall does not duplicate the entry)" {
    "$INSTALL_STATUSLINE" install
    "$INSTALL_STATUSLINE" install
    # statusLine is a single object, so "duplication" would surface as
    # an array or as a stale non-caveman entry. Confirm the marker is
    # still present and the field is still an object.
    run python3 -c 'import json,sys; d=json.load(open(".claude/settings.json")); s=d["statusLine"]; sys.exit(0 if isinstance(s, dict) and s.get("__caveman") else 1)'
    [ "$status" -eq 0 ]
}

@test "uninstall removes the script and clears the field" {
    "$INSTALL_STATUSLINE" install
    run "$INSTALL_STATUSLINE" uninstall
    [ "$status" -eq 0 ]
    [ ! -e .claude/statusline/caveman-statusline.sh ]
    run python3 -c 'import json,sys; d=json.load(open(".claude/settings.json")); sys.exit(0 if "statusLine" not in d else 1)'
    [ "$status" -eq 0 ]
}

@test "uninstall preserves a foreign statusline (no caveman marker)" {
    python3 -c 'import json; json.dump({"statusLine": {"type":"command","command":"my-tool"}}, open(".claude/settings.json","w"))'
    run "$INSTALL_STATUSLINE" uninstall
    [ "$status" -eq 0 ]
    run python3 -c 'import json,sys; d=json.load(open(".claude/settings.json")); s=d.get("statusLine") or {}; sys.exit(0 if s.get("command")=="my-tool" else 1)'
    [ "$status" -eq 0 ]
}

# ── Statusline script ───────────────────────────────────────────────

@test "statusline prints 'caveman: ready' on a workspace with no backups" {
    run bash "$STATUSLINE_SH" <<<'{}'
    [ "$status" -eq 0 ]
    [[ "$output" == "caveman: ready" ]]
}

@test "statusline reports byte savings when .original.md is larger than .md" {
    printf 'This is a long original prose with many many filler words.\n' > doc.original.md
    printf 'Short.\n' > doc.md
    run bash "$STATUSLINE_SH" <<<'{}'
    [ "$status" -eq 0 ]
    [[ "$output" == *"caveman: 1 file"* ]]
    [[ "$output" == *"-"*"bytes"* ]]
    [[ "$output" == *"%"* ]]
}

@test "statusline counts multiple files and aggregates savings" {
    printf 'AAAAAAAAAAAAAAAAAAAA\n' > a.original.md
    printf 'A\n' > a.md
    printf 'BBBBBBBBBBBBBBBBBBBB\n' > b.original.md
    printf 'B\n' > b.md
    run bash "$STATUSLINE_SH" <<<'{}'
    [ "$status" -eq 0 ]
    [[ "$output" == *"caveman: 2 files"* ]]
}

@test "statusline ignores backup files whose live counterpart is missing" {
    printf 'AAAAAAAAAAAAAAAAAAAA\n' > orphan.original.md
    run bash "$STATUSLINE_SH" <<<'{}'
    [ "$status" -eq 0 ]
    [[ "$output" == "caveman: ready" ]]
}

@test "statusline never aborts on a malformed JSON payload" {
    run bash "$STATUSLINE_SH" <<<'this is not json at all'
    [ "$status" -eq 0 ]
}

# ── Wizard wiring ───────────────────────────────────────────────────

@test "wizard --help lists --caveman-statusline" {
    run "$WIZARD" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"--caveman-statusline"* ]]
}

@test "discover_modules registers the --caveman-statusline post-install flag" {
    source_wizard_functions
    run postinstall_index_by_flag --caveman-statusline
    [ "$status" -eq 0 ]
}

@test "post-install action is skipped if caveman module is not included" {
    source_wizard_functions
    local idx
    idx="$(postinstall_index_by_flag --caveman-statusline)"
    POSTINSTALL_REQUESTED[$idx]=true
    module_set_included caveman false
    TARGET_DIR="$TEST_TMP"
    run run_postinstall_actions
    [ "$status" -eq 0 ]
    [[ "$output" == *"Skipping --caveman-statusline"* ]]
}
