#!/bin/bash

##########################################################
###################### SOURCE FILES ######################
##########################################################
source ./utils.sh
##########################################################

cp_hist_flag=false
noninteractive_flag=true
zsh_codex_flag=false

OH_MY_ZSH_FOLDER="$HOME/.config/czsh/oh-my-zsh"
OHMYZSH_CUSTOM_PLUGIN_PATH="$OH_MY_ZSH_FOLDER/custom/plugins"
OHMYZSH_CUSTOM_THEME_PATH="$OH_MY_ZSH_FOLDER/custom/themes"

#############################################################################################
######################################### VARIABLES #########################################
#############################################################################################

OH_MY_ZSHR_REPO="https://github.com/ohmyzsh/ohmyzsh.git"
POWERLEVEL10K_REPO="https://github.com/romkatv/powerlevel10k.git"
POWERLEVEL_10K_PATH=$OHMYZSH_CUSTOM_THEME_PATH/powerlevel10k

FZF_REPO="https://github.com/junegunn/fzf.git"
LAZYDOCKER_REPO="https://github.com/jesseduffield/lazydocker.git"
FZF_INSTALLATION_PATH=$HOME/.config/czsh/fzf    
LAZYDOCKER_INSTALLATION_PATH=$HOME/.config/czsh/lazydocker

declare -A PLUGINS_MAP
PLUGINS_MAP=(
    ["fzf-tab"]="https://github.com/Aloxaf/fzf-tab.git"
    ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions.git"
    ["zsh_codex"]="https://github.com/samastek/zsh_codex.git"
    ["zsh-completions"]="https://github.com/zsh-users/zsh-completions.git"
    ["history-substring-search"]="https://github.com/zsh-users/zsh-history-substring-search.git"
    ["forgit"]="https://github.com/wfxr/forgit.git"
)

# Loop through all arguments
for arg in "$@"; do
    case $arg in
    --cp-hist | -c)
        cp_hist_flag=true
        ;;
    --interactive | -n)
        noninteractive_flag=false
        ;;
    --codex | -x)
        zsh_codex_flag=true
        ;;
    *)
        ;;
    esac
done

#############################################################################################
####################################### FUNCTIONS #########################################
#############################################################################################

prerequists=("zsh" "git" "wget" "bat" "curl" "python3" "fontconfig")
missing_packages=()

detect_missing_packages() {
    for package in "${prerequists[@]}"; do
        if ! command -v "$package" &>/dev/null; then
            missing_packages+=("$package")
        fi
    done
}

perform_update() {
    if brew update; then
        logInfo "System updated\n"
    else
        logError "System update failed\n"
    fi
}

install_missing_packages() {
    perform_update
    for package in "${missing_packages[@]}"; do
        if brew install "$package"; then
            logInfo "$package Installed\n"
        else
            logWarning "🚨 Please install the following packages first, then try again: $package 🚨" && exit
        fi
    done
}

backup_existing_zshrc_config() {
    if [ -f "$HOME/.zshrc" ]; then
        mv "$HOME/.zshrc" "$HOME/.zshrc-backup-$(date +"%Y-%m-%d")"
        logInfo "Backed up the current .zshrc to .zshrc-backup-date\n"
    fi
}

configure_ohmyzsh() {
    if [ -d "$OH_MY_ZSH_FOLDER" ]; then
        logInfo "✅ oh-my-zsh is already installed\n"
        git -C "$OH_MY_ZSH_FOLDER" remote set-url origin "$OH_MY_ZSHR_REPO"
        export ZSH=$OH_MY_ZSH_FOLDER;
        git -C "$OH_MY_ZSH_FOLDER" pull
    elif [ -d "$HOME/.oh-my-zsh" ]; then
        logProgress "⏳ Moving existing oh-my-zsh to '$OH_MY_ZSH_FOLDER'"
        mv "$HOME/.oh-my-zsh" "$OH_MY_ZSH_FOLDER"
        export ZSH=$OH_MY_ZSH_FOLDER;
        git -C "$OH_MY_ZSH_FOLDER" remote set-url origin "$OH_MY_ZSHR_REPO"
        git -C "$OH_MY_ZSH_FOLDER" pull
    else
        git clone --depth=1 "$OH_MY_ZSHR_REPO" "$OH_MY_ZSH_FOLDER"
        export ZSH=$OH_MY_ZSH_FOLDER;
    fi
}

configure_zsh_codex() {
    logProgress "Configuring zsh_codex\n"
    cp openaiapirc "$HOME/.config/"
    read -s -p "Enter your OpenAI API key: " OPENAI_API_KEY
    sed -i "" "s/TOBEREPLEACED/$OPENAI_API_KEY/g" "$HOME/.config/openaiapirc"
    pip3 install openai
}

# Additional functions remain mostly the same

#############################################################################################
####################################### MAIN SCRIPT #########################################
#############################################################################################

detect_missing_packages
install_missing_packages
backup_existing_zshrc_config

logInfo "The setup will be installed in '$HOME/.config/czsh'\n"
logWarning "Place your personal zshrc config files under '$HOME/.config/czsh/zshrc/'\n"

mkdir -p "$HOME/.config/czsh/zshrc"
logInfo "Installing oh-my-zsh\n"
configure_ohmyzsh

# Copy base configuration files
cp -f ./.zshrc "$HOME/"
cp -f ./czshrc.zsh "$HOME/.config/czsh/"

mkdir -p "$HOME/.cache/zsh/"  # for zsh completion cache
mkdir -p "$HOME/.fonts"        # Create .fonts if doesn't exist

finish_installation
