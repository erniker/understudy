#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# 🎭 Understudy — Installer
# ═══════════════════════════════════════════════════════════════
#
# Usage (one-liner):
#   curl -fsSL https://raw.githubusercontent.com/erniker/understudy/main/install.sh | bash
#
# Or with a specific version:
#   curl -fsSL https://raw.githubusercontent.com/erniker/understudy/main/install.sh | bash -s -- --version v1.0.0
#
# Manual flags:
#   --version <tag>   Install a specific version (default: latest)
#   --dir <path>      Install to a custom directory (default: ~/.understudy)
#   --no-path         Skip PATH setup
#   --uninstall       Remove Understudy from the system
#
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# ── Constants ─────────────────────────────────────────────────
REPO="erniker/understudy"
INSTALL_DIR="${HOME}/.understudy"
BIN_DIR="${HOME}/.local/bin"
BIN_NAME="understudy"
GITHUB_API="https://api.github.com/repos/${REPO}/releases/latest"
GITHUB_DOWNLOAD="https://github.com/${REPO}/releases/download"

# ── Colors ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "  ${BLUE}ℹ${NC}  $1"; }
success() { echo -e "  ${GREEN}✔${NC}  $1"; }
warn()    { echo -e "  ${YELLOW}⚠${NC}  $1"; }
error()   { echo -e "  ${RED}✖${NC}  $1" >&2; }
step()    { echo -e "\n  ${CYAN}${BOLD}▸ $1${NC}"; }

# ── Argument parsing ──────────────────────────────────────────
VERSION=""
SETUP_PATH=true
UNINSTALL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --dir)     INSTALL_DIR="$2"; shift 2 ;;
    --no-path) SETUP_PATH=false; shift ;;
    --uninstall) UNINSTALL=true; shift ;;
    *) error "Unknown flag: $1"; exit 1 ;;
  esac
done

# ── Uninstall ─────────────────────────────────────────────────
uninstall() {
  step "Uninstalling Understudy"

  if [[ -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR"
    success "Removed ${INSTALL_DIR}"
  else
    warn "Install directory not found: ${INSTALL_DIR}"
  fi

  local bin_path="${BIN_DIR}/${BIN_NAME}"
  if [[ -f "$bin_path" ]]; then
    rm -f "$bin_path"
    success "Removed ${bin_path}"
  fi

  echo ""
  info "Understudy has been uninstalled."
  info "You may also want to remove the PATH entry from your shell config."
}

if $UNINSTALL; then
  uninstall
  exit 0
fi

# ── Dependency check ──────────────────────────────────────────
check_deps() {
  local missing=()
  command -v curl  &>/dev/null || missing+=("curl")
  command -v tar   &>/dev/null || missing+=("tar")
  command -v bash  &>/dev/null || missing+=("bash")

  if [[ ${#missing[@]} -gt 0 ]]; then
    error "Missing required tools: ${missing[*]}"
    error "Install them and re-run the installer."
    exit 1
  fi
}

# ── Resolve version ───────────────────────────────────────────
resolve_version() {
  if [[ -n "$VERSION" ]]; then
    info "Version requested: ${BOLD}${VERSION}${NC}"
    return
  fi

  info "Fetching latest version from GitHub..."
  VERSION=$(curl -fsSL "$GITHUB_API" \
    -H "Accept: application/vnd.github+json" \
    | grep '"tag_name"' \
    | head -1 \
    | sed 's/.*"tag_name": *"\(.*\)".*/\1/')

  if [[ -z "$VERSION" ]]; then
    error "Could not determine the latest version."
    error "Check your internet connection or specify --version <tag>."
    exit 1
  fi

  info "Latest version: ${BOLD}${VERSION}${NC}"
}

# ── Download and extract ──────────────────────────────────────
download_and_install() {
  local archive="understudy-${VERSION}.tar.gz"
  local url="${GITHUB_DOWNLOAD}/${VERSION}/${archive}"
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  step "Downloading ${archive}"
  info "From: ${url}"

  if ! curl -fsSL "$url" -o "${tmp_dir}/${archive}"; then
    error "Download failed. Is the version tag correct? (${VERSION})"
    rm -rf "$tmp_dir"
    exit 1
  fi
  success "Downloaded"

  step "Installing to ${INSTALL_DIR}"

  # Remove old installation if present
  if [[ -d "$INSTALL_DIR" ]]; then
    warn "Existing installation found — replacing it."
    rm -rf "$INSTALL_DIR"
  fi

  mkdir -p "$INSTALL_DIR"
  tar -xzf "${tmp_dir}/${archive}" -C "$INSTALL_DIR" --strip-components=0
  chmod +x "${INSTALL_DIR}/wizard.sh"
  rm -rf "$tmp_dir"

  success "Files installed to ${INSTALL_DIR}"
}

# ── Create launcher ───────────────────────────────────────────
create_launcher() {
  step "Creating launcher: ${BIN_DIR}/${BIN_NAME}"
  mkdir -p "$BIN_DIR"

  cat > "${BIN_DIR}/${BIN_NAME}" << EOF
#!/usr/bin/env bash
# Understudy launcher — managed by install.sh, do not edit.
exec "${INSTALL_DIR}/wizard.sh" "\$@"
EOF
  chmod +x "${BIN_DIR}/${BIN_NAME}"
  success "Launcher created"
}

# ── PATH setup ────────────────────────────────────────────────
setup_path() {
  # Check if BIN_DIR is already in PATH
  if [[ ":${PATH}:" == *":${BIN_DIR}:"* ]]; then
    info "${BIN_DIR} is already in PATH."
    return
  fi

  step "Adding ${BIN_DIR} to PATH"

  local shell_config=""
  local shell_name
  shell_name="$(basename "${SHELL:-bash}")"

  case "$shell_name" in
    zsh)  shell_config="${ZDOTDIR:-$HOME}/.zshrc" ;;
    bash) shell_config="${HOME}/.bashrc" ;;
    fish) shell_config="${HOME}/.config/fish/config.fish" ;;
    *)    shell_config="${HOME}/.profile" ;;
  esac

  local path_line='export PATH="${HOME}/.local/bin:${PATH}"'
  if [[ "$shell_name" == "fish" ]]; then
    path_line="fish_add_path \$HOME/.local/bin"
  fi

  if ! grep -qF "$BIN_DIR" "$shell_config" 2>/dev/null; then
    echo "" >> "$shell_config"
    echo "# Understudy" >> "$shell_config"
    echo "$path_line" >> "$shell_config"
    success "Added to ${shell_config}"
  else
    info "PATH entry already present in ${shell_config}"
  fi

  warn "Run: source ${shell_config}  (or open a new terminal)"
}

# ── Post-install summary ──────────────────────────────────────
post_install() {
  local msg="🎭  Understudy ${VERSION} installed!"
  local padding=$((42 - ${#msg}))
  local spaces=""
  for ((i = 0; i < padding; i++)); do spaces+=" "; done
  
  echo ""
  echo -e "  ${GREEN}${BOLD}╔══════════════════════════════════════════╗${NC}"
  printf "  ${GREEN}${BOLD}║  %s%s ║${NC}\n" "$msg" "$spaces"
  echo -e "  ${GREEN}${BOLD}╚══════════════════════════════════════════╝${NC}"
  echo ""
  step "Quick start"
  echo ""
  info "Deploy Understudy in any project:"
  echo ""
  echo -e "      ${CYAN}cd /path/to/your/project${NC}"
  echo -e "      ${CYAN}understudy${NC}"
  echo ""
  info "Add a team member:"
  echo -e "      ${CYAN}understudy --add-member${NC}"
  echo ""
  info "Docs: https://github.com/${REPO}#readme"
  echo ""
}

# ── Main ──────────────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}🎭 Understudy Installer${NC}"
echo ""

check_deps
resolve_version
download_and_install
create_launcher

if $SETUP_PATH; then
  setup_path
fi

post_install
