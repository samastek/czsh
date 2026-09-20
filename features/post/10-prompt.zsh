# CZSH prompt — tmux carries Git context when available; plain terminals do too.

[[ -o interactive ]] || return

autoload -Uz add-zsh-hook vcs_info

# Prompt substitution is unnecessary here and can reinterpret text embedded in
# prompt values. Standard percent escapes such as %~ continue to work without it.
unsetopt prompt_subst

# Override these in ~/.config/czsh/zshrc/*.zsh if desired.
: ${CZSH_PROMPT_PURPLE:=$CZSH_THEME_PURPLE}

zstyle ':vcs_info:git:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{$CZSH_PROMPT_GREEN}+%f"
zstyle ':vcs_info:git:*' unstagedstr "%F{$CZSH_PROMPT_RED}*%f"
zstyle ':vcs_info:git:*' formats "%F{$CZSH_PROMPT_PURPLE} %b%f%c%u"
zstyle ':vcs_info:git:*' actionformats "%F{$CZSH_PROMPT_PURPLE} %b|%a%f%c%u"

_czsh_prompt_precmd() {
    local last_status=$?
    local context=''
    local git_context=''

    # Identity is normally noise, but remains useful over SSH or as root.
    if [[ -n $SSH_CONNECTION || EUID == 0 ]]; then
        context="%F{$CZSH_PROMPT_YELLOW}%n@%m%f "
    fi

    if [[ -z $TMUX ]]; then
        vcs_info
        [[ -n $vcs_info_msg_0_ ]] && git_context=" ${vcs_info_msg_0_}"
    fi

    # Preserve the two-line shape and home-relative path. Git is shown here
    # only outside tmux because the tmux status line already carries it.
    PROMPT="%F{$CZSH_PROMPT_MUTED}╭─%f ${context}%F{$CZSH_PROMPT_BLUE}󰉋 %~%f${git_context}"$'\n'
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
