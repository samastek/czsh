#!/bin/bash

install_feature_plugins() {
	print_section "Zsh Plugins Installation" "$PACKAGE" "$PURPLE"

	local plugin_count=0
	local total_plugins=${#PLUGIN_DEFINITIONS[@]}
	local plugin_entry plugin_name plugin_repo plugin_path

	for plugin_entry in "${PLUGIN_DEFINITIONS[@]}"; do
		((plugin_count++))
		plugin_name="${plugin_entry%%:*}"
		plugin_repo="${plugin_entry#*:}"
		plugin_path="$OHMYZSH_CUSTOM_PLUGIN_PATH/$plugin_name"

		logStepProgress "$plugin_count" "$total_plugins" "$plugin_name"

		if [ -d "$plugin_path" ]; then
			logAlreadyInstalled "$plugin_name plugin"
			logUpdating "$plugin_name"
			git -C "$plugin_path" pull --quiet 2>/dev/null || logWarning "Failed to update $plugin_name, but continuing..."
		else
			logInstalling "$plugin_name plugin"
			git clone --depth=1 --quiet "$plugin_repo" "$plugin_path"
			logInstalled "$plugin_name plugin"
		fi
		echo
	done
}

register_install_feature install_feature_plugins