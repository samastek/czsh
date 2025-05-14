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

# Install Homebrew on macOS if not present
install_homebrew() {
    if ! command -v brew &>/dev/null; then
        logProgress "Homebrew not found. Installing Homebrew...\n"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for current session
        if [[ -f /opt/homebrew/bin/brew ]]; then
            # Apple Silicon Mac
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f /usr/local/bin/brew ]]; then
            # Intel Mac
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        
        logInfo "✅ Homebrew installed successfully"
    fi
}

prerequists=("zsh" "git" "wget" "bat" "curl" "python3")
missing_packages=()

detect_missing_packages() {
    for package in "${prerequists[@]}"; do
        if ! command -v "$package" &>/dev/null; then
            missing_packages+=("$package")
        fi
    done
}

perform_update() {
    if command -v brew &>/dev/null; then
        brew update && logInfo "Homebrew updated\n"
    else
        logError "Homebrew is not installed. Please install Homebrew first: https://brew.sh/\n"
        exit 1
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
    if [[ ${#missing_packages[@]} -eq 0 ]]; then
        logInfo "All prerequisites are already installed\n"
        return
    fi
    
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
    if mv -n $HOME/.zshrc $HOME/.zshrc-backup-"$(date +"%Y-%m-%d")"; then # backup .zshrc
        logInfo -e "Backed up the current .zshrc to .zshrc-backup-date\n"
    fi
}

# -d checks if the directory exists
# git -C checks if the directory exists and runs the command in that directory
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
    cp zsh_codex.ini $HOME/.config/

    read -s -p "Enter your openai api key: "
    OPENAI_API_KEY=$REPLY

    sed -i '' "s/TOBEREPLEACED/$OPENAI_API_KEY/g" $HOME/.config/zsh_codex.ini
    pip3 install openai
    pip3 install groq
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

install_powerlevel10k() {
    if [ -d "$POWERLEVEL_10K_PATH" ]; then
        git -C "$POWERLEVEL_10K_PATH" pull
    else
        git clone --depth=1 $POWERLEVEL10K_REPO "$POWERLEVEL_10K_PATH"
    fi
}

install_lazydocker() {
    # For macOS, use Homebrew if available, otherwise build from source
    if command -v brew &>/dev/null; then
        if ! command -v lazydocker &>/dev/null; then
            brew install jesseduffield/lazydocker/lazydocker
            logInfo "✅ lazydocker installed via Homebrew"
        else
            brew upgrade jesseduffield/lazydocker/lazydocker 2>/dev/null || true
            logInfo "✅ lazydocker is up to date"
        fi
    else
        # Fallback: install from source
        if [ -d "$LAZYDOCKER_INSTALLATION_PATH" ]; then
            git -C $LAZYDOCKER_INSTALLATION_PATH pull
        else
            git clone --depth 1 $LAZYDOCKER_REPO "$LAZYDOCKER_INSTALLATION_PATH"
        fi
        # Build lazydocker from source (requires Go)
        if command -v go &>/dev/null; then
            cd "$LAZYDOCKER_INSTALLATION_PATH" && go build -o lazydocker main.go
            mkdir -p "$HOME/.local/bin"
            cp "$LAZYDOCKER_INSTALLATION_PATH/lazydocker" "$HOME/.local/bin/"
            logInfo "✅ lazydocker built and installed to ~/.local/bin/"
        else
            logWarning "Go is not installed. Please install Go or Homebrew to install lazydocker"
        fi
    fi
    sleep 3
}


install_todo() {
    # For macOS, use Homebrew if available
    if command -v brew &>/dev/null; then
        if ! command -v todo.sh &>/dev/null; then
            brew install todo-txt
            logInfo "✅ todo.sh installed via Homebrew"
        else
            logInfo "✅ todo.sh is already installed"
        fi
        return
    fi
    
    # Fallback installation for macOS without Homebrew
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

        if chsh -s "$(which zsh)" && /bin/zsh -i -c 'omz update'; then
            logInfo "Installation complete, exit terminal and enter a new zsh session"
            logWarning "In a new zsh session manually run: build-fzf-tab-module"
        else
            logError "Something is wrong, the password you entered might be wrong\n"

        fi
    fi
}


install_nvim() {
    if ! command -v nvim &>/dev/null; then
        # For macOS, use Homebrew if available
        if command -v brew &>/dev/null; then
            brew install neovim
            logInfo "✅ Neovim installed via Homebrew"
        else
            # Fallback: download macOS binary
            ARCH=$(uname -m)
            case "$ARCH" in
                x86_64)
                    NVIM_PKG="nvim-macos-x86_64.tar.gz"
                    ;;
                arm64)
                    NVIM_PKG="nvim-macos-arm64.tar.gz"
                    ;;
                *)
                    logError "❌ Unsupported macOS architecture: $ARCH"
                    return 1
                    ;;
            esac

            curl -LO "https://github.com/neovim/neovim/releases/latest/download/$NVIM_PKG"
            tar -xzf "$NVIM_PKG"
            mkdir -p "$HOME/.local/bin"
            cp nvim-macos*/bin/nvim "$HOME/.local/bin/"
            rm -rf "$NVIM_PKG" nvim-macos*
            logInfo "✅ Neovim installed to ~/.local/bin/ (make sure ~/.local/bin is in your PATH)"
        fi

        # Install NvChad starter config
        if [ ! -d "$HOME/.config/nvim" ]; then
            git clone https://github.com/NvChad/starter ~/.config/nvim
            logInfo "✅ NvChad starter config installed"
        fi
    else
        logInfo "✅ Neovim is already installed"
    fi
}



#############################################################################################
####################################### MAIN SCRIPT #########################################
#############################################################################################

logInfo "🍎 Starting macOS Zsh Setup Installation\n"

install_homebrew
detect_missing_packages

install_missing_packages

backup_existing_zshrc_config

logInfo "The setup will be installed in '$HOME/.config/czsh'\n"

logWarning "Place your personal zshrc config files under '$HOME/.config/czsh/zshrc/'\n"

mkdir -p $HOME/.config/czsh/zshrc

logInfo "Installing oh-my-zsh\n"

configure_ohmzsh


cp -f ./.zshrc $HOME/
cp -f ./czshrc.zsh $HOME/.config/czsh/

mkdir -p $HOME/.config/czsh/zshrc # PLACE YOUR ZSHRC CONFIGURATIONS OVER THERE
mkdir -p $HOME/.cache/zsh/        # this will be used to store .zcompdump zsh completion cache files which normally clutter $HOME
mkdir -p $HOME/Library/Fonts      # Create Fonts directory

if [ -f $HOME/.zcompdump ]; then
    mv $HOME/.zcompdump* $HOME/.cache/zsh/
fi


if [ "$zsh_codex_flag" = true ]; then
    configure_zsh_codex 
fi


install_powerlevel10k


logProgress "Installing Nerd Fonts version of Hack, Roboto Mono, DejaVu Sans Mono\n"

FONT_DIR="$HOME/Library/Fonts"

if [ ! -f "$FONT_DIR/HackNerdFont-Regular.ttf" ]; then
    wget -q --show-progress -N https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Hack/Regular/HackNerdFont-Regular.ttf -P "$FONT_DIR/"
fi

if [ ! -f "$FONT_DIR/RobotoMonoNerdFont-Regular.ttf" ]; then
    wget -q --show-progress -N https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/RobotoMono/Regular/RobotoMonoNerdFont-Regular.ttf -P "$FONT_DIR/"
fi

if [ ! -f "$FONT_DIR/DejaVuSansMNerdFont-Regular.ttf" ]; then
    wget -q --show-progress -N https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/DejaVuSansMono/Regular/DejaVuSansMNerdFont-Regular.ttf -P "$FONT_DIR/"
fi

# Refresh font cache (if fontconfig is available)
if command -v fc-cache &>/dev/null; then
    fc-cache -fv "$FONT_DIR"
fi
logInfo "Fonts installed to ~/Library/Fonts. They should be available immediately."

install_fzf

install_lazydocker

setup_plugins

install_todo

install_nvim

copy_history

finish_installation

exit
