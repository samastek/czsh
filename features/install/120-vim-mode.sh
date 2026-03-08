#!/bin/bash

install_feature_vim_mode() {
	if [ "$ENABLE_VIM_MODE" != true ]; then
		return 0
	fi

	print_section "Vim Mode Configuration" "$FIRE" "$GREEN"
	logConfiguring "Vim mode for zsh"

	ensure_directories "$CZSH_USER_ZSHRC_DIR"
	cat >"$CZSH_USER_ZSHRC_DIR/vim-mode.zsh" <<'EOF'
# Vim mode configuration for zsh
set -o vi

zle-keymap-select() {
    if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
        echo -ne '\e[1 q'
    elif [[ ${KEYMAP} == main ]] || [[ ${KEYMAP} == viins ]] || [[ ${KEYMAP} = '' ]] || [[ $1 = 'beam' ]]; then
        echo -ne '\e[5 q'
    fi
}
zle -N zle-keymap-select

zle-line-init() {
    echo -ne '\e[5 q'
}
zle -N zle-line-init

bindkey '^?' backward-delete-char
bindkey '^H' backward-delete-char
bindkey '^U' backward-kill-line
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down
bindkey '^R' history-incremental-search-backward

export KEYTIMEOUT=1
EOF

	logConfigured "Vim mode enabled with enhanced key bindings"
	echo
}

register_install_feature install_feature_vim_mode