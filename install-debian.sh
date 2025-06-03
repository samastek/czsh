#!/bin/bash

set -x
##########################################################
###################### SOURCE FILES ######################
##########################################################
source ./utils.sh
##########################################################

cp_hist_flag=false
noninteractive_flag=true
zsh_codex_flag=false

# Updated paths for standalone plugin system
CZSH_HOME="$HOME/.config/czsh"
CZSH_PLUGINS_DIR="$CZSH_HOME/plugins"
CZSH_THEMES_DIR="$CZSH_HOME/themes"

#############################################################################################
######################################### VARIABLES #########################################
#############################################################################################

POWERLEVEL10K_REPO="https://github.com/romkatv/powerlevel10k.git"
POWERLEVEL_10K_PATH="$CZSH_THEMES_DIR/powerlevel10k"

FZF_REPO="https://github.com/junegunn/fzf.git"
MARKER_REPO="https://github.com/pindexis/marker.git"
LAZYDOCKER_REPO="https://github.com/jesseduffield/lazydocker.git"

FZF_INSTALLATION_PATH=$HOME/.config/czsh/fzf
MARKER_INSTALLATION_PATH=$HOME/.config/czsh/marker
LAZYDOCKER_INSTALLATION_PATH=$HOME/.config/czsh/lazydocker

# Plugin repositories - these will be installed directly without Oh My Zsh
declare -A PLUGINS_MAP

export PLUGINS_MAP=(
    ["fzf-tab"]="https://github.com/Aloxaf/fzf-tab.git"
    ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions.git"
    ["zsh_codex"]="https://github.com/samastek/zsh_codex.git"
    ["zsh-completions"]="https://github.com/zsh-users/zsh-completions.git"
    ["history-substring-search"]="https://github.com/zsh-users/zsh-history-substring-search.git"
    ["forgit"]="https://github.com/wfxr/forgit.git"
    ["z"]="https://github.com/rupa/z.git"
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
        # Handle any other arguments or provide an error message
        ;;
    esac
done

#############################################################################################
####################################### FUNCTIONS #########################################
#############################################################################################

prerequists=("zsh" "git" "wget" "curl" "python3" "build-essential")
missing_packages=()

detect_missing_packages() {
    for package in "${prerequists[@]}"; do
        if ! command -v "$package" &>/dev/null; then
            missing_packages+=("$package")
        fi
    done
    
    # Check if bat is installed as 'bat' or 'batcat'
    if ! command -v bat &>/dev/null && ! command -v batcat &>/dev/null; then
        missing_packages+=("bat")
    fi
}

perform_update() {
    sudo apt update && logInfo "Packages updated\n"
}

# Setup plugins directly without Oh My Zsh
setup_plugins(){
    mkdir -p "$CZSH_PLUGINS_DIR"
    
    for PLUGIN_NAME in "${!PLUGINS_MAP[@]}"; do
         PLUGIN_PATH="$CZSH_PLUGINS_DIR/$PLUGIN_NAME"
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
    if [[ ${#missing_packages[@]} -eq 0 ]]; then
        logInfo "All prerequisites are already installed\n"
        return
    fi
    
    perform_update
    
    for package in "${missing_packages[@]}"; do
        if sudo apt install -y "$package"; then
            logInfo "$package Installed\n"
        else
            logWarning "🚨 Please install the following packages first, then try again: $package 🚨" && exit
        fi
    done
}

backup_existing_zshrc_config() {
    if mv -n $HOME/.zshrc $HOME/.zshrc-backup-"$(date +"%Y-%m-%d")"; then # backup .zshrc
        logInfo -e "Backed up the current .zshrc to .zshrc-backup-date\n"
    fi
}

# Setup Powerlevel10k theme directly (without Oh My Zsh)
configure_powerlevel10k() {
    mkdir -p "$CZSH_THEMES_DIR"
    
    if [ -d "$POWERLEVEL_10K_PATH" ]; then
        logInfo "✅ Powerlevel10k is already installed\n"
        git -C "$POWERLEVEL_10K_PATH" pull
    else
        git clone --depth=1 $POWERLEVEL10K_REPO "$POWERLEVEL_10K_PATH"
        logInfo "✅ Powerlevel10k theme installed"
    fi
}

install_fzf() {
    if [ -d $FZF_INSTALLATION_PATH ]; then
        git -C $FZF_INSTALLATION_PATH pull
        $FZF_INSTALLATION_PATH/install --all --key-bindings --completion --no-update-rc
    else
        git clone --branch 0.60.3 --depth 1 $FZF_REPO $FZF_INSTALLATION_PATH
        "$FZF_INSTALLATION_PATH"/install --all --key-bindings --completion --no-update-rc
    fi
}

install_marker() {
    if [ -d $MARKER_INSTALLATION_PATH ]; then
        git -C $MARKER_INSTALLATION_PATH pull
        $MARKER_INSTALLATION_PATH/install.sh
    else
        git clone --depth 1 $MARKER_REPO $MARKER_INSTALLATION_PATH
        $MARKER_INSTALLATION_PATH/install.sh
    fi
}

install_lazydocker() {
    # Linux installation
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
        
        if command -v wget &>/dev/null; then
            wget -q --show-progress "https://github.com/todotxt/todo.txt-cli/releases/download/v2.12.0/todo.txt_cli-2.12.0.tar.gz" -P $HOME/.config/czsh/
        elif command -v curl &>/dev/null; then
            curl -L "https://github.com/todotxt/todo.txt-cli/releases/download/v2.12.0/todo.txt_cli-2.12.0.tar.gz" -o $HOME/.config/czsh/todo.txt_cli-2.12.0.tar.gz
        else
            logError "Neither wget nor curl found. Cannot download todo.sh"
            return 1
        fi
        
        tar xzf $HOME/.config/czsh/todo.txt_cli-2.12.0.tar.gz -C $HOME/.config/czsh/todo --strip 1 && rm $HOME/.config/czsh/todo.txt_cli-2.12.0.tar.gz
        ln -s -f $HOME/.config/czsh/todo/todo.sh $HOME/.config/czsh/bin/todo.sh # so only .../bin is included in $PATH
        ln -s -f $HOME/.config/czsh/todo/todo.cfg $HOME/.todo.cfg               # it expects it there or $HOME/todo.cfg or $HOME/.todo/config
        logInfo "✅ todo.sh installed manually"
    else
        logInfo "✅ todo.sh is already installed in $HOME/.config/czsh/todo/bin/\n"
    fi
}

copy_history() {
    if [ "$cp_hist_flag" = true ]; then
        echo -e "\nCopying bash_history to zsh_history\n"
        if command -v python &>/dev/null; then
            if command -v wget &>/dev/null; then
                wget -q --show-progress https://gist.githubusercontent.com/muendelezaji/c14722ab66b505a49861b8a74e52b274/raw/49f0fb7f661bdf794742257f58950d209dd6cb62/bash-to-zsh-hist.py
            elif command -v curl &>/dev/null; then
                curl -O https://gist.githubusercontent.com/muendelezaji/c14722ab66b505a49861b8a74e52b274/raw/49f0fb7f661bdf794742257f58950d209dd6cb62/bash-to-zsh-hist.py
            else
                logError "Neither wget nor curl found. Cannot download bash-to-zsh conversion script."
                return 1
            fi
            python bash-to-zsh-hist.py < $HOME/.bash_history >> $HOME/.zsh_history
        else
            if command -v python3 &>/dev/null; then
                if command -v wget &>/dev/null; then
                    wget -q --show-progress https://gist.githubusercontent.com/muendelezaji/c14722ab66b505a49861b8a74e52b274/raw/49f0fb7f661bdf794742257f58950d209dd6cb62/bash-to-zsh-hist.py
                elif command -v curl &>/dev/null; then
                    curl -O https://gist.githubusercontent.com/muendelezaji/c14722ab66b505a49861b8a74e52b274/raw/49f0fb7f661bdf794742257f58950d209dd6cb62/bash-to-zsh-hist.py
                else
                    logError "Neither wget nor curl found. Cannot download bash-to-zsh conversion script."
                    return 1
                fi
                python3 bash-to-zsh-hist.py < $HOME/.bash_history >> $HOME/.zsh_history
            else
                logError "Python is not installed, can't copy bash_history to zsh_history\n"
            fi
        fi
    else
        logWarning "\nNot copying bash_history to zsh_history, as --cp-hist or -c is not supplied\n"
    fi
}

finish_installation() {
    logInfo "Installation complete\n"
    if [ "$noninteractive_flag" = true ]; then
        logInfo "Installation complete, exit terminal and enter a new zsh session\n"
        logWarning "Make sure to change zsh to default shell by running: chsh -s $(which zsh)"
        logInfo "In a new zsh session manually run: build-fzf-tab-module"
    else
        logWarning "\nSudo access is needed to change default shell\n"

        if chsh -s "$(which zsh)"; then
            logInfo "Installation complete, exit terminal and enter a new zsh session"
            logWarning "In a new zsh session manually run: build-fzf-tab-module"
        else
            logError "Something is wrong, the password you entered might be wrong\n"
        fi
    fi
}

install_nvim() {
    if ! command -v nvim &>/dev/null; then
        # Linux installation
        ARCH=$(uname -m)
        case "$ARCH" in
            x86_64)
                NVIM_PKG="nvim-linux64.tar.gz"
                ;;
            aarch64 | arm64)
                NVIM_PKG="nvim-linux64.tar.gz"
                ;;
            armv7l)
                NVIM_PKG="nvim-linux64.tar.gz"
                ;;
            *)
                logError "❌ Unsupported architecture: $ARCH"
                return 1
                ;;
        esac

        curl -LO "https://github.com/neovim/neovim/releases/latest/download/$NVIM_PKG"

        sudo rm -rf /opt/nvim
        sudo tar -C /opt -xzf "$NVIM_PKG"
        sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
        rm "$NVIM_PKG"
        
        logInfo "✅ Neovim installed successfully"

        # Install NvChad starter config
        if [ ! -d "$HOME/.config/nvim" ]; then
            git clone https://github.com/NvChad/starter ~/.config/nvim
            logInfo "✅ NvChad starter config installed"
        fi
    else
        logInfo "✅ Neovim is already installed"
    fi
}

configure_zsh_codex() {
    logProgress "configuring zsh_codex\n"
    cp zsh_codex.ini $HOME/.config/

    read -s -p "Enter your openai api key: "
    OPENAI_API_KEY=$REPLY

    sed -i "s/TOBEREPLEACED/$OPENAI_API_KEY/g" $HOME/.config/zsh_codex.ini
    pip3 install openai --break-system-packages
    pip3 install groq --break-system-packages
}

install_nerd_fonts() {
    logProgress "Installing Nerd Fonts version of Hack, Roboto Mono, DejaVu Sans Mono\n"
    
    mkdir -p $HOME/.fonts
    
    if [ ! -f $HOME/.fonts/HackNerdFont-Regular.ttf ]; then
        wget -q --show-progress -N https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Hack/Regular/HackNerdFont-Regular.ttf -P $HOME/.fonts/
    fi
    
    if [ ! -f $HOME/.fonts/RobotoMonoNerdFont-Regular.ttf ]; then
        wget -q --show-progress -N https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/RobotoMono/Regular/RobotoMonoNerdFont-Regular.ttf -P $HOME/.fonts/
    fi
    
    if [ ! -f $HOME/.fonts/DejaVuSansMNerdFont-Regular.ttf ]; then
        wget -q --show-progress -N https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/DejaVuSansMono/Regular/DejaVuSansMNerdFont-Regular.ttf -P $HOME/.fonts/
    fi
    
    fc-cache -fv $HOME/.fonts
    logInfo "Fonts installed and font cache refreshed."
}

#############################################################################################
####################################### MAIN SCRIPT #########################################
#############################################################################################

logInfo "🐧 Starting Debian/Ubuntu Zsh Setup Installation (No Oh My Zsh)\n"

detect_missing_packages

install_missing_packages

backup_existing_zshrc_config

logInfo "The setup will be installed in '$HOME/.config/czsh'\n"

logWarning "Place your personal zshrc config files under '$HOME/.config/czsh/zshrc/'\n"

mkdir -p $HOME/.config/czsh/zshrc

logInfo "Installing Powerlevel10k theme\n"

configure_powerlevel10k

cp -f ./.zshrc $HOME/
cp -f ./czshrc.zsh $HOME/.config/czsh/

mkdir -p $HOME/.config/czsh/zshrc # PLACE YOUR ZSHRC CONFIGURATIONS OVER THERE
mkdir -p $HOME/.cache/zsh/        # this will be used to store .zcompdump zsh completion cache files which normally clutter $HOME
mkdir -p $HOME/.fonts             # Create .fonts if doesn't exist

if [ -f $HOME/.zcompdump ]; then
    mv $HOME/.zcompdump* $HOME/.cache/zsh/
fi

if [ "$zsh_codex_flag" = true ]; then
    configure_zsh_codex 
fi

install_nerd_fonts

install_fzf

install_marker

install_lazydocker

setup_plugins

install_todo

install_nvim

copy_history

finish_installation

exit
