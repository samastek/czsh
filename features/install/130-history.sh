#!/bin/bash

install_feature_history_copy() {
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
	# Bash writes "#<epoch>" before a command when HISTTIMEFORMAT is set; zsh's
	# extended format is ": <epoch>:0;<command>".
	# shortcut: non-ASCII bytes are not zsh-metafied; such lines may show garbled.
	if awk -v now="$(date +%s)" '
		/^#[0-9]+$/ { stamp = substr($0, 2); next }
		{ print ": " (stamp ? stamp : now) ":0;" $0; stamp = "" }
	' "$HOME/.bash_history" >>"$HOME/.zsh_history"; then
		logSuccess "bash_history copied to zsh_history"
	else
		logWarning "History conversion failed"
	fi
	echo
}

register_install_feature install_feature_history_copy