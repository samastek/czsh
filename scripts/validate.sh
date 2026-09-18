#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

bash_files=(
  install.sh
  utils.sh
  get-docker.sh
  scripts/*.sh
  features/install/*.sh
  features/lib/*.sh
)

zsh_files=(
  .zshrc
  czshrc.zsh
  bin/czsh-tmux-git-status
  features/runtime/*.zsh
  features/post/*.zsh
)

printf 'Checking Bash syntax...\n'
bash -n "${bash_files[@]}"

if command -v zsh >/dev/null 2>&1; then
  printf 'Checking Zsh syntax...\n'
  zsh -n "${zsh_files[@]}"
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
  tmux -L czsh-validation -f dotfiles/tmux.conf \
    start-server \; show-options -g status-right \; kill-server >/dev/null
else
  printf 'Skipping tmux configuration check: tmux is not installed.\n'
fi

if command -v git >/dev/null 2>&1 && command -v zsh >/dev/null 2>&1; then
  git_segment="$(bin/czsh-tmux-git-status "$REPO_ROOT")"
  if [[ "$git_segment" != *''* ]]; then
    printf 'Git status helper did not produce a branch segment.\n' >&2
    exit 1
  fi
fi

printf 'Validation passed.\n'
