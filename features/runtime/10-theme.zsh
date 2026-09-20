# Tokyo Night is the single CZSH palette. czsh-sync-theme consumes these same
# tokens to generate tmux, bat, and Lazygit configuration.
export CZSH_THEME_BG='#1a1b26'
export CZSH_THEME_FG='#c0caf5'
export CZSH_THEME_BLUE='#7aa2f7'
export CZSH_THEME_GREEN='#9ece6a'
export CZSH_THEME_RED='#f7768e'
export CZSH_THEME_YELLOW='#e0af68'
export CZSH_THEME_PURPLE='#bb9af7'
export CZSH_THEME_MUTED='#565f89'
export CZSH_THEME_BORDER='#30364d'

# Backwards-compatible prompt token names remain user-overridable.
: ${CZSH_PROMPT_BLUE:=$CZSH_THEME_BLUE}
: ${CZSH_PROMPT_GREEN:=$CZSH_THEME_GREEN}
: ${CZSH_PROMPT_RED:=$CZSH_THEME_RED}
: ${CZSH_PROMPT_YELLOW:=$CZSH_THEME_YELLOW}
: ${CZSH_PROMPT_MUTED:=$CZSH_THEME_MUTED}
export CZSH_PROMPT_BLUE CZSH_PROMPT_GREEN CZSH_PROMPT_RED
export CZSH_PROMPT_YELLOW CZSH_PROMPT_MUTED

# Respect the terminal's advertised capabilities and point Oh My Zsh at the
# managed installation. The native prompt is initialized after OMZ.
: ${TERM:="xterm-256color"}
export TERM
export ZSH="$HOME/.config/czsh/oh-my-zsh"
export ZSH_CUSTOM="$ZSH/custom"
ZSH_THEME=""

export BAT_THEME='CZSH'
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:+$FZF_DEFAULT_OPTS }--color=fg:${CZSH_THEME_FG},bg:${CZSH_THEME_BG},hl:${CZSH_THEME_YELLOW},fg+:${CZSH_THEME_FG},bg+:${CZSH_THEME_BORDER},hl+:${CZSH_THEME_YELLOW},info:${CZSH_THEME_BLUE},prompt:${CZSH_THEME_GREEN},pointer:${CZSH_THEME_RED},marker:${CZSH_THEME_PURPLE},spinner:${CZSH_THEME_GREEN},header:${CZSH_THEME_MUTED},border:${CZSH_THEME_BORDER}"

_czsh_lazygit_theme="$HOME/.config/czsh/lazygit/config.yml"
export LG_CONFIG_FILE="${_czsh_lazygit_theme}${LG_CONFIG_FILE:+,$LG_CONFIG_FILE}"
unset _czsh_lazygit_theme
