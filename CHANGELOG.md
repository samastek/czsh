# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Automatic detection of Homebrew, nvm, fnm, Volta, npm global binaries,
  pnpm, Cargo, and Bun shell environments.
- `czsh scan` to repair the current shell environment and cache npm's global
  prefix for future sessions.
- Installer `--upgrade` and `--uninstall` options for managing an existing
  CZSH installation.
- Available RAM is shown in the tmux status bar on supported systems.
- `git soft-reset-base` resets a feature branch to its recorded creation
  commit while retaining subsequent changes in the index.
- Btop, dust, glow, and sops as managed modern CLI tools, installed via
  Homebrew on macOS and pinned GitHub releases on Linux.
- Lazygit shows diffs through Delta, side by side, with <kbd>|</kbd> switching
  to the inline view.
- Meld is installed and set as the Git diff tool when none is configured, so
  Lazygit's <kbd>Ctrl+T</kbd> opens files in it.
- Tmux scroll mode from the keyboard (prefix + <kbd>[</kbd> or <kbd>PgUp</kbd>)
  with vi keys; mouse selections copy to the system clipboard and keep the
  scroll position.
- `extract` (alias `x`) unpacks common archive formats.

### Changed

- `grep`, `egrep` and `fgrep` use ugrep when it is installed, a faster
  drop-in replacement with GNU grep's options and behavior.
- Oh My Zsh is no longer used. A small built-in core sets history, completion,
  key bindings and the window title and loads the plugins from
  `~/.config/czsh/plugins`. Shell startup is roughly a third faster.
- <kbd>Ctrl+R</kbd> uses FZF history search again; Atuin is no longer installed.
- Tmux uses no plugins. TPM, tmux-sensible, tmux-resurrect and tmux-continuum
  are removed; <kbd>Ctrl+H/J/K/L</kbd> navigation across tmux panes and Vim
  splits is built in, and prefix + <kbd>Ctrl+L</kbd> clears the screen.
- The Ultimate vimrc, the history-substring-search, screen, web-search,
  docker and systemd plugins, and the wget dependency are removed.
- The active tmux window is now highlighted with a filled pill.
- Destroying the current tmux session switches to the next remaining session.
- The project picker visually distinguishes existing sessions from directories
  that can open a new session and prompts for the name of newly created
  sessions.

### Fixed

- Upgrades retain existing CZSH `.zshrc` files and symlinks, preserving settings
  appended by third-party installers, and remove the former Oh My Zsh loader.
- Sessionizer no longer lists every subdirectory of a git repository.
- Fuzzy-finder navigation keys separated from multi-select keys.

## [1.0.1] - 2026-09-19

### Fixed

- Nerd Font downloads restored in the installer.
- The active tmux configuration now reloads after installation.

### Changed

- Tmux adopts an accessible slate-and-sage color palette.

## [1.0.0] - 2026-09-19

Initial tagged release.

### Added

- Modular Zsh configuration with platform detection (`features/install`,
  `features/runtime`, `features/post`).
- Native Zsh prompt and tmux status line, replacing Powerlevel10k.
- Tmux configuration, aliases, and an in-tmux help cheatsheet
  (`prefix+e` popup).
- Architecture-aware installers for Lazygit, Lazydocker, Lazyjournal,
  Neovim (with LazyVim and GitHub Copilot support), the Ultimate vimrc,
  and the Bitwarden CLI.
- fzf, Atuin, zoxide, direnv, and other modern CLI tool integrations.
- Managed binaries and configuration installed under XDG-standard paths.
- `czsh` CLI with a `doctor` subcommand for verifying the installed
  environment.
- CI workflow (`scripts/validate.sh`, `scripts/bench.sh`) validating shell
  and tmux configuration and enforcing a startup-time budget.
- Community health files: `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`,
  `SECURITY.md`, issue templates, and `CODEOWNERS`.

### Changed

- Streamlined the default installation flow, with improved logging and
  progress indication.

### Fixed

- Piped and pasted shell input is now preserved correctly.
- GHCup environment now loads from the active home directory.
- Tmux XDG configuration path no longer shadows the CZSH-managed config.

### Removed

- Gemini and Claude CLI integrations (added and then removed prior to the
  1.0.0 release).

[Unreleased]: https://github.com/samastek/czsh/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/samastek/czsh/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/samastek/czsh/releases/tag/v1.0.0
