#!/bin/bash

install_feature_zsh_codex() {
	local config_path="$HOME/.config/zsh_codex.ini"
	local api_key=""

	if [ "$ENABLE_CODEX" != true ]; then
		return 0
	fi

	print_section "Zsh Codex Configuration" "$FIRE" "$PURPLE"
	logConfiguring "zsh_codex"
	ensure_directories "$HOME/.config"
	cp "$SCRIPT_DIR/zsh_codex.ini" "$config_path"

	if [ "$INTERACTIVE_FLAG" = true ]; then
		api_key=$(prompt_secret "${YELLOW}Enter your OpenAI API key: ${RESET}")
		if [[ -n "$api_key" ]]; then
			sed -i.bak "s/TOBEREPLEACED/${api_key}/g" "$config_path"
			rm -f "$config_path.bak"
		else
			logInfo "No API key entered. Update $config_path later if needed."
		fi
	else
		logInfo "Non-interactive mode: copied zsh_codex.ini template without an API key."
	fi

	logInstalling "OpenAI Python package"
	pip3 install openai >/dev/null 2>&1 && logInstalled "OpenAI Python package" || logWarning "Failed to install openai"

	logInstalling "Groq Python package"
	pip3 install groq >/dev/null 2>&1 && logInstalled "Groq Python package" || logWarning "Failed to install groq"

	logConfigured "zsh_codex"
	echo
}

register_install_feature install_feature_zsh_codex