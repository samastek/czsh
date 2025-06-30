#!/bin/bash


##########################################################
###################### SOURCE FILES ######################
##########################################################
source ./utils.sh
##########################################################


cp_hist_flag=false
noninteractive_flag=true
zsh_codex_flag=false
gemini_cli_flag=false


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
    --gemini | -g)
        gemini_cli_flag=true
        ;;
    *)
        # Handle any other arguments or provide an error message
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
    if sudo apt update || sudo pacman -Sy || sudo dnf check-update || sudo yum check-update || brew update || pkg update; then
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
        if sudo apt install -y "$package" || sudo pacman -S "$package" || sudo dnf install -y "$package" || sudo yum install -y "$package" || sudo brew install "$package" || pkg install "$package"; then
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

    sed -i "s/TOBEREPLEACED/$OPENAI_API_KEY/g" $HOME/.config/zsh_codex.ini
    pip3 install openai --break-system-packages
    pip3 install groq --break-system-packages
}


install_fzf() {
    if [ -d $FZF_INSTALLATION_PATH ]; then
        logInfo "✅ FZF is already installed, updating...\n"
        git -C $FZF_INSTALLATION_PATH pull
        $FZF_INSTALLATION_PATH/install --all --key-bindings --completion --no-update-rc
    else
        logProgress "Installing FZF...\n"
        git clone --depth 1 $FZF_REPO $FZF_INSTALLATION_PATH
        "$FZF_INSTALLATION_PATH"/install --all --key-bindings --completion --no-update-rc
        logInfo "✅ FZF installed successfully\n"
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
        ln -s -f $HOME/.config/czsh/todo/todo.sh $HOME/.config/czsh/bin/todo.sh # so only .../bin is included in $PATH
        ln -s -f $HOME/.config/czsh/todo/todo.cfg $HOME/.todo.cfg               # it expects it there or $HOME/todo.cfg or $HOME/.todo/config
    else
        echo -e "todo.sh is already instlled in $HOME/.config/czsh/todo/bin/\n"
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
            else
                ech "Python is not installed, can't copy bash_history to zsh_history\n"
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
        curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
        sudo rm -rf /opt/nvim
        sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
        sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
        rm nvim-linux-x86_64.tar.gz
        git clone https://github.com/NvChad/starter ~/.config/nvim && nvim
        logInfo "Neovim installed successfully"
    else
        logInfo "✅ Neovim is already installed"
    fi
}

configure_gemini_cli() {
    logProgress "configuring Gemini CLI\n"
    
    # Source nvm to ensure npm is available
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Check if npm is available
    if ! command -v npm &>/dev/null; then
        logError "npm is not available. Node.js installation may have failed."
        return 1
    fi
    
    # Install Gemini CLI globally
    if npm install -g @google/gemini-cli; then
        logInfo "✅ Gemini CLI installed successfully\n"
        
        # Create configuration directory
        mkdir -p $HOME/.config/czsh/gemini
        
        # Ask user for authentication preference
        echo "Choose authentication method for Gemini CLI:"
        echo "1. API Key (requires Google AI Studio key)"
        echo "2. OAuth (will authenticate later with 'gemini auth')"
        echo "3. Skip configuration"
        read -p "Enter your choice (1-3): " auth_choice
        
        case $auth_choice in
            1)
                echo "Get your API key from: https://aistudio.google.com/apikey"
                read -s -p "Enter your Gemini API key: "
                GEMINI_API_KEY=$REPLY
                echo
                
                if [[ -n "$GEMINI_API_KEY" ]]; then
                    # Create config file with API key
                    cat > $HOME/.config/czsh/gemini/config.sh << EOF
#!/bin/bash
# Gemini CLI Configuration
export GEMINI_API_KEY="$GEMINI_API_KEY"
EOF
                    logInfo "✅ API key saved to ~/.config/czsh/gemini/config.sh\n"
                else
                    logWarning "No API key provided. You can set it later in ~/.config/czsh/gemini/config.sh\n"
                fi
                ;;
            2)
                # Create config file without API key
                cat > $HOME/.config/czsh/gemini/config.sh << 'EOF'
#!/bin/bash
# Gemini CLI Configuration

# Set your Gemini API key here (get it from https://aistudio.google.com/apikey)
# export GEMINI_API_KEY="your_api_key_here"

# Uncomment the line above and replace with your actual API key
# Or authenticate with: gemini auth
EOF
                logInfo "✅ Configuration file created. Run 'gemini auth' after installation to authenticate\n"
                ;;
            3)
                # Create minimal config file
                cat > $HOME/.config/czsh/gemini/config.sh << 'EOF'
#!/bin/bash
# Gemini CLI Configuration - Run 'gemini auth' to authenticate
EOF
                logInfo "✅ Minimal configuration created\n"
                ;;
            *)
                logWarning "Invalid choice. Creating minimal configuration\n"
                cat > $HOME/.config/czsh/gemini/config.sh << 'EOF'
#!/bin/bash
# Gemini CLI Configuration - Run 'gemini auth' to authenticate
EOF
                ;;
        esac
    else
        logError "❌ Failed to install Gemini CLI\n"
        return 1
    fi
}

install_nodejs() {
    logProgress "Checking Node.js installation...\n"
    
    # Check if node is already available
    if command -v node &>/dev/null; then
        local node_version=$(node -v)
        logInfo "✅ Node.js is already installed: $node_version\n"
        return 0
    fi
    
    logProgress "Node.js not found. Installing via nvm...\n"
    
    # Download and install nvm
    if ! command -v nvm &>/dev/null && [ ! -f "$HOME/.nvm/nvm.sh" ]; then
        logProgress "Installing nvm...\n"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
        
        if [ $? -ne 0 ]; then
            logError "❌ Failed to install nvm\n"
            return 1
        fi
    fi
    
    # Source nvm to make it available in current session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    # Install Node.js version 22
    logProgress "Installing Node.js v22...\n"
    if nvm install 22; then
        nvm use 22
        nvm alias default 22
        
        # Verify installation
        local node_version=$(node -v)
        local npm_version=$(npm -v)
        
        logInfo "✅ Node.js installed successfully: $node_version\n"
        logInfo "✅ npm version: $npm_version\n"
        
        return 0
    else
        logError "❌ Failed to install Node.js\n"
        return 1
    fi
}
#############################################################################################
####################################### MAIN SCRIPT #########################################
#############################################################################################

detect_missing_packages

install_missing_packages

install_nodejs

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
mkdir -p $HOME/.fonts             # Create .fonts if doesn't exist

if [ -f $HOME/.zcompdump ]; then
    mv $HOME/.zcompdump* $HOME/.cache/zsh/
fi


if [ "$zsh_codex_flag" = true ]; then
    configure_zsh_codex 
fi

if [ "$gemini_cli_flag" = true ]; then
    configure_gemini_cli
fi


install_powerlevel10k


logProgress "Installing Nerd Fonts version of Hack, Roboto Mono, DejaVu Sans Mono\n"

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

install_fzf

install_lazydocker

setup_plugins

install_todo

install_nvim

copy_history

finish_installation

exit
