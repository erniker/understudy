#!/usr/bin/env bash
# Caveman evals orchestrator. Runs both halves of the harness and writes
# modules/caveman/evals/RESULTS.md.
#
# Usage:  ./modules/caveman/evals/run.sh
#
# Optional dependency: tiktoken (Python). Without it, the harness uses a
# whitespace word-count fallback and labels its output accordingly.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${HERE}/../../.." && pwd)"

PY="${PYTHON:-python3}"
if ! command -v "${PY}" >/dev/null 2>&1; then
  PY="python"
fi
if ! command -v "${PY}" >/dev/null 2>&1; then
  echo "evals: no python3 / python on PATH" >&2
  exit 2
fi

cd "${ROOT}"
"${PY}" modules/caveman/evals/dogfood.py \
    --targets templates/docs \
    --label "\`templates/docs/\` — terse (tables, bullets)" \
    --marker-id DOGFOOD-TEMPLATES
echo
"${PY}" modules/caveman/evals/dogfood.py \
    --targets docs \
    --label "\`docs/\` — prose-heavy (project documentation)" \
    --marker-id DOGFOOD-DOCS
echo
"${PY}" modules/caveman/evals/three_arms.py
echo
echo "Done. See modules/caveman/evals/RESULTS.md"
