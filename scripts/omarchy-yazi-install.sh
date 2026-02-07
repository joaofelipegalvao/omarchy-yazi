#!/bin/bash
# Omarchy Yazi Theme - Installer
# https://github.com/joaofelipegalvao/omarchy-yazi

set -euo pipefail

readonly VERSION="2.0.0"
readonly REPO="https://github.com/joaofelipegalvao/omarchy-yazi.git"
readonly INSTALL_DIR="$HOME/.local/share/omarchy-yazi"
readonly YAZI_CONF="$HOME/.config/yazi/theme.toml"
readonly PERSISTENT_THEMES_DIR="$HOME/.config/yazi/omarchy-themes"
readonly GENERATOR_SCRIPT="$HOME/.local/bin/omarchy-yazi-generator"
readonly HOOK_SCRIPT="$HOME/.local/bin/omarchy-yazi-hook"
readonly HOOK_FILE="$HOME/.config/omarchy/hooks/theme-set"
readonly OMARCHY_DIR="$HOME/.config/omarchy"

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

Architecture (v2.0):
  ~/.config/yazi/theme.toml (symlink)
    ↓ points to
  ~/.config/yazi/omarchy-themes/THEME_NAME.toml (persistent profiles)

Changes are PERSISTENT per theme. Edit theme files directly!

