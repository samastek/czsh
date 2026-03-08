#!/bin/bash

install_feature_gemini() {
	local auth_choice="3"
	local api_key=""
	local config_dir="$CZSH_HOME/gemini"
	local config_file="$config_dir/config.sh"

	if [ "$ENABLE_GEMINI" != true ]; then
		return 0
	fi

	print_section "Gemini CLI Configuration" "$STAR" "$CYAN"
	logConfiguring "Gemini CLI"

	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

	if ! command -v npm >/dev/null 2>&1; then
		logError "npm is not available. Node.js installation may have failed."
		echo
		return 0
	fi

	logInstalling "Gemini CLI globally"
	if ! npm install -g @google/gemini-cli >/dev/null 2>&1; then
		logWarning "Failed to install Gemini CLI"
		echo
		return 0
	fi
	logInstalled "Gemini CLI"

	ensure_directories "$config_dir"

	if [ "$INTERACTIVE_FLAG" = true ]; then
		printf "${CYAN}${BOLD}Choose authentication method for Gemini CLI:${RESET}\n"
		printf "${WHITE}1.${RESET} API Key\n"
		printf "${WHITE}2.${RESET} OAuth later with 'gemini auth'\n"
		printf "${WHITE}3.${RESET} Skip configuration\n"
		auth_choice=$(prompt_choice "${YELLOW}Enter your choice (1-3): ${RESET}" "3")
	fi

	case "$auth_choice" in
	1)
		logInfo "Get your API key from: https://aistudio.google.com/apikey"
		api_key=$(prompt_secret "${YELLOW}🔑 Enter your Gemini API key: ${RESET}")
		if [[ -n "$api_key" ]]; then
			cat >"$config_file" <<EOF
#!/bin/bash
export GEMINI_API_KEY="$api_key"
EOF
			logConfigured "Gemini API key saved to $config_file"
		else
			logWarning "No API key provided. Creating a template instead."
			cat >"$config_file" <<'EOF'
#!/bin/bash
# export GEMINI_API_KEY="your_api_key_here"
# Or authenticate with: gemini auth
EOF
		fi
		;;
	2)
		cat >"$config_file" <<'EOF'
#!/bin/bash
# export GEMINI_API_KEY="your_api_key_here"
# Or authenticate with: gemini auth
EOF
		logConfigured "Gemini configuration created. Run 'gemini auth' after installation."
		;;
	*)
		cat >"$config_file" <<'EOF'
#!/bin/bash
# Gemini CLI configuration placeholder
# Run 'gemini auth' or export GEMINI_API_KEY here.
EOF
		logConfigured "Gemini configuration placeholder created"
		;;
	esac
	echo
}

register_install_feature install_feature_gemini