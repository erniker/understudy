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
#     ./wizard.sh                    → Interactive deployment
#     ./wizard.sh --add-member       → Add a team member
#     ./wizard.sh --help             → Help
#
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# ─── Configuration ──────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"
ROLES_DIR="${SCRIPT_DIR}/roles"
DEFAULT_CONFIG="${SCRIPT_DIR}/understudy.yaml"

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

confirm() {
    local prompt="$1"
    echo -ne "  ${YELLOW}?${NC}  ${prompt} ${CYAN}[Y/n]${NC}: "
    read -r answer
    [[ "${answer,,}" != "n" ]]
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

# ─── Existing project detection ─────────────────────────────

detect_existing_project() {
    local dir="$1"

    DETECTED_NAME=""
    DETECTED_DESC=""
    DETECTED_STACK=""
    DETECTED_REPO=""
    DETECTED_COMPONENTS=()
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
}

# ─── Gather project information ─────────────────────────────

gather_project_info() {
    step "Spec-Driven Development — Project data"
    echo ""
    info "I need some data to deploy your team."
    echo ""

    ask "Project name (no spaces, e.g. customer-portal)" PROJECT_NAME
    ask "Base directory (${PROJECT_NAME}/ will be created inside)" BASE_DIR "."

    # Normalize Windows paths typed in Git Bash (e.g. C:\Users\foo → /c/Users/foo)
    if [[ "${BASE_DIR:1:1}" == ":" ]]; then
        local drive="${BASE_DIR:0:1}"
        BASE_DIR="/${drive,,}${BASE_DIR:2}"
    fi
    BASE_DIR=$(tr '\134' '/' <<< "$BASE_DIR")  # replace backslashes with forward slashes (\134 = octal backslash)

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
    case "${ans_copilot,,}" in
        n|no) PLATFORM_COPILOT=false ;;
        *) PLATFORM_COPILOT=true ;;
    esac

    ask "Deploy for Claude Code? [Y/n]" ans_claude "Y"
    case "${ans_claude,,}" in
        n|no) PLATFORM_CLAUDE=false ;;
        *) PLATFORM_CLAUDE=true ;;
    esac

    ask "Deploy for Cursor? [Y/n]" ans_cursor "Y"
    case "${ans_cursor,,}" in
        n|no) PLATFORM_CURSOR=false ;;
        *) PLATFORM_CURSOR=true ;;
    esac

    if ! $PLATFORM_COPILOT && ! $PLATFORM_CLAUDE && ! $PLATFORM_CURSOR; then
        warn "You must select at least one platform."
        PLATFORM_COPILOT=true
        info "Copilot selected by default."
    fi

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
    mkdir -p "${TARGET_DIR}/.cursor/rules"

    # Global rules
    deploy_file "${TEMPLATES_DIR}/.cursor/rules/understudy-global.mdc" "${TARGET_DIR}/.cursor/rules/understudy-global.mdc"

    # Agents
    for agent_file in "${TEMPLATES_DIR}/.cursor/agents/"*.md; do
        if [[ -f "$agent_file" ]]; then
            deploy_file "$agent_file" "${TARGET_DIR}/.cursor/agents/$(basename "$agent_file")"
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

    # Copy config to project for local override
    if [[ -f "$DEFAULT_CONFIG" ]] && [[ ! -f "${TARGET_DIR}/understudy.yaml" ]]; then
        cp "$DEFAULT_CONFIG" "${TARGET_DIR}/understudy.yaml"
        success "understudy.yaml (edit it to override per-project settings)"
    fi

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

    if [[ ! -d "${TARGET_DIR}/.github/instructions" ]]; then
        error "This does not look like an Understudy project. Run the wizard first."
        exit 1
    fi

    local dest="${TARGET_DIR}/.github/instructions/${selected_name}.instructions.md"
    if [[ -f "$dest" ]]; then
        warn "Role ${selected_name} already exists in this project."
        return
    fi

    cp "$selected_file" "$dest"
    success "Role '${selected_name}' added to ${TARGET_DIR}"

    # Update team-roster.md
    local roster="${TARGET_DIR}/docs/team-roster.md"
    if [[ -f "$roster" ]]; then
        local display_name
        display_name="$(echo "$selected_name" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')"
        sed -i "/<!-- new members here -->/a | **${display_name}** | ${display_name} | \`.github/instructions/${selected_name}.instructions.md\` | ✅ Active |" "$roster" 2>/dev/null || \
            sed -i'' "/<!-- new members here -->/a\\
| **${display_name}** | ${display_name} | \`.github/instructions/${selected_name}.instructions.md\` | ✅ Active |" "$roster"
        success "team-roster.md updated"
    fi

    info "Activate the new agent in Copilot CLI with: /instructions"
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

# ─── Help ────────────────────────────────────────────────────

show_help() {
    banner
    echo "  Usage:"
    echo "    ./wizard.sh                  Interactive Understudy deployment"
    echo "    ./wizard.sh --add-member     Add a team member"
    echo "    ./wizard.sh --create-role    Create a new custom role"
    echo "    ./wizard.sh --help           Show this help"
    echo ""
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
    case "${1:-}" in
        --help|-h)
            show_help
            ;;
        --add-member)
            banner
            add_team_member
            ;;
        --create-role)
            banner
            create_custom_role
            ;;
        *)
            banner
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
