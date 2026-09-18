if [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
elif [ -f "$HOME/.config/czsh/fzf/shell/completion.zsh" ]; then
    source "$HOME/.config/czsh/fzf/shell/completion.zsh"
fi

if [ -f "$HOME/.config/czsh/fzf/shell/key-bindings.zsh" ]; then
    source "$HOME/.config/czsh/fzf/shell/key-bindings.zsh"
fi

if [ -d "$HOME/.config/czsh/fzf/bin" ]; then
    export PATH="$PATH:$HOME/.config/czsh/fzf/bin"
fi

export FZF_DEFAULT_OPTS="--extended"

# Keep Tab as the completion trigger, then use it to mark multiple results in
# fzf-tab. Enter accepts every marked completion.
zstyle ':fzf-tab:*' fzf-bindings \
    'tab:toggle+down' \
    'btab:toggle+up'
