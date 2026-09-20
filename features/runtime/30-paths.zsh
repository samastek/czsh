path=(
    "$HOME/.config/czsh/bin"
    "$HOME/.local/bin"
    "$HOME/.config/czsh/fzf/bin"
    $path
)
typeset -U path
export PATH

export ZSH_COMPDUMP="$HOME/.cache/zsh/.zcompdump-${ZSH_VERSION}"
SAVEHIST=50000
