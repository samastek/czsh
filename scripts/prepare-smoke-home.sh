#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  printf 'Usage: %s HOME_DIRECTORY [--full]\n' "$0" >&2
  exit 2
fi

smoke_home="$1"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
mode="${2:-}"

mkdir -p \
  "$smoke_home/.config/czsh/features/runtime" \
  "$smoke_home/.config/czsh/features/post" \
  "$smoke_home/.config/czsh/oh-my-zsh/custom/plugins" \
  "$smoke_home/.config/czsh/zshrc" \
  "$smoke_home/.config/czsh/bin" \
  "$smoke_home/.cache/zsh"

cp "$repo_root/.zshrc" "$smoke_home/.zshrc"
cp "$repo_root/czshrc.zsh" "$smoke_home/.config/czsh/czshrc.zsh"
cp "$repo_root"/features/runtime/*.zsh "$smoke_home/.config/czsh/features/runtime/"
cp "$repo_root"/features/post/*.zsh "$smoke_home/.config/czsh/features/post/"

if [[ "$mode" == '--full' ]]; then
  rm -rf "$smoke_home/.config/czsh/oh-my-zsh"
  git clone --depth=1 --quiet https://github.com/ohmyzsh/ohmyzsh.git \
    "$smoke_home/.config/czsh/oh-my-zsh"

  plugins=(
    'fzf-tab:https://github.com/Aloxaf/fzf-tab.git'
    'zsh-syntax-highlighting:https://github.com/zsh-users/zsh-syntax-highlighting.git'
    'zsh-autosuggestions:https://github.com/zsh-users/zsh-autosuggestions.git'
    'zsh-completions:https://github.com/zsh-users/zsh-completions.git'
    'history-substring-search:https://github.com/zsh-users/zsh-history-substring-search.git'
  )
  for plugin in "${plugins[@]}"; do
    name="${plugin%%:*}"
    repo="${plugin#*:}"
    git clone --depth=1 --quiet "$repo" \
      "$smoke_home/.config/czsh/oh-my-zsh/custom/plugins/$name"
  done
else
  # The fast smoke test validates source order without network access.
  printf '%s\n' '# minimal Oh My Zsh stub for CZSH runtime smoke tests' \
    >"$smoke_home/.config/czsh/oh-my-zsh/oh-my-zsh.sh"
fi
