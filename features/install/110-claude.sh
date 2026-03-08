#!/bin/bash

install_feature_claude() {
	local auth_choice="2"
	local api_key=""
	local config_dir="$CZSH_HOME/claude"
	local config_file="$config_dir/config.sh"

	if [ "$ENABLE_CLAUDE" != true ]; then
		return 0
	fi

	print_section "Claude CLI Configuration" "$FIRE" "$PURPLE"
	logConfiguring "Claude CLI"

	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

	if ! command -v npm >/dev/null 2>&1; then
		logError "npm is not available. Node.js installation may have failed."
		echo
		return 0
	fi

	logInstalling "Claude CLI globally"
	if ! npm install -g @anthropic-ai/claude-code >/dev/null 2>&1; then
		logWarning "Failed to install Claude CLI"
		echo
		return 0
	fi
	logInstalled "Claude CLI"

	ensure_directories "$config_dir"

	if [ "$INTERACTIVE_FLAG" = true ]; then
		printf "${PURPLE}${BOLD}Choose authentication method for Claude CLI:${RESET}\n"
		printf "${WHITE}1.${RESET} API Key\n"
		printf "${WHITE}2.${RESET} Skip configuration and authenticate later\n"
		auth_choice=$(prompt_choice "${YELLOW}Enter your choice (1-2): ${RESET}" "2")
	fi

	case "$auth_choice" in
	1)
		logInfo "Get your API key from: https://console.anthropic.com/settings/keys"
		api_key=$(prompt_secret "${YELLOW}🔑 Enter your Anthropic API key: ${RESET}")
		if [[ -n "$api_key" ]]; then
			cat >"$config_file" <<EOF
#!/bin/bash
export ANTHROPIC_API_KEY="$api_key"
EOF
			logConfigured "Claude API key saved to $config_file"
		else
			logWarning "No API key provided. Creating a template instead."
			cat >"$config_file" <<'EOF'
#!/bin/bash
# export ANTHROPIC_API_KEY="your_api_key_here"
EOF
		fi
		;;
	*)
		cat >"$config_file" <<'EOF'
#!/bin/bash
# export ANTHROPIC_API_KEY="your_api_key_here"
# Authenticate directly when running claude.
EOF
		logConfigured "Claude configuration placeholder created"
		;;
	esac

	logTip "Usage: run 'claude' from a project directory to start the Claude CLI."
	echo
}

register_install_feature install_feature_claude