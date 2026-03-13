#!/bin/bash

lazyjournal_asset_name() {
	local tag_name="$1"
	local version="$tag_name"

	case "$CZSH_PLATFORM:$CZSH_ARCH" in
	macos:arm64)
		echo "lazyjournal-${version}-darwin-arm64"
		;;
	macos:x86_64)
		echo "lazyjournal-${version}-darwin-amd64"
		;;
	linux:arm64)
		echo "lazyjournal-${version}-linux-arm64"
		;;
	linux:x86_64)
		echo "lazyjournal-${version}-linux-amd64"
		;;
	*)
		return 1
		;;
	esac
}

install_feature_lazyjournal() {
	local had_lazyjournal=false
	local tag_name=""
	local asset_name=""

	print_section "Lazyjournal Installation" "$PACKAGE" "$CYAN"

	if ! is_linux; then
		logInfo "Skipping Lazyjournal on $CZSH_PLATFORM. Lazyjournal is only enabled on Linux systems with journald."
		echo
		return 0
	fi

	if ! command -v journalctl >/dev/null 2>&1; then
		logInfo "Skipping Lazyjournal because journalctl is not available on this system"
		echo
		return 0
	fi

	if command -v lazyjournal >/dev/null 2>&1; then
		had_lazyjournal=true
		logUpdating "Lazyjournal"
	else
		logInstalling "Lazyjournal"
	fi

	tag_name="$(github_latest_release_tag "Lifailon/lazyjournal")"
	if [[ -z "$tag_name" ]]; then
		logWarning "Failed to determine latest Lazyjournal release"
		echo
		return 0
	fi

	asset_name="$(lazyjournal_asset_name "$tag_name")"
	if [[ -z "$asset_name" ]]; then
		logWarning "Skipping Lazyjournal installation on unsupported platform: $CZSH_PLATFORM/$CZSH_ARCH"
		echo
		return 0
	fi

	if install_github_release_binary "Lifailon/lazyjournal" "$asset_name" "$HOME/.local/bin/lazyjournal" "$tag_name"; then
		if $had_lazyjournal; then
			logUpdated "Lazyjournal"
		else
			logInstalled "Lazyjournal"
		fi
	else
		logWarning "Failed to install Lazyjournal release asset $asset_name"
	fi

	echo
}

register_install_feature install_feature_lazyjournal