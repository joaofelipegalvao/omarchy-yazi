#!/bin/bash
# Omarchy Yazi Theme - Uninstaller
# https://github.com/joaofelipegalvao/omarchy-yazi

set -uo pipefail

readonly VERSION="1.0.0"
readonly INSTALL_DIR="$HOME/.local/share/omarchy-yazi"
readonly YAZI_CONF="$HOME/.config/yazi/theme.toml"
readonly THEMES_DIR="$HOME/.config/omarchy/themes"
readonly HOOK_SCRIPT="$HOME/.local/bin/omarchy-yazi-hook"
readonly HOOK_FILE="$HOME/.config/omarchy/hooks/theme-set"
readonly YAZI_STATE="$HOME/.local/state/yazi"

QUIET=0
FORCE=0
KEEP_CONFIGS=0

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

log() { [[ $QUIET -eq 0 ]] && echo -e "${GREEN}▶${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*" >&2; }
success() { [[ $QUIET -eq 0 ]] && echo -e "${GREEN}✓${NC} $*"; }
error() {
  echo -e "${RED}✗${NC} $*" >&2
  exit 1
}
info() { [[ $QUIET -eq 0 ]] && echo -e "${BLUE}󰋼${NC} $*"; }

usage() {
  cat <<EOF
Omarchy Yazi Theme Uninstaller v$VERSION

Usage: $(basename "$0") [OPTIONS]

Options:
  -h, --help          Show this help
  -q, --quiet         Minimal output
  -f, --force         Skip confirmation prompts
  -k, --keep-configs  Keep theme configs in ~/.config/omarchy/themes
  -v, --version       Show version

EOF
  exit 0
}

confirm() {
  [[ $FORCE -eq 1 ]] && return 0

  local prompt="$1"
  read -rp "$prompt [y/N] " response </dev/tty
  [[ $response =~ ^[Yy]$ ]]
}

remove_plugin() {
  if [[ -d "$INSTALL_DIR" ]]; then
    log "Removing Omarchy Yazi plugin directory..."
    rm -rf "$INSTALL_DIR" || warn "Failed to remove plugin directory: $INSTALL_DIR"
  else
    [[ $QUIET -eq 0 ]] && info "Plugin directory not found, skipping."
  fi
}

remove_hook() {
  # Remove hook script
  if [[ -f "$HOOK_SCRIPT" ]]; then
    log "Removing hook script..."
    rm -f "$HOOK_SCRIPT"
  fi

  if [[ -f "$HOOK_FILE" ]]; then
    if grep -q 'omarchy-yazi-hook' "$HOOK_FILE"; then
      log "Removing hook from Omarchy configuration..."
      sed -i '/omarchy-yazi-hook/d' "$HOOK_FILE"

      # If file only contains shebang, remove it
      if [[ $(wc -l <"$HOOK_FILE") -le 1 ]]; then
        rm -f "$HOOK_FILE"
        log "Removed empty hook file"
      fi
    fi
  fi
}

clean_yazi_conf() {
  if [[ ! -f "$YAZI_CONF" ]]; then
    [[ $QUIET -eq 0 ]] && info "Yazi config not found: $YAZI_CONF"
    return
  fi

  if [[ -L "$YAZI_CONF" ]]; then
    local link_target=$(readlink "$YAZI_CONF")
    if [[ "$link_target" == *"/omarchy/themes/"* ]]; then
      log "Removing Omarchy theme symlink..."
      rm -f "$YAZI_CONF"

      # Restore from backup if exists
      local backup=$(find "$(dirname "$YAZI_CONF")" -maxdepth 1 -name "theme.toml.backup.*" -type f | sort -r | head -n1)
      if [[ -n "$backup" ]]; then
        cp "$backup" "$YAZI_CONF"
        log "Restored backup: $(basename "$backup")"
      fi
    else
      info "Yazi theme.toml is not an Omarchy symlink, keeping it."
    fi
  else
    info "Yazi theme.toml is not a symlink, keeping it."
  fi

  find "$(dirname "$YAZI_CONF")" -maxdepth 1 -name "theme.toml.backup.*" -type f -delete 2>/dev/null || true
}

remove_theme_configs() {
  if [[ $KEEP_CONFIGS -eq 1 ]]; then
    info "Keeping theme configs (--keep-configs)"
    return
  fi

  if [[ ! -d "$THEMES_DIR" ]]; then
    warn "Themes directory not found at $THEMES_DIR"
    return
  fi

  local count=0

  for theme_dir in "$THEMES_DIR"/*; do
    [[ ! -d "$theme_dir" ]] && continue

    local theme_name=$(basename "$theme_dir")
    local yazi_file="$theme_dir/theme-yazi.toml" # CORRIGIDO: era theme.toml

    if [[ -f "$yazi_file" ]]; then
      if [[ $QUIET -eq 0 ]]; then
        log "Removing config: $theme_name/theme-yazi.toml"
      fi
      rm -f "$yazi_file"
      ((count++)) || true
    fi
  done

  if [[ $count -gt 0 ]]; then
    log "Removed $count Yazi theme config(s)"
  else
    [[ $QUIET -eq 0 ]] && info "No Yazi theme configs found to remove"
  fi
}

clean_yazi_state() {
  if [[ -d "$YAZI_STATE" ]]; then
    log "Cleaning Yazi state cache..."
    rm -rf "$YAZI_STATE"
  fi
}

show_summary() {
  if [[ $QUIET -eq 1 ]]; then
    return
  fi

  echo -e "\n${BLUE}Removal Summary:${NC}"

  echo -e "\n${GREEN}Removed:${NC}"
  [[ ! -d "$INSTALL_DIR" ]] && echo "  ✓ Omarchy Yazi plugin"
  [[ ! -f "$HOOK_SCRIPT" ]] && echo "  ✓ Hook script"
  [[ ! -L "$YAZI_CONF" ]] && echo "  ✓ Theme symlink"
  [[ ! -d "$YAZI_STATE" ]] && echo "  ✓ Yazi cache"

  echo -e "\n${BLUE}Next steps:${NC}"
  echo "  If Yazi is running, restart it to see changes:"
  echo -e "    ${CYAN}killall yazi${NC}"
  echo -e "    ${CYAN}yazi${NC}"

  if [[ $KEEP_CONFIGS -eq 0 ]]; then
    echo -e "\n  Theme configs were removed from:"
    echo -e "    ${CYAN}~/.config/omarchy/themes/*/theme-yazi.toml${NC}"
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
    -k | --keep-configs)
      KEEP_CONFIGS=1
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
  [[ $QUIET -eq 0 ]] && echo -e "${BLUE}║${NC}        ${BLUE}Omarchy Yazi Uninstaller${NC}       ${BLUE}║${NC}"
  [[ $QUIET -eq 0 ]] && echo -e "${BLUE}╚════════════════════════════════════════╝${NC}\n"

  if [[ $FORCE -eq 0 ]]; then
    echo "This will remove the following components:"
    echo "  • Omarchy Yazi plugin ($INSTALL_DIR)"
    echo "  • Hook script ($HOOK_SCRIPT)"
    echo "  • Theme symlink ($YAZI_CONF)"
    echo "  • Yazi cache ($YAZI_STATE)"
    [[ $KEEP_CONFIGS -eq 0 ]] && echo "  • Theme configs (use -k to keep)"
    echo ""

    if ! confirm "Continue with uninstallation?"; then
      info "Uninstallation aborted by user."
      exit 0
    fi
  fi

  remove_plugin
  remove_hook
  clean_yazi_conf
  remove_theme_configs
  clean_yazi_state
  show_summary

  if [[ $QUIET -eq 0 ]]; then
    echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}        ${GREEN}✓${NC} Uninstallation Complete       ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}\n"
  fi
}

main "$@"
