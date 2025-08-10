#!/usr/bin/env bash
czsh_install_nvim() {
  if command -v nvim >/dev/null 2>&1; then logAlreadyInstalled "Neovim"; return; fi
  if [[ $OSTYPE == linux* ]]; then
    # Detect architecture
    local arch=$(uname -m)
    local nvim_file=""
    local nvim_dir=""
    
    case "$arch" in
      x86_64)
        nvim_file="nvim-linux-x86_64.tar.gz"
        nvim_dir="nvim-linux64"
        ;;
      aarch64|arm64)
        nvim_file="nvim-linux-arm64.tar.gz"
        nvim_dir="nvim-linux64"
        ;;
      *)
        logError "Unsupported architecture: $arch"
        return
        ;;
    esac
    
    logInfo "Installing Neovim for $arch architecture"
    curl -LO "https://github.com/neovim/neovim/releases/latest/download/$nvim_file" 2>/dev/null || { logError "nvim download failed"; return; }
    sudo rm -rf /opt/nvim
    sudo tar -C /opt -xzf "$nvim_file"
    sudo ln -sf "/opt/$nvim_dir/bin/nvim" /usr/local/bin/nvim
    rm "$nvim_file"
    git clone --quiet https://github.com/NvChad/starter ~/.config/nvim 2>/dev/null && nvim --headless +qall 2>/dev/null
    logInstalled "Neovim"
  else
    logInfo "Skipping Neovim binary install (macOS use brew)."
  fi
}
register_component "Neovim" czsh_install_nvim
