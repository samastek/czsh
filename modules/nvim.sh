#!/usr/bin/env bash
czsh_install_nvim() {
  if command -v nvim >/dev/null 2>&1; then logAlreadyInstalled "Neovim"; return; fi
  if [[ $OSTYPE == linux* ]]; then
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz 2>/dev/null || { logError "nvim download failed"; return; }
    sudo rm -rf /opt/nvim
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
    rm nvim-linux-x86_64.tar.gz
    git clone --quiet https://github.com/NvChad/starter ~/.config/nvim 2>/dev/null && nvim --headless +qall 2>/dev/null
    logInstalled "Neovim"
  else
    logInfo "Skipping Neovim binary install (macOS use brew)."
  fi
}
register_component "Neovim" czsh_install_nvim
