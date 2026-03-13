#!/bin/bash

install_feature_powerlevel10k() {
	print_section "Powerlevel10k Theme" "$SPARKLES" "$PURPLE"

	if [ -d "$POWERLEVEL_10K_PATH" ]; then
		logAlreadyInstalled "Powerlevel10k"
		logUpdating "Powerlevel10k"
		if git -C "$POWERLEVEL_10K_PATH" pull --quiet 2>/dev/null; then
			logUpdated "Powerlevel10k"
		else
			logWarning "Failed to update Powerlevel10k, but continuing..."
		fi
	else
		logInstalling "Powerlevel10k"
		git clone --depth=1 --quiet "$POWERLEVEL10K_REPO" "$POWERLEVEL_10K_PATH"
		logInstalled "Powerlevel10k"
	fi
	echo
}

register_install_feature install_feature_powerlevel10k