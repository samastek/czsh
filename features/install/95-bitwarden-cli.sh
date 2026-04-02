#!/bin/bash

bw_cli_asset_name() {
	local version="$1"

	case "$CZSH_PLATFORM:$CZSH_ARCH" in
	macos:arm64)
		echo "bw-macos-arm64-${version}.zip"
		;;
	macos:x86_64)
		echo "bw-macos-${version}.zip"
		;;
	linux:arm64)
		echo "bw-linux-arm64-${version}.zip"
		;;
	linux:x86_64)
		echo "bw-linux-${version}.zip"
		;;
	*)
		return 1
		;;
	esac
}

install_feature_bitwarden_cli() {
	local had_bw=false
	local tag_name=""
	local version=""
	local asset_name=""

	print_section "Bitwarden CLI Installation" "$PACKAGE" "$CYAN"

	if command -v bw >/dev/null 2>&1; then
		had_bw=true
		logUpdating "Bitwarden CLI"
	else
		logInstalling "Bitwarden CLI"
	fi

	tag_name="$(github_latest_release_tag_matching "bitwarden/clients" "cli-v")"
	if [[ -z "$tag_name" ]]; then
		logWarning "Failed to determine latest Bitwarden CLI release"
		echo
		return 0
	fi

	# Strip "cli-v" prefix to get the bare version number
	version="${tag_name#cli-v}"
	asset_name="$(bw_cli_asset_name "$version")"
	if [[ -z "$asset_name" ]]; then
		logWarning "Skipping Bitwarden CLI installation on unsupported platform: $CZSH_PLATFORM/$CZSH_ARCH"
		echo
		return 0
	fi

	if install_github_zip_binary "bitwarden/clients" "$asset_name" "bw" "$HOME/.local/bin/bw" "$tag_name"; then
		if $had_bw; then
			logUpdated "Bitwarden CLI"
		else
			logInstalled "Bitwarden CLI"
		fi
	else
		logWarning "Failed to install Bitwarden CLI release asset $asset_name"
	fi

	echo
}

register_install_feature install_feature_bitwarden_cli
