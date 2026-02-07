#!/bin/bash
# Omarchy Yazi - Uninstaller (v2.0.0)
# https://github.com/joaofelipegalvao/omarchy-yazi

set -uo pipefail

readonly VERSION="2.0.0"
readonly INSTALL_DIR="$HOME/.local/share/omarchy-yazi"
readonly YAZI_CONF="$HOME/.config/yazi/theme.toml"
readonly PERSISTENT_THEMES_DIR="$HOME/.config/yazi/omarchy-themes"
readonly RELOAD_SCRIPT="$HOME/.local/bin/omarchy-yazi-reload"
readonly GENERATOR_SCRIPT="$HOME/.local/bin/omarchy-yazi-generator"
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
info() { [[ $QUIET -eq 0 ]] && echo -e "${BLUE}ℹ ${NC} $*"; }

usage() {
  cat <<EOF
Omarchy Yazi Uninstaller v$VERSION

Usage: $(basename "$0") [OPTIONS]

Options:
  -h, --help          Show this help
  -q, --quiet         Minimal output
  -f, --force         Skip confirmation prompts
  -k, --keep-configs  Keep theme profiles in ~/.config/yazi/omarchy-themes
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

remove_fallback_themes() {
  if [[ -d "$INSTALL_DIR" ]]; then
    log "Removing fallback theme repository..."
    rm -rf "$INSTALL_DIR" || warn "Failed to remove: $INSTALL_DIR"
  else
    [[ $QUIET -eq 0 ]] && info "Fallback themes directory not found, skipping."
  fi
}

remove_scripts() {
  # Remove generator script
  if [[ -f "$GENERATOR_SCRIPT" ]]; then
    log "Removing generator script..."
    rm -f "$GENERATOR_SCRIPT"
  fi

  # Remove reload script
  if [[ -f "$RELOAD_SCRIPT" ]]; then
    log "Removing reload script..."
    rm -f "$RELOAD_SCRIPT"
  fi
}

remove_hook() {
  if [[ -f "$HOOK_FILE" ]]; then
    if grep -q 'omarchy-yazi-reload' "$HOOK_FILE"; then
      log "Removing hook from Omarchy configuration..."
      sed -i '/omarchy-yazi-reload/d' "$HOOK_FILE"

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
    if [[ "$link_target" == *"/omarchy-themes/"* ]]; then
      log "Removing Omarchy theme symlink..."
      rm -f "$YAZI_CONF"

      # Restore from backup if exists
      local backup=$(find "$(dirname "$YAZI_CONF")" -maxdepth 1 -name "theme.toml.backup.*" -type f 2>/dev/null | sort -r | head -n1)
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

  # Clean up old backups
  find "$(dirname "$YAZI_CONF")" -maxdepth 1 -name "theme.toml.backup.*" -type f -delete 2>/dev/null || true
}

remove_theme_profiles() {
  if [[ $KEEP_CONFIGS -eq 1 ]]; then
    info "Keeping theme profiles (--keep-configs)"
    return
  fi

  if [[ ! -d "$PERSISTENT_THEMES_DIR" ]]; then
    warn "Persistent themes directory not found at $PERSISTENT_THEMES_DIR"
    return
  fi

  local count=$(find "$PERSISTENT_THEMES_DIR" -maxdepth 1 -name "*.toml" -type f 2>/dev/null | wc -l)

  if [[ $count -gt 0 ]]; then
    log "Removing $count theme profile(s)..."
    rm -rf "$PERSISTENT_THEMES_DIR"
  else
    [[ $QUIET -eq 0 ]] && info "No theme profiles found to remove"
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
  [[ ! -d "$INSTALL_DIR" ]] && echo "  ✓ Fallback theme repository"
  [[ ! -f "$GENERATOR_SCRIPT" ]] && echo "  ✓ Generator script"
  [[ ! -f "$RELOAD_SCRIPT" ]] && echo "  ✓ Reload script"
  [[ ! -L "$YAZI_CONF" ]] && echo "  ✓ Theme symlink"
  [[ ! -d "$YAZI_STATE" ]] && echo "  ✓ Yazi cache"

  echo -e "\n${BLUE}Next steps:${NC}"
  echo "  If Yazi is running, restart it to see changes:"
  echo -e "    ${CYAN}killall yazi${NC}"
  echo -e "    ${CYAN}yazi${NC}"

  if [[ $KEEP_CONFIGS -eq 0 ]]; then
    echo -e "\n  Theme profiles were removed from:"
    echo -e "    ${CYAN}~/.config/yazi/omarchy-themes/${NC}"
  else
    echo -e "\n  Theme profiles were kept at:"
    echo -e "    ${CYAN}~/.config/yazi/omarchy-themes/${NC}"
    echo "  You can manually remove them if desired."
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
    *) error "Unknown option: $1
Use --help for usage" ;;
    esac
  done

  [[ $QUIET -eq 0 ]] && echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
  [[ $QUIET -eq 0 ]] && echo -e "${BLUE}║${NC}        ${BLUE}Omarchy Yazi Uninstaller${NC}       ${BLUE}║${NC}"
  [[ $QUIET -eq 0 ]] && echo -e "${BLUE}╚════════════════════════════════════════╝${NC}\n"

  if [[ $FORCE -eq 0 ]]; then
    echo "This will remove the following components:"
    echo "  • Fallback theme repository ($INSTALL_DIR)"
    echo "  • Generator script ($GENERATOR_SCRIPT)"
    echo "  • Reload script ($RELOAD_SCRIPT)"
    echo "  • Theme symlink ($YAZI_CONF)"
    echo "  • Yazi cache ($YAZI_STATE)"
    [[ $KEEP_CONFIGS -eq 0 ]] && echo "  • Theme profiles (use -k to keep)"
    echo ""

    if ! confirm "Continue with uninstallation?"; then
      info "Uninstallation aborted by user."
      exit 0
    fi
  fi

  remove_fallback_themes
  remove_scripts
  remove_hook
  clean_yazi_conf
  remove_theme_profiles
  clean_yazi_state
  show_summary

  if [[ $QUIET -eq 0 ]]; then
    echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}        ${GREEN}✓${NC} Uninstallation Complete       ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}\n"
  fi
}

main "$@"
