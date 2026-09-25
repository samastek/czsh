# CZSH

[![CI](https://github.com/samastek/czsh/actions/workflows/ci.yml/badge.svg)](https://github.com/samastek/czsh/actions/workflows/ci.yml)
![Platforms](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-7aa2f7)
![Shell](https://img.shields.io/badge/shell-Zsh-bb9af7?logo=zsh)
[![License: MIT](https://img.shields.io/badge/license-MIT-9ece6a)](LICENSE)

CZSH is an opinionated Zsh and terminal-environment bootstrapper for macOS and
Linux. It installs a managed Oh My Zsh setup, configures fuzzy completion and a
fast native Zsh prompt, provisions a practical set of terminal tools, and keeps
personal shell overrides separate from generated configuration.

The project is intended for users who want one reproducible setup rather than a
collection of unrelated dotfiles. The installer is designed to run again when
the configuration needs to be synchronized or managed tools need to be updated.

> [!IMPORTANT]
> CZSH replaces `~/.zshrc` after moving the existing file to a timestamped
> backup. It also manages both standard tmux configuration paths. Review the
> [files changed by the installer](#files-and-directories) before running it.

## Quick start

```bash
git clone https://github.com/samastek/czsh.git
cd czsh
./install.sh
```

Open a new terminal after installation, or run `exec zsh`. The default install
does not change the login shell and does not install Neovim; both remain
explicit user choices.

## Contents

- [Quick start](#quick-start)
- [Learning guide](#learning-guide)
- [Capabilities](#capabilities)
- [Installed components](#installed-components)
- [Platform support](#platform-support)
- [Installation](#installation)
- [Installer options](#installer-options)
- [Using the shell](#using-the-shell)
- [Tmux configuration](#tmux-configuration)
- [Customization](#customization)
- [Files and directories](#files-and-directories)
- [Updating](#updating)
- [Troubleshooting](#troubleshooting)
- [Project structure](#project-structure)
- [Development and community](#development-and-community)

## Learning guide

New to Atuin, zoxide, direnv, the modern CLI tools, or the tmux workflow? Start
with the [CZSH learning guide](docs/README.md). It includes a guided first
session, focused chapters with copy-paste examples, practice exercises, and a
[one-page cheat sheet](docs/cheat-sheet.md).

## Capabilities

CZSH provides the following as one managed setup:

- Oh My Zsh with the native CZSH prompt and a curated plugin set.
- FZF-backed Zsh completion and file/directory pickers, with Atuin providing
  fuzzy, session-aware, directory-aware history on `Ctrl+R`.
- Syntax highlighting, inline autosuggestions, additional completion
  definitions, substring history search, directory jumping, and interactive
  Git helpers.
- A configured tmux environment with project/session picking, seamless Vim
  navigation, popups, clipboard integration, and automatic persistence.
- Reproducible, architecture-aware installation of pinned GitHub releases.
- Three Nerd Fonts, FZF, and a managed Vim configuration when Vim is already
  available.
- Optional Neovim installation, Vim-style Zsh editing, and Bash-history
  migration.
- Custom aliases and functions for file search, process selection, GitLab group
  cloning, command reference lookup, and network testing.
- A modular feature system for extending installation and shell startup without
  turning `.zshrc` into a single large file.

## Installed components

### Shell framework and prompt

| Component | Configuration |
| --- | --- |
| [Oh My Zsh](https://ohmyz.sh/) | Installed under `~/.config/czsh/oh-my-zsh` and updated on subsequent runs. |
| CZSH prompt | A two-line native prompt with path, Git branch/dirty state, and exit status in every terminal. |
| [FZF](https://github.com/junegunn/fzf) | Installed under `~/.config/czsh/fzf` with Zsh completion and key bindings enabled. |
| Nerd Fonts | Installs Hack, Roboto Mono, and DejaVu Sans Mono from official release archives. |

The runtime preserves the terminal's advertised `TERM`, enables `no_nomatch`, sets
`SAVEHIST=50000`, and adds the following locations to `PATH`:

```text
~/.config/czsh/bin
~/.local/bin
~/.config/czsh/fzf/bin
```

The prompt is implemented in native Zsh and uses Git's porcelain status for its
repository capsule; it never reads from standard input. For more Bash-like
interactive command handling, unmatched glob characters, `!`, and `=command`
are passed through literally, interactive comments are accepted, and pipeline
redirection uses Bash semantics instead of Zsh `MULTIOS` behavior.
These settings make pasted commands and text pipelines less surprising without
changing Zsh into a Bash-compatible script interpreter; Bash scripts should
still be run with their shebang or explicitly with `bash`.

### Zsh plugins

CZSH enables these plugins at startup:

| Plugin | Purpose |
| --- | --- |
| `zsh-completions` | Additional completion definitions. |
| `zsh-autosuggestions` | Suggestions based on command history. |
| `zsh-syntax-highlighting` | Command-line syntax highlighting. |
| `history-substring-search` | History navigation filtered by current input. |
| `fzf-tab` | Replaces the completion menu with an FZF picker. |
| `screen` | GNU Screen aliases and helpers. |
| `web-search` | Search-engine shortcuts. |
| `extract` | Archive extraction helper. |
| `sudo` | Adds `sudo` to the current command with `Esc` twice. |
| `docker` | Docker aliases and completions. |
| `systemd` | systemd aliases; enabled on Linux only. |

### Command-line tools

The following tools are installed or configured by the default `./install.sh`
run:

- **Lazygit.** Installs the version pinned in `config.conf` to
  `~/.local/bin/lazygit`.
- **Lazydocker.** Installs the version pinned in `config.conf` to
  `~/.local/bin/lazydocker`. Docker Engine is not installed by the main
  installer.
- **Lazyjournal.** Installs the pinned release on supported Linux systems
  only when `journalctl` is available.
- **tmux.** Installs through the detected package manager when missing, then
  deploys the CZSH configuration and TPM plugins.
- **The Ultimate vimrc.** Installs or updates
  [amix/vimrc](https://github.com/amix/vimrc) when `vim` is already installed.
  CZSH does not install Vim itself.

The default setup also installs `eza`, `fd`, ripgrep, zoxide, Delta, Atuin,
direnv, Yazi, btop, dust, glow, and sops. Zoxide supplies `z`/`zi`, Delta is
the Git pager, and `y` opens Yazi and changes the shell directory to its exit
location. Btop is an interactive resource monitor, dust is a fast disk-usage
visualizer, glow renders Markdown in the terminal, and sops encrypts secrets
in files such as `.sops.yaml`-managed configuration.

Neovim is opt-in. It is installed only when `--neovim` is present. That option
installs the pinned release under `~/.local/share` and links `nvim` into
`~/.local/bin`; it does not install a Neovim configuration or plugins.

Package-manager inputs are readable in `packages/Brewfile` and
`packages/apt.txt`; portable Linux tools that are unavailable in older distro
repositories use the versions in `config.conf`.

## Platform support

The main installer supports macOS and Linux. It recognizes Homebrew, APT,
Pacman, DNF, YUM, and `pkg` for prerequisite and tmux installation.

Prebuilt release support varies by tool:

| Tool | macOS | Linux |
| --- | --- | --- |
| Neovim (opt-in) | x86_64, arm64 | x86_64, arm64 |
| Lazygit | x86_64, arm64 | x86_64, x86, arm64, armv6 |
| Lazydocker | x86_64, arm64 | x86_64, x86, arm64, armv7, armv6 |
| Lazyjournal | Not installed | x86_64, arm64; requires `journalctl` |

Unsupported release combinations are skipped without stopping the rest of the
installation.

### Additional requirements

- A network connection for package installation, Git clones, and release
  downloads.
- `sudo` access when the detected system package manager requires it.
- `tar` for downloaded release archives.
- A terminal configured to use one of the installed Nerd Fonts.

## Installation

Clone the repository and run the installer:

```bash
git clone https://github.com/samastek/czsh.git
cd czsh
./install.sh
```

The default command does not install Neovim. Use `./install.sh --neovim` when
Neovim should be installed or updated.

Open a new terminal after installation. To make Zsh the login shell, run:

```bash
chsh -s "$(command -v zsh)"
```

The installer does not change the login shell automatically.

### Existing configuration

Before deploying CZSH, the installer moves an existing `~/.zshrc` to:

```text
~/.zshrc-backup-YYYY-MM-DD-HHMMSS
```

An existing `~/.oh-my-zsh` directory is moved into the managed CZSH directory.
Existing tmux configuration files are backed up as `~/.tmux.conf.bak` and
`~/.config/tmux/tmux.conf.bak` before managed symlinks are created.
When a tmux server is already running, the installer reloads it so configuration
and colour changes take effect in existing sessions.

Managed plugin directories are synchronized to each plugin's upstream default
branch. Do not keep local changes inside
`~/.config/czsh/oh-my-zsh/custom/plugins`.

## Installer options

```text
Usage: ./install.sh [options]

  -h, --help         Show installer help
  -c, --cp-hist      Import ~/.bash_history into ~/.zsh_history
  -v, --vim-mode     Enable Vim-style Zsh line editing
      --neovim       Install or update Neovim
      --upgrade      Reinstall versions pinned in config.conf
      --uninstall    Remove managed loaders/links and restore backups
```

Options may be combined:

```bash
./install.sh --neovim --cp-hist --vim-mode
```

### Bash-history migration

`--cp-hist` downloads a conversion script, reads `~/.bash_history`, and appends
the converted entries to `~/.zsh_history`. It does not import an existing Zsh
history file, remove duplicate entries, or replace the source Bash history.

### Neovim

Neovim is not part of the default installation. Install or update it explicitly:

```bash
./install.sh --neovim
```

The installer downloads the pinned architecture-matched release, extracts it
under `~/.local/share`, and links the executable into `~/.local/bin`. It does
not install a Neovim configuration or plugins.

### Vim-style shell editing

`--vim-mode` creates `~/.config/czsh/zshrc/vim-mode.zsh`. It enables Zsh's Vi
line editor, uses a beam cursor in insert mode and a block cursor in command
mode, sets `KEYTIMEOUT=1`, and adds these bindings:

| Key | Action |
| --- | --- |
| `Esc` | Enter Vi command mode. |
| `j` / `k` in command mode | Search through matching history. |
| `Ctrl+R` | Open Atuin history search (after post-runtime initialization). |
| `Ctrl+A` / `Ctrl+E` | Move to the beginning or end of the line. |
| `Ctrl+U` | Delete backward to the beginning of the line. |
| `Backspace` / `Ctrl+H` | Delete the previous character. |

## Using the shell

### Fuzzy completion

Press `Tab` to open completion. Inside the FZF picker:

| Key | Action |
| --- | --- |
| `Tab` | Move to the next item. |
| `Shift+Tab` | Move to the previous item. |
| `Ctrl+Space` | Toggle the current item and move down. |
| `Enter` | Insert all marked items. |
| `F1` / `F2` | Move between completion groups. |
| `/` | Accept the current directory and continue completing a deeper path. |

Terminals traditionally send the same control code for `Ctrl+Tab` and `Tab`,
and FZF therefore has no separate `ctrl-tab` key name. To use `Ctrl+Tab` for
multi-selection, configure the terminal (or terminal multiplexer) to send
`Ctrl+Space` for `Ctrl+Tab`; FZF will then apply the binding above while plain
`Tab` continues to move through the choices.

`Ctrl+R` opens Atuin history search. The standard FZF file and directory
widgets remain loaded from the installed FZF shell integration.

### Aliases

- **`l`** runs `eza -la --git --icons`.
- **`cat`** runs `bat -p` (`batcat -p` on Debian when needed).
- **`e`** exits the current shell.
- **`myip`** retrieves the public IP with `curl` from `ifconfig.me`, with an
  OpenDNS `dig` fallback.
- **`ip`** enables colored output when the `ip` command exists.
- **`kp`** uses FZF to select processes and sends `TERM`; use `kp -9` to opt
  into `KILL`.
- **`git-update-all`** uses fd's parallel executor to pull every Git repository
  below the current directory with rebase and autostash.
- **`git soft-reset-base`** finds the current branch's creation commit in its
  reflog and soft-resets to it, leaving the removed commits' changes staged.
- **`ta NAME`**, **`tls`**, **`tns NAME`**, and **`tks NAME`** attach, list,
  create, and terminate tmux sessions.

### Functions

- **`cheat COMMAND [TOPIC ...]`** queries `cheat.sh` for a command or topic.
- **`speedtest`** downloads and executes the `sivel/speedtest-cli` Python
  script.
- **`s QUERY`** searches the current tree with ripgrep and opens matching
  lines in FZF with a `bat` preview.
- **`f`** selects a file below the current directory in FZF and prints its
  file type.
- **`y [PATH]`** opens Yazi and changes directory to Yazi's exit location.
- **`glclone`** recursively clones a GitLab group, including nested
  subgroups, while preserving the group hierarchy.
- **`tmux-help`** prints the active tmux keybinding reference.

`glclone` supports public and private GitLab instances, paginates API results,
skips repositories already present, and uses SSH clone URLs by default.

```text
Usage: glclone <group_url> [options]

  -h, --help              Show help
  -t, --token TOKEN       GitLab access token
  -d, --clone-dir DIR     Destination root; default: ./gitlab_projects
  -g, --gitlab-url URL    Override the detected GitLab base URL
      --https             Prefer HTTPS clone URLs
```

The token may also be supplied through `GITLAB_TOKEN` or
`GITLAB_PRIVATE_TOKEN`:

```bash
GITLAB_TOKEN=glpat-example glclone https://gitlab.com/example/team
glclone https://gitlab.example.com/group/subgroup --clone-dir ~/src --https
```

## Tmux configuration

CZSH uses `Ctrl+A` as the tmux prefix and starts window and pane numbering at 1.
Tmux mouse handling and copy-mode shortcuts are disabled. Drag normally to
select text in your terminal, and use the wheel for terminal scrollback. Focus
events, automatic window renumbering, a
50,000-line history buffer, and clipboard integration are enabled. Window names
follow the active pane's current folder rather than its foreground process,
which keeps multiple editors and shells distinguishable.

The prompt, tmux, FZF, bat, and Lazygit share the Tokyo Night tokens exported
by `features/runtime/10-theme.zsh`. The prompt always shows the Git branch and
dirty state. The tmux status line shows optional laptop battery, available RAM,
SSH hostname, synchronized-pane state, date, and time. Everything else uses
native tmux formats. Holding the prefix highlights a `PREFIX` indicator.

| Prompt marker | Meaning |
| --- | --- |
| ` main` | Current branch, or the short commit when detached. |
| `⇡N` / `⇣N` | Commits ahead of / behind the configured upstream. |
| `+N` | Staged files. |
| `~N` | Modified tracked files. |
| `?N` | Untracked files. |
| `!N` | Conflicted files. |
| `≡N` | Stashed entries. |

Ahead/behind counts use the locally known tracking ref. Run `git fetch` when
the prompt must reflect the newest remote state.

### Core bindings

| Binding | Action |
| --- | --- |
| `prefix` + `\|` | Vertical split in the current directory. |
| `prefix` + `-` | Horizontal split in the current directory. |
| `prefix` + `c` | Open a window in the current pane directory. |
| `prefix` + `f` or `Ctrl+F` | Pick a project or existing session. |
| `prefix` + `h/j/k/l` | Move between panes. |
| `Ctrl+H/J/K/L` | Move seamlessly between tmux panes and Vim splits. |
| `prefix` + `H/J/K/L` | Resize panes in five-cell increments. |
| `Shift+Left` / `Shift+Right` | Change windows without the prefix. |
| `prefix` + `<` / `>` | Move the current window. |
| `prefix` + `r` | Reload the configuration. |
| `prefix` + `e` | Open the CZSH tmux help in a popup. |
| `prefix` + `g` / `D` | Open Lazygit / Lazydocker in a popup. |
| `prefix` + `/` | Search and select any window or pane. |

### Tmux plugins

The installer provisions TPM and installs:

- `tmux-sensible`
- `tmux-resurrect`, including pane-content capture
- `tmux-continuum`, saving every 15 minutes and restoring automatically
- `vim-tmux-navigator`

CZSH links a small loader into both `~/.vim/plugin` and
`~/.config/nvim/plugin`, so the editor and tmux halves of the navigator are
available without modifying an existing Vim or Neovim configuration file.

With `tmux-resurrect`, use `prefix` + `Ctrl+S` to save a session and `prefix` +
`Ctrl+R` to restore it manually; continuum also saves and restores sessions.

## Customization

Personal configuration belongs in:

```text
~/.config/czsh/zshrc/
```

Every regular file in this directory, including dotfiles, is sourced after the
CZSH runtime modules and before Oh My Zsh. This makes it possible to modify the
`plugins` array, override prompt variables, add aliases and functions, or set
environment variables without editing generated files.

For example:

```zsh
# ~/.config/czsh/zshrc/local.zsh
plugins+=(kubectl)
export EDITOR=nvim
alias g='git'
```

The prompt colours are regular variables and can be overridden in the same file
before the prompt is initialized:

```zsh
CZSH_PROMPT_BLUE='#89b4fa'
CZSH_PROMPT_GREEN='#a6e3a1'
CZSH_PROMPT_RED='#f38ba8'
```

Post-runtime features are loaded after Oh My Zsh. Repository contributors can
place plugin-dependent configuration in `features/post`; personal users should
normally keep local changes in `~/.config/czsh/zshrc`.

The runtime also sources `~/.config/czsh/marker/marker.sh` when that file already
exists. Marker is not installed by CZSH.

## Files and directories

The main managed layout is:

```text
~/.zshrc                              Main loader installed by CZSH
~/.zshrc-backup-*                     Timestamped pre-install backups
~/.tmux.conf                          Link to the managed tmux configuration
~/.config/tmux/tmux.conf              Second managed tmux link
~/.vim/plugin/czsh-tmux-navigator.vim Vim navigator bridge link
~/.config/nvim/plugin/czsh-tmux-navigator.vim Neovim navigator bridge link
~/.cache/zsh/                         Zsh completion cache
~/.local/bin/                         Release-installed command-line tools
~/.local/share/nvim-*                 Optional extracted Neovim release

~/.config/czsh/
├── bin/                              Managed helper commands
├── czshrc.zsh                        Runtime feature loader
├── features/
│   ├── runtime/                      Loaded before Oh My Zsh
│   └── post/                         Loaded after Oh My Zsh
├── fzf/                              FZF checkout and shell integration
├── oh-my-zsh/                        Framework and plugins
├── tmux/
│   ├── tmux.conf                     Managed tmux configuration
│   ├── theme.conf                    Generated from the shared palette
│   └── plugins/                      TPM and tmux plugins
└── zshrc/                            Personal configuration files
```

At startup, files are loaded in this order:

1. `~/.config/czsh/features/runtime/*.zsh`
2. `~/.config/czsh/zshrc/*`
3. Oh My Zsh and the configured plugins
4. `~/.config/czsh/features/post/*.zsh`

## Updating

Run the installer again from an updated repository checkout:

```bash
git pull
./install.sh
```

A subsequent run updates Oh My Zsh, FZF, managed Zsh plugins, TPM, and The
Ultimate vimrc. Release tools remain at their installed version unless
`--upgrade` is passed; change a pin in `config.conf` and use that flag for an
explicit upgrade. Neovim is updated only with `--neovim --upgrade`. The installer copies the
repository's current runtime and post-runtime modules into the managed
configuration.

Reruns recognize the managed `~/.zshrc` and do not create backup chains. Files
inside `~/.config/czsh/zshrc` are retained.

To remove the managed loaders and tmux links and restore the backups recorded
at installation time, run `./install.sh --uninstall`. Personal overrides and
installed CLI packages are retained.

Some opt-in actions are intentionally not idempotent: `--vim-mode` replaces
`vim-mode.zsh`, and `--cp-hist` appends the Bash history again. Back up local
changes before repeating those options.

After changing shell configuration, start a new shell:

```bash
exec zsh
```

## Troubleshooting

### Completion does not open

Confirm that FZF and `fzf-tab` exist under `~/.config/czsh`, then rerun the
installer. The plugin also provides an optional native module:

```bash
build-fzf-tab-module
exec zsh
```

### Icons are missing or misaligned

Select Hack Nerd Font, Roboto Mono Nerd Font, or DejaVu Sans Mono Nerd Font in
the terminal application's font settings. Installing a font does not make the
terminal select it automatically.

### Restore the previous Zsh configuration

Use the idempotent uninstaller, which restores the recorded Zsh and tmux
backups:

```bash
./install.sh --uninstall
```

## Project structure

```text
.
├── .github/                         CI, ownership, and contribution templates
├── bin/                             Managed helper commands
├── scripts/                         Development and validation commands
├── packages/                        Brew and APT package manifests
├── config.conf                      Pinned GitHub release versions
├── install.sh                        Installer entry point
├── utils.sh                          Installer output and progress helpers
├── .zshrc                            Managed shell loader template
├── czshrc.zsh                        Runtime-module loader template
├── CONTRIBUTING.md                   Contribution workflow and standards
├── SECURITY.md                       Private vulnerability-reporting policy
├── dotfiles/
│   ├── tmux.conf                     Managed tmux configuration
│   └── libinput-gestures.conf        Reference libinput gesture configuration
└── features/
    ├── install/                      Installer features
    ├── lib/                          Shared installer and platform helpers
    ├── runtime/                      Pre-Oh-My-Zsh shell features
    └── post/                         Post-Oh-My-Zsh shell features
```

Installer feature files register themselves with `register_install_feature` and
are sourced by filename order. Runtime and post-runtime files are copied into the
managed configuration during installation and sourced by filename order when a
new shell starts.

The repository also contains `get-docker.sh`, a standalone Docker Engine
installation script derived from `docker/docker-install`. The main CZSH
installer does not execute it.

## Development and community

- Read [CONTRIBUTING.md](CONTRIBUTING.md) before proposing code changes.
- See [CHANGELOG.md](CHANGELOG.md) for release history.
- Run `./scripts/validate.sh` locally; the same checks run in GitHub Actions.
- Run `./scripts/bench.sh` to enforce the 150 ms interactive-startup budget.
- Run `czsh doctor` after installation to check tools, fonts, and managed links.
- Use the structured GitHub issue forms for reproducible bugs and focused
  feature requests.
- Report sensitive problems according to [SECURITY.md](SECURITY.md), never in a
  public issue.
- Participation is governed by the [Code of Conduct](CODE_OF_CONDUCT.md).

CZSH is licensed under the [MIT License](LICENSE).
