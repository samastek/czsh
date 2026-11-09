# CZSH shell core: history, completion, key bindings and plugins. This covers
# what CZSH used from Oh My Zsh, without the framework.

[[ -o interactive ]] || return

typeset -g CZSH_PLUGIN_DIR="$HOME/.config/czsh/plugins"

# ─── History ─────────────────────────────────
: ${HISTFILE:=$HOME/.zsh_history}
HISTSIZE=50000
setopt extended_history hist_expire_dups_first hist_ignore_dups \
    hist_ignore_space hist_verify share_history

# ─── Directories, jobs and colors ────────────
setopt auto_cd auto_pushd pushd_ignore_dups pushd_minus long_list_jobs
unsetopt flow_control
alias -- -='cd -'
alias ...='../..' ....='../../..' md='mkdir -p'
export CLICOLOR=1 PAGER="${PAGER:-less}" LESS="${LESS:--R}"
[[ $CZSH_PLATFORM == linux ]] && alias ls='ls --color=auto'
if (( $+commands[ugrep] )); then
    alias grep='ugrep -G' egrep='ugrep -E' fgrep='ugrep -F'
else
    alias grep='grep --color=auto'
fi

# ─── Completion ──────────────────────────────
setopt complete_in_word always_to_end
fpath=("$CZSH_PLUGIN_DIR/zsh-completions/src" "$CZSH_PLUGIN_DIR"/${^plugins}(N/) $fpath)
zmodload zsh/complist
autoload -Uz compinit
() {
    setopt local_options extended_glob
    mkdir -p "${ZSH_COMPDUMP:h}"
    # Rebuild and security-check the dump at most once a day; -i skips
    # insecure directories instead of prompting.
    if [[ -n $ZSH_COMPDUMP(#qN.mh-20) ]]; then
        compinit -C -d "$ZSH_COMPDUMP"
    else
        compinit -i -d "$ZSH_COMPDUMP"
    fi
}
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache"
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"

# ─── Key bindings ────────────────────────────
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# Esc Esc toggles sudo in front of the current (or previous) command.
_czsh_sudo_toggle() {
    [[ -n $BUFFER ]] || { BUFFER="$(fc -ln -1)"; CURSOR=$#BUFFER; }
    if [[ $BUFFER == 'sudo '* ]]; then
        BUFFER="${BUFFER#sudo }"
        (( CURSOR = CURSOR > 5 ? CURSOR - 5 : 0 ))
    else
        BUFFER="sudo $BUFFER"
        (( CURSOR += 5 ))
    fi
}
zle -N _czsh_sudo_toggle

() {
    local keymap key
    local -A keys=(
        '^[[A' up-line-or-beginning-search    '^[OA' up-line-or-beginning-search
        '^[[B' down-line-or-beginning-search  '^[OB' down-line-or-beginning-search
        '^[[H' beginning-of-line  '^[OH' beginning-of-line  '^[[1~' beginning-of-line
        '^[[F' end-of-line        '^[OF' end-of-line        '^[[4~' end-of-line
        '^[[3~' delete-char       '^[[3;5~' kill-word
        '^[[1;5C' forward-word    '^[[1;5D' backward-word
        '^[[Z' reverse-menu-complete
        '^[^[' _czsh_sudo_toggle
    )
    for keymap in emacs viins vicmd; do
        for key in ${(k)keys}; do
            bindkey -M $keymap "$key" "$keys[$key]"
        done
    done
}

# ─── Window title ────────────────────────────
if [[ $TERM != (dumb|linux) ]]; then
    _czsh_title_precmd() { print -Pn '\e]2;%~\a' }
    _czsh_title_preexec() { print -rn -- $'\e]2;'"${${1//[[:cntrl:]]}[1,80]}"$'\a' }
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd _czsh_title_precmd
    add-zsh-hook preexec _czsh_title_preexec
fi

# ─── Plugins ─────────────────────────────────
# fzf-tab must follow compinit; syntax highlighting must load last. Names in
# $plugins (from personal overrides) load from $CZSH_PLUGIN_DIR/<name>/.
() {
    local name file
    for name in fzf-tab $plugins zsh-autosuggestions zsh-syntax-highlighting; do
        for file in "$CZSH_PLUGIN_DIR/$name/$name".{plugin.zsh,zsh}(N); do
            source "$file"
            break
        done
    done
}
