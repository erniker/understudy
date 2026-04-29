#!/usr/bin/env bash
# Caveman evals orchestrator. Runs both halves of the harness and writes
# tests/evals/RESULTS.md.
#
# Usage:  ./tests/evals/run.sh
#
# Optional dependency: tiktoken (Python). Without it, the harness uses a
# whitespace word-count fallback and labels its output accordingly.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${HERE}/../.." && pwd)"

PY="${PYTHON:-python3}"
if ! command -v "${PY}" >/dev/null 2>&1; then
  PY="python"
fi
if ! command -v "${PY}" >/dev/null 2>&1; then
  echo "evals: no python3 / python on PATH" >&2
  exit 2
fi

cd "${ROOT}"
"${PY}" tests/evals/dogfood.py \
    --targets templates/docs \
    --label "\`templates/docs/\` — terse (tables, bullets)" \
    --marker-id DOGFOOD-TEMPLATES
echo
"${PY}" tests/evals/dogfood.py \
    --targets docs \
    --label "\`docs/\` — prose-heavy (project documentation)" \
    --marker-id DOGFOOD-DOCS
echo
"${PY}" tests/evals/three_arms.py
echo
echo "Done. See tests/evals/RESULTS.md"
