#!/usr/bin/env bash
czsh_install_fzf() {
  local dest="$CZSH_CONFIG_DIR/fzf"
  ensure_clone "$REPO_FZF" "$dest"
  if [[ -x $dest/install ]]; then
    "$dest/install" --all --key-bindings --completion --no-update-rc --no-bash --no-fish >/dev/null 2>&1 || logWarning "fzf install script issues"
  fi
}
register_component "FZF" czsh_install_fzf
