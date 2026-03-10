#!/bin/bash

SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

INSTALL_START_TIME=$(date +%s)

COPY_HISTORY_FLAG=false
INTERACTIVE_FLAG=false
ENABLE_CODEX=false
ENABLE_VIM_MODE=false

OH_MY_ZSH_REPO="https://github.com/ohmyzsh/ohmyzsh.git"
POWERLEVEL10K_REPO="https://github.com/romkatv/powerlevel10k.git"
FZF_REPO="https://github.com/junegunn/fzf.git"

PLUGIN_DEFINITIONS=(
	"fzf-tab:https://github.com/Aloxaf/fzf-tab.git"
	"zsh-syntax-highlighting:https://github.com/zsh-users/zsh-syntax-highlighting.git"
	"zsh-autosuggestions:https://github.com/zsh-users/zsh-autosuggestions.git"
	"zsh_codex:https://github.com/samastek/zsh_codex.git"
	"zsh-completions:https://github.com/zsh-users/zsh-completions.git"
	"history-substring-search:https://github.com/zsh-users/zsh-history-substring-search.git"
	"forgit:https://github.com/wfxr/forgit.git"
)

PREREQUISITE_SPECS=(
	"zsh:zsh"
	"git:git"
	"wget:wget"
	"bat|batcat:bat"
	"curl:curl"
	"jq:jq"
	"fc-cache:fontconfig"
	"python3:python3"
)

declare -a MISSING_PACKAGES=()
declare -a CZSH_INSTALL_FEATURES=()

configure_install_paths() {
	CZSH_HOME="$HOME/.config/czsh"
	CZSH_USER_ZSHRC_DIR="$CZSH_HOME/zshrc"
	CZSH_BIN_DIR="$CZSH_HOME/bin"
	CZSH_CACHE_DIR="$HOME/.cache/zsh"
	CZSH_RUNTIME_FEATURES_TARGET_DIR="$CZSH_HOME/features/runtime"
	CZSH_POST_FEATURES_TARGET_DIR="$CZSH_HOME/features/post"
	OH_MY_ZSH_FOLDER="$CZSH_HOME/oh-my-zsh"
	OHMYZSH_CUSTOM_PLUGIN_PATH="$OH_MY_ZSH_FOLDER/custom/plugins"
	OHMYZSH_CUSTOM_THEME_PATH="$OH_MY_ZSH_FOLDER/custom/themes"
	POWERLEVEL_10K_PATH="$OHMYZSH_CUSTOM_THEME_PATH/powerlevel10k"
	FZF_INSTALLATION_PATH="$CZSH_HOME/fzf"

	export CZSH_HOME
	export CZSH_USER_ZSHRC_DIR
	export CZSH_BIN_DIR
	export CZSH_CACHE_DIR
	export CZSH_RUNTIME_FEATURES_TARGET_DIR
	export CZSH_POST_FEATURES_TARGET_DIR
	export OH_MY_ZSH_FOLDER
	export OHMYZSH_CUSTOM_PLUGIN_PATH
	export OHMYZSH_CUSTOM_THEME_PATH
	export POWERLEVEL_10K_PATH
	export FZF_INSTALLATION_PATH
}

show_install_help() {
	cat <<'EOF'
Usage: ./install.sh [options]

Options:
  -h, --help         Show this help message and exit
  -c, --cp-hist      Copy existing shell history into CZSH
  -n, --interactive  Run installer in interactive mode
  -x, --codex        Enable zsh_codex setup
  -v, --vim-mode     Enable vim mode for shell editing

Examples:
  ./install.sh
  ./install.sh --cp-hist --vim-mode
	./install.sh --interactive
EOF
}

parse_args() {
	for arg in "$@"; do
		case "$arg" in
		--help|-h)
			show_install_help
			exit 0
			;;
		--cp-hist|-c)
			COPY_HISTORY_FLAG=true
			;;
		--interactive|-n)
			INTERACTIVE_FLAG=true
			;;
		--codex|-x)
			ENABLE_CODEX=true
			;;
		--vim-mode|-v)
			ENABLE_VIM_MODE=true
			;;
		*)
			echo "Unknown option: $arg" >&2
			show_install_help >&2
			exit 1
			;;
		esac
	done
}

register_install_feature() {
	CZSH_INSTALL_FEATURES+=("$1")
}

load_install_feature_scripts() {
	local script

	for script in "$SCRIPT_DIR"/features/install/*.sh; do
		[ -f "$script" ] || continue
		source "$script"
	done
}

run_install_features() {
	local feature

	for feature in "${CZSH_INSTALL_FEATURES[@]}"; do
		"$feature"
	done
}

ensure_directories() {
	local path

	for path in "$@"; do
		mkdir -p "$path"
	done
}

install_binary() {
	local source_path="$1"
	local target_path="$2"
	local target_dir

	target_dir="$(dirname "$target_path")"
	if [ -w "$target_dir" ]; then
		install -m 0755 "$source_path" "$target_path"
	else
		sudo install -m 0755 "$source_path" "$target_path"
	fi
}

github_latest_release_tag() {
	local repo="$1"
	local api_url="https://api.github.com/repos/$repo/releases/latest"
	local response=""

	response="$(curl -fsSL "$api_url" 2>/dev/null)" || return 1
	printf '%s\n' "$response" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1
}

version_without_v() {
	printf '%s\n' "${1#v}"
}

download_github_release_asset() {
	local repo="$1"
	local asset_name="$2"
	local destination_path="$3"
	local tag_name="${4:-}"
	local download_url=""

	if [[ -z "$tag_name" ]]; then
		tag_name="$(github_latest_release_tag "$repo")" || return 1
	fi

	download_url="https://github.com/$repo/releases/download/$tag_name/$asset_name"
	curl -fsSL "$download_url" -o "$destination_path" 2>/dev/null
}

install_github_release_binary() {
	local repo="$1"
	local asset_name="$2"
	local target_path="$3"
	local tag_name="${4:-}"
	local archive_path="$HOME/.cache/$asset_name"
	local status=0

	ensure_directories "$HOME/.cache"

	if ! download_github_release_asset "$repo" "$asset_name" "$archive_path" "$tag_name"; then
		return 1
	fi

	if ! install_binary "$archive_path" "$target_path"; then
		status=1
	fi

	rm -f "$archive_path"
	return "$status"
}

install_github_tarball_binary() {
	local repo="$1"
	local asset_name="$2"
	local binary_name="$3"
	local target_path="$4"
	local tag_name="${5:-}"
	local archive_path="$HOME/.cache/$asset_name"
	local extract_dir=""
	local source_path=""
	local status=0

	ensure_directories "$HOME/.cache"
	extract_dir="$(mktemp -d "${TMPDIR:-/tmp}/czsh.XXXXXX")" || return 1

	if ! download_github_release_asset "$repo" "$asset_name" "$archive_path" "$tag_name"; then
		rm -rf "$extract_dir"
		return 1
	fi

	if ! tar -xzf "$archive_path" -C "$extract_dir" >/dev/null 2>&1; then
		rm -f "$archive_path"
		rm -rf "$extract_dir"
		return 1
	fi

	source_path="$(find "$extract_dir" -type f -name "$binary_name" | head -n 1)"
	if [[ -z "$source_path" ]]; then
		rm -f "$archive_path"
		rm -rf "$extract_dir"
		return 1
	fi

	if ! install_binary "$source_path" "$target_path"; then
		status=1
	fi

	rm -f "$archive_path"
	rm -rf "$extract_dir"
	return "$status"
}

append_unique_package() {
	local package="$1"
	local existing

	for existing in "${MISSING_PACKAGES[@]}"; do
		if [[ "$existing" == "$package" ]]; then
			return 0
		fi
	done

	MISSING_PACKAGES+=("$package")
}

has_any_command() {
	local command_group="$1"
	local command_name

	IFS='|' read -r -a command_names <<<"$command_group"
	for command_name in "${command_names[@]}"; do
		if command -v "$command_name" >/dev/null 2>&1; then
			return 0
		fi
	done

	return 1
}

detect_missing_packages() {
	local specs=("${PREREQUISITE_SPECS[@]}")
	local spec command_spec package_name

	if is_linux; then
		specs+=("pip3:python3-pip")
	else
		specs+=("pip3:python3")
	fi

	MISSING_PACKAGES=()

	for spec in "${specs[@]}"; do
		command_spec="${spec%%:*}"
		package_name="${spec#*:}"

		if ! has_any_command "$command_spec"; then
			append_unique_package "$package_name"
		fi
	done
}

perform_system_update() {
	print_section "System Update" "$ZAPP" "$BLUE"

	if [[ -z "$CZSH_PACKAGE_MANAGER" ]]; then
		logWarning "No supported package manager detected. Skipping package index update."
		echo
		return 0
	fi

	logProgress "Updating package metadata for $CZSH_PACKAGE_MANAGER..."
	if package_manager_update >/dev/null 2>&1; then
		logSuccess "System updated successfully"
	else
		logWarning "System update failed, continuing with installation"
	fi
	echo
}

install_missing_packages() {
	local package_count=0
	local total_packages=${#MISSING_PACKAGES[@]}
	local package

	if [ "$total_packages" -eq 0 ]; then
		logSuccess "All required packages are already installed!"
		return 0
	fi

	print_section "Package Installation" "$PACKAGE" "$YELLOW"
	logWarning "Missing packages detected: ${MISSING_PACKAGES[*]}"

	perform_system_update

	for package in "${MISSING_PACKAGES[@]}"; do
		((package_count++))
		logStepProgress "$package_count" "$total_packages" "Installing $package"
		if package_manager_install "$package" >/dev/null 2>&1; then
			logInstalled "$package"
		else
			logErrorWithSuggestion "Failed to install $package" "Install it manually using your system package manager and re-run install.sh"
			exit 1
		fi
		echo
	done
}

backup_existing_zshrc_config() {
	print_section "Configuration Backup" "$FOLDER" "$YELLOW"
	if [ -f "$HOME/.zshrc" ]; then
		local backup_file="$HOME/.zshrc-backup-$(date +"%Y-%m-%d-%H%M%S")"
		if mv "$HOME/.zshrc" "$backup_file"; then
			logSuccess "Backed up existing .zshrc to $(basename "$backup_file")"
		else
			logWarning "Failed to backup existing .zshrc"
		fi
	else
		logInfo "No existing .zshrc found, skipping backup"
	fi
	echo
}

configure_ohmyzsh() {
	print_section "Oh My Zsh Setup" "$STAR" "$GREEN"

	if [ -d "$OH_MY_ZSH_FOLDER" ]; then
		logAlreadyInstalled "oh-my-zsh"
		logUpdating "oh-my-zsh"
		git -C "$OH_MY_ZSH_FOLDER" remote set-url origin "$OH_MY_ZSH_REPO"
		export ZSH="$OH_MY_ZSH_FOLDER"
		if git -C "$OH_MY_ZSH_FOLDER" pull --quiet 2>/dev/null; then
			logUpdated "oh-my-zsh"
		else
			logWarning "Failed to update oh-my-zsh, but continuing..."
		fi
	elif [ -d "$HOME/.oh-my-zsh" ]; then
		logProgress "Moving existing oh-my-zsh into $OH_MY_ZSH_FOLDER"
		mv "$HOME/.oh-my-zsh" "$OH_MY_ZSH_FOLDER"
		git -C "$OH_MY_ZSH_FOLDER" remote set-url origin "$OH_MY_ZSH_REPO"
		export ZSH="$OH_MY_ZSH_FOLDER"
		if git -C "$OH_MY_ZSH_FOLDER" pull --quiet 2>/dev/null; then
			logSuccess "oh-my-zsh moved and updated successfully"
		else
			logSuccess "oh-my-zsh moved successfully"
		fi
	else
		logInstalling "oh-my-zsh"
		git clone --depth=1 --quiet "$OH_MY_ZSH_REPO" "$OH_MY_ZSH_FOLDER"
		export ZSH="$OH_MY_ZSH_FOLDER"
		logInstalled "oh-my-zsh"
	fi
	echo
}

sync_runtime_features() {
	ensure_directories "$CZSH_RUNTIME_FEATURES_TARGET_DIR" "$CZSH_POST_FEATURES_TARGET_DIR"
	cp -R "$SCRIPT_DIR/features/runtime/." "$CZSH_RUNTIME_FEATURES_TARGET_DIR/"
	cp -R "$SCRIPT_DIR/features/post/." "$CZSH_POST_FEATURES_TARGET_DIR/"
}

copy_base_configuration_files() {
	print_section "Configuration Files" "$GEAR" "$BLUE"
	logProgress "Copying configuration files and feature modules..."

	cp -f "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
	cp -f "$SCRIPT_DIR/czshrc.zsh" "$CZSH_HOME/czshrc.zsh"
	sync_runtime_features

	ensure_directories "$CZSH_USER_ZSHRC_DIR" "$CZSH_CACHE_DIR" "$CZSH_BIN_DIR" "$CZSH_FONT_DIR"

	if compgen -G "$HOME/.zcompdump*" >/dev/null 2>&1; then
		logProgress "Moving zsh completion cache files..."
		command mv -f "$HOME/.zcompdump"* "$CZSH_CACHE_DIR/"
		logSuccess "Moved completion cache files to $CZSH_CACHE_DIR"
	fi

	logSuccess "Configuration files copied successfully"
	echo
}

prompt_secret() {
	local prompt="$1"
	local secret_value=""

	if [ "$INTERACTIVE_FLAG" != true ]; then
		echo ""
		return 0
	fi

	read -r -s -p "$(printf "%b" "$prompt")" secret_value
	echo
	echo "$secret_value"
}

prompt_choice() {
	local prompt="$1"
	local fallback="$2"
	local choice=""

	if [ "$INTERACTIVE_FLAG" != true ]; then
		echo "$fallback"
		return 0
	fi

	read -r -p "$(printf "%b" "$prompt")" choice
	if [[ -z "$choice" ]]; then
		choice="$fallback"
	fi
	echo "$choice"
}

finish_installation() {
	local end_time

	end_time=$(date +%s)

	print_header "Installation Complete!" "$GREEN" "$BG_GREEN"
	logSuccess "CZSH installation completed successfully."
	print_installation_summary "$INSTALL_START_TIME" "$end_time"

	if [ "$INTERACTIVE_FLAG" = true ]; then
		logInfo "Interactive mode enabled. Run 'chsh -s $(which zsh)' if you want zsh as the default shell."
		logTip "Open a new shell and run 'build-fzf-tab-module' if you use the fzf-tab plugin."
	else
		printf "${GREEN}${BOLD}Installation finished. Open a new terminal session to start using CZSH.${RESET}\n"
	fi
}