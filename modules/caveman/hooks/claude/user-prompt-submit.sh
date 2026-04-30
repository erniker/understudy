#!/usr/bin/env bash
# Claude Code UserPromptSubmit hook for caveman mode (auto-compress).
#
# Runs on every prompt the user submits. Reads a list of paths from
#   .caveman/auto-compress.paths
# (one absolute or repo-relative path per line, # for comments) and runs
# `understudy-compress` on each before the prompt reaches the model.
# Effect: prose-heavy markdown that the role file references stays
# small in the model's context.
#
# Installed by:  modules/caveman/bin/install-hooks install --mode compress
# Removed by:    modules/caveman/bin/install-hooks uninstall
#
# Safety:
# - Does nothing if the paths file is missing or empty.
# - Skips paths outside the current working directory (compressor
#   already enforces this; we double-check here so a hook never reaches
#   into another tree).
# - Compress failures are logged to stderr but never abort the prompt.

set -uo pipefail

PATHS_FILE=".caveman/auto-compress.paths"
COMPRESS_BIN="${CAVEMAN_COMPRESS_BIN:-understudy-compress}"

[[ -f "$PATHS_FILE" ]] || exit 0

# Resolve the compressor: prefer an absolute path injected at install time
# (via CAVEMAN_COMPRESS_BIN), else fall back to PATH lookup, else give up
# silently — this hook must never block the prompt.
if ! command -v "$COMPRESS_BIN" >/dev/null 2>&1; then
    echo "[caveman:hook] understudy-compress not found in PATH; skipping" >&2
    exit 0
fi

cwd="$(pwd)"
while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
    line="${raw_line%%#*}"          # strip comments
    line="${line#"${line%%[![:space:]]*}"}"   # ltrim
    line="${line%"${line##*[![:space:]]}"}"   # rtrim
    [[ -z "$line" ]] && continue

    # Resolve relative paths against the current working directory.
    if [[ "$line" = /* ]]; then
        target="$line"
    else
        target="${cwd}/${line}"
    fi

    # Defense in depth: refuse anything outside cwd.
    case "$target" in
        "${cwd}"/*) ;;
        *)
            echo "[caveman:hook] refusing path outside cwd: $line" >&2
            continue
            ;;
    esac

    [[ -f "$target" ]] || continue

    if ! "$COMPRESS_BIN" "$target" >/dev/null 2>&1; then
        echo "[caveman:hook] compress failed on: $line" >&2
    fi
done < "$PATHS_FILE"

exit 0
