#!/usr/bin/env bash
# Central paths & repo constants

CZSH_ROOT_DIR="${CZSH_ROOT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
CZSH_CONFIG_DIR="$HOME/.config/czsh"
CZSH_ZSHRC_DIR="$CZSH_CONFIG_DIR/zshrc"
CZSH_CACHE_DIR="$HOME/.cache/zsh"
CZSH_BIN_DIR="$CZSH_CONFIG_DIR/bin"
CZSH_FONTS_DIR="$HOME/.fonts"

OH_MY_ZSH_FOLDER="$CZSH_CONFIG_DIR/oh-my-zsh"
OHMYZSH_CUSTOM_PLUGIN_PATH="$OH_MY_ZSH_FOLDER/custom/plugins"
OHMYZSH_CUSTOM_THEME_PATH="$OH_MY_ZSH_FOLDER/custom/themes"

# Repos
REPO_OHMYZSH="https://github.com/ohmyzsh/ohmyzsh.git"
REPO_POWERLEVEL10K="https://github.com/romkatv/powerlevel10k.git"
REPO_FZF="https://github.com/junegunn/fzf.git"
REPO_LAZYDOCKER="https://github.com/jesseduffield/lazydocker.git"

# Component registry file (generated/extended by modules)
CZSH_COMPONENT_REGISTRY_FILE="${CZSH_COMPONENT_REGISTRY_FILE:-$CZSH_ROOT_DIR/modules/registry.sh}"
