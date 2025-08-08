#!/usr/bin/env bash
# Declarative plugin list & helpers

# Each entry: name|repo_url|flags (reserved for future metadata)
CZSH_PLUGINS=(
  "fzf-tab|https://github.com/Aloxaf/fzf-tab.git"
  "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting.git"
  "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions.git"
  "zsh_codex|https://github.com/samastek/zsh_codex.git|optional"
  "zsh-completions|https://github.com/zsh-users/zsh-completions.git"
  "history-substring-search|https://github.com/zsh-users/zsh-history-substring-search.git"
  "forgit|https://github.com/wfxr/forgit.git"
)

czsh_plugin_is_enabled() {
  local name=$1 flags=$2
  # User can explicitly limit via CZSH_ENABLED_PLUGINS (space separated names)
  if [[ -n ${CZSH_ENABLED_PLUGINS:-} ]]; then
    [[ " $CZSH_ENABLED_PLUGINS " == *" $name "* ]] || return 1
  fi
  # Optional gating: infer FLAG variable (NAME with non-alnum -> _) + _FLAG
  if [[ $flags == *optional* ]]; then
    local flag_var
    flag_var="$(echo "$name" | tr '[:lower:]-' '[:upper:]_')_FLAG"
    if [[ ${!flag_var:-false} != true ]]; then
      logInfo "Skipping optional plugin $name (flag $flag_var not enabled)"
      return 1
    fi
  fi
  return 0
}

czsh_each_plugin() {
  local cb=$1
  local entry name repo flags
  for entry in "${CZSH_PLUGINS[@]}"; do
    IFS='|' read -r name repo flags <<<"$entry"
    if czsh_plugin_is_enabled "$name" "${flags:-}"; then
      "$cb" "$name" "$repo" "$flags"
    fi
  done
}
