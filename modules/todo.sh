#!/usr/bin/env bash
czsh_install_todo() {
  local base="$CZSH_CONFIG_DIR/todo"
  ensure_dir "$base" "$CZSH_BIN_DIR"
  if [[ ! -L $base/bin/todo.sh && ! -f $CZSH_BIN_DIR/todo.sh ]]; then
    logInstalling "todo.sh"
    wget -q "https://github.com/todotxt/todo.txt-cli/releases/download/v2.12.0/todo.txt_cli-2.12.0.tar.gz" -P "$CZSH_CONFIG_DIR" || { logError "todo.sh download failed"; return; }
    tar xf "$CZSH_CONFIG_DIR/todo.txt_cli-2.12.0.tar.gz" -C "$base" --strip 1 2>/dev/null && rm "$CZSH_CONFIG_DIR/todo.txt_cli-2.12.0.tar.gz"
    ln -sf "$base/todo.sh" "$CZSH_BIN_DIR/todo.sh"
    ln -sf "$base/todo.cfg" "$HOME/.todo.cfg"
    logInstalled "todo.sh"
  else
    logAlreadyInstalled "todo.sh"
  fi
}
register_component "Todo.sh" czsh_install_todo
