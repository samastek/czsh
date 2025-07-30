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

# Create the directory if it doesn't exist
mkdir -p "$ZSH_CONFIGS_DIR"

if [ "$(ls -A $ZSH_CONFIGS_DIR 2>/dev/null)" ]; then
    # Set nullglob to handle empty glob patterns gracefully
    setopt nullglob
    for file in "$ZSH_CONFIGS_DIR"/* "$ZSH_CONFIGS_DIR"/.*; do
        # Exclude '.' and '..' from being sourced
        if [ -f "$file" ] && [[ "$(basename "$file")" != "." ]] && [[ "$(basename "$file")" != ".." ]]; then
            source "$file"
        fi
    done
    # Restore default glob behavior
    unsetopt nullglob
fi

# Now source oh-my-zsh.sh so that any plugins added in ~/.config/czsh/zshrc/* files also get loaded
source $ZSH/oh-my-zsh.sh


# Configs that can only work after "source $ZSH/oh-my-zsh.sh", such as Aliases that depend oh-my-zsh plugins

# Now source fzf.zsh , otherwise Ctr+r is overwritten by ohmyzsh
# Try multiple FZF source locations
if [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
elif [ -f "$HOME/.config/czsh/fzf/shell/completion.zsh" ]; then
    source "$HOME/.config/czsh/fzf/shell/completion.zsh"
fi

if [ -f "$HOME/.config/czsh/fzf/shell/key-bindings.zsh" ]; then
    source "$HOME/.config/czsh/fzf/shell/key-bindings.zsh"
fi

# Add FZF to PATH if it exists
if [ -d "$HOME/.config/czsh/fzf/bin" ]; then
    export PATH="$PATH:$HOME/.config/czsh/fzf/bin"
fi

export FZF_DEFAULT_OPS="--extended"


[ -f "/home/user/.ghcup/env" ] && . "/home/user/.ghcup/env" # ghcup-env