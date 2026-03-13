typeset -ga plugins

plugins=(
    zsh-completions
    zsh-autosuggestions
    zsh-syntax-highlighting
    history-substring-search
    screen
    web-search
    extract
    z
    sudo
    docker
    fzf-tab
    forgit
)

if [[ "$CZSH_PLATFORM" == "linux" ]]; then
    plugins+=(systemd)
fi

setopt no_nomatch