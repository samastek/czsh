#!/bin/bash

install_feature_neovim() {
	local archive_path="$HOME/.cache/nvim-linux-x86_64.tar.gz"
	local extract_root="/opt"
	local extract_dir="/opt/nvim-linux-x86_64"

	print_section "Neovim Installation" "$FIRE" "$BLUE"

	if command -v nvim >/dev/null 2>&1; then
		logAlreadyInstalled "Neovim"
		echo
		return 0
	fi

	if is_macos; then
		if [[ "$CZSH_PACKAGE_MANAGER" == "brew" ]]; then
			logInstalling "Neovim via Homebrew"
			if brew install neovim >/dev/null 2>&1; then
				logInstalled "Neovim"
			else
				logWarning "Failed to install Neovim with Homebrew"
			fi
		else
			logWarning "Homebrew not available, skipping Neovim installation on macOS"
		fi
		echo
		return 0
	fi

	if [[ "$(uname -m)" != "x86_64" && "$(uname -m)" != "amd64" ]]; then
		logWarning "Skipping Neovim tarball install on unsupported Linux architecture: $(uname -m)"
		echo
		return 0
	fi

	logInstalling "Neovim"
	ensure_directories "$HOME/.cache"
	if curl -L "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz" -o "$archive_path" 2>/dev/null; then
		sudo rm -rf "$extract_dir"
		sudo tar -C "$extract_root" -xzf "$archive_path"
		sudo ln -sf "$extract_dir/bin/nvim" /usr/local/bin/nvim
		rm -f "$archive_path"
		logInstalled "Neovim"
	else
		logWarning "Failed to download Neovim tarball"
		echo
		return 0
	fi

	if [ ! -d "$HOME/.config/nvim" ]; then
		logProgress "Setting up NvChad configuration..."
		git clone --quiet https://github.com/NvChad/starter "$HOME/.config/nvim" 2>/dev/null && nvim --headless +qall 2>/dev/null
	fi
	echo
}

register_install_feature install_feature_neovim