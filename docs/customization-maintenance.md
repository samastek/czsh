# Customization and maintenance

CZSH separates durable personal settings from managed files. Knowing that
boundary makes updates predictable.

## Managed versus personal files

The repository is the source for the managed installation. Running
<code>./install.sh</code> copies runtime files and helper commands into
<code>~/.config/czsh</code>.

On upgrades, the installer keeps an existing CZSH <code>~/.zshrc</code>
unchanged. Settings appended by Homebrew, language-manager installers, or other
tools survive alongside the loader. Only the initial installation replaces an
unmanaged <code>.zshrc</code>, after creating a timestamped backup.

Personal shell settings belong in:

~~~text
~/.config/czsh/zshrc/
~~~

Files in that directory survive installer reruns. Do not keep personal edits
inside the managed Oh My Zsh or plugin checkouts.

Startup order:

~~~text
1. ~/.config/czsh/features/runtime/*.zsh
2. ~/.config/czsh/zshrc/*
3. Oh My Zsh and its plugins
4. ~/.config/czsh/features/post/*.zsh
~~~

The order explains when a value can be consumed or overwritten. Prompt color
variables are designed for personal overrides. Managed post-runtime aliases
such as <code>l</code> and <code>cat</code> intentionally win after Oh My Zsh.

## Automatic tool detection and repair

Homebrew, nvm, fnm, Volta, npm global binaries, pnpm, Cargo, and Bun are detected
automatically in their standard locations. Existing tool home variables and
Node-manager initialization take precedence over defaults.

After installing a tool, run:

~~~sh
czsh scan
~~~

Inside CZSH, this repairs PATH and initialization in the current session and
reports detected integrations. Outside CZSH, it detects integrations and caches
npm's global prefix; start a new CZSH shell to apply the environment.

Scanning queries npm's prefix from your home directory, so a project's
<code>.npmrc</code> does not become your global shell configuration. The prefix
is cached in <code>~/.config/czsh/state/npm-prefix</code>. Startup uses the user
<code>.npmrc</code> or this plain-text cache without launching npm. Simple
absolute paths, quotes, <code>~/</code>, and <code>${HOME}</code> work in the
user prefix setting; scanning handles other npm configuration formats.

If several Node managers are installed, an initialized nvm or fnm environment
is retained; otherwise detection prefers Volta, then fnm, then nvm. Set
<code>CZSH_AUTO_DETECT_TOOLS=false</code> before startup to opt out. Manual scans
still work. Detection initializes installed tools; it cannot infer arbitrary
settings that were already deleted.

## Personal shell configuration

Create one or more clearly named files:

~~~sh
mkdir -p ~/.config/czsh/zshrc
$EDITOR ~/.config/czsh/zshrc/local.zsh
~~~

Example:

~~~sh
export EDITOR=nvim
export VISUAL=nvim

plugins+=(kubectl)

alias g='git'
alias dc='docker compose'

mkcd() {
    mkdir -p -- "$1" && cd -- "$1"
}
~~~

Reload with:

~~~sh
exec zsh
~~~

Diagnose a name before overriding it:

~~~sh
type g
alias l
whence -v mkcd
~~~

If a personal alias conflicts with a managed post-runtime alias, change the
corresponding repository file under <code>features/post</code> and rerun the
installer. That makes the choice explicit and reproducible in your CZSH fork.

## Prompt customization

The prompt uses the shared theme but exposes color variables that can be
overridden from <code>local.zsh</code>:

~~~sh
CZSH_PROMPT_BLUE='#89b4fa'
CZSH_PROMPT_GREEN='#a6e3a1'
CZSH_PROMPT_RED='#f38ba8'
CZSH_PROMPT_YELLOW='#f9e2af'
CZSH_PROMPT_MUTED='#6c7086'
~~~

The prompt shows the branch and dirty state in every terminal, including inside
tmux. Its Git capsule keeps the former tmux colors by default; variables named
<code>CZSH_GIT_*_FG</code> and <code>CZSH_GIT_*_BG</code> can override them.

Over SSH or as root, the prompt also displays <code>user@host</code>.

## Changing the unified palette

The durable source of truth is:

~~~text
features/runtime/10-theme.zsh
~~~

It defines:

~~~text
CZSH_THEME_BG
CZSH_THEME_FG
CZSH_THEME_BLUE
CZSH_THEME_GREEN
CZSH_THEME_RED
CZSH_THEME_YELLOW
CZSH_THEME_PURPLE
CZSH_THEME_MUTED
CZSH_THEME_BORDER
~~~

After changing tokens in the repository:

~~~sh
./install.sh
exec zsh
~~~

The installer runs <code>czsh-sync-theme</code>, which generates matching tmux,
bat, and Lazygit configuration. It also reloads an existing tmux server.

For quick experimentation against the installed copy:

~~~sh
$EDITOR ~/.config/czsh/features/runtime/10-theme.zsh
czsh-sync-theme
tmux source-file ~/.tmux.conf
exec zsh
~~~

Those installed-file edits are temporary; the next installer run replaces
them from the repository.

## Updating CZSH

Routine update:

~~~sh
cd /path/to/czsh
git pull
./install.sh
exec zsh
~~~

This updates managed checkouts and deploys the current configuration.

GitHub-release tools use versions pinned in <code>config.conf</code>. A normal
rerun does not silently replace them. After deliberately changing a pin:

~~~sh
./install.sh --upgrade
~~~

Neovim remains opt-in:

~~~sh
./install.sh --neovim
./install.sh --neovim --upgrade
~~~

Review package inputs in:

~~~text
packages/Brewfile
packages/apt.txt
~~~

These manifests answer “what system packages does CZSH install?” without
having to inspect installer code.

## Health checks

Run the installed-environment doctor first:

~~~sh
czsh doctor
~~~

It checks managed commands, a compatible Nerd Font, tmux links, Vim/Neovim
navigator links, and the Zsh loader.

Useful focused checks:

~~~sh
command -v rg
command -v atuin
alias l
echo "$GIT_PAGER"
echo "$BAT_THEME"
direnv status
atuin doctor
tmux list-sessions
~~~

Remember that installing a Nerd Font does not select it in the terminal
application. If icons appear as boxes, choose Hack Nerd Font, Roboto Mono Nerd
Font, or DejaVu Sans Mono Nerd Font in terminal preferences.

## Repository validation

Before committing CZSH changes:

~~~sh
./scripts/validate.sh
~~~

The validation suite checks:

- Bash and Zsh syntax.
- A clean-HOME runtime smoke test.
- Automatic tool detection, scan repair, and preservation of `.zshrc` additions.
- ShellCheck results.
- tmux configuration parsing.

Measure interactive startup:

~~~sh
./scripts/bench.sh
~~~

The default mean budget is 150 milliseconds. Override it temporarily when
investigating a machine-specific result:

~~~sh
CZSH_STARTUP_BUDGET_MS=200 ./scripts/bench.sh
~~~

Do not raise the committed budget simply to hide a regression. Profile slow
startup code and lazy-load expensive language managers or SDK initialization.

## Safe removal

Uninstall managed loaders and links:

~~~sh
./install.sh --uninstall
~~~

The uninstaller restores recorded Zsh and tmux backups when available.
Personal files under <code>~/.config/czsh/zshrc</code> and installed CLI
packages are retained.

Review the result:

~~~sh
ls -la ~/.zshrc*
ls -la ~/.tmux.conf ~/.config/tmux/tmux.conf
~~~

## Backups and checkout recovery

Initial configuration backups use timestamped or <code>.bak</code> names. If a
managed Git checkout contains an unresolved merge, the installer preserves
diagnostic state under:

~~~text
~/.config/czsh/state/recovery/
~~~

It then repairs the managed checkout so installation can continue. Inspect
recovery folders before deleting them if you suspect a local plugin change was
valuable.

## Common troubleshooting sequence

When a new shell behaves unexpectedly:

~~~sh
czsh doctor
zsh -lic exit
./scripts/validate.sh
type NAME
~~~

Then narrow the layer:

| Symptom | Inspect |
| --- | --- |
| Command missing | <code>command -v NAME</code>, <code>echo "$PATH"</code> |
| Alias surprising | <code>type NAME</code>, <code>alias NAME</code> |
| History picker missing | <code>atuin doctor</code>, <code>bindkey '^R'</code> |
| Project env not loaded | <code>direnv status</code>, contents of <code>.envrc</code> |
| Wrong zoxide destination | <code>zoxide query -l</code> |
| tmux key not working | prefix + <kbd>?</kbd>, <code>tmux show-options -g</code> |
| Theme mismatch | <code>czsh-sync-theme</code>, reload tmux, restart shell |
| Icons missing | Select an installed Nerd Font in terminal preferences |

## Practice

1. Add a harmless alias to <code>local.zsh</code> and reload.
2. Change one prompt color, reload, then restore it.
3. Run <code>czsh doctor</code>, validation, and the startup benchmark.
4. Read <code>config.conf</code> and the package manifest for your platform.
