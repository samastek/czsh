#!/usr/bin/env bash
czsh_configure_vim_mode() {
  mkdir -p "$CZSH_ZSHRC_DIR"
  cat > "$CZSH_ZSHRC_DIR/vim-mode.zsh" <<'EOF'
set -o vi
function zle-keymap-select { if [[ ${KEYMAP} == vicmd ]]; then echo -ne '\e[1 q'; else echo -ne '\e[5 q'; fi }
zle -N zle-keymap-select
zle-line-init() { echo -ne '\e[5 q'; }
zle -N zle-line-init
bindkey "^?" backward-delete-char
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down
export KEYTIMEOUT=1
EOF
  logConfigured "Vim mode"
}
register_component "Vim Mode" czsh_configure_vim_mode VIM_MODE_FLAG
