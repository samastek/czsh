# Respect the terminal's advertised capabilities (notably tmux-256color).
: ${TERM:="xterm-256color"}
export TERM
export ZSH="$HOME/.config/czsh/oh-my-zsh"
export ZSH_CUSTOM="$ZSH/custom"

# The prompt is initialized after Oh My Zsh by features/post/10-prompt.zsh.
# Keeping the OMZ theme empty avoids loading a theme only to replace it later.
ZSH_THEME=""
