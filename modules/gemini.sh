#!/usr/bin/env bash
czsh_configure_gemini() {
  export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  command -v npm >/dev/null 2>&1 || { logError "npm missing"; return; }
  npm install -g @google/gemini-cli >/dev/null 2>&1 && logInstalled "Gemini CLI" || { logError "Gemini CLI install failed"; return; }
  mkdir -p "$CZSH_CONFIG_DIR/gemini"
  cat > "$CZSH_CONFIG_DIR/gemini/config.sh" <<'EOF'
#!/usr/bin/env bash
# Add export GEMINI_API_KEY=... here or run 'gemini auth'
EOF
  logConfigured "Gemini CLI"
}
register_component "Gemini CLI" czsh_configure_gemini GEMINI_FLAG
