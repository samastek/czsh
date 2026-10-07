# CZSH keeps this loader and third-party additions intact during upgrades.
# Optional personal overrides live in ~/.config/czsh/zshrc/.


# Load czsh configurations
source "$HOME/.config/czsh/czshrc.zsh"

# Any zshrc configurations under the folder ~/.config/czsh/zshrc/ will override the default czsh configs.
# Place all of your personal configurations over there
ZSH_CONFIGS_DIR="$HOME/.config/czsh/zshrc"

[[ -d "$ZSH_CONFIGS_DIR" ]] || mkdir -p "$ZSH_CONFIGS_DIR"

for file in "$ZSH_CONFIGS_DIR"/*(N-.) "$ZSH_CONFIGS_DIR"/.*(N-.); do
    source "$file"
done

# Now source oh-my-zsh.sh so that any plugins added in ~/.config/czsh/zshrc/* files also get loaded
source "$ZSH/oh-my-zsh.sh"

CZSH_POST_FEATURES_DIR="$HOME/.config/czsh/features/post"
for feature_file in "$CZSH_POST_FEATURES_DIR"/*.zsh(N-.); do
    source "$feature_file"
done

if [[ -f "$HOME/.ghcup/env" ]]; then
    source "$HOME/.ghcup/env"
fi
