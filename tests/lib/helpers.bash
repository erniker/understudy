# ── Shared helpers for all bats test suites ──────────────────────────────────
# Sourced automatically via bats setup() functions.

UNDERSTUDY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WIZARD="${UNDERSTUDY_ROOT}/wizard.sh"
FIXTURES="${UNDERSTUDY_ROOT}/tests/fixtures"

# Create an isolated temp directory per test and clean it up automatically.
setup_tmp() {
  TEST_TMP="$(mktemp -d)"
}

teardown_tmp() {
  [[ -n "${TEST_TMP:-}" && -d "$TEST_TMP" ]] && rm -rf "$TEST_TMP"
}

# Source only the pure functions from wizard.sh (no side-effects).
# We set up the variables the functions depend on so they can run standalone.
source_wizard_functions() {
  # Stub interactive functions so sourcing doesn't execute them
  banner()             { :; }
  ask()                { :; }
  confirm()            { return 0; }
  info()               { :; }
  success()            { :; }
  warn()               { :; }
  error()              { echo "$*" >&2; }
  step()               { :; }

  # Minimal required globals
  SCRIPT_DIR="$UNDERSTUDY_ROOT"
  TEMPLATES_DIR="${UNDERSTUDY_ROOT}/templates"
  ROLES_DIR="${UNDERSTUDY_ROOT}/roles"
  MODULES_DIR="${UNDERSTUDY_ROOT}/modules"
  DEFAULT_CONFIG="${UNDERSTUDY_ROOT}/understudy.yaml"

  MODEL_ARCHITECT="claude-opus-4.6"
  MODEL_BACKEND="claude-sonnet-4.5"
  MODEL_FRONTEND="claude-sonnet-4.5"
  MODEL_DEVOPS="claude-haiku-4.5"
  MODEL_SECURITY="claude-sonnet-4.5"
  MODEL_QA="claude-sonnet-4.5"

  APPLY_TO_ARCHITECT="docs/**"
  APPLY_TO_BACKEND="src/api/**"
  APPLY_TO_FRONTEND="**/*.tsx"
  APPLY_TO_DEVOPS="infra/**"
  APPLY_TO_SECURITY=""
  APPLY_TO_QA="tests/**"

  GUARDRAILS_MODE="split"
  PLATFORM_COPILOT=true
  PLATFORM_CLAUDE=true
  PLATFORM_CURSOR=true

  # Source only — no main() call
  # shellcheck source=../../wizard.sh
  source "$WIZARD"

  # Populate the module registry so tests can flip module inclusion via
  # `module_set_included <name> true|false` exactly the way main() does.
  discover_modules
}
