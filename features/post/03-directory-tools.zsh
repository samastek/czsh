[[ -o interactive ]] || return

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh --cmd z)"
fi

if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi
