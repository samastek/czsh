#!/usr/bin/env bash
# Node / nvm installer

czsh_install_node() {
  if command -v node >/dev/null 2>&1; then
    logAlreadyInstalled "Node $(node -v)"; return 0; fi
  if ! command -v nvm >/dev/null 2>&1 && [[ ! -f $HOME/.nvm/nvm.sh ]]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh 2>/dev/null | bash || { logError "nvm install failed"; return 1; }
  fi
  export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  nvm install 22 >/dev/null 2>&1 && nvm alias default 22 >/dev/null 2>&1 && logInstalled "Node $(node -v)" || logError "Node install failed"
}
register_component "Node.js" czsh_install_node
