#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# 🛡️ Understudy Guardrails Check — Claude Code PreToolUse Hook
# ═══════════════════════════════════════════════════════════════
#
# Este hook se ejecuta ANTES de que Claude Code ejecute comandos
# en el shell. Bloquea operaciones destructivas que requieren
# confirmación explícita del PM.
#
# Salida:
#   exit 0 → permitir la operación
#   exit 2 → bloquear la operación (muestra mensaje en stderr)
#
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

TOOL_INPUT="${1:-}"

# Patrones de operaciones destructivas que requieren confirmación
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
        echo "🛡️ GUARDRAIL: Operación destructiva detectada: '$pattern'" >&2
        echo "   Esta operación requiere confirmación explícita del PM." >&2
        echo "   Describe qué vas a hacer, por qué, y el impacto antes de proceder." >&2
        exit 2
    fi
done

# Detectar acceso a archivos de secretos
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
        echo "🛡️ GUARDRAIL: Posible acceso a archivos sensibles detectado: '$pattern'" >&2
        echo "   Verifica que no estás exponiendo secretos o credenciales." >&2
        # Advertencia, no bloqueo — exit 0 para permitir pero alertar
        exit 0
    fi
done

exit 0
