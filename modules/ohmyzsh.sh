#!/usr/bin/env bash
# Oh My Zsh setup + plugins

czsh_setup_ohmyzsh() {
  ensure_dir "$OH_MY_ZSH_FOLDER"
  if [[ -d $OH_MY_ZSH_FOLDER/.git ]]; then
    git -C "$OH_MY_ZSH_FOLDER" remote set-url origin "$REPO_OHMYZSH"
    git -C "$OH_MY_ZSH_FOLDER" pull --quiet --ff-only && logUpdated "oh-my-zsh" || logWarning "oh-my-zsh update failed (non-ff)"
  else
    rm -rf "$OH_MY_ZSH_FOLDER" && git clone --depth 1 --quiet "$REPO_OHMYZSH" "$OH_MY_ZSH_FOLDER" && logInstalled "oh-my-zsh"
  fi
}

czsh_install_plugins() {
  source "$CZSH_ROOT_DIR/core/plugins.sh"
  czsh_each_plugin czsh_handle_plugin
}

czsh_handle_plugin() { # name repo flags
  local name=$1 repo=$2
  local dest="$OHMYZSH_CUSTOM_PLUGIN_PATH/$name"
  ensure_dir "$OHMYZSH_CUSTOM_PLUGIN_PATH"
  if [[ -d $dest/.git ]]; then
    # Attempt fast-forward; if fails, fallback to rebase; else warn
    if git -C "$dest" fetch --quiet && git -C "$dest" merge --ff-only FETCH_HEAD --quiet 2>/dev/null; then
      logUpdated "$name"
    elif git -C "$dest" pull --rebase --autostash --quiet 2>/dev/null; then
      logUpdated "$name" "(rebased)"
    else
      logWarning "Update failed for $dest; keeping existing version"
    fi
  else
    git clone --depth 1 --quiet "$repo" "$dest" && logInstalled "$name" || logWarning "Clone failed for $name"
  fi
}

czsh_ohmyzsh_main() { czsh_setup_ohmyzsh; czsh_install_plugins; }
register_component "Oh My Zsh & Plugins" czsh_ohmyzsh_main
