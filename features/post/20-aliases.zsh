# Oh My Zsh defines its own `l` alias while loading. Apply CZSH's modern-tool
# defaults afterwards so the documented commands are the ones users receive.
if command -v eza >/dev/null 2>&1; then
    alias l='eza -la --git --icons'
else
    alias l='ls -la'
fi

if [[ "$CZSH_BAT_BIN" != cat ]]; then
    alias cat="$CZSH_BAT_BIN -p"
fi

if command -v delta >/dev/null 2>&1; then
    export GIT_PAGER='delta'
fi
