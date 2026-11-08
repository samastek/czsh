# Extra Zsh plugins, loaded from ~/.config/czsh/plugins/<name>/ by
# features/post/00-core.zsh. Personal overrides may append names here.
typeset -ga plugins
plugins=()

# Emacs-style line editing unless a personal override (vim-mode.zsh) switches.
bindkey -e

setopt no_nomatch
