#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# 🎭  UNDERSTUDY WIZARD — One AI, Every Role
# ═══════════════════════════════════════════════════════════════
#
# TUTORIAL: What does this wizard do?
#
#   This script deploys the Understudy system in any project.
#   It generates all the files Copilot CLI needs to
#   activate a complete team of specialized AI agents:
#
#   - AGENTS.md → team definition (selectable with /agent)
#   - .github/copilot-instructions.md → global instructions
#   - .github/instructions/*.instructions.md → per-role instructions
#   - docs/ → spec, decisions, session log templates
#
#   Usage:
#     understudy                     → Interactive deployment
#     understudy --here              → Deploy using inferred values
#     understudy --here --yes        → Same as --here, skip confirmation
#     understudy --add-member        → Add a team member
#     understudy --create-role       → Create a new custom role
#     understudy --all-roles         → Deploy the entire role catalog, not just the defaults
#     understudy --global            → Deploy a default team machine-wide (see docs/12-global-mode.md)
#     understudy --docs-only         → Create persistent per-repo memory only (pairs with --global)
#     understudy --uninstall         → Remove Understudy files from the current project
#     understudy --help              → Show help
#
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# ─── Configuration ──────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"
ROLES_DIR="${SCRIPT_DIR}/roles"
MODULES_DIR="${SCRIPT_DIR}/modules"
DEFAULT_CONFIG="${SCRIPT_DIR}/understudy.yaml"
UPDATE_REPO="erniker/understudy"
UPDATE_API_URL="https://api.github.com/repos/${UPDATE_REPO}/releases/latest"
UPDATE_INSTALL_URL="https://raw.githubusercontent.com/${UPDATE_REPO}/main/install.sh"

# ─── Config defaults (overridden by understudy.yaml) ───────
MODEL_ARCHITECT="claude-opus-4.6"
MODEL_BACKEND="claude-sonnet-4.5"
MODEL_FRONTEND="claude-sonnet-4.5"
MODEL_DEVOPS="claude-haiku-4.5"
MODEL_SECURITY="claude-sonnet-4.5"

APPLY_TO_ARCHITECT="docs/**"
APPLY_TO_BACKEND="src/api/**,src/application/**,src/domain/**,src/infrastructure/**"
APPLY_TO_FRONTEND="src/components/**,src/features/**,src/hooks/**,src/ui/**,**/*.tsx,**/*.jsx"
APPLY_TO_DEVOPS="infra/**,pipelines/**,docker/**,.github/workflows/**,**/*.tf"
APPLY_TO_SECURITY=""
APPLY_TO_QA="tests/**,**/*.test.*,**/*.spec.*,**/*Tests*/**"
MODEL_QA="claude-sonnet-4.5"

# Guardrails
GUARDRAILS_MODE="split"

# Plataformas
PLATFORM_COPILOT=true
PLATFORM_CLAUDE=true
PLATFORM_CURSOR=true

# Git integration
GIT_LOCAL_CONFIG=false   # gitignore AI config files (agents, instructions, hooks)
GIT_LOCAL_MEMORY=false   # gitignore session memory files (spec, decisions, session-log)

# Detection defaults (set properly when detect_existing_project runs)
DETECTED_STACK=""
DETECTED_REPO=""
DETECTED_DESC=""
DETECTED_COMPONENTS=()
DETECTED_HAS_SHELL=false

# CLI flags
DEPLOY_HERE=false        # --here: deploy in current directory using inferred values
AUTO_CONFIRM=false       # --yes/-y: skip confirmation prompts when used with --here
GLOBAL_MODE=false        # --global: deploy machine-wide instead of into a project
GLOBAL_UNINSTALL=false   # --global --uninstall: remove everything a global deploy wrote
ALL_ROLES=false          # --all-roles: deploy every role in the catalog, not just the defaults
DOCS_ONLY=false          # --docs-only: create per-repo persistent memory only (docs/ + understudy.yaml), no agent files

# Module registry — populated by discover_modules() from modules/<name>/module.yaml.
#
# Implemented as 5 parallel indexed arrays so the registry stays global even
# when wizard.sh is sourced from inside a function (e.g. the bats test
# helper). Plain `arr=()` at top level becomes global automatically; we
# avoid `declare -A` because macOS ships bash 4.0/4.1 (no `declare -g`)
# which would scope the arrays to the calling function instead.
#
#   MODULE_NAMES[i]    = module name (e.g. "caveman")
#   MODULE_FLAGS_[i]   = CLI flag for that module (e.g. "--caveman")
#   MODULE_INCLUDED[i] = "true" once the matching flag is parsed ("false" otherwise)
#   MODULE_TITLES[i]   = human-readable label for --help
#   MODULE_DESCS[i]    = one-line description for --help
MODULE_NAMES=()
MODULE_FLAGS_=()
MODULE_INCLUDED=()
MODULE_TITLES=()
MODULE_DESCS=()

# Post-install registry — populated alongside the module registry.
#
# A module declares optional post-install actions in a sidecar file
# `modules/<name>/post-install.flags` (tab-separated: flag, command,
# description). When the user passes the flag, the wizard runs the
# command (relative to the module dir) inside the deployment target
# after the normal deploy finishes. The command may include the literal
# token `{TARGET}` which is substituted with the absolute target path.
#
#   POSTINSTALL_MODULES[i] = owning module name
#   POSTINSTALL_FLAGS[i]   = CLI flag (e.g. "--caveman-hooks")
#   POSTINSTALL_CMDS[i]    = command line, relative to module directory
#   POSTINSTALL_DESCS[i]   = one-line description for --help
#   POSTINSTALL_REQUESTED[i] = "true" once the user passes the flag
POSTINSTALL_MODULES=()
POSTINSTALL_FLAGS=()
POSTINSTALL_CMDS=()
POSTINSTALL_DESCS=()
POSTINSTALL_REQUESTED=()

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Funciones de UI ─────────────────────────────────────────

# ─── Config parser ───────────────────────────────────────────
# Reads values from a simple YAML file (flat structure / 1 level of nesting).
# Uso: config_read "models" "architect" "default-value" "config-file"
config_read() {
    local section="$1"
    local key="$2"
    local default="$3"
    local file="${4:-$DEFAULT_CONFIG}"

    if [[ ! -f "$file" ]]; then
        echo "$default"
        return
    fi

    local value
    value=$(awk -v section="$section" -v key="$key" '
        BEGIN { in_section=0 }
        /^[a-z]/ { in_section=0 }
        $0 ~ "^"section":" { in_section=1; next }
        in_section && $0 ~ "^  "key":" {
            val=$0
            sub(/^[^:]+:[[:space:]]*/, "", val)
            gsub(/"/, "", val)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
            print val
            exit
        }
    ' "$file")

    echo "${value:-$default}"
}

# Reads system configuration, then project override if it exists
load_config() {
    local project_config="${TARGET_DIR:-}/understudy.yaml"

    # Capa 1: defaults del sistema (junto a wizard.sh)
    if [[ -f "$DEFAULT_CONFIG" ]]; then
        info "Reading global config: $(basename "$DEFAULT_CONFIG")"
        MODEL_ARCHITECT=$(config_read "models" "architect" "$MODEL_ARCHITECT" "$DEFAULT_CONFIG")
        MODEL_BACKEND=$(config_read "models" "backend" "$MODEL_BACKEND" "$DEFAULT_CONFIG")
        MODEL_FRONTEND=$(config_read "models" "frontend" "$MODEL_FRONTEND" "$DEFAULT_CONFIG")
        MODEL_DEVOPS=$(config_read "models" "devops" "$MODEL_DEVOPS" "$DEFAULT_CONFIG")
        MODEL_SECURITY=$(config_read "models" "security" "$MODEL_SECURITY" "$DEFAULT_CONFIG")
        MODEL_QA=$(config_read "models" "qa-engineer" "$MODEL_QA" "$DEFAULT_CONFIG")

        APPLY_TO_ARCHITECT=$(config_read "  architect" "apply_to" "$APPLY_TO_ARCHITECT" "$DEFAULT_CONFIG")
        APPLY_TO_BACKEND=$(config_read "  backend" "apply_to" "$APPLY_TO_BACKEND" "$DEFAULT_CONFIG")
        APPLY_TO_FRONTEND=$(config_read "  frontend" "apply_to" "$APPLY_TO_FRONTEND" "$DEFAULT_CONFIG")
        APPLY_TO_DEVOPS=$(config_read "  devops" "apply_to" "$APPLY_TO_DEVOPS" "$DEFAULT_CONFIG")
        APPLY_TO_SECURITY=$(config_read "  security" "apply_to" "$APPLY_TO_SECURITY" "$DEFAULT_CONFIG")
        APPLY_TO_QA=$(config_read "  qa-engineer" "apply_to" "$APPLY_TO_QA" "$DEFAULT_CONFIG")

        GUARDRAILS_MODE=$(config_read "guardrails" "mode" "$GUARDRAILS_MODE" "$DEFAULT_CONFIG")

        # Plataformas
        local val_copilot val_claude val_cursor
        val_copilot=$(config_read "platforms" "copilot" "true" "$DEFAULT_CONFIG")
        val_claude=$(config_read "platforms" "claude" "true" "$DEFAULT_CONFIG")
        val_cursor=$(config_read "platforms" "cursor" "true" "$DEFAULT_CONFIG")
        [[ "$val_copilot" == "false" ]] && PLATFORM_COPILOT=false
        [[ "$val_claude" == "false" ]] && PLATFORM_CLAUDE=false
        [[ "$val_cursor" == "false" ]] && PLATFORM_CURSOR=false

        # Git integration
        local val_local_config val_local_memory
        val_local_config=$(config_read "git" "local_config" "false" "$DEFAULT_CONFIG")
        val_local_memory=$(config_read "git" "local_memory" "false" "$DEFAULT_CONFIG")
        [[ "$val_local_config" == "true" ]] && GIT_LOCAL_CONFIG=true
        [[ "$val_local_memory" == "true" ]] && GIT_LOCAL_MEMORY=true
    fi

    # Capa 2: override del proyecto (si existe)
    if [[ -f "$project_config" ]]; then
        info "Project override found: $project_config"
        MODEL_ARCHITECT=$(config_read "models" "architect" "$MODEL_ARCHITECT" "$project_config")
        MODEL_BACKEND=$(config_read "models" "backend" "$MODEL_BACKEND" "$project_config")
        MODEL_FRONTEND=$(config_read "models" "frontend" "$MODEL_FRONTEND" "$project_config")
        MODEL_DEVOPS=$(config_read "models" "devops" "$MODEL_DEVOPS" "$project_config")
        MODEL_SECURITY=$(config_read "models" "security" "$MODEL_SECURITY" "$project_config")
        MODEL_QA=$(config_read "models" "qa-engineer" "$MODEL_QA" "$project_config")

        GUARDRAILS_MODE=$(config_read "guardrails" "mode" "$GUARDRAILS_MODE" "$project_config")

        # Override plataformas
        local val_copilot val_claude val_cursor
        val_copilot=$(config_read "platforms" "copilot" "$PLATFORM_COPILOT" "$project_config")
        val_claude=$(config_read "platforms" "claude" "$PLATFORM_CLAUDE" "$project_config")
        val_cursor=$(config_read "platforms" "cursor" "$PLATFORM_CURSOR" "$project_config")
        [[ "$val_copilot" == "false" ]] && PLATFORM_COPILOT=false || PLATFORM_COPILOT=true
        [[ "$val_claude" == "false" ]] && PLATFORM_CLAUDE=false || PLATFORM_CLAUDE=true
        [[ "$val_cursor" == "false" ]] && PLATFORM_CURSOR=false || PLATFORM_CURSOR=true

        # Override git integration
        local val_local_config val_local_memory
        val_local_config=$(config_read "git" "local_config" "false" "$project_config")
        val_local_memory=$(config_read "git" "local_memory" "false" "$project_config")
        [[ "$val_local_config" == "true" ]] && GIT_LOCAL_CONFIG=true || GIT_LOCAL_CONFIG=false
        [[ "$val_local_memory" == "true" ]] && GIT_LOCAL_MEMORY=true || GIT_LOCAL_MEMORY=false
    fi

    success "Configuration loaded — models: Arch=${MODEL_ARCHITECT}, Back=${MODEL_BACKEND}, Front=${MODEL_FRONTEND}, Ops=${MODEL_DEVOPS}, Sec=${MODEL_SECURITY}, QA=${MODEL_QA}"
    info "Guardrails: mode ${BOLD}${GUARDRAILS_MODE}${NC}"
    local platforms_str=""
    $PLATFORM_COPILOT && platforms_str+="Copilot "
    $PLATFORM_CLAUDE && platforms_str+="Claude "
    $PLATFORM_CURSOR && platforms_str+="Cursor "
    info "Platforms: ${BOLD}${platforms_str}${NC}"
}

# ─── Funciones de UI (original) ──────────────────────────────

banner() {
    echo ""
    echo -e "\033[38;5;51m  ██╗   ██╗ ███╗   ██╗ ██████╗  ███████╗ ██████╗  ███████╗ ████████╗ ██╗   ██╗ ██████╗  ██╗   ██╗"
    echo -e "\033[38;5;45m  ██║   ██║ ████╗  ██║ ██╔══██╗ ██╔════╝ ██╔══██╗ ██╔════╝ ╚══██╔══╝ ██║   ██║ ██╔══██╗ ╚██╗ ██╔╝"
    echo -e "\033[38;5;39m  ██║   ██║ ██╔██╗ ██║ ██║  ██║ █████╗   ██████╔╝ ███████╗    ██║    ██║   ██║ ██║  ██║  ╚████╔╝ "
    echo -e "\033[38;5;33m  ██║   ██║ ██║╚██╗██║ ██║  ██║ ██╔══╝   ██╔══██╗ ╚════██║    ██║    ██║   ██║ ██║  ██║   ╚██╔╝  "
    echo -e "\033[38;5;27m  ╚██████╔╝ ██║ ╚████║ ██████╔╝ ███████╗ ██║  ██║ ███████║    ██║    ╚██████╔╝ ██████╔╝    ██║   "
    echo -e "\033[38;5;63m   ╚═════╝  ╚═╝  ╚═══╝ ╚═════╝  ╚══════╝ ╚═╝  ╚═╝ ╚══════╝    ╚═╝     ╚═════╝  ╚═════╝     ╚═╝   "
    echo -e "${NC}"
    echo -e "  ${BOLD}🎭 One AI, Every Role${NC}                                              ${CYAN}Deployment Wizard${NC}"
    echo -e "  ${BLUE}Architect · Backend · Frontend · DevOps · Security · QA${NC}"
    echo -e "  ${CYAN}Copilot CLI · VS Code · Claude Code · Cursor${NC}"
    echo ""
}

info()    { echo -e "  ${BLUE}ℹ${NC}  $1"; }
success() { echo -e "  ${GREEN}✔${NC}  $1"; }
warn()    { echo -e "  ${YELLOW}⚠${NC}  $1"; }
error()   { echo -e "  ${RED}✖${NC}  $1"; }
step()    { echo -e "\n  ${CYAN}${BOLD}▸ $1${NC}"; }

to_lower() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

ask() {
    local prompt="$1"
    local var_name="$2"
    local default="${3:-}"

    if [[ -n "$default" ]]; then
        echo -ne "  ${YELLOW}?${NC}  ${prompt} ${CYAN}[${default}]${NC}: "
        read -r -e input
        eval "$var_name=\"${input:-$default}\""
    else
        echo -ne "  ${YELLOW}?${NC}  ${prompt}: "
        read -r -e input
        while [[ -z "$input" ]]; do
            echo -ne "  ${RED}!${NC}  This field is required: "
            read -r -e input
        done
        eval "$var_name=\"$input\""
    fi
}

# Prompt the user for a yes/no confirmation.
#
# Behavior:
# - Returns 0 only when the resolved answer is "y" / "yes" (case-insensitive).
# - Empty input or EOF falls back to the second argument (defaults to "Y" so
#   non-destructive prompts keep their previous "press Enter to accept"
#   semantics, including non-interactive runs that pipe input and let stdin
#   close after the last expected answer).
#
# For destructive prompts (update, delete, overwrite) callers should pass
# `"N"` as the second argument so that an unanswered prompt — including the
# case where the read silently fails because the script is wrapped in a
# non-interactive launcher — cannot trigger the destructive action.
confirm() {
    local prompt="$1"
    local default="${2:-Y}"
    local default_label="[Y/n]"
    [[ "$(to_lower "$default")" == "n" ]] && default_label="[y/N]"

    echo -ne "  ${YELLOW}?${NC}  ${prompt} ${CYAN}${default_label}${NC}: "

    local answer=""
    # On EOF `read` returns non-zero and leaves $answer empty; in either case
    # we let the default resolve the answer below.
    IFS= read -r answer || true
    answer="${answer:-$default}"
    [[ "$(to_lower "$answer")" == "y" || "$(to_lower "$answer")" == "yes" ]]
}

# ─── Version and update check ───────────────────────────────

read_local_version() {
    local changelog_file="${1:-${SCRIPT_DIR}/CHANGELOG.md}"
    [[ -f "$changelog_file" ]] || return 1

    awk -F'[][]' '
        /^## \[[0-9]+\.[0-9]+\.[0-9]+\]/ {
            print "v" $2
            exit
        }
    ' "$changelog_file"
}

fetch_latest_version() {
    command -v curl &>/dev/null || return 1

    curl -fsSL \
        --connect-timeout 2 \
        --max-time 4 \
        "$UPDATE_API_URL" \
        -H "Accept: application/vnd.github+json" \
        | awk -F'"' '/"tag_name"/ { print $4; exit }'
}

version_is_newer() {
    local latest="${1#v}"
    local current="${2#v}"
    latest="${latest%%-*}"
    current="${current%%-*}"

    local l1=0 l2=0 l3=0 c1=0 c2=0 c3=0
    IFS='.' read -r l1 l2 l3 <<< "$latest"
    IFS='.' read -r c1 c2 c3 <<< "$current"
    l1=${l1:-0}; l2=${l2:-0}; l3=${l3:-0}
    c1=${c1:-0}; c2=${c2:-0}; c3=${c3:-0}

    if (( l1 > c1 )); then return 0; fi
    if (( l1 < c1 )); then return 1; fi
    if (( l2 > c2 )); then return 0; fi
    if (( l2 < c2 )); then return 1; fi
    if (( l3 > c3 )); then return 0; fi
    return 1
}

check_for_updates() {
    [[ "${UNDERSTUDY_SKIP_UPDATE_CHECK:-0}" == "1" ]] && return 0

    # Skip in non-interactive runs and local development clones.
    [[ -t 0 ]] || return 0
    [[ -d "${SCRIPT_DIR}/.git" ]] && return 0

    local current_version latest_version
    current_version="$(read_local_version "${SCRIPT_DIR}/CHANGELOG.md" 2>/dev/null || true)"
    [[ -n "$current_version" ]] || return 0

    latest_version="$(fetch_latest_version 2>/dev/null || true)"
    [[ -n "$latest_version" ]] || return 0
    # Validate it looks like a semver tag (proxy/HTML responses would fail this)
    [[ "$latest_version" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+ ]] || return 0

    if version_is_newer "$latest_version" "$current_version"; then
        warn "New Understudy version available: ${latest_version} (current: ${current_version})"

        # Read the answer directly from the controlling terminal so that any
        # buffered input on stdin (caused by wrappers, here-docs, leftover
        # bytes from previous reads, etc.) cannot pre-answer this prompt.
        # The wizard explicitly waits here for the user to type y/N.
        local answer=""
        echo -ne "  ${YELLOW}?${NC}  Do you want to update now? ${CYAN}[y/N]${NC}: "
        if [[ -r /dev/tty ]]; then
            IFS= read -r answer < /dev/tty || answer=""
        else
            # No controlling terminal available — do not auto-update.
            echo ""
            warn "No interactive terminal detected; skipping update."
            return 0
        fi

        case "$(to_lower "${answer:-n}")" in
            y|yes)
                step "Updating Understudy"
                if curl -fsSL "$UPDATE_INSTALL_URL" | bash; then
                    success "Update completed. Restarting Understudy..."
                    exec "$0" "$@"
                else
                    warn "Update failed. Continuing with current version (${current_version})."
                fi
                ;;
            *)
                info "Continuing with the installed version (${current_version})."
                ;;
        esac
    fi

    return 0
}

# ─── Validations ────────────────────────────────────────────

validate_templates() {
    if [[ ! -d "$TEMPLATES_DIR" ]]; then
        error "Templates directory not found: $TEMPLATES_DIR"
        error "Make sure you run the wizard from its directory."
        exit 1
    fi

    # Shared templates (always required)
    local shared_files=(
        "docs/spec.md"
        "docs/decisions.md"
        "docs/session-log.md"
        "docs/team-roster.md"
    )

    for f in "${shared_files[@]}"; do
        if [[ ! -f "${TEMPLATES_DIR}/${f}" ]]; then
            error "Missing shared template: ${f}"
            exit 1
        fi
    done
    success "Shared templates validated"
}

validate_copilot_templates() {
    local copilot_files=(
        "AGENTS.md"
        ".github/copilot-instructions.md"
        ".github/instructions/architect.instructions.md"
        ".github/instructions/backend.instructions.md"
        ".github/instructions/frontend.instructions.md"
        ".github/instructions/devops.instructions.md"
        ".github/instructions/security.instructions.md"
        ".github/instructions/qa-engineer.instructions.md"
        ".github/instructions/guardrails.instructions.md"
    )

    for f in "${copilot_files[@]}"; do
        if [[ ! -f "${TEMPLATES_DIR}/${f}" ]]; then
            error "Missing Copilot template: ${f}"
            exit 1
        fi
    done
    success "Copilot templates validated"
}

validate_claude_templates() {
    local claude_files=(
        "CLAUDE.md"
        ".claude/agents/architect.md"
        ".claude/agents/backend.md"
        ".claude/agents/frontend.md"
        ".claude/agents/devops.md"
        ".claude/agents/security.md"
        ".claude/agents/qa.md"
        ".claude/commands/start-session.md"
        ".claude/commands/end-session.md"
        ".claude/commands/design-feature.md"
        ".claude/commands/security-review.md"
        ".claude/commands/understudy.md"
        ".claude/settings.json"
        ".claude/hooks/guardrails-check.sh"
    )

    for f in "${claude_files[@]}"; do
        if [[ ! -f "${TEMPLATES_DIR}/${f}" ]]; then
            error "Missing Claude template: ${f}"
            exit 1
        fi
    done
    success "Claude templates validated"
}

validate_cursor_templates() {
    local cursor_files=(
        ".cursor/agents/architect.md"
        ".cursor/agents/backend.md"
        ".cursor/agents/frontend.md"
        ".cursor/agents/devops.md"
        ".cursor/agents/security.md"
        ".cursor/agents/qa-engineer.md"
        ".cursor/commands/understudy.md"
        ".cursor/rules/understudy-global.mdc"
        ".cursor/rules/guardrails.mdc"
    )

    for f in "${cursor_files[@]}"; do
        if [[ ! -f "${TEMPLATES_DIR}/${f}" ]]; then
            error "Missing Cursor template: ${f}"
            exit 1
        fi
    done
    success "Cursor templates validated"
}

validate_global_templates() {
    local global_files=(
        "global/CLAUDE.md"
        "global/copilot-instructions.instructions.md"
        "global/cursor-user-rules.md"
        "global/commands/start-session.md"
        "global/commands/end-session.md"
        "global/commands/start-session.prompt.md"
        "global/commands/end-session.prompt.md"
        "global/commands/localize-project.md"
        "global/commands/localize-project.prompt.md"
    )

    for f in "${global_files[@]}"; do
        if [[ ! -f "${TEMPLATES_DIR}/${f}" ]]; then
            error "Missing global template: ${f}"
            exit 1
        fi
    done
    success "Global templates validated"
}

# ─── Existing project detection ─────────────────────────────

detect_existing_project() {
    local dir="$1"

    DETECTED_NAME=""
    DETECTED_DESC=""
    DETECTED_STACK=""
    DETECTED_REPO=""
    DETECTED_COMPONENTS=()
    DETECTED_HAS_SHELL=false
    EXISTING_MODE="directory"

    local is_project=false
    local dotnet_count=0
    local node_count=0
    local python_count=0
    local has_react=false
    local has_vue=false
    local has_angular=false
    local has_terraform=false
    local has_docker=false
    local has_shell=false

    # Already an Understudy project?
    if [[ -f "${dir}/AGENTS.md" ]] && [[ -d "${dir}/.github/instructions" ]]; then
        EXISTING_MODE="understudy"
        is_project=true
    elif [[ -f "${dir}/CLAUDE.md" ]] && [[ -d "${dir}/.claude/agents" ]]; then
        EXISTING_MODE="understudy"
        is_project=true
    elif [[ -d "${dir}/.cursor/agents" ]] && [[ -f "${dir}/.cursor/rules/understudy-global.mdc" ]]; then
        EXISTING_MODE="understudy"
        is_project=true
    fi

    # Git repo?
    if [[ -d "${dir}/.git" ]]; then
        DETECTED_REPO=$(git -C "$dir" remote get-url origin 2>/dev/null || echo "")
        is_project=true
    fi

    # Root package.json (project name/description)
    if [[ -f "${dir}/package.json" ]]; then
        DETECTED_NAME=$(awk -F'"' '/"name"[[:space:]]*:/{print $4; exit}' "${dir}/package.json" 2>/dev/null || echo "")
        DETECTED_DESC=$(awk -F'"' '/"description"[[:space:]]*:/{print $4; exit}' "${dir}/package.json" 2>/dev/null || echo "")
        is_project=true
    fi

    # Fallback: extract description from README.md (first paragraph after title)
    if [[ -z "$DETECTED_DESC" ]] && [[ -f "${dir}/README.md" ]]; then
        DETECTED_DESC=$(awk '
            BEGIN { found_title=0 }
            /^#[^#]/ && !found_title { found_title=1; next }
            found_title && NF==0 { next }
            found_title && /^[#>!`-]/ { next }
            found_title && /^[^[:space:]]/ {
                # Strip simple markdown emphasis and inline code; keep link text intact
                gsub(/\*\*/, "")
                gsub(/`/, "")
                print
                exit
            }
        ' "${dir}/README.md" 2>/dev/null | cut -c1-200)
    fi

    # ── .NET: scan for .csproj (depth 3) ──
    while IFS= read -r csproj; do
        [[ -z "$csproj" ]] && continue
        local proj_dir
        proj_dir=$(dirname "$csproj")
        local rel_path="${proj_dir#"$dir"/}"
        [[ "$proj_dir" == "$dir" ]] && rel_path="."
        local proj_name
        proj_name=$(basename "$csproj" .csproj)
        DETECTED_COMPONENTS+=(".NET: ${rel_path} (${proj_name})")
        dotnet_count=$((dotnet_count + 1))
        is_project=true
    done < <(find "$dir" -maxdepth 3 -name "*.csproj" -not -path "*/bin/*" -not -path "*/obj/*" 2>/dev/null)

    # .sln at root (only if no csproj found)
    if [[ $dotnet_count -eq 0 ]]; then
        while IFS= read -r sln; do
            [[ -z "$sln" ]] && continue
            local sln_name
            sln_name=$(basename "$sln")
            DETECTED_COMPONENTS+=(".NET solution: ${sln_name}")
            dotnet_count=$((dotnet_count + 1))
            is_project=true
        done < <(find "$dir" -maxdepth 2 -name "*.sln" 2>/dev/null)
    fi

    # ── Node.js: scan package.json in subdirs (depth 3) ──
    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        [[ "$pkg" == "${dir}/package.json" ]] && continue
        local pkg_dir
        pkg_dir=$(dirname "$pkg")
        local rel_path="${pkg_dir#"$dir"/}"

        if grep -q '"react"\|"next"' "$pkg" 2>/dev/null; then
            DETECTED_COMPONENTS+=("React: ${rel_path}")
            has_react=true
        elif grep -q '"vue"' "$pkg" 2>/dev/null; then
            DETECTED_COMPONENTS+=("Vue: ${rel_path}")
            has_vue=true
        elif grep -q '"@angular/core"' "$pkg" 2>/dev/null; then
            DETECTED_COMPONENTS+=("Angular: ${rel_path}")
            has_angular=true
        else
            DETECTED_COMPONENTS+=("Node.js: ${rel_path}")
        fi
        node_count=$((node_count + 1))
        is_project=true
    done < <(find "$dir" -maxdepth 3 -name "package.json" -not -path "*/node_modules/*" 2>/dev/null | sort)

    # Root package.json framework detection (if no sub-projects)
    if [[ -f "${dir}/package.json" ]] && [[ $node_count -eq 0 ]]; then
        if grep -q '"react"\|"next"' "${dir}/package.json" 2>/dev/null; then
            DETECTED_COMPONENTS+=("React: ./")
            has_react=true
        elif grep -q '"vue"' "${dir}/package.json" 2>/dev/null; then
            DETECTED_COMPONENTS+=("Vue: ./")
            has_vue=true
        elif grep -q '"@angular/core"' "${dir}/package.json" 2>/dev/null; then
            DETECTED_COMPONENTS+=("Angular: ./")
            has_angular=true
        else
            DETECTED_COMPONENTS+=("Node.js: ./")
        fi
        node_count=$((node_count + 1))
    fi

    # ── Python: scan for markers (depth 3) ──
    local python_paths_seen=()
    while IFS= read -r pyfile; do
        [[ -z "$pyfile" ]] && continue
        local py_dir
        py_dir=$(dirname "$pyfile")
        local rel_path="${py_dir#"$dir"/}"
        [[ "$py_dir" == "$dir" ]] && rel_path="."

        # Avoid duplicate paths
        local already=false
        for seen in "${python_paths_seen[@]:-}"; do
            [[ "$seen" == "$rel_path" ]] && already=true && break
        done
        if ! $already; then
            python_paths_seen+=("$rel_path")
            DETECTED_COMPONENTS+=("Python: ${rel_path}")
            python_count=$((python_count + 1))
            is_project=true
        fi
    done < <(find "$dir" -maxdepth 3 \( -name "requirements.txt" -o -name "pyproject.toml" -o -name "setup.py" -o -name "Pipfile" \) -not -path "*/venv/*" -not -path "*/.venv/*" 2>/dev/null | sort)

    # ── Terraform ──
    local tf_file
    tf_file=$(find "$dir" -maxdepth 3 -name "*.tf" -not -path "*/.terraform/*" 2>/dev/null | head -1)
    if [[ -n "$tf_file" ]]; then
        local tf_dir
        tf_dir=$(dirname "$tf_file")
        local rel_path="${tf_dir#"$dir"/}"
        [[ "$tf_dir" == "$dir" ]] && rel_path="."
        DETECTED_COMPONENTS+=("Terraform: ${rel_path}")
        has_terraform=true
        is_project=true
    fi

    # ── Docker ──
    local dockerfile_count
    dockerfile_count=$(find "$dir" -maxdepth 3 -name "Dockerfile" 2>/dev/null | wc -l)
    if [[ $dockerfile_count -gt 1 ]]; then
        DETECTED_COMPONENTS+=("Docker: ${dockerfile_count} Dockerfiles")
        has_docker=true
        is_project=true
    elif [[ $dockerfile_count -eq 1 ]]; then
        has_docker=true
        is_project=true
    fi
    if [[ -f "${dir}/docker-compose.yml" ]] || [[ -f "${dir}/docker-compose.yaml" ]]; then
        DETECTED_COMPONENTS+=("Docker Compose: ./")
        has_docker=true
        is_project=true
    fi

    # ── Shell scripting ──
    local shell_count
    shell_count=$(find "$dir" -maxdepth 3 \( -name "*.sh" -o -name "*.bash" -o -name "*.zsh" \) -not -path "*/.git/*" -not -path "*/node_modules/*" 2>/dev/null | wc -l)
    if [[ $shell_count -gt 0 ]]; then
        DETECTED_COMPONENTS+=("Shell scripting: ${shell_count} script(s)")
        has_shell=true
        is_project=true
    fi

    # ── Build DETECTED_STACK summary ──
    local stack_parts=()
    if [[ $dotnet_count -gt 1 ]]; then
        stack_parts+=(".NET(${dotnet_count})")
    elif [[ $dotnet_count -eq 1 ]]; then
        stack_parts+=(".NET")
    fi

    if [[ $node_count -gt 0 ]]; then
        local node_label="Node.js"
        $has_react && node_label="Node.js + React"
        $has_vue && node_label="Node.js + Vue"
        $has_angular && node_label="Node.js + Angular"
        [[ $node_count -gt 1 ]] && node_label="${node_label}(${node_count})"
        stack_parts+=("$node_label")
    fi

    if [[ $python_count -gt 1 ]]; then
        stack_parts+=("Python(${python_count})")
    elif [[ $python_count -eq 1 ]]; then
        stack_parts+=("Python")
    fi

    $has_terraform && stack_parts+=("Terraform")
    $has_docker && stack_parts+=("Docker")
    $has_shell && stack_parts+=("Shell")

    # Join with " + "
    local joined=""
    for part in "${stack_parts[@]:-}"; do
        if [[ -n "$joined" ]]; then
            joined="${joined} + ${part}"
        else
            joined="$part"
        fi
    done
    DETECTED_STACK="$joined"

    # Label as monorepo if multiple independent projects
    local total_projects=$((dotnet_count + node_count + python_count))
    if [[ $total_projects -gt 2 ]]; then
        DETECTED_STACK="Monorepo: ${DETECTED_STACK}"
    fi

    if $is_project && [[ "$EXISTING_MODE" != "understudy" ]]; then
        EXISTING_MODE="project"
    fi

    DETECTED_HAS_SHELL=$has_shell
}

# ─── Gather project information (--here mode) ───────────────
# Deploys Understudy in $PWD using fully inferred values.
# Asks at most one confirmation (skipped with --yes / -y).

_here_platforms_label() {
    local out=""
    $PLATFORM_COPILOT && out+="Copilot "
    $PLATFORM_CLAUDE && out+="Claude "
    $PLATFORM_CURSOR && out+="Cursor "
    [[ -z "$out" ]] && out="(none)"
    echo "${out% }"
}

_here_git_label() {
    local out=""
    $GIT_LOCAL_CONFIG && out+="AI config local "
    $GIT_LOCAL_MEMORY && out+="Session memory local "
    [[ -z "$out" ]] && out="committed (default)"
    echo "${out% }"
}

_here_print_summary() {
    info "Inferred settings:"
    info "  ${BOLD}1)${NC} Project name:    ${BOLD}${PROJECT_NAME}${NC}"
    if [[ -n "$PROJECT_DESCRIPTION" ]]; then
        info "  ${BOLD}2)${NC} Description:     ${PROJECT_DESCRIPTION}"
    else
        info "  ${BOLD}2)${NC} Description:     ${YELLOW}(none — add later in docs/spec.md)${NC}"
    fi
    info "  ${BOLD}3)${NC} Tech stack:      ${TECH_STACK}"
    info "  ${BOLD}4)${NC} Repository URL:  ${REPOSITORY_URL}"
    info "  ${BOLD}5)${NC} PM (your name):  ${TEAM_LEAD}"
    info "  ${BOLD}6)${NC} Guardrails mode: ${BOLD}${GUARDRAILS_MODE}${NC}"
    info "  ${BOLD}7)${NC} Platforms:       ${BOLD}$(_here_platforms_label)${NC}"
    info "  ${BOLD}8)${NC} AI config:       $($GIT_LOCAL_CONFIG && echo 'local only (gitignored)' || echo 'committed')"
    info "  ${BOLD}9)${NC} Session memory:  $($GIT_LOCAL_MEMORY && echo 'local only (gitignored)' || echo 'committed')"
    info "     Target dir:      ${TARGET_DIR}"
}

_here_edit_field() {
    local field="$1"
    local ans
    case "$field" in
        1)
            ask "Project name (no spaces)" PROJECT_NAME "$PROJECT_NAME"
            ;;
        2)
            ask "Short project description" PROJECT_DESCRIPTION "$PROJECT_DESCRIPTION"
            ;;
        3)
            ask "Main stack (e.g. .NET + React, Node.js + Vue)" TECH_STACK "$TECH_STACK"
            ;;
        4)
            ask "Repository URL (or 'local' if none)" REPOSITORY_URL "$REPOSITORY_URL"
            ;;
        5)
            ask "Your name (Project Manager)" TEAM_LEAD "$TEAM_LEAD"
            ;;
        6)
            ask "Guardrails mode [1=split, 2=embedded]" ans "$([[ $GUARDRAILS_MODE == embedded ]] && echo 2 || echo 1)"
            case "$ans" in
                2|embedded) GUARDRAILS_MODE="embedded" ;;
                *)          GUARDRAILS_MODE="split" ;;
            esac
            ;;
        7)
            local cur_c cur_cl cur_cu
            cur_c=$($PLATFORM_COPILOT && echo Y || echo N)
            cur_cl=$($PLATFORM_CLAUDE && echo Y || echo N)
            cur_cu=$($PLATFORM_CURSOR && echo Y || echo N)
            ask "Deploy for GitHub Copilot? [Y/n]" ans "$cur_c"
            case "$(to_lower "$ans")" in n|no) PLATFORM_COPILOT=false ;; *) PLATFORM_COPILOT=true ;; esac
            ask "Deploy for Claude Code? [Y/n]" ans "$cur_cl"
            case "$(to_lower "$ans")" in n|no) PLATFORM_CLAUDE=false ;; *) PLATFORM_CLAUDE=true ;; esac
            ask "Deploy for Cursor? [Y/n]" ans "$cur_cu"
            case "$(to_lower "$ans")" in n|no) PLATFORM_CURSOR=false ;; *) PLATFORM_CURSOR=true ;; esac
            if ! $PLATFORM_COPILOT && ! $PLATFORM_CLAUDE && ! $PLATFORM_CURSOR; then
                warn "At least one platform required — re-enabling Copilot."
                PLATFORM_COPILOT=true
            fi
            ;;
        8)
            ask "Keep AI config local only? (agents, instructions, hooks) [y/N]" ans \
                "$($GIT_LOCAL_CONFIG && echo Y || echo N)"
            case "$(to_lower "$ans")" in y|yes) GIT_LOCAL_CONFIG=true ;; *) GIT_LOCAL_CONFIG=false ;; esac
            ;;
        9)
            ask "Keep session memory local only? (spec.md, decisions.md, session-log.md) [y/N]" ans \
                "$($GIT_LOCAL_MEMORY && echo Y || echo N)"
            case "$(to_lower "$ans")" in y|yes) GIT_LOCAL_MEMORY=true ;; *) GIT_LOCAL_MEMORY=false ;; esac
            ;;
        *)
            warn "Invalid field: $field"
            ;;
    esac
}

_here_edit_loop() {
    local pick
    while true; do
        echo ""
        _here_print_summary
        echo ""
        ask "Field number to edit (1-9), or ${BOLD}d${NC} to deploy / ${BOLD}q${NC} to quit" pick "d"
        case "$(to_lower "$pick")" in
            d|deploy|y|yes) return 0 ;;
            q|quit|n|no)
                warn "Operation cancelled."
                exit 0
                ;;
            [1-9]) _here_edit_field "$pick" ;;
            *) warn "Enter 1-9, d (deploy) or q (quit)." ;;
        esac
    done
}

gather_project_info_here() {
    step "Deploy in current directory (--here)"
    echo ""

    TARGET_DIR="$PWD"
    BASE_DIR="$(dirname "$PWD")"

    detect_existing_project "$TARGET_DIR"

    PROJECT_NAME="${DETECTED_NAME:-$(basename "$PWD")}"
    PROJECT_DESCRIPTION="${DETECTED_DESC:-}"
    TECH_STACK="${DETECTED_STACK:-Unknown}"
    REPOSITORY_URL="${DETECTED_REPO:-local}"
    TEAM_LEAD="$(git config user.name 2>/dev/null || echo 'Project Lead')"

    # Sensible defaults for non-inferable choices
    GUARDRAILS_MODE="split"
    PLATFORM_COPILOT=true
    PLATFORM_CLAUDE=true
    PLATFORM_CURSOR=true
    GIT_LOCAL_CONFIG=false
    GIT_LOCAL_MEMORY=false
    PROJECT_DATE="$(date +%Y-%m-%d)"

    case "$EXISTING_MODE" in
        "understudy")
            INTEGRATION_MODE=true
            info "Understudy already deployed here — missing files will be added, existing files preserved."
            ;;
        "project")
            INTEGRATION_MODE=true
            info "Existing project detected — Understudy will be integrated without touching your files."
            ;;
        *)
            INTEGRATION_MODE=false
            info "Empty / fresh directory."
            ;;
    esac

    echo ""
    _here_print_summary
    echo ""

    if $AUTO_CONFIRM; then
        info "Auto-confirm enabled (--yes) — proceeding."
        return
    fi

    local ans
    ask "Deploy with these settings? [${BOLD}Y${NC}=yes / ${BOLD}n${NC}=cancel / ${BOLD}e${NC}=edit]" ans "Y"
    case "$(to_lower "$ans")" in
        n|no)
            warn "Operation cancelled. Run without --here for the interactive wizard."
            exit 0
            ;;
        e|edit)
            _here_edit_loop
            ;;
        *) ;;
    esac
}

# ─── Gather project information — global mode ───────────────
# Deploys machine-wide using `--global`. Mirrors the --here UX (numbered
# editable summary) but drops project-identity questions (name, description,
# tech stack, repo URL) since there is no single project at this scope.

_global_print_summary() {
    info "Global deployment settings:"
    info "  ${BOLD}1)${NC} Guardrails mode: ${BOLD}${GUARDRAILS_MODE}${NC}"
    info "  ${BOLD}2)${NC} Platforms:       ${BOLD}$(_here_platforms_label)${NC}"
    info "     Claude target:    $(global_claude_dir)"
    local vs_dirs
    vs_dirs="$(detect_vscode_user_dirs)"
    if [[ -n "$vs_dirs" ]]; then
        info "     VS Code profile(s):"
        while IFS= read -r d; do [[ -n "$d" ]] && info "       - ${d}"; done <<< "$vs_dirs"
    else
        info "     VS Code profile:  ${YELLOW}(none detected)${NC}"
    fi
    info "     Cursor:           manual paste block at $(global_state_dir)/cursor-user-rules.md"
}

_global_edit_field() {
    local field="$1"
    local ans
    case "$field" in
        1)
            ask "Guardrails mode [1=split, 2=embedded]" ans "$([[ $GUARDRAILS_MODE == embedded ]] && echo 2 || echo 1)"
            case "$ans" in
                2|embedded) GUARDRAILS_MODE="embedded" ;;
                *)          GUARDRAILS_MODE="split" ;;
            esac
            ;;
        2)
            local cur_c cur_cl cur_cu
            cur_c=$($PLATFORM_COPILOT && echo Y || echo N)
            cur_cl=$($PLATFORM_CLAUDE && echo Y || echo N)
            cur_cu=$($PLATFORM_CURSOR && echo Y || echo N)
            ask "Deploy for GitHub Copilot? [Y/n]" ans "$cur_c"
            case "$(to_lower "$ans")" in n|no) PLATFORM_COPILOT=false ;; *) PLATFORM_COPILOT=true ;; esac
            ask "Deploy for Claude Code? [Y/n]" ans "$cur_cl"
            case "$(to_lower "$ans")" in n|no) PLATFORM_CLAUDE=false ;; *) PLATFORM_CLAUDE=true ;; esac
            ask "Deploy for Cursor? [Y/n]" ans "$cur_cu"
            case "$(to_lower "$ans")" in n|no) PLATFORM_CURSOR=false ;; *) PLATFORM_CURSOR=true ;; esac
            if ! $PLATFORM_COPILOT && ! $PLATFORM_CLAUDE && ! $PLATFORM_CURSOR; then
                warn "At least one platform required — re-enabling Claude."
                PLATFORM_CLAUDE=true
            fi
            ;;
        *)
            warn "Invalid field: $field"
            ;;
    esac
}

_global_edit_loop() {
    local pick
    while true; do
        echo ""
        _global_print_summary
        echo ""
        ask "Field number to edit (1-2), or ${BOLD}d${NC} to deploy / ${BOLD}q${NC} to quit" pick "d"
        case "$(to_lower "$pick")" in
            d|deploy|y|yes) return 0 ;;
            q|quit|n|no)
                warn "Operation cancelled."
                exit 0
                ;;
            [1-2]) _global_edit_field "$pick" ;;
            *) warn "Enter 1-2, d (deploy) or q (quit)." ;;
        esac
    done
}

gather_project_info_global() {
    step "Deploy machine-wide (--global)"
    echo ""
    info "This seeds a default Understudy team for every project on this machine."
    info "Per-project customization (spec.md, models, apply_to overrides) is"
    info "untouched — run 'understudy --here' inside any repo to fully"
    info "customize it on top of the global team, exactly like today."
    echo ""

    GUARDRAILS_MODE="split"
    PLATFORM_COPILOT=true
    PLATFORM_CLAUDE=true
    PLATFORM_CURSOR=true

    # Generic values fed into the shared deploy_file substitution pipeline —
    # there is no single project at this scope, so these are illustrative.
    PROJECT_NAME="(this repository)"
    PROJECT_DESCRIPTION="(varies per repository)"
    TECH_STACK="(detected per repository)"
    REPOSITORY_URL="(varies per repository)"
    TEAM_LEAD="$(git config --global user.name 2>/dev/null || echo 'Project Lead')"
    PROJECT_DATE="$(date +%Y-%m-%d)"
    INTEGRATION_MODE=true

    echo ""
    _global_print_summary
    echo ""

    if $AUTO_CONFIRM; then
        info "Auto-confirm enabled (--yes) — proceeding."
        return
    fi

    local ans
    ask "Deploy with these settings? [${BOLD}Y${NC}=yes / ${BOLD}n${NC}=cancel / ${BOLD}e${NC}=edit]" ans "Y"
    case "$(to_lower "$ans")" in
        n|no)
            warn "Operation cancelled."
            exit 0
            ;;
        e|edit)
            _global_edit_loop
            ;;
        *) ;;
    esac
}

# ─── Gather project information ─────────────────────────────

gather_project_info() {
    if $DEPLOY_HERE; then
        gather_project_info_here
        return
    fi

    step "Spec-Driven Development — Project data"
    echo ""
    info "I need some data to deploy your team."
    echo ""

    ask "Project name (no spaces, e.g. customer-portal)" PROJECT_NAME

    # Show an OS-appropriate example path so users know the expected format.
    # Git Bash on Windows requires forward slashes (C:/Users/...) or /c/... notation.
    # Backslashes are processed by the terminal before bash sees them, so they cannot
    # be typed directly — users must use forward slashes or the /c/... Git Bash path.
    local _dir_hint
    case "$(uname -s)" in
        MINGW*|CYGWIN*|MSYS*)
            _dir_hint="e.g. C:/Users/you/Desktop or /c/Users/you/Desktop" ;;
        Darwin*)
            _dir_hint="e.g. /Users/you/projects" ;;
        *)
            _dir_hint="e.g. /home/you/projects" ;;
    esac
    ask "Base directory [${_dir_hint}]" BASE_DIR "."
    BASE_DIR=$(normalize_path "$BASE_DIR")
    TARGET_DIR="${BASE_DIR}/${PROJECT_NAME}"

    INTEGRATION_MODE=false

    # Detect existing project
    if [[ -d "$TARGET_DIR" ]]; then
        detect_existing_project "$TARGET_DIR"

        case "$EXISTING_MODE" in
            "understudy")
                echo ""
                warn "This project already has Understudy deployed."
                info "Existing files will be preserved."
                info "Only missing files will be added."
                echo ""
                if ! confirm "Continue and add missing files?"; then
                    warn "Operation cancelled."
                    exit 0
                fi
                INTEGRATION_MODE=true
                ;;
            "project")
                echo ""
                step "🔍 Existing project detected"
                echo ""
                [[ -n "$DETECTED_STACK" ]] && info "  Stack detected:    ${BOLD}${DETECTED_STACK}${NC}"
                [[ -n "$DETECTED_REPO" ]]  && info "  Repository:        ${DETECTED_REPO}"
                [[ -n "$DETECTED_DESC" ]]  && info "  Description:       ${DETECTED_DESC}"

                if [[ ${#DETECTED_COMPONENTS[@]} -gt 0 ]]; then
                    echo ""
                    info "  Components found:"
                    for comp in "${DETECTED_COMPONENTS[@]}"; do
                        echo -e "    ${CYAN}•${NC} ${comp}"
                    done
                fi

                echo ""
                info "Understudy will be integrated without touching existing files."
                echo ""
                if ! confirm "Integrate Understudy into this project?"; then
                    warn "Operation cancelled."
                    exit 0
                fi
                INTEGRATION_MODE=true
                ;;
            "directory")
                echo ""
                info "Directory ${TARGET_DIR} already exists."
                if ! confirm "Deploy Understudy in this directory?"; then
                    warn "Operation cancelled."
                    exit 0
                fi
                ;;
        esac
    fi

    echo ""
    ask "Short project description" PROJECT_DESCRIPTION "${DETECTED_DESC:-}"
    ask "Main stack (e.g. .NET + React, Node.js + Vue)" TECH_STACK "${DETECTED_STACK:-}"
    ask "Your name (Project Manager)" TEAM_LEAD "$(git config user.name 2>/dev/null || echo '')"
    ask "Repository URL (or 'local' if none)" REPOSITORY_URL "${DETECTED_REPO:-local}"

    echo ""
    step "Guardrails — Team protection"
    echo ""
    info "Guardrails are security and behavioral limits for all agents."
    echo ""
    echo -e "    ${CYAN}1)${NC} ${BOLD}split${NC} (recommended) — Critical always active + full details file"
    echo -e "    ${CYAN}2)${NC} ${BOLD}embedded${NC} — Only critical guardrails embedded (always active, lighter)"
    echo ""
    ask "Guardrails mode [1=split, 2=embedded]" GUARDRAILS_CHOICE "1"
    case "$GUARDRAILS_CHOICE" in
        2|embedded) GUARDRAILS_MODE="embedded" ;;
        *) GUARDRAILS_MODE="split" ;;
    esac

    echo ""
    step "Platforms — Where will you use Understudy?"
    echo ""
    info "Select the AI platforms where you want to deploy Understudy."
    echo ""

    local ans_copilot ans_claude ans_cursor
    ask "Deploy for GitHub Copilot? [Y/n]" ans_copilot "Y"
    case "$(to_lower "$ans_copilot")" in
        n|no) PLATFORM_COPILOT=false ;;
        *) PLATFORM_COPILOT=true ;;
    esac

    ask "Deploy for Claude Code? [Y/n]" ans_claude "Y"
    case "$(to_lower "$ans_claude")" in
        n|no) PLATFORM_CLAUDE=false ;;
        *) PLATFORM_CLAUDE=true ;;
    esac

    ask "Deploy for Cursor? [Y/n]" ans_cursor "Y"
    case "$(to_lower "$ans_cursor")" in
        n|no) PLATFORM_CURSOR=false ;;
        *) PLATFORM_CURSOR=true ;;
    esac

    if ! $PLATFORM_COPILOT && ! $PLATFORM_CLAUDE && ! $PLATFORM_CURSOR; then
        warn "You must select at least one platform."
        PLATFORM_COPILOT=true
        info "Copilot selected by default."
    fi

    echo ""
    step "Git integration — what to commit"
    echo ""
    info "By default all Understudy files are committed to the repo."
    info "You can keep them local so they never appear in git history."
    echo ""

    local ans_local_config ans_local_memory
    ask "Keep AI config local only? (agents, instructions, hooks) [y/N]" ans_local_config "N"
    case "$(to_lower "$ans_local_config")" in
        y|yes) GIT_LOCAL_CONFIG=true ;;
        *) GIT_LOCAL_CONFIG=false ;;
    esac

    ask "Keep session memory local only? (spec.md, decisions.md, session-log.md) [y/N]" ans_local_memory "N"
    case "$(to_lower "$ans_local_memory")" in
        y|yes) GIT_LOCAL_MEMORY=true ;;
        *) GIT_LOCAL_MEMORY=false ;;
    esac

    PROJECT_DATE="$(date +%Y-%m-%d)"

    echo ""
    step "Deployment summary"
    echo ""
    if $INTEGRATION_MODE; then
        info "Mode:         ${BOLD}🔄 INTEGRATION into existing project${NC}"
    else
        info "Mode:         ${BOLD}🆕 NEW PROJECT${NC}"
    fi
    info "Project:      ${BOLD}${PROJECT_NAME}${NC}"
    info "Description:  ${PROJECT_DESCRIPTION}"
    info "Stack:        ${TECH_STACK}"
    info "PM:           ${TEAM_LEAD}"
    info "Repository:   ${REPOSITORY_URL}"
    info "Guardrails:   ${BOLD}${GUARDRAILS_MODE}${NC}"
    local platforms_display=""
    $PLATFORM_COPILOT && platforms_display+="Copilot "
    $PLATFORM_CLAUDE && platforms_display+="Claude "
    $PLATFORM_CURSOR && platforms_display+="Cursor "
    info "Platforms:    ${BOLD}${platforms_display}${NC}"
    local git_display=""
    $GIT_LOCAL_CONFIG && git_display+="AI config "
    $GIT_LOCAL_MEMORY && git_display+="Session memory "
    [[ -z "$git_display" ]] && git_display="committed (default)"
    info "Local only:   ${BOLD}${git_display}${NC}"
    info "Target:       ${TARGET_DIR}"
    info "Date:         ${PROJECT_DATE}"
    echo ""

    if ! confirm "Deploy Understudy with these settings?"; then
        warn "Operation cancelled."
        exit 0
    fi
}

# ─── Generate critical guardrails block ──────────────────────
# Generates the compact guardrails content to embed in copilot-instructions.md
generate_guardrails_critical() {
    local mode="${1:-split}"
    local ref_line=""
    if [[ "$mode" == "split" ]]; then
        ref_line="For the full version with details and examples, see \`.github/instructions/guardrails.instructions.md\`."
    fi

    cat << GUARDRAILS_EOF
## 🛡️ Guardrails — Non-negotiable limits

All team agents MUST respect these guardrails at all times.
${ref_line}

### Security
- **NEVER** hardcode secrets, tokens, API keys or passwords in code, logs or config
- **ALWAYS** use vault services (Key Vault, Secrets Manager) for secrets
- **ALWAYS** validate and sanitize inputs at system boundaries
- **ALWAYS** apply the principle of least privilege
- If you detect an exposed secret → **STOP and alert the PM**

### Destructive operations
- **NEVER** delete files, cloud resources, data or revoke access without explicit PM confirmation
- Before destroying: explain what, why, impact and reversibility — wait for approval

### Data and PII
- **NEVER** include, process or repeat real customer or production data
- **NEVER** log sensitive data (tokens, passwords, PII)
- If you detect real data → **STOP immediately**, do not process or repeat it

### Environments
- **NEVER** make changes directly in production without an approved change request
- **ALWAYS** follow the promotion order: dev → test → acc → eng → prd
- **ALWAYS** use IaC and pipelines — never manual console changes

### Scope and process
- Each agent respects ownership of its areas (crossing boundaries requires justification)
- No code written without an approved spec (except bugfixes, emergencies, CVE, config)
- Propose a plan to the PM and wait for approval before executing significant changes
- Update \`docs/session-log.md\` at the end of each session

### Quality
- Self-review before presenting code
- Appropriate tests for new code (unit, integration, dry-run depending on type)
- No dead code, unused imports or TODOs in commits
- Explicit error handling with context — never silent failures
GUARDRAILS_EOF
}

# ─── Path normalization ──────────────────────────────────────
# Converts Windows-style paths to Unix/Git-Bash paths.
# Safe no-op on Linux and macOS (paths without ':' or '\' pass through unchanged).
#   C:\Users\foo\bar  →  /c/Users/foo/bar
#   C:/Users/foo      →  /c/Users/foo
#   /home/user/foo    →  /home/user/foo  (unchanged)
#   .                 →  .               (unchanged)
normalize_path() {
    local path="$1"
    if [[ "${path:1:1}" == ":" ]]; then
        local drive="${path:0:1}"
        path="/$(tr '[:upper:]' '[:lower:]' <<< "$drive")${path:2}"
    fi
    path=$(tr '\134' '/' <<< "$path")
    echo "$path"
}

# ─── Path -> clickable file:// URI ───────────────────────────
# Converts an absolute path into a file:// URI that most modern terminals
# (Windows Terminal, iTerm2, VS Code's integrated terminal, GNOME Terminal)
# auto-detect and render as a clickable link. Git-bash mount-style paths
# (/c/Users/...) are converted back to Windows drive notation
# (file:///C:/Users/...), since that's the form file:// URIs expect on
# Windows; Linux/macOS paths only need the scheme prepended.
path_to_file_uri() {
    local path="$1"
    if [[ "$(os_family)" == "windows" ]] && [[ "$path" =~ ^/([a-zA-Z])/(.*)$ ]]; then
        local drive="${BASH_REMATCH[1]}"
        local rest="${BASH_REMATCH[2]}"
        echo "file:///$(tr '[:lower:]' '[:upper:]' <<< "$drive"):/${rest}"
    else
        echo "file://${path}"
    fi
}

# ─── Global mode: cross-platform path resolution ────────────
# Helpers used only by `understudy --global` to resolve machine-wide targets.
# Kept separate from per-project deploy so the existing project flow is
# never touched by this logic.

os_family() {
    case "$(uname -s)" in
        MINGW*|CYGWIN*|MSYS*) echo "windows" ;;
        Darwin*)              echo "macos" ;;
        *)                    echo "linux" ;;
    esac
}

# Claude Code always resolves its user-level directory relative to $HOME,
# consistently across Linux/macOS/Windows (git-bash/WSL) — no OS branching
# needed here, unlike the VS Code profile lookup below.
global_claude_dir() {
    echo "${HOME}/.claude"
}

# Understudy's own global-deploy bookkeeping (deploy manifest + the Cursor
# paste-block). Deliberately NOT placed under ~/.understudy: install.sh runs
# `rm -rf "$INSTALL_DIR"` on every self-update, which would silently wipe
# this state since that directory is install payload, not deployed state.
global_state_dir() {
    echo "${HOME}/.understudy-global"
}

# Resolves VS Code user profile directories that could host global Copilot
# instructions/prompts. Echoes one absolute path per line (stable and/or
# Insiders, whichever exist); empty output means no VS Code profile found.
#
#   Linux:   ~/.config/Code[ - Insiders]/User
#   macOS:   ~/Library/Application Support/Code[ - Insiders]/User
#   Windows: %APPDATA%/Code[ - Insiders]/User
detect_vscode_user_dirs() {
    local base_stable base_insiders
    case "$(os_family)" in
        macos)
            base_stable="${HOME}/Library/Application Support/Code/User"
            base_insiders="${HOME}/Library/Application Support/Code - Insiders/User"
            ;;
        windows)
            local appdata
            appdata="$(normalize_path "${APPDATA:-${HOME}/AppData/Roaming}")"
            base_stable="${appdata}/Code/User"
            base_insiders="${appdata}/Code - Insiders/User"
            ;;
        *)
            base_stable="${HOME}/.config/Code/User"
            base_insiders="${HOME}/.config/Code - Insiders/User"
            ;;
    esac

    [[ -d "$base_stable" ]] && echo "$base_stable"
    [[ -d "$base_insiders" ]] && echo "$base_insiders"
    return 0
}

# Records a path written during a --global deploy so `--global --uninstall`
# can remove exactly what Understudy created — never a pre-existing file.
global_manifest_add() {
    local path="$1"
    local state_dir
    state_dir="$(global_state_dir)"
    mkdir -p "$state_dir"
    if [[ ! -f "${state_dir}/manifest" ]] || ! grep -qxF "$path" "${state_dir}/manifest" 2>/dev/null; then
        printf '%s\n' "$path" >> "${state_dir}/manifest"
    fi
}

# Wraps deploy_file() so global-mode deploys get manifest tracking for free,
# while preserving the exact same "skip if exists" safety as project mode
# (a file that already existed before this run is never recorded, so
# --uninstall can never remove something the user already had).
deploy_file_global() {
    local src="$1"
    local dst="$2"
    local existed=false
    [[ -f "$dst" ]] && existed=true

    deploy_file "$src" "$dst"

    $existed || global_manifest_add "$dst"
}

# ─── Global mode: ephemeral jq dependency ───────────────────
# Understudy never leaves new dependencies on the developer's machine: if jq
# is missing, install it long enough to safely patch VS Code's settings.json
# (JSONC — unsafe to hand-edit with sed/awk), then remove it again. Never
# attempted blindly under sudo in a non-interactive run.
JQ_INSTALLED_BY_UNDERSTUDY=false
JQ_PM_USED=""

_jq_pm_available() {
    command -v "$1" &>/dev/null
}

ensure_jq() {
    command -v jq &>/dev/null && return 0

    # Escape hatch for automated tests/CI — mirrors UNDERSTUDY_SKIP_UPDATE_CHECK.
    # Never attempt a real package-manager install when set.
    [[ "${UNDERSTUDY_SKIP_JQ_INSTALL:-0}" == "1" ]] && return 1

    if ! $AUTO_CONFIRM; then
        confirm "jq is required to safely edit VS Code's settings.json — install it temporarily?" "Y" || return 1
    fi

    local family
    family="$(os_family)"

    case "$family" in
        macos)
            if _jq_pm_available brew; then
                JQ_PM_USED="brew"
                brew install jq &>/dev/null && JQ_INSTALLED_BY_UNDERSTUDY=true
            fi
            ;;
        windows)
            if _jq_pm_available scoop; then
                JQ_PM_USED="scoop"
                scoop install jq &>/dev/null && JQ_INSTALLED_BY_UNDERSTUDY=true
            elif _jq_pm_available winget; then
                JQ_PM_USED="winget"
                winget install -e --id jqlang.jq --accept-source-agreements --accept-package-agreements &>/dev/null \
                    && JQ_INSTALLED_BY_UNDERSTUDY=true
            elif _jq_pm_available choco; then
                JQ_PM_USED="choco"
                choco install jq -y &>/dev/null && JQ_INSTALLED_BY_UNDERSTUDY=true
            fi
            ;;
        linux)
            # System package managers need sudo — only attempt with a
            # controlling terminal, mirroring the guard check_for_updates
            # already uses before touching stdin/tty. Never risk a blind
            # sudo password prompt in a non-interactive/--yes run.
            if [[ -t 0 ]]; then
                if _jq_pm_available apt-get; then
                    JQ_PM_USED="apt-get"
                    sudo apt-get install -y jq &>/dev/null && JQ_INSTALLED_BY_UNDERSTUDY=true
                elif _jq_pm_available dnf; then
                    JQ_PM_USED="dnf"
                    sudo dnf install -y jq &>/dev/null && JQ_INSTALLED_BY_UNDERSTUDY=true
                elif _jq_pm_available pacman; then
                    JQ_PM_USED="pacman"
                    sudo pacman -S --noconfirm jq &>/dev/null && JQ_INSTALLED_BY_UNDERSTUDY=true
                elif _jq_pm_available apk; then
                    JQ_PM_USED="apk"
                    sudo apk add jq &>/dev/null && JQ_INSTALLED_BY_UNDERSTUDY=true
                fi
            fi
            ;;
    esac

    # A package manager can report success (exit 0) without jq actually being
    # invokable yet (e.g. winget installing to a path not yet on this shell's
    # PATH). Trust the invocation, not the exit code, before proceeding.
    if $JQ_INSTALLED_BY_UNDERSTUDY && command -v jq &>/dev/null; then
        success "jq installed temporarily via ${JQ_PM_USED} (will be removed at the end of this run)"
        trap cleanup_jq EXIT
        return 0
    fi

    if $JQ_INSTALLED_BY_UNDERSTUDY; then
        # Installed but not yet usable in this shell — still attempt cleanup
        # so we don't claim to have left it behind on the machine, but don't
        # report success for the patch step.
        cleanup_jq
    fi

    warn "Could not install jq automatically — falling back to manual instructions for VS Code settings."
    return 1
}

cleanup_jq() {
    $JQ_INSTALLED_BY_UNDERSTUDY || return 0
    case "$JQ_PM_USED" in
        brew)    brew uninstall jq &>/dev/null ;;
        scoop)   scoop uninstall jq &>/dev/null ;;
        winget)  winget uninstall -e --id jqlang.jq &>/dev/null ;;
        choco)   choco uninstall jq -y &>/dev/null ;;
        apt-get) sudo apt-get remove -y jq &>/dev/null ;;
        dnf)     sudo dnf remove -y jq &>/dev/null ;;
        pacman)  sudo pacman -R --noconfirm jq &>/dev/null ;;
        apk)     sudo apk del jq &>/dev/null ;;
    esac
    JQ_INSTALLED_BY_UNDERSTUDY=false
    info "jq removed (temporary dependency cleaned up)"
}

# ─── Inject guardrails into copilot-instructions.md ─────────
# Replaces the block between GUARDRAILS_START and GUARDRAILS_END with the generated content
inject_guardrails_block() {
    local target_file="$1"
    local mode="$2"

    if [[ "$mode" == "embedded" ]] || [[ "$mode" == "split" ]]; then
        # Write content to a temp file — avoids passing multi-line strings via
        # awk -v, which macOS awk (One True AWK) does not support.
        local content_tmp
        content_tmp="$(mktemp)"
        generate_guardrails_critical "$mode" > "$content_tmp"

        # FNR==NR: first file (content_tmp) is loaded into lines[].
        # Second pass: replace the block between markers with those lines.
        awk '
            FNR == NR { lines[NR] = $0; max = NR; next }
            /<!-- GUARDRAILS_START -->/ {
                print
                for (i = 1; i <= max; i++) print lines[i]
                skip = 1
                next
            }
            /<!-- GUARDRAILS_END -->/ { skip = 0; print; next }
            !skip { print }
        ' "$content_tmp" "$target_file" > "${target_file}.tmp" \
            && mv "${target_file}.tmp" "$target_file"
        rm -f "$content_tmp"
        success "Critical guardrails embedded in copilot-instructions.md"
    else
        # Remove the marker block if no guardrails are wanted
        awk '
            /<!-- GUARDRAILS_START -->/ { skip=1; next }
            /<!-- GUARDRAILS_END -->/ { skip=0; next }
            !skip { print }
        ' "$target_file" > "${target_file}.tmp" && mv "${target_file}.tmp" "$target_file"
    fi
}

# ─── Deploy files ───────────────────────────────────────────

# Function to copy a template and replace placeholders
deploy_file() {
    local src="$1"
    local dst="$2"

    if [[ -f "$dst" ]]; then
        warn "File already exists, preserving: $(basename "$dst")"
        return
    fi

    cp "$src" "$dst"

    # Replace all placeholders in one pass.
    # Uses output redirection instead of sed -i to avoid BSD/GNU sed differences
    # (macOS sed requires `sed -i ''` with a space; GNU sed accepts `sed -i`).
    local tmp="${dst}.tmp"
    sed \
        -e "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" \
        -e "s|{{PROJECT_DESCRIPTION}}|${PROJECT_DESCRIPTION}|g" \
        -e "s|{{TECH_STACK}}|${TECH_STACK}|g" \
        -e "s|{{TEAM_LEAD}}|${TEAM_LEAD}|g" \
        -e "s|{{REPOSITORY_URL}}|${REPOSITORY_URL}|g" \
        -e "s|{{DATE}}|${PROJECT_DATE}|g" \
        -e "s|{{MODEL_ARCHITECT}}|${MODEL_ARCHITECT}|g" \
        -e "s|{{MODEL_BACKEND}}|${MODEL_BACKEND}|g" \
        -e "s|{{MODEL_FRONTEND}}|${MODEL_FRONTEND}|g" \
        -e "s|{{MODEL_DEVOPS}}|${MODEL_DEVOPS}|g" \
        -e "s|{{MODEL_SECURITY}}|${MODEL_SECURITY}|g" \
        -e "s|{{MODEL_QA}}|${MODEL_QA}|g" \
        -e "s|{{APPLY_TO_ARCHITECT}}|${APPLY_TO_ARCHITECT}|g" \
        -e "s|{{APPLY_TO_BACKEND}}|${APPLY_TO_BACKEND}|g" \
        -e "s|{{APPLY_TO_FRONTEND}}|${APPLY_TO_FRONTEND}|g" \
        -e "s|{{APPLY_TO_DEVOPS}}|${APPLY_TO_DEVOPS}|g" \
        -e "s|{{APPLY_TO_SECURITY}}|${APPLY_TO_SECURITY}|g" \
        -e "s|{{APPLY_TO_QA}}|${APPLY_TO_QA}|g" \
        "$dst" > "$tmp" && mv "$tmp" "$dst"

    success "$(basename "$dst")"
}

# ─── Deploy Copilot files ───────────────────────────────────

deploy_copilot() {
    step "Deploying Copilot files"

    mkdir -p "${TARGET_DIR}/.github/instructions"

    deploy_file "${TEMPLATES_DIR}/AGENTS.md" "${TARGET_DIR}/AGENTS.md"
    deploy_file "${TEMPLATES_DIR}/.github/copilot-instructions.md" "${TARGET_DIR}/.github/copilot-instructions.md"
    deploy_file "${TEMPLATES_DIR}/.github/instructions/architect.instructions.md" "${TARGET_DIR}/.github/instructions/architect.instructions.md"
    deploy_file "${TEMPLATES_DIR}/.github/instructions/backend.instructions.md" "${TARGET_DIR}/.github/instructions/backend.instructions.md"
    deploy_file "${TEMPLATES_DIR}/.github/instructions/frontend.instructions.md" "${TARGET_DIR}/.github/instructions/frontend.instructions.md"
    deploy_file "${TEMPLATES_DIR}/.github/instructions/devops.instructions.md" "${TARGET_DIR}/.github/instructions/devops.instructions.md"
    deploy_file "${TEMPLATES_DIR}/.github/instructions/security.instructions.md" "${TARGET_DIR}/.github/instructions/security.instructions.md"
    deploy_file "${TEMPLATES_DIR}/.github/instructions/qa-engineer.instructions.md" "${TARGET_DIR}/.github/instructions/qa-engineer.instructions.md"

    # Copilot Guardrails
    step "Deploying Copilot guardrails (mode: ${GUARDRAILS_MODE})"
    if [[ "$GUARDRAILS_MODE" == "split" ]]; then
        deploy_file "${TEMPLATES_DIR}/.github/instructions/guardrails.instructions.md" "${TARGET_DIR}/.github/instructions/guardrails.instructions.md"
    fi

    local copilot_instructions="${TARGET_DIR}/.github/copilot-instructions.md"
    if [[ -f "$copilot_instructions" ]]; then
        inject_guardrails_block "$copilot_instructions" "$GUARDRAILS_MODE"
    fi

    # Prompt files for VS Code
    step "Deploying prompt files (VS Code)"
    mkdir -p "${TARGET_DIR}/.github/prompts"
    for prompt_file in "${TEMPLATES_DIR}/.github/prompts/"*.prompt.md; do
        if [[ -f "$prompt_file" ]]; then
            deploy_file "$prompt_file" "${TARGET_DIR}/.github/prompts/$(basename "$prompt_file")"
        fi
    done
}

# ─── Deploy Claude Code files ───────────────────────────────

deploy_claude() {
    step "Deploying Claude Code files"

    mkdir -p "${TARGET_DIR}/.claude/agents"
    mkdir -p "${TARGET_DIR}/.claude/commands"
    mkdir -p "${TARGET_DIR}/.claude/hooks"

    # CLAUDE.md — global instructions
    deploy_file "${TEMPLATES_DIR}/CLAUDE.md" "${TARGET_DIR}/CLAUDE.md"

    # Agents
    for agent_file in "${TEMPLATES_DIR}/.claude/agents/"*.md; do
        if [[ -f "$agent_file" ]]; then
            deploy_file "$agent_file" "${TARGET_DIR}/.claude/agents/$(basename "$agent_file")"
        fi
    done

    # Commands
    for cmd_file in "${TEMPLATES_DIR}/.claude/commands/"*.md; do
        if [[ -f "$cmd_file" ]]; then
            deploy_file "$cmd_file" "${TARGET_DIR}/.claude/commands/$(basename "$cmd_file")"
        fi
    done

    # Settings and hooks
    deploy_file "${TEMPLATES_DIR}/.claude/settings.json" "${TARGET_DIR}/.claude/settings.json"
    deploy_file "${TEMPLATES_DIR}/.claude/hooks/guardrails-check.sh" "${TARGET_DIR}/.claude/hooks/guardrails-check.sh"
    chmod +x "${TARGET_DIR}/.claude/hooks/guardrails-check.sh" 2>/dev/null || true

    # Inject guardrails into CLAUDE.md
    step "Deploying Claude Code guardrails"
    local claude_md="${TARGET_DIR}/CLAUDE.md"
    if [[ -f "$claude_md" ]]; then
        inject_guardrails_block "$claude_md" "$GUARDRAILS_MODE"
    fi
}

# ─── Deploy Cursor files ──────────────────────────────────

deploy_cursor() {
    step "Deploying Cursor files"

    mkdir -p "${TARGET_DIR}/.cursor/agents"
    mkdir -p "${TARGET_DIR}/.cursor/commands"
    mkdir -p "${TARGET_DIR}/.cursor/rules"

    # Global rules
    deploy_file "${TEMPLATES_DIR}/.cursor/rules/understudy-global.mdc" "${TARGET_DIR}/.cursor/rules/understudy-global.mdc"

    # Agents
    for agent_file in "${TEMPLATES_DIR}/.cursor/agents/"*.md; do
        if [[ -f "$agent_file" ]]; then
            deploy_file "$agent_file" "${TARGET_DIR}/.cursor/agents/$(basename "$agent_file")"
        fi
    done

    # Commands
    for cmd_file in "${TEMPLATES_DIR}/.cursor/commands/"*.md; do
        if [[ -f "$cmd_file" ]]; then
            deploy_file "$cmd_file" "${TARGET_DIR}/.cursor/commands/$(basename "$cmd_file")"
        fi
    done

    # Inject guardrails into guardrails.mdc
    step "Deploying Cursor guardrails"
    deploy_file "${TEMPLATES_DIR}/.cursor/rules/guardrails.mdc" "${TARGET_DIR}/.cursor/rules/guardrails.mdc"
    local guardrails_mdc="${TARGET_DIR}/.cursor/rules/guardrails.mdc"
    if [[ -f "$guardrails_mdc" ]]; then
        inject_guardrails_block "$guardrails_mdc" "$GUARDRAILS_MODE"
    fi
}

# ─── Deploy files — global mode (`understudy --global`) ─────
# Machine-wide equivalents of deploy_claude/deploy_copilot/deploy_cursor.
# Fully additive: none of the functions above are touched, so
# `understudy` / `understudy --here` keep behaving exactly as before.

deploy_claude_global() {
    step "Deploying Claude Code files (global)"

    local target
    target="$(global_claude_dir)"

    mkdir -p "${target}/agents" "${target}/commands" "${target}/hooks"

    deploy_file_global "${TEMPLATES_DIR}/global/CLAUDE.md" "${target}/CLAUDE.md"

    for agent_file in "${TEMPLATES_DIR}/.claude/agents/"*.md; do
        [[ -f "$agent_file" ]] && deploy_file_global "$agent_file" "${target}/agents/$(basename "$agent_file")"
    done

    for cmd_file in "${TEMPLATES_DIR}/.claude/commands/"*.md; do
        [[ -f "$cmd_file" ]] || continue
        # start-session/end-session are replaced by the global-flavored
        # versions below — deploying the project ones first would win the
        # "skip if exists" race and leave the wrong (docs/-assuming) content.
        case "$(basename "$cmd_file")" in
            start-session.md|end-session.md) continue ;;
        esac
        deploy_file_global "$cmd_file" "${target}/commands/$(basename "$cmd_file")"
    done
    # Global-flavored session commands replace the project-only versions:
    # they check whether docs/ exists in the current repo instead of
    # assuming it unconditionally, and flag stale project metadata.
    deploy_file_global "${TEMPLATES_DIR}/global/commands/start-session.md" "${target}/commands/start-session.md"
    deploy_file_global "${TEMPLATES_DIR}/global/commands/end-session.md" "${target}/commands/end-session.md"
    deploy_file_global "${TEMPLATES_DIR}/global/commands/localize-project.md" "${target}/commands/localize-project.md"

    deploy_file_global "${TEMPLATES_DIR}/.claude/hooks/guardrails-check.sh" "${target}/hooks/guardrails-check.sh"
    chmod +x "${target}/hooks/guardrails-check.sh" 2>/dev/null || true

    # settings.json needs an ABSOLUTE hook path here: the hook runs with
    # cwd = whatever repo is open, not ~/.claude, so the project-relative
    # path used by deploy_claude() would not resolve.
    local settings_dst="${target}/settings.json"
    if [[ ! -f "$settings_dst" ]]; then
        sed "s|\.claude/hooks/guardrails-check.sh|${target}/hooks/guardrails-check.sh|" \
            "${TEMPLATES_DIR}/.claude/settings.json" > "$settings_dst"
        global_manifest_add "$settings_dst"
        success "settings.json (global, absolute hook path)"
    else
        warn "File already exists, preserving: settings.json"
    fi

    step "Deploying Claude Code guardrails (global)"
    local claude_md="${target}/CLAUDE.md"
    [[ -f "$claude_md" ]] && inject_guardrails_block "$claude_md" "$GUARDRAILS_MODE"
}

# Applies the two Copilot user-scope settings via jq (installed on demand,
# see ensure_jq). Backs up settings.json first so a failed merge is
# trivially reversible.
patch_vscode_settings() {
    local vs_dir="$1" inst_dir="$2" prompt_dir="$3"
    local settings="${vs_dir}/settings.json"

    [[ -f "$settings" ]] || echo '{}' > "$settings"
    cp "$settings" "${settings}.bak-understudy"

    if jq --arg i "$inst_dir" --arg p "$prompt_dir" \
        '.["chat.instructionsFilesLocations"] = ((.["chat.instructionsFilesLocations"] // {}) + {($i): true}) |
         .["chat.promptFilesLocations"]       = ((.["chat.promptFilesLocations"] // {}) + {($p): true})' \
        "$settings" > "${settings}.tmp-understudy"; then
        mv "${settings}.tmp-understudy" "$settings"
        success "VS Code settings.json updated: ${settings}"
    else
        rm -f "${settings}.tmp-understudy"
        warn "Could not patch ${settings} with jq — restoring backup."
        cp "${settings}.bak-understudy" "$settings"
        print_vscode_manual_instructions "$vs_dir" "$inst_dir" "$prompt_dir"
    fi
}

print_vscode_manual_instructions() {
    local vs_dir="$1" inst_dir="$2" prompt_dir="$3"
    warn "Manual step required for VS Code (${vs_dir}):"
    info "Add to User settings.json (Command Palette → \"Preferences: Open User Settings (JSON)\"):"
    echo "      \"chat.instructionsFilesLocations\": { \"${inst_dir}\": true },"
    echo "      \"chat.promptFilesLocations\": { \"${prompt_dir}\": true }"
}

deploy_copilot_global() {
    step "Deploying Copilot files (global)"

    local vscode_dirs
    vscode_dirs="$(detect_vscode_user_dirs)"

    if [[ -z "$vscode_dirs" ]]; then
        warn "No VS Code profile found (Code / Code - Insiders) — skipping Copilot global deploy."
        info "Install VS Code and re-run 'understudy --global' to enable it later."
        return
    fi

    local jq_available=false
    ensure_jq && jq_available=true

    local vs_dir
    while IFS= read -r vs_dir; do
        [[ -z "$vs_dir" ]] && continue
        local inst_dir="${vs_dir}/understudy/instructions"
        local prompt_dir="${vs_dir}/understudy/prompts"
        mkdir -p "$inst_dir" "$prompt_dir"

        deploy_file_global "${TEMPLATES_DIR}/global/copilot-instructions.instructions.md" "${inst_dir}/understudy-global.instructions.md"

        for role_file in architect backend frontend devops security qa-engineer; do
            deploy_file_global "${TEMPLATES_DIR}/.github/instructions/${role_file}.instructions.md" "${inst_dir}/${role_file}.instructions.md"
        done

        if [[ "$GUARDRAILS_MODE" == "split" ]]; then
            deploy_file_global "${TEMPLATES_DIR}/.github/instructions/guardrails.instructions.md" "${inst_dir}/guardrails.instructions.md"
        fi
        inject_guardrails_block "${inst_dir}/understudy-global.instructions.md" "$GUARDRAILS_MODE"

        for prompt_file in "${TEMPLATES_DIR}/.github/prompts/"*.prompt.md; do
            [[ -f "$prompt_file" ]] || continue
            # start-session/end-session are replaced by the global-flavored
            # versions below — the project ones assume docs/ unconditionally.
            case "$(basename "$prompt_file")" in
                start-session.prompt.md|end-session.prompt.md) continue ;;
            esac
            deploy_file_global "$prompt_file" "${prompt_dir}/$(basename "$prompt_file")"
        done
        deploy_file_global "${TEMPLATES_DIR}/global/commands/start-session.prompt.md" "${prompt_dir}/start-session.prompt.md"
        deploy_file_global "${TEMPLATES_DIR}/global/commands/end-session.prompt.md" "${prompt_dir}/end-session.prompt.md"
        deploy_file_global "${TEMPLATES_DIR}/global/commands/localize-project.prompt.md" "${prompt_dir}/localize-project.prompt.md"

        if $jq_available; then
            patch_vscode_settings "$vs_dir" "$inst_dir" "$prompt_dir"
        else
            print_vscode_manual_instructions "$vs_dir" "$inst_dir" "$prompt_dir"
        fi
    done <<< "$vscode_dirs"

    cleanup_jq
}

deploy_cursor_global() {
    step "Deploying Cursor global rules (manual paste required)"

    local state_dir dst
    state_dir="$(global_state_dir)"
    mkdir -p "$state_dir"
    dst="${state_dir}/cursor-user-rules.md"

    # This file only ever mirrors the current configuration (models,
    # guardrails mode, roster) — always regenerate rather than skip-if-exists,
    # unlike every other deploy_file_global call.
    rm -f "$dst"
    deploy_file_global "${TEMPLATES_DIR}/global/cursor-user-rules.md" "$dst"
    inject_guardrails_block "$dst" "$GUARDRAILS_MODE"

    warn "Cursor has no scriptable global-rules directory (platform limitation — see docs/12-global-mode.md)."
    info "One-time manual step:"
    info "  1. Open Cursor → Settings → Rules → User Rules"
    info "  2. Paste the contents of: ${dst}"
    info "     $(path_to_file_uri "$dst")"
    info "Re-run 'understudy --global' anytime to refresh this file after a config change."

    # Canonical per-role Cursor agent files. Cursor's Agent panel only reads
    # .cursor/agents/ inside a repo, so these aren't directly usable yet —
    # link_cursor_agents_into_project() (called by --docs-only) hard-links
    # them into each localized repo, giving Cursor real selectable per-role
    # agents backed by one shared source, instead of just the merged text
    # block above.
    local cursor_agents_dir="${state_dir}/cursor-agents"
    mkdir -p "$cursor_agents_dir"
    for agent_file in "${TEMPLATES_DIR}/.cursor/agents/"*.md; do
        [[ -f "$agent_file" ]] && deploy_file_global "$agent_file" "${cursor_agents_dir}/$(basename "$agent_file")"
    done
}

# ─── Global mode: shared per-role deploy helper ─────────────
# Used by both the default-optional-roles pass and --global --add-member so
# the Claude/Copilot writing logic for a single role lives in one place.
_deploy_role_globally() {
    local role_name="$1"
    local src="$2"

    if $PLATFORM_CLAUDE; then
        local claude_dir dst_claude
        claude_dir="$(global_claude_dir)"
        dst_claude="${claude_dir}/agents/${role_name}.md"
        if [[ -d "${claude_dir}/agents" ]] && [[ ! -f "$dst_claude" ]]; then
            cat > "$dst_claude" << EOF
---
name: ${role_name}
description: "Optional specialist role: ${role_name}"
model: ${MODEL_BACKEND}
tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
---

EOF
            cat "$src" >> "$dst_claude"
            global_manifest_add "$dst_claude"
            success "Optional role added globally (Claude): ${role_name}"
        fi
    fi

    if $PLATFORM_COPILOT; then
        local vs_dir
        while IFS= read -r vs_dir; do
            [[ -z "$vs_dir" ]] && continue
            local inst_dir="${vs_dir}/understudy/instructions"
            [[ -d "$inst_dir" ]] || continue
            local dst_copilot="${inst_dir}/${role_name}.instructions.md"
            if [[ ! -f "$dst_copilot" ]]; then
                cp "$src" "$dst_copilot"
                global_manifest_add "$dst_copilot"
                success "Optional role added globally (Copilot): ${role_name}"
            fi
        done <<< "$(detect_vscode_user_dirs)"
    fi

    if $PLATFORM_CURSOR; then
        local cursor_agents_dir dst_cursor
        cursor_agents_dir="$(global_state_dir)/cursor-agents"
        dst_cursor="${cursor_agents_dir}/${role_name}.md"
        if [[ -d "$cursor_agents_dir" ]] && [[ ! -f "$dst_cursor" ]]; then
            cat > "$dst_cursor" << EOF
---
name: ${role_name}
description: "Optional specialist role: ${role_name}"
model: ${MODEL_BACKEND}
---

EOF
            cat "$src" >> "$dst_cursor"
            global_manifest_add "$dst_cursor"
            success "Optional role added globally (Cursor canonical source): ${role_name}"
        fi
    fi
}

add_optional_role_to_project_global() {
    local role_name="$1"
    local src
    if ! src="$(module_role_source "$role_name")"; then
        warn "Optional role not found in catalog: ${role_name}"
        return
    fi
    _deploy_role_globally "$role_name" "$src"
}

deploy_default_optional_roles_global() {
    if $ALL_ROLES; then
        step "Deploying entire role catalog globally (--all-roles)"
        local role_file role_name
        for role_file in "${ROLES_DIR}"/*.instructions.md; do
            [[ -f "$role_file" ]] || continue
            role_name="$(basename "$role_file" .instructions.md)"
            add_optional_role_to_project_global "$role_name"
        done
    else
        # git-specialist / repo-documenter are useful in any repo — deployed by
        # default just like in project mode. shell-scripting is skipped here:
        # its auto-detection scans a single repo's files, which doesn't apply
        # at machine scope.
        add_optional_role_to_project_global "git-specialist"
        add_optional_role_to_project_global "repo-documenter"
    fi

    local i
    for i in "${!MODULE_NAMES[@]}"; do
        if [[ "${MODULE_INCLUDED[$i]}" == "true" ]]; then
            local mod_name="${MODULE_NAMES[$i]}"
            add_optional_role_to_project_global "$mod_name"
            info "Opt-in module (global): ${mod_name} (${MODULE_DESCS[$i]:-${MODULE_TITLES[$i]:-$mod_name}})"
        fi
    done
}

deploy_team_global() {
    step "Deploying global Understudy team"

    # Best-effort target for module post-install {TARGET} substitution
    # (see run_postinstall_actions) — there is no single project directory
    # in global mode, so ~/.claude is the closest sensible default.
    TARGET_DIR="$(global_claude_dir)"

    if $PLATFORM_CLAUDE; then
        deploy_claude_global
    fi
    if $PLATFORM_COPILOT; then
        deploy_copilot_global
    fi
    if $PLATFORM_CURSOR; then
        deploy_cursor_global
    fi

    deploy_default_optional_roles_global
}

# ─── Global mode: add member ─────────────────────────────────

add_team_member_global() {
    step "Add team member (global)"

    local claude_dir
    claude_dir="$(global_claude_dir)"
    if [[ ! -d "${claude_dir}/agents" ]] && [[ -z "$(detect_vscode_user_dirs)" ]]; then
        error "No global Understudy deployment found. Run 'understudy --global' first."
        exit 1
    fi

    if [[ ! -d "$ROLES_DIR" ]] || [[ -z "$(ls -A "$ROLES_DIR" 2>/dev/null)" ]]; then
        warn "No additional roles found in: $ROLES_DIR"
        return
    fi

    echo ""
    info "Available roles:"
    echo ""

    local roles=()
    local i=1
    for role_file in "${ROLES_DIR}"/*.instructions.md; do
        local role_name
        role_name="$(basename "$role_file" .instructions.md)"
        roles+=("$role_file")
        echo -e "    ${CYAN}${i})${NC} ${role_name}"
        i=$((i + 1))
    done
    echo ""

    ask "Select a number" selection
    local selected_file="${roles[$((selection - 1))]}"
    local selected_name
    selected_name="$(basename "$selected_file" .instructions.md)"

    PLATFORM_CLAUDE=true
    PLATFORM_COPILOT=true
    PLATFORM_CURSOR=true
    _deploy_role_globally "$selected_name" "$selected_file"

    info "Cursor: added to the canonical source — repos already localized with"
    info "'understudy --docs-only' will pick it up next time you re-run that"
    info "command there (existing files are never overwritten, so it's safe"
    info "to re-run). Also re-run 'understudy --global' to refresh the"
    info "consolidated User Rules paste block with the new role."
}

# ─── Global mode: uninstall ──────────────────────────────────

global_uninstall() {
    step "Uninstalling global Understudy deployment"

    local state_dir manifest_file
    state_dir="$(global_state_dir)"
    manifest_file="${state_dir}/manifest"

    if [[ ! -f "$manifest_file" ]]; then
        warn "No global deployment manifest found at ${manifest_file} — nothing to remove."
        return
    fi

    local path
    while IFS= read -r path; do
        [[ -z "$path" ]] && continue
        if [[ -f "$path" ]]; then
            rm -f "$path"
            success "Removed: $path"
        fi
    done < "$manifest_file"

    # Restore VS Code settings.json backups written by patch_vscode_settings.
    local vs_dir
    while IFS= read -r vs_dir; do
        [[ -z "$vs_dir" ]] && continue
        local bak="${vs_dir}/settings.json.bak-understudy"
        if [[ -f "$bak" ]]; then
            mv "$bak" "${vs_dir}/settings.json"
            success "Restored original settings.json: ${vs_dir}"
        fi
    done <<< "$(detect_vscode_user_dirs)"

    rm -f "$manifest_file"

    # Best-effort tidy-up of now-empty directories Understudy created.
    rmdir "${state_dir}" 2>/dev/null || true
    rmdir "$(global_claude_dir)/agents" "$(global_claude_dir)/commands" "$(global_claude_dir)/hooks" 2>/dev/null || true

    success "Global Understudy deployment removed."
}

# ─── Project uninstall (`understudy --uninstall`) ───────────
# Removes the well-known Understudy-owned paths from the current directory —
# the same list documented as the manual "full reset" procedure in
# docs/09-configuration.md, now automated. Unlike global_uninstall (which
# tracks a manifest of exactly what one --global run created), this removes
# anything Understudy could have deployed to a project, matching that
# documented reset scope. Your source code, package.json, CI workflows and
# any file outside this list are never touched.
project_uninstall() {
    step "Uninstall Understudy from this project"

    local target="$PWD"
    local paths=(
        "AGENTS.md"
        "CLAUDE.md"
        "understudy.yaml"
        ".github/instructions"
        ".github/prompts"
        ".github/copilot-instructions.md"
        ".claude"
        ".cursor/agents"
        ".cursor/commands"
        ".cursor/rules"
        "docs/spec.md"
        "docs/decisions.md"
        "docs/session-log.md"
        "docs/team-roster.md"
    )

    local existing=()
    local p
    for p in "${paths[@]}"; do
        [[ -e "${target}/${p}" ]] && existing+=("$p")
    done

    if [[ ${#existing[@]} -eq 0 ]]; then
        warn "No Understudy files found in ${target} — nothing to remove."
        return
    fi

    echo ""
    info "This will remove the following from ${BOLD}${target}${NC}:"
    for p in "${existing[@]}"; do
        echo -e "    ${CYAN}•${NC} ${p}"
    done
    echo ""

    if ! $AUTO_CONFIRM; then
        if ! confirm "Remove these Understudy files from this project?" "N"; then
            warn "Operation cancelled."
            return
        fi
    fi

    for p in "${existing[@]}"; do
        rm -rf "${target:?}/${p}"
        success "Removed: ${p}"
    done

    echo ""
    info "Your source code, package.json, CI workflows and any file not listed above were never touched."
}

# ─── Git integration: local-only mode ──────────────────────
# Appends Understudy-owned paths to the project's .gitignore when
# the user chose to keep AI config or session memory out of git.

deploy_gitignore() {
    if ! $GIT_LOCAL_CONFIG && ! $GIT_LOCAL_MEMORY; then
        return
    fi

    local gitignore="${TARGET_DIR}/.gitignore"

    # Idempotent: skip if Understudy block already present
    if [[ -f "$gitignore" ]] && grep -q "Understudy" "$gitignore"; then
        warn ".gitignore already has an Understudy block — skipping"
        return
    fi

    step "Configuring .gitignore (local-only mode)"

    {
        printf '\n# ── Understudy ────────────────────────────────────────────────\n'
    } >> "$gitignore"

    if $GIT_LOCAL_CONFIG; then
        {
            printf '# AI configuration — kept local, not committed to git\n'
            printf 'AGENTS.md\n'
            printf 'CLAUDE.md\n'
            printf 'understudy.yaml\n'
        } >> "$gitignore"

        if $PLATFORM_COPILOT; then
            {
                printf '.github/copilot-instructions.md\n'
                printf '.github/instructions/\n'
                printf '.github/prompts/\n'
            } >> "$gitignore"
        fi

        if $PLATFORM_CLAUDE; then
            printf '.claude/\n' >> "$gitignore"
        fi

        if $PLATFORM_CURSOR; then
            {
                printf '.cursor/agents/\n'
                printf '.cursor/commands/\n'
                printf '.cursor/rules/understudy-global.mdc\n'
                printf '.cursor/rules/guardrails.mdc\n'
            } >> "$gitignore"
        fi
    fi

    if $GIT_LOCAL_MEMORY; then
        {
            printf '# Session memory — kept local, not shared via git\n'
            printf 'docs/spec.md\n'
            printf 'docs/decisions.md\n'
            printf 'docs/session-log.md\n'
            printf 'docs/team-roster.md\n'
        } >> "$gitignore"
    fi

    success ".gitignore updated"
}

# ─── Optional roles automation ──────────────────────────────

# Discover opt-in modules under modules/<name>/module.yaml.
#
# The manifest is a flat YAML; we read only the four keys we care about with
# awk so we do not require yq/python at deploy time.
discover_modules() {
    [[ -d "$MODULES_DIR" ]] || return 0
    local manifest mname mflag mtitle mdesc
    # Reset registry on each call (idempotent).
    MODULE_NAMES=()
    MODULE_FLAGS_=()
    MODULE_INCLUDED=()
    MODULE_TITLES=()
    MODULE_DESCS=()
    for manifest in "$MODULES_DIR"/*/module.yaml; do
        [[ -f "$manifest" ]] || continue
        mname="$(awk -F': *'   '/^name: */    {gsub(/[" \r]/,"",$2); print $2; exit}' "$manifest")"
        mflag="$(awk -F': *'   '/^flag: */    {gsub(/[" \r]/,"",$2); print $2; exit}' "$manifest")"
        mtitle="$(awk -F': *'  '/^title: */   {sub(/^title: */,""); gsub(/^"|"$/,""); gsub(/\r/,""); print; exit}' "$manifest")"
        mdesc="$(awk -F': *'   '/^description: */ {sub(/^description: */,""); gsub(/^"|"$/,""); gsub(/\r/,""); print; exit}' "$manifest")"

        if [[ -z "$mname" || -z "$mflag" ]]; then
            warn "Module manifest missing name/flag: $manifest"
            continue
        fi

        MODULE_NAMES+=("$mname")
        MODULE_FLAGS_+=("$mflag")
        MODULE_INCLUDED+=("false")
        MODULE_TITLES+=("${mtitle:-$mname}")
        MODULE_DESCS+=("${mdesc:-}")

        # Optional post-install flags shipped by the module.
        local post_file="${MODULES_DIR}/${mname}/post-install.flags"
        if [[ -f "$post_file" ]]; then
            local pflag pcmd pdesc
            while IFS=$'\t' read -r pflag pcmd pdesc || [[ -n "$pflag" ]]; do
                # Skip blanks and comments.
                [[ -z "$pflag" || "$pflag" == \#* ]] && continue
                if [[ -z "$pcmd" ]]; then
                    warn "Module $mname: post-install line missing command: $pflag"
                    continue
                fi
                POSTINSTALL_MODULES+=("$mname")
                POSTINSTALL_FLAGS+=("$pflag")
                POSTINSTALL_CMDS+=("$pcmd")
                POSTINSTALL_DESCS+=("${pdesc:-}")
                POSTINSTALL_REQUESTED+=("false")
            done < "$post_file"
        fi
    done
}

# Lookup helpers around the parallel-arrays registry. They echo the index
# (0-based) of the matching module on stdout and return 0 on hit, 1 on miss.
module_index_by_name() {
    local i
    for i in "${!MODULE_NAMES[@]}"; do
        [[ "${MODULE_NAMES[$i]}" == "$1" ]] && { printf '%s\n' "$i"; return 0; }
    done
    return 1
}

module_index_by_flag() {
    local i
    for i in "${!MODULE_FLAGS_[@]}"; do
        [[ "${MODULE_FLAGS_[$i]}" == "$1" ]] && { printf '%s\n' "$i"; return 0; }
    done
    return 1
}

# Mark a module as included by name. Returns 1 if the module is unknown.
module_set_included() {
    local idx
    idx="$(module_index_by_name "$1")" || return 1
    MODULE_INCLUDED[idx]="$2"
}

# True when the module called "$1" is included.
module_is_included() {
    local idx
    idx="$(module_index_by_name "$1")" || return 1
    [[ "${MODULE_INCLUDED[$idx]}" == "true" ]]
}

# Look up a post-install entry by its CLI flag. Echoes the 0-based
# index on stdout, returns 1 if not found.
postinstall_index_by_flag() {
    local i
    for i in "${!POSTINSTALL_FLAGS[@]}"; do
        [[ "${POSTINSTALL_FLAGS[$i]}" == "$1" ]] && { printf '%s\n' "$i"; return 0; }
    done
    return 1
}

# Run every requested post-install command from the deployment target.
# Substitutes the literal token {TARGET} with the absolute target path.
# Each command is invoked through bash so simple multi-word command
# lines work without extra quoting in post-install.flags.
run_postinstall_actions() {
    local i mname cmd full_cmd module_dir
    for i in "${!POSTINSTALL_FLAGS[@]}"; do
        [[ "${POSTINSTALL_REQUESTED[$i]}" == "true" ]] || continue
        # Only run post-install actions for modules that were actually
        # included; otherwise we would wire hooks for assets that were
        # never deployed.
        mname="${POSTINSTALL_MODULES[$i]}"
        if ! module_is_included "$mname"; then
            warn "Skipping ${POSTINSTALL_FLAGS[$i]}: module '$mname' was not included (--$mname missing?)"
            continue
        fi
        module_dir="${MODULES_DIR}/${mname}"
        cmd="${POSTINSTALL_CMDS[$i]}"
        full_cmd="${cmd//\{TARGET\}/$TARGET_DIR}"
        info "Running post-install for $mname: ${POSTINSTALL_FLAGS[$i]}"
        ( cd "$module_dir" && bash -c "$full_cmd" ) || warn "Post-install command failed: $full_cmd"
    done
}

# Resolve the role source file for a given role name.
#
#   1. modules/<name>/role.instructions.md  (module-provided role)
#   2. roles/<name>.instructions.md         (built-in optional role)
#
# Echoes the absolute path on success, returns 1 on miss.
module_role_source() {
    local role_name="$1"
    local mod_src="${MODULES_DIR}/${role_name}/role.instructions.md"
    local cat_src="${ROLES_DIR}/${role_name}.instructions.md"
    if [[ -f "$mod_src" ]]; then
        echo "$mod_src"
        return 0
    fi
    if [[ -f "$cat_src" ]]; then
        echo "$cat_src"
        return 0
    fi
    return 1
}

add_optional_role_to_project() {
    local role_name="$1"

    local src
    if ! src="$(module_role_source "$role_name")"; then
        warn "Optional role not found in catalog: ${role_name}"
        return
    fi

    local roster_ref=""

    if $PLATFORM_COPILOT; then
        local dst_copilot="${TARGET_DIR}/.github/instructions/${role_name}.instructions.md"
        if [[ -f "$dst_copilot" ]]; then
            info "Optional role already present (Copilot): ${role_name}"
        else
            cp "$src" "$dst_copilot"
            success "Optional role added (Copilot): ${role_name}"
        fi
        [[ -z "$roster_ref" ]] && roster_ref=".github/instructions/${role_name}.instructions.md"
    fi

    if $PLATFORM_CLAUDE; then
        local dst_claude="${TARGET_DIR}/.claude/agents/${role_name}.md"
        if [[ -f "$dst_claude" ]]; then
            info "Optional role already present (Claude): ${role_name}"
        else
            cat > "$dst_claude" << EOF
---
name: ${role_name}
description: "Optional specialist role: ${role_name}"
model: ${MODEL_BACKEND}
tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
---

EOF
            cat "$src" >> "$dst_claude"
            success "Optional role added (Claude): ${role_name}"
        fi
        [[ -z "$roster_ref" ]] && roster_ref=".claude/agents/${role_name}.md"
    fi

    if $PLATFORM_CURSOR; then
        local dst_cursor="${TARGET_DIR}/.cursor/agents/${role_name}.md"
        if [[ -f "$dst_cursor" ]]; then
            info "Optional role already present (Cursor): ${role_name}"
        else
            cat > "$dst_cursor" << EOF
---
name: ${role_name}
description: "Optional specialist role: ${role_name}"
model: ${MODEL_BACKEND}
---

EOF
            cat "$src" >> "$dst_cursor"
            success "Optional role added (Cursor): ${role_name}"
        fi
        [[ -z "$roster_ref" ]] && roster_ref=".cursor/agents/${role_name}.md"
    fi

    # Keep team-roster in sync (idempotent)
    local roster="${TARGET_DIR}/docs/team-roster.md"
    if [[ -f "$roster" ]] && [[ -n "$roster_ref" ]] && ! grep -q "${role_name}" "$roster"; then
        local display_name
        display_name="$(echo "$role_name" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}')"
        local tmp_roster
        tmp_roster="$(mktemp)"
        sed "/<!-- new members here -->/a\\
| **${display_name}** | ${display_name} | \`${roster_ref}\` | ✅ Active |" "$roster" > "$tmp_roster" && mv "$tmp_roster" "$roster"
        success "team-roster.md updated (${role_name})"
    fi
}

deploy_default_optional_roles() {
    if $ALL_ROLES; then
        step "Deploying entire role catalog (--all-roles)"
        local role_file role_name
        for role_file in "${ROLES_DIR}"/*.instructions.md; do
            [[ -f "$role_file" ]] || continue
            role_name="$(basename "$role_file" .instructions.md)"
            add_optional_role_to_project "$role_name"
        done
    else
        # Always include repository workflow and documentation expertise by default.
        add_optional_role_to_project "git-specialist"
        add_optional_role_to_project "repo-documenter"

        # Auto-add shell scripting specialist on scripting-heavy repositories.
        local stack_lc
        stack_lc="$(to_lower "${TECH_STACK} ${DETECTED_STACK}")"
        if $DETECTED_HAS_SHELL || [[ "$stack_lc" == *"bash"* ]] || [[ "$stack_lc" == *"shell"* ]] || [[ "$stack_lc" == *"scripting"* ]]; then
            add_optional_role_to_project "shell-scripting"
            info "Auto-selected optional role: shell-scripting"
        fi
    fi

    # Opt-in modules (discovered from modules/<name>/module.yaml). Independent
    # of --all-roles: modules change agent behavior (e.g. caveman mode), not
    # just add a specialist, so they stay opt-in via their own flag.
    # Replaces the previous hard-coded `if $INCLUDE_CAVEMAN` branch:
    # adding/removing modules/<name>/ now toggles availability without
    # touching this file.
    local i
    for i in "${!MODULE_NAMES[@]}"; do
        if [[ "${MODULE_INCLUDED[$i]}" == "true" ]]; then
            local mod_name="${MODULE_NAMES[$i]}"
            add_optional_role_to_project "$mod_name"
            info "Opt-in module: ${mod_name} (${MODULE_DESCS[$i]:-${MODULE_TITLES[$i]:-$mod_name}})"
        fi
    done
}

# ─── Deployment orchestrator ───────────────────────────────

deploy_team() {
    step "Deploying project structure"

    # Create common directories
    mkdir -p "${TARGET_DIR}/docs"
    mkdir -p "${TARGET_DIR}/src"
    mkdir -p "${TARGET_DIR}/tests"
    mkdir -p "${TARGET_DIR}/scripts"
    success "Common directories created"

    # Deploy per platform
    if $PLATFORM_COPILOT; then
        deploy_copilot
    fi

    if $PLATFORM_CLAUDE; then
        deploy_claude
    fi

    if $PLATFORM_CURSOR; then
        deploy_cursor
    fi

    # Shared docs
    step "Deploying shared documentation"
    deploy_file "${TEMPLATES_DIR}/docs/spec.md" "${TARGET_DIR}/docs/spec.md"
    deploy_file "${TEMPLATES_DIR}/docs/decisions.md" "${TARGET_DIR}/docs/decisions.md"
    deploy_file "${TEMPLATES_DIR}/docs/session-log.md" "${TARGET_DIR}/docs/session-log.md"
    deploy_file "${TEMPLATES_DIR}/docs/team-roster.md" "${TARGET_DIR}/docs/team-roster.md"

    # Optional roles defaults and auto-detection
    deploy_default_optional_roles

    # Copy config to project for local override
    if [[ -f "$DEFAULT_CONFIG" ]] && [[ ! -f "${TARGET_DIR}/understudy.yaml" ]]; then
        cp "$DEFAULT_CONFIG" "${TARGET_DIR}/understudy.yaml"
        success "understudy.yaml (edit it to override per-project settings)"
    fi

    # Gitignore for local-only mode
    deploy_gitignore

    # Initialize git if not present
    if [[ ! -d "${TARGET_DIR}/.git" ]]; then
        if confirm "Initialize git repository?"; then
            git -C "${TARGET_DIR}" init --quiet
            success "Git repository initialized"
        fi
    else
        info "Git repository already exists"
    fi
}

# ─── Docs-only mode (`understudy --docs-only`) ──────────────
# For repos that already get their agents from a --global install: creates
# just the persistent per-repo memory (docs/spec.md, decisions.md,
# session-log.md, team-roster.md) and a project-level understudy.yaml,
# without deploying any per-platform agent files. Complements --global —
# use `understudy --here` instead if you want full per-project agent
# customization on top of this.
# Cursor has no global agents directory — its Agent panel only reads
# .cursor/agents/ inside a repo. So each repo still needs files there, but
# instead of copying content (which drifts), hard-link each one to the
# single canonical source under ~/.understudy-global/cursor-agents/
# (populated by deploy_cursor_global / _deploy_role_globally): editing
# either side updates both, with zero duplication or staleness. Falls back
# to a plain copy when hard links aren't possible — they require both paths
# on the same filesystem, so a repo on a different drive than the global
# source would fail a hard link attempt.
link_cursor_agents_into_project() {
    local target_dir="$1"
    local cursor_agents_dir
    cursor_agents_dir="$(global_state_dir)/cursor-agents"

    # Nothing to link if Cursor wasn't part of the --global deploy.
    [[ -d "$cursor_agents_dir" ]] || return 0

    mkdir -p "${target_dir}/.cursor/agents"

    local src role_file dst
    for src in "${cursor_agents_dir}"/*.md; do
        [[ -f "$src" ]] || continue
        role_file="$(basename "$src")"
        dst="${target_dir}/.cursor/agents/${role_file}"
        [[ -f "$dst" ]] && continue

        if ln "$src" "$dst" 2>/dev/null; then
            success "Linked Cursor agent (shared with global, edits sync both ways): ${role_file}"
        else
            cp "$src" "$dst"
            warn "Copied Cursor agent ${role_file} (hard link unavailable — likely a different drive). Re-run to refresh if the global copy changes."
        fi
    done
}

deploy_docs_only() {
    step "Creating persistent project memory (docs-only)"

    if [[ ! -f "${TEMPLATES_DIR}/global/docs/team-roster.md" ]]; then
        error "Missing template: global/docs/team-roster.md"
        exit 1
    fi

    TARGET_DIR="$PWD"
    detect_existing_project "$TARGET_DIR"

    PROJECT_NAME="${DETECTED_NAME:-$(basename "$PWD")}"
    PROJECT_DESCRIPTION="${DETECTED_DESC:-}"
    TECH_STACK="${DETECTED_STACK:-Unknown}"
    REPOSITORY_URL="${DETECTED_REPO:-local}"
    TEAM_LEAD="$(git config user.name 2>/dev/null || echo 'Project Lead')"
    PROJECT_DATE="$(date +%Y-%m-%d)"

    echo ""
    info "Target:       ${BOLD}${TARGET_DIR}${NC}"
    info "Project name: ${PROJECT_NAME}"
    info "Stack:        ${TECH_STACK}"
    info "This creates docs/{spec,decisions,session-log,team-roster}.md,"
    info "understudy.yaml, and (Cursor only) hard-linked agent files that"
    info "share content with the global install — no other agent files are"
    info "deployed or touched."
    echo ""

    if ! $AUTO_CONFIRM; then
        if ! confirm "Create persistent project memory here?" "Y"; then
            warn "Operation cancelled."
            return
        fi
    fi

    mkdir -p "${TARGET_DIR}/docs"

    deploy_file "${TEMPLATES_DIR}/docs/spec.md" "${TARGET_DIR}/docs/spec.md"
    deploy_file "${TEMPLATES_DIR}/docs/decisions.md" "${TARGET_DIR}/docs/decisions.md"
    deploy_file "${TEMPLATES_DIR}/docs/session-log.md" "${TARGET_DIR}/docs/session-log.md"
    deploy_file "${TEMPLATES_DIR}/global/docs/team-roster.md" "${TARGET_DIR}/docs/team-roster.md"

    if [[ -f "$DEFAULT_CONFIG" ]] && [[ ! -f "${TARGET_DIR}/understudy.yaml" ]]; then
        cp "$DEFAULT_CONFIG" "${TARGET_DIR}/understudy.yaml"
        success "understudy.yaml (edit it to override per-project settings)"
    fi

    # There is no stored record of which platforms a prior --global run
    # selected, so infer it from what actually exists on disk — the same
    # signal link_cursor_agents_into_project already relies on for Cursor.
    PLATFORM_CLAUDE=false
    [[ -d "$(global_claude_dir)/agents" ]] && PLATFORM_CLAUDE=true
    PLATFORM_COPILOT=false
    [[ -n "$(detect_vscode_user_dirs)" ]] && PLATFORM_COPILOT=true
    PLATFORM_CURSOR=false
    [[ -d "$(global_state_dir)/cursor-agents" ]] && PLATFORM_CURSOR=true

    # Mirrors the auto-detection deploy_default_optional_roles() does for
    # project mode: a scripting-heavy repo gets the shell-scripting role
    # without having to ask for it via --all-roles or --add-member. Adding
    # it globally (not just to this repo) means every other repo you open
    # gets it too, and it's a no-op if it already exists.
    local stack_lc
    stack_lc="$(to_lower "${TECH_STACK} ${DETECTED_STACK}")"
    if $DETECTED_HAS_SHELL || [[ "$stack_lc" == *"bash"* ]] || [[ "$stack_lc" == *"shell"* ]] || [[ "$stack_lc" == *"scripting"* ]]; then
        info "Detected shell scripts in this repo — adding shell-scripting role globally"
        add_optional_role_to_project_global "shell-scripting"
    fi

    link_cursor_agents_into_project "$TARGET_DIR"

    echo ""
    success "Persistent project memory created for ${TARGET_DIR}."
    info "Claude/Copilot agents remain purely global (~/.claude/, VS Code profile)."
    info "Cursor agents (if any were linked above) are shared with the global"
    info "install via hard link — no drift, no need to re-sync."
    info "Run 'understudy --here' anytime later for full per-project agent"
    info "customization (different models per role, apply_to scoping, etc.)"
    info "on top of what was just created — nothing here would be lost."
}

# ─── Add team member ────────────────────────────────────────

add_team_member() {
    step "Add team member"

    # List available roles in /roles
    if [[ ! -d "$ROLES_DIR" ]] || [[ -z "$(ls -A "$ROLES_DIR" 2>/dev/null)" ]]; then
        warn "No additional roles found in: $ROLES_DIR"
        info "You can create one manually in that folder."
        echo ""
        if confirm "Do you want to create a new role from scratch?"; then
            create_custom_role
        fi
        return
    fi

    echo ""
    info "Available roles:"
    echo ""

    local roles=()
    local i=1
    for role_file in "${ROLES_DIR}"/*.instructions.md; do
        local role_name
        role_name="$(basename "$role_file" .instructions.md)"
        roles+=("$role_file")
        echo -e "    ${CYAN}${i})${NC} ${role_name}"
        i=$((i + 1))
    done
    echo -e "    ${CYAN}${i})${NC} Create custom role"
    echo ""

    ask "Select a number" selection
    if [[ "$selection" -eq "$i" ]]; then
        create_custom_role
        return
    fi

    local selected_file="${roles[$((selection - 1))]}"
    local selected_name
    selected_name="$(basename "$selected_file" .instructions.md)"

    ask "Project directory where to add the member" TARGET_DIR

    local has_copilot=false has_claude=false has_cursor=false
    [[ -d "${TARGET_DIR}/.github/instructions" ]] && has_copilot=true
    [[ -d "${TARGET_DIR}/.claude/agents" ]] && has_claude=true
    [[ -d "${TARGET_DIR}/.cursor/agents" ]] && has_cursor=true

    if ! $has_copilot && ! $has_claude && ! $has_cursor; then
        error "This does not look like an Understudy project. Run the wizard first."
        exit 1
    fi

    local copied_any=false
    local roster_ref=""

    if $has_copilot; then
        local dest_copilot="${TARGET_DIR}/.github/instructions/${selected_name}.instructions.md"
        if [[ ! -f "$dest_copilot" ]]; then
            cp "$selected_file" "$dest_copilot"
            copied_any=true
            [[ -z "$roster_ref" ]] && roster_ref=".github/instructions/${selected_name}.instructions.md"
        fi
    fi

    if $has_claude; then
        local dest_claude="${TARGET_DIR}/.claude/agents/${selected_name}.md"
        if [[ ! -f "$dest_claude" ]]; then
            cat > "$dest_claude" << EOF
---
name: ${selected_name}
description: "Optional specialist role: ${selected_name}"
model: ${MODEL_BACKEND}
tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
---

EOF
            cat "$selected_file" >> "$dest_claude"
            copied_any=true
            [[ -z "$roster_ref" ]] && roster_ref=".claude/agents/${selected_name}.md"
        fi
    fi

    if $has_cursor; then
        local dest_cursor="${TARGET_DIR}/.cursor/agents/${selected_name}.md"
        if [[ ! -f "$dest_cursor" ]]; then
            cat > "$dest_cursor" << EOF
---
name: ${selected_name}
description: "Optional specialist role: ${selected_name}"
model: ${MODEL_BACKEND}
---

EOF
            cat "$selected_file" >> "$dest_cursor"
            copied_any=true
            [[ -z "$roster_ref" ]] && roster_ref=".cursor/agents/${selected_name}.md"
        fi
    fi

    if ! $copied_any; then
        warn "Role ${selected_name} already exists in this project."
        return
    fi

    success "Role '${selected_name}' added to ${TARGET_DIR}"

    # Update team-roster.md
    local roster="${TARGET_DIR}/docs/team-roster.md"
    if [[ -f "$roster" ]]; then
        local display_name
        display_name="$(echo "$selected_name" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}')"
        local tmp_roster
        tmp_roster="$(mktemp)"
        sed "/<!-- new members here -->/a\\
| **${display_name}** | ${display_name} | \`${roster_ref}\` | ✅ Active |" "$roster" > "$tmp_roster" && mv "$tmp_roster" "$roster"
        success "team-roster.md updated"
    fi

    info "Member added for detected platform(s). Activate it from your tool's agent/instructions flow."
}

# ─── Create custom role ─────────────────────────────────────

create_custom_role() {
    step "Create custom role"
    echo ""

    ask "Role name (e.g. data-engineer, qa-tester)" ROLE_NAME
    ask "Role title (e.g. Data Engineer, QA Tester)" ROLE_TITLE
    ask "Short role description" ROLE_DESC
    ask "Areas of expertise (comma-separated)" ROLE_EXPERTISE
    ask "Character motto (a short phrase)" ROLE_MOTTO

    local role_file="${ROLES_DIR}/${ROLE_NAME}.instructions.md"

    cat > "$role_file" << EOF
# ${ROLE_TITLE} — ${ROLE_TITLE} Instructions

## Identity

You are the ${ROLE_TITLE} of the Understudy team. Your code name is **${ROLE_TITLE}**.
${ROLE_DESC}
Your motto: "${ROLE_MOTTO}"

## Expertise
$(echo "$ROLE_EXPERTISE" | tr ',' '\n' | sed 's/^[[:space:]]*/- /')

## How you work
1. You read \`docs/spec.md\` to understand the requirements
2. You consult \`docs/decisions.md\` for decisions already made
3. You coordinate with the other team agents as needed
4. You document your decisions and progress

## Standards
- Clean and maintainable code
- Explicit error handling
- No hardcoded secrets
- Documentation of what you produce

## Team interaction
- **← Architect**: You receive design decisions
- **→ Security**: You consult on security matters
- **← PM**: You resolve requirements questions
EOF

    success "Role '${ROLE_NAME}' created at: ${role_file}"
    info "You can now add it to a project with: ./wizard.sh --add-member"
}

# ─── Post-deploy ─────────────────────────────────────────────

post_deploy() {
    # Run any module-supplied post-install actions the user requested
    # via flags from modules/<name>/post-install.flags. Done before the
    # success banner so failures surface above it.
    run_postinstall_actions

    echo ""
    echo -e "${GREEN}${BOLD}"
    if $INTEGRATION_MODE; then
        echo "    ╔═══════════════════════════════════════════════╗"
        echo "    ║                                               ║"
        echo "    ║    🎭  UNDERSTUDY INTEGRATED SUCCESSFULLY      ║"
        echo "    ║    Existing project enhanced                   ║"
        echo "    ║                                               ║"
        echo "    ╚═══════════════════════════════════════════════╝"
    else
        echo "    ╔═══════════════════════════════════════════════╗"
        echo "    ║                                               ║"
        echo "    ║    🎭  UNDERSTUDY DEPLOYED SUCCESSFULLY        ║"
        echo "    ║                                               ║"
        echo "    ╚═══════════════════════════════════════════════╝"
    fi
    echo -e "${NC}"

    step "Next steps"
    echo ""

    if $PLATFORM_COPILOT; then
        info "${BOLD}── GitHub Copilot ──${NC}"
        echo ""
        info "1. Open Copilot CLI in the project directory:"
        echo -e "      ${CYAN}cd ${TARGET_DIR} && copilot${NC}"
        echo ""
        info "2. Start with the spec — tell the Architect what you need:"
        echo -e "      ${CYAN}/agent → Architect${NC}"
        echo ""
        info "3. When the spec is ready, activate Backend/Frontend:"
        echo -e "      ${CYAN}/agent → Backend${NC}  or  ${CYAN}/agent → Frontend${NC}"
        echo ""
    fi

    if $PLATFORM_CLAUDE; then
        info "${BOLD}── Claude Code ──${NC}"
        echo ""
        info "1. Open Claude Code in the project directory:"
        echo -e "      ${CYAN}cd ${TARGET_DIR} && claude${NC}"
        echo ""
        info "2. Start a session by loading context:"
        echo -e "      ${CYAN}/project:start-session${NC}"
        echo ""
        info "3. Agents are in .claude/agents/ — invoke them by name"
        echo ""
        info "4. Design features with the command:"
        echo -e "      ${CYAN}/project:design-feature${NC}"
        echo ""
    fi

    if $PLATFORM_CURSOR; then
        info "${BOLD}── Cursor ──${NC}"
        echo ""
        info "1. Open Cursor in the project directory:"
        echo -e "      ${CYAN}cd ${TARGET_DIR} && cursor .${NC}"
        echo ""
        info "2. Global rules are applied automatically (.cursor/rules/)"
        echo ""
        info "3. Agents are in .cursor/agents/ — invoke them from the Agent panel"
        echo ""
    fi

    info "At the end of the session, update the log:"
    if $PLATFORM_COPILOT || $PLATFORM_CURSOR; then
        echo -e "      Copilot/Cursor: ${CYAN}\"Update docs/session-log.md\"${NC}"
    fi
    if $PLATFORM_CLAUDE; then
        echo -e "      Claude:  ${CYAN}/project:end-session${NC}"
    fi
    echo ""

    step "Deployed structure"
    echo ""
    if command -v tree &>/dev/null; then
        tree -a -I '.git' "${TARGET_DIR}" --charset=utf-8
    else
        find "${TARGET_DIR}" -not -path '*/.git/*' -not -name '.git' | sort | head -30
    fi
    echo ""

    step "Useful commands"
    echo ""

    if $PLATFORM_COPILOT; then
        echo -e "    ${BOLD}Copilot CLI:${NC}"
        echo -e "    ${CYAN}./wizard.sh --add-member${NC}   → Add Data Engineer, QA, etc."
        echo -e "    ${CYAN}/agent${NC}                     → Select team agent"
        echo -e "    ${CYAN}/instructions${NC}              → Enable/disable instructions"
        echo -e "    ${CYAN}/model${NC}                     → Change model (see understudy.yaml)"
        echo ""
        echo -e "    ${BOLD}VS Code:${NC}"
        echo -e "    Instructions are applied automatically based on the file you are editing."
        echo -e "    Prompt files are in ${CYAN}.github/prompts/${NC} — use them from Copilot Chat."
        echo ""
    fi

    if $PLATFORM_CLAUDE; then
        echo -e "    ${BOLD}Claude Code:${NC}"
        echo -e "    ${CYAN}/project:start-session${NC}     → Load context at startup"
        echo -e "    ${CYAN}/project:end-session${NC}       → Close session and update logs"
        echo -e "    ${CYAN}/project:design-feature${NC}    → Design a new feature"
        echo -e "    ${CYAN}/project:security-review${NC}   → Security review of changes"
        echo ""
    fi

    if $PLATFORM_CURSOR; then
        echo -e "    ${BOLD}Cursor:${NC}"
        echo -e "    Agents are in ${CYAN}.cursor/agents/${NC} — invoke them from the Agent panel."
        echo -e "    Rules are applied automatically from ${CYAN}.cursor/rules/${NC}."
        echo -e "    Guardrails are in ${CYAN}.cursor/rules/guardrails.mdc${NC}."
        echo ""
    fi

    echo -e "    To override: edit ${CYAN}understudy.yaml${NC} at the project root."
    echo ""
}

# ─── Post-deploy — global mode ───────────────────────────────

post_deploy_global() {
    run_postinstall_actions

    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "    ╔═══════════════════════════════════════════════╗"
    echo "    ║                                               ║"
    echo "    ║    🎭  UNDERSTUDY INSTALLED GLOBALLY           ║"
    echo "    ║                                               ║"
    echo "    ╚═══════════════════════════════════════════════╝"
    echo -e "${NC}"

    step "What this means"
    echo ""
    info "Every repository you open now has the Understudy team available"
    info "for the platforms you selected — no per-project setup required."
    echo ""
    info "Run ${CYAN}understudy --here${NC} inside any specific repo to add full"
    info "per-project customization (spec.md, ADRs, session log, apply_to"
    info "overrides, team roster) on top of the global team — nothing is lost."
    echo ""

    if $PLATFORM_CURSOR; then
        warn "Cursor requires a one-time manual step — see above and docs/12-global-mode.md"
        echo ""
    fi

    step "Manage this installation"
    echo ""
    echo -e "    ${CYAN}understudy --global --add-member${NC}   → add an optional role globally"
    echo -e "    ${CYAN}understudy --global --uninstall${NC}    → remove everything installed globally"
    echo ""
}

# ─── Help ────────────────────────────────────────────────────

show_help() {
    banner
    echo "  Usage:"
    echo "    understudy                   Interactive Understudy deployment"
    echo "    understudy --here            Deploy in current directory using inferred values"
    echo "    understudy --here --yes      Same as --here, skip confirmation prompt"
    echo "    understudy --here -y         Short form of --yes"
    echo "    understudy --add-member      Add a team member"
    echo "    understudy --create-role     Create a new custom role"
    echo "    understudy --all-roles       Deploy the entire role catalog, not just the defaults"
    echo "    understudy --uninstall       Remove Understudy files from the current project"
    echo "    understudy --uninstall --yes Same as --uninstall, skip confirmation prompt"
    echo "    understudy --help            Show this help"
    echo ""
    echo "  Machine-wide install (see docs/12-global-mode.md):"
    echo "    understudy --global               Deploy a default team for every project on this machine"
    echo "    understudy --global --yes         Same as --global, skip confirmation prompt"
    echo "    understudy --global --all-roles   Deploy the entire role catalog globally"
    echo "    understudy --global --add-member  Add an optional role to the global team"
    echo "    understudy --global --uninstall   Remove everything a --global deploy wrote"
    echo "    understudy --docs-only            Create persistent per-repo memory only — no agent files (pairs with --global)"
    echo "    understudy --docs-only --yes      Same as --docs-only, skip confirmation prompt"
    echo ""

    # Auto-list opt-in modules so adding modules/<name>/ surfaces in --help
    # without further edits.
    if [[ ${#MODULE_NAMES[@]} -gt 0 ]]; then
        echo "  Opt-in modules:"
        local i mflag mname desc
        for i in "${!MODULE_NAMES[@]}"; do
            mflag="${MODULE_FLAGS_[$i]}"
            mname="${MODULE_NAMES[$i]}"
            desc="${MODULE_DESCS[$i]:-${MODULE_TITLES[$i]:-$mname}}"
            printf "    understudy %-14s %s\n" "$mflag" "$desc"
        done
        echo ""
    fi

    # Auto-list module-supplied post-install flags. Each module declares
    # them in modules/<name>/post-install.flags and discover_modules()
    # registers them at startup, so contributors can ship new automation
    # without editing this file.
    if [[ ${#POSTINSTALL_FLAGS[@]} -gt 0 ]]; then
        echo "  Module post-install flags (combine with the matching opt-in module):"
        local j pflag pdesc
        for j in "${!POSTINSTALL_FLAGS[@]}"; do
            pflag="${POSTINSTALL_FLAGS[$j]}"
            pdesc="${POSTINSTALL_DESCS[$j]:-(no description)}"
            printf "    understudy %-25s %s\n" "$pflag" "$pdesc"
        done
        echo ""
    fi

    echo "  Supported platforms:"
    echo "    • GitHub Copilot CLI / VS Code"
    echo "    • Claude Code"
    echo "    • Cursor"
    echo ""
    echo "  The wizard deploys a complete AI agent team to your project:"
    echo "    • Architect — Solution design"
    echo "    • Backend   — API and service implementation"
    echo "    • Frontend  — User interfaces"
    echo "    • DevOps    — Infrastructure and CI/CD"
    echo "    • Security  — Integrated security"
    echo "    • QA        — Testing and software quality"
    echo ""
    echo "  Additional roles available in: ${ROLES_DIR}/"
    echo ""
}

# ─── Main ────────────────────────────────────────────────────

main() {
    check_for_updates "$@"

    # Populate the module registry before arg parsing so module flags
    # (e.g. --caveman) resolve dynamically.
    discover_modules

    # Pre-parse flags that combine with the default deploy flow.
    # --here / --yes (-y) can appear in any order before/after each other.
    local _args=()
    local _mod_idx _post_idx
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --here)       DEPLOY_HERE=true ;;
            --yes|-y)     AUTO_CONFIRM=true ;;
            --global)     GLOBAL_MODE=true ;;
            --uninstall)  GLOBAL_UNINSTALL=true ;;
            --all-roles)  ALL_ROLES=true ;;
            --docs-only)  DOCS_ONLY=true ;;
            *)
                # Module flags (registered via discover_modules) flip the
                # corresponding MODULE_INCLUDED entry. Module post-install
                # flags flip POSTINSTALL_REQUESTED. Anything else falls
                # through to the subcommand parser below.
                if _mod_idx="$(module_index_by_flag "$1")"; then
                    MODULE_INCLUDED[_mod_idx]=true
                elif _post_idx="$(postinstall_index_by_flag "$1")"; then
                    POSTINSTALL_REQUESTED[_post_idx]=true
                else
                    _args+=("$1")
                fi
                ;;
        esac
        shift
    done
    if [[ ${#_args[@]} -gt 0 ]]; then
        set -- "${_args[@]}"
    else
        set --
    fi

    case "${1:-}" in
        --help|-h)
            show_help
            ;;
        --add-member)
            banner
            if $GLOBAL_MODE; then
                add_team_member_global
            else
                add_team_member
            fi
            ;;
        --create-role)
            banner
            create_custom_role
            ;;
        *)
            banner
            if $GLOBAL_UNINSTALL && ! $GLOBAL_MODE; then
                project_uninstall
                return
            fi
            if $DOCS_ONLY; then
                validate_templates
                deploy_docs_only
                return
            fi
            if $GLOBAL_MODE; then
                if $GLOBAL_UNINSTALL; then
                    global_uninstall
                    return
                fi
                validate_templates
                validate_global_templates
                gather_project_info_global
                if $PLATFORM_COPILOT; then
                    validate_copilot_templates
                fi
                if $PLATFORM_CLAUDE; then
                    validate_claude_templates
                fi
                if $PLATFORM_CURSOR; then
                    validate_cursor_templates
                fi
                load_config
                deploy_team_global
                post_deploy_global
                return
            fi
            validate_templates
            gather_project_info
            if $PLATFORM_COPILOT; then
                validate_copilot_templates
            fi
            if $PLATFORM_CLAUDE; then
                validate_claude_templates
            fi
            if $PLATFORM_CURSOR; then
                validate_cursor_templates
            fi
            load_config
            deploy_team
            post_deploy
            ;;
    esac
}

# Only run main when executed directly (not when sourced for testing)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
