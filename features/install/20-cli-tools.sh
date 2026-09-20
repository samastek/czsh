#!/bin/bash

install_pinned_tar_tool() {
	local command_name="$1"
	local display_name="$2"
	local repo="$3"
	local asset_name="$4"
	local binary_name="$5"
	local version="$6"
	local tag_name="$7"

	if command -v "$command_name" >/dev/null 2>&1 && [[ "$UPGRADE_TOOLS" != true ]]; then
		logAlreadyInstalled "$display_name"
		return 0
	fi

	if command -v "$command_name" >/dev/null 2>&1; then
		logUpdating "$display_name to $version"
	else
		logInstalling "$display_name $version"
	fi

	if install_github_tarball_binary "$repo" "$asset_name" "$binary_name" \
		"$HOME/.local/bin/$command_name" "$tag_name"; then
		logInstalled "$display_name $version"
	else
		logWarning "Failed to install $display_name release asset $asset_name"
		return 1
	fi
}

install_yazi_release() {
	local target="$1"
	local asset_name="yazi-${target}.zip"
	local tag_name="v$YAZI_VERSION"
	local archive_path="$HOME/.cache/$asset_name"
	local extract_dir=""
	local binary=""

	if command -v yazi >/dev/null 2>&1 && [[ "$UPGRADE_TOOLS" != true ]]; then
		logAlreadyInstalled "Yazi"
		return 0
	fi

	logInstalling "Yazi $YAZI_VERSION"
	ensure_directories "$HOME/.cache" "$HOME/.local/bin"
	extract_dir="$(mktemp -d "${TMPDIR:-/tmp}/czsh-yazi.XXXXXX")" || return 1

	if ! download_github_release_asset "sxyazi/yazi" "$asset_name" "$archive_path" "$tag_name" || \
		! unzip -q "$archive_path" -d "$extract_dir"; then
		logWarning "Failed to download or extract $asset_name"
		rm -f "$archive_path"
		rm -rf "$extract_dir"
		return 1
	fi

	for binary in yazi ya; do
		local source_path
		source_path="$(find "$extract_dir" -type f -name "$binary" | head -n 1)"
		if [[ -z "$source_path" ]] || ! install_binary "$source_path" "$HOME/.local/bin/$binary"; then
			logWarning "Yazi archive did not contain $binary"
			rm -f "$archive_path"
			rm -rf "$extract_dir"
			return 1
		fi
	done

	rm -f "$archive_path"
	rm -rf "$extract_dir"
	logInstalled "Yazi $YAZI_VERSION"
}

install_feature_cli_tools() {
	local atuin_target=""
	local zoxide_target=""
	local delta_target=""
	local eza_asset=""
	local yazi_target=""

	print_section "Modern CLI Tools" "$PACKAGE" "$CYAN"

	# Homebrew owns these tools on macOS; the pinned release path is used on
	# Linux where several packages are missing from older distro repositories.
	if is_macos; then
		logInfo "Modern CLI tools are managed by packages/Brewfile on macOS"
	else
		case "$CZSH_ARCH" in
		x86_64)
			atuin_target="x86_64-unknown-linux-gnu"
			zoxide_target="x86_64-unknown-linux-musl"
			delta_target="x86_64-unknown-linux-gnu"
			eza_asset="eza_x86_64-unknown-linux-gnu.tar.gz"
			yazi_target="x86_64-unknown-linux-gnu"
			;;
		arm64)
			atuin_target="aarch64-unknown-linux-gnu"
			zoxide_target="aarch64-unknown-linux-musl"
			delta_target="aarch64-unknown-linux-gnu"
			eza_asset="eza_aarch64-unknown-linux-gnu.tar.gz"
			yazi_target="aarch64-unknown-linux-gnu"
			;;
		*)
			logWarning "Pinned modern CLI releases are unavailable for $CZSH_ARCH"
			echo
			return 0
			;;
		esac

		install_pinned_tar_tool atuin Atuin atuinsh/atuin \
			"atuin-${atuin_target}.tar.gz" atuin "$ATUIN_VERSION" "v$ATUIN_VERSION" || true
		install_pinned_tar_tool zoxide Zoxide ajeetdsouza/zoxide \
			"zoxide-${ZOXIDE_VERSION}-${zoxide_target}.tar.gz" zoxide "$ZOXIDE_VERSION" "v$ZOXIDE_VERSION" || true
		install_pinned_tar_tool delta Delta dandavison/delta \
			"delta-${DELTA_VERSION}-${delta_target}.tar.gz" delta "$DELTA_VERSION" "$DELTA_VERSION" || true
		install_pinned_tar_tool eza Eza eza-community/eza \
			"$eza_asset" eza "$EZA_VERSION" "v$EZA_VERSION" || true
		install_yazi_release "$yazi_target" || true
	fi

	# Debian names these binaries differently. Stable command names keep the
	# runtime and documented aliases portable.
	if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
		ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
	fi
	if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
		ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
	fi

	echo
}

register_install_feature install_feature_cli_tools
