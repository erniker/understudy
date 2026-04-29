#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# 🎭 Understudy — Test runner
# ═══════════════════════════════════════════════════════════════
# Usage:
#   ./run_tests.sh              → run all suites
#   ./run_tests.sh unit         → only unit tests
#   ./run_tests.sh hooks        → only hook tests
#   ./run_tests.sh integration  → only integration tests
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="${SCRIPT_DIR}/tests"

# ── Colors ────────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Dependency check ──────────────────────────────────────────
if ! command -v bats &>/dev/null; then
  echo -e "${RED}✖${NC}  bats not found. Install it first:"
  echo ""
  echo "    Linux:   sudo apt install bats"
  echo "    macOS:   brew install bats-core"
  echo "    Windows: use WSL or Git Bash + brew/apt"
  echo ""
  exit 1
fi

# Optional: python3 is not required by the bash test suite, but some
# opt-in tooling under tests/evals/ uses it. Warn early so any future
# test that depends on python3 can gate cleanly on this variable
# instead of failing with an opaque "command not found".
if ! command -v python3 &>/dev/null; then
  echo -e "${CYAN}ℹ${NC}  python3 not found; tests that require it will be skipped."
  echo ""
  export UNDERSTUDY_NO_PYTHON=1
fi

echo ""
echo -e "  ${BOLD}🎭 Understudy Test Suite${NC}"
echo -e "  bats $(bats --version 2>/dev/null | head -1)"
echo ""

SUITE="${1:-all}"
FAILED=0

run_suite() {
  local name="$1"
  local path="$2"

  echo -e "  ${CYAN}▸ ${name}${NC}"
  if bats "$path"; then
    echo -e "  ${GREEN}✔${NC}  ${name} passed"
  else
    echo -e "  ${RED}✖${NC}  ${name} FAILED"
    FAILED=1
  fi
  echo ""
}

case "$SUITE" in
  unit)
    run_suite "Unit tests" "${TESTS_DIR}/unit/"
    ;;
  hooks)
    run_suite "Hook tests" "${TESTS_DIR}/hooks/"
    ;;
  integration)
    run_suite "Integration tests" "${TESTS_DIR}/integration/"
    ;;
  all)
    run_suite "Unit tests"        "${TESTS_DIR}/unit/"
    run_suite "Hook tests"        "${TESTS_DIR}/hooks/"
    run_suite "Integration tests" "${TESTS_DIR}/integration/"
    ;;
  *)
    echo "Usage: $0 [unit|hooks|integration|all]"
    exit 1
    ;;
esac

if [[ "$FAILED" -eq 0 ]]; then
  echo -e "  ${GREEN}${BOLD}All tests passed.${NC}"
else
  echo -e "  ${RED}${BOLD}Some tests failed.${NC}"
  exit 1
fi
