#!/usr/bin/env bash
# Theme + font installer

czsh_install_p10k() {
  local dest="$OHMYZSH_CUSTOM_THEME_PATH/powerlevel10k"
  ensure_dir "$OHMYZSH_CUSTOM_THEME_PATH"
  ensure_clone "$REPO_POWERLEVEL10K" "$dest"
}

FONTS=(
  "HackNerdFont-Regular.ttf|https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Hack/Regular/HackNerdFont-Regular.ttf"
  "RobotoMonoNerdFont-Regular.ttf|https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/RobotoMono/Regular/RobotoMonoNerdFont-Regular.ttf"
  "DejaVuSansMNerdFont-Regular.ttf|https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/DejaVuSansMono/Regular/DejaVuSansMNerdFont-Regular.ttf"
)

czsh_install_fonts() {
  ensure_dir "$CZSH_FONTS_DIR"
  local entry name url
  for entry in "${FONTS[@]}"; do
    IFS='|' read -r name url <<<"$entry"
    if [[ -f $CZSH_FONTS_DIR/$name ]]; then
      logAlreadyInstalled "$name"; continue
    fi
    wget -q -N "$url" -P "$CZSH_FONTS_DIR" && logInstalled "$name" || logWarning "Font failed: $name"
  done
  fc-cache -fv "$CZSH_FONTS_DIR" >/dev/null 2>&1 && logSuccess "Font cache refreshed"
}

czsh_theme_fonts_main() { czsh_install_p10k; czsh_install_fonts; }
register_component "Theme & Fonts" czsh_theme_fonts_main
