#!/bin/bash

##########################################################
###################### SOURCE FILES ######################
##########################################################
source ./utils.sh

# Record start time for installation summary
INSTALL_START_TIME=$(date +%s)

# Welcome header
print_header "CZSH - Enhanced Zsh Configuration Installer" "$CYAN" "$BG_BLUE"
logInfo "Welcome to the enhanced zsh setup installer! $SPARKLES"
logNote "This installer will set up a powerful zsh environment with modern tools and plugins"
echo

##########################################################

cp_hist_flag=false
noninteractive_flag=true
zsh_codex_flag=false
gemini_cli_flag=false
claude_cli_flag=false

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

# Plugin definitions - name:repo_url pairs
PLUGIN_FZF_TAB="fzf-tab:https://github.com/Aloxaf/fzf-tab.git"
PLUGIN_SYNTAX_HIGHLIGHTING="zsh-syntax-highlighting:https://github.com/zsh-users/zsh-syntax-highlighting.git"
PLUGIN_AUTOSUGGESTIONS="zsh-autosuggestions:https://github.com/zsh-users/zsh-autosuggestions.git"
PLUGIN_ZSH_CODEX="zsh_codex:https://github.com/samastek/zsh_codex.git"
PLUGIN_COMPLETIONS="zsh-completions:https://github.com/zsh-users/zsh-completions.git"
PLUGIN_HISTORY_SEARCH="history-substring-search:https://github.com/zsh-users/zsh-history-substring-search.git"
PLUGIN_FORGIT="forgit:https://github.com/wfxr/forgit.git"

PLUGINS_LIST="$PLUGIN_FZF_TAB $PLUGIN_SYNTAX_HIGHLIGHTING $PLUGIN_AUTOSUGGESTIONS $PLUGIN_ZSH_CODEX $PLUGIN_COMPLETIONS $PLUGIN_HISTORY_SEARCH $PLUGIN_FORGIT"

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
        --claude | -cl)
            claude_cli_flag=true
            ;;
        *)
            # Handle any other arguments or provide an error message
            ;;
    esac
done

#############################################################################################
####################################### FUNCTIONS #########################################
#############################################################################################

prerequists=("zsh" "git" "wget" "bat" "curl" "fontconfig")
missing_packages=()

detect_missing_packages() {
    for package in "${prerequists[@]}"; do
        if ! command -v "$package" &> /dev/null; then
            missing_packages+=("$package")
        fi
    done

    # Check for python3 and pip3 separately on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # On macOS, check for python3 and pip3
        if ! command -v python3 &> /dev/null; then
            missing_packages+=("python3")
        fi
        if ! command -v pip3 &> /dev/null; then
            # pip3 is usually included with python3 on macOS
            if ! python3 -m pip --version &> /dev/null 2>&1; then
                missing_packages+=("python3")
            fi
        fi
    else
        # On Linux, check for python3-pip
        if ! command -v pip3 &> /dev/null; then
            missing_packages+=("python3-pip")
        fi
    fi
}

perform_update() {
    print_section "System Update" "$ZAPP" "$BLUE"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - use Homebrew without sudo
        logProgress "Updating Homebrew packages..."
        if brew update; then
            logSuccess "System updated successfully"
        else
            logError "System update failed"
        fi
    else
        # Linux - try different package managers
        logProgress "Updating system packages..."
        if sudo apt update || sudo pacman -Sy || sudo dnf check-update || sudo yum check-update || pkg update; then
            logSuccess "System updated successfully"
        else
            logError "System update failed"
        fi
    fi
    echo
}

setup_plugins() {
    print_section "Zsh Plugins Installation" "$PACKAGE" "$PURPLE"

    local plugin_count=0
    local total_plugins=$(echo $PLUGINS_LIST | wc -w)

    for PLUGIN_ENTRY in $PLUGINS_LIST; do
        ((plugin_count++))
        PLUGIN_NAME="${PLUGIN_ENTRY%%:*}"
        PLUGIN_REPO_LINK="${PLUGIN_ENTRY#*:}"
        PLUGIN_PATH="$OHMYZSH_CUSTOM_PLUGIN_PATH/$PLUGIN_NAME"

        logStepProgress "$plugin_count" "$total_plugins" "$PLUGIN_NAME"

        if [ -d "$PLUGIN_PATH" ]; then
            logAlreadyInstalled "$PLUGIN_NAME plugin"
            logUpdating "$PLUGIN_NAME"
            if git -C "$PLUGIN_PATH" pull --quiet 2> /dev/null; then
                logUpdated "$PLUGIN_NAME"
            else
                logWarning "Failed to update $PLUGIN_NAME, but continuing..."
            fi
        else
            logInstalling "$PLUGIN_NAME plugin"
            git clone --depth=1 --quiet "$PLUGIN_REPO_LINK" "$PLUGIN_PATH"
            logInstalled "$PLUGIN_NAME plugin"
        fi
        echo
    done
}

install_missing_packages() {
    if [ ${#missing_packages[@]} -eq 0 ]; then
        logSuccess "All required packages are already installed!"
        return
    fi

    print_section "Package Installation" "$PACKAGE" "$YELLOW"
    logWarning "Missing packages detected: ${missing_packages[*]}"

    perform_update

    local package_count=0
    local total_packages=${#missing_packages[@]}

    for package in "${missing_packages[@]}"; do
        ((package_count++))
        logStepProgress "$package_count" "$total_packages" "Installing $package"

        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS - use Homebrew without sudo
            logInstalling "$package"
            if brew install "$package" > /dev/null 2>&1; then
                logInstalled "$package"
            else
                logErrorWithSuggestion "Failed to install $package" "Try running 'brew install $package' manually"
                exit 1
            fi
        else
            # Linux - try different package managers
            logInstalling "$package"
            if sudo apt install -y "$package" > /dev/null 2>&1 || sudo pacman -S "$package" > /dev/null 2>&1 || sudo dnf install -y "$package" > /dev/null 2>&1 || sudo yum install -y "$package" > /dev/null 2>&1 || pkg install "$package" > /dev/null 2>&1; then
                logInstalled "$package"
            else
                logErrorWithSuggestion "Failed to install $package" "Try installing manually with your system's package manager"
                exit 1
            fi
        fi
        echo
    done
}

backup_existing_zshrc_config() {
    print_section "Configuration Backup" "$FOLDER" "$YELLOW"
    if [ -f "$HOME/.zshrc" ]; then
        local backup_file="$HOME/.zshrc-backup-$(date +"%Y-%m-%d-%H%M%S")"
        if mv "$HOME/.zshrc" "$backup_file"; then
            logSuccess "Backed up existing .zshrc to $(basename $backup_file)"
        else
            logWarning "Failed to backup existing .zshrc"
        fi
    else
        logInfo "No existing .zshrc found, skipping backup"
    fi
    echo
}

# -d checks if the directory exists
# git -C checks if the directory exists and runs the command in that directory
configure_ohmzsh() {
    print_section "Oh My Zsh Setup" "$STAR" "$GREEN"

    if [ -d "$OH_MY_ZSH_FOLDER" ]; then
        logAlreadyInstalled "oh-my-zsh"
        logUpdating "oh-my-zsh"
        git -C "$OH_MY_ZSH_FOLDER" remote set-url origin "$OH_MY_ZSHR_REPO"
        export ZSH=$OH_MY_ZSH_FOLDER
        if git -C "$OH_MY_ZSH_FOLDER" pull --quiet 2> /dev/null; then
            logUpdated "oh-my-zsh"
        else
            logWarning "Failed to update oh-my-zsh, but continuing..."
        fi
    elif [ -d "$HOME/.oh-my-zsh" ]; then
        logProgress "Moving existing oh-my-zsh from '$HOME/.oh-my-zsh' to '$HOME/.config/czsh/oh-my-zsh'"
        export ZSH=$OH_MY_ZSH_FOLDER
        mv "$HOME/.oh-my-zsh" "$OH_MY_ZSH_FOLDER"
        git -C "$OH_MY_ZSH_FOLDER" remote set-url origin "$OH_MY_ZSHR_REPO"
        if git -C "$OH_MY_ZSH_FOLDER" pull --quiet 2> /dev/null; then
            logSuccess "oh-my-zsh moved and updated successfully"
        else
            logSuccess "oh-my-zsh moved successfully (update failed but continuing)"
        fi
    else
        logInstalling "oh-my-zsh"
        git clone --depth=1 --quiet $OH_MY_ZSHR_REPO "$OH_MY_ZSH_FOLDER"
        export ZSH=$OH_MY_ZSH_FOLDER
        logInstalled "oh-my-zsh"
    fi
    echo
}

configure_zsh_codex() {
    print_section "Zsh Codex Configuration" "$FIRE" "$PURPLE"
    logConfiguring "zsh_codex"
    cp zsh_codex.ini $HOME/.config/

    read -s -p "$(printf "${YELLOW}🔑 Enter your OpenAI API key: ${RESET}")"
    OPENAI_API_KEY=$REPLY
    echo

    sed -i "s/TOBEREPLEACED/$OPENAI_API_KEY/g" $HOME/.config/zsh_codex.ini

    logInstalling "OpenAI Python package"
    pip3 install openai --break-system-packages > /dev/null 2>&1
    logInstalled "OpenAI Python package"

    logInstalling "Groq Python package"
    pip3 install groq --break-system-packages > /dev/null 2>&1
    logInstalled "Groq Python package"

    logConfigured "zsh_codex"
    echo
}

install_fzf() {
    print_section "FZF Installation" "$ROCKET" "$BLUE"

    if [ -d "$FZF_INSTALLATION_PATH" ]; then
        logAlreadyInstalled "FZF"
        logUpdating "FZF"
        if git -C "$FZF_INSTALLATION_PATH" pull --quiet 2> /dev/null; then
            logUpdated "FZF"
        else
            logWarning "Failed to update FZF, but continuing..."
        fi
        logProgress "Running FZF install script..."
        if "$FZF_INSTALLATION_PATH/install" --all --key-bindings --completion --no-update-rc --no-bash --no-fish > /dev/null 2>&1; then
            logSuccess "FZF installation completed"
        else
            logWarning "FZF install script failed, but continuing..."
        fi
    else
        logInstalling "FZF"
        if git clone --depth 1 --quiet "$FZF_REPO" "$FZF_INSTALLATION_PATH" 2> /dev/null; then
            logProgress "Running FZF install script..."
            if "$FZF_INSTALLATION_PATH/install" --all --key-bindings --completion --no-update-rc --no-bash --no-fish > /dev/null 2>&1; then
                logInstalled "FZF"

                # Ensure FZF binary is properly linked
                if [ -f "$FZF_INSTALLATION_PATH/bin/fzf" ]; then
                    logSuccess "FZF binary available at $FZF_INSTALLATION_PATH/bin/fzf"
                else
                    logWarning "FZF binary not found, trying to build..."
                    if command -v go > /dev/null 2>&1; then
                        cd "$FZF_INSTALLATION_PATH" && make install > /dev/null 2>&1 && cd - > /dev/null
                    fi
                fi
            else
                logError "FZF install script failed"
                return 1
            fi
        else
            logError "Failed to clone FZF repository"
            return 1
        fi
    fi
    echo
}

install_powerlevel10k() {
    print_section "Powerlevel10k Theme" "$SPARKLES" "$PURPLE"

    if [ -d "$POWERLEVEL_10K_PATH" ]; then
        logAlreadyInstalled "Powerlevel10k"
        logUpdating "Powerlevel10k"
        if git -C "$POWERLEVEL_10K_PATH" pull --quiet 2> /dev/null; then
            logUpdated "Powerlevel10k"
        else
            logWarning "Failed to update Powerlevel10k, but continuing..."
        fi
    else
        logInstalling "Powerlevel10k"
        git clone --depth=1 --quiet $POWERLEVEL10K_REPO "$POWERLEVEL_10K_PATH"
        logInstalled "Powerlevel10k"
    fi
    echo
}

install_lazydocker() {
    print_section "Lazydocker Installation" "$GEAR" "$CYAN"

    if [ -d "$LAZYDOCKER_INSTALLATION_PATH" ]; then
        logAlreadyInstalled "Lazydocker"
        logUpdating "Lazydocker"
        if git -C $LAZYDOCKER_INSTALLATION_PATH pull --quiet 2> /dev/null; then
            logUpdated "Lazydocker"
        else
            logWarning "Failed to update Lazydocker, but continuing..."
        fi
        "$LAZYDOCKER_INSTALLATION_PATH"/scripts/install_update_linux.sh > /dev/null 2>&1
    else
        logInstalling "Lazydocker"
        git clone --depth 1 --quiet $LAZYDOCKER_REPO "$LAZYDOCKER_INSTALLATION_PATH"
        "$LAZYDOCKER_INSTALLATION_PATH"/scripts/install_update_linux.sh > /dev/null 2>&1
        logInstalled "Lazydocker"
    fi
    echo
}

install_todo() {
    print_section "Todo.sh Installation" "$CHECKMARK" "$GREEN"

    if [ ! -L $HOME/.config/czsh/todo/bin/todo.sh ]; then
        logInstalling "todo.sh in $HOME/.config/czsh/todo"
        mkdir -p $HOME/.config/czsh/bin
        mkdir -p $HOME/.config/czsh/todo

        logProgress "Downloading todo.sh v2.12.0..."
        wget -q --show-progress "https://github.com/todotxt/todo.txt-cli/releases/download/v2.12.0/todo.txt_cli-2.12.0.tar.gz" -P $HOME/.config/czsh/ 2> /dev/null

        logProgress "Extracting and setting up todo.sh..."
        tar xf $HOME/.config/czsh/todo.txt_cli-2.12.0.tar.gz -C $HOME/.config/czsh/todo --strip 1 2> /dev/null && rm $HOME/.config/czsh/todo.txt_cli-2.12.0.tar.gz
        ln -s -f $HOME/.config/czsh/todo/todo.sh $HOME/.config/czsh/bin/todo.sh # so only .../bin is included in $PATH
        ln -s -f $HOME/.config/czsh/todo/todo.cfg $HOME/.todo.cfg               # it expects it there or $HOME/todo.cfg or $HOME/.todo/config

        logInstalled "todo.sh"
    else
        logAlreadyInstalled "todo.sh in $HOME/.config/czsh/todo/bin/"
    fi
    echo
}

copy_history() {
    print_section "Bash History Migration" "$FOLDER" "$YELLOW"

    if [ "$cp_hist_flag" = true ]; then
        logProgress "Copying bash_history to zsh_history..."
        if command -v python &> /dev/null; then
            wget -q --show-progress https://gist.githubusercontent.com/muendelezaji/c14722ab66b505a49861b8a74e52b274/raw/49f0fb7f661bdf794742257f58950d209dd6cb62/bash-to-zsh-hist.py 2> /dev/null
            python bash-to-zsh-hist.py < $HOME/.bash_history >> $HOME/.zsh_history 2> /dev/null
            logSuccess "bash_history copied to zsh_history"
        else
            if command -v python3 &> /dev/null; then
                wget -q --show-progress https://gist.githubusercontent.com/muendelezaji/c14722ab66b505a49861b8a74e52b274/raw/49f0fb7f661bdf794742257f58950d209dd6cb62/bash-to-zsh-hist.py 2> /dev/null
                python3 bash-to-zsh-hist.py < $HOME/.bash_history >> $HOME/.zsh_history 2> /dev/null
                logSuccess "bash_history copied to zsh_history"
            else
                logError "Python is not installed, can't copy bash_history to zsh_history"
            fi
        fi
    else
        logWarning "Not copying bash_history to zsh_history (use --cp-hist or -c to enable)"
    fi
    echo
}

finish_installation() {
    local end_time=$(date +%s)

    print_header "Installation Complete!" "$GREEN" "$BG_GREEN"
    logSuccess "CZSH installation completed successfully! $SPARKLES"

    print_installation_summary "$INSTALL_START_TIME" "$end_time"

    if [ "$noninteractive_flag" = true ]; then
        echo
        printf "${GREEN}${BOLD}🎉 Enjoy your enhanced zsh experience! 🎉${RESET}\n"
    else
        logWarning "Sudo access is needed to change default shell"

        if chsh -s "$(which zsh)" && /bin/zsh -i -c 'omz update'; then
            logSuccess "Installation complete, exit terminal and enter a new zsh session"
            logTip "In a new zsh session manually run: build-fzf-tab-module"
        else
            logError "Something went wrong, the password you entered might be incorrect"
        fi
    fi
}

install_nvim() {
    print_section "Neovim Installation" "$FIRE" "$BLUE"

    if ! command -v nvim &> /dev/null; then
        logInstalling "Neovim"
        curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz 2> /dev/null
        sudo rm -rf /opt/nvim
        sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
        sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
        rm nvim-linux-x86_64.tar.gz

        logProgress "Setting up NvChad configuration..."
        git clone --quiet https://github.com/NvChad/starter ~/.config/nvim 2> /dev/null && nvim --headless +qall 2> /dev/null
        logInstalled "Neovim with NvChad"
    else
        logAlreadyInstalled "Neovim"
    fi
    echo
}

configure_gemini_cli() {
    print_section "Gemini CLI Configuration" "$STAR" "$CYAN"
    logConfiguring "Gemini CLI"

    # Source nvm to ensure npm is available
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Check if npm is available
    if ! command -v npm &> /dev/null; then
        logError "npm is not available. Node.js installation may have failed."
        return 1
    fi

    # Install Gemini CLI globally
    logInstalling "Gemini CLI globally"
    if npm install -g @google/gemini-cli > /dev/null 2>&1; then
        logInstalled "Gemini CLI"

        # Create configuration directory
        mkdir -p $HOME/.config/czsh/gemini

        # Ask user for authentication preference
        echo
        printf "${CYAN}${BOLD}Choose authentication method for Gemini CLI:${RESET}\n"
        printf "${WHITE}1.${RESET} API Key (requires Google AI Studio key)\n"
        printf "${WHITE}2.${RESET} OAuth (will authenticate later with 'gemini auth')\n"
        printf "${WHITE}3.${RESET} Skip configuration\n"
        read -p "$(printf "${YELLOW}Enter your choice (1-3): ${RESET}")" auth_choice

        case $auth_choice in
            1)
                echo
                logInfo "Get your API key from: https://aistudio.google.com/apikey"
                read -s -p "$(printf "${YELLOW}🔑 Enter your Gemini API key: ${RESET}")"
                GEMINI_API_KEY=$REPLY
                echo

                if [[ -n "$GEMINI_API_KEY" ]]; then
                    # Create config file with API key
                    cat > $HOME/.config/czsh/gemini/config.sh << EOF
#!/bin/bash
# Gemini CLI Configuration
export GEMINI_API_KEY="$GEMINI_API_KEY"
EOF
                    logConfigured "API key saved to ~/.config/czsh/gemini/config.sh"
                else
                    logWarning "No API key provided. You can set it later in ~/.config/czsh/gemini/config.sh"
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
                logConfigured "Configuration file created. Run 'gemini auth' after installation to authenticate"
                ;;
            3)
                # Create minimal config file
                cat > $HOME/.config/czsh/gemini/config.sh << 'EOF'
#!/bin/bash
# Gemini CLI Configuration - Run 'gemini auth' to authenticate
EOF
                logConfigured "Minimal configuration created"
                ;;
            *)
                logWarning "Invalid choice. Creating minimal configuration"
                cat > $HOME/.config/czsh/gemini/config.sh << 'EOF'
#!/bin/bash
# Gemini CLI Configuration - Run 'gemini auth' to authenticate
EOF
                ;;
        esac
    else
        logError "Failed to install Gemini CLI"
        return 1
    fi
    echo
}

configure_claude_cli() {
    print_section "Claude CLI Configuration" "$FIRE" "$PURPLE"
    logConfiguring "Claude CLI"

    # Source nvm to ensure npm is available
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Check if npm is available
    if ! command -v npm &> /dev/null; then
        logError "npm is not available. Node.js installation may have failed."
        return 1
    fi

    # Install Claude CLI globally
    logInstalling "Claude CLI globally"
    if npm install -g @anthropic-ai/claude-code > /dev/null 2>&1; then
        logInstalled "Claude CLI"

        # Create configuration directory
        mkdir -p $HOME/.config/czsh/claude

        # Ask user for authentication preference
        echo
        printf "${PURPLE}${BOLD}Choose authentication method for Claude CLI:${RESET}\n"
        printf "${WHITE}1.${RESET} API Key (requires Anthropic API key)\n"
        printf "${WHITE}2.${RESET} Skip configuration (authenticate later with Claude)\n"
        read -p "$(printf "${YELLOW}Enter your choice (1-2): ${RESET}")" auth_choice

        case $auth_choice in
            1)
                echo
                logInfo "Get your API key from: https://console.anthropic.com/settings/keys"
                read -s -p "$(printf "${YELLOW}🔑 Enter your Anthropic API key: ${RESET}")"
                ANTHROPIC_API_KEY=$REPLY
                echo

                if [[ -n "$ANTHROPIC_API_KEY" ]]; then
                    # Create config file with API key
                    cat > $HOME/.config/czsh/claude/config.sh << EOF
#!/bin/bash
# Claude CLI Configuration
export ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"
EOF
                    logConfigured "API key saved to ~/.config/czsh/claude/config.sh"
                else
                    logWarning "No API key provided. You can set it later in ~/.config/czsh/claude/config.sh"
                fi
                ;;
            2)
                # Create minimal config file
                cat > $HOME/.config/czsh/claude/config.sh << 'EOF'
#!/bin/bash
# Claude CLI Configuration

# Set your Anthropic API key here (get it from https://console.anthropic.com/settings/keys)
# export ANTHROPIC_API_KEY="your_api_key_here"

# Uncomment the line above and replace with your actual API key
# Or authenticate directly when running claude for the first time
EOF
                logConfigured "Configuration file created. You can authenticate when running claude for the first time"
                ;;
            *)
                logWarning "Invalid choice. Creating minimal configuration"
                cat > $HOME/.config/czsh/claude/config.sh << 'EOF'
#!/bin/bash
# Claude CLI Configuration - Set your API key or authenticate when running claude
EOF
                ;;
        esac

        logTip "Usage: Navigate to your project directory and run 'claude' to start"
        logTip "Use '/bug' command within Claude CLI to report issues"
    else
        logError "Failed to install Claude CLI"
        return 1
    fi
    echo
}

install_nodejs() {
    print_section "Node.js Installation" "$ZAPP" "$GREEN"
    logProgress "Checking Node.js installation..."

    # Check if node is already available
    if command -v node &> /dev/null; then
        local node_version=$(node -v)
        logAlreadyInstalled "Node.js $node_version"
        return 0
    fi

    logProgress "Node.js not found. Installing via nvm..."

    # Download and install nvm
    if ! command -v nvm &> /dev/null && [ ! -f "$HOME/.nvm/nvm.sh" ]; then
        logInstalling "nvm (Node Version Manager)"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh 2> /dev/null | bash

        if [ $? -ne 0 ]; then
            logError "Failed to install nvm"
            return 1
        fi
        logInstalled "nvm"
    fi

    # Source nvm to make it available in current session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    # Install Node.js version 22
    logInstalling "Node.js v22"
    if nvm install 22 > /dev/null 2>&1; then
        nvm use 22 > /dev/null 2>&1
        nvm alias default 22 > /dev/null 2>&1

        # Verify installation
        local node_version=$(node -v)
        local npm_version=$(npm -v)

        logInstalled "Node.js $node_version"
        logSuccess "npm version: $npm_version"
        echo
        return 0
    else
        logError "Failed to install Node.js"
        return 1
    fi
}
#############################################################################################
####################################### MAIN SCRIPT #########################################
#############################################################################################

print_section "Prerequisites Check" "$CHECKMARK" "$YELLOW"
logProgress "Detecting missing packages..."
detect_missing_packages

if [ ${#missing_packages[@]} -gt 0 ]; then
    logWarning "Missing packages found: ${missing_packages[*]}"
else
    logSuccess "All prerequisites are satisfied!"
fi
echo

install_missing_packages

install_nodejs

backup_existing_zshrc_config

print_section "Directory Setup" "$FOLDER" "$CYAN"
logInfo "The setup will be installed in '$HOME/.config/czsh'"
logNote "Place your personal zshrc config files under '$HOME/.config/czsh/zshrc/'"

mkdir -p $HOME/.config/czsh/zshrc
logSuccess "Created configuration directories"
echo

configure_ohmzsh

# Copy configuration files
print_section "Configuration Files" "$GEAR" "$BLUE"
logProgress "Copying configuration files..."
cp -f ./.zshrc $HOME/
cp -f ./czshrc.zsh $HOME/.config/czsh/

mkdir -p $HOME/.config/czsh/zshrc # PLACE YOUR ZSHRC CONFIGURATIONS OVER THERE
mkdir -p $HOME/.cache/zsh/        # this will be used to store .zcompdump zsh completion cache files which normally clutter $HOME
mkdir -p $HOME/.fonts             # Create .fonts if doesn't exist

if [ -f $HOME/.zcompdump ]; then
    logProgress "Moving zsh completion cache files..."
    mv $HOME/.zcompdump* $HOME/.cache/zsh/
    logSuccess "Moved completion cache files to ~/.cache/zsh/"
fi

logSuccess "Configuration files copied successfully"
echo

# Optional configurations based on flags
if [ "$zsh_codex_flag" = true ]; then
    configure_zsh_codex
fi

if [ "$gemini_cli_flag" = true ]; then
    configure_gemini_cli
fi

if [ "$claude_cli_flag" = true ]; then
    configure_claude_cli
fi

install_powerlevel10k

print_section "Nerd Fonts Installation" "$SPARKLES" "$PURPLE"
logProgress "Installing Nerd Fonts (Hack, Roboto Mono, DejaVu Sans Mono)..."

font_count=0
total_fonts=3

if [ ! -f $HOME/.fonts/HackNerdFont-Regular.ttf ]; then
    ((font_count++))
    logStepProgress "$font_count" "$total_fonts" "Downloading HackNerdFont-Regular.ttf"
    wget -q --show-progress -N https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Hack/Regular/HackNerdFont-Regular.ttf -P $HOME/.fonts/ 2> /dev/null
    logInstalled "HackNerdFont-Regular.ttf"
else
    logAlreadyInstalled "HackNerdFont-Regular.ttf"
fi

if [ ! -f $HOME/.fonts/RobotoMonoNerdFont-Regular.ttf ]; then
    ((font_count++))
    logStepProgress "$font_count" "$total_fonts" "Downloading RobotoMonoNerdFont-Regular.ttf"
    wget -q --show-progress -N https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/RobotoMono/Regular/RobotoMonoNerdFont-Regular.ttf -P $HOME/.fonts/ 2> /dev/null
    logInstalled "RobotoMonoNerdFont-Regular.ttf"
else
    logAlreadyInstalled "RobotoMonoNerdFont-Regular.ttf"
fi

if [ ! -f $HOME/.fonts/DejaVuSansMNerdFont-Regular.ttf ]; then
    ((font_count++))
    logStepProgress "$font_count" "$total_fonts" "Downloading DejaVuSansMNerdFont-Regular.ttf"
    wget -q --show-progress -N https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/DejaVuSansMono/Regular/DejaVuSansMNerdFont-Regular.ttf -P $HOME/.fonts/ 2> /dev/null
    logInstalled "DejaVuSansMNerdFont-Regular.ttf"
else
    logAlreadyInstalled "DejaVuSansMNerdFont-Regular.ttf"
fi

logProgress "Refreshing font cache..."
fc-cache -fv $HOME/.fonts > /dev/null 2>&1
logSuccess "Font cache updated successfully"
echo

install_fzf

install_lazydocker

setup_plugins

install_todo

install_nvim

copy_history

finish_installation

exit
