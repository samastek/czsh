# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Installer `--upgrade` and `--uninstall` options for managing an existing
  CZSH installation.
- Available RAM is shown in the tmux status bar on supported systems.

### Fixed

- Sessionizer no longer lists every subdirectory of a git repository.
- Fuzzy-finder navigation keys separated from multi-select keys.

### Changed

- The active tmux window is now highlighted with a filled pill.

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
