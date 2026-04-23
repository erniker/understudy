#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# 🛡️ Understudy Guardrails Check — Claude Code PreToolUse Hook
# ═══════════════════════════════════════════════════════════════
#
# This hook runs BEFORE Claude Code executes shell commands.
# It blocks destructive operations that require
# explicit PM confirmation.
#
# Output:
#   exit 0 → allow the operation
#   exit 2 → block the operation (shows message in stderr)
#
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

TOOL_INPUT="${1:-}"

# Destructive operation patterns that require confirmation
DESTRUCTIVE_PATTERNS=(
    "rm -rf"
    "rm -r /"
    "rmdir"
    "terraform destroy"
    "kubectl delete"
    "docker system prune"
    "DROP TABLE"
    "DROP DATABASE"
    "TRUNCATE TABLE"
    "DELETE FROM"
    "git push --force"
    "git push -f"
    "git rebase"
    "force-push"
)

for pattern in "${DESTRUCTIVE_PATTERNS[@]}"; do
    if echo "$TOOL_INPUT" | grep -qi "$pattern"; then
        echo "🛡️ GUARDRAIL: Destructive operation detected: '$pattern'" >&2
        echo "   This operation requires explicit PM confirmation." >&2
        echo "   Describe what you are going to do, why, and the impact before proceeding." >&2
        exit 2
    fi
done

# Detect access to secret files
SECRET_PATTERNS=(
    "\.env"
    "\.key$"
    "\.pem$"
    "\.pfx$"
    "secrets/"
    "credentials"
    "password"
)

for pattern in "${SECRET_PATTERNS[@]}"; do
    if echo "$TOOL_INPUT" | grep -qi "$pattern"; then
        echo "🛡️ GUARDRAIL: Possible access to sensitive files detected: '$pattern'" >&2
        echo "   Verify that you are not exposing secrets or credentials." >&2
        # Warning, not blocking — exit 0 to allow but alert
        exit 0
    fi
done

exit 0
