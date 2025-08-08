#!/bin/bash
# Modular CZSH installer (refactored)
# Thin orchestrator: parses flags, sets component flags, runs registry

set -euo pipefail

source ./utils.sh
source ./core/paths.sh
source ./lib/guard.sh

# Load registry FIRST so arrays exist before modules register
source modules/registry.sh 2>/dev/null || true

# Load modules (each registers itself)
for f in modules/*.sh; do
  [[ $f == *registry.sh ]] && continue
  source "$f"
done

print_header "CZSH - Enhanced Zsh Configuration Installer" "$CYAN" "$BG_BLUE"
INSTALL_START_TIME=$(date +%s)

# Flag defaults
CP_HIST_FLAG=false
INTERACTIVE=false
CODEX_FLAG=false
GEMINI_FLAG=false
CLAUDE_FLAG=false
VIM_MODE_FLAG=false

usage() {
  cat <<EOF
Usage: $0 [options]
  --cp-hist        Copy bash history into zsh history
  --interactive    Run interactive steps (future use)
  --codex          Configure zsh_codex
  --gemini         Install Gemini CLI
  --claude         Install Claude CLI
  --vim-mode       Enable vim mode config
  --list           List components & exit
  -h, --help       Show help
EOF
}

if [[ $# -eq 0 ]]; then :; fi

while [[ $# -gt 0 ]]; do
  case $1 in
    --cp-hist|-c) CP_HIST_FLAG=true ; shift ;;
    --interactive|-n) INTERACTIVE=true ; shift ;;
    --codex|-x) CODEX_FLAG=true ; shift ;;
    --gemini|-g) GEMINI_FLAG=true ; shift ;;
    --claude|-cl) CLAUDE_FLAG=true ; shift ;;
    --vim-mode|-v) VIM_MODE_FLAG=true ; shift ;;
    --list) echo "Registered components:"; for e in "${CZSH_COMPONENTS[@]}"; do IFS='|' read -r n fn flag <<<"$e"; printf " - %s%s\n" "$n" "${flag:+ (flag:$flag)}"; done; exit 0 ;;
    -h|--help) usage; exit 0 ;;
    *) logWarning "Unknown arg: $1"; shift ;;
  esac
done

# Pre-config directory scaffolding & baseline files
print_section "Directory Setup" "$FOLDER" "$CYAN"
ensure_dir "$CZSH_CONFIG_DIR" "$CZSH_ZSHRC_DIR" "$CZSH_CACHE_DIR" "$CZSH_BIN_DIR" "$CZSH_FONTS_DIR"

if [[ -f $HOME/.zshrc ]]; then
  backup_file="$HOME/.zshrc-backup-$(date +%Y-%m-%d-%H%M%S)"
  mv "$HOME/.zshrc" "$backup_file" && logSuccess "Backed up existing .zshrc to $(basename "$backup_file")" || logWarning "Backup failed"
fi

cp -f ./.zshrc "$HOME/" 2>/dev/null || true
cp -f ./czshrc.zsh "$CZSH_CONFIG_DIR/" 2>/dev/null || true
if [[ -f $HOME/.zcompdump ]]; then mv $HOME/.zcompdump* "$CZSH_CACHE_DIR" 2>/dev/null || true; fi
logSuccess "Baseline configuration deployed"

# Run components via registry
run_registered_components

# Summary
end_time=$(date +%s)
print_installation_summary "$INSTALL_START_TIME" "$end_time"

# Component timing table
if ((${#CZSH_COMPONENT_TIMES[@]})); then
  echo
  print_section "Component Durations" "$HOURGLASS" "$GREEN"
  printf "%s\n" "Name | Seconds | Status" 
  printf "%s\n" "-----------------------" 
  for t in "${CZSH_COMPONENT_TIMES[@]}"; do IFS=':' read -r name secs rc <<<"$t"; printf "%s | %s | %s\n" "$name" "$secs" "$([[ $rc -eq 0 ]] && echo OK || echo FAIL)"; done
fi

logTip "Restart terminal to start using CZSH"

exit 0
