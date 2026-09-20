#!/bin/bash

install_feature_tmux() {
  local tmux_config_dir="$CZSH_HOME/tmux"
  local tmux_plugins_dir="$tmux_config_dir/plugins"
  local tpm_dir="$tmux_plugins_dir/tpm"
  local tmux_conf_src="$SCRIPT_DIR/dotfiles/tmux.conf"
  local tmux_conf_dst="$tmux_config_dir/tmux.conf"
  local editor_bridge_dir="$CZSH_HOME/editor"
  local editor_bridge="$editor_bridge_dir/czsh-tmux-navigator.vim"
  local editor_target=""

  print_section "Tmux Installation" "$PACKAGE" "$CYAN"

  # ── Install tmux binary ────────────────────
  if command -v tmux >/dev/null 2>&1; then
    logAlreadyInstalled "tmux $(tmux -V | cut -d' ' -f2)"
  else
    logInstalling "tmux"
    if package_manager_install tmux; then
      logInstalled "tmux"
    else
      logError "Failed to install tmux"
      echo
      return 1
    fi
  fi

  # ── Deploy configuration ───────────────────
  logConfiguring "tmux config"
  mkdir -p "$tmux_config_dir" "$tmux_plugins_dir"

  cp "$tmux_conf_src" "$tmux_conf_dst"

  # Symlink ~/.tmux.conf → managed config
  if [ -L "$HOME/.tmux.conf" ]; then
    rm "$HOME/.tmux.conf"
  elif [ -f "$HOME/.tmux.conf" ]; then
    mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak"
    record_backup_path tmux "$HOME/.tmux.conf.bak"
    logWarning "Existing ~/.tmux.conf backed up to ~/.tmux.conf.bak"
  fi
  ln -s "$tmux_conf_dst" "$HOME/.tmux.conf"

  # tmux >= 3.1 looks for ~/.config/tmux/tmux.conf BEFORE ~/.tmux.conf, and
  # ignores ~/.tmux.conf entirely if that file exists. Symlink it too so a
  # stray/older config there can never silently shadow the czsh config.
  local xdg_tmux_dir="$HOME/.config/tmux"
  mkdir -p "$xdg_tmux_dir"
  if [ -L "$xdg_tmux_dir/tmux.conf" ]; then
    rm "$xdg_tmux_dir/tmux.conf"
  elif [ -f "$xdg_tmux_dir/tmux.conf" ]; then
    mv "$xdg_tmux_dir/tmux.conf" "$xdg_tmux_dir/tmux.conf.bak"
    record_backup_path xdg-tmux "$xdg_tmux_dir/tmux.conf.bak"
    logWarning "Existing ~/.config/tmux/tmux.conf backed up to ~/.config/tmux/tmux.conf.bak"
  fi
  ln -s "$tmux_conf_dst" "$xdg_tmux_dir/tmux.conf"
  # ── Install TPM (Tmux Plugin Manager) ──────
  if [ -d "$tpm_dir/.git" ]; then
    logUpdating "TPM"
    git -C "$tpm_dir" pull --quiet >/dev/null 2>&1
    logUpdated "TPM"
  else
    logInstalling "TPM (Tmux Plugin Manager)"
    git clone --quiet https://github.com/tmux-plugins/tpm "$tpm_dir" >/dev/null 2>&1
    logInstalled "TPM"
  fi

  # Install TPM plugins headlessly
  logProgress "Installing tmux plugins..."
  if [ -x "$tpm_dir/bin/install_plugins" ]; then
    "$tpm_dir/bin/install_plugins" >/dev/null 2>&1
    logSuccess "Tmux plugins installed"
  fi

  # TPM provides the tmux half of vim-tmux-navigator. These managed links put
  # its Vim plugin on both editors' runtime paths without replacing user config.
  mkdir -p "$editor_bridge_dir" "$HOME/.vim/plugin" "$HOME/.config/nvim/plugin"
  cp "$SCRIPT_DIR/dotfiles/czsh-tmux-navigator.vim" "$editor_bridge"
  for editor_target in \
    "$HOME/.vim/plugin/czsh-tmux-navigator.vim" \
    "$HOME/.config/nvim/plugin/czsh-tmux-navigator.vim"; do
    if [[ -L "$editor_target" && "$(readlink "$editor_target")" == "$editor_bridge" ]]; then
      continue
    fi
    if [[ -e "$editor_target" || -L "$editor_target" ]]; then
      logWarning "Leaving existing editor plugin file untouched: $editor_target"
      continue
    fi
    ln -s "$editor_bridge" "$editor_target"
  done

  # A running tmux server keeps its options in memory. Reload after deployment
  # so reinstalling CZSH updates existing sessions as well as future ones.
  if tmux list-sessions >/dev/null 2>&1; then
    if tmux source-file "$tmux_conf_dst" >/dev/null 2>&1; then
      tmux refresh-client -S >/dev/null 2>&1 || true
      logConfigured "tmux config and active server"
    else
      logWarning "Tmux config was installed but the active server could not reload it"
    fi
  else
    logConfigured "tmux config"
  fi

  echo
}

register_install_feature install_feature_tmux
