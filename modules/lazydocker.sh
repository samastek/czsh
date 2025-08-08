#!/usr/bin/env bash
czsh_install_lazydocker() {
  local dest="$CZSH_CONFIG_DIR/lazydocker"
  ensure_clone "$REPO_LAZYDOCKER" "$dest"
  if [[ -x $dest/scripts/install_update_linux.sh ]]; then
    "$dest/scripts/install_update_linux.sh" >/dev/null 2>&1 || logWarning "lazydocker script failed"
  fi
}
register_component "Lazydocker" czsh_install_lazydocker
