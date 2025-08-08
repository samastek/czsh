#!/usr/bin/env bash
czsh_copy_history() {
  [[ ${CP_HIST_FLAG:-false} != true ]] && { logInfo "History migration skipped"; return; }
  local tmp_script="bash-to-zsh-hist.py"
  wget -q https://gist.githubusercontent.com/muendelezaji/c14722ab66b505a49861b8a74e52b274/raw/49f0fb7f661bdf794742257f58950d209dd6cb62/bash-to-zsh-hist.py || { logWarning "History script download failed"; return; }
  (python3 "$tmp_script" < "$HOME/.bash_history" >> "$HOME/.zsh_history" 2>/dev/null || python "$tmp_script" < "$HOME/.bash_history" >> "$HOME/.zsh_history") && logSuccess "bash history merged" || logWarning "bash history merge failed"
  rm -f "$tmp_script"
}
register_component "History Migration" czsh_copy_history CP_HIST_FLAG
