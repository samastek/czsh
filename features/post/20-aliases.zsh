# Prefer the modern tools when they are installed.
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
