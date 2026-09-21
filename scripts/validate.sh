#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

bash_files=(install.sh utils.sh get-docker.sh)
zsh_files=(.zshrc czshrc.zsh bin/czsh-sync-theme)

while IFS= read -r file; do
  bash_files+=("$file")
done < <(rg -l '^#!(/usr/bin/env bash|/bin/bash)$' bin | sort)

while IFS= read -r file; do
  bash_files+=("$file")
done < <(find scripts features -type f -name '*.sh' -print | sort)

while IFS= read -r file; do
  zsh_files+=("$file")
done < <(find features -type f -name '*.zsh' -print | sort)

printf 'Checking Bash syntax...\n'
bash -n "${bash_files[@]}"

if command -v zsh >/dev/null 2>&1; then
  printf 'Checking Zsh syntax...\n'
  zsh -n "${zsh_files[@]}"

  printf 'Smoke-testing runtime in a clean HOME...\n'
  smoke_home="$(mktemp -d "${TMPDIR:-/tmp}/czsh-smoke.XXXXXX")"
  trap 'rm -rf "$smoke_home"' EXIT
  scripts/prepare-smoke-home.sh "$smoke_home"
  HOME="$smoke_home" ZDOTDIR="$smoke_home" TMUX='' zsh -ic \
    '_czsh_prompt_precmd; [[ -n "$CZSH_THEME_BLUE" && "$FZF_DEFAULT_OPTS" == *"$CZSH_THEME_BLUE"* && "$PROMPT" == *""* && "$PROMPT" == *""* && "$PROMPT" == *""* && " ${plugins[*]} " != *" z "* ]] && whence -w myip >/dev/null && whence -w git-update-all >/dev/null && [[ "$(alias l)" == *"eza -la --git --icons"* || "$(alias l)" == *"ls -la"* ]]'
  HOME="$smoke_home" ZDOTDIR="$smoke_home" TMUX=1 zsh -ic \
    '_czsh_prompt_precmd; [[ "$PROMPT" == *""* && "$PROMPT" == *""* && "$PROMPT" == *""* ]]'
else
  printf 'Skipping Zsh syntax check: zsh is not installed.\n'
fi

if command -v shellcheck >/dev/null 2>&1; then
  printf 'Running ShellCheck...\n'
  # These files deliberately share variables and source dynamically selected
  # feature modules, which ShellCheck cannot resolve across file boundaries.
  shellcheck --severity=warning --exclude=SC1090,SC2034 "${bash_files[@]}"
else
  printf 'Skipping ShellCheck: shellcheck is not installed.\n'
fi

if command -v tmux >/dev/null 2>&1; then
  printf 'Parsing tmux configuration...\n'
  tmux_home="$(mktemp -d "${TMPDIR:-/tmp}/czsh-tmux.XXXXXX")"
  HOME="$tmux_home" CZSH_THEME_FILE="$REPO_ROOT/features/runtime/10-theme.zsh" \
    bin/czsh-sync-theme
  tmux_status="$(HOME="$tmux_home" tmux -L czsh-validation -f dotfiles/tmux.conf \
    start-server \; show-options -gv status-right \; kill-server)"
  if [[ "$tmux_status" != *'czsh-tmux-battery'* || "$tmux_status" != *'czsh-tmux-ram'* ]]; then
    printf 'Generated tmux theme was not loaded with system indicators.\n' >&2
    exit 1
  fi
  rm -rf "$tmux_home"
else
  printf 'Skipping tmux configuration check: tmux is not installed.\n'
fi

printf 'Validation passed.\n'
