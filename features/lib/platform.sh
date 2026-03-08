#!/bin/bash

detect_package_manager() {
	if command -v brew >/dev/null 2>&1; then
		CZSH_PACKAGE_MANAGER="brew"
	elif command -v apt-get >/dev/null 2>&1; then
		CZSH_PACKAGE_MANAGER="apt"
	elif command -v pacman >/dev/null 2>&1; then
		CZSH_PACKAGE_MANAGER="pacman"
	elif command -v dnf >/dev/null 2>&1; then
		CZSH_PACKAGE_MANAGER="dnf"
	elif command -v yum >/dev/null 2>&1; then
		CZSH_PACKAGE_MANAGER="yum"
	elif command -v pkg >/dev/null 2>&1; then
		CZSH_PACKAGE_MANAGER="pkg"
	else
		CZSH_PACKAGE_MANAGER=""
	fi
}

detect_platform() {
	case "$OSTYPE" in
	darwin*)
		CZSH_PLATFORM="macos"
		CZSH_FONT_DIR="$HOME/Library/Fonts"
		;;
	linux*)
		CZSH_PLATFORM="linux"
		CZSH_FONT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
		;;
	*)
		CZSH_PLATFORM="unknown"
		CZSH_FONT_DIR="$HOME/.local/share/fonts"
		;;
	esac

	detect_package_manager

	export CZSH_PLATFORM
	export CZSH_FONT_DIR
	export CZSH_PACKAGE_MANAGER
}

is_macos() {
	[[ "$CZSH_PLATFORM" == "macos" ]]
}

is_linux() {
	[[ "$CZSH_PLATFORM" == "linux" ]]
}

package_manager_update() {
	case "$CZSH_PACKAGE_MANAGER" in
	brew)
		brew update
		;;
	apt)
		sudo apt-get update
		;;
	pacman)
		sudo pacman -Sy
		;;
	dnf)
		sudo dnf check-update
		;;
	yum)
		sudo yum check-update
		;;
	pkg)
		pkg update
		;;
	*)
		return 1
		;;
	esac
}

package_manager_install() {
	local package="$1"

	case "$CZSH_PACKAGE_MANAGER" in
	brew)
		brew install "$package"
		;;
	apt)
		sudo apt-get install -y "$package"
		;;
	pacman)
		sudo pacman -S --noconfirm "$package"
		;;
	dnf)
		sudo dnf install -y "$package"
		;;
	yum)
		sudo yum install -y "$package"
		;;
	pkg)
		pkg install -y "$package"
		;;
	*)
		return 1
		;;
	esac
}