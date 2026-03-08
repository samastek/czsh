#!/bin/bash

install_feature_todo() {
	local todo_root="$CZSH_HOME/todo"
	local archive="$CZSH_HOME/todo.txt_cli-2.12.0.tar.gz"

	print_section "Todo.sh Installation" "$CHECKMARK" "$GREEN"

	if [ -L "$todo_root/bin/todo.sh" ] || [ -f "$CZSH_BIN_DIR/todo.sh" ]; then
		logAlreadyInstalled "todo.sh"
		echo
		return 0
	fi

	logInstalling "todo.sh in $todo_root"
	ensure_directories "$todo_root" "$CZSH_BIN_DIR"

	logProgress "Downloading todo.sh v2.12.0..."
	wget -q --show-progress "https://github.com/todotxt/todo.txt-cli/releases/download/v2.12.0/todo.txt_cli-2.12.0.tar.gz" -O "$archive" 2>/dev/null

	logProgress "Extracting and setting up todo.sh..."
	tar xf "$archive" -C "$todo_root" --strip 1 2>/dev/null && rm -f "$archive"
	ln -s -f "$todo_root/todo.sh" "$CZSH_BIN_DIR/todo.sh"
	ln -s -f "$todo_root/todo.cfg" "$HOME/.todo.cfg"

	logInstalled "todo.sh"
	echo
}

register_install_feature install_feature_todo