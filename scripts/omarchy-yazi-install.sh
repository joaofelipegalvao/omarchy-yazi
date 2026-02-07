#!/bin/bash
# Omarchy Yazi - Theme Configurator (v2.0.0 - Persistent Profiles)
# Architecture: Persistent Theme Profiles in ~/.config/yazi/omarchy-themes/
# https://github.com/joaofelipegalvao/omarchy-yazi

set -euo pipefail

readonly VERSION="2.0.0"
readonly YAZI_CONF="$HOME/.config/yazi/theme.toml"
readonly RELOAD_SCRIPT="$HOME/.local/bin/omarchy-yazi-reload"
readonly GENERATOR_SCRIPT="$HOME/.local/bin/omarchy-yazi-generator"
readonly HOOK_FILE="$HOME/.config/omarchy/hooks/theme-set"
readonly OMARCHY_DIR="$HOME/.config/omarchy"
readonly PERSISTENT_THEMES_DIR="$HOME/.config/yazi/omarchy-themes"

QUIET=0
FORCE=0

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

log() {
  if [[ $QUIET -eq 0 ]]; then
    echo -e "${GREEN}▶${NC} $*"
  fi
}
warn() { echo -e "${YELLOW}⚠${NC} $*" >&2; }
error() {
  echo -e "${RED}✗${NC} $*" >&2
  exit 1
}
info() {
  if [[ $QUIET -eq 0 ]]; then
    echo -e "${BLUE}ℹ ${NC} $*"
  fi
}

usage() {
  cat <<EOF
Omarchy Yazi Installer v$VERSION

Configures Yazi to work with Omarchy 3.3+.

Usage: $(basename "$0") [OPTIONS]

Options:
  -h, --help     Show this help
  -q, --quiet    Minimal output
  -f, --force    Force reinstall (regenerate all files)
  -v, --version  Show version

Architecture (v2.0):
  ~/.config/yazi/theme.toml (symlink)
    ↓ points to
  ~/.config/yazi/omarchy-themes/THEME_NAME.toml (persistent profiles)

Changes are PERSISTENT per theme. Edit theme files directly!

EOF
  exit 0
}

check_deps() {
  local missing=()

  # Check Omarchy
  if [[ ! -d "$OMARCHY_DIR" ]]; then
    error "Omarchy not found at $OMARCHY_DIR
This installer is for Omarchy Linux users.
Visit: https://omarchy.org"
  fi

  # Check for theme.name file (3.3+ indicator)
  if [[ ! -f "$OMARCHY_DIR/current/theme.name" ]]; then
    warn "Theme name file not found - this may be an older Omarchy version"
    warn "Expected: $OMARCHY_DIR/current/theme.name"
  fi

  # Check dependencies
  command -v yazi >/dev/null 2>&1 || missing+=("yazi")
  command -v git >/dev/null 2>&1 || missing+=("git")

  if [[ ${#missing[@]} -gt 0 ]]; then
    error "Missing dependencies: ${missing[*]}
Install: sudo pacman -S ${missing[*]}"
  fi

  log "Dependencies OK"
}

create_generator_script() {
  log "Creating persistent theme generator..."

  local script_dir="$(dirname "$GENERATOR_SCRIPT")"
  mkdir -p "$script_dir"
  mkdir -p "$PERSISTENT_THEMES_DIR"

  # Check if script exists and is current version
  if [[ -f "$GENERATOR_SCRIPT" && $FORCE -eq 0 ]]; then
    if grep -q "v2.0.0" "$GENERATOR_SCRIPT" 2>/dev/null; then
      info "Generator script already up to date"
      return 0
    fi
  fi

  cat >"$GENERATOR_SCRIPT" <<'GENERATOR'
#!/bin/bash
# Omarchy Yazi Theme Generator (v2.0.0)
# Generates and maintains persistent theme profiles
set -euo pipefail

readonly OMARCHY_DIR="$HOME/.config/omarchy"
readonly THEME_NAME_FILE="$OMARCHY_DIR/current/theme.name"
readonly PERSISTENT_THEMES_DIR="$HOME/.config/yazi/omarchy-themes"
readonly CURRENT_THEME_LINK="$HOME/.config/yazi/theme.toml"
readonly FALLBACK_THEMES_DIR="$HOME/.local/share/omarchy-yazi/themes"

detect_theme() {
  local theme_name=""
  
  # Try reading from theme.name file
  if [[ -f "$THEME_NAME_FILE" ]]; then
    theme_name=$(cat "$THEME_NAME_FILE" | tr -d '[:space:]' 2>/dev/null || echo "")
  fi
  
  # Fallback to default
  echo "${theme_name:-tokyo-night}"
}

find_source_theme() {
  local theme_name="$1"
  local source_file=""
  
  # Try exact match first in fallback themes
  if [[ -f "$FALLBACK_THEMES_DIR/$theme_name/theme.toml" ]]; then
    source_file="$FALLBACK_THEMES_DIR/$theme_name/theme.toml"
  else
    # Try to find variant (e.g., catppuccin-latte -> catppuccin)
    local variant_dir=$(find "$FALLBACK_THEMES_DIR" -maxdepth 1 -type d -name "${theme_name}*" 2>/dev/null | head -n1)
    
    if [[ -n "$variant_dir" ]] && [[ -f "$variant_dir/theme.toml" ]]; then
      source_file="$variant_dir/theme.toml"
    fi
  fi
  
  echo "$source_file"
}

# Main execution
theme_name=$(detect_theme)
theme_file="$PERSISTENT_THEMES_DIR/$theme_name.toml"

# Create persistent theme file ONLY if it doesn't exist
if [[ ! -f "$theme_file" ]]; then
  source_theme=$(find_source_theme "$theme_name")
  
  if [[ -n "$source_theme" ]]; then
    # Copy from fallback themes
    cat >"$theme_file" <<EOF
# ============================================================================
# Omarchy Yazi Theme: $theme_name
# Source: $(basename "$(dirname "$source_theme")")
# ============================================================================
# 
# PERSISTENT THEME PROFILE
# This file is yours to customize! Your changes will persist across theme
# switches - when you return to this theme, your customizations remain.
#
# ============================================================================

EOF
    cat "$source_theme" >>"$theme_file"
  else
    # Create minimal default theme
    cat >"$theme_file" <<'EOF'
# ============================================================================
# Omarchy Yazi Theme (Default)
# ============================================================================
# 
# PERSISTENT THEME PROFILE
# No source theme found - using Yazi defaults.
# Customize this file as needed!
#
# ============================================================================

[manager]
# Add your customizations here

EOF
  fi
fi

# Update symlink to point to current theme's persistent profile
ln -sf "$theme_file" "$CURRENT_THEME_LINK"

exit 0
GENERATOR

  chmod +x "$GENERATOR_SCRIPT" || error "Failed to make generator executable"
  log "Created generator script"
}

install_fallback_themes() {
  log "Installing fallback theme repository..."

  local repo_url="https://github.com/joaofelipegalvao/omarchy-yazi.git"
  local install_dir="$HOME/.local/share/omarchy-yazi"

  mkdir -p "$(dirname "$install_dir")"

  # Check if we're running from the repo directory
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)"

  if [[ -f "$script_dir/scripts/omarchy-yazi-install.sh" ]]; then
    # Development mode - copy local files
    if [[ "$script_dir" != "$install_dir" ]]; then
      log "Copying local files to $install_dir..."
      rm -rf "$install_dir"
      cp -r "$script_dir" "$install_dir"
      log "Local files copied"
    else
      log "Already running from install directory"
    fi
  elif [[ -d "$install_dir/.git" ]]; then
    # Update existing repo
    log "Updating fallback themes..."
    git -C "$install_dir" pull --quiet 2>&1 && log "Themes updated" || warn "Update failed"
  elif [[ -d "$install_dir" ]]; then
    if [[ $FORCE -eq 1 ]]; then
      log "Removing existing installation..."
      rm -rf "$install_dir"
      log "Cloning theme repository..."
      git clone --quiet --depth 1 "$repo_url" "$install_dir" 2>&1 || error "Clone failed"
    else
      log "Fallback themes already exist (use -f to reinstall)"
    fi
  else
    log "Cloning theme repository..."
    git clone --quiet --depth 1 "$repo_url" "$install_dir" 2>&1 || error "Clone failed"
  fi
}

create_reload_script() {
  log "Creating reload script..."
  local script_dir="$(dirname "$RELOAD_SCRIPT")"
  mkdir -p "$script_dir" || error "Failed to create $script_dir"

  cat >"$RELOAD_SCRIPT" <<'SCRIPT'
#!/bin/bash
# Omarchy Yazi Reload Script (v2.0.0)
# Called by Omarchy when theme changes
set -euo pipefail

readonly GENERATOR="$HOME/.local/bin/omarchy-yazi-generator"
readonly YAZI_STATE="$HOME/.local/state/yazi"

# Regenerate current theme config
if [[ -x "$GENERATOR" ]]; then
  "$GENERATOR" &>/dev/null || true
fi

# Clear Yazi state cache
if [[ -d "$YAZI_STATE" ]]; then
  rm -rf "$YAZI_STATE" &>/dev/null || true
fi

exit 0
SCRIPT

  chmod +x "$RELOAD_SCRIPT" || error "Failed to make reload script executable"
  log "Created reload script"
}

install_hook() {
  log "Installing Omarchy hook..."

  local hook_dir="$(dirname "$HOOK_FILE")"

  # Verify hook directory exists
  if [[ ! -d "$hook_dir" ]]; then
    warn "Hook directory not found: $hook_dir"
    warn "Creating it now (may require Omarchy restart)"
    mkdir -p "$hook_dir" || error "Failed to create hook directory"
  fi

  # Create hook file if doesn't exist
  if [[ ! -f "$HOOK_FILE" ]]; then
    cat >"$HOOK_FILE" <<'HOOK'
#!/bin/bash
# Omarchy theme-set hook
HOOK
    chmod +x "$HOOK_FILE" || error "Failed to make hook executable"
  fi

  # Ensure hook is executable
  [[ ! -x "$HOOK_FILE" ]] && chmod +x "$HOOK_FILE"

  # Add reload script to hook if not present
  if ! grep -q 'omarchy-yazi-reload' "$HOOK_FILE" 2>/dev/null; then
    echo "$RELOAD_SCRIPT" >>"$HOOK_FILE"
    log "Hook installed"
  else
    log "Hook already installed"
  fi
}

validate_setup() {
  log "Validating setup..."

  local issues=0

  # Check if generator script exists and is executable
  if [[ ! -x "$GENERATOR_SCRIPT" ]]; then
    warn "Generator script not executable"
    ((issues++))
  fi

  # Check if persistent themes directory exists
  if [[ ! -d "$PERSISTENT_THEMES_DIR" ]]; then
    warn "Persistent themes directory not found"
    ((issues++))
  fi

  # Try to detect current theme
  local theme_name_file="$OMARCHY_DIR/current/theme.name"
  if [[ ! -f "$theme_name_file" ]]; then
    warn "Current theme name file not found at $theme_name_file"
    warn "This is expected on older Omarchy versions"
    ((issues++))
  fi

  if [[ $issues -eq 0 ]]; then
    log "Setup validated successfully"
    return 0
  else
    warn "Setup validation found $issues issue(s)"
    return 1
  fi
}

main() {
  # Parse arguments
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
    *) error "Unknown option: $1
Use --help for usage" ;;
    esac
  done

  # Header
  if [[ $QUIET -eq 0 ]]; then
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}         ${BLUE}Omarchy Yazi Installer${NC}         ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}\n"
    echo -e "${CYAN}New Architecture (v2.0):${NC}"
    echo "  ✓ Works with Omarchy 3.3+"
    echo "  ✓ Persistent theme profiles"
    echo "  ✓ No manual theme directory needed"
    echo ""
  fi

  # Installation steps
  check_deps
  install_fallback_themes
  create_generator_script

  # Generate initial theme config
  if [[ -x "$GENERATOR_SCRIPT" ]]; then
    log "Generating initial theme configuration..."
    "$GENERATOR_SCRIPT" || warn "Initial theme generation failed (will retry on theme change)"
  fi

  create_reload_script
  install_hook

  # Validation
  local validation_ok=0
  validate_setup && validation_ok=1 || validation_ok=0

  # Success message
  if [[ $QUIET -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}     ${GREEN}✓${NC} Installation Complete            ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo ""
    echo "  1. Test theme switching:"
    echo -e "     ${YELLOW}Super + Ctrl + Shift + Space${NC}"
    echo "     → Yazi updates automatically!"
    echo ""
    echo "  2. Restart Yazi to see changes:"
    echo -e "     ${YELLOW}killall yazi && yazi${NC}"
    echo ""
    echo -e "${CYAN}How it works:${NC}"
    echo -e "  • Your theme.toml is now a symlink to:"
    echo -e "    ${YELLOW}~/.config/yazi/omarchy-themes/THEME.toml${NC}"
    echo -e "  • Each theme has its own persistent profile"
    echo -e "  • Your customizations are preserved per theme!"
    echo ""
    echo -e "${CYAN}Customization:${NC}"
    echo -e "  Edit theme profiles directly:"
    echo -e "  ${YELLOW}~/.config/yazi/omarchy-themes/THEME_NAME.toml${NC}"
    echo ""
    echo -e "  Changes persist when you return to that theme!"
    echo ""

    if [[ $validation_ok -eq 0 ]]; then
      echo -e "${YELLOW}⚠ Note:${NC} Setup validation had warnings."
      echo "  This is usually fine - switch themes once to complete setup."
      echo ""
    fi

    echo -e "${GREEN}Enjoy your themed Yazi! 🎉${NC}"
    echo ""
  fi
}

main "$@"
