[[ -o interactive ]] || return

if command -v zoxide >/dev/null 2>&1; then
    _czsh_cached_init zoxide init zsh --cmd z
fi

if command -v direnv >/dev/null 2>&1; then
    _czsh_cached_init direnv hook zsh
fi
