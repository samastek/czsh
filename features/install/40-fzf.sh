#!/bin/bash

install_feature_fzf() {
	print_section "FZF Installation" "$ROCKET" "$BLUE"

	if [ -d "$FZF_INSTALLATION_PATH" ]; then
		logAlreadyInstalled "FZF"
		logUpdating "FZF"
		if git -C "$FZF_INSTALLATION_PATH" pull --quiet 2>/dev/null; then
			logUpdated "FZF"
		else
			logWarning "Failed to update FZF, but continuing..."
		fi
	else
		logInstalling "FZF"
		if ! git clone --depth 1 --quiet "$FZF_REPO" "$FZF_INSTALLATION_PATH" 2>/dev/null; then
			logError "Failed to clone FZF repository"
			return 1
		fi
		logInstalled "FZF"
	fi

	logProgress "Running FZF install script..."
	if "$FZF_INSTALLATION_PATH/install" --all --key-bindings --completion --no-update-rc --no-bash --no-fish >/dev/null 2>&1; then
		logSuccess "FZF installation completed"
	else
		logWarning "FZF install script failed, but continuing..."
	fi
	echo
}

register_install_feature install_feature_fzf