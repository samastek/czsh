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
    sudo rm -rf /opt/nvim /opt/nvim-linux64
    sudo tar -C /opt -xzf "$nvim_file"
    
    # Find the actual extracted directory
    local extracted_dir=$(find /opt -maxdepth 1 -name "nvim*" -type d | head -1)
    if [[ -z "$extracted_dir" ]]; then
      logError "Could not find extracted Neovim directory"
      rm "$nvim_file"
      return
    fi
    
    # Create symlink from the actual directory
    sudo ln -sf "$extracted_dir/bin/nvim" /usr/local/bin/nvim
    rm "$nvim_file"
    
    # Verify installation
    if command -v nvim >/dev/null 2>&1; then
      git clone --quiet https://github.com/NvChad/starter ~/.config/nvim 2>/dev/null && nvim --headless +qall 2>/dev/null
      logInstalled "Neovim"
    else
      logError "Neovim installation verification failed"
    fi
  else
    logInfo "Skipping Neovim binary install (macOS use brew)."
  fi
}
register_component "Neovim" czsh_install_nvim
