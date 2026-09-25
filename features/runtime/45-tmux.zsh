# ── Tmux aliases ─────────────────────────────
if command -v tmux >/dev/null 2>&1; then
    alias ta='tmux attach -t'
    alias tls='tmux list-sessions'
    alias tns='tmux new-session -s'
    alias tks='tmux kill-session -t'
fi

# ── tmux-help ────────────────────────────────
tmux-help() {
    local C=$'\033[0;36m'    # cyan
    local B=$'\033[1;34m'    # bold blue
    local Y=$'\033[0;33m'    # yellow
    local G=$'\033[0;32m'    # green
    local D=$'\033[0;90m'    # dim
    local W=$'\033[1;37m'    # white bold
    local R=$'\033[0m'       # reset

    cat <<EOF

${W}╔══════════════════════════════════════════════════════════╗${R}
${W}║              tmux keybinding reference                   ║${R}
${W}║         ${D}prefix = Ctrl+a  ${D}(press first, then key)${W}        ║${R}
${W}╚══════════════════════════════════════════════════════════╝${R}

${B}── Sessions ───────────────────────────────────────────────${R}
  ${Y}prefix + f / Ctrl+f${R}  ${D}│${R} Pick project/session with FZF
  ${Y}prefix + d${R}           ${D}│${R} Detach from session
  ${Y}prefix + s${R}           ${D}│${R} List sessions (interactive picker)
  ${Y}prefix + \$${R}           ${D}│${R} Rename current session
  ${G}tns <name>${R}           ${D}│${R} New named session  ${D}(alias)${R}
  ${G}ta <name>${R}            ${D}│${R} Attach to session  ${D}(alias)${R}
  ${G}tls${R}                  ${D}│${R} List all sessions  ${D}(alias)${R}
  ${G}tks <name>${R}           ${D}│${R} Kill session       ${D}(alias)${R}

${B}── Windows ────────────────────────────────────────────────${R}
  ${Y}prefix + c${R}           ${D}│${R} New window (in current dir)
  ${Y}prefix + ,${R}           ${D}│${R} Rename window
  ${Y}prefix + &${R}           ${D}│${R} Close window
  ${Y}prefix + w${R}           ${D}│${R} Window picker (interactive)
  ${Y}prefix + 1-9${R}         ${D}│${R} Jump to window N
  ${Y}Shift + ←/→${R}         ${D}│${R} Previous / next window ${D}(no prefix)${R}
  ${Y}prefix + < / >${R}       ${D}│${R} Move window left / right

${B}── Panes ──────────────────────────────────────────────────${R}
  ${Y}prefix + |${R}           ${D}│${R} Split vertical   (side by side)
  ${Y}prefix + -${R}           ${D}│${R} Split horizontal (top / bottom)
  ${Y}prefix + h j k l${R}     ${D}│${R} Navigate panes   ${D}(vim-style)${R}
  ${Y}Ctrl + h j k l${R}       ${D}│${R} Cross tmux panes / Vim splits
  ${Y}prefix + H J K L${R}     ${D}│${R} Resize panes     ${D}(5 cells, repeatable)${R}
  ${Y}prefix + x${R}           ${D}│${R} Close current pane
  ${Y}prefix + z${R}           ${D}│${R} Toggle pane zoom (fullscreen)
  ${Y}prefix + !${R}           ${D}│${R} Break pane into new window
  ${Y}prefix + q${R}           ${D}│${R} Show pane numbers (then press N)

${B}── Plugins ────────────────────────────────────────────────${R}
  ${Y}prefix + Ctrl+s${R}      ${D}│${R} Save session    ${D}(tmux-resurrect)${R}
  ${Y}prefix + Ctrl+r${R}      ${D}│${R} Restore session ${D}(tmux-resurrect)${R}
  ${D}Sessions auto-save every 15 minutes and restore on server start.${R}

${B}── Popups ─────────────────────────────────────────────────${R}
  ${Y}prefix + g${R}           ${D}│${R} Lazygit in current directory
  ${Y}prefix + D${R}           ${D}│${R} Lazydocker
  ${Y}prefix + /${R}           ${D}│${R} Search all windows and panes

${B}── General ────────────────────────────────────────────────${R}
  ${Y}prefix + r${R}           ${D}│${R} Reload tmux config
  ${Y}prefix + e${R}           ${D}│${R} Show this cheatsheet
  ${Y}prefix + ?${R}           ${D}│${R} Show all keybindings
  ${Y}prefix + t${R}           ${D}│${R} Show clock
  ${D}Tmux ignores the mouse; select text directly in your terminal.${R}

EOF
}
