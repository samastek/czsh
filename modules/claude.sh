#!/usr/bin/env bash
czsh_configure_claude() {
  export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  command -v npm >/dev/null 2>&1 || { logError "npm missing"; return; }
  npm install -g @anthropic-ai/claude-code >/dev/null 2>&1 && logInstalled "Claude CLI" || { logError "Claude CLI install failed"; return; }
  mkdir -p "$CZSH_CONFIG_DIR/claude"
  cat > "$CZSH_CONFIG_DIR/claude/config.sh" <<'EOF'
#!/usr/bin/env bash
# export ANTHROPIC_API_KEY=...
EOF
  logConfigured "Claude CLI"
}
register_component "Claude CLI" czsh_configure_claude CLAUDE_FLAG
