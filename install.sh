#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/features/lib/platform.sh"
source "$SCRIPT_DIR/features/lib/common.sh"

print_header "CZSH - Enhanced Zsh Configuration Installer" "$CYAN" "$BG_BLUE"
logInfo "Installing CZSH with modular runtime and install features."
logNote "Repository feature scripts live under features/, and installed runtime modules are sourced from ~/.config/czsh/features/."
echo

parse_args "$@"
detect_platform
configure_install_paths

if [[ "$CZSH_PLATFORM" == "unknown" ]]; then
	logErrorWithSuggestion "Unsupported platform detected: $OSTYPE" "Use macOS or Linux."
	exit 1
fi

print_section "Platform Detection" "$GEAR" "$CYAN"
logInfo "Platform: $CZSH_PLATFORM"
if [[ -n "$CZSH_PACKAGE_MANAGER" ]]; then
	logInfo "Package manager: $CZSH_PACKAGE_MANAGER"
else
	logWarning "No supported package manager detected; some prerequisites may need manual installation."
fi
echo

load_install_feature_scripts
run_install_features
finish_installation
