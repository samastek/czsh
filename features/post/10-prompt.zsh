# CZSH prompt — native Zsh prompt with Git context in every terminal.

[[ -o interactive ]] || return

autoload -Uz add-zsh-hook
zmodload zsh/datetime
zmodload zsh/system
typeset -g _CZSH_GIT_JOB_CONTROL=$options[monitor]

# Prompt substitution is unnecessary here and can reinterpret text embedded in
# prompt values. Standard percent escapes such as %~ continue to work without it.
unsetopt prompt_subst

# These are the colors used by the former tmux Git capsule. Keeping them
# separate from the shared palette preserves that segment's exact appearance.
: ${CZSH_GIT_PROMPT_BG:='#161b22'}
: ${CZSH_GIT_BRANCH_BG:='#78a99f'}
: ${CZSH_GIT_STATE_BG:='#22272e'}
: ${CZSH_GIT_REMOTE_FG:='#80a8d8'}
: ${CZSH_GIT_STAGED_FG:='#87b886'}
: ${CZSH_GIT_MODIFIED_FG:='#d6ae68'}
: ${CZSH_GIT_UNTRACKED_FG:='#8b949e'}
: ${CZSH_GIT_CONFLICTED_FG:='#d4777f'}
: ${CZSH_GIT_STASH_FG:='#78a99f'}

_czsh_git_prompt() {
    local line head='' oid='' xy=''
    local -i ahead=0 behind=0 stash=0
    local -i staged=0 modified=0 untracked=0 conflicted=0 has_state=0

    REPLY=''

    while IFS= read -r line; do
        case $line in
            '# branch.head '*) head=${line#\# branch.head } ;;
            '# branch.oid '*)  oid=${line#\# branch.oid } ;;
            '# branch.ab +'* )
                ahead=${${line#\# branch.ab +}%% *}
                behind=${line##* -}
                ;;
            '# stash '*) stash=${line#\# stash } ;;
            '1 '*|'2 '*)
                xy=${line[3,4]}
                [[ ${xy[1]} != '.' ]] && (( staged++ ))
                [[ ${xy[2]} != '.' ]] && (( modified++ ))
                ;;
            'u '*) (( conflicted++ )) ;;
            '? '*) (( untracked++ )) ;;
        esac
    done < <(GIT_OPTIONAL_LOCKS=0 command git status --porcelain=v2 --branch --show-stash </dev/null 2>/dev/null)

    [[ -n $head ]] || return
    [[ $head == '(detached)' ]] && head="@${oid[1,7]}"

    # A branch name can contain %, which Zsh would otherwise treat as a prompt
    # escape even though prompt_subst is disabled.
    head=${head//\%/%%}
    has_state=$(( ahead || behind || staged || modified || untracked || conflicted || stash ))

    REPLY="%F{$CZSH_GIT_BRANCH_BG}%K{$CZSH_GIT_PROMPT_BG}"
    REPLY+="%F{$CZSH_GIT_PROMPT_BG}%K{$CZSH_GIT_BRANCH_BG}%B  ${head} %b"

    if (( has_state )); then
        REPLY+="%F{$CZSH_GIT_BRANCH_BG}%K{$CZSH_GIT_STATE_BG}"
        (( ahead ))      && REPLY+=" %F{$CZSH_GIT_REMOTE_FG}%K{$CZSH_GIT_STATE_BG}⇡${ahead}"
        (( behind ))     && REPLY+=" %F{$CZSH_GIT_REMOTE_FG}%K{$CZSH_GIT_STATE_BG}⇣${behind}"
        (( staged ))     && REPLY+=" %F{$CZSH_GIT_STAGED_FG}%K{$CZSH_GIT_STATE_BG}+${staged}"
        (( modified ))   && REPLY+=" %F{$CZSH_GIT_MODIFIED_FG}%K{$CZSH_GIT_STATE_BG}~${modified}"
        (( untracked ))  && REPLY+=" %F{$CZSH_GIT_UNTRACKED_FG}%K{$CZSH_GIT_STATE_BG}?${untracked}"
        (( conflicted )) && REPLY+=" %F{$CZSH_GIT_CONFLICTED_FG}%K{$CZSH_GIT_STATE_BG}!${conflicted}"
        (( stash ))      && REPLY+=" %F{$CZSH_GIT_STASH_FG}%K{$CZSH_GIT_STATE_BG}≡${stash}"
        REPLY+=" %F{$CZSH_GIT_STATE_BG}%K{$CZSH_GIT_PROMPT_BG}%k%f"
    else
        REPLY+="%F{$CZSH_GIT_BRANCH_BG}%K{$CZSH_GIT_PROMPT_BG}%k%f"
    fi
}

_czsh_git_cancel() {
    if [[ -n ${_CZSH_GIT_FD:-} ]]; then
        zle -F "$_CZSH_GIT_FD"
        exec {_CZSH_GIT_FD}<&-
        unset _CZSH_GIT_FD
    fi
    if (( ${_CZSH_GIT_PID:-0} > 0 )); then
        kill -TERM -- "-$_CZSH_GIT_PID" 2>/dev/null ||
            kill -TERM "$_CZSH_GIT_PID" 2>/dev/null
        unset _CZSH_GIT_PID
    fi
    return 0
}

_czsh_prompt_render() {
    local git_context=''
    if [[ ${_CZSH_GIT_PROMPT_PWD:-} == "$PWD" && -n ${_CZSH_GIT_CONTEXT:-} ]]; then
        git_context=" $_CZSH_GIT_CONTEXT"
    fi
    PROMPT="${_CZSH_PROMPT_PREFIX}${git_context}"$'\n'
    PROMPT+="%F{$CZSH_PROMPT_MUTED}╰─%f %F{$CZSH_PROMPT_GREEN}❯%f "
}

_czsh_git_ready() {
    [[ "$1" == "${_CZSH_GIT_FD:-}" ]] || return 0
    local git_context='' request_pwd="$_CZSH_GIT_REQUEST_PWD"
    IFS= read -r git_context <&"$_CZSH_GIT_FD"
    unset _CZSH_GIT_PID
    _czsh_git_cancel
    [[ "$request_pwd" == "$PWD" ]] || return 0
    typeset -g _CZSH_GIT_CONTEXT="$git_context" _CZSH_GIT_PROMPT_PWD="$request_pwd"
    _czsh_prompt_render
    if (( $+functions[__atuin_osc133_wrap_prompt] )); then
        __atuin_osc133_wrap_prompt
    fi
    zle reset-prompt
}

_czsh_git_request() {
    if [[ -n ${_CZSH_GIT_FD:-} && $_CZSH_GIT_REQUEST_PWD == "$PWD" ]]; then
        return 0
    fi
    _czsh_git_cancel
    typeset -g _CZSH_GIT_REQUEST_PWD="$PWD"
    exec {_CZSH_GIT_FD}< <(
        { print -r -- "$sysparams[pid]"; _czsh_git_prompt; print -r -- "$REPLY"; } 2>/dev/null
    )
    IFS= read -r _CZSH_GIT_PID <&"$_CZSH_GIT_FD"
    zle -F "$_CZSH_GIT_FD" _czsh_git_ready
}

_czsh_prompt_preexec() {
    typeset -gF _CZSH_COMMAND_STARTED_AT=$EPOCHREALTIME
}

_czsh_prompt_precmd() {
    local last_status=$?
    local context=''
    local duration_context=''
    local -F elapsed seconds
    local -i hundredths minutes

    if [[ -n $_CZSH_COMMAND_STARTED_AT ]]; then
        elapsed=$(( EPOCHREALTIME - _CZSH_COMMAND_STARTED_AT ))
        hundredths=$(( elapsed * 100 + 0.5 ))
        if (( hundredths >= 6000 )); then
            minutes=$(( hundredths / 6000 ))
            seconds=$(( hundredths % 6000 / 100.0 ))
            printf -v duration_context '%dm %.2fs' "$minutes" "$seconds"
        else
            seconds=$(( hundredths / 100.0 ))
            printf -v duration_context '%.2fs' "$seconds"
        fi
        duration_context="%F{$CZSH_PROMPT_MUTED}${duration_context}%f "
        unset _CZSH_COMMAND_STARTED_AT
    fi

    # Identity is normally noise, but remains useful over SSH or as root.
    if [[ -n $SSH_CONNECTION || EUID == 0 ]]; then
        context="%F{$CZSH_PROMPT_YELLOW}%n@%m%f "
    fi

    if [[ ${CZSH_GIT_PROMPT_ASYNC:-true} == true && $_CZSH_GIT_JOB_CONTROL == on && -t 0 && -o zle ]]; then
        _czsh_git_request
    else
        _czsh_git_prompt
        typeset -g _CZSH_GIT_CONTEXT="$REPLY" _CZSH_GIT_PROMPT_PWD="$PWD"
    fi

    # Preserve the two-line shape, home-relative path, and original Git visuals.
    typeset -g _CZSH_PROMPT_PREFIX="%F{$CZSH_PROMPT_MUTED}╭─%f ${context}%F{$CZSH_PROMPT_BLUE}󰉋 %~%f"
    _czsh_prompt_render

    if (( last_status == 0 )); then
        RPROMPT="%F{$CZSH_PROMPT_GREEN}✔ 0%f"
    else
        RPROMPT="%F{$CZSH_PROMPT_RED}✘ ${last_status}%f"
    fi
    RPROMPT="${duration_context}${RPROMPT}"
}

add-zsh-hook preexec _czsh_prompt_preexec
add-zsh-hook precmd _czsh_prompt_precmd
add-zsh-hook zshexit _czsh_git_cancel

# Capture command status before other precmd hooks can replace it.
precmd_functions=(_czsh_prompt_precmd ${precmd_functions:#_czsh_prompt_precmd})
