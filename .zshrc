# CZSH keeps this loader and third-party additions intact during upgrades.
# Optional personal overrides live in ~/.config/czsh/zshrc/.


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

CZSH_POST_FEATURES_DIR="$HOME/.config/czsh/features/post"
mkdir -p "$CZSH_POST_FEATURES_DIR"

setopt nullglob
for feature_file in "$CZSH_POST_FEATURES_DIR"/*.zsh; do
    [ -f "$feature_file" ] && source "$feature_file"
done
unsetopt nullglob

if [[ -f "$HOME/.ghcup/env" ]]; then
    source "$HOME/.ghcup/env"
fi
