#!/usr/bin/env bash
# System package detection & installation

czsh_detect_missing_packages() {
  local prereqs=(zsh git wget bat curl fontconfig)
  MISSING_PACKAGES=()
  for p in "${prereqs[@]}"; do command -v "$p" >/dev/null 2>&1 || MISSING_PACKAGES+=("$p"); done
  if [[ $OSTYPE == darwin* ]]; then
    command -v python3 >/dev/null 2>&1 || MISSING_PACKAGES+=(python3)
  else
    command -v pip3 >/dev/null 2>&1 || MISSING_PACKAGES+=(python3-pip)
  fi
}

czsh_install_missing_packages() {
  if (( ${#MISSING_PACKAGES[@]} == 0 )); then
    logSuccess "All required packages installed"; return 0
  fi
  logWarning "Missing packages: ${MISSING_PACKAGES[*]}"
  if [[ $OSTYPE == darwin* ]]; then
    for pkg in "${MISSING_PACKAGES[@]}"; do brew install "$pkg" >/dev/null 2>&1 || logError "Failed: $pkg"; done
  else
    local installer
    for installer in 'sudo apt install -y' 'sudo pacman -S --noconfirm' 'sudo dnf install -y' 'sudo yum install -y' 'pkg install -y'; do
      for pkg in "${MISSING_PACKAGES[@]}"; do
        command -v "$pkg" >/dev/null 2>&1 && continue
        eval "$installer $pkg" >/dev/null 2>&1 && logInstalled "$pkg"
      done
    done
  fi
}

czsh_packages_main() { czsh_detect_missing_packages; czsh_install_missing_packages; }
register_component "Packages" czsh_packages_main
