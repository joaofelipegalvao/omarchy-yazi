#!/bin/bash
# Omarchy Yazi Theme - Uninstaller
# https://github.com/joaofelipegalvao/omarchy-yazi

set -uo pipefail

readonly VERSION="2.0.0"
readonly INSTALL_DIR="$HOME/.local/share/omarchy-yazi"
readonly YAZI_CONF="$HOME/.config/yazi/theme.toml"
readonly PERSISTENT_THEMES_DIR="$HOME/.config/yazi/omarchy-themes"
readonly HOOK_SCRIPT="$HOME/.local/bin/omarchy-yazi-hook"
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
info() { [[ $QUIET -eq 0 ]] && echo -e "${BLUE}󰋼${NC} $*"; }

usage() {
  cat <<EOF
Omarchy Yazi Theme Uninstaller v$VERSION

Usage: $(basename "$0") [OPTIONS]

Options:
  -h, --help          Show this help
  -q, --quiet         Minimal output
  -f, --force         Skip confirmation prompts
  -k, --keep-configs  Keep theme configs in ~/.config/yazi/omarchy-themes
  -v, --version       Show version

