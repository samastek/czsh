# CZSH prompt — deliberately small because tmux carries the rich context.

[[ -o interactive ]] || return

autoload -Uz add-zsh-hook

# Prompt substitution is unnecessary here and can reinterpret text embedded in
# prompt values. Standard percent escapes such as %~ continue to work without it.
unsetopt prompt_subst

# Override these in ~/.config/czsh/zshrc/*.zsh if desired.
: ${CZSH_PROMPT_BLUE:='#7aa2f7'}
: ${CZSH_PROMPT_GREEN:='#9ece6a'}
: ${CZSH_PROMPT_RED:='#f7768e'}
: ${CZSH_PROMPT_YELLOW:='#e0af68'}
: ${CZSH_PROMPT_MUTED:='#565f89'}

_czsh_prompt_precmd() {
    local last_status=$?
    local context=''

    # Identity is normally noise, but remains useful over SSH or as root.
    if [[ -n $SSH_CONNECTION || EUID == 0 ]]; then
        context="%F{$CZSH_PROMPT_YELLOW}%n@%m%f "
    fi

    # Preserve the original two-line shape and home-relative path. Git and time
    # live in tmux; the input line contains only the arrow.
    PROMPT="%F{$CZSH_PROMPT_MUTED}╭─%f ${context}%F{$CZSH_PROMPT_BLUE}󰉋 %~%f"$'\n'
    PROMPT+="%F{$CZSH_PROMPT_MUTED}╰─%f %F{$CZSH_PROMPT_GREEN}❯%f "

    if (( last_status == 0 )); then
        RPROMPT="%F{$CZSH_PROMPT_GREEN}✔ 0%f"
    else
        RPROMPT="%F{$CZSH_PROMPT_RED}✘ ${last_status}%f"
    fi
}

add-zsh-hook precmd _czsh_prompt_precmd

# Capture command status before other precmd hooks can replace it.
precmd_functions=(_czsh_prompt_precmd ${precmd_functions:#_czsh_prompt_precmd})

_czsh_prompt_precmd
