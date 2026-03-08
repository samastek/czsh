#!/bin/bash

install_feature_lazydocker() {
	print_section "Lazydocker Installation" "$GEAR" "$CYAN"

	if command -v lazydocker >/dev/null 2>&1; then
		logAlreadyInstalled "Lazydocker"
		echo
		return 0
	fi

	if is_macos; then
		if [[ "$CZSH_PACKAGE_MANAGER" == "brew" ]]; then
			logInstalling "Lazydocker via Homebrew"
			if brew install lazydocker >/dev/null 2>&1; then
				logInstalled "Lazydocker"
			else
				logWarning "Failed to install lazydocker with Homebrew"
			fi
		else
			logWarning "Homebrew not available, skipping lazydocker installation on macOS"
		fi
	else
		if [ -d "$LAZYDOCKER_INSTALLATION_PATH" ]; then
			logAlreadyInstalled "Lazydocker installer repository"
			logUpdating "Lazydocker installer repository"
			git -C "$LAZYDOCKER_INSTALLATION_PATH" pull --quiet 2>/dev/null || logWarning "Failed to update lazydocker repository"
		else
			logInstalling "Lazydocker installer repository"
			git clone --depth 1 --quiet "$LAZYDOCKER_REPO" "$LAZYDOCKER_INSTALLATION_PATH"
			logInstalled "Lazydocker installer repository"
		fi

		if "$LAZYDOCKER_INSTALLATION_PATH/scripts/install_update_linux.sh" >/dev/null 2>&1; then
			logInstalled "Lazydocker"
		else
			logWarning "Failed to install lazydocker on Linux"
		fi
	fi
	echo
}

register_install_feature install_feature_lazydocker