#!/usr/bin/env bash
czsh_configure_codex() {
  cp "$CZSH_ROOT_DIR/zsh_codex.ini" "$HOME/.config/" || return
  read -s -p "Enter your OpenAI API key: " OPENAI_API_KEY; echo
  sed -i "s/TOBEREPLEACED/$OPENAI_API_KEY/" "$HOME/.config/zsh_codex.ini" 2>/dev/null || sed -i '' "s/TOBEREPLEACED/$OPENAI_API_KEY/" "$HOME/.config/zsh_codex.ini"
  pip3 install openai groq --break-system-packages >/dev/null 2>&1 || pip3 install openai groq >/dev/null 2>&1
  logConfigured "zsh_codex"
}
register_component "Zsh Codex" czsh_configure_codex CODEX_FLAG
