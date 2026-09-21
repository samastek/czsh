# CZSH prompt — native Zsh prompt with Git context in every terminal.

[[ -o interactive ]] || return

autoload -Uz add-zsh-hook

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
    done < <(command git status --porcelain=v2 --branch --show-stash 2>/dev/null)

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

_czsh_prompt_precmd() {
    local last_status=$?
    local context=''
    local git_context=''

    # Identity is normally noise, but remains useful over SSH or as root.
    if [[ -n $SSH_CONNECTION || EUID == 0 ]]; then
        context="%F{$CZSH_PROMPT_YELLOW}%n@%m%f "
    fi

    _czsh_git_prompt
    [[ -n $REPLY ]] && git_context=" ${REPLY}"

    # Preserve the two-line shape, home-relative path, and original Git visuals.
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
