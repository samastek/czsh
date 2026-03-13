#!/bin/bash

neovim_asset_name() {
	case "$CZSH_PLATFORM:$CZSH_ARCH" in
	macos:arm64)
		echo "nvim-macos-arm64.tar.gz"
		;;
	macos:x86_64)
		echo "nvim-macos-x86_64.tar.gz"
		;;
	linux:arm64)
		echo "nvim-linux-arm64.tar.gz"
		;;
	linux:x86_64)
		echo "nvim-linux-x86_64.tar.gz"
		;;
	*)
		return 1
		;;
	esac
}

ensure_neovim_copilot_enabled() {
	local nvim_config_dir="$HOME/.config/nvim"
	local plugin_dir="$nvim_config_dir/lua/plugins"
	local copilot_plugin_file="$plugin_dir/copilot.lua"

	if [ ! -d "$plugin_dir" ]; then
		logProgress "Skipping GitHub Copilot plugin bootstrap for non-NvChad Neovim config"
		return 0
	fi

	if [ -f "$copilot_plugin_file" ]; then
		logAlreadyInstalled "GitHub Copilot Neovim plugin"
		return 0
	fi

	logProgress "Enabling GitHub Copilot for Neovim..."
	cat >"$copilot_plugin_file" <<'EOF'
return {
  {
    "github/copilot.vim",
    event = "InsertEnter",
    cmd = "Copilot",
  },
}
EOF
	logInstalled "GitHub Copilot Neovim plugin"
}

setup_neovim_config() {
	local nvim_config_dir="$HOME/.config/nvim"

	if [ ! -d "$nvim_config_dir" ]; then
		logProgress "Setting up NvChad configuration..."
		if ! git clone --quiet https://github.com/NvChad/starter "$nvim_config_dir" 2>/dev/null; then
			logWarning "Failed to clone NvChad starter configuration"
			return 0
		fi
	fi

	ensure_neovim_copilot_enabled

	if command -v nvim >/dev/null 2>&1; then
		nvim --headless +qall 2>/dev/null
	fi
}

install_neovim_release() {
	local repo="neovim/neovim"
	local asset_name=""
	local archive_path=""
	local extract_root="$HOME/.local/share"
	local extract_dir=""
	local tag_name=""

	asset_name="$(neovim_asset_name)"
	if [[ -z "$asset_name" ]]; then
		logWarning "Skipping Neovim installation on unsupported platform: $CZSH_PLATFORM/$CZSH_ARCH"
		return 1
	fi

	tag_name="$(github_latest_release_tag "$repo")"
	if [[ -z "$tag_name" ]]; then
		logWarning "Failed to determine latest Neovim release"
		return 1
	fi

	ensure_directories "$HOME/.cache"
	archive_path="$HOME/.cache/$asset_name"
	extract_dir="$extract_root/${asset_name%.tar.gz}"

	if ! download_github_release_asset "$repo" "$asset_name" "$archive_path" "$tag_name"; then
		logWarning "Failed to download Neovim release asset $asset_name"
		return 1
	fi

	if is_macos && command -v xattr >/dev/null 2>&1; then
		xattr -c "$archive_path" 2>/dev/null || true
	fi

	ensure_directories "$extract_root"
	rm -rf "$extract_dir"

	if ! tar -C "$extract_root" -xzf "$archive_path"; then
		rm -f "$archive_path"
		return 1
	fi

	if is_macos && command -v xattr >/dev/null 2>&1; then
		xattr -cr "$extract_dir" 2>/dev/null || true
	fi

	ensure_directories "$HOME/.local/bin"
	if ! ln -sf "$extract_dir/bin/nvim" "$HOME/.local/bin/nvim"; then
		rm -f "$archive_path"
		return 1
	fi

	rm -f "$archive_path"
	return 0
}

install_feature_neovim() {
	local had_neovim=false
	local neovim_ready=false

	print_section "Neovim Installation" "$FIRE" "$BLUE"

	if command -v nvim >/dev/null 2>&1; then
		had_neovim=true
		logUpdating "Neovim"
	else
		logInstalling "Neovim"
	fi

	if install_neovim_release; then
		if $had_neovim; then
			logUpdated "Neovim"
		else
			logInstalled "Neovim"
		fi
		neovim_ready=true
	elif command -v nvim >/dev/null 2>&1; then
		logWarning "Failed to update Neovim, using existing installation"
		neovim_ready=true
	else
		logWarning "Failed to install Neovim"
		echo
		return 0
	fi

	if $neovim_ready; then
		setup_neovim_config
	fi

	echo
}

register_install_feature install_feature_neovim