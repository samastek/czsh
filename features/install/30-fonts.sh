#!/bin/bash

install_font() {
	local filename="$1"
	local url="$2"
	local target="$CZSH_FONT_DIR/$filename"

	if [ -f "$target" ]; then
		logAlreadyInstalled "$filename"
		return 0
	fi

	logInstalling "$filename"
	if wget -q --show-progress -N "$url" -P "$CZSH_FONT_DIR/" 2>/dev/null; then
		logInstalled "$filename"
	else
		logWarning "Failed to download $filename"
	fi
}

install_feature_fonts() {
	print_section "Nerd Fonts Installation" "$SPARKLES" "$PURPLE"
	logProgress "Installing fonts into $CZSH_FONT_DIR"

	install_font "HackNerdFont-Regular.ttf" "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Hack/Regular/HackNerdFont-Regular.ttf"
	install_font "RobotoMonoNerdFont-Regular.ttf" "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/RobotoMono/Regular/RobotoMonoNerdFont-Regular.ttf"
	install_font "DejaVuSansMNerdFont-Regular.ttf" "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/DejaVuSansMono/Regular/DejaVuSansMNerdFont-Regular.ttf"

	if command -v fc-cache >/dev/null 2>&1; then
		logProgress "Refreshing font cache..."
		fc-cache -fv "$CZSH_FONT_DIR" >/dev/null 2>&1 || logWarning "Failed to refresh font cache"
		logSuccess "Font cache updated successfully"
	fi
	echo
}

register_install_feature install_feature_fonts