#!/bin/bash

##########################################################
###################### SOURCE FILES ######################
##########################################################
source ./utils.sh
##########################################################

# Detect OS and run appropriate install script
detect_os_and_run() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        logInfo "🍎 Detected macOS - Running macOS installation script\n"
        exec ./install-macos.sh "$@"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        logInfo "🐧 Detected Linux - Running Debian/Ubuntu installation script\n"
        exec ./install-debian.sh "$@"
    else
        echo "❌ Unsupported operating system: $OSTYPE"
        echo ""
        echo "Supported operating systems:"
        echo "  • macOS (Intel and Apple Silicon)"
        echo "  • Linux (Debian, Ubuntu, and derivatives)"
        echo ""
        echo "If you're using a different Linux distribution, try running:"
        echo "  ./install-debian.sh"
        echo ""
        exit 1
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Universal installer for czsh (Customized Zsh) that automatically detects"
    echo "your operating system and runs the appropriate installation script."
    echo ""
    echo "OPTIONS:"
    echo "  --cp-hist, -c     Copy bash history to zsh history"
    echo "  --interactive, -n Run in interactive mode (prompts for shell change)"
    echo "  --codex, -x       Enable zsh-codex with OpenAI integration"
    echo "  --help, -h        Show this help message"
    echo ""
    echo "EXAMPLES:"
    echo "  $0                      # Basic installation"
    echo "  $0 --cp-hist --codex    # Install with bash history copy and OpenAI codex"
    echo "  $0 -c -x               # Same as above (short flags)"
    echo ""
    echo "SUPPORTED OPERATING SYSTEMS:"
    echo "  • macOS (Intel and Apple Silicon Macs)"
    echo "  • Linux (Debian, Ubuntu, Arch, Fedora, CentOS)"
    echo ""
    echo "The installer will automatically:"
    echo "  • Install oh-my-zsh and plugins"
    echo "  • Install fzf for fuzzy finding"
    echo "  • Install powerlevel10k theme"
    echo "  • Install lazydocker for Docker management"
    echo "  • Install todo.sh for task management"
    echo "  • Install Neovim with NvChad config"
    echo "  • Install Nerd Fonts"
    echo ""
}

# Check for help flag
for arg in "$@"; do
    case $arg in
        --help | -h)
            show_usage
            exit 0
            ;;
    esac
done

# Check if required files exist
if [ ! -f "./install-macos.sh" ] || [ ! -f "./install-debian.sh" ]; then
    echo "❌ Required installation scripts not found!"
    echo "Please ensure the following files exist in the current directory:"
    echo "  • install-macos.sh"
    echo "  • install-debian.sh"
    echo "  • utils.sh"
    exit 1
fi

# Check if utils.sh exists
if [ ! -f "./utils.sh" ]; then
    echo "❌ utils.sh not found!"
    echo "This file is required for the installation scripts to work properly."
    exit 1
fi

# Run the appropriate installer
detect_os_and_run "$@"

# Run the appropriate installer
detect_os_and_run "$@"
