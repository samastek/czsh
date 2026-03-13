#!/bin/bash

lazydocker_asset_name() {
	local version="$1"

	case "$CZSH_PLATFORM:$CZSH_ARCH" in
	macos:arm64)
		echo "lazydocker_${version}_Darwin_arm64.tar.gz"
		;;
	macos:x86_64)
		echo "lazydocker_${version}_Darwin_x86_64.tar.gz"
		;;
	linux:arm64)
		echo "lazydocker_${version}_Linux_arm64.tar.gz"
		;;
	linux:armv6)
		echo "lazydocker_${version}_Linux_armv6.tar.gz"
		;;
	linux:armv7)
		echo "lazydocker_${version}_Linux_armv7.tar.gz"
		;;
	linux:x86)
		echo "lazydocker_${version}_Linux_x86.tar.gz"
		;;
	linux:x86_64)
		echo "lazydocker_${version}_Linux_x86_64.tar.gz"
		;;
	*)
		return 1
		;;
	esac
}

install_feature_lazydocker() {
	local had_lazydocker=false
	local tag_name=""
	local version=""
	local asset_name=""

	print_section "Lazydocker Installation" "$GEAR" "$CYAN"

	if command -v lazydocker >/dev/null 2>&1; then
		had_lazydocker=true
		logUpdating "Lazydocker"
	else
		logInstalling "Lazydocker"
	fi

	tag_name="$(github_latest_release_tag "jesseduffield/lazydocker")"
	if [[ -z "$tag_name" ]]; then
		logWarning "Failed to determine latest Lazydocker release"
		echo
		return 0
	fi

	version="$(version_without_v "$tag_name")"
	asset_name="$(lazydocker_asset_name "$version")"
	if [[ -z "$asset_name" ]]; then
		logWarning "Skipping Lazydocker installation on unsupported platform: $CZSH_PLATFORM/$CZSH_ARCH"
		echo
		return 0
	fi

	if install_github_tarball_binary "jesseduffield/lazydocker" "$asset_name" "lazydocker" "$HOME/.local/bin/lazydocker" "$tag_name"; then
		if $had_lazydocker; then
			logUpdated "Lazydocker"
		else
			logInstalled "Lazydocker"
		fi
	else
		logWarning "Failed to install Lazydocker release asset $asset_name"
	fi

	echo
}

register_install_feature install_feature_lazydocker