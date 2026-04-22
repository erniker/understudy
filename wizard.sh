#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# 🎭  UNDERSTUDY WIZARD — One AI, Every Role
# ═══════════════════════════════════════════════════════════════
#
# TUTORIAL: ¿Qué hace este wizard?
#
#   Este script despliega el sistema Understudy en cualquier proyecto.
#   Genera todos los archivos que Copilot CLI necesita para
#   activar un equipo completo de agentes IA especializados:
#
#   - AGENTS.md → definición del equipo (seleccionable con /agent)
#   - .github/copilot-instructions.md → instrucciones globales
#   - .github/instructions/*.instructions.md → instrucciones por rol
#   - docs/ → plantillas de spec, decisiones, session log
#
#   Uso:
#     ./wizard.sh                    → Despliegue interactivo
#     ./wizard.sh --add-member       → Añadir un miembro al equipo
#     ./wizard.sh --help             → Ayuda
#
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# ─── Configuración ───────────────────────────────────────────
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
# Lee valores de un archivo YAML simple (estructura plana/1 nivel de anidación).
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

# Lee la configuración del sistema, luego override del proyecto si existe
load_config() {
    local project_config="${TARGET_DIR:-}/understudy.yaml"

    # Capa 1: defaults del sistema (junto a wizard.sh)
    if [[ -f "$DEFAULT_CONFIG" ]]; then
        info "Leyendo config global: $(basename "$DEFAULT_CONFIG")"
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
        info "Override de proyecto encontrado: $project_config"
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

    success "Configuración cargada — modelos: Arch=${MODEL_ARCHITECT}, Back=${MODEL_BACKEND}, Front=${MODEL_FRONTEND}, Ops=${MODEL_DEVOPS}, Sec=${MODEL_SECURITY}, QA=${MODEL_QA}"
    info "Guardrails: modo ${BOLD}${GUARDRAILS_MODE}${NC}"
    local platforms_str=""
    $PLATFORM_COPILOT && platforms_str+="Copilot "
    $PLATFORM_CLAUDE && platforms_str+="Claude "
    $PLATFORM_CURSOR && platforms_str+="Cursor "
    info "Plataformas: ${BOLD}${platforms_str}${NC}"
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
        read -r input
        eval "$var_name=\"${input:-$default}\""
    else
        echo -ne "  ${YELLOW}?${NC}  ${prompt}: "
        read -r input
        while [[ -z "$input" ]]; do
            echo -ne "  ${RED}!${NC}  Este campo es obligatorio: "
            read -r input
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

# ─── Validaciones ────────────────────────────────────────────

validate_templates() {
    if [[ ! -d "$TEMPLATES_DIR" ]]; then
        error "Directorio de templates no encontrado: $TEMPLATES_DIR"
        error "Asegúrate de ejecutar el wizard desde su directorio."
        exit 1
    fi

    # Templates compartidos (siempre requeridos)
    local shared_files=(
        "docs/spec.md"
        "docs/decisions.md"
        "docs/session-log.md"
        "docs/team-roster.md"
    )

    for f in "${shared_files[@]}"; do
        if [[ ! -f "${TEMPLATES_DIR}/${f}" ]]; then
            error "Template compartido faltante: ${f}"
            exit 1
        fi
    done
    success "Templates compartidos validados"
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
            error "Template Copilot faltante: ${f}"
            exit 1
        fi
    done
    success "Templates Copilot validados"
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
            error "Template Claude faltante: ${f}"
            exit 1
        fi
    done
    success "Templates Claude validados"
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
            error "Template Cursor faltante: ${f}"
            exit 1
        fi
    done
    success "Templates Cursor validados"
}

# ─── Detección de proyecto existente ─────────────────────────

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

# ─── Recopilar información del proyecto ──────────────────────

gather_project_info() {
    step "Spec-Driven Development — Datos del proyecto"
    echo ""
    info "Necesito algunos datos para desplegar tu equipo."
    echo ""

    ask "Nombre del proyecto (sin espacios, ej: customer-portal)" PROJECT_NAME
    ask "Directorio base (se creará ${PROJECT_NAME}/ dentro)" BASE_DIR "."
    TARGET_DIR="${BASE_DIR}/${PROJECT_NAME}"

    INTEGRATION_MODE=false

    # Detect existing project
    if [[ -d "$TARGET_DIR" ]]; then
        detect_existing_project "$TARGET_DIR"

        case "$EXISTING_MODE" in
            "understudy")
                echo ""
                warn "Este proyecto ya tiene Understudy desplegado."
                info "Los archivos existentes se preservarán."
                info "Solo se añadirán archivos que falten."
                echo ""
                if ! confirm "¿Continuar y añadir archivos faltantes?"; then
                    warn "Operación cancelada."
                    exit 0
                fi
                INTEGRATION_MODE=true
                ;;
            "project")
                echo ""
                step "🔍 Proyecto existente detectado"
                echo ""
                [[ -n "$DETECTED_STACK" ]] && info "  Stack detectado:   ${BOLD}${DETECTED_STACK}${NC}"
                [[ -n "$DETECTED_REPO" ]]  && info "  Repositorio:       ${DETECTED_REPO}"
                [[ -n "$DETECTED_DESC" ]]  && info "  Descripción:       ${DETECTED_DESC}"

                if [[ ${#DETECTED_COMPONENTS[@]} -gt 0 ]]; then
                    echo ""
                    info "  Componentes encontrados:"
                    for comp in "${DETECTED_COMPONENTS[@]}"; do
                        echo -e "    ${CYAN}•${NC} ${comp}"
                    done
                fi

                echo ""
                info "El Understudy se integrará sin tocar archivos existentes."
                echo ""
                if ! confirm "¿Integrar Understudy en este proyecto?"; then
                    warn "Operación cancelada."
                    exit 0
                fi
                INTEGRATION_MODE=true
                ;;
            "directory")
                echo ""
                info "El directorio ${TARGET_DIR} ya existe."
                if ! confirm "¿Desplegar el Understudy en este directorio?"; then
                    warn "Operación cancelada."
                    exit 0
                fi
                ;;
        esac
    fi

    echo ""
    ask "Descripción breve del proyecto" PROJECT_DESCRIPTION "${DETECTED_DESC:-}"
    ask "Stack principal (ej: .NET + React, Node.js + Vue)" TECH_STACK "${DETECTED_STACK:-}"
    ask "Tu nombre (Project Manager)" TEAM_LEAD "$(git config user.name 2>/dev/null || echo '')"
    ask "URL del repositorio (o 'local' si no tiene)" REPOSITORY_URL "${DETECTED_REPO:-local}"

    echo ""
    step "Guardrails — Protección del equipo"
    echo ""
    info "Los guardrails son límites de seguridad y comportamiento para todos los agentes."
    echo ""
    echo -e "    ${CYAN}1)${NC} ${BOLD}split${NC} (recomendado) — Críticos siempre activos + archivo completo con detalles"
    echo -e "    ${CYAN}2)${NC} ${BOLD}embedded${NC} — Solo guardrails críticos incrustados (siempre activos, más ligero)"
    echo ""
    ask "Modo de guardrails [1=split, 2=embedded]" GUARDRAILS_CHOICE "1"
    case "$GUARDRAILS_CHOICE" in
        2|embedded) GUARDRAILS_MODE="embedded" ;;
        *) GUARDRAILS_MODE="split" ;;
    esac

    echo ""
    step "Plataformas — ¿Dónde usarás el Understudy?"
    echo ""
    info "Selecciona las plataformas de IA donde quieres desplegar el Understudy."
    echo ""

    local ans_copilot ans_claude ans_cursor
    ask "¿Desplegar para GitHub Copilot? [S/n]" ans_copilot "S"
    case "${ans_copilot,,}" in
        n|no) PLATFORM_COPILOT=false ;;
        *) PLATFORM_COPILOT=true ;;
    esac

    ask "¿Desplegar para Claude Code? [S/n]" ans_claude "S"
    case "${ans_claude,,}" in
        n|no) PLATFORM_CLAUDE=false ;;
        *) PLATFORM_CLAUDE=true ;;
    esac

    ask "¿Desplegar para Cursor? [S/n]" ans_cursor "S"
    case "${ans_cursor,,}" in
        n|no) PLATFORM_CURSOR=false ;;
        *) PLATFORM_CURSOR=true ;;
    esac

    if ! $PLATFORM_COPILOT && ! $PLATFORM_CLAUDE && ! $PLATFORM_CURSOR; then
        warn "Debes seleccionar al menos una plataforma."
        PLATFORM_COPILOT=true
        info "Seleccionada Copilot por defecto."
    fi

    PROJECT_DATE="$(date +%Y-%m-%d)"

    echo ""
    step "Resumen del despliegue"
    echo ""
    if $INTEGRATION_MODE; then
        info "Modo:         ${BOLD}🔄 INTEGRACIÓN en proyecto existente${NC}"
    else
        info "Modo:         ${BOLD}🆕 NUEVO PROYECTO${NC}"
    fi
    info "Proyecto:     ${BOLD}${PROJECT_NAME}${NC}"
    info "Descripción:  ${PROJECT_DESCRIPTION}"
    info "Stack:        ${TECH_STACK}"
    info "PM:           ${TEAM_LEAD}"
    info "Repositorio:  ${REPOSITORY_URL}"
    info "Guardrails:   ${BOLD}${GUARDRAILS_MODE}${NC}"
    local platforms_display=""
    $PLATFORM_COPILOT && platforms_display+="Copilot "
    $PLATFORM_CLAUDE && platforms_display+="Claude "
    $PLATFORM_CURSOR && platforms_display+="Cursor "
    info "Plataformas:  ${BOLD}${platforms_display}${NC}"
    info "Destino:      ${TARGET_DIR}"
    info "Fecha:        ${PROJECT_DATE}"
    echo ""

    if ! confirm "¿Desplegar el Understudy con estos datos?"; then
        warn "Operación cancelada."
        exit 0
    fi
}

# ─── Generar bloque de guardrails críticos ───────────────────
# Genera el contenido compacto de guardrails para incrustar en copilot-instructions.md
generate_guardrails_critical() {
    local mode="${1:-split}"
    local ref_line=""
    if [[ "$mode" == "split" ]]; then
        ref_line="Para la versión completa con detalles y ejemplos, consulta \`.github/instructions/guardrails.instructions.md\`."
    fi

    cat << GUARDRAILS_EOF
## 🛡️ Guardrails — Límites no negociables

Todos los agentes del equipo DEBEN respetar estos guardrails en todo momento.
${ref_line}

### Seguridad
- **NUNCA** hardcodear secretos, tokens, API keys o passwords en código, logs o config
- **SIEMPRE** usar vault services (Key Vault, Secrets Manager) para secretos
- **SIEMPRE** validar y sanitizar inputs en las fronteras del sistema
- **SIEMPRE** aplicar principio de mínimo privilegio
- Si detectas un secreto expuesto → **PARA y alerta al PM**

### Operaciones destructivas
- **NUNCA** borrar archivos, recursos cloud, datos o revocar accesos sin confirmación explícita del PM
- Antes de destruir: explica qué, por qué, impacto y reversibilidad — espera aprobación

### Datos y PII
- **NUNCA** incluir, procesar o repetir datos reales de clientes o producción
- **NUNCA** loguear datos sensibles (tokens, passwords, PII)
- Si detectas datos reales → **PARA inmediatamente**, no los proceses ni repitas

### Entornos
- **NUNCA** ejecutar cambios directamente en producción sin change request aprobado
- **SIEMPRE** seguir el orden de promoción: dev → test → acc → eng → prd
- **SIEMPRE** usar IaC y pipelines — nunca cambios manuales en consola

### Scope y proceso
- Cada agente respeta la ownership de sus áreas (cruzar boundaries requiere justificación)
- No se escribe código sin spec aprobada (excepto bugfixes, emergencias, CVE, config)
- Proponer plan al PM y esperar aprobación antes de ejecutar cambios significativos
- Actualizar \`docs/session-log.md\` al final de cada sesión

### Calidad
- Self-review antes de presentar código
- Tests apropiados para código nuevo (unit, integration, dry-run según el tipo)
- Sin código muerto, imports sin usar, o TODOs en commits
- Error handling explícito con contexto — nunca fallos silenciosos
GUARDRAILS_EOF
}

# ─── Insertar guardrails en copilot-instructions.md ──────────
# Reemplaza el bloque entre GUARDRAILS_START y GUARDRAILS_END con el contenido generado
inject_guardrails_block() {
    local target_file="$1"
    local mode="$2"

    if [[ "$mode" == "embedded" ]] || [[ "$mode" == "split" ]]; then
        local guardrails_content
        guardrails_content=$(generate_guardrails_critical "$mode")

        # Usar awk para reemplazar el bloque entre marcadores
        awk -v content="$guardrails_content" '
            /<!-- GUARDRAILS_START -->/ {
                print
                print content
                skip=1
                next
            }
            /<!-- GUARDRAILS_END -->/ {
                print
                skip=0
                next
            }
            !skip { print }
        ' "$target_file" > "${target_file}.tmp" && mv "${target_file}.tmp" "$target_file"
        success "Guardrails críticos incrustados en copilot-instructions.md"
    else
        # Eliminar el bloque de marcadores si no se quieren guardrails
        awk '
            /<!-- GUARDRAILS_START -->/ { skip=1; next }
            /<!-- GUARDRAILS_END -->/ { skip=0; next }
            !skip { print }
        ' "$target_file" > "${target_file}.tmp" && mv "${target_file}.tmp" "$target_file"
    fi
}

# ─── Desplegar archivos ─────────────────────────────────────

# Función para copiar template y reemplazar placeholders
deploy_file() {
    local src="$1"
    local dst="$2"

    if [[ -f "$dst" ]]; then
        warn "Archivo ya existe, se preserva: $(basename "$dst")"
        return
    fi

    cp "$src" "$dst"
    # Reemplazar placeholders
    sed -i "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" "$dst" 2>/dev/null || \
        sed -i'' "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" "$dst"
    sed -i "s|{{PROJECT_DESCRIPTION}}|${PROJECT_DESCRIPTION}|g" "$dst" 2>/dev/null || \
        sed -i'' "s|{{PROJECT_DESCRIPTION}}|${PROJECT_DESCRIPTION}|g" "$dst"
    sed -i "s|{{TECH_STACK}}|${TECH_STACK}|g" "$dst" 2>/dev/null || \
        sed -i'' "s|{{TECH_STACK}}|${TECH_STACK}|g" "$dst"
    sed -i "s|{{TEAM_LEAD}}|${TEAM_LEAD}|g" "$dst" 2>/dev/null || \
        sed -i'' "s|{{TEAM_LEAD}}|${TEAM_LEAD}|g" "$dst"
    sed -i "s|{{REPOSITORY_URL}}|${REPOSITORY_URL}|g" "$dst" 2>/dev/null || \
        sed -i'' "s|{{REPOSITORY_URL}}|${REPOSITORY_URL}|g" "$dst"
    sed -i "s|{{DATE}}|${PROJECT_DATE}|g" "$dst" 2>/dev/null || \
        sed -i'' "s|{{DATE}}|${PROJECT_DATE}|g" "$dst"

    # Reemplazar placeholders de modelo (desde config)
    sed -i "s|{{MODEL_ARCHITECT}}|${MODEL_ARCHITECT}|g" "$dst" 2>/dev/null || \
        sed -i'' "s|{{MODEL_ARCHITECT}}|${MODEL_ARCHITECT}|g" "$dst"
    sed -i "s|{{MODEL_BACKEND}}|${MODEL_BACKEND}|g" "$dst" 2>/dev/null || \
        sed -i'' "s|{{MODEL_BACKEND}}|${MODEL_BACKEND}|g" "$dst"
    sed -i "s|{{MODEL_FRONTEND}}|${MODEL_FRONTEND}|g" "$dst" 2>/dev/null || \
        sed -i'' "s|{{MODEL_FRONTEND}}|${MODEL_FRONTEND}|g" "$dst"
    sed -i "s|{{MODEL_DEVOPS}}|${MODEL_DEVOPS}|g" "$dst" 2>/dev/null || \
        sed -i'' "s|{{MODEL_DEVOPS}}|${MODEL_DEVOPS}|g" "$dst"
    sed -i "s|{{MODEL_SECURITY}}|${MODEL_SECURITY}|g" "$dst" 2>/dev/null || \
        sed -i'' "s|{{MODEL_SECURITY}}|${MODEL_SECURITY}|g" "$dst"
    sed -i "s|{{MODEL_QA}}|${MODEL_QA}|g" "$dst" 2>/dev/null || \
        sed -i'' "s|{{MODEL_QA}}|${MODEL_QA}|g" "$dst"

    # Reemplazar placeholders de applyTo (desde config)
    sed -i "s|{{APPLY_TO_ARCHITECT}}|${APPLY_TO_ARCHITECT}|g" "$dst" 2>/dev/null || \
        sed -i'' "s|{{APPLY_TO_ARCHITECT}}|${APPLY_TO_ARCHITECT}|g" "$dst"
    sed -i "s|{{APPLY_TO_BACKEND}}|${APPLY_TO_BACKEND}|g" "$dst" 2>/dev/null || \
        sed -i'' "s|{{APPLY_TO_BACKEND}}|${APPLY_TO_BACKEND}|g" "$dst"
    sed -i "s|{{APPLY_TO_FRONTEND}}|${APPLY_TO_FRONTEND}|g" "$dst" 2>/dev/null || \
        sed -i'' "s|{{APPLY_TO_FRONTEND}}|${APPLY_TO_FRONTEND}|g" "$dst"
    sed -i "s|{{APPLY_TO_DEVOPS}}|${APPLY_TO_DEVOPS}|g" "$dst" 2>/dev/null || \
        sed -i'' "s|{{APPLY_TO_DEVOPS}}|${APPLY_TO_DEVOPS}|g" "$dst"
    sed -i "s|{{APPLY_TO_SECURITY}}|${APPLY_TO_SECURITY}|g" "$dst" 2>/dev/null || \
        sed -i'' "s|{{APPLY_TO_SECURITY}}|${APPLY_TO_SECURITY}|g" "$dst"
    sed -i "s|{{APPLY_TO_QA}}|${APPLY_TO_QA}|g" "$dst" 2>/dev/null || \
        sed -i'' "s|{{APPLY_TO_QA}}|${APPLY_TO_QA}|g" "$dst"

    success "$(basename "$dst")"
}

# ─── Desplegar archivos Copilot ─────────────────────────────

deploy_copilot() {
    step "Desplegando archivos Copilot"

    mkdir -p "${TARGET_DIR}/.github/instructions"

    deploy_file "${TEMPLATES_DIR}/AGENTS.md" "${TARGET_DIR}/AGENTS.md"
    deploy_file "${TEMPLATES_DIR}/.github/copilot-instructions.md" "${TARGET_DIR}/.github/copilot-instructions.md"
    deploy_file "${TEMPLATES_DIR}/.github/instructions/architect.instructions.md" "${TARGET_DIR}/.github/instructions/architect.instructions.md"
    deploy_file "${TEMPLATES_DIR}/.github/instructions/backend.instructions.md" "${TARGET_DIR}/.github/instructions/backend.instructions.md"
    deploy_file "${TEMPLATES_DIR}/.github/instructions/frontend.instructions.md" "${TARGET_DIR}/.github/instructions/frontend.instructions.md"
    deploy_file "${TEMPLATES_DIR}/.github/instructions/devops.instructions.md" "${TARGET_DIR}/.github/instructions/devops.instructions.md"
    deploy_file "${TEMPLATES_DIR}/.github/instructions/security.instructions.md" "${TARGET_DIR}/.github/instructions/security.instructions.md"
    deploy_file "${TEMPLATES_DIR}/.github/instructions/qa-engineer.instructions.md" "${TARGET_DIR}/.github/instructions/qa-engineer.instructions.md"

    # Guardrails Copilot
    step "Desplegando guardrails Copilot (modo: ${GUARDRAILS_MODE})"
    if [[ "$GUARDRAILS_MODE" == "split" ]]; then
        deploy_file "${TEMPLATES_DIR}/.github/instructions/guardrails.instructions.md" "${TARGET_DIR}/.github/instructions/guardrails.instructions.md"
    fi

    local copilot_instructions="${TARGET_DIR}/.github/copilot-instructions.md"
    if [[ -f "$copilot_instructions" ]]; then
        inject_guardrails_block "$copilot_instructions" "$GUARDRAILS_MODE"
    fi

    # Prompt files para VS Code
    step "Desplegando prompt files (VS Code)"
    mkdir -p "${TARGET_DIR}/.github/prompts"
    for prompt_file in "${TEMPLATES_DIR}/.github/prompts/"*.prompt.md; do
        if [[ -f "$prompt_file" ]]; then
            deploy_file "$prompt_file" "${TARGET_DIR}/.github/prompts/$(basename "$prompt_file")"
        fi
    done
}

# ─── Desplegar archivos Claude Code ─────────────────────────

deploy_claude() {
    step "Desplegando archivos Claude Code"

    mkdir -p "${TARGET_DIR}/.claude/agents"
    mkdir -p "${TARGET_DIR}/.claude/commands"
    mkdir -p "${TARGET_DIR}/.claude/hooks"

    # CLAUDE.md — instrucciones globales
    deploy_file "${TEMPLATES_DIR}/CLAUDE.md" "${TARGET_DIR}/CLAUDE.md"

    # Agentes
    for agent_file in "${TEMPLATES_DIR}/.claude/agents/"*.md; do
        if [[ -f "$agent_file" ]]; then
            deploy_file "$agent_file" "${TARGET_DIR}/.claude/agents/$(basename "$agent_file")"
        fi
    done

    # Comandos
    for cmd_file in "${TEMPLATES_DIR}/.claude/commands/"*.md; do
        if [[ -f "$cmd_file" ]]; then
            deploy_file "$cmd_file" "${TARGET_DIR}/.claude/commands/$(basename "$cmd_file")"
        fi
    done

    # Settings y hooks
    deploy_file "${TEMPLATES_DIR}/.claude/settings.json" "${TARGET_DIR}/.claude/settings.json"
    deploy_file "${TEMPLATES_DIR}/.claude/hooks/guardrails-check.sh" "${TARGET_DIR}/.claude/hooks/guardrails-check.sh"
    chmod +x "${TARGET_DIR}/.claude/hooks/guardrails-check.sh" 2>/dev/null || true

    # Inyectar guardrails en CLAUDE.md
    step "Desplegando guardrails Claude Code"
    local claude_md="${TARGET_DIR}/CLAUDE.md"
    if [[ -f "$claude_md" ]]; then
        inject_guardrails_block "$claude_md" "$GUARDRAILS_MODE"
    fi
}

# ─── Desplegar archivos Cursor ──────────────────────────────

deploy_cursor() {
    step "Desplegando archivos Cursor"

    mkdir -p "${TARGET_DIR}/.cursor/agents"
    mkdir -p "${TARGET_DIR}/.cursor/rules"

    # Reglas globales
    deploy_file "${TEMPLATES_DIR}/.cursor/rules/understudy-global.mdc" "${TARGET_DIR}/.cursor/rules/understudy-global.mdc"

    # Agentes
    for agent_file in "${TEMPLATES_DIR}/.cursor/agents/"*.md; do
        if [[ -f "$agent_file" ]]; then
            deploy_file "$agent_file" "${TARGET_DIR}/.cursor/agents/$(basename "$agent_file")"
        fi
    done

    # Inyectar guardrails en guardrails.mdc
    step "Desplegando guardrails Cursor"
    deploy_file "${TEMPLATES_DIR}/.cursor/rules/guardrails.mdc" "${TARGET_DIR}/.cursor/rules/guardrails.mdc"
    local guardrails_mdc="${TARGET_DIR}/.cursor/rules/guardrails.mdc"
    if [[ -f "$guardrails_mdc" ]]; then
        inject_guardrails_block "$guardrails_mdc" "$GUARDRAILS_MODE"
    fi
}

# ─── Orquestador de despliegue ──────────────────────────────

deploy_team() {
    step "Desplegando estructura del proyecto"

    # Crear directorios comunes
    mkdir -p "${TARGET_DIR}/docs"
    mkdir -p "${TARGET_DIR}/src"
    mkdir -p "${TARGET_DIR}/tests"
    mkdir -p "${TARGET_DIR}/scripts"
    success "Directorios comunes creados"

    # Desplegar por plataforma
    if $PLATFORM_COPILOT; then
        deploy_copilot
    fi

    if $PLATFORM_CLAUDE; then
        deploy_claude
    fi

    if $PLATFORM_CURSOR; then
        deploy_cursor
    fi

    # Docs compartidos
    step "Desplegando documentación compartida"
    deploy_file "${TEMPLATES_DIR}/docs/spec.md" "${TARGET_DIR}/docs/spec.md"
    deploy_file "${TEMPLATES_DIR}/docs/decisions.md" "${TARGET_DIR}/docs/decisions.md"
    deploy_file "${TEMPLATES_DIR}/docs/session-log.md" "${TARGET_DIR}/docs/session-log.md"
    deploy_file "${TEMPLATES_DIR}/docs/team-roster.md" "${TARGET_DIR}/docs/team-roster.md"

    # Copiar config al proyecto para override local
    if [[ -f "$DEFAULT_CONFIG" ]] && [[ ! -f "${TARGET_DIR}/understudy.yaml" ]]; then
        cp "$DEFAULT_CONFIG" "${TARGET_DIR}/understudy.yaml"
        success "understudy.yaml (edítalo para override por proyecto)"
    fi

    # Inicializar git si no existe
    if [[ ! -d "${TARGET_DIR}/.git" ]]; then
        if confirm "¿Inicializar repositorio git?"; then
            git -C "${TARGET_DIR}" init --quiet
            success "Repositorio git inicializado"
        fi
    else
        info "Repositorio git ya existe"
    fi
}

# ─── Añadir miembro al equipo ───────────────────────────────

add_team_member() {
    step "Añadir miembro al equipo"

    # Listar roles disponibles en /roles
    if [[ ! -d "$ROLES_DIR" ]] || [[ -z "$(ls -A "$ROLES_DIR" 2>/dev/null)" ]]; then
        warn "No hay roles adicionales en: $ROLES_DIR"
        info "Puedes crear uno manualmente en esa carpeta."
        echo ""
        if confirm "¿Quieres crear un nuevo rol desde cero?"; then
            create_custom_role
        fi
        return
    fi

    echo ""
    info "Roles disponibles:"
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
    echo -e "    ${CYAN}${i})${NC} Crear rol personalizado"
    echo ""

    ask "Selecciona un número" selection
    if [[ "$selection" -eq "$i" ]]; then
        create_custom_role
        return
    fi

    local selected_file="${roles[$((selection - 1))]}"
    local selected_name
    selected_name="$(basename "$selected_file" .instructions.md)"

    ask "Directorio del proyecto donde añadir el miembro" TARGET_DIR

    if [[ ! -d "${TARGET_DIR}/.github/instructions" ]]; then
        error "No parece un proyecto con Understudy. Ejecuta el wizard primero."
        exit 1
    fi

    local dest="${TARGET_DIR}/.github/instructions/${selected_name}.instructions.md"
    if [[ -f "$dest" ]]; then
        warn "El rol ${selected_name} ya existe en este proyecto."
        return
    fi

    cp "$selected_file" "$dest"
    success "Rol '${selected_name}' añadido a ${TARGET_DIR}"

    # Actualizar team-roster.md
    local roster="${TARGET_DIR}/docs/team-roster.md"
    if [[ -f "$roster" ]]; then
        local display_name
        display_name="$(echo "$selected_name" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')"
        sed -i "/<!-- nuevos miembros aquí -->/a | **${display_name}** | ${display_name} | \`.github/instructions/${selected_name}.instructions.md\` | ✅ Activo |" "$roster" 2>/dev/null || \
            sed -i'' "/<!-- nuevos miembros aquí -->/a\\
| **${display_name}** | ${display_name} | \`.github/instructions/${selected_name}.instructions.md\` | ✅ Activo |" "$roster"
        success "team-roster.md actualizado"
    fi

    info "Activa el nuevo agente en Copilot CLI con: /instructions"
}

# ─── Crear rol personalizado ────────────────────────────────

create_custom_role() {
    step "Crear rol personalizado"
    echo ""

    ask "Nombre del rol (ej: data-engineer, qa-tester)" ROLE_NAME
    ask "Título del rol (ej: Data Engineer, QA Tester)" ROLE_TITLE
    ask "Descripción breve del rol" ROLE_DESC
    ask "Áreas de expertise (separadas por coma)" ROLE_EXPERTISE
    ask "Lema del personaje (una frase corta)" ROLE_MOTTO

    local role_file="${ROLES_DIR}/${ROLE_NAME}.instructions.md"

    cat > "$role_file" << EOF
# ${ROLE_TITLE} — ${ROLE_TITLE} Instructions

## Identidad

Eres el ${ROLE_TITLE} del Understudy. Tu nombre en código es **${ROLE_TITLE}**.
${ROLE_DESC}
Tu lema: "${ROLE_MOTTO}"

## Expertise
$(echo "$ROLE_EXPERTISE" | tr ',' '\n' | sed 's/^[[:space:]]*/- /')

## Cómo trabajas
1. Lees \`docs/spec.md\` para entender los requisitos
2. Consultas \`docs/decisions.md\` para decisiones ya tomadas
3. Coordinas con los demás agentes del equipo según necesidad
4. Documentas tus decisiones y progreso

## Estándares
- Código limpio y mantenible
- Error handling explícito
- Sin secretos hardcodeados
- Documentación de lo que produces

## Interacción con el equipo
- **← Architect**: Recibes decisiones de diseño
- **→ Security**: Consultas sobre seguridad
- **← PM**: Resuelves dudas de requisitos
EOF

    success "Rol '${ROLE_NAME}' creado en: ${role_file}"
    info "Ahora puedes añadirlo a un proyecto con: ./wizard.sh --add-member"
}

# ─── Post-deploy ─────────────────────────────────────────────

post_deploy() {
    echo ""
    echo -e "${GREEN}${BOLD}"
    if $INTEGRATION_MODE; then
        echo "    ╔═══════════════════════════════════════════════╗"
        echo "    ║                                               ║"
        echo "    ║    🎭  UNDERSTUDY INTEGRADO CON ÉXITO          ║"
        echo "    ║    Proyecto existente potenciado               ║"
        echo "    ║                                               ║"
        echo "    ╚═══════════════════════════════════════════════╝"
    else
        echo "    ╔═══════════════════════════════════════════════╗"
        echo "    ║                                               ║"
        echo "    ║    🎭  UNDERSTUDY DESPLEGADO CON ÉXITO         ║"
        echo "    ║                                               ║"
        echo "    ╚═══════════════════════════════════════════════╝"
    fi
    echo -e "${NC}"

    step "Próximos pasos"
    echo ""

    if $PLATFORM_COPILOT; then
        info "${BOLD}── GitHub Copilot ──${NC}"
        echo ""
        info "1. Abre Copilot CLI en el directorio del proyecto:"
        echo -e "      ${CYAN}cd ${TARGET_DIR} && copilot${NC}"
        echo ""
        info "2. Empieza con la spec — cuéntale al Architect qué necesitas:"
        echo -e "      ${CYAN}/agent → Architect${NC}"
        echo ""
        info "3. Cuando la spec esté lista, activa Backend/Frontend:"
        echo -e "      ${CYAN}/agent → Backend${NC}  o  ${CYAN}/agent → Frontend${NC}"
        echo ""
    fi

    if $PLATFORM_CLAUDE; then
        info "${BOLD}── Claude Code ──${NC}"
        echo ""
        info "1. Abre Claude Code en el directorio del proyecto:"
        echo -e "      ${CYAN}cd ${TARGET_DIR} && claude${NC}"
        echo ""
        info "2. Inicia sesión cargando contexto:"
        echo -e "      ${CYAN}/project:start-session${NC}"
        echo ""
        info "3. Los agentes están en .claude/agents/ — invócalos por nombre"
        echo ""
        info "4. Diseña features con el comando:"
        echo -e "      ${CYAN}/project:design-feature${NC}"
        echo ""
    fi

    if $PLATFORM_CURSOR; then
        info "${BOLD}── Cursor ──${NC}"
        echo ""
        info "1. Abre Cursor en el directorio del proyecto:"
        echo -e "      ${CYAN}cd ${TARGET_DIR} && cursor .${NC}"
        echo ""
        info "2. Las reglas globales se aplican automáticamente (.cursor/rules/)"
        echo ""
        info "3. Los agentes están en .cursor/agents/ — invócalos desde el Agent panel"
        echo ""
    fi

    info "Al terminar la sesión, actualiza el log:"
    if $PLATFORM_COPILOT || $PLATFORM_CURSOR; then
        echo -e "      Copilot/Cursor: ${CYAN}\"Actualiza docs/session-log.md\"${NC}"
    fi
    if $PLATFORM_CLAUDE; then
        echo -e "      Claude:  ${CYAN}/project:end-session${NC}"
    fi
    echo ""

    step "Estructura desplegada"
    echo ""
    if command -v tree &>/dev/null; then
        tree -a -I '.git' "${TARGET_DIR}" --charset=utf-8
    else
        find "${TARGET_DIR}" -not -path '*/.git/*' -not -name '.git' | sort | head -30
    fi
    echo ""

    step "Comandos útiles"
    echo ""

    if $PLATFORM_COPILOT; then
        echo -e "    ${BOLD}Copilot CLI:${NC}"
        echo -e "    ${CYAN}./wizard.sh --add-member${NC}   → Añadir Data Engineer, QA, etc."
        echo -e "    ${CYAN}/agent${NC}                     → Seleccionar agente del equipo"
        echo -e "    ${CYAN}/instructions${NC}              → Activar/desactivar instrucciones"
        echo -e "    ${CYAN}/model${NC}                     → Cambiar modelo (ver understudy.yaml)"
        echo ""
        echo -e "    ${BOLD}VS Code:${NC}"
        echo -e "    Las instrucciones se aplican automáticamente según el archivo que editas."
        echo -e "    Los prompt files están en ${CYAN}.github/prompts/${NC} — úsalos desde Copilot Chat."
        echo ""
    fi

    if $PLATFORM_CLAUDE; then
        echo -e "    ${BOLD}Claude Code:${NC}"
        echo -e "    ${CYAN}/project:start-session${NC}     → Cargar contexto al iniciar"
        echo -e "    ${CYAN}/project:end-session${NC}       → Cerrar sesión y actualizar logs"
        echo -e "    ${CYAN}/project:design-feature${NC}    → Diseñar nueva feature"
        echo -e "    ${CYAN}/project:security-review${NC}   → Security review de cambios"
        echo ""
    fi

    if $PLATFORM_CURSOR; then
        echo -e "    ${BOLD}Cursor:${NC}"
        echo -e "    Los agentes están en ${CYAN}.cursor/agents/${NC} — invócalos desde el Agent panel."
        echo -e "    Las reglas se aplican automáticamente desde ${CYAN}.cursor/rules/${NC}."
        echo -e "    Los guardrails están en ${CYAN}.cursor/rules/guardrails.mdc${NC}."
        echo ""
    fi

    echo -e "    Para override: edita ${CYAN}understudy.yaml${NC} en la raíz del proyecto."
    echo ""
}

# ─── Ayuda ───────────────────────────────────────────────────

show_help() {
    banner
    echo "  Uso:"
    echo "    ./wizard.sh                  Despliegue interactivo del Understudy"
    echo "    ./wizard.sh --add-member     Añadir un miembro al equipo"
    echo "    ./wizard.sh --create-role    Crear un nuevo rol personalizado"
    echo "    ./wizard.sh --help           Mostrar esta ayuda"
    echo ""
    echo "  Plataformas soportadas:"
    echo "    • GitHub Copilot CLI / VS Code"
    echo "    • Claude Code"
    echo "    • Cursor"
    echo ""
    echo "  El wizard despliega un equipo completo de agentes IA en tu proyecto:"
    echo "    • Architect — Diseño de soluciones"
    echo "    • Backend   — Implementación de APIs y servicios"
    echo "    • Frontend  — Interfaces de usuario"
    echo "    • DevOps    — Infraestructura y CI/CD"
    echo "    • Security  — Seguridad integrada"
    echo "    • QA        — Testing y calidad del software"
    echo ""
    echo "  Roles adicionales disponibles en: ${ROLES_DIR}/"
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

main "$@"
