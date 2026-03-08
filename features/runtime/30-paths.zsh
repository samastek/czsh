export PATH="$HOME/.config/czsh/fzf/bin:$PATH"
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.config/czsh/bin"

if [[ "$CZSH_PLATFORM" == "linux" && -d "/opt/nvim-linux-x86_64/bin" ]]; then
    export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

export NPM_PACKAGES="$HOME/.npm"
export PATH="$NPM_PACKAGES/bin:$PATH"

SAVEHIST=50000