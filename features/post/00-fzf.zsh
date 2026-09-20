# Widgets and completion need a real line editor. Skipping them for `zsh -ic`
# without a TTY also keeps startup benchmarks and remote command execution quiet.
if [[ -o interactive && -t 0 ]]; then
    if [[ -f "$HOME/.fzf.zsh" ]]; then
        # The FZF installer generates this loader; it already includes both
        # completion and key bindings, so do not source the managed files again.
        source "$HOME/.fzf.zsh"
    else
        [[ -f "$HOME/.config/czsh/fzf/shell/completion.zsh" ]] && \
            source "$HOME/.config/czsh/fzf/shell/completion.zsh"
        [[ -f "$HOME/.config/czsh/fzf/shell/key-bindings.zsh" ]] && \
            source "$HOME/.config/czsh/fzf/shell/key-bindings.zsh"
    fi
fi

if [ -d "$HOME/.config/czsh/fzf/bin" ]; then
    export PATH="$PATH:$HOME/.config/czsh/fzf/bin"
fi

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:+$FZF_DEFAULT_OPTS }--extended"

# Inside fzf-tab, Tab only moves through the results. Ctrl-Space toggles the
# current result for multi-selection; terminals that can distinguish Ctrl-Tab
# may map it to Ctrl-Space to use Ctrl-Tab as the physical shortcut.
zstyle ':fzf-tab:*' fzf-bindings \
    'tab:down' \
    'btab:up' \
    'ctrl-space:toggle+down'
