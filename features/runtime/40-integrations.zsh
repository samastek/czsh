if [[ -f "$ZSH_CUSTOM/plugins/zsh_codex/zsh_codex.plugin.zsh" ]]; then
    source "$ZSH_CUSTOM/plugins/zsh_codex/zsh_codex.plugin.zsh"
    bindkey '^X' create_completion
fi

[[ -s "$HOME/.config/czsh/marker/marker.sh" ]] && source "$HOME/.config/czsh/marker/marker.sh"
[[ -f "$HOME/.config/czsh/gemini/config.sh" ]] && source "$HOME/.config/czsh/gemini/config.sh"
[[ -f "$HOME/.config/czsh/claude/config.sh" ]] && source "$HOME/.config/czsh/claude/config.sh"