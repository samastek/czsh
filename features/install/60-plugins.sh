#!/bin/bash

managed_repo_default_branch() {
	local repo_url="$1"

	git ls-remote --symref "$repo_url" HEAD 2>/dev/null | sed -n 's@^ref: refs/heads/\([^[:space:]]*\)[[:space:]]*HEAD@\1@p' | head -n 1
}

sync_managed_plugin_repo() {
	local plugin_repo="$1"
	local plugin_path="$2"
	local default_branch=""

	default_branch="$(managed_repo_default_branch "$plugin_repo")"
	if [[ -z "$default_branch" ]]; then
		return 1
	fi

	git -C "$plugin_path" remote set-url origin "$plugin_repo" >/dev/null 2>&1 || return 1
	git -C "$plugin_path" fetch --depth=1 origin "$default_branch" >/dev/null 2>&1 || return 1
	git -C "$plugin_path" checkout -B "$default_branch" FETCH_HEAD >/dev/null 2>&1 || return 1
	git -C "$plugin_path" config "branch.$default_branch.remote" origin || return 1
	git -C "$plugin_path" config "branch.$default_branch.merge" "refs/heads/$default_branch" || return 1
}

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
			if sync_managed_plugin_repo "$plugin_repo" "$plugin_path"; then
				logUpdated "$plugin_name"
			else
				logWarning "Failed to update $plugin_name, but continuing..."
			fi
		else
			logInstalling "$plugin_name plugin"
			git clone --depth=1 --quiet "$plugin_repo" "$plugin_path"
			logInstalled "$plugin_name plugin"
		fi
		echo
	done
}

register_install_feature install_feature_plugins