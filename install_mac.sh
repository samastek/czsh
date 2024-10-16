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
POWERLEVEL_10K_PATH=$OHMYZSH_CUSTOM_THEME_PATH/powerlevel10k

FZF_INSTALLATION_PATH=$HOME/.config/czsh/fzf    
LAZYDOCKER_INSTALLATION_PATH=$HOME/.config/czsh/lazydocker

declare -A PLUGINS_MAP

export PLUGINS_MAP=(
    ["fzf-tab"]="https://github.com/Aloxaf/fzf-tab.git"
    ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions.git"
    ["zsh_codex"]="https://github.com/samastek/zsh_codex.git"
    ["zsh-completions"]="https://github.com/zsh-users/zsh-completions.git"
    ["history-substring-search"]="https://github.com/zsh-users/zsh-history-substring-search.git"
    ["forgit"]="https://github.com/wfxr/forgit.git"
)

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

prerequists=("zsh" "git" "wget" "bat" "curl" "python3-pip" "fontconfig")
missing_packages=()

detect_missing_packages() {
    for package in "${prerequists[@]}"; do
        if ! command -v "$package" &>/dev/null; then
            missing_packages+=("$package")
        fi
    done
}

perform_update() {
    if brew update || sudo apt update || sudo pacman -Sy || sudo dnf check-update || sudo yum check-update || pkg update; then
        logInfo "System updated\n"
    else
        logError "System update failed\n"
    fi
}

setup_plugins(){
    for PLUGIN_NAME in "${!PLUGINS_MAP[@]}"; do
         PLUGIN_PATH="$OHMYZSH_CUSTOM_PLUGIN_PATH/$PLUGIN_NAME"
         if [ -d "$PLUGIN_PATH" ]; then
              logInfo "✅ $PLUGIN_NAME plugin is already installed"
              git -C "$PLUGIN_PATH" pull
         else
              PLUGIN_REPO_LINK="${PLUGINS_MAP[$PLUGIN_NAME]}"
              git clone --depth=1 "$PLUGIN_REPO_LINK" "$PLUGIN_PATH"
              logInfo "✅ $PLUGIN_NAME plugin installed"
         fi
    done
}

install_missing_packages() {
    perform_update
    for package in "${missing_packages[@]}"; do
        if brew install "$package" || sudo apt install -y "$package" || sudo pacman -S "$package" || sudo dnf install -y "$package" || sudo yum install -y "$package" || pkg install "$package"; then
            logInfo "$package Installed\n"
        else
            logWarning "🚨 Please install the following packages first, then try again: $package 🚨" && exit
        fi
    done
}

backup_existing_zshrc_config() {
    if mv -n $HOME/.zshrc $HOME/.zshrc-backup-"$(date +"%Y-%m-%d")"; then
        logInfo -e "Backed up the current .zshrc to .zshrc-backup-date\n"
    fi
}

configure_ohmzsh() {
    if [ -d "$OH_MY_ZSH_FOLDER" ]; then
        logInfo "✅ oh-my-zsh is already installed\n"
        git -C "$OH_MY_ZSH_FOLDER" remote set-url origin "$OH_MY_ZSHR_REPO"
        export ZSH=$OH_MY_ZSH_FOLDER;
        git -C "$OH_MY_ZSH_FOLDER" pull
    elif [ -d "$HOME/.oh-my-zsh" ]; then
        logProgress "⏳ oh-my-zsh is already installed at '$HOME/.oh-my-zsh'. Moving it to '$HOME/.config/czsh/oh-my-zsh'"
        export ZSH=$OH_MY_ZSH_FOLDER;
        mv "$HOME/.oh-my-zsh" "$OH_MY_ZSH_FOLDER"
        git -C "$OH_MY_ZSH_FOLDER" remote set-url origin "$OH_MY_ZSHR_REPO"
        git -C "$OH_MY_ZSH_FOLDER" pull
    else
        git clone --depth=1 $OH_MY_ZSHR_REPO "$OH_MY_ZSH_FOLDER"
        export ZSH=$OH_MY_ZSH_FOLDER;
    fi
}

configure_zsh_codex() {
    logProgress "configuring zsh_codex\n"
    cp openaiapirc $HOME/.config/

    read -s -p "Enter your openai api key: "
    OPENAI_API_KEY=$REPLY

    sed -i "s/TOBEREPLEACED/$OPENAI_API_KEY/g" $HOME/.config/openaiapirc
    pip3 install openai --break-system-packages
}

install_fzf() {
    if [ -d $FZF_INSTALLATION_PATH ]; then
        git -C $FZF_INSTALLATION_PATH pull
        $FZF_INSTALLATION_PATH/install --all --key-bindings --completion --no-update-rc
    else
        git clone --depth 1 $FZF_REPO $FZF_INSTALLATION_PATH
        "$FZF_INSTALLATION_PATH"/install --all --key-bindings --completion --no-update-rc
    fi
}

install_powerlevel10k() {
    if [ -d "$POWERLEVEL_10K_PATH" ]; then
        git -C "$POWERLEVEL_10K_PATH" pull
    else
        git clone --depth=1 $POWERLEVEL10K_REPO "$POWERLEVEL_10K_PATH"
    fi
}

install_lazydocker() {
    if [ -d "$LAZYDOCKER_INSTALLATION_PATH" ]; then
        git -C $LAZYDOCKER_INSTALLATION_PATH pull
        "$LAZYDOCKER_INSTALLATION_PATH"/scripts/install_update_linux.sh
    else
        git clone --depth 1 $LAZYDOCKER_REPO "$LAZYDOCKER_INSTALLATION_PATH"
        "$LAZYDOCKER_INSTALLATION_PATH"/scripts/install_update_linux.sh
    fi
    sleep 3
}

install_todo() {
    if [ ! -L $HOME/.config/czsh/todo/bin/todo.sh ]; then
        logInfo "Installing todo.sh in $HOME/.config/czsh/todo\n"
        mkdir -p $HOME/.config/czsh/bin
        mkdir -p $HOME/.config/czsh/todo
        wget -q --show-progress "https://github.com/todotxt/todo.txt-cli/releases/download/v2.12.0/todo.txt_cli-2.12.0.tar.gz" -P $HOME/.config/czsh/
        tar xvf $HOME/.config/czsh/todo.txt_cli-2.12.0.tar.gz -C $HOME/.config/czsh/todo --strip 1 && rm $HOME/.config/czsh/todo.txt_cli-2.12.0.tar.gz
        ln -s -f $HOME/.config/czsh/todo/todo.sh $HOME/.config/czsh/bin/todo.sh
        ln -s -f $HOME/.config/czsh/todo/todo.cfg $HOME/.todo.cfg
    else
        echo -e "todo.sh is already installed in $HOME/.config/czsh/todo/bin/\n"
    fi
}

copy_history() {
    if [ "$cp_hist_flag" = true ]; then
        echo -e "\nCopying bash_history to zsh_history\n"
        if command -v python &>/dev/null; then
            wget -q --show-progress https://gist.githubusercontent.com/muendelezaji/c14722ab66b505a49861b8a74e52b274/raw/49f0fb7f661bdf794742257f58950d209dd6cb62/bash-to-zsh-hist.py
            python bash-to-zsh-hist.py < $HOME/.bash_history >> $HOME/.zsh_history
        else
            if command -v python3 &>/dev/null; then
                wget -q --show-progress https://gist.githubusercontent.com/muendelezaji/c14722ab66b505a49861b8a74e52b274/raw/49f0fb7f661bdf794742257f58950d209dd6cb62/bash-to-zsh-hist.py
                python3 bash-to-zsh-hist.py < $HOME/.bash_history >> $HOME/.zsh_history
            fi
        fi
    fi
}

install_ohmyzsh() {
    logProgress "Performing initial steps\n"
    backup_existing_zshrc_config
    detect_missing_packages
    install_missing_packages
    setup_plugins
    install_fzf
    install_powerlevel10k
    install_lazydocker
    install_todo
    configure_ohmzsh

    [ "$zsh_codex_flag" = true ] && configure_zsh_codex
    copy_history

    if cp zshrc $HOME/.zshrc; then
        logInfo "🔄 Copied new .zshrc file successfully"
    fi

    sleep 1 && exec zsh
}

install_ohmyzsh
