[[ -o interactive ]] || return

if command -v atuin >/dev/null 2>&1; then
    # Atuin owns Ctrl+R; FZF remains available for files, directories, and
    # completion. Up-arrow history behavior is left unchanged.
    eval "$(atuin init zsh --disable-up-arrow)"
fi
