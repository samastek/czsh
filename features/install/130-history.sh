#!/bin/bash

install_feature_history_copy() {
	local script_path="$HOME/.cache/bash-to-zsh-hist.py"

	print_section "Bash History Migration" "$FOLDER" "$YELLOW"

	if [ "$COPY_HISTORY_FLAG" != true ]; then
		logWarning "Not copying bash_history to zsh_history (use --cp-hist or -c to enable)"
		echo
		return 0
	fi

	if [ ! -f "$HOME/.bash_history" ]; then
		logWarning "No ~/.bash_history file found"
		echo
		return 0
	fi

	logProgress "Copying bash_history to zsh_history..."
	if wget -q --show-progress "https://gist.githubusercontent.com/muendelezaji/c14722ab66b505a49861b8a74e52b274/raw/49f0fb7f661bdf794742257f58950d209dd6cb62/bash-to-zsh-hist.py" -O "$script_path" 2>/dev/null; then
		if python3 "$script_path" <"$HOME/.bash_history" >>"$HOME/.zsh_history" 2>/dev/null; then
			logSuccess "bash_history copied to zsh_history"
		else
			logWarning "History conversion script failed"
		fi
	else
		logWarning "Failed to download history conversion script"
	fi
	echo
}

register_install_feature install_feature_history_copy