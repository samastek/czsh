#!/bin/bash

install_feature_nodejs() {
	print_section "Node.js Installation" "$ZAPP" "$GREEN"
	logProgress "Checking Node.js installation..."

	if command -v node >/dev/null 2>&1; then
		logAlreadyInstalled "Node.js $(node -v)"
		echo
		return 0
	fi

	logProgress "Node.js not found. Installing via nvm..."

	if ! command -v nvm >/dev/null 2>&1 && [ ! -f "$HOME/.nvm/nvm.sh" ]; then
		logInstalling "nvm (Node Version Manager)"
		if ! curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh 2>/dev/null | bash; then
			logError "Failed to install nvm"
			return 1
		fi
		logInstalled "nvm"
	fi

	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
	[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

	logInstalling "Node.js v22"
	if nvm install 22 >/dev/null 2>&1; then
		nvm use 22 >/dev/null 2>&1
		nvm alias default 22 >/dev/null 2>&1
		logInstalled "Node.js $(node -v)"
		logSuccess "npm version: $(npm -v)"
	else
		logError "Failed to install Node.js"
		return 1
	fi
	echo
}

register_install_feature install_feature_nodejs