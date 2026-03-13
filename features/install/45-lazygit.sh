#!/bin/bash

lazygit_asset_name() {
	local version="$1"

	case "$CZSH_PLATFORM:$CZSH_ARCH" in
	macos:arm64)
		echo "lazygit_${version}_darwin_arm64.tar.gz"
		;;
	macos:x86_64)
		echo "lazygit_${version}_darwin_x86_64.tar.gz"
		;;
	linux:arm64)
		echo "lazygit_${version}_linux_arm64.tar.gz"
		;;
	linux:armv6)
		echo "lazygit_${version}_linux_armv6.tar.gz"
		;;
	linux:x86)
		echo "lazygit_${version}_linux_32-bit.tar.gz"
		;;
	linux:x86_64)
		echo "lazygit_${version}_linux_x86_64.tar.gz"
		;;
	*)
		return 1
		;;
	esac
}

install_feature_lazygit() {
	local had_lazygit=false
	local tag_name=""
	local version=""
	local asset_name=""

	print_section "Lazygit Installation" "$PACKAGE" "$CYAN"

	if command -v lazygit >/dev/null 2>&1; then
		had_lazygit=true
		logUpdating "Lazygit"
	else
		logInstalling "Lazygit"
	fi

	tag_name="$(github_latest_release_tag "jesseduffield/lazygit")"
	if [[ -z "$tag_name" ]]; then
		logWarning "Failed to determine latest Lazygit release"
		echo
		return 0
	fi

	version="$(version_without_v "$tag_name")"
	asset_name="$(lazygit_asset_name "$version")"
	if [[ -z "$asset_name" ]]; then
		logWarning "Skipping Lazygit installation on unsupported platform: $CZSH_PLATFORM/$CZSH_ARCH"
		echo
		return 0
	fi

	if install_github_tarball_binary "jesseduffield/lazygit" "$asset_name" "lazygit" "$HOME/.local/bin/lazygit" "$tag_name"; then
		if $had_lazygit; then
			logUpdated "Lazygit"
		else
			logInstalled "Lazygit"
		fi
	else
		logWarning "Failed to install Lazygit release asset $asset_name"
	fi

	echo
}

register_install_feature install_feature_lazygit