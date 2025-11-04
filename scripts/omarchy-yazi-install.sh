#!/bin/bash
# Omarchy Yazi Theme - Installer
# https://github.com/joaofelipegalvao/omarchy-yazi

set -euo pipefail

readonly VERSION="1.0.0"
readonly REPO="https://github.com/joaofelipegalvao/omarchy-yazi.git"
readonly INSTALL_DIR="$HOME/.local/share/omarchy-yazi"
readonly YAZI_CONF="$HOME/.config/yazi/theme.toml"
readonly HOOK_SCRIPT="$HOME/.local/bin/omarchy-yazi-hook"
readonly HOOK_FILE="$HOME/.config/omarchy/hooks/theme-set"
readonly OMARCHY_DIR="$HOME/.config/omarchy"
readonly THEMES_DIR="$OMARCHY_DIR/themes"

QUIET=0
FORCE=0

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log() { [[ $QUIET -eq 0 ]] && echo -e "${GREEN}▶${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*" >&2; }
error() {
  echo -e "${RED}✗${NC} $*" >&2
  exit 1
}
info() { [[ $QUIET -eq 0 ]] && echo -e "${BLUE}󰋼${NC} $*"; }

usage() {
  cat <<EOF
Omarchy Yazi Theme Installer v$VERSION

Usage: $(basename "$0") [OPTIONS]

Options:
  -h, --help     Show this help
  -q, --quiet    Minimal output
  -f, --force    Force reinstall
  -v, --version  Show version

EOF
  exit 0
}

check_deps() {
  local missing=()

  if [[ ! -d "$OMARCHY_DIR" ]]; then
    error "Omarchy not found at $OMARCHY_DIR"
  fi

  if [[ ! -d "$(dirname $HOOK_FILE)" ]]; then
    error "Omarchy hook directory not found, version 3.1+ required"
  fi

  command -v yazi >/dev/null 2>&1 || missing+=("yazi")
  command -v git >/dev/null 2>&1 || missing+=("git")

  if [[ ${#missing[@]} -gt 0 ]]; then
    error "Missing dependencies: ${missing[*]}"
  fi

  log "Dependencies OK"
}

install_plugin() {
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

  if [[ -f "$script_dir/scripts/omarchy-yazi-install.sh" ]]; then
    log "Running in development mode (local directory)"

    mkdir -p "$(dirname "$INSTALL_DIR")"

    if [[ "$script_dir" != "$INSTALL_DIR" ]]; then
      log "Copying local files to $INSTALL_DIR..."
      rm -rf "$INSTALL_DIR"
      cp -r "$script_dir" "$INSTALL_DIR"
      log "Local files copied"
    else
      log "Already running from install directory"
    fi
    return 0
  fi

  mkdir -p "$(dirname "$INSTALL_DIR")"

  if [[ -d "$INSTALL_DIR/.git" ]]; then
    log "Updating plugin..."
    git -C "$INSTALL_DIR" pull --quiet 2>&1 && log "Plugin updated" || warn "Update failed"
  elif [[ -d "$INSTALL_DIR" ]]; then
    if [[ $FORCE -eq 1 ]]; then
      log "Removing existing installation..."
      rm -rf "$INSTALL_DIR"
      log "Installing plugin..."
      git clone --quiet --depth 1 "$REPO" "$INSTALL_DIR" 2>&1 || error "Clone failed"
    else
      log "Plugin already exists (use -f to reinstall)"
    fi
  else
    log "Installing plugin..."
    git clone --quiet --depth 1 "$REPO" "$INSTALL_DIR" 2>&1 || error "Clone failed"
  fi
}

install_hook() {
  mkdir -p "$(dirname "$HOOK_SCRIPT")"

  cp "$INSTALL_DIR/scripts/omarchy-yazi-hook" "$HOOK_SCRIPT"
  chmod +x "$HOOK_SCRIPT"

  # Add to Omarchy hook file
  if [[ -f "${HOOK_FILE}.sample" ]] && [[ ! -f "$HOOK_FILE" ]]; then
    mv "${HOOK_FILE}.sample" "$HOOK_FILE"
  fi

  if [[ ! -f "$HOOK_FILE" ]]; then
    echo '#!/bin/bash' >"$HOOK_FILE"
    chmod +x "$HOOK_FILE"
  fi

  if ! grep -q 'omarchy-yazi-hook' "$HOOK_FILE"; then
    echo "$HOOK_SCRIPT \$1" >>"$HOOK_FILE"
    log "Installed Yazi hook"
  else
    log "Hook already configured"
  fi
}

generate_theme_configs() {
  if [[ ! -d "$THEMES_DIR" ]]; then
    warn "Themes dir not found at $THEMES_DIR"
    return
  fi

  local count=0

  for theme_dir in "$THEMES_DIR"/*; do
    [[ ! -d "$theme_dir" ]] && continue

    local theme_name=$(basename "$theme_dir")
    local yazi_file="$theme_dir/theme-yazi.toml"

    [[ -f "$yazi_file" ]] && continue

    local source_theme="$INSTALL_DIR/themes/$theme_name/theme.toml"

    # Se não encontrar o tema exato, tentar encontrar uma variante
    if [[ ! -f "$source_theme" ]]; then
      # Procurar por temas que começam com o mesmo nome
      local variant_theme=$(find "$INSTALL_DIR/themes" -maxdepth 1 -type d -name "${theme_name}*" | head -n1)

      if [[ -n "$variant_theme" ]] && [[ -f "$variant_theme/theme.toml" ]]; then
        source_theme="$variant_theme/theme.toml"
        log "Using variant $(basename "$variant_theme") for $theme_name"
      else
        warn "No Yazi theme found for: $theme_name"
        continue
      fi
    fi

    cp "$source_theme" "$yazi_file"
    ((count++)) || true
  done

  if [[ $count -gt 0 ]]; then
    log "Created $count Yazi theme config(s)"
  else
    log "Theme configs already exist"
  fi
}

configure_yazi() {
  mkdir -p "$(dirname "$YAZI_CONF")"

  local current_theme_file="$OMARCHY_DIR/current/theme/theme-yazi.toml"

  if [[ -f "$current_theme_file" ]]; then
    ln -sf "$current_theme_file" "$YAZI_CONF"
    log "Linked current Omarchy theme to Yazi"
  else

    local current_theme=$(basename "$(dirname "$OMARCHY_DIR/current/theme")" 2>/dev/null || echo "tokyo-night")
    local theme_file="$THEMES_DIR/$current_theme/theme-yazi.toml"

    if [[ -f "$theme_file" ]]; then
      ln -sf "$theme_file" "$YAZI_CONF"
      log "Linked current Omarchy theme to Yazi"
    else
      warn "Current theme file not found, skipping initial link"
    fi
  fi
}

main() {
  while [[ $# -gt 0 ]]; do
    case $1 in
    -h | --help) usage ;;
    -q | --quiet)
      QUIET=1
      shift
      ;;
    -f | --force)
      FORCE=1
      shift
      ;;
    -v | --version)
      echo "$VERSION"
      exit 0
      ;;
    *) error "Unknown option: $1\nUse --help for usage" ;;
    esac
  done

  [[ $QUIET -eq 0 ]] && echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
  [[ $QUIET -eq 0 ]] && echo -e "${BLUE}║${NC}         ${BLUE}Omarchy Yazi Installer${NC}         ${BLUE}║${NC}"
  [[ $QUIET -eq 0 ]] && echo -e "${BLUE}╚════════════════════════════════════════╝${NC}\n"

  check_deps
  install_plugin
  generate_theme_configs
  install_hook
  configure_yazi

  if [[ $QUIET -eq 0 ]]; then
    echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}        ${GREEN}✓${NC} Installation Complete         ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}\n"
    echo "Next steps:"
    echo "  1. Change theme with Super+Shift+Ctrl+Space"
    echo "  2. Restart Yazi to see the new theme"
    echo ""
  fi
}

main "$@"
