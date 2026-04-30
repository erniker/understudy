#!/usr/bin/env bash
# caveman-statusline — Claude Code statusline that reports compression
# savings across the workspace.
#
# Claude Code invokes statusline scripts on every turn (rate-limited to
# ~300ms). It pipes a JSON payload on stdin (session_id, transcript_path,
# cwd, model, ...) and prints whatever this script writes on stdout as
# the statusline. Stderr and exit codes are ignored.
#
# Contract:
# - Must be fast (<300ms). We rely on `find` + `stat` only.
# - Must never modify any file. Read-only.
# - Must never abort. Errors fall back to a neutral "caveman: ready"
#   line so the user is not left without a statusline.
#
# Output:
#   "caveman: ready"                                 — no compressed files
#   "caveman: N file(s) | -X bytes (-Y%)"            — savings detected
set -uo pipefail

# Be defensive about CWD: Claude passes cwd in the JSON, but $PWD is
# typically the same. Don't bother parsing JSON for portability.
ROOT="${PWD:-.}"

# Find all .original.md backup files anywhere in the workspace, prune
# heavy / irrelevant trees.
mapfile -t backups < <(
    find "$ROOT" \
        \( -name node_modules -o -name .git -o -name dist -o -name build -o -name .venv -o -name venv -o -name target \) -prune -o \
        -type f -name '*.original.md' -print 2>/dev/null
)

if (( ${#backups[@]} == 0 )); then
    printf 'caveman: ready'
    exit 0
fi

count=0
orig_total=0
live_total=0

for orig in "${backups[@]}"; do
    # Live counterpart: drop the ".original" infix.
    live="${orig%.original.md}.md"
    [[ -f "$live" ]] || continue

    # `stat -c %s` (GNU) and `stat -f %z` (BSD/macOS). Try both.
    obytes="$(stat -c %s -- "$orig" 2>/dev/null || stat -f %z -- "$orig" 2>/dev/null || echo 0)"
    lbytes="$(stat -c %s -- "$live" 2>/dev/null || stat -f %z -- "$live" 2>/dev/null || echo 0)"

    # Skip pathological reads.
    [[ "$obytes" =~ ^[0-9]+$ ]] || continue
    [[ "$lbytes" =~ ^[0-9]+$ ]] || continue

    count=$((count + 1))
    orig_total=$((orig_total + obytes))
    live_total=$((live_total + lbytes))
done

if (( count == 0 || orig_total == 0 )); then
    printf 'caveman: ready'
    exit 0
fi

# Negative delta = compression win; positive would mean the "compressed"
# file grew (rare but possible if the user re-edited it).
delta=$((live_total - orig_total))
pct=$(( delta * 100 / orig_total ))

printf 'caveman: %d file%s | %+d bytes (%+d%%)' \
    "$count" \
    "$([[ $count -eq 1 ]] && printf '' || printf 's')" \
    "$delta" \
    "$pct"
