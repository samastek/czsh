[[ -o interactive ]] || return

if command -v atuin >/dev/null 2>&1; then
    # Atuin owns Ctrl+R; FZF remains available for files, directories, and
    # completion. Up-arrow history behavior is left unchanged.
    typeset -ga _czsh_suggestion_strategy=("${ZSH_AUTOSUGGEST_STRATEGY[@]:-history}")
    eval "$(atuin init zsh --disable-up-arrow)"
    ZSH_AUTOSUGGEST_STRATEGY=("${_czsh_suggestion_strategy[@]}")
    unset _czsh_suggestion_strategy
fi
