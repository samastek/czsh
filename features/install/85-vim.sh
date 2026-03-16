#!/bin/bash

AMIX_VIMRC_REPO="https://github.com/amix/vimrc.git"
AMIX_VIMRC_DIR="$HOME/.vim_runtime"

install_amix_vimrc() {
	if [ -d "$AMIX_VIMRC_DIR/.git" ]; then
		logUpdating "The Ultimate vimrc"
		if ! git -C "$AMIX_VIMRC_DIR" pull --quiet --rebase 2>/dev/null; then
			logWarning "Failed to update The Ultimate vimrc"
			return 1
		fi
		logUpdated "The Ultimate vimrc"
	else
		logInstalling "The Ultimate vimrc"
		rm -rf "$AMIX_VIMRC_DIR"
		if ! git clone --depth=1 --quiet "$AMIX_VIMRC_REPO" "$AMIX_VIMRC_DIR" 2>/dev/null; then
			logWarning "Failed to clone The Ultimate vimrc"
			return 1
		fi
		logInstalled "The Ultimate vimrc"
	fi

	logProgress "Running The Ultimate vimrc install script..."
	if ! bash "$AMIX_VIMRC_DIR/install_awesome_vimrc.sh" 2>/dev/null; then
		logWarning "Failed to run The Ultimate vimrc install script"
		return 1
	fi

	return 0
}

install_feature_vim() {
	print_section "Vim Configuration" "$PACKAGE" "$GREEN"

	if ! command -v vim >/dev/null 2>&1; then
		logWarning "vim not found — skipping The Ultimate vimrc installation"
		echo
		return 0
	fi

	install_amix_vimrc

	echo
}

register_install_feature install_feature_vim
