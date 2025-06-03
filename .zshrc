################# DO NOT MODIFY THIS FILE #######################
####### PLACE YOUR CONFIGS IN ~/.config/czsh/zshrc FOLDER #######
#################################################################

# This file is created by czsh setup.
# Place all your .zshrc configurations / overrides in a single or multiple files under ~/.config/czsh/zshrc/ folder
# Your original .zshrc is backed up at ~/.zshrc-backup-%y-%m-%d


# Load czsh configurations
source "$HOME/.config/czsh/czshrc.zsh"

# Any zshrc configurations under the folder ~/.config/czsh/zshrc/ will override the default czsh configs.
# Place all of your personal configurations over there
ZSH_CONFIGS_DIR="$HOME/.config/czsh/zshrc"

if [ "$(ls -A $ZSH_CONFIGS_DIR)" ]; then
    for file in "$ZSH_CONFIGS_DIR"/* "$ZSH_CONFIGS_DIR"/.*; do
        # Exclude '.' and '..' from being sourced
        if [ -f "$file" ]; then
            source "$file"
        fi
    done
fi

# Enable fzf integration (replaces the need for Oh My Zsh fzf integration)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_OPS="--extended"

# Additional environment setup
[ -f "/home/user/.ghcup/env" ] && . "/home/user/.ghcup/env" # ghcup-env